-- TrophyInventoryData (client only, ModuleScript)
-- Pure helpers for the trophy inventory panel (TrophyInventory.client.luau):
-- turn the server's decoded TrophyInventory / TrophyStats attributes into
-- safe tables, sort the trophies, and write the "Active powers" line.
--
-- No Roblox APIs and no requires, so it can be tested with the plain `luau`
-- CLI. It decides nothing: the server owns the inventory and the powers;
-- bad or missing data just shows as an empty inventory.

local TrophyInventoryData = {}

export type Trophy = {
	InstanceId: string,
	Variant: string,
	EventId: string,
	EarnedAt: number,
}

export type Inventory = {
	Owned: { Trophy },
	Equipped: { string }, -- InstanceIds that are in Owned, in display order
	EquippedSet: { [string]: boolean },
	CaseBuilt: boolean,
	Max: number,
	Saved: boolean,
}

-- Powers line order and wording. A stat not listed here (added later) still
-- shows as "+X% <Stat>" after these.
local STAT_ORDER = {
	"CookieMultiplier",
	"DropperSpeed",
	"ExtraCookieChance",
	"LuckyCookieChance",
	"CollectBonus",
	"WalkSpeed",
	"JumpHeight",
	"DoubleJump",
}
local STAT_TEXT = {
	CookieMultiplier = "+%d%% cookies",
	DropperSpeed = "+%d%% drop speed",
	ExtraCookieChance = "%d%% extra cookie chance",
	LuckyCookieChance = "%d%% lucky cookie chance",
	CollectBonus = "+%d%% collect bonus",
	WalkSpeed = "+%d%% speed",
	JumpHeight = "+%d%% jump",
}

local function isFiniteNumber(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- decoded: the JSON-decoded TrophyInventory attribute (anything; nil when the
-- attribute is missing or not valid JSON). Never errors.
function TrophyInventoryData.Parse(decoded: any, defaultMax: number): Inventory
	local inv: Inventory = {
		Owned = {},
		Equipped = {},
		EquippedSet = {},
		CaseBuilt = false,
		Max = defaultMax,
		Saved = true,
	}
	if type(decoded) ~= "table" then
		return inv
	end

	local seen = {}
	if type(decoded.Owned) == "table" then
		for _, record in decoded.Owned do
			if type(record) == "table" and type(record.InstanceId) == "string"
				and type(record.Variant) == "string" and not seen[record.InstanceId] then
				seen[record.InstanceId] = true
				table.insert(inv.Owned, {
					InstanceId = record.InstanceId,
					Variant = record.Variant,
					EventId = if type(record.EventId) == "string" then record.EventId else "",
					EarnedAt = if isFiniteNumber(record.EarnedAt) then record.EarnedAt else 0,
				})
			end
		end
	end

	if type(decoded.Equipped) == "table" then
		for _, id in decoded.Equipped do
			if type(id) == "string" and seen[id] and not inv.EquippedSet[id] then
				inv.EquippedSet[id] = true
				table.insert(inv.Equipped, id)
			end
		end
	end

	inv.CaseBuilt = decoded.CaseBuilt == true
	inv.Saved = decoded.Saved ~= false
	if isFiniteNumber(decoded.Max) and decoded.Max >= 0 then
		inv.Max = math.floor(decoded.Max)
	end
	return inv
end

-- Display order: equipped first (in equip order), then rarest, then newest.
-- rarityOrder(variantId) -> number (higher = rarer).
function TrophyInventoryData.Sort(inv: Inventory, rarityOrder: (string) -> number): { Trophy }
	local equipIndex = {}
	for i, id in inv.Equipped do
		equipIndex[id] = i
	end
	local list = table.clone(inv.Owned)
	table.sort(list, function(a, b)
		local ea, eb = equipIndex[a.InstanceId], equipIndex[b.InstanceId]
		if ea or eb then
			if ea and eb then
				return ea < eb
			end
			return ea ~= nil
		end
		local ra, rb = rarityOrder(a.Variant), rarityOrder(b.Variant)
		if ra ~= rb then
			return ra > rb
		end
		if a.EarnedAt ~= b.EarnedAt then
			return a.EarnedAt > b.EarnedAt
		end
		return a.InstanceId < b.InstanceId
	end)
	return list
end

-- How many different collectable variants are owned (isCollectable(variantId)).
function TrophyInventoryData.DistinctOwned(inv: Inventory, isCollectable: (string) -> boolean): number
	local found, count = {}, 0
	for _, t in inv.Owned do
		if not found[t.Variant] and isCollectable(t.Variant) then
			found[t.Variant] = true
			count += 1
		end
	end
	return count
end

-- decoded TrophyStats ({[Stat] = total}) -> "+125% cookies, +20% speed",
-- or "" when nothing is active.
function TrophyInventoryData.PowerSummary(decoded: any): string
	if type(decoded) ~= "table" then
		return ""
	end
	local parts = {}
	local function add(stat: string, value: any)
		if not isFiniteNumber(value) or value <= 0 then
			return
		end
		if stat == "DoubleJump" then
			table.insert(parts, "double jump")
			return
		end
		local percent = math.floor(value * 100 + 0.5)
		local fmt = STAT_TEXT[stat]
		table.insert(parts, if fmt then string.format(fmt, percent) else `+{percent}% {stat}`)
	end

	local known = {}
	for _, stat in STAT_ORDER do
		known[stat] = true
		add(stat, decoded[stat])
	end
	local extra = {}
	for stat in decoded do
		if type(stat) == "string" and not known[stat] then
			table.insert(extra, stat)
		end
	end
	table.sort(extra)
	for _, stat in extra do
		add(stat, decoded[stat])
	end
	return table.concat(parts, ", ")
end

return table.freeze(TrophyInventoryData)
