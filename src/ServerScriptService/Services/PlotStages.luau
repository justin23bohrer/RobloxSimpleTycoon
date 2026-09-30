-- PlotStages (server only)
-- Helper for TycoonService: decides which parts of a plot are visible at each
-- stage of the tycoon. It only shows and hides parts; TycoonService decides
-- when a plot is claimed and when a dropper is bought.
--
--   Unclaimed        only the Base and the ClaimPad.
--   Claimed          the ClaimPad disappears; the owner sign, conveyor,
--                    collector, Collect pad, cash tank, and the first buy
--                    button appear.
--   Dropper N bought button N disappears and button N+1 appears (none after
--                    the last dropper).
--
-- Hidden parts cannot be touched (see PlotVisibility), so a hidden button or
-- pad can never be used.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BuyButtons = require(script.Parent.BuyButtons)
local PlotVisibility = require(script.Parent.PlotVisibility)

local PlotStages = {}

-- Everything the owner gets on claim, apart from the buy buttons.
-- CashTank is optional (only looks); the rest are required plot parts.
local CLAIMED_AREA = { "OwnerSign", "Conveyor", "Collector", "CollectPad", "CashTank" }

local function setArea(plot: Model, visible: boolean)
	for _, name in CLAIMED_AREA do
		local part = plot:FindFirstChild(name)
		if part then
			if visible then
				PlotVisibility.Show(part)
			else
				PlotVisibility.Hide(part)
			end
		end
	end
end

-- Nothing but the Base and the ClaimPad.
function PlotStages.ShowUnclaimed(plot: Model)
	setArea(plot, false)
	BuyButtons.HideAll(plot)
	PlotVisibility.Show(plot.ClaimPad)
end

-- The owner's collect area and the first buy button.
function PlotStages.ShowClaimed(plot: Model)
	PlotVisibility.Hide(plot.ClaimPad)
	setArea(plot, true)
	BuyButtons.Show(plot, 1)
end

-- Removes the bought dropper's button and reveals the next one, if any.
function PlotStages.ShowAfterPurchase(plot: Model, index: number)
	BuyButtons.SetPurchased(plot, index)
	if Config.Droppers[index + 1] then
		BuyButtons.Show(plot, index + 1)
	end
end

return PlotStages
