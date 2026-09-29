-- CollectorService (server only)
-- Handles each plot's Collector and CollectPad:
--   1. A drop touching plot.Collector adds its value to that plot's stored
--      (uncollected) cash. DropperService.ClaimDrop validates and destroys it.
--   2. The plot's owner touching plot.CollectPad moves the stored cash into
--      their cash via EconomyService.AddCash.
-- The CollectPad label shows "Collect $<stored>" (or "Collect" when empty).
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

local Players = game:GetService("Players")

local DropperService = require(script.Parent.DropperService)
local EconomyService = require(script.Parent.EconomyService)

local CollectorService = {}

local storedCashByPlot: { [Model]: number } = {}

local function updateLabel(plot: Model)
	local label = plot.CollectPad:FindFirstChild("TextLabel", true)
	if label and label:IsA("TextLabel") then
		local stored = storedCashByPlot[plot] or 0
		label.Text = if stored > 0 then `Collect ${stored}` else "Collect"
	end
end

local function onCollectorTouched(plot: Model, hit: BasePart)
	local value = DropperService.ClaimDrop(hit, plot)
	if value == nil then
		return
	end
	storedCashByPlot[plot] = (storedCashByPlot[plot] or 0) + value
	updateLabel(plot)
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
	if not EconomyService.AddCash(player, amount) then
		-- Payout failed (e.g. player data missing); keep the cash on the plot.
		storedCashByPlot[plot] += amount
	end
	updateLabel(plot)
end

-- Connects the Collector and CollectPad touch handlers for a plot. Called once
-- per plot at server start.
function CollectorService.SetupPlot(plot: Model)
	if storedCashByPlot[plot] ~= nil then
		return -- already set up; never connect twice
	end
	storedCashByPlot[plot] = 0
	updateLabel(plot)

	plot.Collector.Touched:Connect(function(hit)
		onCollectorTouched(plot, hit)
	end)
	plot.CollectPad.Touched:Connect(function(hit)
		onCollectPadTouched(plot, hit)
	end)
end

-- Clears a plot's stored cash (called when the plot is released).
function CollectorService.ResetPlot(plot: Model)
	storedCashByPlot[plot] = 0
	updateLabel(plot)
end

return CollectorService
