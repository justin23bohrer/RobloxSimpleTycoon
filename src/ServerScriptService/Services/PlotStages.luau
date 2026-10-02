-- PlotStages (server only)
-- Helper for TycoonService: decides which parts of a plot are visible at each
-- stage of the tycoon. It only shows and hides parts; TycoonService decides
-- when a plot is claimed and when something is bought.
--
--   Unclaimed   only the Base and the ClaimPad.
--   Claimed     the ClaimPad disappears; the owner sign, conveyor, collector,
--               Collect pad, cash tank, and the buttons of purchases with no
--               After (Dropper 1) appear.
--   X bought    X's button disappears; a build's Parts appear (walls,
--               stairs, second floor); the buttons of purchases whose After
--               is X appear.
--   Maxed       every dropper and build bought: the TrophyButtons of trophy
--               builds not bought yet appear (garage, backyard spots). A
--               bought trophy build's Parts appear like a build's.
--
-- Hidden parts cannot be touched (see PlotVisibility), so a hidden button or
-- pad can never be used.

local BuyButtons = require(script.Parent.BuyButtons)
local PlotVisibility = require(script.Parent.PlotVisibility)
local Purchases = require(script.Parent.Purchases)

local PlotStages = {}

-- Everything the owner gets on claim, apart from the buy buttons.
-- CashTank is optional (only looks); the rest are required plot parts.
local CLAIMED_AREA = { "OwnerSign", "Conveyor", "Collector", "CollectPad", "CashTank" }

-- includeEffects: also switch the parts' fires/particles/lights (trophy
-- builds only, see PlotVisibility).
local function setVisible(plot: Model, names: { string }, visible: boolean, includeEffects: boolean?)
	for _, name in names do
		local part = plot:FindFirstChild(name)
		if part then
			if visible then
				PlotVisibility.Show(part)
			else
				PlotVisibility.Hide(part, includeEffects)
			end
		end
	end
end

local function showUnlockedBy(plot: Model, purchaseId: string?)
	for _, purchase in Purchases.UnlockedBy(purchaseId) do
		BuyButtons.Show(plot, purchase.Id)
	end
end

-- Nothing but the Base and the ClaimPad.
function PlotStages.ShowUnclaimed(plot: Model)
	setVisible(plot, CLAIMED_AREA, false)
	BuyButtons.HideAll(plot)
	for _, purchase in Purchases.All() do
		if purchase.Kind ~= "Dropper" then
			setVisible(plot, purchase.Entry.Parts, false, purchase.Kind == "TrophyBuild")
		end
	end
	PlotVisibility.Show(plot.ClaimPad)
end

-- The owner's collect area and the first buy button(s).
function PlotStages.ShowClaimed(plot: Model)
	PlotVisibility.Hide(plot.ClaimPad)
	setVisible(plot, CLAIMED_AREA, true)
	showUnlockedBy(plot, nil)
end

-- Removes the bought button, shows what a build built, and reveals the
-- buttons it unlocks.
function PlotStages.ShowAfterPurchase(plot: Model, purchaseId: string)
	BuyButtons.SetPurchased(plot, purchaseId)
	local purchase = Purchases.Get(purchaseId)
	if purchase and purchase.Kind ~= "Dropper" then
		setVisible(plot, purchase.Entry.Parts, true)
	end
	showUnlockedBy(plot, purchaseId)
end

-- The house is maxed: shows the buttons of the trophy builds not in
-- `purchased` yet. Safe to call again (shown buttons stay shown).
function PlotStages.ShowTrophyButtons(plot: Model, purchased: { [string]: boolean })
	for _, purchase in Purchases.TrophyBuilds() do
		if not purchased[purchase.Id] then
			BuyButtons.Show(plot, purchase.Id)
		end
	end
end

return PlotStages
