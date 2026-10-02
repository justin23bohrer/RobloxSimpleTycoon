-- Purchases (server only)
-- Read-only catalog of everything a plot can buy: Config.Droppers,
-- Config.Builds and Config.TrophyBuilds as one list. Used by TycoonService,
-- BuyButtons, and PlotStages. It decides nothing; TycoonService decides
-- purchases.
--
-- Each purchase has a Kind ("Dropper", "Build" or "TrophyBuild"), its
-- position in its own Config list (Index), and the plot part players step on
-- to buy it (BuyButtonN for droppers, BuildButtonN for builds, TrophyButtonN
-- for trophy builds). Droppers and builds make up the house: each unlocks
-- when the purchase named in its Config After field is bought (nil = on
-- claim). A trophy build unlocks when the house purchase named in its After
-- is bought, or, with no After, once the house is maxed (IsHouseMaxed). See
-- IsUnlocked.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Purchases = {}

export type Purchase = {
	Id: string,
	Kind: string, -- "Dropper", "Build" or "TrophyBuild"
	Index: number,
	Entry: any, -- the Config.Droppers / Config.Builds / Config.TrophyBuilds entry
	ButtonName: string,
}

local all: { Purchase } = {}
local byId: { [string]: Purchase } = {}

local function add(kind: string, index: number, entry: any, buttonName: string)
	if byId[entry.Id] then
		warn(`Purchases: duplicate purchase id '{entry.Id}' in Config; the second one is ignored`)
		return
	end
	local purchase = { Id = entry.Id, Kind = kind, Index = index, Entry = entry, ButtonName = buttonName }
	table.insert(all, purchase)
	byId[entry.Id] = purchase
end

for index, entry in Config.Droppers do
	add("Dropper", index, entry, `BuyButton{index}`)
end
for index, entry in Config.Builds do
	add("Build", index, entry, `BuildButton{index}`)
end
for index, entry in Config.TrophyBuilds do
	add("TrophyBuild", index, entry, `TrophyButton{index}`)
end
for _, purchase in all do
	local after = purchase.Entry.After
	if after ~= nil and not byId[after] then
		warn(`Purchases: '{purchase.Id}' has After = '{after}', which is not a purchase id, so it can never unlock`)
	elseif after ~= nil and purchase.Kind == "TrophyBuild" and byId[after].Kind == "TrophyBuild" then
		warn(`Purchases: '{purchase.Id}' has After = '{after}', a trophy build; a trophy build's After must be a house purchase`)
	end
end

-- Returns the purchase with this id, or nil if there is none.
function Purchases.Get(id: string): Purchase?
	return byId[id]
end

-- Every purchase, droppers first, then builds, then trophy builds.
function Purchases.All(): { Purchase }
	return all
end

-- True for droppers and builds (the house), false for trophy builds.
function Purchases.IsHouse(purchase: Purchase): boolean
	return purchase.Kind ~= "TrophyBuild"
end

-- The house purchases that unlock when `id` is bought (nil = when the plot
-- is claimed). Never trophy builds: see IsUnlocked and
-- PlotStages.ShowTrophyButtons.
function Purchases.UnlockedBy(id: string?): { Purchase }
	local unlocked = {}
	for _, purchase in all do
		if Purchases.IsHouse(purchase) and purchase.Entry.After == id then
			table.insert(unlocked, purchase)
		end
	end
	return unlocked
end

-- True once every dropper and build is in `purchased` (purchase id -> true).
function Purchases.IsHouseMaxed(purchased: { [string]: boolean }): boolean
	for _, purchase in all do
		if Purchases.IsHouse(purchase) and not purchased[purchase.Id] then
			return false
		end
	end
	return true
end

-- True if the purchase's button may be shown and bought, given what is in
-- `purchased` (purchase id -> true): its After is bought (house purchases
-- with no After: always); a trophy build with no After needs the house
-- maxed.
function Purchases.IsUnlocked(purchase: Purchase, purchased: { [string]: boolean }): boolean
	local after = purchase.Entry.After
	if after ~= nil then
		return purchased[after] == true
	end
	return Purchases.IsHouse(purchase) or Purchases.IsHouseMaxed(purchased)
end

-- The trophy builds (Config.TrophyBuilds order).
function Purchases.TrophyBuilds(): { Purchase }
	local list = {}
	for _, purchase in all do
		if not Purchases.IsHouse(purchase) then
			table.insert(list, purchase)
		end
	end
	return list
end

return Purchases
