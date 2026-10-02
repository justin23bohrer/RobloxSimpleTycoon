-- DataService (server only)
-- Saves and loads each player's cookies (cash), house purchases, Caleb
-- trophies, and which trophies are equipped with a DataStore
-- (Config.DataStoreName, key "Player_<UserId>").
--
-- Cookies: DataService only keeps the saved copy. EconomyService (the only
-- writer of cash) reads it with GetSavedCash once the data loaded, and hands
-- every later change to SetSavedCash, which only marks the data dirty: the
-- amount is written by the normal autosave / leave save / BindToClose, never
-- once per drop.
--
-- The shape of the saved data and how bad data is cleaned is in DataSchema.
--
-- Safety rules:
-- * Every DataStore call is retried with backoff (1, 2, 4, 8 s).
-- * If loading fails, the player plays UNSAVED this session: nothing is ever
--   written over their stored data (a warn says so in the server Output).
-- * Session lock: loading writes this server's id (game.JobId) into the record
--   (SessionJobId/SessionTime), and every save first checks the record still
--   carries this server's id. Leaving clears it. A server that joins while
--   another server holds a fresh lock waits for it to be released (~30 s at
--   most), then takes it over; the old server then sees a foreign id and stops
--   saving, so a fast server hop can never write older data over newer data.
--   A lock not refreshed for LOCK_EXPIRE_SECONDS (crashed server) is taken
--   over at once.
-- * Saves use UpdateAsync: on leave, every Config.DataAutosaveSeconds when
--   something changed (or to refresh the lock), right after a new trophy, and
--   for everyone in parallel in game:BindToClose.
-- * In Studio without "Enable Studio Access to API Services" every DataStore
--   call errors: that is detected, warned once, and the game runs unsaved.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataSchema = require(script.Parent.DataSchema)
local Purchases = require(script.Parent.Purchases)

local DataService = {}

export type TrophyRecord = DataSchema.TrophyRecord

-- Safety timings (not gameplay tuning, so they live here, not in Config).
local MAX_ATTEMPTS = 5 -- tries per DataStore call
local RETRY_BASE_SECONDS = 1 -- waits 1, 2, 4, 8 s between tries
local LOCK_WAIT_SECONDS = 5 -- between tries while another server holds the lock
local LOCK_WAIT_ATTEMPTS = 6 -- then take the lock over (~30 s)
local LOCK_EXPIRE_SECONDS = 30 * 60 -- older locks belong to a dead server
local LOCK_REFRESH_SECONDS = 10 * 60 -- autosave rewrites unchanged data this often
local CLOSE_TIMEOUT_SECONDS = 25 -- BindToClose gets 30 s in total

-- game.JobId is "" in Studio, so make up a unique id there.
local SERVER_ID = if game.JobId ~= "" then game.JobId else `Studio-{HttpService:GenerateGUID(false)}`

type Session = {
	Status: string, -- "Loading", "Loaded" (saving), or "Unsaved"
	Data: DataSchema.PlayerData?,
	Dirty: boolean, -- changed since the last successful save
	LastWrite: number, -- os.clock() of the last successful write
	Saving: boolean,
	Released: boolean, -- lock given back on leave; never write again
	Leaving: boolean,
}

local sessions: { [Player]: Session } = {}
local removed: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local releasingUserIds: { [number]: boolean } = {} -- leave saves still running
local busy = 0 -- loads + saves in progress (BindToClose waits for them)
local closing = false
local savingDisabled = false

local loadFinished = Instance.new("BindableEvent")
local trophiesChanged = Instance.new("BindableEvent")
local equippedChanged = Instance.new("BindableEvent")
-- Fires (player) after AddTrophy adds a trophy.
DataService.TrophiesChanged = trophiesChanged.Event
-- Fires (player) after the equipped list changes (SetEquipped, or AddTrophy
-- auto-equipping a new trophy).
DataService.EquippedChanged = equippedChanged.Event

local function disableSaving(message: string)
	if savingDisabled then
		return
	end
	savingDisabled = true
	warn(`DataService: saving is OFF this session ({message}). Enable Studio Access to API Services to test saving (Game Settings > Security).`)
end

-- In Studio, DataStores need a published place and API access turned on.
local function isNoAccessError(message: string): boolean
	if not RunService:IsStudio() then
		return false
	end
	local lower = string.lower(message)
	return lower:find("studioaccesstoapisnotallowed", 1, true) ~= nil
		or lower:find("access to api", 1, true) ~= nil
		or lower:find("publish", 1, true) ~= nil
		or lower:find("403", 1, true) ~= nil
end

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		disableSaving(tostring(result))
	end
end

local function keyFor(player: Player): string
	return `Player_{player.UserId}`
end

-- Calls fn up to MAX_ATTEMPTS times. Returns (true, result) or (false, error).
local function withRetries(what: string, fn: () -> any): (boolean, any)
	local lastError = "saving is off"
	for attempt = 1, MAX_ATTEMPTS do
		if savingDisabled then
			return false, lastError
		end
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = tostring(result)
		if isNoAccessError(lastError) then
			disableSaving(lastError)
			return false, lastError
		end
		if attempt < MAX_ATTEMPTS then
			task.wait(RETRY_BASE_SECONDS * 2 ^ (attempt - 1))
		end
	end
	warn(`DataService: {what} failed after {MAX_ATTEMPTS} tries: {lastError}`)
	return false, lastError
end

local function toStored(data: DataSchema.PlayerData, lockedBy: string?): { [string]: any }
	local stored = DataSchema.ToStored(data)
	stored.SessionJobId = lockedBy
	stored.SessionTime = os.time()
	return stored
end

local function isLockedByOtherServer(stored: any): boolean
	return typeof(stored) == "table"
		and typeof(stored.SessionJobId) == "string"
		and stored.SessionJobId ~= SERVER_ID
		and typeof(stored.SessionTime) == "number"
		and os.time() - stored.SessionTime < LOCK_EXPIRE_SECONDS
end

-- Reads the player's data and takes the session lock in one UpdateAsync.
-- Returns the data, or nil and why (then nothing was written).
local function load(player: Player): (DataSchema.PlayerData?, string?)
	local lockTries = 0
	while true do
		local outcome, loaded, reason = nil, nil, nil
		local ok, err = withRetries(`loading {player.Name}`, function()
			return (store :: DataStore):UpdateAsync(keyFor(player), function(stored)
				-- May run more than once; only the last run counts.
				local data, why = DataSchema.FromStored(stored)
				if not data then
					outcome, loaded, reason = "bad", nil, why
					return nil -- cancel: never overwrite data we can't read
				end
				if isLockedByOtherServer(stored) and lockTries < LOCK_WAIT_ATTEMPTS then
					outcome, loaded, reason = "locked", nil, nil
					return nil
				end
				outcome, loaded, reason = "ok", data, nil
				return toStored(data, SERVER_ID), { player.UserId }
			end)
		end)
		if not ok then
			return nil, err
		elseif outcome == "ok" then
			return loaded, nil
		elseif outcome ~= "locked" then
			return nil, reason or "unknown"
		end
		lockTries += 1
		if player.Parent ~= Players then
			return nil, "left while another server still had their data open"
		end
		task.wait(LOCK_WAIT_SECONDS)
	end
end

-- Writes the session's data if this server still holds the lock.
-- release = true gives the lock back (player left / server closing).
local function saveNow(player: Player, session: Session, release: boolean)
	while session.Saving do
		task.wait() -- one write per player at a time
	end
	if session.Status ~= "Loaded" or session.Released or savingDisabled then
		return
	end
	session.Saving = true
	local wasDirty = session.Dirty
	session.Dirty = false -- changes made during this write mark it dirty again

	local outcome = nil
	local ok = withRetries(`saving {player.Name}`, function()
		return (store :: DataStore):UpdateAsync(keyFor(player), function(stored)
			if typeof(stored) ~= "table" or stored.SessionJobId ~= SERVER_ID then
				outcome = "lost"
				return nil -- another server has newer data; never overwrite it
			end
			outcome = "ok"
			return toStored(session.Data :: DataSchema.PlayerData, if release then nil else SERVER_ID), { player.UserId }
		end)
	end)

	if ok and outcome == "ok" then
		session.LastWrite = os.clock()
		session.Released = release
	elseif ok and outcome == "lost" then
		session.Status = "Unsaved"
		warn(`DataService: another server took over {player.Name}'s data; this server stops saving it.`)
	else
		session.Dirty = session.Dirty or wasDirty -- try again next autosave
	end
	session.Saving = false
end

local function save(player: Player, session: Session, release: boolean)
	busy += 1
	saveNow(player, session, release)
	busy -= 1
end

local function getLoaded(player: Player): Session?
	local session = sessions[player]
	return if session and session.Status == "Loaded" then session else nil
end

-- Called by ServerMain when a player joins. Loads in the background.
function DataService.OnPlayerAdded(player: Player)
	if sessions[player] then
		return
	end
	local session: Session = {
		Status = "Loading",
		Data = nil,
		Dirty = false,
		LastWrite = os.clock(),
		Saving = false,
		Released = false,
		Leaving = false,
	}
	sessions[player] = session
	busy += 1

	task.spawn(function()
		-- Rejoining this same server: let the old session's leave save finish.
		while releasingUserIds[player.UserId] and not session.Leaving do
			task.wait(0.2)
		end
		local data, reason = nil, "saving is off"
		if not savingDisabled and store and not session.Leaving then
			data, reason = load(player)
		end
		if data then
			session.Data = data
			session.Status = "Loaded"
			session.LastWrite = os.clock()
		else
			session.Status = "Unsaved"
			if not savingDisabled and not session.Leaving then
				warn(`DataService: could not load {player.Name}'s data ({reason}). They play UNSAVED this session; their saved data is left untouched.`)
			end
		end
		loadFinished:Fire(player)
		if session.Leaving or closing then
			saveNow(player, session, true) -- gone already: give the lock back
		end
		busy -= 1
	end)
end

-- Called by ServerMain when a player leaves (last). Saves and releases.
function DataService.OnPlayerRemoving(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	removed[player] = true
	session.Leaving = true
	loadFinished:Fire(player) -- wake anyone in WaitForData
	if session.Status ~= "Loaded" then
		return -- still loading (the loader releases the lock) or unsaved
	end
	local userId = player.UserId
	releasingUserIds[userId] = true
	task.spawn(function()
		save(player, session, true)
		releasingUserIds[userId] = nil
	end)
end

-- True while the player's data is still loading (just joined).
function DataService.IsLoading(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and session.Status == "Loading"
end

-- True once the player's data loaded and is being saved.
function DataService.IsLoaded(player: Player): boolean
	return getLoaded(player) ~= nil
end

-- Yields until loading finished (or the player left). Returns IsLoaded.
function DataService.WaitForData(player: Player): boolean
	while player.Parent == Players and not removed[player] do
		local session = sessions[player]
		if session and session.Status ~= "Loading" then
			return session.Status == "Loaded"
		end
		loadFinished.Event:Wait()
	end
	return false
end

-- The saved cookie amount, or nil if the data is not loaded.
function DataService.GetSavedCash(player: Player): number?
	local session = getLoaded(player)
	return if session then (session.Data :: DataSchema.PlayerData).Cash else nil
end

-- Records the player's current cookies for the next save (EconomyService
-- only; it does not change anyone's cash). Ignored if the data is not loaded.
function DataService.SetSavedCash(player: Player, amount: number)
	local session = getLoaded(player)
	if not session then
		return
	end
	local data = session.Data :: DataSchema.PlayerData
	local clean = DataSchema.CleanCash(amount)
	if data.Cash ~= clean then
		data.Cash = clean
		session.Dirty = true
	end
end

-- A copy of the saved purchase ids ({} if not loaded).
function DataService.GetPurchases(player: Player): { [string]: true }
	local copy = {}
	local session = getLoaded(player)
	if session then
		for id in (session.Data :: DataSchema.PlayerData).Purchases do
			copy[id] = true
		end
	end
	return copy
end

-- Records a purchase (TycoonService, after a successful purchase).
function DataService.SetPurchased(player: Player, purchaseId: string)
	local session = getLoaded(player)
	if not session or typeof(purchaseId) ~= "string" or not Purchases.Get(purchaseId) then
		return
	end
	local purchases = (session.Data :: DataSchema.PlayerData).Purchases
	if not purchases[purchaseId] then
		purchases[purchaseId] = true
		session.Dirty = true
	end
end

-- A copy of the player's trophies, oldest first ({} if not loaded).
function DataService.GetTrophies(player: Player): { TrophyRecord }
	local session = getLoaded(player)
	return if session then DataSchema.CopyTrophies((session.Data :: DataSchema.PlayerData).Trophies) else {}
end

-- Adds a trophy and saves right away. False if the data is not loaded, the
-- record is invalid, or it is an event trophy (EventId ~= "") and the player
-- already has one for that EventId. A missing InstanceId (or one the player
-- already owns) is replaced by a new one. If an active slot is free
-- (fewer than Config.TrophyActiveSlots equipped), the new trophy is equipped
-- too, so a first trophy shows up in the Trophy Case right away.
function DataService.AddTrophy(player: Player, record: TrophyRecord): boolean
	local session = getLoaded(player)
	local clean = DataSchema.CleanTrophy(record)
	if not session or not clean then
		return false
	end
	local data = session.Data :: DataSchema.PlayerData
	for _, owned in data.Trophies do
		if clean.EventId ~= "" and owned.EventId == clean.EventId then
			return false
		end
		if owned.InstanceId == clean.InstanceId then
			clean.InstanceId = DataSchema.NewInstanceId()
		end
	end
	table.insert(data.Trophies, clean)
	local autoEquipped = #data.Equipped < Config.TrophyActiveSlots
	if autoEquipped then
		table.insert(data.Equipped, clean.InstanceId)
	end
	session.Dirty = true
	trophiesChanged:Fire(player)
	if autoEquipped then
		equippedChanged:Fire(player)
	end
	task.spawn(save, player, session, false)
	return true
end

-- A copy of the equipped InstanceIds in display order ({} if not loaded).
function DataService.GetEquipped(player: Player): { string }
	local session = getLoaded(player)
	return if session then table.clone((session.Data :: DataSchema.PlayerData).Equipped) else {}
end

-- Replaces the equipped list. Every id must be a trophy the player owns,
-- with no repeats and at most Config.TrophyActiveSlots. Returns (true) or
-- (false, reason); nothing changes on false. Saved with the next autosave.
function DataService.SetEquipped(player: Player, ids: { string }): (boolean, string?)
	local session = getLoaded(player)
	if not session then
		return false, "data not loaded"
	end
	if typeof(ids) ~= "table" then
		return false, "not a list"
	end
	local count = 0
	for _ in ids do
		count += 1
	end
	if count ~= #ids then
		return false, "not a list"
	end
	if count > Config.TrophyActiveSlots then
		return false, "too many equipped"
	end
	local data = session.Data :: DataSchema.PlayerData
	local owned = {}
	for _, record in data.Trophies do
		owned[record.InstanceId] = true
	end
	local seen = {}
	for _, id in ids do
		if typeof(id) ~= "string" or not owned[id] then
			return false, "not owned"
		end
		if seen[id] then
			return false, "equipped twice"
		end
		seen[id] = true
	end
	local same = #ids == #data.Equipped
	for i, id in ids do
		same = same and data.Equipped[i] == id
	end
	if not same then
		data.Equipped = table.clone(ids)
		session.Dirty = true
		equippedChanged:Fire(player)
	end
	return true
end

-- Autosave: only changed data, plus an occasional rewrite to keep the lock fresh.
task.spawn(function()
	while true do
		task.wait(Config.DataAutosaveSeconds)
		for player, session in sessions do
			local stale = os.clock() - session.LastWrite >= LOCK_REFRESH_SECONDS
			if session.Status == "Loaded" and (session.Dirty or stale) then
				task.spawn(save, player, session, false)
			end
		end
	end
end)

-- Server shutting down: save everyone in parallel and wait (within the limit).
game:BindToClose(function()
	closing = true
	for player, session in sessions do
		task.spawn(save, player, session, true)
	end
	local deadline = os.clock() + CLOSE_TIMEOUT_SECONDS
	while busy > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

return DataService
