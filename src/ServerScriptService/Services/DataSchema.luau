-- DataSchema (server only)
-- Helper for DataService: the shape of one player's saved data, and how to
-- turn whatever is in the DataStore into that shape safely. Decides nothing
-- about when to load or save (that is DataService).
--
-- Saved record (key "Player_<UserId>" in Config.DataStoreName):
--   Version       number   CURRENT_VERSION
--   Cash          number   cookies, a whole number 0..MAX_CASH
--   Purchases     { [purchaseId]: true }   house purchases (droppers + builds)
--   Trophies      { TrophyRecord }         Caleb trophies, oldest first
--   Equipped      { InstanceId }           equipped trophies, display order
--   SessionJobId  string?  server that has this player's data open (lock)
--   SessionTime   number?  os.time() of that server's last write
--
-- Session fields are DataService's session lock and never leave DataService.
--
-- Version history:
--   1  Purchases + Trophies {Variant, EventId, EarnedAt}
--   2  every trophy gets an InstanceId; Equipped added. Migrating 1 -> 2
--      gives each old trophy a new InstanceId and equips the newest
--      Config.TrophyActiveSlots (what the old Trophy Case showed).
--   3  Cash added (cookies are saved). Migrating 2 -> 3 (or 1 -> 3) gives
--      Config.StartingCash, what every session used to start with.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Purchases = require(script.Parent.Purchases)

local DataSchema = {}

DataSchema.CURRENT_VERSION = 3

local MAX_STRING = 100 -- Variant / EventId
local MAX_INSTANCE_ID = 64
-- Highest cash ever saved or loaded: far above anything playable, and well
-- inside the whole numbers a double (and an IntValue) holds exactly.
local MAX_CASH = 1_000_000_000_000_000

export type TrophyRecord = {
	InstanceId: string, -- unique per earned trophy, never reused
	Variant: string, -- key into Shared/TrophyVariants
	EventId: string, -- the CalebCycleId it was earned in ("" for none)
	EarnedAt: number, -- os.time()
}

export type PlayerData = {
	Version: number,
	Cash: number, -- whole number, 0..MAX_CASH
	Purchases: { [string]: true },
	Trophies: { TrophyRecord },
	Equipped: { string }, -- InstanceIds, unique, owned, <= TrophyActiveSlots
}

-- A new, never reused trophy InstanceId.
function DataSchema.NewInstanceId(): string
	return HttpService:GenerateGUID(false)
end

local function isNonEmptyString(value: any): boolean
	return typeof(value) == "string" and #value > 0 and #value <= MAX_STRING
end

-- True if the value can be a trophy InstanceId (a non-empty string <= 64 chars).
function DataSchema.IsInstanceId(value: any): boolean
	return typeof(value) == "string" and #value > 0 and #value <= MAX_INSTANCE_ID
end

-- Returns a clean copy of one trophy record, or nil if it is not valid (no
-- Variant string, or a bad EarnedAt). A missing or invalid InstanceId gets a
-- new one; a missing EventId becomes "".
function DataSchema.CleanTrophy(record: any): TrophyRecord?
	if typeof(record) ~= "table" then
		return nil
	end
	local earnedAt = record.EarnedAt
	if not isNonEmptyString(record.Variant) then
		return nil
	end
	if typeof(earnedAt) ~= "number" or earnedAt ~= earnedAt or earnedAt < 0 or earnedAt == math.huge then
		return nil -- not a number, NaN, negative, or infinite
	end
	local eventId = record.EventId
	if typeof(eventId) ~= "string" or #eventId > MAX_STRING then
		eventId = ""
	end
	local instanceId = record.InstanceId
	if not DataSchema.IsInstanceId(instanceId) then
		instanceId = DataSchema.NewInstanceId()
	end
	return { InstanceId = instanceId, Variant = record.Variant, EventId = eventId, EarnedAt = earnedAt }
end

-- A safe cash amount from any value: not a number, NaN or infinite ->
-- Config.StartingCash; negative -> 0; fractions are rounded down; anything
-- above MAX_CASH -> MAX_CASH.
function DataSchema.CleanCash(value: any): number
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return Config.StartingCash
	end
	return math.clamp(math.floor(value), 0, MAX_CASH)
end

-- Fresh data for a player who has never saved.
function DataSchema.Default(): PlayerData
	return {
		Version = DataSchema.CURRENT_VERSION,
		Cash = Config.StartingCash,
		Purchases = {},
		Trophies = {},
		Equipped = {},
	}
end

-- The newest `TrophyActiveSlots` trophies' ids, newest first (trophies are
-- oldest first): the old Trophy Case showed exactly these.
local function newestIds(trophies: { TrophyRecord }): { string }
	local ids = {}
	for i = #trophies, math.max(1, #trophies - Config.TrophyActiveSlots + 1), -1 do
		table.insert(ids, trophies[i].InstanceId)
	end
	return ids
end

-- Owned, unique ids from `raw`, in order, at most TrophyActiveSlots.
local function cleanEquipped(raw: any, trophies: { TrophyRecord }): { string }
	local owned = {}
	for _, record in trophies do
		owned[record.InstanceId] = true
	end
	local ids = {}
	if typeof(raw) ~= "table" then
		return ids
	end
	for _, id in ipairs(raw) do
		if #ids >= Config.TrophyActiveSlots then
			break
		end
		if typeof(id) == "string" and owned[id] then
			owned[id] = nil -- each id once
			table.insert(ids, id)
		end
	end
	return ids
end

-- Turns a stored value into clean PlayerData. Returns nil plus a reason when
-- the value must NOT be used or overwritten (not a table, or written by a
-- newer version of the game that this server does not understand).
-- Cash is cleaned with CleanCash (versions before 3 get Config.StartingCash).
-- Unknown purchase ids, bad trophy records, a second trophy for the same
-- EventId, and bad Equipped ids are dropped; a repeated InstanceId gets a
-- new one (the trophy is kept).
function DataSchema.FromStored(raw: any): (PlayerData?, string?)
	if raw == nil then
		return DataSchema.Default(), nil
	end
	if typeof(raw) ~= "table" then
		return nil, `stored value is a {typeof(raw)}, not a table`
	end
	if raw.Version ~= nil and typeof(raw.Version) ~= "number" then
		return nil, "stored Version is not a number"
	end
	if raw.Version and raw.Version > DataSchema.CURRENT_VERSION then
		return nil, `stored Version {raw.Version} is newer than this server's {DataSchema.CURRENT_VERSION}`
	end
	local version = raw.Version or 1 -- treat an unversioned table as version 1

	local data = DataSchema.Default()
	if version >= 3 then
		data.Cash = DataSchema.CleanCash(raw.Cash)
	end -- older saves keep Default's Config.StartingCash (2 -> 3)
	if typeof(raw.Purchases) == "table" then
		for id, owned in raw.Purchases do
			if owned == true and typeof(id) == "string" and Purchases.Get(id) then
				data.Purchases[id] = true
			end
		end
	end
	if typeof(raw.Trophies) == "table" then
		local seenEvents, seenIds = {}, {}
		for _, record in ipairs(raw.Trophies) do
			local clean = DataSchema.CleanTrophy(record)
			if clean and version < 2 then
				clean.InstanceId = DataSchema.NewInstanceId() -- 1 -> 2: every trophy gets a new id
			end
			if clean and (clean.EventId == "" or not seenEvents[clean.EventId]) then
				seenEvents[clean.EventId] = true
				if seenIds[clean.InstanceId] then
					clean.InstanceId = DataSchema.NewInstanceId()
				end
				seenIds[clean.InstanceId] = true
				table.insert(data.Trophies, clean)
			end
		end
	end
	if version < 2 then
		data.Equipped = newestIds(data.Trophies)
	else
		data.Equipped = cleanEquipped(raw.Equipped, data.Trophies)
	end
	return data, nil
end

-- A deep copy for storing (DataService adds the session fields).
function DataSchema.ToStored(data: PlayerData): { [string]: any }
	local purchases = {}
	for id in data.Purchases do
		purchases[id] = true
	end
	return {
		Version = DataSchema.CURRENT_VERSION,
		Cash = DataSchema.CleanCash(data.Cash),
		Purchases = purchases,
		Trophies = DataSchema.CopyTrophies(data.Trophies),
		Equipped = table.clone(data.Equipped),
	}
end

function DataSchema.CopyTrophies(trophies: { TrophyRecord }): { TrophyRecord }
	local copy = {}
	for i, record in trophies do
		copy[i] = table.clone(record)
	end
	return copy
end

return DataSchema
