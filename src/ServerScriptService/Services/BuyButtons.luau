-- BuyButtons (server only)
-- Helper for TycoonService: finds, labels, shows/hides, and connects a plot's
-- dropper buy buttons. It never decides a purchase; it only reports touches
-- to the callback TycoonService passes in.
--
-- Buttons are hidden until TycoonService unlocks them one at a time (see
-- PlotStages). A shown button appears together with its DropperSpotN, so the
-- player sees where that dropper will go. A bought button and its spot
-- disappear. Hidden buttons cannot be touched.
--
-- Button N (BuyButtonN in the plot) belongs to Config.Droppers[N]. Its label
-- text ("Dropper N" over a yellow "$Cost", or "FREE!") is built from Config so
-- prices live in one place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlotVisibility = require(script.Parent.PlotVisibility)

local BuyButtons = {}

-- Looks only. The map's buttons start red.
local FOR_SALE_COLOR = Color3.fromRGB(255, 0, 0)
local PRICE_COLOR = "#FFE14D" -- sunny yellow, like the cash display panel

-- Name of the plot part for the dropper at this position in Config.Droppers.
function BuyButtons.PartName(index: number): string
	return `BuyButton{index}`
end

local function getButton(plot: Model, index: number): BasePart?
	local button = plot:FindFirstChild(BuyButtons.PartName(index))
	if button and button:IsA("BasePart") then
		return button
	end
	return nil
end

-- The button and the dropper spot that appear and disappear together.
local function getParts(plot: Model, index: number): { Instance }
	local parts = {}
	local button = getButton(plot, index)
	if button then
		table.insert(parts, button)
	end
	local spot = plot:FindFirstChild(`DropperSpot{index}`)
	if spot then
		table.insert(parts, spot)
	end
	return parts
end

-- Calls onTouched(hit, dropperId) whenever a part touches one of the plot's
-- buy buttons. Call once per plot.
function BuyButtons.Connect(plot: Model, onTouched: (hit: BasePart, dropperId: string) -> ())
	for index, entry in Config.Droppers do
		local button = plot:FindFirstChild(BuyButtons.PartName(index)) :: BasePart
		button.Touched:Connect(function(hit)
			onTouched(hit, entry.Id)
		end)
	end
end

-- Puts every buy button back to "for sale" and hides it and its spot.
function BuyButtons.HideAll(plot: Model)
	for index, entry in Config.Droppers do
		local button = getButton(plot, index)
		if button then
			button.Color = FOR_SALE_COLOR
			local label = button:FindFirstChild("TextLabel", true)
			if label and label:IsA("TextLabel") then
				-- Two lines: name, then the price in yellow (the label is RichText).
				local price = if entry.Cost == 0 then "FREE!" else `${entry.Cost}`
				label.Text = `Dropper {index}\n<font color="{PRICE_COLOR}">{price}</font>`
			end
		end
		for _, part in getParts(plot, index) do
			PlotVisibility.Hide(part)
		end
	end
end

-- Shows button N and the spot where its dropper will go.
function BuyButtons.Show(plot: Model, index: number)
	for _, part in getParts(plot, index) do
		PlotVisibility.Show(part)
	end
end

-- Makes button N and its spot disappear after the dropper is bought.
function BuyButtons.SetPurchased(plot: Model, index: number)
	for _, part in getParts(plot, index) do
		PlotVisibility.Hide(part)
	end
end

return BuyButtons
