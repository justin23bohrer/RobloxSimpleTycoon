-- CollectorService (server only)
-- Handles each plot's collectors and CollectPad:
--   1. A drop touching one of the plot's collectors (Collector on the first
--      floor, Collector2 on the second; see DropperService.CollectorNames)
--      adds its value to that plot's single stored
--      (uncollected) cash. DropperService.ClaimDrop validates and destroys it.
--   2. The plot's owner touching plot.CollectPad moves the stored cash into
--      their cash via EconomyService.AddCash.
-- The stored amount is never shown as text. CollectorDisplay shows it as
-- small cookies filling the CashTank ("COOKIE JAR") behind the pad (presentation only).
--
-- Named CollectorService (not CollectionService) to avoid confusion with
-- Roblox's built-in game:GetService("CollectionService") tagging service.
--
-- Security notes:
-- * Drop values come only from DropperService.ClaimDrop(hit, plot), which
--   returns nil for anything that isn't a live drop from THIS plot. A value is
--   never read from the touching part.
-- * Payout only if plot:GetAttribute("OwnerUserId") == player.UserId.
-- * Stored cash is set to 0 BEFORE paying out so a double touch cannot pay twice.
-- * The owner's CollectBonus trophy power (PowerService) is added at payout:
--   paid = floor(stored * (1 + CollectBonus)). If the payout fails, only the
--   stored amount (without the bonus) goes back on the plot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrophyPowers = require(ReplicatedStorage.Shared.TrophyPowers)

local CollectorDisplay = require(script.Parent.CollectorDisplay)
local DropperService = require(script.Parent.DropperService)
local EconomyService = require(script.Parent.EconomyService)
local PowerService = require(script.Parent.PowerService)

local CollectorService = {}

local storedCashByPlot: { [Model]: number } = {}

local function onCollectorTouched(plot: Model, hit: BasePart)
	local value = DropperService.ClaimDrop(hit, plot)
	if value == nil then
		return
	end
	storedCashByPlot[plot] = (storedCashByPlot[plot] or 0) + value
	CollectorDisplay.AddCube(plot)
end

local function onCollectPadTouched(plot: Model, hit: BasePart)
	local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
	if not player or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end

	local amount = storedCashByPlot[plot] or 0
	if amount <= 0 then
		return
	end

	storedCashByPlot[plot] = 0
	local bonus = PowerService.Get(player, TrophyPowers.Stat.CollectBonus)
	local payout = math.floor(amount * (1 + bonus))
	if not EconomyService.AddCash(player, payout) then
		-- Payout failed (e.g. player data missing); keep the cash (and the
		-- cubes in the tank) on the plot.
		storedCashByPlot[plot] += amount
		return
	end
	CollectorDisplay.Clear(plot, true)
end

-- Connects the collector and CollectPad touch handlers for a plot. Called once
-- per plot at server start.
function CollectorService.SetupPlot(plot: Model)
	if storedCashByPlot[plot] ~= nil then
		return -- already set up; never connect twice
	end
	storedCashByPlot[plot] = 0
	CollectorDisplay.Setup(plot)

	for _, name in DropperService.CollectorNames() do
		local collector = plot:FindFirstChild(name)
		if collector and collector:IsA("BasePart") then
			collector.Touched:Connect(function(hit)
				onCollectorTouched(plot, hit)
			end)
		end
	end
	plot.CollectPad.Touched:Connect(function(hit)
		onCollectPadTouched(plot, hit)
	end)
end

-- Clears a plot's stored cash (called when the plot is released).
function CollectorService.ResetPlot(plot: Model)
	storedCashByPlot[plot] = 0
	CollectorDisplay.Clear(plot, false)
end

return CollectorService
