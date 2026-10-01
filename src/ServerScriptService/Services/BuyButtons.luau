-- BuyButtons (server only)
-- Helper for TycoonService: finds, labels, shows/hides, and connects a plot's
-- buy buttons (dropper BuyButtonN and build BuildButtonN parts, see
-- Purchases). It never decides a purchase; it only reports touches to the
-- callback TycoonService passes in.
--
-- Buttons are hidden until TycoonService unlocks them (see PlotStages). A
-- shown dropper button appears together with its DropperSpotN, so the player
-- sees where that dropper will go. A bought button (and its spot) disappears.
-- Hidden buttons cannot be touched.
--
-- Label text ("Dropper N" or the build's Name, over a yellow "🍪 Cost", or
-- "FREE!") is built from Config so prices live in one place.

local Purchases = require(script.Parent.Purchases)
local PlotVisibility = require(script.Parent.PlotVisibility)

local BuyButtons = {}

-- Looks only. The map's dropper buttons start red, build buttons orange.
local FOR_SALE_COLORS = {
	Dropper = Color3.fromRGB(255, 0, 0),
	Build = Color3.fromRGB(255, 140, 0),
}
local PRICE_COLOR = "#FFE14D" -- sunny yellow

local function getButton(plot: Model, purchase: Purchases.Purchase): BasePart?
	local button = plot:FindFirstChild(purchase.ButtonName)
	if button and button:IsA("BasePart") then
		return button
	end
	return nil
end

-- The button, plus a dropper's spot, which appear and disappear together.
local function getParts(plot: Model, purchase: Purchases.Purchase): { Instance }
	local parts = {}
	local button = getButton(plot, purchase)
	if button then
		table.insert(parts, button)
	end
	if purchase.Kind == "Dropper" then
		local spot = plot:FindFirstChild(`DropperSpot{purchase.Index}`)
		if spot then
			table.insert(parts, spot)
		end
	end
	return parts
end

-- Two lines: name, then the price in yellow (the label is RichText).
local function labelText(purchase: Purchases.Purchase): string
	local entry = purchase.Entry
	local name = if purchase.Kind == "Dropper" then `Dropper {purchase.Index}` else entry.Name
	local price = if entry.Cost == 0 then "FREE!" else `🍪 {entry.Cost}`
	return `{name}\n<font color="{PRICE_COLOR}">{price}</font>`
end

-- Calls onTouched(hit, purchaseId) whenever a part touches one of the plot's
-- buy buttons. Call once per plot.
function BuyButtons.Connect(plot: Model, onTouched: (hit: BasePart, purchaseId: string) -> ())
	for _, purchase in Purchases.All() do
		local button = plot:FindFirstChild(purchase.ButtonName) :: BasePart
		button.Touched:Connect(function(hit)
			onTouched(hit, purchase.Id)
		end)
	end
end

-- Puts every buy button back to "for sale" and hides it (and its spot).
function BuyButtons.HideAll(plot: Model)
	for _, purchase in Purchases.All() do
		local button = getButton(plot, purchase)
		if button then
			button.Color = FOR_SALE_COLORS[purchase.Kind]
			local label = button:FindFirstChild("TextLabel", true)
			if label and label:IsA("TextLabel") then
				label.Text = labelText(purchase)
			end
		end
		for _, part in getParts(plot, purchase) do
			PlotVisibility.Hide(part)
		end
	end
end

-- Shows a purchase's button (and a dropper's spot).
function BuyButtons.Show(plot: Model, purchaseId: string)
	local purchase = Purchases.Get(purchaseId)
	if purchase then
		for _, part in getParts(plot, purchase) do
			PlotVisibility.Show(part)
		end
	end
end

-- Makes a purchase's button (and spot) disappear after it is bought.
function BuyButtons.SetPurchased(plot: Model, purchaseId: string)
	local purchase = Purchases.Get(purchaseId)
	if purchase then
		for _, part in getParts(plot, purchase) do
			PlotVisibility.Hide(part)
		end
	end
end

return BuyButtons
