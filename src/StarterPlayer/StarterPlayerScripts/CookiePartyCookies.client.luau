-- CookiePartyCookies (client only)
-- Draws the Cookie Party's collectable cookies and asks the server to collect
-- them. The server (CookiePartyService) decides every cookie (CookiePartySpawn)
-- and every collect (CookiePartyCollected); this script only draws what it
-- was sent, fires CookiePartyCollect(id) once per cookie when the local
-- character gets close, and plays the feedback.
--
-- Each cookie falls from the sky (or arcs out of Caleb's mouth when
-- FromCaleb) and touches down exactly at LandAt, bounces, then bobs and spins
-- over a glowing beacon, blinks for its last moments and vanishes at
-- ExpiresAt. Collected by you: pop + burst + "+50" + sound + earnings counter;
-- by someone else: a puff; expired: a quick fade. The movement is in
-- CookiePartyMotion, the parts in CookiePartyLook, the effects in
-- CookiePartyFeedback, the earnings counter in CookiePartyHUD.
--
-- Cookies are pooled parts (CookiePartyLook) in a client-local
-- Workspace.CookiePartyCookies folder, all moved by one Heartbeat with one
-- BulkMoveTo, only while the party runs. When Celebration ends everything is
-- removed (a pop already playing finishes first, at most CLEANUP_GRACE s).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)
local Look = require(script.Parent:WaitForChild("CookiePartyLook"))
local Feedback = require(script.Parent:WaitForChild("CookiePartyFeedback"))
local HUD = require(script.Parent:WaitForChild("CookiePartyHUD"))
local Motion = require(script.Parent:WaitForChild("CookiePartyMotion"))

local player = Players.LocalPlayer
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")
local spawnRemote = CookieParty.GetRemote(CookieParty.Remote.Spawn)
local collectRemote = CookieParty.GetRemote(CookieParty.Remote.Collect)
local collectedRemote = CookieParty.GetRemote(CookieParty.Remote.Collected)

-- Not tuning: looks, or mirrors of the server's checks (ARCHITECTURE.md).
local CLEANUP_GRACE = 0.6
local COLLECT_EARLY = 0.3 -- the server accepts from LandAt - 0.3
local COLLECT_VERTICAL = 20 -- the server allows 25
local QUEUE_MAX = 100

type Live = Motion.Live

local partyOn = false
local folder: Folder? = nil
local heartbeat: RBXScriptConnection? = nil
local stoppedAt = 0
local cookies: { [number]: Live } = {}
local pools: { [string]: { Look.Cookie } } = {}
local built = 0
local queued: { any } = {} -- batches that came just before the state did
local collectBudget = 0
local combo, lastCollect = 0, 0

local function getRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function release(id: number)
	local c = cookies[id]
	if not c then
		return
	end
	cookies[id] = nil
	Look.SetActive(c.Cookie, false)
	local pool = pools[c.Cookie.Type]
	if not pool then
		pool = {}
		pools[c.Cookie.Type] = pool
	end
	table.insert(pool, c.Cookie)
end

local function addCookie(s: any, now: number, mouth: () -> Vector3)
	if typeof(s) ~= "table" or typeof(s.Id) ~= "number" or typeof(s.Position) ~= "Vector3" then
		return
	end
	if cookies[s.Id] or typeof(s.LandAt) ~= "number" or typeof(s.ExpiresAt) ~= "number" or now >= s.ExpiresAt then
		return
	end
	local cookieType = if typeof(s.Type) == "string" then s.Type else "Normal"
	local pool = pools[Look.Kind(cookieType)]
	local cookie = pool and table.remove(pool)
	if not cookie then
		if built >= Config.CookiePartyMaxAlive * 2 or not folder then
			return -- safety cap: the server never has this many alive
		end
		built += 1
		cookie = Look.Build(cookieType, folder :: Folder)
	end
	Look.SetActive(cookie, true)
	local from = if s.FromCaleb == true then mouth() else nil
	cookies[s.Id] = Motion.New(s, cookie, from, now)
end

local function addBatch(batch: { any }, now: number)
	local mouth: Vector3? = nil
	local function getMouth(): Vector3
		mouth = mouth or Motion.MouthPosition(statue)
		return mouth :: Vector3
	end
	for _, s in batch do
		addCookie(s, now, getMouth)
	end
end

-- Asks the server for every cookie the local character is close enough to,
-- once per cookie, and at most ClientCollectsPerSecond.
local function tryCollect(now: number, dt: number, rootPos: Vector3)
	local rate = Config.CookiePartyClientCollectsPerSecond
	collectBudget = math.min(collectBudget + dt * rate, 3)
	for id, c in cookies do
		if collectBudget < 1 then
			return
		end
		if not c.Asked and not c.Ending and now >= c.LandAt - COLLECT_EARLY and now < c.ExpiresAt then
			local info = Config.CookiePartyTypes[c.Type]
			local radius = (if info then info.CollectRadius else 6) - Config.CookiePartyClientCollectMargin
			local dx, dz = rootPos.X - c.Ground.X, rootPos.Z - c.Ground.Z
			if dx * dx + dz * dz <= radius * radius and math.abs(rootPos.Y - c.Ground.Y) <= COLLECT_VERTICAL then
				c.Asked, c.AskedAt = true, now
				collectBudget -= 1
				collectRemote:FireServer(id)
			end
		end
	end
end

local function teardown()
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	if folder then
		folder:Destroy() -- every pooled cookie
		folder = nil
	end
	cookies, pools, built = {}, {}, 0
	Feedback.Teardown()
end

local function onHeartbeat(dt: number)
	local now = Workspace:GetServerTimeNow()
	local root = getRoot()
	local rootPos = root and root.Position
	local parts, frames = {}, {}
	local any = false
	for id, c in cookies do
		local frame, groundFrame = Motion.Step(c, now, dt, rootPos)
		if frame then
			any = true
			Look.AddFrames(c.Cookie, frame, groundFrame, parts, frames)
		else
			release(id)
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	if partyOn and rootPos then
		tryCollect(now, dt, rootPos)
	elseif not partyOn and (not any or os.clock() - stoppedAt > CLEANUP_GRACE) then
		teardown()
	end
end

local function earned(): number
	local value = player:GetAttribute(CookieParty.PlayerAttr.Earned)
	return if typeof(value) == "number" then value else 0
end

local function start()
	if partyOn then
		return
	end
	partyOn = true
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "CookiePartyCookies"
		newFolder.Parent = Workspace
		folder = newFolder
		Feedback.Setup()
	end
	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(onHeartbeat)
	end
	combo, collectBudget = 0, 0
	HUD.Show(earned())
	local early = queued
	queued = {}
	addBatch(early, Workspace:GetServerTimeNow())
end

local function stop()
	queued = {}
	if not partyOn then
		return
	end
	partyOn = false
	stoppedAt = os.clock()
	HUD.Hide()
	for id, c in cookies do
		if c.Ending ~= "Pop" then
			release(id) -- only pops already playing finish
		end
	end
end

spawnRemote.OnClientEvent:Connect(function(batch: any)
	if typeof(batch) ~= "table" then
		return
	end
	if partyOn then
		addBatch(batch, Workspace:GetServerTimeNow())
	elseif CalebEvent.GetState(statue) ~= CalebEvent.State.TrophyClaim then
		for _, s in batch do -- the state change may replicate a moment later
			if #queued < QUEUE_MAX then
				table.insert(queued, s)
			end
		end
	end
end)

collectedRemote.OnClientEvent:Connect(function(id: any, userId: any, value: any, cookieType: any)
	if not partyOn or typeof(id) ~= "number" then
		return
	end
	local c = cookies[id]
	if userId == player.UserId and userId ~= 0 then
		local clock = os.clock()
		combo = if clock - lastCollect <= Config.CookiePartyComboSeconds then combo + 1 else 1
		lastCollect = clock
		local root = getRoot()
		local at = if c then c.Pos elseif root then root.Position else nil
		if at and typeof(value) == "number" then
			Feedback.Collect(if typeof(cookieType) == "string" then cookieType else "Normal", value, at, combo)
		end
		HUD.Combo(combo)
		if c and c.Ending ~= "Pop" then
			Motion.End(c, "Pop", Workspace:GetServerTimeNow())
		end
	elseif c and not c.Ending then
		if userId == 0 then
			Motion.End(c, "Fade", Workspace:GetServerTimeNow())
		else
			Feedback.Puff(c.Pos, 6) -- someone else got it
			release(id)
		end
	end
end)

player:GetAttributeChangedSignal(CookieParty.PlayerAttr.Earned):Connect(function()
	if partyOn then
		HUD.SetEarned(earned())
	end
end)

local function onStateChanged()
	if CalebEvent.GetState(statue) == CalebEvent.State.Celebration then
		start()
	else
		stop()
	end
end

statue:GetAttributeChangedSignal(CalebEvent.Attr.State):Connect(onStateChanged)
onStateChanged() -- joined mid-party
