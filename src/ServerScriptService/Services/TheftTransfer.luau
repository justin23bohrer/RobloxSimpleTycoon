-- TheftTransfer (server only)
-- Helper for TheftService: the permanent transfer when a thief reaches their
-- own TrophyStash, and the receiver checks done before a theft starts.
-- Never a second inventory: it only calls DataService and TrophyInventory.
--
-- Where the trophy lives decides how it moves (exactly one owner, always):
-- 1. Session-only (claimed while its owner's data was not loaded; kept by
--    UserId until the server closes, even after they leave): it moves from
--    the owner's session list to the thief's (TrophyInventory). No yield.
-- 2. Saved, owner in this server with loaded data: DataService.AddTrophy
--    (thief) then DataService.RemoveTrophy (owner); if the remove fails the
--    add is undone. No yield.
-- 3. Saved, owner not in this server (left mid-theft) or their data is open
--    elsewhere: DataService.TransferTrophyOffline (yields; refused while any
--    server holds the owner's session lock).
--
-- Same Caleb round: a player may hold only one trophy per EventId (a second
-- saved one would be dropped on the next load), so a thief who already owns
-- one from that round can't steal another from it (CanReceive refuses at the
-- start, and again at the stash).

local Players = game:GetService("Players")

local DataSchema = require(script.Parent.DataSchema)
local DataService = require(script.Parent.DataService)
local TrophyInventory = require(script.Parent.TrophyInventory)

local TheftTransfer = {}

type TrophyRecord = DataSchema.TrophyRecord

-- Messages for the thief (a small notification).
local LOADING = "Your trophies are still loading. Try again in a moment."
local UNSAVED = "Your trophies aren't saving right now, so you can't keep a stolen trophy."
local SAME_ROUND = "You already have a trophy from that Caleb round."
local GONE = "That trophy isn't there anymore."
local FAILED = "Couldn't take the trophy right now, so it went back to its owner."

local function owns(list: { TrophyRecord }, instanceId: string): TrophyRecord?
	for _, record in list do
		if record.InstanceId == instanceId then
			return record
		end
	end
	return nil
end

-- Can `thief` receive this trophy? A saved trophy needs the thief's data
-- loaded (it must stay saved). Returns (true) or (false, message).
function TheftTransfer.CanReceive(thief: Player, record: TrophyRecord, sessionOnly: boolean): (boolean, string?)
	if not sessionOnly then
		if DataService.IsLoading(thief) then
			return false, LOADING
		end
		if not DataService.IsLoaded(thief) then
			return false, UNSAVED
		end
	end
	if TrophyInventory.HasEventTrophy(thief, record.EventId) then
		return false, SAME_ROUND
	end
	if owns(TrophyInventory.GetOwned(thief), record.InstanceId) then
		return false, GONE -- can't happen (unique ids); keeps the undo below exact
	end
	return true
end

-- Moves the trophy from `fromUserId` to `thief`. `record` is what was stolen
-- (read when the theft started). Returns (true) or (false, message); on
-- false nothing changed and the owner still has it.
function TheftTransfer.Run(thief: Player, fromUserId: number, record: TrophyRecord): (boolean, string?)
	local instanceId = record.InstanceId

	-- 1. Session-only trophy.
	local sessionRecord = TrophyInventory.FindSessionTrophy(fromUserId, instanceId)
	if sessionRecord then
		local ok, why = TheftTransfer.CanReceive(thief, sessionRecord, true)
		if not ok then
			return false, why
		end
		local moved = TrophyInventory.RemoveSessionTrophy(fromUserId, instanceId) :: TrophyRecord
		TrophyInventory.AddSessionTrophy(thief, moved)
		return true
	end

	local ok, why = TheftTransfer.CanReceive(thief, record, false)
	if not ok then
		return false, why
	end

	-- 2. Owner here with loaded data: both changes in memory, no yield.
	local owner = Players:GetPlayerByUserId(fromUserId)
	if owner and DataService.IsLoaded(owner) then
		local saved = owns(DataService.GetTrophies(owner), instanceId)
		if not saved then
			return false, GONE
		end
		if not DataService.AddTrophy(thief, saved) then
			return false, FAILED
		end
		if not DataService.RemoveTrophy(owner, instanceId) then
			DataService.RemoveTrophy(thief, instanceId) -- undo: never two owners
			return false, FAILED
		end
		return true
	end

	-- 3. Owner's saved key (they left, or their data is open elsewhere).
	local moved = DataService.TransferTrophyOffline(fromUserId, instanceId, thief)
	return moved, if moved then nil else FAILED
end

return TheftTransfer
