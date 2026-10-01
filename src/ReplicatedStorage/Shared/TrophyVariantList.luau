-- TrophyVariantList (shared: server and client)
-- The data behind TrophyVariants: every Caleb Trophy definition. Pure data;
-- read it through TrophyVariants (Get / RollReward), not directly.
--
-- A saved trophy stores only its definition Id, so:
-- * Never rename or remove an Id that players may own. To retire one, set its
--   Weight to 0 (it is never rolled again but still renders and still has
--   its powers).
--
-- Fields:
--   Id          unique, saved in the DataStore (never change it)
--   DisplayName shown on the trophy's nameplate, in the claim message and UI
--   Rarity      a key of TrophyVariants.Rarities
--   Weight      chance to be picked AMONG ITS RARITY (0 = never picked); the
--               rarity itself is rolled first (Config.TrophyRarityChances)
--   Description one fun sentence for the UI
--   Powers      { [TrophyPowers.Stat]: number } (see TrophyPowers for stacking)
--   PowerText   short caps line for the UI, e.g. "2x COOKIE PRODUCTION"
--   Figure      { Color, Material } of the mini Caleb
--   Base        { Color, Material } of the plinth
--   Accessories names from TrophyAccessories / TrophyProps (e.g. "Crown",
--               "Cookie", "Springs", "RainbowArch"; empty = none)
--   Pose        "Down", "ArmsUp", "Wave", "BellyPat", "HandOnHip",
--               "HoldCookie", "Run", "Think" (TrophyModel)
--   Effect      "None", "Sparkles", "Glow", "Flame"
--   EffectColor color of the sparkles / glow / flame

local Config = require(script.Parent.Config)
local TrophyPowers = require(script.Parent.TrophyPowers)

export type Look = { Color: Color3, Material: Enum.Material }

export type Variant = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	Weight: number,
	Description: string,
	Powers: { [string]: number },
	PowerText: string,
	Figure: Look,
	Base: Look,
	Accessories: { string },
	Pose: string,
	Effect: string,
	EffectColor: Color3,
}

local Stat = TrophyPowers.Stat
local rgb = Color3.fromRGB
local M = Enum.Material
local WHITE = rgb(255, 255, 255)
local LUCKY = `{Config.TrophyLuckyCookieMultiplier}x`
local DARK_WOOD = { Color = rgb(92, 60, 38), Material = M.Wood }
local WHITE_STONE = { Color = rgb(235, 232, 225), Material = M.Marble }
local BLACK_STONE = { Color = rgb(35, 35, 40), Material = M.Granite }

local function variant(v: Variant): Variant
	table.freeze(v.Powers)
	table.freeze(v.Accessories)
	return table.freeze(v)
end

local function figure(color: Color3, material: Enum.Material?): Look
	return { Color = color, Material = material or M.SmoothPlastic }
end

local List: { Variant } = {
	-- Common
	variant({
		Id = "BronzeCaleb", DisplayName = "Bronze Caleb", Rarity = "Common", Weight = 10,
		Description = "Caleb's very first trophy, polished with cookie crumbs.",
		Powers = { [Stat.CookieMultiplier] = 0.05 }, PowerText = "+5% COOKIE PRODUCTION",
		Figure = figure(rgb(205, 127, 50), M.Metal), Base = DARK_WOOD,
		Accessories = {}, Pose = "Wave", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "PartyCaleb", DisplayName = "Party Caleb", Rarity = "Common", Weight = 10,
		Description = "He heard there was cake. There was not cake.",
		Powers = { [Stat.WalkSpeed] = 0.05 }, PowerText = "+5% WALK SPEED",
		Figure = figure(rgb(200, 205, 215), M.Metal), Base = DARK_WOOD,
		Accessories = { "PartyHat" }, Pose = "ArmsUp", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "CookieCaleb", DisplayName = "Cookie Caleb", Rarity = "Common", Weight = 10,
		Description = "Found a cookie bigger than his head and refuses to share.",
		Powers = { [Stat.CookieMultiplier] = 0.25 }, PowerText = "+25% COOKIE PRODUCTION",
		Figure = figure(rgb(240, 215, 170)), Base = DARK_WOOD,
		Accessories = { "GiantCookie" }, Pose = "ArmsUp", Effect = "None", EffectColor = WHITE,
	}),
	-- Uncommon
	variant({
		Id = "ChefCaleb", DisplayName = "Chef Caleb", Rarity = "Uncommon", Weight = 10,
		Description = "Bakes a fresh batch, then eats the whole batch.",
		Powers = { [Stat.CollectBonus] = 0.05 }, PowerText = "+5% COOKIES WHEN YOU COLLECT",
		Figure = figure(rgb(245, 240, 230)), Base = DARK_WOOD,
		Accessories = { "ChefHat", "Cookie" }, Pose = "HoldCookie", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "SnackCaleb", DisplayName = "Snack Time Caleb", Rarity = "Uncommon", Weight = 10,
		Description = "It is always snack time somewhere.",
		Powers = { [Stat.ExtraCookieChance] = 0.03 }, PowerText = "3% CHANCE FOR AN EXTRA COOKIE",
		Figure = figure(rgb(160, 110, 70)), Base = WHITE_STONE,
		Accessories = { "Cookie" }, Pose = "BellyPat", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "SpeedCaleb", DisplayName = "Speed Caleb", Rarity = "Uncommon", Weight = 10,
		Description = "Runs so fast the cookies can't keep up.",
		Powers = { [Stat.WalkSpeed] = 0.20 }, PowerText = "+20% WALK SPEED",
		Figure = figure(rgb(40, 120, 255)), Base = WHITE_STONE,
		Accessories = { "LightningBolt", "SpeedLines" }, Pose = "Run", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "JumpCaleb", DisplayName = "Jump Caleb", Rarity = "Uncommon", Weight = 10,
		Description = "Boing! Boing! Boing! He never stops bouncing.",
		Powers = { [Stat.JumpHeight] = 0.50 }, PowerText = "+50% JUMP HEIGHT",
		Figure = figure(rgb(120, 210, 60)), Base = DARK_WOOD,
		Accessories = { "Springs" }, Pose = "ArmsUp", Effect = "None", EffectColor = WHITE,
	}),
	-- Rare
	variant({
		Id = "CoolCaleb", DisplayName = "Cool Caleb", Rarity = "Rare", Weight = 10,
		Description = "Too cool for school, just right for cookies.",
		Powers = { [Stat.WalkSpeed] = 0.12 }, PowerText = "+12% WALK SPEED",
		Figure = figure(rgb(40, 170, 170)), Base = BLACK_STONE,
		Accessories = { "Sunglasses" }, Pose = "HandOnHip", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "StuffedCaleb", DisplayName = "Stuffed Caleb", Rarity = "Rare", Weight = 10,
		Description = "Ate one cookie too many. Worth it.",
		Powers = { [Stat.CookieMultiplier] = 0.15 }, PowerText = "+15% COOKIE PRODUCTION",
		Figure = figure(rgb(255, 150, 180)), Base = WHITE_STONE,
		Accessories = { "BowTie" }, Pose = "BellyPat", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "RubyCaleb", DisplayName = "Ruby Caleb", Rarity = "Rare", Weight = 10,
		Description = "Carved from a giant ruby, still smells like cookies.",
		Powers = { [Stat.LuckyCookieChance] = 0.04 }, PowerText = `4% CHANCE FOR {LUCKY} COOKIES`,
		Figure = figure(rgb(200, 30, 50), M.Glass), Base = BLACK_STONE,
		Accessories = {}, Pose = "Wave", Effect = "Sparkles", EffectColor = rgb(255, 80, 100),
	}),
	variant({
		Id = "FireCaleb", DisplayName = "Fire Caleb", Rarity = "Rare", Weight = 10,
		Description = "His hair is on fire and so are your droppers.",
		Powers = { [Stat.DropperSpeed] = 0.25 }, PowerText = "DROPPERS 25% FASTER",
		Figure = figure(rgb(230, 80, 30)), Base = BLACK_STONE,
		Accessories = { "FlameHair" }, Pose = "HandOnHip", Effect = "Flame", EffectColor = rgb(255, 150, 40),
	}),
	variant({
		Id = "CloneCaleb", DisplayName = "Clone Caleb", Rarity = "Rare", Weight = 10,
		Description = "One Caleb was not enough, so now there are three.",
		Powers = { [Stat.ExtraCookieChance] = 0.15 }, PowerText = "15% CHANCE FOR AN EXTRA COOKIE",
		Figure = figure(rgb(120, 150, 255)), Base = WHITE_STONE,
		Accessories = { "MiniCalebs" }, Pose = "Wave", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "BigBrainCaleb", DisplayName = "Big Brain Caleb", Rarity = "Rare", Weight = 10,
		Description = "Figured out the secret to collecting more cookies.",
		Powers = { [Stat.CollectBonus] = 0.10 }, PowerText = "+10% COOKIES WHEN YOU COLLECT",
		Figure = figure(rgb(150, 200, 230)), Base = WHITE_STONE,
		Accessories = { "BigBrain" }, Pose = "Think", Effect = "None", EffectColor = WHITE,
	}),
	-- Epic
	variant({
		Id = "DiamondCaleb", DisplayName = "Diamond Caleb", Rarity = "Epic", Weight = 10,
		Description = "Shiny, sparkly, and lucky with every cookie.",
		Powers = { [Stat.LuckyCookieChance] = 0.10 }, PowerText = `10% CHANCE FOR {LUCKY} COOKIES`,
		Figure = figure(rgb(170, 230, 255), M.Glass), Base = WHITE_STONE,
		Accessories = { "Sunglasses" }, Pose = "ArmsUp", Effect = "Sparkles", EffectColor = rgb(200, 245, 255),
	}),
	variant({
		Id = "NeonCaleb", DisplayName = "Neon Caleb", Rarity = "Epic", Weight = 10,
		Description = "Glows in the dark and drops cookies in a hurry.",
		Powers = { [Stat.DropperSpeed] = 0.30 }, PowerText = "DROPPERS 30% FASTER",
		Figure = figure(rgb(170, 70, 255), M.Neon), Base = BLACK_STONE,
		Accessories = { "PartyHat" }, Pose = "Wave", Effect = "Glow", EffectColor = rgb(170, 70, 255),
	}),
	variant({
		Id = "MidnightCaleb", DisplayName = "Midnight Caleb", Rarity = "Epic", Weight = 10,
		Description = "Sneaks out at midnight for a cookie run.",
		Powers = { [Stat.JumpHeight] = 0.40, [Stat.WalkSpeed] = 0.10 }, PowerText = "+40% JUMP, +10% SPEED",
		Figure = figure(rgb(30, 35, 70), M.Foil), Base = BLACK_STONE,
		Accessories = { "Crown" }, Pose = "HandOnHip", Effect = "Sparkles", EffectColor = rgb(120, 140, 255),
	}),
	variant({
		Id = "RocketCaleb", DisplayName = "Rocket Caleb", Rarity = "Epic", Weight = 10,
		Description = "Strapped two rockets to his back. Mom said no.",
		Powers = { [Stat.DoubleJump] = 1, [Stat.JumpHeight] = 0.20 }, PowerText = "DOUBLE JUMP + 20% JUMP HEIGHT",
		Figure = figure(rgb(230, 235, 245)), Base = BLACK_STONE,
		Accessories = { "RocketPack" }, Pose = "ArmsUp", Effect = "None", EffectColor = WHITE,
	}),
	variant({
		Id = "RainbowCaleb", DisplayName = "Rainbow Caleb", Rarity = "Epic", Weight = 10,
		Description = "A little bit of everything, in every color.",
		Powers = {
			[Stat.CookieMultiplier] = 0.10, [Stat.WalkSpeed] = 0.10,
			[Stat.JumpHeight] = 0.10, [Stat.DropperSpeed] = 0.10,
		},
		PowerText = "+10% COOKIES, SPEED, JUMP & DROPPERS",
		Figure = figure(rgb(250, 245, 250)), Base = WHITE_STONE,
		Accessories = { "RainbowArch" }, Pose = "Wave", Effect = "Sparkles", EffectColor = rgb(255, 180, 230),
	}),
	-- Legendary
	variant({
		Id = "GoldenCaleb", DisplayName = "Golden Caleb", Rarity = "Legendary", Weight = 10,
		Description = "Solid gold, and so is every cookie he touches.",
		Powers = { [Stat.CookieMultiplier] = 1.0 }, PowerText = "2x COOKIE PRODUCTION",
		Figure = figure(rgb(255, 200, 40), M.Foil), Base = BLACK_STONE,
		Accessories = { "Crown" }, Pose = "ArmsUp", Effect = "Sparkles", EffectColor = rgb(255, 220, 90),
	}),
	variant({
		Id = "CookieKingCaleb", DisplayName = "Cookie King Caleb", Rarity = "Legendary", Weight = 10,
		Description = "Rules the cookie kingdom with a chocolate-chip fist.",
		Powers = { [Stat.CookieMultiplier] = 0.60, [Stat.CollectBonus] = 0.15 }, PowerText = "+60% COOKIES, +15% COLLECT",
		Figure = figure(rgb(196, 134, 66)), Base = WHITE_STONE,
		Accessories = { "Crown", "Cookie" }, Pose = "HoldCookie", Effect = "Glow", EffectColor = rgb(255, 190, 90),
	}),
	-- Mythic
	variant({
		Id = "KingCaleb", DisplayName = "King Caleb", Rarity = "Mythic", Weight = 10,
		Description = "The one true king of Caleb Town. Bow before the belly.",
		Powers = { [Stat.CookieMultiplier] = 0.50, [Stat.WalkSpeed] = 0.15 }, PowerText = "+50% COOKIES, +15% WALK SPEED",
		Figure = figure(rgb(110, 50, 170), M.Foil), Base = BLACK_STONE,
		Accessories = { "Cape", "Crown" }, Pose = "HandOnHip", Effect = "Sparkles", EffectColor = rgb(255, 220, 90),
	}),
}

-- Used for an Id that is not in List (never picked, no powers).
local Fallback = variant({
	Id = "Unknown", DisplayName = "Mystery Caleb", Rarity = "Common", Weight = 0,
	Description = "Nobody knows where this Caleb came from.",
	Powers = {}, PowerText = "NO POWER",
	Figure = figure(rgb(160, 160, 165)), Base = DARK_WOOD,
	Accessories = {}, Pose = "Down", Effect = "None", EffectColor = WHITE,
})

return table.freeze({
	List = table.freeze(List),
	Fallback = Fallback,
})
