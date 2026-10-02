-- PowerVisualsRoot (server only, helper for PowerVisuals)
-- The body power effects that hang off the HumanoidRootPart (names and tags
-- in Shared/PowerLooks). Built here so they replicate to everyone; each
-- client's PowerLooks.client switches them on and plays them.
--
-- * SetTrail(root, walkBonus): bonus > 0 -> attachments SpeedTrailTop /
--   SpeedTrailBottom just behind the back (waist to knees), a SpeedTrail
--   Trail between them (FaceCamera, cyan -> electric blue, fades and tapers;
--   created Enabled = false, tagged PowerSpeedTrail, Strength attribute) and a
--   SpeedBurst emitter (Rate 0: speed lines, emitted by clients). Lifetime,
--   MaxLength and opacity scale with the bonus (Config.TrophySpeedTrail*).
--   bonus <= 0 removes them.
-- * SetJump(root, humanoid, jumpBonus, doubleJump): either on -> one JumpFX
--   attachment at foot level (tagged PowerJumpFX, Strength attribute) with
--   AirGlow (Enabled = false) + JumpBurst (Rate 0) while jumpBonus > 0, and
--   AirBurst (Rate 0) while doubleJump. Both off removes JumpFX.
-- Idempotent: one of each per root; changed values only update properties.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PowerLooks = require(ReplicatedStorage.Shared.PowerLooks)

local PowerVisualsRoot = {}

local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local WHITE = Color3.new(1, 1, 1)
-- Trail ribbon: from just above the waist to about the knees, a little
-- behind the back (the root is 2 x 2 x 1; +Z is behind).
local TRAIL_TOP = Vector3.new(0, 0.7, 0.45)
local TRAIL_BOTTOM = Vector3.new(0, -0.9, 0.45)
local R6_LEG_LENGTH = 2

local lerp = PowerLooks.Lerp

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function emitter(name: string, texture: string): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = texture
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rotation = NumberRange.new(0, 360)
	return e
end

local function remove(parent: Instance, name: string)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

-- The child named `name` of class `className`, built with `build` if missing
-- (a same-named child of another class is replaced).
local function ensure<T>(parent: Instance, name: string, className: string, build: () -> T): T
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing :: any
	end
	if existing then
		existing:Destroy()
	end
	local made = build() :: any
	made.Parent = parent
	return made
end

local function buildTrail(root: BasePart): Attachment
	local top = Instance.new("Attachment")
	top.Name = PowerLooks.TrailTop
	top.Position = TRAIL_TOP
	local bottom = Instance.new("Attachment")
	bottom.Name = PowerLooks.TrailBottom
	bottom.Position = TRAIL_BOTTOM

	local trail = Instance.new("Trail")
	trail.Name = PowerLooks.Trail
	trail.Enabled = false -- each client turns it on while this player runs fast
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.MinLength = 0.1
	trail.WidthScale = seq(1, 0.15)
	trail.Color = ColorSequence.new(Config.TrophySpeedTrailColor, Config.TrophySpeedTrailColorEnd)
	trail.Parent = top

	-- Speed lines streaking out behind you when you start sprinting.
	local burst = emitter(PowerLooks.SpeedBurst, SPARKLE_TEXTURE)
	burst.Rate = 0
	burst.EmissionDirection = Enum.NormalId.Back
	burst.SpreadAngle = Vector2.new(30, 30)
	burst.Speed = NumberRange.new(18, 28)
	burst.Drag = 3
	burst.Lifetime = NumberRange.new(0.25, 0.4)
	burst.Orientation = Enum.ParticleOrientation.VelocityParallel
	burst.Squash = NumberSequence.new(2) -- long thin streaks
	burst.Size = seq(0.3, 0.1)
	burst.Transparency = seq(0.15, 1)
	burst.Color = ColorSequence.new(WHITE, Config.TrophySpeedTrailColor)
	burst.Parent = top

	bottom.Parent = root
	top.Parent = root
	CollectionService:AddTag(trail, PowerLooks.TrailTag)
	return top
end

function PowerVisualsRoot.SetTrail(root: BasePart, bonus: number)
	if bonus <= 0 then
		remove(root, PowerLooks.TrailTop)
		remove(root, PowerLooks.TrailBottom)
		return
	end
	local top = root:FindFirstChild(PowerLooks.TrailTop)
	local bottom = root:FindFirstChild(PowerLooks.TrailBottom)
	local trail = top and top:FindFirstChild(PowerLooks.Trail)
	if not (trail and trail:IsA("Trail") and bottom and bottom:IsA("Attachment")) then
		remove(root, PowerLooks.TrailTop)
		remove(root, PowerLooks.TrailBottom)
		trail = buildTrail(root):FindFirstChild(PowerLooks.Trail)
	end
	local t = PowerLooks.SpeedStrength(bonus)
	local ribbon = trail :: Trail
	ribbon.Lifetime = lerp(Config.TrophySpeedTrailLifetimeMin, Config.TrophySpeedTrailLifetimeMax, t)
	ribbon.MaxLength = lerp(Config.TrophySpeedTrailMaxLengthMin, Config.TrophySpeedTrailMaxLengthMax, t)
	local opacity = lerp(Config.TrophySpeedTrailOpacityMin, Config.TrophySpeedTrailOpacityMax, t)
	ribbon.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 - opacity),
		NumberSequenceKeypoint.new(0.5, 1 - opacity * 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	ribbon:SetAttribute(PowerLooks.StrengthAttr, t)
end

local function buildAirGlow(): ParticleEmitter
	local e = emitter(PowerLooks.AirGlow, SPARKLE_TEXTURE)
	e.Enabled = false -- each client turns it on while this player is in the air
	e.Lifetime = NumberRange.new(0.4, 0.7)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -1, 0)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Size = seq(0.4, 0)
	e.Transparency = seq(0.15, 1)
	return e
end

local function buildJumpBurst(): ParticleEmitter
	local e = emitter(PowerLooks.JumpBurst, SPARKLE_TEXTURE)
	e.Rate = 0
	e.EmissionDirection = Enum.NormalId.Top
	e.SpreadAngle = Vector2.new(80, 80)
	e.Speed = NumberRange.new(7, 14)
	e.Drag = 5
	e.Acceleration = Vector3.new(0, -10, 0)
	e.Lifetime = NumberRange.new(0.35, 0.6)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.Size = seq(0.5, 0)
	e.Transparency = seq(0.05, 1)
	return e
end

local function buildAirBurst(): ParticleEmitter
	local e = emitter(PowerLooks.AirBurst, SMOKE_TEXTURE)
	e.Rate = 0
	e.LightEmission = 0.7
	e.SpreadAngle = Vector2.new(180, 180)
	e.Speed = NumberRange.new(3, 7)
	e.Drag = 5
	e.Lifetime = NumberRange.new(0.4, 0.6)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Size = seq(0.8, 3)
	e.Transparency = seq(0.3, 1)
	return e
end

function PowerVisualsRoot.SetJump(root: BasePart, humanoid: Humanoid?, bonus: number, doubleJump: boolean)
	if bonus <= 0 and not doubleJump then
		remove(root, PowerLooks.JumpFX)
		return
	end
	local fx = ensure(root, PowerLooks.JumpFX, "Attachment", function()
		local made = Instance.new("Attachment")
		made.Name = PowerLooks.JumpFX
		CollectionService:AddTag(made, PowerLooks.JumpTag)
		return made
	end) :: Attachment
	-- At the feet: R15 legs are HipHeight long, R6 legs are 2 studs.
	local legs = if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight else R6_LEG_LENGTH
	fx.Position = Vector3.new(0, -(root.Size.Y / 2 + legs), 0)

	local t = PowerLooks.JumpStrength(bonus)
	fx:SetAttribute(PowerLooks.StrengthAttr, t)
	local jumpColor = ColorSequence.new(WHITE, Config.TrophyJumpLookColor)
	if bonus > 0 then
		local glow = ensure(fx, PowerLooks.AirGlow, "ParticleEmitter", buildAirGlow) :: ParticleEmitter
		glow.Color = jumpColor
		glow.Rate = lerp(Config.TrophyJumpAirGlowRateMin, Config.TrophyJumpAirGlowRateMax, t)
		local burst = ensure(fx, PowerLooks.JumpBurst, "ParticleEmitter", buildJumpBurst) :: ParticleEmitter
		burst.Color = jumpColor
	else
		remove(fx, PowerLooks.AirGlow)
		remove(fx, PowerLooks.JumpBurst)
	end
	if doubleJump then
		local puff = ensure(fx, PowerLooks.AirBurst, "ParticleEmitter", buildAirBurst) :: ParticleEmitter
		puff.Color = ColorSequence.new(Config.TrophyDoubleJumpColor, WHITE)
	else
		remove(fx, PowerLooks.AirBurst)
	end
end

return PowerVisualsRoot
