-- Purchases (server only)
-- Read-only catalog of everything a plot can buy: Config.Droppers and
-- Config.Builds as one list. Used by TycoonService, BuyButtons, and
-- PlotStages. It decides nothing; TycoonService decides purchases.
--
-- Each purchase has a Kind ("Dropper" or "Build"), its position in its own
-- Config list (Index), and the plot part players step on to buy it
-- (BuyButtonN for droppers, BuildButtonN for builds). A purchase unlocks when
-- the purchase named in its Config After field is bought (nil = on claim).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Purchases = {}

export type Purchase = {
	Id: string,
	Kind: string, -- "Dropper" or "Build"
	Index: number,
	Entry: any, -- the Config.Droppers / Config.Builds entry
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
for _, purchase in all do
	local after = purchase.Entry.After
	if after ~= nil and not byId[after] then
		warn(`Purchases: '{purchase.Id}' has After = '{after}', which is not a purchase id, so it can never unlock`)
	end
end

-- Returns the purchase with this id, or nil if there is none.
function Purchases.Get(id: string): Purchase?
	return byId[id]
end

-- Every purchase, droppers first, then builds.
function Purchases.All(): { Purchase }
	return all
end

-- The purchases that unlock when `id` is bought (nil = when the plot is claimed).
function Purchases.UnlockedBy(id: string?): { Purchase }
	local unlocked = {}
	for _, purchase in all do
		if purchase.Entry.After == id then
			table.insert(unlocked, purchase)
		end
	end
	return unlocked
end

return Purchases
