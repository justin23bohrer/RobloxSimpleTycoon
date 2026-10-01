-- ServerMain (server entry point)
-- The only server Script. It starts the services and routes player join/leave
-- events to them in a fixed order. Game logic belongs in the services, not here.

local Players = game:GetService("Players")

local Services = script.Parent.Services
local PlayerDataService = require(Services.PlayerDataService)
local StatueService = require(Services.StatueService)
local TycoonService = require(Services.TycoonService)

TycoonService.Start()
StatueService.Start()

-- Players get a plot by stepping on a ClaimPad (TycoonService), not on join.
local function onPlayerAdded(player: Player)
	PlayerDataService.OnPlayerAdded(player)
end

local function onPlayerRemoving(player: Player)
	TycoonService.OnPlayerRemoving(player) -- stop systems and free the plot
	StatueService.OnPlayerRemoving(player)
	PlayerDataService.OnPlayerRemoving(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script connected (common in Studio testing).
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
