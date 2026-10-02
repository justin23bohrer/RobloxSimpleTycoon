-- CookiePartyService (server only)
-- The Cookie Party's collectable cookies and rewards (CalebState
-- "Celebration"). It decides every cookie (type, value, landing spot,
-- timing), keeps them in a server table only (no parts), validates every
-- collect, pays through EconomyService, and pays the final reward once per
-- cycle when the party ends. Clients only draw the cookies.
-- See ARCHITECTURE.md "Cookie Party (contract)".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)
local CalebCycle = require(script.Parent.CalebCycle)
local CookiePartySpawner = require(script.Parent.CookiePartySpawner)
local EconomyService = require(script.Parent.EconomyService)

-- Collect checks (contract): time slack around LandAt / ExpiresAt, extra
-- horizontal studs for lag, and the most vertical studs from the cookie.
local EARLY_SLACK = 0.3
local LATE_SLACK = 0.5
local RADIUS_SLACK = 2
local MAX_VERTICAL = 25

local PlayerAttr = CookieParty.PlayerAttr
local State = CalebEvent.State

local CookiePartyService = {}

local statue: Instance? = nil
local spawnRemote: RemoteEvent
local collectedRemote: RemoteEvent
local finaleRemote: RemoteEvent

local partyCycle: string? = nil -- cycle id of the running party (nil = none)
local finishedCycle: string? = nil -- last cycle whose party ended (never restarts or pays twice)
local alive: { [number]: CookieParty.Spawn } = {}
local aliveCount = 0
local nextId = 0
local budget = 0 -- fractional cookies owed to the spawn rate
-- Per-player collect rate limit: requests counted in 1-second buckets.
local buckets: { [Player]: { Start: number, Count: number } } = {}

local function resetPlayer(player: Player)
	player:SetAttribute(PlayerAttr.Earned, 0)
	player:SetAttribute(PlayerAttr.Collected, 0)
end

-- Removes a cookie and tells everyone it is gone (userId 0).
local function removeCookie(id: number)
	local cookie = alive[id]
	if cookie then
		alive[id] = nil
		aliveCount -= 1
		collectedRemote:FireAllClients(id, 0, 0, cookie.Type)
	end
end

local function spawnTick(dt: number)
	local s = statue :: Instance
	local now = Workspace:GetServerTimeNow()
	for id, cookie in alive do
		if now > cookie.ExpiresAt + LATE_SLACK then
			removeCookie(id)
		end
	end

	-- A cookie that could not land before the party ends is never spawned.
	local timeLeft = CalebEvent.TimeLeft(s)
	if timeLeft <= Config.CookiePartyFallSeconds then
		return
	end
	local phase = CookieParty.GetPhase(timeLeft)
	local extraPlayers = math.max(0, #Players:GetPlayers() - 1)
	local rate = Config.CookiePartySpawnPerSecond[phase] * (1 + Config.CookiePartySpawnPerExtraPlayer * extraPlayers)
	budget += rate * dt
	if aliveCount >= Config.CookiePartyMaxAlive then
		budget = math.min(budget, 1) -- don't save up a burst while full
		return
	end

	CookiePartySpawner.BeginTick()
	local batch: { CookieParty.Spawn } = {}
	while budget >= 1 and aliveCount < Config.CookiePartyMaxAlive do
		budget -= 1
		local position = CookiePartySpawner.PickSpot()
		if position then
			nextId += 1
			local landAt = now + Config.CookiePartyFallSeconds
			local cookie: CookieParty.Spawn = {
				Id = nextId,
				Type = CookiePartySpawner.PickType(phase),
				Position = position,
				LandAt = landAt,
				ExpiresAt = landAt + Config.CookiePartyLifetime,
				FromCaleb = math.random() < Config.CookiePartyFromCalebShare[phase],
			}
			alive[nextId] = cookie
			aliveCount += 1
			table.insert(batch, cookie)
		end
	end
	if #batch > 0 then
		spawnRemote:FireAllClients(batch)
	end
end

local function startParty(cycleId: string)
	if partyCycle == cycleId or finishedCycle == cycleId then
		return
	end
	partyCycle = cycleId
	budget = 0
	for _, player in Players:GetPlayers() do
		resetPlayer(player)
	end
	task.spawn(function()
		local dt = 0
		while partyCycle == cycleId do
			spawnTick(dt)
			dt = task.wait(Config.CookiePartyTickSeconds)
		end
	end)
end

-- Ends the party; pays the finale only on Celebration -> TrophyClaim of the
-- same cycle, and at most once per cycle.
local function endParty(state: string, cycleId: string)
	local endedCycle = partyCycle
	partyCycle = nil -- stops the spawn loop
	for id in alive do
		removeCookie(id)
	end
	alive, aliveCount, budget = {}, 0, 0
	if state ~= State.TrophyClaim or endedCycle ~= cycleId or finishedCycle == cycleId then
		return
	end
	finishedCycle = cycleId
	local reward = Config.CookiePartyFinalReward
	for _, player in Players:GetPlayers() do
		if reward <= 0 then
			finaleRemote:FireClient(player, 0)
		elseif EconomyService.AddCash(player, reward) then
			finaleRemote:FireClient(player, reward)
		end
	end
end

local function onStateChanged(state: string, cycleId: string)
	if state == State.Celebration then
		startParty(cycleId)
	elseif partyCycle then
		endParty(state, cycleId)
	end
end

-- True if the player is still under the collect rate limit (counts this request).
local function allowRequest(player: Player): boolean
	local now = os.clock()
	local bucket = buckets[player]
	if not bucket or now - bucket.Start >= 1 then
		bucket = { Start = now, Count = 0 }
		buckets[player] = bucket
	end
	bucket.Count += 1
	return bucket.Count <= Config.CookiePartyMaxCollectsPerSecond
end

-- CookiePartyCollect: (player, id). Everything is untrusted; invalid
-- requests are ignored silently.
local function onCollect(player: Player, id: unknown)
	if not partyCycle or CalebCycle.GetState() ~= State.Celebration then
		return
	end
	if not allowRequest(player) then
		return
	end
	if typeof(id) ~= "number" or id ~= math.floor(id) then
		return -- also rejects NaN (inf is never an alive id)
	end
	local cookie = alive[id]
	if not cookie then
		return
	end
	local now = Workspace:GetServerTimeNow()
	if now < cookie.LandAt - EARLY_SLACK or now > cookie.ExpiresAt + LATE_SLACK then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart")) or not humanoid or humanoid.Health <= 0 then
		return
	end
	local offset = root.Position - cookie.Position
	local radius = Config.CookiePartyTypes[cookie.Type].CollectRadius + RADIUS_SLACK
	if Vector2.new(offset.X, offset.Z).Magnitude > radius or math.abs(offset.Y) > MAX_VERTICAL then
		return
	end

	-- First valid collect wins. Nothing here yields, so no one else can take
	-- it in between; if the player has no cash data yet, it stays available.
	local value = Config.CookiePartyTypes[cookie.Type].Value
	alive[id] = nil
	if not EconomyService.AddCash(player, value) then
		alive[id] = cookie
		return
	end
	aliveCount -= 1
	player:SetAttribute(PlayerAttr.Earned, (player:GetAttribute(PlayerAttr.Earned) or 0) + value)
	player:SetAttribute(PlayerAttr.Collected, (player:GetAttribute(PlayerAttr.Collected) or 0) + 1)
	collectedRemote:FireAllClients(id, player.UserId, value, cookie.Type)
end

-- Called once by ServerMain after CalebCycle.Start(statue).
function CookiePartyService.Start(statueModel: Instance)
	if statue then
		warn("CookiePartyService.Start: already started")
		return
	end
	statue = statueModel
	spawnRemote = CookieParty.GetRemote(CookieParty.Remote.Spawn)
	collectedRemote = CookieParty.GetRemote(CookieParty.Remote.Collected)
	finaleRemote = CookieParty.GetRemote(CookieParty.Remote.Finale)
	CookiePartySpawner.Setup(statueModel)
	CookieParty.GetRemote(CookieParty.Remote.Collect).OnServerEvent:Connect(onCollect)
	CalebCycle.StateChanged:Connect(onStateChanged)
	-- Started in the middle of a party (unlikely): run the rest of it.
	if CalebCycle.GetState() == State.Celebration then
		startParty(CalebCycle.GetCycleId())
	end
end

-- Join: earnings start at 0; mid-party, the player gets every alive cookie.
function CookiePartyService.OnPlayerAdded(player: Player)
	resetPlayer(player)
	if partyCycle and aliveCount > 0 then
		local batch: { CookieParty.Spawn } = {}
		for _, cookie in alive do
			table.insert(batch, cookie)
		end
		spawnRemote:FireClient(player, batch)
	end
end

function CookiePartyService.OnPlayerRemoving(player: Player)
	buckets[player] = nil
end

return CookiePartyService
