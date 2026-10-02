-- DevPhotoMode (server only)
-- TESTING ONLY: Config.DevPhotoMode, for icon / thumbnail screenshots. Does
-- nothing unless Shared/PhotoMode.Enabled (the switch is on AND the game runs
-- in Roblox Studio), so a published game is never affected.
--
-- When on:
-- * Sets Lighting.ClockTime to Config.DevPhotoClockTime (sunny afternoon).
-- * Gives each joining player the first free plot (TycoonService.TryClaimPlot,
--   the same as stepping on its ClaimPad). TycoonService.RestorePurchases then
--   builds every purchase for free (Photo Mode branch there).
-- The rest of Photo Mode lives elsewhere: DataService loads and saves nothing,
-- DevTrophies gives session-only trophies (opens the back door), and the
-- client's PhotoCamera does the camera presets and hiding the UI.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PhotoMode = require(ReplicatedStorage.Shared.PhotoMode)
local TycoonService = require(script.Parent.TycoonService)

local DevPhotoMode = {}

-- Claims the first free plot (lowest PlotId) for the player.
local function claimFirstFreePlot(player: Player)
	if TycoonService.GetTycoon(player) then
		return
	end
	local plots = Workspace:WaitForChild("Map"):WaitForChild("Plots"):GetChildren()
	table.sort(plots, function(a, b)
		return (a:GetAttribute("PlotId") or math.huge) < (b:GetAttribute("PlotId") or math.huge)
	end)
	for _, plot in plots do
		if plot:IsA("Model") and TycoonService.TryClaimPlot(player, plot) then
			return
		end
	end
	warn(`[DevPhotoMode] no free plot for {player.Name}`)
end

-- Called once by ServerMain after TycoonService.Start.
function DevPhotoMode.Start()
	if not PhotoMode.Enabled then
		return
	end
	print("[DevPhotoMode] Photo Mode is ON (Studio only): free fully built plot, nothing saved. Keys 1-6 shots, 0 normal camera, H hide UI.")
	Lighting.ClockTime = Config.DevPhotoClockTime
	Players.PlayerAdded:Connect(claimFirstFreePlot)
	for _, player in Players:GetPlayers() do
		task.spawn(claimFirstFreePlot, player)
	end
end

return DevPhotoMode
