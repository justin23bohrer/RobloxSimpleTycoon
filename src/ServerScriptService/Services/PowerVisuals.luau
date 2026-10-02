-- PowerVisuals (server only, helper for PowerService)
-- Builds the effects a player's body powers show (names and tags in
-- Shared/PowerLooks), stronger for bigger bonuses (Config.TrophySpeedGlow*,
-- TrophySpeedTrail*, TrophyJump*, TrophyDoubleJump*):
--   * WalkSpeed > 0: glowing feet (this file): one Attachment "SpeedGlow" at
--     the bottom of each foot (R15 LeftFoot/RightFoot, R6 Left Leg/Right Leg)
--     with a PointLight, colored sparkles and fast electric sparks; plus the
--     speed trail and speed-line burst on the HumanoidRootPart
--     (PowerVisualsRoot).
--   * JumpHeight > 0 / CanDoubleJump: the JumpFX attachment with the air
--     glow and the jump / double-jump burst emitters (PowerVisualsRoot).
-- Full look at the *FullAt bonus and no stronger past it (looks only; the
-- powers have no limit).
--
-- Made on the server, inside the character, so it replicates to every client
-- (everyone sees it, late joiners too). Things that depend on motion (trail
-- only while running fast, air glow, bursts) are switched on and played by
-- each client (PowerLooks.client), which never builds or keeps any of it.
--
-- * SetLooks(character, looks): creates, updates or removes every piece.
--   Idempotent: at most one of each per foot / per character.
-- * Watch(player, character, getLooks): re-applies when a foot part or the
--   HumanoidRootPart is added later (avatar body parts can be swapped in
--   after spawn). One watch per player; a new character replaces the old
--   watch. Forget(player) on leave.
-- Everything lives in the character, so it goes away with it on respawn;
-- PowerService re-applies it on CharacterAdded.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PowerLooks = require(ReplicatedStorage.Shared.PowerLooks)
local PowerVisualsRoot = require(script.Parent.PowerVisualsRoot)

local PowerVisuals = {}

export type Looks = {
	Walk: number, -- WalkSpeed bonus
	Jump: number, -- JumpHeight bonus
	DoubleJump: boolean,
}

local GLOW_NAME = PowerLooks.FootGlow
local SPARKLES = "Sparkles"
local ENERGY = "Energy"
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local FOOT_NAMES = { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }
local IS_WATCHED = {
	LeftFoot = true,
	RightFoot = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	HumanoidRootPart = true,
}

local watches: { [Player]: RBXScriptConnection } = {}
local lerp = PowerLooks.Lerp

-- R15 has feet; an R6 rig has only legs, so its legs are its "feet".
local function feet(character: Model): { BasePart }
	local found = {}
	local hasR15Feet = character:FindFirstChild("LeftFoot") or character:FindFirstChild("RightFoot")
	for _, name in FOOT_NAMES do
		local isLeg = name == "Left Leg" or name == "Right Leg"
		if isLeg and hasR15Feet then
			continue
		end
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			table.insert(found, part)
		end
	end
	return found
end

local function makeGlow(foot: BasePart): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = GLOW_NAME

	local light = Instance.new("PointLight")
	light.Shadows = false
	light.Parent = attachment

	-- Bright sparkles left behind as you run, drifting up.
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = SPARKLES
	sparkles.Texture = SPARKLE_TEXTURE
	sparkles.LightEmission = 1
	sparkles.LightInfluence = 0
	sparkles.Lifetime = NumberRange.new(0.35, 0.7)
	sparkles.Speed = NumberRange.new(0.5, 2)
	sparkles.SpreadAngle = Vector2.new(60, 60)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Acceleration = Vector3.new(0, 2.5, 0)
	sparkles.Rotation = NumberRange.new(0, 360)
	sparkles.RotSpeed = NumberRange.new(-120, 120)
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkles.Parent = attachment

	-- Tiny fast sparks crackling off the foot in every direction.
	local energy = Instance.new("ParticleEmitter")
	energy.Name = ENERGY
	energy.Texture = SPARKLE_TEXTURE
	energy.LightEmission = 1
	energy.LightInfluence = 0
	energy.Lifetime = NumberRange.new(0.12, 0.25)
	energy.Speed = NumberRange.new(4, 7)
	energy.SpreadAngle = Vector2.new(180, 180)
	energy.Drag = 6
	energy.Rotation = NumberRange.new(0, 360)
	energy.RotSpeed = NumberRange.new(-400, 400)
	energy.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	energy.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	energy.Parent = attachment

	attachment.Parent = foot
	return attachment
end

local function setFeet(character: Model, bonus: number)
	local t = PowerLooks.SpeedStrength(bonus)
	local color = Config.TrophySpeedGlowColor
	local white = Color3.new(1, 1, 1)
	for _, foot in feet(character) do
		local existing = foot:FindFirstChild(GLOW_NAME)
		if bonus <= 0 then
			if existing then
				existing:Destroy()
			end
			continue
		end
		-- An older glow (no Energy sparks) or a wrong class is rebuilt.
		local attachment = if existing and existing:IsA("Attachment") and existing:FindFirstChild(ENERGY)
			then existing
			else nil
		if not attachment then
			if existing then
				existing:Destroy()
			end
			attachment = makeGlow(foot)
		end
		local glow = attachment :: Attachment
		glow.Position = Vector3.new(0, -foot.Size.Y / 2, 0)
		local light = glow:FindFirstChildOfClass("PointLight")
		if light then
			light.Color = color
			light.Brightness = lerp(Config.TrophySpeedGlowBrightnessMin, Config.TrophySpeedGlowBrightnessMax, t)
			light.Range = lerp(Config.TrophySpeedGlowRangeMin, Config.TrophySpeedGlowRangeMax, t)
		end
		local sparkles = glow:FindFirstChild(SPARKLES)
		if sparkles and sparkles:IsA("ParticleEmitter") then
			sparkles.Color = ColorSequence.new(white, color)
			sparkles.Rate = lerp(Config.TrophySpeedGlowRateMin, Config.TrophySpeedGlowRateMax, t)
		end
		local energy = glow:FindFirstChild(ENERGY)
		if energy and energy:IsA("ParticleEmitter") then
			energy.Color = ColorSequence.new(white, color)
			energy.Rate = lerp(Config.TrophySpeedGlowEnergyRateMin, Config.TrophySpeedGlowEnergyRateMax, t)
		end
	end
end

-- Creates, updates or removes every body power effect on this character.
function PowerVisuals.SetLooks(character: Model?, looks: Looks)
	if not character then
		return
	end
	setFeet(character, looks.Walk)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		PowerVisualsRoot.SetTrail(root, looks.Walk)
		PowerVisualsRoot.SetJump(root, humanoid, looks.Jump, looks.DoubleJump)
	end
end

-- Re-applies the looks when a foot part or the root shows up later on this
-- character.
function PowerVisuals.Watch(player: Player, character: Model, getLooks: () -> Looks)
	PowerVisuals.Forget(player)
	watches[player] = character.ChildAdded:Connect(function(child)
		if IS_WATCHED[child.Name] and child:IsA("BasePart") and player.Character == character then
			PowerVisuals.SetLooks(character, getLooks())
		end
	end)
end

function PowerVisuals.Forget(player: Player)
	local connection = watches[player]
	if connection then
		connection:Disconnect()
		watches[player] = nil
	end
end

return PowerVisuals
