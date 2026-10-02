-- PowerLooks (shared: server and client)
-- The contract between the server's PowerVisuals (which BUILDS each
-- character's power effects, so everyone sees them, late joiners too) and
-- the client's PowerLooks.client (which only ANIMATES them on each screen:
-- turns the speed trail on while running fast, the air glow on while
-- jumping, and plays the jump / double-jump bursts).
--
-- Names of the instances PowerVisuals puts in a character, the
-- CollectionService tags it gives them, and the "Strength" attribute
-- (0..1, how strong the look is) it writes on them. Looks only.

local Config = require(script.Parent.Config)

local PowerLooks = {}

-- Instance names (inside the character).
PowerLooks.FootGlow = "SpeedGlow" -- Attachment at the bottom of each foot
PowerLooks.TrailTop = "SpeedTrailTop" -- Attachment on the HumanoidRootPart (holds SpeedBurst)
PowerLooks.TrailBottom = "SpeedTrailBottom" -- Attachment on the HumanoidRootPart
PowerLooks.Trail = "SpeedTrail" -- Trail (in TrailTop), Enabled by each client
PowerLooks.SpeedBurst = "SpeedBurst" -- ParticleEmitter (Rate 0) for speed lines
PowerLooks.JumpFX = "JumpFX" -- Attachment on the HumanoidRootPart at foot level
PowerLooks.AirGlow = "AirGlow" -- ParticleEmitter in JumpFX, Enabled by each client
PowerLooks.JumpBurst = "JumpBurst" -- ParticleEmitter (Rate 0) in JumpFX
PowerLooks.AirBurst = "AirBurst" -- ParticleEmitter (Rate 0) in JumpFX, double jump only

-- CollectionService tags (they replicate), so clients find effects without
-- watching every player.
PowerLooks.TrailTag = "PowerSpeedTrail" -- on the SpeedTrail
PowerLooks.JumpTag = "PowerJumpFX" -- on the JumpFX attachment

-- Attribute on SpeedTrail and JumpFX: 0..1 strength of the look.
PowerLooks.StrengthAttr = "Strength"

-- 0..1: how strong a look is for this bonus (1 at fullAt and above). Looks
-- only: the power itself has no limit.
function PowerLooks.Strength(bonus: number, fullAt: number): number
	if bonus <= 0 then
		return 0
	end
	return if fullAt > 0 then math.clamp(bonus / fullAt, 0, 1) else 1
end

function PowerLooks.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Strength of the speed look / jump look for a bonus (Config.*FullAt).
function PowerLooks.SpeedStrength(bonus: number): number
	return PowerLooks.Strength(bonus, Config.TrophySpeedGlowFullAt)
end

function PowerLooks.JumpStrength(bonus: number): number
	return PowerLooks.Strength(bonus, Config.TrophyJumpLookFullAt)
end

return table.freeze(PowerLooks)
