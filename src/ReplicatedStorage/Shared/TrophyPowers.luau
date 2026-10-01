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

return table.freeze(TrophyPowers)
