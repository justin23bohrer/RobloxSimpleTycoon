-- CookiePartyFinale (client only, ModuleScript)
-- The Cookie Party's finale explosion, played by CalebEventUI.client.luau on
-- Celebration -> TrophyClaim (only for players who saw the party live):
-- Config.CookiePartyFinaleCookies cookies burst out of Caleb's head in all
-- directions, arc down with gravity, spin, bounce on the ground and fade;
-- plus a crumb + sparkle ParticleEmitter burst, a quick glowing ball and an
-- expanding shockwave ring. After Config.CookiePartyFinaleSeconds (~2.5 s)
-- everything is gone: the Heartbeat is disconnected, the folder, ring and
-- emitters are destroyed, and the pooled cookie parts are parked
-- (Parent = nil) to be reused by the next finale.
--
-- Looks only: client-local parts (never replicated), anchored, no
-- collisions, no touches, invisible to raycasts. Never talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CookiePartyFinale = {}

-- Look (presentation only)
local MAX_COOKIES = 80
local DIAMETER = 3
local THICKNESS = 0.6
local FLAT = CFrame.Angles(0, 0, math.pi / 2) -- a Cylinder's round faces are on X
local DOUGH = Color3.fromRGB(214, 160, 90)
local GOLDEN = Color3.fromRGB(255, 200, 60)
local CHIP = Color3.fromRGB(70, 40, 20)
local CHIP_SPOTS = { Vector3.new(0.6, 0, 0.4), Vector3.new(-0.6, 0, 0.5), Vector3.new(0.1, 0, -0.7) }
local RING_COLOR = Color3.fromRGB(255, 220, 120)
local FADE_SECONDS = 0.6
local BOUNCE = 0.45 -- vertical speed kept on a bounce
local FRICTION = 0.7 -- horizontal speed kept on a bounce

type Cookie = {
	Parts: { BasePart },
	Offsets: { CFrame },
	Position: Vector3,
	Velocity: Vector3,
	Rotation: CFrame,
	Axis: Vector3,
	Spin: number,
}

local pool: { Cookie } = {}
local playing = false

local function decorate(part: BasePart, color: Color3)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
end

-- One cookie: a disc + 3 chips (built once, reused).
local function buildCookie(golden: boolean): Cookie
	local disc = Instance.new("Part")
	disc.Name = "FinaleCookie"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(THICKNESS, DIAMETER, DIAMETER)
	decorate(disc, if golden then GOLDEN else DOUGH)
	local parts, offsets = { disc :: BasePart }, { FLAT }
	for _, spot in CHIP_SPOTS do
		local chip = Instance.new("Part")
		chip.Name = "Chip"
		chip.Shape = Enum.PartType.Ball
		chip.Size = Vector3.new(0.55, 0.55, 0.55)
		decorate(chip, CHIP)
		table.insert(parts, chip)
		table.insert(offsets, CFrame.new(spot + Vector3.new(0, THICKNESS / 2, 0)))
	end
	return {
		Parts = parts,
		Offsets = offsets,
		Position = Vector3.zero,
		Velocity = Vector3.zero,
		Rotation = CFrame.identity,
		Axis = Vector3.yAxis,
		Spin = 0,
	}
end

-- Where Caleb's head is (or a guess from the pedestal if it streamed out),
-- and the ground height around the statue.
local function findOrigin(statue: Instance): (Vector3, number)
	local base = statue:FindFirstChild("PedestalBase")
	local head = statue:FindFirstChild("Head")
	local ground = if base and base:IsA("BasePart") then base.Position.Y - base.Size.Y / 2 else nil
	local origin
	if head and head:IsA("BasePart") then
		origin = head.Position
	elseif base and base:IsA("BasePart") then
		origin = base.Position + Vector3.new(0, 25, 0)
	else
		origin = (statue :: PVInstance):GetPivot().Position + Vector3.new(0, 25, 0)
	end
	return origin, ground or origin.Y - 25
end

local function tween(instance: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

-- The glowing ball, the shockwave ring and the particle bursts. All live in
-- `folder` (destroyed at the end).
local function burst(folder: Folder, origin: Vector3, ground: number)
	local ball = Instance.new("Part")
	ball.Name = "FinaleBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(4, 4, 4)
	ball.CFrame = CFrame.new(origin)
	decorate(ball, Color3.fromRGB(255, 245, 220))
	ball.Material = Enum.Material.Neon
	ball.Transparency = 0.25
	ball.Parent = folder
	tween(ball, 0.45, { Size = Vector3.new(34, 34, 34), Transparency = 1 })

	local ring = Instance.new("Part")
	ring.Name = "FinaleRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 6, 6)
	ring.CFrame = CFrame.new(origin.X, ground + 1, origin.Z) * FLAT
	decorate(ring, RING_COLOR)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.35
	ring.Parent = folder
	tween(ring, 0.9, { Size = Vector3.new(0.4, 120, 120), Transparency = 1 })

	local holder = Instance.new("Part")
	holder.Name = "FinaleEmitters"
	holder.Size = Vector3.new(1, 1, 1)
	holder.CFrame = CFrame.new(origin)
	decorate(holder, DOUGH)
	holder.Transparency = 1
	holder.Parent = folder

	local crumbs = Instance.new("ParticleEmitter")
	crumbs.Enabled = false
	crumbs.Color = ColorSequence.new(DOUGH, Color3.fromRGB(140, 90, 45))
	crumbs.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.4) })
	crumbs.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	crumbs.Lifetime = NumberRange.new(0.8, 1.6)
	crumbs.Speed = NumberRange.new(25, 60)
	crumbs.SpreadAngle = Vector2.new(180, 180)
	crumbs.Acceleration = Vector3.new(0, -60, 0)
	crumbs.Drag = 1
	crumbs.RotSpeed = NumberRange.new(-300, 300)
	crumbs.Parent = holder

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Enabled = false
	sparkles.Color = ColorSequence.new(GOLDEN, Color3.fromRGB(255, 255, 255))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Lifetime = NumberRange.new(0.6, 1.2)
	sparkles.Speed = NumberRange.new(35, 80)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Drag = 2
	sparkles.Parent = holder

	crumbs:Emit(90)
	sparkles:Emit(60)
end

-- Plays once; a second call while one is running is ignored.
function CookiePartyFinale.Play(statue: Instance)
	if playing then
		return
	end
	playing = true
	local count = math.clamp(Config.CookiePartyFinaleCookies, 0, MAX_COOKIES)
	local total = math.max(Config.CookiePartyFinaleSeconds, FADE_SECONDS)
	local gravity = Vector3.new(0, -Config.CookiePartyFinaleGravity, 0)
	local origin, ground = findOrigin(statue)
	local floor = ground + THICKNESS / 2

	local folder = Instance.new("Folder")
	folder.Name = "CookiePartyFinale"
	folder.Parent = Workspace

	while #pool < count do
		table.insert(pool, buildCookie(#pool % 6 == 0)) -- every 6th is golden
	end
	local allParts: { BasePart } = {}
	local cookies: { Cookie } = {}
	for i = 1, count do
		local c = pool[i]
		-- Outward in every direction, mostly upward so they arc.
		local angle = math.random() * 2 * math.pi
		local up = 0.15 + math.random() * 0.85
		local dir = Vector3.new(math.cos(angle), up, math.sin(angle)).Unit
		local speed = Config.CookiePartyFinaleSpeedMin
			+ math.random() * (Config.CookiePartyFinaleSpeedMax - Config.CookiePartyFinaleSpeedMin)
		c.Position = origin + dir * 2
		c.Velocity = dir * speed
		c.Rotation = CFrame.Angles(math.random() * 6.3, math.random() * 6.3, math.random() * 6.3)
		c.Axis = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
		c.Spin = 6 + math.random() * 10
		local frame = CFrame.new(c.Position) * c.Rotation
		for j, part in c.Parts do
			part.CFrame = frame * c.Offsets[j]
			part.Transparency = 0
			part.Parent = folder
			table.insert(allParts, part)
		end
		table.insert(cookies, c)
	end
	burst(folder, origin, ground)

	local frames: { CFrame } = table.create(#allParts)
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - started
		if t >= total then
			connection:Disconnect()
			for _, part in allParts do
				part.Parent = nil -- parked in the pool
			end
			folder:Destroy()
			playing = false
			return
		end
		dt = math.min(dt, 1 / 20)
		local fade = math.clamp((t - (total - FADE_SECONDS)) / FADE_SECONDS, 0, 1)
		local k = 0
		for _, c in cookies do
			local v = c.Velocity + gravity * dt
			local p = c.Position + v * dt
			if p.Y < floor and v.Y < 0 then
				p = Vector3.new(p.X, floor, p.Z)
				v = Vector3.new(v.X * FRICTION, -v.Y * BOUNCE, v.Z * FRICTION)
				c.Spin *= FRICTION
			end
			c.Velocity, c.Position = v, p
			c.Rotation = c.Rotation * CFrame.fromAxisAngle(c.Axis, c.Spin * dt)
			local frame = CFrame.new(p) * c.Rotation
			for i, part in c.Parts do
				k += 1
				frames[k] = frame * c.Offsets[i]
				if fade > 0 then
					part.Transparency = fade
				end
			end
		end
		Workspace:BulkMoveTo(allParts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return CookiePartyFinale
