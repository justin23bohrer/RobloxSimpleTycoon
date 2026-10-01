-- TrophyEffects (server only)
-- Helper for TrophyModel: the non-part effects on a trophy: the variant's
-- Effect ("Sparkles", "Glow", or a small "Flame") and a soft light for
-- rarities with Glow (TrophyVariants.Rarities). Presentation only; kept
-- light (a few particles, no heavy emitters).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrophyVariants = require(ReplicatedStorage.Shared.TrophyVariants)

local TrophyEffects = {}

-- A few small flame particles rising from the flame (or the head).
local function addFlame(part: BasePart, color: Color3, scale: number)
	local flame = Instance.new("ParticleEmitter")
	flame.Name = "Flame"
	flame.Rate = 8
	flame.Lifetime = NumberRange.new(0.4, 0.7)
	flame.Speed = NumberRange.new(0.8 * scale, 1.4 * scale)
	flame.Acceleration = Vector3.new(0, 1.5 * scale, 0)
	flame.SpreadAngle = Vector2.new(15, 15)
	flame.EmissionDirection = Enum.NormalId.Top
	flame.Size = NumberSequence.new(0.3 * scale, 0)
	flame.Transparency = NumberSequence.new(0.2, 1)
	flame.Color = ColorSequence.new(color, Color3.fromRGB(230, 50, 20))
	flame.LightEmission = 0.5
	flame.Parent = part
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 1
	light.Range = math.clamp(3 * scale, 3, 30)
	light.Parent = part
end

-- Adds the variant's effect and its rarity's glow. Call after scaling the
-- model (lights and particles don't scale with it).
function TrophyEffects.Add(model: Model, variant: TrophyVariants.Variant, scale: number)
	local head = model:FindFirstChild("Head")
	local torso = model:FindFirstChild("Torso")
	local rarity = TrophyVariants.GetRarity(variant.Rarity)
	local trim = model:FindFirstChild("PlinthTrim")
	if rarity.Glow and trim then
		local light = Instance.new("PointLight")
		light.Name = "RarityGlow"
		light.Color = rarity.Color
		light.Brightness = 1.5
		light.Range = math.clamp(5 * scale, 5, 40)
		light.Parent = trim
	end
	if variant.Effect == "Flame" then
		local at = model:FindFirstChild("FlameTop") or head
		if at and at:IsA("BasePart") then
			addFlame(at, variant.EffectColor, scale)
		end
	elseif variant.Effect == "Sparkles" and head then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = variant.EffectColor
		sparkles.Parent = head
	elseif variant.Effect == "Glow" and torso then
		local light = Instance.new("PointLight")
		light.Color = variant.EffectColor
		light.Brightness = 2
		light.Range = math.clamp(4 * scale, 4, 40)
		light.Parent = torso
	end
end

return TrophyEffects
