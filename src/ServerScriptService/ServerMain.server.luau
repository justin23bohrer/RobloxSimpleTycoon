-- ServerMain (server entry point)
-- The only server Script. It starts the services and routes player join/leave
-- events to them in a fixed order. Game logic belongs in the services, not here.

local Players = game:GetService("Players")

local Services = script.Parent.Services
local CalebCycle = require(Services.CalebCycle)
local CookiePartyService = require(Services.CookiePartyService)
local DataService = require(Services.DataService)
local HouseSecurityService = require(Services.HouseSecurityService)
local PlayerDataService = require(Services.PlayerDataService)
local PowerService = require(Services.PowerService)
local PushService = require(Services.PushService)
local StatueService = require(Services.StatueService)
local TheftService = require(Services.TheftService)
local TrophyService = require(Services.TrophyService)
local TycoonService = require(Services.TycoonService)

TycoonService.Start()
local statue = StatueService.Start()
if statue then
	CalebCycle.Start(statue)
	CookiePartyService.Start(statue) -- Cookie Party collectable cookies + rewards
end
TrophyService.Start(statue) -- podium claim + Trophy Case display
HouseSecurityService.Start() -- security pad + red bars in every house
TheftService.Start() -- stealing displayed trophies
PushService.Start() -- the push that stops thieves

-- Players get a plot by stepping on a ClaimPad (TycoonService), not on join.
local function onPlayerAdded(player: Player)
	PlayerDataService.OnPlayerAdded(player)
	CalebCycle.OnPlayerAdded(player)
	CookiePartyService.OnPlayerAdded(player) -- party earnings at 0; alive cookies if mid-party
	PowerService.OnPlayerAdded(player) -- trophy power attributes + respawn movement
	DataService.OnPlayerAdded(player) -- loads saved house + trophies in the background
end

local function onPlayerRemoving(player: Player)
	TycoonService.OnPlayerRemoving(player) -- stop systems and free the plot
	StatueService.OnPlayerRemoving(player)
	TheftService.OnPlayerRemoving(player) -- a thief who leaves: trophy goes home; an owner who leaves: theft continues
	PushService.OnPlayerRemoving(player)
	CookiePartyService.OnPlayerRemoving(player)
	PlayerDataService.OnPlayerRemoving(player)
	PowerService.OnPlayerRemoving(player)
	DataService.OnPlayerRemoving(player) -- saves and releases (does not yield)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script connected (common in Studio testing).
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
