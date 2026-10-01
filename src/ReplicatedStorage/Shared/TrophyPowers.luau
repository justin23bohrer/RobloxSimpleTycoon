-- TrophyPowers (shared: server and client)
-- The contract for Caleb Trophy powers: the stat names a trophy definition
-- can grant (TrophyVariants entry .Powers = { [Stat]: number }), and how they
-- stack. The server's PowerService does the real calculation; the client only
-- reads the published result (player attribute "TrophyStats").
--
-- Stacking (one predictable formula, no exponential multipliers):
--   * Only trophies DISPLAYED in a built Trophy Case count (equipped, up to
--     Config.TrophyActiveSlots, and the TrophyCase build is bought).
--   * A definition counts once: two Golden Calebs on display give Golden's
--     bonus once.
--   * Per stat, bonuses ADD: total = sum of every displayed definition's
--     value, then clamped to Config.TrophyStatCaps[stat].
--   * Multiplier stats are applied as (1 + total): Golden (+1.0) + Cookie
--     (+0.25) = 2.25x cookies, never 2 x 1.25 x ...
--   * Chance stats are probabilities 0..1 per event.
--   * DoubleJump is a flag: any value > 0 enables it.

local Config = require(script.Parent.Config)

local TrophyPowers = {}

TrophyPowers.Stat = table.freeze({
	CookieMultiplier = "CookieMultiplier", -- +bonus to every drop's value (owner's plot)
	DropperSpeed = "DropperSpeed", -- +bonus drop rate: interval = DropInterval / (1 + bonus)
	ExtraCookieChance = "ExtraCookieChance", -- chance a drop spawns one extra drop
	LuckyCookieChance = "LuckyCookieChance", -- chance a drop is worth Config.TrophyLuckyCookieMultiplier x
	CollectBonus = "CollectBonus", -- +bonus paid on each Collect pad collect
	WalkSpeed = "WalkSpeed", -- +bonus to Humanoid.WalkSpeed
	JumpHeight = "JumpHeight", -- +bonus to Humanoid.JumpHeight
	DoubleJump = "DoubleJump", -- flag (> 0 = can jump once more in the air)
})

-- The total bonus per stat for a list of displayed variant ids (pure: no
-- side effects, same input -> same output). Applies the stacking rule above:
-- each distinct definition counts once, values add, each total is clamped to
-- [0, Config.TrophyStatCaps[stat]]. Unknown stats are ignored; stats with no
-- bonus are left out (read them as 0).
function TrophyPowers.Compute(variantIds: { string }): { [string]: number }
	-- Required here, not at the top: TrophyVariants may require this module
	-- for the Stat names, and a top-level require both ways would be a cycle.
	local TrophyVariants = require(script.Parent.TrophyVariants) :: any
	local totals: { [string]: number } = {}
	local counted: { [any]: boolean } = {}
	for _, id in variantIds do
		-- Get never returns nil; an unknown id is the Fallback definition,
		-- which is still counted only once.
		local definition = TrophyVariants.Get(id) :: any
		if counted[definition] then
			continue
		end
		counted[definition] = true
		local powers = definition.Powers
		if type(powers) ~= "table" then
			continue
		end
		for stat, value in powers do
			if TrophyPowers.Stat[stat] and type(value) == "number" and value == value then
				totals[stat] = (totals[stat] or 0) + value
			end
		end
	end
	for stat, total in totals do
		local cap = Config.TrophyStatCaps[stat] or 0
		local clamped = math.clamp(total, 0, cap)
		totals[stat] = if clamped > 0 then clamped else nil
	end
	return totals
end

return table.freeze(TrophyPowers)
