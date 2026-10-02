-- PlayerDataService (server only)
-- Creates and removes each player's session data.
--
-- The currency players see is Cookies. In code it is still called "cash"
-- (StartingCash, AddCash, ...); only the leaderstat and the text are cookies.
--
-- Cash is stored in player.leaderstats.Cookies (an IntValue). Roblox shows
-- leaderstats in the player list automatically, and changes made by a client
-- never replicate back to the server, so the server's value is the real one.
--
-- Only EconomyService should change cash. Other code reads it through
-- EconomyService.GetCash.
--
-- Every session starts at Config.StartingCash; once the player's saved data
-- loads, EconomyService replaces it with the saved amount (see EconomyService
-- for the load-window rule).
--
-- Testing only: if Config.DevUnlimitedCash is true AND the game is running in
-- Roblox Studio, players start with Config.DevStartingCash instead, and their
-- cookies are neither loaded nor saved (IsDevCash), so dev cash can never
-- reach a real save. The RunService:IsStudio() check means this can never
-- apply in a published game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerDataService = {}

local devCash = Config.DevUnlimitedCash == true and RunService:IsStudio()
local startingCash = if devCash then Config.DevStartingCash else Config.StartingCash
if devCash then
	print(`[DEV] Unlimited cash is ON (Studio only): players start with {startingCash} cookies, and cookies are NOT loaded or saved. Set Config.DevUnlimitedCash = false to turn it off.`)
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
	cash.Name = "Cookies"
	cash.Value = startingCash
	cash.Parent = leaderstats

	leaderstats.Parent = player
	cashValues[player] = cash
end

-- Called by ServerMain when a player leaves.
function PlayerDataService.OnPlayerRemoving(player: Player)
	cashValues[player] = nil
end

-- True while dev cash is on (Studio only): cookies must not be loaded or saved.
function PlayerDataService.IsDevCash(): boolean
	return devCash
end

-- For EconomyService only. Returns nil if the player has no data (e.g. left).
function PlayerDataService.GetCashValue(player: Player): IntValue?
	return cashValues[player]
end

return PlayerDataService
