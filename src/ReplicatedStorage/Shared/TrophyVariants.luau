-- TrophyVariants (shared: server and client)
-- Every Caleb Trophy definition (the data is in TrophyVariantList), the
-- rarities and how they look, and the reward roll. It decides nothing about
-- WHO gets a trophy (TrophyService does that on the server).
--
-- A saved trophy stores only its definition Id (TrophyRecord.Variant):
-- * Never rename or remove an Id that players may own (see TrophyVariantList).
-- * An Id that is not in the list (removed, or saved by a newer version)
--   still renders with the Fallback look and has no powers (Get never
--   returns nil).
--
-- To add a trophy: add one entry to TrophyVariantList (and, for a new look,
-- an accessory in TrophyAccessories / TrophyProps).

local Config = require(script.Parent.Config)
local TrophyVariantList = require(script.Parent.TrophyVariantList)

export type Variant = TrophyVariantList.Variant

export type Rarity = {
	Order: number, -- 1 = most common
	Color: Color3, -- nameplate / UI text color
	PlinthTrimColor: Color3, -- the band around the top of the trophy's plinth
	TrimMaterial: Enum.Material,
	Glow: boolean, -- a soft light in Color around the trophy
}

local TrophyVariants = {}

local function rarity(r: Rarity): Rarity
	return table.freeze(r)
end

local rgb = Color3.fromRGB
local M = Enum.Material

-- The ONLY place rarity presentation lives (TrophyModel, the case nameplates,
-- the UI all read it).
TrophyVariants.Rarities = table.freeze({
	Common = rarity({
		Order = 1, Color = rgb(235, 235, 235),
		PlinthTrimColor = rgb(185, 185, 190), TrimMaterial = M.SmoothPlastic, Glow = false,
	}),
	Uncommon = rarity({
		Order = 2, Color = rgb(110, 220, 90),
		PlinthTrimColor = rgb(80, 190, 70), TrimMaterial = M.SmoothPlastic, Glow = false,
	}),
	Rare = rarity({
		Order = 3, Color = rgb(90, 170, 255),
		PlinthTrimColor = rgb(60, 140, 240), TrimMaterial = M.SmoothPlastic, Glow = false,
	}),
	Epic = rarity({
		Order = 4, Color = rgb(190, 110, 255),
		PlinthTrimColor = rgb(160, 80, 230), TrimMaterial = M.Foil, Glow = false,
	}),
	Legendary = rarity({
		Order = 5, Color = rgb(255, 200, 40),
		PlinthTrimColor = rgb(255, 200, 40), TrimMaterial = M.Foil, Glow = false,
	}),
	Mythic = rarity({
		Order = 6, Color = rgb(255, 80, 150),
		PlinthTrimColor = rgb(255, 80, 150), TrimMaterial = M.Foil, Glow = true,
	}),
})

TrophyVariants.List = TrophyVariantList.List
TrophyVariants.Fallback = TrophyVariantList.Fallback

local byId: { [string]: Variant } = {}
for _, v in TrophyVariants.List do
	if byId[v.Id] then
		warn(`TrophyVariants: duplicate Id '{v.Id}'; the second one is ignored`)
	elseif not TrophyVariants.Rarities[v.Rarity] then
		warn(`TrophyVariants: '{v.Id}' has unknown Rarity '{v.Rarity}'`)
	end
	byId[v.Id] = byId[v.Id] or v
end

-- The definition with this Id, or Fallback (never nil).
function TrophyVariants.Get(id: string): Variant
	return byId[id] or TrophyVariants.Fallback
end

-- True if the Id is a real definition (not the fallback).
function TrophyVariants.Exists(id: string): boolean
	return byId[id] ~= nil
end

-- The rarity's presentation (Common for an unknown name; never nil).
function TrophyVariants.GetRarity(name: string): Rarity
	return TrophyVariants.Rarities[name] or TrophyVariants.Rarities.Common
end

-- How many definitions can be won (Weight > 0).
function TrophyVariants.CollectableCount(): number
	local count = 0
	for _, v in TrophyVariants.List do
		if v.Weight > 0 then
			count += 1
		end
	end
	return count
end

local rng = Random.new()

-- Picks one item by its weight (items with weight <= 0 are skipped).
local function weightedPick<T>(items: { T }, weightOf: (T) -> number): T?
	local total = 0
	for _, item in items do
		total += math.max(weightOf(item), 0)
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	local last: T? = nil
	for _, item in items do
		local w = weightOf(item)
		if w > 0 then
			last = item
			roll -= w
			if roll <= 0 then
				return item
			end
		end
	end
	return last -- rounding left a tiny remainder
end

local function variantWeight(v: Variant): number
	return v.Weight
end

-- Rarity names in Order, each with its pickable definitions.
local pools: { { Name: string, Variants: { Variant } } } = {}
for name in TrophyVariants.Rarities do
	local variants = {}
	for _, v in TrophyVariants.List do
		if v.Rarity == name and v.Weight > 0 and byId[v.Id] == v then
			table.insert(variants, v)
		end
	end
	if #variants > 0 then
		table.insert(pools, { Name = name, Variants = variants })
	end
end
table.sort(pools, function(a, b)
	return TrophyVariants.Rarities[a.Name].Order < TrophyVariants.Rarities[b.Name].Order
end)

local function rarityChance(pool): number
	return tonumber(Config.TrophyRarityChances[pool.Name]) or 0
end

-- The claim reward (server calls it). First a rarity by
-- Config.TrophyRarityChances (rarities with no pickable definition are
-- skipped and the rest renormalized), then a definition of that rarity by
-- Weight, preferring ones not in ownedVariantIds (a repeat only once the
-- player owns every definition of that rarity).
function TrophyVariants.RollReward(ownedVariantIds: { string }?): string
	local owned = {}
	for _, id in ownedVariantIds or {} do
		owned[id] = true
	end
	local pool = weightedPick(pools, rarityChance) or pools[1]
	if not pool then
		return TrophyVariants.List[1].Id -- nothing is pickable (misconfigured)
	end
	local fresh = {}
	for _, v in pool.Variants do
		if not owned[v.Id] then
			table.insert(fresh, v)
		end
	end
	local picked = weightedPick(fresh, variantWeight) or weightedPick(pool.Variants, variantWeight)
	return if picked then picked.Id else pool.Variants[1].Id
end

-- Old name, kept so existing callers keep working.
TrophyVariants.PickVariant = TrophyVariants.RollReward

return table.freeze(TrophyVariants)
