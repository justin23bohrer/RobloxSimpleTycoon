-- TrophyInventory (server only)
-- Helper for TrophyService: what trophies a player owns and has equipped,
-- the TrophyEquip remote's rules, and the TrophyInventory player attribute.
-- TrophyService decides when to refresh the case and powers.
--
-- * Owned = saved trophies (DataService) + session-only ones (claimed while
--   the player's data was not loaded; kept here by UserId until this server
--   closes, never written).
-- * Equipped = DataService's saved list, then equipped session-only ones,
--   at most Config.TrophyActiveSlots in all. Session-only trophies can be
--   equipped like saved ones; that part of the list is not saved either.
-- * Every check uses server data only: the client sends an action and an
--   InstanceId, and the id must be one of the caller's own trophies.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataSchema = require(script.Parent.DataSchema)
local DataService = require(script.Parent.DataService)

local TrophyInventory = {}

type TrophyRecord = DataSchema.TrophyRecord

TrophyInventory.ATTRIBUTE = "TrophyInventory"

local sessionTrophies: { [number]: { TrophyRecord } } = {} -- unsaved claims, by UserId
local sessionEquipped: { [number]: { string } } = {} -- equipped unsaved claims, by UserId
local lastRequest: { [Player]: number } = {}

-- A new trophy record with a fresh InstanceId.
function TrophyInventory.NewRecord(variantId: string, eventId: string): TrophyRecord
	return {
		InstanceId = DataSchema.NewInstanceId(),
		Variant = variantId,
		EventId = eventId,
		EarnedAt = os.time(),
	}
end

-- Saved + session-only trophies, oldest first.
function TrophyInventory.GetOwned(player: Player): { TrophyRecord }
	local list = DataService.GetTrophies(player)
	for _, record in sessionTrophies[player.UserId] or {} do
		table.insert(list, table.clone(record))
	end
	table.sort(list, function(a, b)
		if a.EarnedAt ~= b.EarnedAt then
			return a.EarnedAt < b.EarnedAt
		end
		return a.InstanceId < b.InstanceId
	end)
	return list
end

local function isSession(player: Player, instanceId: string): boolean
	for _, record in sessionTrophies[player.UserId] or {} do
		if record.InstanceId == instanceId then
			return true
		end
	end
	return false
end

-- Equipped InstanceIds in display order (saved first, then session-only).
function TrophyInventory.GetEquipped(player: Player): { string }
	local ids = DataService.GetEquipped(player)
	for _, id in sessionEquipped[player.UserId] or {} do
		if #ids < Config.TrophyActiveSlots and not table.find(ids, id) then
			table.insert(ids, id)
		end
	end
	return ids
end

-- The equipped trophies' records, in display order.
function TrophyInventory.GetEquippedRecords(player: Player): { TrophyRecord }
	local byId = {}
	for _, record in TrophyInventory.GetOwned(player) do
		byId[record.InstanceId] = record
	end
	local records = {}
	for _, id in TrophyInventory.GetEquipped(player) do
		if byId[id] then
			table.insert(records, byId[id])
		end
	end
	return records
end

-- Keeps a trophy claimed while the player's data is not loaded, and equips
-- it if an active slot is free (like DataService.AddTrophy).
function TrophyInventory.AddSessionTrophy(player: Player, record: TrophyRecord)
	local userId = player.UserId
	sessionTrophies[userId] = sessionTrophies[userId] or {}
	table.insert(sessionTrophies[userId], record)
	if #TrophyInventory.GetEquipped(player) < Config.TrophyActiveSlots then
		sessionEquipped[userId] = sessionEquipped[userId] or {}
		table.insert(sessionEquipped[userId], record.InstanceId)
	end
end

-- Equips or unequips one of the player's own trophies. Returns (true) or
-- (false, friendly reason). Server data only; nothing changes on false.
function TrophyInventory.SetEquippedState(player: Player, instanceId: string, equip: boolean): (boolean, string?)
	local owned = false
	for _, record in TrophyInventory.GetOwned(player) do
		owned = owned or record.InstanceId == instanceId
	end
	if not owned then
		return false, "That trophy isn't in your collection."
	end
	local equipped = TrophyInventory.GetEquipped(player)
	local index = table.find(equipped, instanceId)
	if equip == (index ~= nil) then
		return true -- already that way
	end
	if equip and #equipped >= Config.TrophyActiveSlots then
		return false, `All {Config.TrophyActiveSlots} active slots are full. Unequip a trophy first.`
	end

	if isSession(player, instanceId) then
		local list = sessionEquipped[player.UserId] or {}
		sessionEquipped[player.UserId] = list
		if equip then
			if not table.find(list, instanceId) then
				table.insert(list, instanceId)
			end
		else
			table.remove(list, table.find(list, instanceId) :: number)
		end
		return true
	end
	local saved = DataService.GetEquipped(player)
	if equip then
		table.insert(saved, instanceId)
	else
		table.remove(saved, table.find(saved, instanceId) :: number)
	end
	local ok = DataService.SetEquipped(player, saved)
	return ok, if ok then nil else "Couldn't change that trophy right now. Try again."
end

-- The TrophyEquip remote: (player, action, instanceId), all untrusted.
function TrophyInventory.HandleRequest(player: Player, action: any, instanceId: any): (boolean, string?)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < Config.TrophyEquipCooldown then
		return false, "Slow down a little!"
	end
	lastRequest[player] = now
	if action ~= "Equip" and action ~= "Unequip" then
		return false, "Unknown action."
	end
	if not DataSchema.IsInstanceId(instanceId) then
		return false, "That trophy isn't in your collection."
	end
	if DataService.IsLoading(player) then
		return false, "Your trophies are still loading. Try again in a moment."
	end
	return TrophyInventory.SetEquippedState(player, instanceId, action == "Equip")
end

-- Writes the TrophyInventory player attribute (JSON, see ARCHITECTURE.md).
function TrophyInventory.Publish(player: Player, caseBuilt: boolean)
	local owned = {}
	for _, record in TrophyInventory.GetOwned(player) do
		table.insert(owned, {
			InstanceId = record.InstanceId,
			Variant = record.Variant,
			EventId = record.EventId,
			EarnedAt = record.EarnedAt,
		})
	end
	local inventory = {
		Owned = owned,
		Equipped = TrophyInventory.GetEquipped(player),
		CaseBuilt = caseBuilt,
		Max = Config.TrophyActiveSlots,
		Saved = DataService.IsLoaded(player),
	}
	player:SetAttribute(TrophyInventory.ATTRIBUTE, HttpService:JSONEncode(inventory))
end

function TrophyInventory.OnPlayerRemoving(player: Player)
	lastRequest[player] = nil
end

return TrophyInventory
