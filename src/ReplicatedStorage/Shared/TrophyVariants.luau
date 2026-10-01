-- TrophyVariants (shared: server and client)
-- Every look a Caleb Trophy can have. Pure data plus two helpers; it decides
-- nothing about who gets a trophy (TrophyService does that on the server).
--
-- A saved trophy stores only its variant Id (TrophyRecord.Variant), so:
-- * Never rename or remove an Id that players may own. To retire a variant,
--   set its Weight to 0 (it is never picked again but still renders).
-- * An Id that is not in this list (removed, or saved by a newer version)
--   still renders with the Fallback look (Get never returns nil).
--
-- To add a variant: add one entry below. Fields:
--   Id          unique, saved in the DataStore (never change it)
--   DisplayName shown on the trophy's nameplate and in the claim message
--   Rarity      "Common" / "Rare" / "Epic" / "Legendary" (see Rarities)
--   Weight      relative chance to be picked (0 = never picked)
--   Figure      { Color, Material } of the mini Caleb
--   Base        { Color, Material } of the plinth
--   Accessories list of: "Crown", "PartyHat", "ChefHat", "Sunglasses",
--               "Cookie" (in his right hand), "BowTie" (empty = none)
--   Pose        "Down", "ArmsUp", "Wave", "BellyPat", "HandOnHip", "HoldCookie"
--   Effect      "None", "Sparkles", "Glow"
--   EffectColor color of the sparkles / glow

local TrophyVariants = {}

export type Variant = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	Weight: number,
	Figure: { Color: Color3, Material: Enum.Material },
	Base: { Color: Color3, Material: Enum.Material },
	Accessories: { string },
	Pose: string,
	Effect: string,
	EffectColor: Color3,
}

-- Rarity order (1 = most common) and the nameplate text color.
TrophyVariants.Rarities = table.freeze({
	Common = table.freeze({ Order = 1, Color = Color3.fromRGB(235, 235, 235) }),
	Rare = table.freeze({ Order = 2, Color = Color3.fromRGB(90, 170, 255) }),
	Epic = table.freeze({ Order = 3, Color = Color3.fromRGB(190, 110, 255) }),
	Legendary = table.freeze({ Order = 4, Color = Color3.fromRGB(255, 200, 40) }),
})

local rgb = Color3.fromRGB
local M = Enum.Material
local DARK_WOOD = { Color = rgb(92, 60, 38), Material = M.Wood }
local WHITE_STONE = { Color = rgb(235, 232, 225), Material = M.Marble }
local BLACK_STONE = { Color = rgb(35, 35, 40), Material = M.Granite }

local function variant(v: Variant): Variant
	return table.freeze(v)
end

TrophyVariants.List = table.freeze({
	-- Common
	variant({
		Id = "BronzeCaleb", DisplayName = "Bronze Caleb", Rarity = "Common", Weight = 20,
		Figure = { Color = rgb(205, 127, 50), Material = M.Metal }, Base = DARK_WOOD,
		Accessories = {}, Pose = "Wave", Effect = "None", EffectColor = rgb(255, 255, 255),
	}),
	variant({
		Id = "PartyCaleb", DisplayName = "Party Caleb", Rarity = "Common", Weight = 20,
		Figure = { Color = rgb(200, 205, 215), Material = M.Metal }, Base = DARK_WOOD,
		Accessories = { "PartyHat" }, Pose = "ArmsUp", Effect = "None", EffectColor = rgb(255, 255, 255),
	}),
	variant({
		Id = "ChefCaleb", DisplayName = "Chef Caleb", Rarity = "Common", Weight = 20,
		Figure = { Color = rgb(245, 240, 230), Material = M.SmoothPlastic }, Base = DARK_WOOD,
		Accessories = { "ChefHat", "Cookie" }, Pose = "HoldCookie", Effect = "None", EffectColor = rgb(255, 255, 255),
	}),
	variant({
		Id = "SnackCaleb", DisplayName = "Snack Time Caleb", Rarity = "Common", Weight = 20,
		Figure = { Color = rgb(160, 110, 70), Material = M.SmoothPlastic }, Base = WHITE_STONE,
		Accessories = { "Cookie" }, Pose = "BellyPat", Effect = "None", EffectColor = rgb(255, 255, 255),
	}),
	-- Rare
	variant({
		Id = "CoolCaleb", DisplayName = "Cool Caleb", Rarity = "Rare", Weight = 9,
		Figure = { Color = rgb(40, 170, 170), Material = M.SmoothPlastic }, Base = BLACK_STONE,
		Accessories = { "Sunglasses" }, Pose = "HandOnHip", Effect = "None", EffectColor = rgb(255, 255, 255),
	}),
	variant({
		Id = "StuffedCaleb", DisplayName = "Stuffed Caleb", Rarity = "Rare", Weight = 9,
		Figure = { Color = rgb(255, 150, 180), Material = M.SmoothPlastic }, Base = WHITE_STONE,
		Accessories = { "BowTie" }, Pose = "BellyPat", Effect = "None", EffectColor = rgb(255, 255, 255),
	}),
	variant({
		Id = "RubyCaleb", DisplayName = "Ruby Caleb", Rarity = "Rare", Weight = 9,
		Figure = { Color = rgb(200, 30, 50), Material = M.Glass }, Base = BLACK_STONE,
		Accessories = {}, Pose = "Wave", Effect = "Sparkles", EffectColor = rgb(255, 80, 100),
	}),
	-- Epic
	variant({
		Id = "DiamondCaleb", DisplayName = "Diamond Caleb", Rarity = "Epic", Weight = 4,
		Figure = { Color = rgb(170, 230, 255), Material = M.Glass }, Base = WHITE_STONE,
		Accessories = { "Sunglasses" }, Pose = "ArmsUp", Effect = "Sparkles", EffectColor = rgb(200, 245, 255),
	}),
	variant({
		Id = "NeonCaleb", DisplayName = "Neon Caleb", Rarity = "Epic", Weight = 4,
		Figure = { Color = rgb(170, 70, 255), Material = M.Neon }, Base = BLACK_STONE,
		Accessories = { "PartyHat" }, Pose = "Wave", Effect = "Glow", EffectColor = rgb(170, 70, 255),
	}),
	variant({
		Id = "MidnightCaleb", DisplayName = "Midnight Caleb", Rarity = "Epic", Weight = 4,
		Figure = { Color = rgb(30, 35, 70), Material = M.Foil }, Base = BLACK_STONE,
		Accessories = { "Crown" }, Pose = "HandOnHip", Effect = "Sparkles", EffectColor = rgb(120, 140, 255),
	}),
	-- Legendary
	variant({
		Id = "GoldenCaleb", DisplayName = "Golden Caleb", Rarity = "Legendary", Weight = 1.5,
		Figure = { Color = rgb(255, 200, 40), Material = M.Foil }, Base = BLACK_STONE,
		Accessories = { "Crown" }, Pose = "ArmsUp", Effect = "Sparkles", EffectColor = rgb(255, 220, 90),
	}),
	variant({
		Id = "CookieKingCaleb", DisplayName = "Cookie King Caleb", Rarity = "Legendary", Weight = 1.5,
		Figure = { Color = rgb(196, 134, 66), Material = M.SmoothPlastic }, Base = WHITE_STONE,
		Accessories = { "Crown", "Cookie" }, Pose = "HoldCookie", Effect = "Glow", EffectColor = rgb(255, 190, 90),
	}),
})

-- Used for an Id that is not in List (never picked).
TrophyVariants.Fallback = variant({
	Id = "Unknown", DisplayName = "Mystery Caleb", Rarity = "Common", Weight = 0,
	Figure = { Color = rgb(160, 160, 165), Material = M.SmoothPlastic }, Base = DARK_WOOD,
	Accessories = {}, Pose = "Down", Effect = "None", EffectColor = rgb(255, 255, 255),
})

local byId: { [string]: Variant } = {}
for _, v in TrophyVariants.List do
	if byId[v.Id] then
		warn(`TrophyVariants: duplicate Id '{v.Id}'; the second one is ignored`)
	elseif not TrophyVariants.Rarities[v.Rarity] then
		warn(`TrophyVariants: '{v.Id}' has unknown Rarity '{v.Rarity}'`)
	end
	byId[v.Id] = byId[v.Id] or v
end

-- The variant with this Id, or Fallback (never nil).
function TrophyVariants.Get(id: string): Variant
	return byId[id] or TrophyVariants.Fallback
end

-- True if the Id is a real variant (not the fallback).
function TrophyVariants.Exists(id: string): boolean
	return byId[id] ~= nil
end

local rng = Random.new()

local function weightedPick(list: { Variant }): Variant?
	local total = 0
	for _, v in list do
		total += math.max(v.Weight, 0)
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	local last: Variant? = nil
	for _, v in list do
		if v.Weight > 0 then
			last = v
			roll -= v.Weight
			if roll <= 0 then
				return v
			end
		end
	end
	return last -- rounding left a tiny remainder
end

-- Weighted random variant Id. Prefers variants not in ownedVariantIds, so a
-- player collects every variant before getting a repeat.
function TrophyVariants.PickVariant(ownedVariantIds: { string }?): string
	local owned = {}
	for _, id in ownedVariantIds or {} do
		owned[id] = true
	end
	local fresh = {}
	for _, v in TrophyVariants.List do
		if not owned[v.Id] and v.Weight > 0 then
			table.insert(fresh, v)
		end
	end
	local picked = weightedPick(fresh) or weightedPick(TrophyVariants.List)
	return if picked then picked.Id else TrophyVariants.List[1].Id
end

return table.freeze(TrophyVariants)
