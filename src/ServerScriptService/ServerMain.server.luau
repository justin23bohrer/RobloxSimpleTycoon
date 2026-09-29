-- ServerMain (server entry point)
-- The only server Script. It starts the services and routes player join/leave
-- events to them in a fixed order. Game logic belongs in the services, not here.

local Players = game:GetService("Players")

local Services = script.Parent.Services
local PlayerDataService = require(Services.PlayerDataService)
local TycoonService = require(Services.TycoonService)

TycoonService.Start()

local function onPlayerAdded(player: Player)
	PlayerDataService.OnPlayerAdded(player) -- cash first
	TycoonService.OnPlayerAdded(player) -- then a plot
end

local function onPlayerRemoving(player: Player)
	TycoonService.OnPlayerRemoving(player) -- stop systems and free the plot
	PlayerDataService.OnPlayerRemoving(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script connected (common in Studio testing).
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
