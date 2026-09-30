-- PlayerDataService (server only)
-- Creates and removes each player's session data.
--
-- Cash is stored in player.leaderstats.Cash (an IntValue). Roblox shows
-- leaderstats in the player list automatically, and changes made by a client
-- never replicate back to the server, so the server's value is the real one.
--
-- Only EconomyService should change cash. Other code reads it through
-- EconomyService.GetCash.
--
-- No DataStore persistence yet: every session starts at Config.StartingCash.
--
-- Testing only: if Config.DevUnlimitedCash is true AND the game is running in
-- Roblox Studio, players start with Config.DevStartingCash instead. The
-- RunService:IsStudio() check means this can never apply in a published game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataService = {}

local startingCash = Config.StartingCash
if Config.DevUnlimitedCash and RunService:IsStudio() then
	startingCash = Config.DevStartingCash
	print(`[DEV] Unlimited cash is ON (Studio only): players start with ${startingCash}. Set Config.DevUnlimitedCash = false to turn it off.`)
end

local cashValues: { [Player]: IntValue } = {}

-- Called by ServerMain when a player joins.
function PlayerDataService.OnPlayerAdded(player: Player)
	if cashValues[player] then
		return -- already set up; never grant starting cash twice
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = startingCash
	cash.Parent = leaderstats

	leaderstats.Parent = player
	cashValues[player] = cash
end

-- Called by ServerMain when a player leaves.
function PlayerDataService.OnPlayerRemoving(player: Player)
	cashValues[player] = nil
end

-- For EconomyService only. Returns nil if the player has no data (e.g. left).
function PlayerDataService.GetCashValue(player: Player): IntValue?
	return cashValues[player]
end

return PlayerDataService
