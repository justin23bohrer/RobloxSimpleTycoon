-- DataSchema (server only)
-- Helper for DataService: the shape of one player's saved data, and how to
-- turn whatever is in the DataStore into that shape safely. Decides nothing
-- about when to load or save (that is DataService).
--
-- Saved record (key "Player_<UserId>" in Config.DataStoreName):
--   Version       number   CURRENT_VERSION
--   Purchases     { [purchaseId]: true }   house purchases (droppers + builds)
--   Trophies      { TrophyRecord }         Caleb trophies, oldest first
--   SessionJobId  string?  server that has this player's data open (lock)
--   SessionTime   number?  os.time() of that server's last write
--
-- Session fields are DataService's session lock and never leave DataService.

local Purchases = require(script.Parent.Purchases)

local DataSchema = {}

DataSchema.CURRENT_VERSION = 1

export type TrophyRecord = {
	Variant: string, -- key into Shared/TrophyVariants
	EventId: string, -- the CalebCycleId it was earned in
	EarnedAt: number, -- os.time()
}

export type PlayerData = {
	Version: number,
	Purchases: { [string]: true },
	Trophies: { TrophyRecord },
}

local function isNonEmptyString(value: any): boolean
	return typeof(value) == "string" and #value > 0 and #value <= 100
end

-- Returns a clean copy of one trophy record, or nil if it is not valid.
function DataSchema.CleanTrophy(record: any): TrophyRecord?
	if typeof(record) ~= "table" then
		return nil
	end
	local earnedAt = record.EarnedAt
	if not isNonEmptyString(record.Variant) or not isNonEmptyString(record.EventId) then
		return nil
	end
	if typeof(earnedAt) ~= "number" or earnedAt ~= earnedAt or earnedAt < 0 or earnedAt == math.huge then
		return nil -- not a number, NaN, negative, or infinite
	end
	return { Variant = record.Variant, EventId = record.EventId, EarnedAt = earnedAt }
end

-- Fresh data for a player who has never saved.
function DataSchema.Default(): PlayerData
	return { Version = DataSchema.CURRENT_VERSION, Purchases = {}, Trophies = {} }
end

-- Older versions -> CURRENT_VERSION, one step at a time. There is only
-- version 1 so far; add a step here when the shape changes, e.g.
--   if raw.Version == 1 then ...; raw.Version = 2 end
local function migrate(raw: { [any]: any }): { [any]: any }
	if raw.Version == nil then
		raw.Version = 1 -- treat an unversioned table as version 1
	end
	return raw
end

-- Turns a stored value into clean PlayerData. Returns nil plus a reason when
-- the value must NOT be used or overwritten (not a table, or written by a
-- newer version of the game that this server does not understand).
-- Unknown purchase ids and bad or duplicate trophy records are dropped.
function DataSchema.FromStored(raw: any): (PlayerData?, string?)
	if raw == nil then
		return DataSchema.Default(), nil
	end
	if typeof(raw) ~= "table" then
		return nil, `stored value is a {typeof(raw)}, not a table`
	end
	if raw.Version ~= nil and typeof(raw.Version) ~= "number" then
		return nil, "stored Version is not a number"
	end
	if raw.Version and raw.Version > DataSchema.CURRENT_VERSION then
		return nil, `stored Version {raw.Version} is newer than this server's {DataSchema.CURRENT_VERSION}`
	end
	raw = migrate(raw)

	local data = DataSchema.Default()
	if typeof(raw.Purchases) == "table" then
		for id, owned in raw.Purchases do
			if owned == true and typeof(id) == "string" and Purchases.Get(id) then
				data.Purchases[id] = true
			end
		end
	end
	if typeof(raw.Trophies) == "table" then
		local seen = {}
		for _, record in raw.Trophies do
			local clean = DataSchema.CleanTrophy(record)
			if clean and not seen[clean.EventId] then
				seen[clean.EventId] = true
				table.insert(data.Trophies, clean)
			end
		end
	end
	return data, nil
end

-- A deep copy for storing (DataService adds the session fields).
function DataSchema.ToStored(data: PlayerData): { [string]: any }
	local purchases = {}
	for id in data.Purchases do
		purchases[id] = true
	end
	return {
		Version = DataSchema.CURRENT_VERSION,
		Purchases = purchases,
		Trophies = DataSchema.CopyTrophies(data.Trophies),
	}
end

function DataSchema.CopyTrophies(trophies: { TrophyRecord }): { TrophyRecord }
	local copy = {}
	for i, record in trophies do
		copy[i] = { Variant = record.Variant, EventId = record.EventId, EarnedAt = record.EarnedAt }
	end
	return copy
end

return DataSchema
