-- BuyButtons (server only)
-- Helper for TycoonService: finds, labels, recolors, and connects a plot's
-- dropper buy buttons. It never decides a purchase; it only reports touches
-- to the callback TycoonService passes in.
--
-- A bought button disappears (pad, ring, and label hidden, no collisions or
-- touches) and comes back when the plot is reset.
--
-- Button N (BuyButtonN in the plot) belongs to Config.Droppers[N]. Its label
-- text ("Dropper N - $Cost") is built from Config so prices live in one place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DropperService = require(script.Parent.DropperService)

local BuyButtons = {}

-- Looks only. The map's buttons start red.
local FOR_SALE_COLOR = Color3.fromRGB(255, 0, 0)

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

-- Shows or hides a button together with its ring and floating label.
local function setVisible(button: BasePart, visible: boolean)
	for _, item in { button :: Instance, table.unpack(button:GetDescendants()) } do
		if item:IsA("BasePart") then
			item.Transparency = if visible then 0 else 1
			item.CanCollide = visible
		elseif item:IsA("BillboardGui") then
			item.Enabled = visible
		end
	end
	button.CanTouch = visible
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

-- Puts every buy button on the plot back to "for sale" and makes it visible.
function BuyButtons.ResetAll(plot: Model)
	for index, entry in Config.Droppers do
		local button = getButton(plot, index)
		if button then
			button.Color = FOR_SALE_COLOR
			local label = button:FindFirstChild("TextLabel", true)
			if label and label:IsA("TextLabel") then
				label.Text = `Dropper {index} - ${entry.Cost}`
			end
			setVisible(button, true)
		end
	end
end

-- Makes one dropper's button disappear after it is bought.
function BuyButtons.SetPurchased(plot: Model, dropperId: string)
	local _, index = DropperService.GetConfig(dropperId)
	local button = if index then getButton(plot, index) else nil
	if button then
		setVisible(button, false)
	end
end

return BuyButtons
