-- ServerMain (server entry point)
-- The only server Script. It starts the services and routes player join/leave
-- events to them in a fixed order. Game logic belongs in the services, not here.

local Players = game:GetService("Players")

local Services = script.Parent.Services
local CalebCycle = require(Services.CalebCycle)
local CookiePartyService = require(Services.CookiePartyService)
local DataService = require(Services.DataService)
local EconomyService = require(Services.EconomyService)
local PlayerDataService = require(Services.PlayerDataService)
local PowerService = require(Services.PowerService)
local StatueService = require(Services.StatueService)
local TrophyService = require(Services.TrophyService)
local TycoonService = require(Services.TycoonService)

TycoonService.Start()
local statue = StatueService.Start()
if statue then
	CalebCycle.Start(statue)
	CookiePartyService.Start(statue) -- Cookie Party collectable cookies + rewards
end
TrophyService.Start(statue) -- podium claim + Trophy Case display

-- Players get a plot by stepping on a ClaimPad (TycoonService), not on join.
local function onPlayerAdded(player: Player)
	PlayerDataService.OnPlayerAdded(player)
	CalebCycle.OnPlayerAdded(player) -- restores CalebFed; raises Caleb's goal in Normal
	CookiePartyService.OnPlayerAdded(player) -- party earnings at 0; alive cookies if mid-party
	PowerService.OnPlayerAdded(player) -- trophy power attributes + respawn movement
	DataService.OnPlayerAdded(player) -- loads saved cookies, house + trophies in the background
	EconomyService.OnPlayerAdded(player) -- applies the saved cookies once loaded (not with dev cash)
end

local function onPlayerRemoving(player: Player)
	TycoonService.OnPlayerRemoving(player) -- stop systems and free the plot
	StatueService.OnPlayerRemoving(player)
	CalebCycle.OnPlayerRemoving(player) -- lowers Caleb's goal in Normal
	CookiePartyService.OnPlayerRemoving(player)
	PlayerDataService.OnPlayerRemoving(player)
	EconomyService.OnPlayerRemoving(player)
	PowerService.OnPlayerRemoving(player)
	DataService.OnPlayerRemoving(player) -- saves and releases (does not yield)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script connected (common in Studio testing).
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
