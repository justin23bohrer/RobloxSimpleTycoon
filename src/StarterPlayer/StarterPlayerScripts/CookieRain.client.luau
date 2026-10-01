-- CookieRain (client only)
-- While Caleb's CalebState is "Celebration", chocolate chip cookies rain
-- from the sky within Config.CookieRainRadius of the statue, more of them
-- near the local player. They spin and wobble as they fall, then give a
-- little bounce and puff where they land and fade away.
--
-- Visual only: no rewards, no remotes, nothing on the server. Everything
-- lives in a client-local Workspace folder (created by this LocalScript, so it
-- is never replicated). Cookies come from a pool of at most
-- Config.CookieRainMaxCookies that is reused, never rebuilt per cookie; one
-- Heartbeat connection moves them all (BulkMoveTo) and exists only while
-- cookies are falling. When the celebration ends no new cookies spawn; the
-- falling ones land and fade, then the folder, pool and connection are gone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local CookieRainLook = require(script.Parent:WaitForChild("CookieRainLook"))

local player = Players.LocalPlayer
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")

-- Looks only; not gameplay tuning.
local WOBBLE_STUDS = 1.2 -- sideways sway while falling
local TILT = 0.6 -- radians the cookie rocks while falling
local BOUNCE_SECONDS = 0.35
local BOUNCE_STUDS = 1.2
local FADE_SECONDS = 0.5
local PUFF_COUNT = 6
local RAY_HEIGHT = 300 -- landing raycasts start this far above the statue

type Slot = {
	Cookie: CookieRainLook.Cookie,
	Active: boolean,
	X: number,
	Z: number,
	Y: number,
	LandY: number,
	Speed: number,
	Spin: number,
	Phase: number,
	Age: number,
	LandedAt: number?, -- Age when it landed
}

local folder: Folder? = nil
local puffAttachment: Attachment? = nil
local puff: ParticleEmitter? = nil
local slots: { Slot } = {}
local heartbeat: RBXScriptConnection? = nil
local raining = false
local spawnBudget = 0
local center = statue:GetPivot().Position -- replaced by updateCenter()
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

-- Statue center at ground level (bottom of PedestalBase). If it is streamed
-- out, keep the last known center (it never moves).
local function updateCenter()
	local base = statue:FindFirstChild("PedestalBase")
	if base and base:IsA("BasePart") then
		center = base.Position - Vector3.new(0, base.Size.Y / 2, 0)
	end
end

-- A random point (X, Z) in the rain circle, often near the local player.
local function pickSpot(): (number, number)
	local radius = Config.CookieRainRadius
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and math.random() < Config.CookieRainNearPlayerShare then
		local angle = math.random() * 2 * math.pi
		local dist = Config.CookieRainNearPlayerRadius * math.sqrt(math.random())
		local x = root.Position.X + math.cos(angle) * dist
		local z = root.Position.Z + math.sin(angle) * dist
		if (Vector2.new(x, z) - Vector2.new(center.X, center.Z)).Magnitude <= radius then
			return x, z
		end
	end
	local angle = math.random() * 2 * math.pi
	local dist = radius * math.sqrt(math.random()) -- uniform over the disc
	return center.X + math.cos(angle) * dist, center.Z + math.sin(angle) * dist
end

-- Height of the first visible surface under (x, z). Invisible parts (spawn
-- areas, barriers) are skipped so cookies never sit on thin air.
local function landingY(x: number, z: number): number
	local origin = Vector3.new(x, center.Y + RAY_HEIGHT, z)
	for _ = 1, 3 do
		local hit = Workspace:Raycast(origin, Vector3.new(0, center.Y - RAY_HEIGHT - origin.Y, 0), rayParams)
		if not hit then
			break
		end
		if hit.Instance.Transparency < 0.95 then
			return hit.Position.Y
		end
		origin = hit.Position - Vector3.new(0, 0.05, 0)
	end
	return center.Y -- nothing visible (or not streamed in): ground level
end

local function spawnCookie(): boolean
	local slot: Slot? = nil
	for _, candidate in slots do
		if not candidate.Active then
			slot = candidate
			break
		end
	end
	if not slot then
		if #slots >= Config.CookieRainMaxCookies or not folder then
			return false
		end
		slot = { Cookie = CookieRainLook.Build(folder :: Folder) } :: any
		table.insert(slots, slot :: Slot)
	end
	local s = slot :: Slot
	s.X, s.Z = pickSpot()
	s.LandY = landingY(s.X, s.Z) + CookieRainLook.HalfThickness
	s.Y = s.LandY + Config.CookieRainHeight * (0.8 + math.random() * 0.4)
	s.Speed = Config.CookieRainFallSpeed * (0.8 + math.random() * 0.4)
	s.Spin = Config.CookieRainSpinSpeed * (0.5 + math.random()) * (if math.random() < 0.5 then -1 else 1)
	s.Phase = math.random() * 2 * math.pi
	s.Age = 0
	s.LandedAt = nil
	s.Active = true
	CookieRainLook.SetTransparency(s.Cookie, 0)
	return true
end

local function cleanup()
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	if folder then
		folder:Destroy() -- the whole pool
		folder = nil
	end
	if puffAttachment then
		puffAttachment:Destroy()
		puffAttachment, puff = nil, nil
	end
	slots = {}
	spawnBudget = 0
end

-- The frame (position + rotation) of a cookie this frame; may land it.
local function step(s: Slot, dt: number): CFrame?
	s.Age += dt
	if not s.LandedAt then
		s.Y -= s.Speed * dt
		if s.Y <= s.LandY then
			s.Y = s.LandY
			s.LandedAt = s.Age
			if puff and puffAttachment then
				puffAttachment.WorldPosition = Vector3.new(s.X, s.LandY, s.Z)
				puff:Emit(PUFF_COUNT)
			end
		else
			local t = s.Age + s.Phase
			local sway = Vector3.new(math.sin(t * 2) * WOBBLE_STUDS, 0, math.cos(t * 1.6) * WOBBLE_STUDS)
			return CFrame.new(Vector3.new(s.X, s.Y, s.Z) + sway)
				* CFrame.Angles(0, s.Age * s.Spin, 0)
				* CFrame.Angles(math.sin(t * 3) * TILT, 0, math.cos(t * 2.4) * TILT)
		end
	end
	local since = s.Age - (s.LandedAt :: number)
	if since >= BOUNCE_SECONDS + FADE_SECONDS then
		s.Active = false
		CookieRainLook.SetTransparency(s.Cookie, 1)
		return nil
	end
	local hop = 0
	if since < BOUNCE_SECONDS then
		local k = since / BOUNCE_SECONDS
		hop = math.sin(k * math.pi) * BOUNCE_STUDS * (1 - k * 0.5)
	else
		CookieRainLook.SetTransparency(s.Cookie, (since - BOUNCE_SECONDS) / FADE_SECONDS)
	end
	return CFrame.new(s.X, s.LandY + hop, s.Z) * CFrame.Angles(0, (s.LandedAt :: number) * s.Spin, 0)
end

local function onHeartbeat(dt: number)
	if raining then
		updateCenter()
		spawnBudget = math.min(spawnBudget + dt * Config.CookieRainPerSecond, 5)
		while spawnBudget >= 1 do
			spawnBudget -= 1
			if not spawnCookie() then
				spawnBudget = 0 -- pool full: skip, don't save up a burst
			end
		end
	end

	local parts, frames = {}, {}
	local anyActive = false
	for _, s in slots do
		if s.Active then
			local frame = step(s, dt)
			if frame then
				anyActive = true
				for i, part in s.Cookie.Parts do
					table.insert(parts, part)
					table.insert(frames, frame * s.Cookie.Offsets[i])
				end
			end
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	if not raining and not anyActive then
		cleanup()
	end
end

local function start()
	raining = true
	if heartbeat then
		return -- still finishing the last rain: keep going
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = "CookieRain"
	puffAttachment, puff = CookieRainLook.BuildPuff(Workspace.Terrain)
	folder = newFolder
	rayParams.FilterDescendantsInstances = { newFolder }
	newFolder.Parent = Workspace
	updateCenter()
	heartbeat = RunService.Heartbeat:Connect(onHeartbeat)
end

local function onStateChanged()
	if CalebEvent.GetState(statue) == CalebEvent.State.Celebration then
		start()
	else
		raining = false -- falling cookies finish; onHeartbeat cleans up
	end
end

statue:GetAttributeChangedSignal(CalebEvent.Attr.State):Connect(onStateChanged)
onStateChanged() -- joined mid-celebration
