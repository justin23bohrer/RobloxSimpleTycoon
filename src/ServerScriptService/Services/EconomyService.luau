-- EconomyService (server only)
-- The ONLY module allowed to change a player's cash.
-- Every change goes through AddCash or TrySpend so validation lives in one place.
--
-- Saved cookies (DataService). Load-window rule:
-- * A player joins with Config.StartingCash while their data loads.
-- * Until the load finishes, spending is blocked (TrySpend returns false) and
--   every cookie earned is counted.
-- * When the data loads, cash becomes saved amount + cookies earned while
--   loading, so nothing earned in that window is lost or counted twice (the
--   StartingCash placeholder is dropped; it was never spendable).
-- * If the data did not load (DataStore down, Studio without API access,
--   another server kept the lock), they keep StartingCash + what they earned,
--   and nothing is saved, like trophies.
-- * After that, every change is handed to DataService.SetSavedCash, which only
--   marks the data dirty; autosave / leave / BindToClose write it.
-- * Dev cash (PlayerDataService.IsDevCash, Studio only): cookies are never
--   loaded or saved, so DevStartingCash can't reach a real save.

local DataService = require(script.Parent.DataService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local EconomyService = {}

-- Players whose saved cookies have not been applied yet -> cookies earned since join.
local earnedWhileLoading: { [Player]: number } = {}

local function isValidAmount(amount: number): boolean
	return typeof(amount) == "number" and amount > 0 and amount == math.floor(amount)
end

-- Hands the current amount to DataService for the next save (once loaded).
local function recordForSave(player: Player, cash: IntValue)
	if earnedWhileLoading[player] == nil and not PlayerDataService.IsDevCash() then
		DataService.SetSavedCash(player, cash.Value)
	end
end

-- Called by ServerMain when a player joins (after PlayerDataService and
-- DataService). Waits for the data in the background, then applies the save.
function EconomyService.OnPlayerAdded(player: Player)
	if PlayerDataService.IsDevCash() or earnedWhileLoading[player] ~= nil then
		return -- dev cash: never load or save cookies
	end
	earnedWhileLoading[player] = 0
	task.spawn(function()
		local loaded = DataService.WaitForData(player)
		local earned = earnedWhileLoading[player]
		local cash = PlayerDataService.GetCashValue(player)
		if earned == nil or not cash then
			return -- left while loading
		end
		earnedWhileLoading[player] = nil -- spending allowed from here on
		local saved = if loaded then DataService.GetSavedCash(player) else nil
		if saved then
			cash.Value = saved + earned
			DataService.SetSavedCash(player, cash.Value)
		end
	end)
end

-- Called by ServerMain when a player leaves.
function EconomyService.OnPlayerRemoving(player: Player)
	earnedWhileLoading[player] = nil
end

-- True while the player's saved cookies are still loading (spending blocked).
function EconomyService.IsCashLoading(player: Player): boolean
	return earnedWhileLoading[player] ~= nil
end

-- Returns the player's cash, or 0 if they have no data.
function EconomyService.GetCash(player: Player): number
	local cash = PlayerDataService.GetCashValue(player)
	return if cash then cash.Value else 0
end

-- Gives cash to a player. Amount must be a positive whole number.
-- Returns true if the cash was added.
function EconomyService.AddCash(player: Player, amount: number): boolean
	local cash = PlayerDataService.GetCashValue(player)
	if not cash or not isValidAmount(amount) then
		return false
	end
	cash.Value += amount
	local earned = earnedWhileLoading[player]
	if earned ~= nil then
		earnedWhileLoading[player] = earned + amount
	end
	recordForSave(player, cash)
	return true
end

-- Removes cash only if the player can afford it, and never while their saved
-- cookies are still loading. Returns true if the cash was spent, false if not
-- (nothing changes).
function EconomyService.TrySpend(player: Player, amount: number): boolean
	local cash = PlayerDataService.GetCashValue(player)
	if not cash or not isValidAmount(amount) or earnedWhileLoading[player] ~= nil or cash.Value < amount then
		return false
	end
	cash.Value -= amount
	recordForSave(player, cash)
	return true
end

return EconomyService
