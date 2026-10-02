-- PowerVisuals (server only, helper for PowerService)
-- Glowing feet while a player has a WalkSpeed trophy bonus: one Attachment
-- named "SpeedGlow" at the bottom of each foot (R15 LeftFoot/RightFoot, R6
-- Left Leg/Right Leg) holding a soft PointLight and a few sparkles that are
-- left behind as you run. Stronger for bigger bonuses (Config.TrophySpeedGlow*).
--
-- Made on the server, inside the character, so it replicates to every client
-- (everyone sees who is fast, late joiners too) with no client code.
--
-- * SetSpeedGlow(character, bonus): bonus > 0 creates or updates the glow,
--   bonus <= 0 removes it. Idempotent: at most one SpeedGlow per foot.
-- * Watch(player, character, getBonus): re-applies when a foot part is added
--   later (avatar body parts can be swapped in after spawn). One watch per
--   player; a new character replaces the old watch. Forget(player) on leave.
-- The glow lives in the character, so it goes away with it on respawn;
-- PowerService re-applies it on CharacterAdded.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PowerVisuals = {}

local GLOW_NAME = "SpeedGlow"
local FOOT_NAMES = { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }
local IS_FOOT = { LeftFoot = true, RightFoot = true, ["Left Leg"] = true, ["Right Leg"] = true }

local watches: { [Player]: RBXScriptConnection } = {}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

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

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.LightEmission = 1
	sparkles.LightInfluence = 0
	sparkles.Lifetime = NumberRange.new(0.35, 0.6)
	sparkles.Speed = NumberRange.new(0.5, 1.5)
	sparkles.SpreadAngle = Vector2.new(60, 60)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Acceleration = Vector3.new(0, 2, 0)
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkles.Parent = attachment

	attachment.Parent = foot
	return attachment
end

-- Creates, updates or (bonus <= 0) removes the glow on this character's feet.
function PowerVisuals.SetSpeedGlow(character: Model?, bonus: number)
	if not character then
		return
	end
	for _, foot in feet(character) do
		local existing = foot:FindFirstChild(GLOW_NAME)
		if bonus <= 0 then
			if existing then
				existing:Destroy()
			end
			continue
		end
		local attachment = if existing and existing:IsA("Attachment") then existing else nil
		if not attachment then
			if existing then
				existing:Destroy()
			end
			attachment = makeGlow(foot)
		end
		local cap = Config.TrophyStatCaps.WalkSpeed
		local t = if cap > 0 then math.clamp(bonus / cap, 0, 1) else 1
		local color = Config.TrophySpeedGlowColor
		local glow = attachment :: Attachment
		glow.Position = Vector3.new(0, -foot.Size.Y / 2, 0)
		local light = glow:FindFirstChildOfClass("PointLight")
		if light then
			light.Color = color
			light.Brightness = lerp(Config.TrophySpeedGlowBrightnessMin, Config.TrophySpeedGlowBrightnessMax, t)
			light.Range = lerp(Config.TrophySpeedGlowRangeMin, Config.TrophySpeedGlowRangeMax, t)
		end
		local sparkles = glow:FindFirstChildOfClass("ParticleEmitter")
		if sparkles then
			sparkles.Color = ColorSequence.new(color)
			sparkles.Rate = lerp(Config.TrophySpeedGlowRateMin, Config.TrophySpeedGlowRateMax, t)
		end
	end
end

-- Re-applies the glow when a foot part shows up later on this character.
function PowerVisuals.Watch(player: Player, character: Model, getBonus: () -> number)
	PowerVisuals.Forget(player)
	watches[player] = character.ChildAdded:Connect(function(child)
		if IS_FOOT[child.Name] and child:IsA("BasePart") and player.Character == character then
			PowerVisuals.SetSpeedGlow(character, getBonus())
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
