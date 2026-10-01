-- CalebCycle (server only)
-- Owns the Caleb Full Event state (see Shared/CalebEvent.luau and the
-- "Caleb Full Event (contract)" section of ARCHITECTURE.md):
--   Normal -> Full -> Celebration -> TrophyClaim -> (reset) -> Normal.
--
-- * The shared cookie total, each player's contribution (keyed by UserId, so
--   leaving and rejoining the same server keeps it), and who claimed this
--   cycle's trophy live only here. Everything is published as attributes on
--   the statue and on each Player (CalebEvent.Attr / CalebEvent.PlayerAttr).
-- * StatueService spends the cookies and then calls AddCookies. Reaching the
--   goal starts Full; timed states advance with task.delay. Every timer
--   checks the cycle id and state it was started for, so a stale timer can
--   never advance a newer cycle and no transition can happen twice.
-- * The top feeders board (JSON) is published at most every
--   Config.CalebLeaderboardInterval seconds; feeds in between are batched
--   and the last value is always published. A reset publishes right away.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)

local State = CalebEvent.State
local Attr = CalebEvent.Attr
local PlayerAttr = CalebEvent.PlayerAttr

local CalebCycle = {}

type Contribution = { Name: string, Cookies: number }

local statue: Instance? = nil
local state = State.Normal
local cycleId = ""
local goal = 0
local eaten = 0
local contributions: { [number]: Contribution } = {}
local claimed: { [number]: true } = {}

local changed = Instance.new("BindableEvent")
-- Fires (state, cycleId) after every transition (not on Start).
CalebCycle.StateChanged = changed.Event

-- Leaderboard throttle.
local lastPublish = -math.huge
local publishPending = false

local function publishBoard()
	publishPending = false
	lastPublish = os.clock()
	if not statue then
		return
	end
	local rows = {}
	for userId, entry in contributions do
		if entry.Cookies > 0 then
			table.insert(rows, { UserId = userId, Name = entry.Name, Cookies = entry.Cookies })
		end
	end
	table.sort(rows, function(a, b)
		if a.Cookies ~= b.Cookies then
			return a.Cookies > b.Cookies
		end
		return a.UserId < b.UserId
	end)
	for i = #rows, Config.CalebLeaderboardSize + 1, -1 do
		rows[i] = nil
	end
	statue:SetAttribute(Attr.TopFeeders, HttpService:JSONEncode(rows))
end

-- Publishes now if the interval has passed, otherwise once when it has.
local function requestBoard()
	if publishPending then
		return
	end
	local remaining = Config.CalebLeaderboardInterval - (os.clock() - lastPublish)
	if remaining <= 0 then
		publishBoard()
	else
		publishPending = true
		task.delay(remaining, publishBoard)
	end
end

local function setPlayerAttributes(player: Player)
	local entry = contributions[player.UserId]
	player:SetAttribute(PlayerAttr.Fed, if entry then entry.Cookies else 0)
	player:SetAttribute(PlayerAttr.TrophyClaimed, claimed[player.UserId] == true)
end

local advance: () -> ()

-- Enters a state, publishes it, and starts its timer (if it has one).
local function enter(newState: string)
	local s = statue :: Instance
	state = newState
	local seconds = CalebEvent.Duration(newState)
	s:SetAttribute(Attr.StateEndsAt, if seconds > 0 then Workspace:GetServerTimeNow() + seconds else 0)
	s:SetAttribute(Attr.State, newState)
	if seconds > 0 then
		local forCycle, forState = cycleId, newState
		task.delay(seconds, function()
			if cycleId == forCycle and state == forState then
				advance()
			end
		end)
	end
end

-- Starts a fresh cycle: total 0, no contributions or claims, new id, Normal.
local function newCycle()
	local s = statue :: Instance
	cycleId = HttpService:GenerateGUID(false)
	goal = CalebEvent.MaxCookies()
	eaten = 0
	contributions = {}
	claimed = {}
	s:SetAttribute(Attr.CycleId, cycleId)
	s:SetAttribute(Attr.MaxCookies, goal)
	s:SetAttribute(Attr.CookiesEaten, 0)
	for _, player in Players:GetPlayers() do
		setPlayerAttributes(player)
	end
	publishBoard()
	enter(State.Normal)
end

advance = function()
	if state == State.Full then
		enter(State.Celebration)
	elseif state == State.Celebration then
		enter(State.TrophyClaim)
	elseif state == State.TrophyClaim then
		newCycle()
	else
		return
	end
	changed:Fire(state, cycleId)
end

-- Called once by ServerMain with Workspace.Map.Statue.
function CalebCycle.Start(statueModel: Instance)
	if statue then
		warn("CalebCycle.Start: already started")
		return
	end
	statue = statueModel
	newCycle()
end

function CalebCycle.GetState(): string
	return state
end

function CalebCycle.GetCycleId(): string
	return cycleId
end

-- True only in Normal (and after Start) with room left under the goal.
function CalebCycle.CanFeed(): boolean
	return statue ~= nil and state == State.Normal and eaten < goal
end

-- Called by StatueService after EconomyService.TrySpend succeeded. Records
-- the contribution and starts Full when the goal is reached. StatueService
-- already capped cookies to the room left; this caps again to be safe.
function CalebCycle.AddCookies(player: Player, cookies: number)
	if not CalebCycle.CanFeed() or typeof(cookies) ~= "number" or cookies ~= cookies or cookies < 1 then
		return
	end
	cookies = math.min(math.floor(cookies), goal - eaten)

	local entry = contributions[player.UserId]
	if not entry then
		entry = { Name = player.DisplayName, Cookies = 0 }
		contributions[player.UserId] = entry
	end
	entry.Name = player.DisplayName
	entry.Cookies += cookies
	eaten += cookies

	local s = statue :: Instance
	s:SetAttribute(Attr.CookiesEaten, eaten)
	player:SetAttribute(PlayerAttr.Fed, entry.Cookies)
	requestBoard()

	if eaten >= goal then
		enter(State.Full)
		changed:Fire(state, cycleId)
	end
end

-- Cookies this user fed Caleb in the current cycle.
function CalebCycle.GetContribution(userId: number): number
	local entry = contributions[userId]
	return if entry then entry.Cookies else 0
end

-- True during TrophyClaim for a user who fed this cycle and hasn't claimed.
function CalebCycle.IsEligible(userId: number): boolean
	return state == State.TrophyClaim and CalebCycle.GetContribution(userId) > 0 and not claimed[userId]
end

-- Records that this user claimed this cycle's trophy (cleared on reset).
function CalebCycle.MarkTrophyClaimed(userId: number)
	if not CalebCycle.IsEligible(userId) then
		return
	end
	claimed[userId] = true
	local player = Players:GetPlayerByUserId(userId)
	if player then
		player:SetAttribute(PlayerAttr.TrophyClaimed, true)
	end
end

-- Called by ServerMain on join: restores CalebFed / CalebTrophyClaimed for a
-- player who left and rejoined during the same cycle (0 / false otherwise).
function CalebCycle.OnPlayerAdded(player: Player)
	setPlayerAttributes(player)
end

return CalebCycle
