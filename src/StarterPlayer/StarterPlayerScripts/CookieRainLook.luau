-- CookieRainLook (client only, ModuleScript)
-- Builds one falling cookie for CookieRain.client: a round golden-brown disc
-- with dark chocolate chips, the same look as the server's cookie drops
-- (DropperService), just a little bigger so it reads from far away.
--
-- Looks only. Every part is anchored and has CanCollide, CanTouch and
-- CanQuery off: no physics, nothing to touch, invisible to raycasts. The
-- parts are not welded; CookieRain moves them all with one BulkMoveTo, using
-- the offsets returned here.

local CookieRainLook = {}

-- Looks only; not gameplay tuning.
-- A Cylinder's round faces are on its X axis, so FLAT turns that axis to
-- point along the cookie frame's Y (the cookie lies flat when the frame is
-- upright).
local THICKNESS = 0.5
local DIAMETER = 2.4
local FLAT = CFrame.Angles(0, 0, math.pi / 2)
local DOUGH_COLOR = Color3.fromRGB(214, 160, 90) -- golden-brown dough (same as drops)
local CHIP_COLOR = Color3.fromRGB(70, 40, 20) -- chocolate (same as drops)
local CHIP_SIZE = Vector3.new(0.45, 0.45, 0.45)
-- Chip spots in the cookie frame's X/Z plane; Side = 1 top face, -1 bottom
-- face (the cookies tumble, so both faces get chips).
local CHIP_SPOTS = {
	{ X = 0.5, Z = 0.35, Side = 1 },
	{ X = -0.55, Z = 0.45, Side = 1 },
	{ X = 0.1, Z = -0.6, Side = 1 },
	{ X = -0.3, Z = -0.2, Side = -1 },
	{ X = 0.45, Z = 0.3, Side = -1 },
}

local PUFF_COLOR = Color3.fromRGB(240, 215, 170) -- crumbly dough dust

CookieRainLook.HalfThickness = THICKNESS / 2

export type Cookie = {
	Parts: { BasePart },
	Offsets: { CFrame }, -- Parts[i].CFrame = cookieFrame * Offsets[i]
}

local function decorate(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 1 -- hidden until CookieRain uses it
end

-- Builds one cookie (hidden) under parent.
function CookieRainLook.Build(parent: Instance): Cookie
	local parts = {}
	local offsets = {}

	local disc = Instance.new("Part")
	disc.Name = "Cookie"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(THICKNESS, DIAMETER, DIAMETER)
	disc.Color = DOUGH_COLOR
	decorate(disc)
	table.insert(parts, disc)
	table.insert(offsets, FLAT)

	for _, spot in CHIP_SPOTS do
		local chip = Instance.new("Part")
		chip.Name = "Chip"
		chip.Shape = Enum.PartType.Ball
		chip.Size = CHIP_SIZE
		chip.Color = CHIP_COLOR
		decorate(chip)
		table.insert(parts, chip)
		table.insert(offsets, CFrame.new(spot.X, spot.Side * THICKNESS / 2, spot.Z))
	end

	for _, part in parts do
		part.Parent = parent
	end
	return { Parts = parts, Offsets = offsets }
end

-- Shows or fades the whole cookie (0 = solid, 1 = invisible).
function CookieRainLook.SetTransparency(cookie: Cookie, transparency: number)
	for _, part in cookie.Parts do
		part.Transparency = transparency
	end
end

-- The landing puff: an Attachment (parent must be Terrain or a BasePart)
-- with a ParticleEmitter that only bursts when told to (Emit). Move the
-- attachment's WorldPosition to a landing spot, then Emit.
function CookieRainLook.BuildPuff(parent: Instance): (Attachment, ParticleEmitter)
	local attachment = Instance.new("Attachment")
	attachment.Name = "CookieRainPuff"
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(PUFF_COLOR)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.4, 0.6)
	emitter.Speed = NumberRange.new(3, 5)
	emitter.SpreadAngle = Vector2.new(80, 80)
	emitter.Acceleration = Vector3.new(0, -4, 0)
	emitter.Rate = 0 -- bursts only
	emitter.Parent = attachment
	attachment.Parent = parent
	return attachment, emitter
end

return CookieRainLook
