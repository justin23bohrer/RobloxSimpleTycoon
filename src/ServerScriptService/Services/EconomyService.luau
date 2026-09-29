-- EconomyService (server only)
-- The ONLY module allowed to change a player's cash.
-- Every change goes through AddCash or TrySpend so validation lives in one place.

local PlayerDataService = require(script.Parent.PlayerDataService)

local EconomyService = {}

local function isValidAmount(amount: number): boolean
	return typeof(amount) == "number" and amount > 0 and amount == math.floor(amount)
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
	return true
end

-- Removes cash only if the player can afford it.
-- Returns true if the cash was spent, false if not (nothing changes).
function EconomyService.TrySpend(player: Player, amount: number): boolean
	local cash = PlayerDataService.GetCashValue(player)
	if not cash or not isValidAmount(amount) or cash.Value < amount then
		return false
	end
	cash.Value -= amount
	return true
end

return EconomyService
