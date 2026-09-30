-- BuyButtons (server only)
-- Helper for TycoonService: finds, labels, recolors, and connects a plot's
-- dropper buy buttons. It never decides a purchase; it only reports touches
-- to the callback TycoonService passes in.
--
-- Button N (BuyButtonN in the plot) belongs to Config.Droppers[N]. Its label
-- text ("Dropper N - $Cost") is built from Config so prices live in one place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DropperService = require(script.Parent.DropperService)

local BuyButtons = {}

-- Looks only. The map's buttons start red.
local FOR_SALE_COLOR = Color3.fromRGB(255, 0, 0)
local PURCHASED_COLOR = Color3.fromRGB(80, 80, 80)
local PURCHASED_TEXT = "Purchased"

-- Name of the plot part for the dropper at this position in Config.Droppers.
function BuyButtons.PartName(index: number): string
	return `BuyButton{index}`
end

local function setButton(plot: Model, index: number, color: Color3, text: string)
	local button = plot:FindFirstChild(BuyButtons.PartName(index))
	if not button or not button:IsA("BasePart") then
		return
	end
	button.Color = color
	local label = button:FindFirstChild("TextLabel", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
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

-- Puts every buy button on the plot back to "for sale".
function BuyButtons.ResetAll(plot: Model)
	for index, entry in Config.Droppers do
		setButton(plot, index, FOR_SALE_COLOR, `Dropper {index} - ${entry.Cost}`)
	end
end

-- Grays out one dropper's button and labels it "Purchased".
function BuyButtons.SetPurchased(plot: Model, dropperId: string)
	local _, index = DropperService.GetConfig(dropperId)
	if index then
		setButton(plot, index, PURCHASED_COLOR, PURCHASED_TEXT)
	end
end

return BuyButtons
