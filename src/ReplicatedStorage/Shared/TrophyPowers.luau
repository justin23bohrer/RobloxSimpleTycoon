-- TrophyPowers (shared: server and client)
-- The contract for Caleb Trophy powers: the stat names a trophy definition
-- can grant (TrophyVariants entry .Powers = { [Stat]: number }), and how they
-- stack. The server's PowerService does the real calculation; the client only
-- reads the published result (player attribute "TrophyStats").
--
-- Stacking (one predictable formula, no exponential multipliers):
--   * Only trophies DISPLAYED in a built Trophy Case count (equipped, up to
--     Config.TrophyActiveSlots, and the TrophyCase build is bought).
--   * Every displayed trophy counts, duplicates too: two Speed Calebs give
--     Speed's bonus twice (+150% walk speed), five give +375%.
--   * Per stat, bonuses ADD: total = sum of every displayed trophy's value.
--     There is no upper limit (no stat caps); the lower bound is 0.
--   * Multiplier stats are applied as (1 + total): Golden (+1.0) + Cookie
--     (+0.25) = 2.25x cookies, never 2 x 1.25 x ...
--   * Chance stats are probabilities per event, so their total is clamped
--     to 1: a chance can't go past 100%. (Not a balance cap.)
--   * DoubleJump is a flag: any value > 0 enables it.

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

-- Stats that are probabilities: a chance can't go past 100%, so their
-- totals are clamped to 1.
TrophyPowers.ChanceStats = table.freeze({
	[TrophyPowers.Stat.ExtraCookieChance] = true,
	[TrophyPowers.Stat.LuckyCookieChance] = true,
})

-- The total bonus per stat for a list of displayed variant ids (pure: no
-- side effects, same input -> same output). Applies the stacking rule above:
-- every id counts (duplicates too), values add with no upper limit, totals
-- below 0 are dropped, and chance stats are clamped to 1. Unknown stats are
-- ignored; stats with no bonus are left out (read them as 0).
function TrophyPowers.Compute(variantIds: { string }): { [string]: number }
	-- Required here, not at the top: TrophyVariants may require this module
	-- for the Stat names, and a top-level require both ways would be a cycle.
	local TrophyVariants = require(script.Parent.TrophyVariants) :: any
	local totals: { [string]: number } = {}
	for _, id in variantIds do
		-- Get never returns nil; an unknown id is the Fallback definition
		-- (no powers).
		local powers = (TrophyVariants.Get(id) :: any).Powers
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
		if TrophyPowers.ChanceStats[stat] then
			total = math.min(total, 1) -- a chance can't go past 100%
		end
		totals[stat] = if total > 0 then total else nil
	end
	return totals
end

return table.freeze(TrophyPowers)
