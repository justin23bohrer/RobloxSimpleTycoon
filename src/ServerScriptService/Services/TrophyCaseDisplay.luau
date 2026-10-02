-- TrophyCaseDisplay (server only)
-- Helper for TrophyService: puts trophy models on a plot's Trophy Case
-- slots (TrophySlot1..N, N = Config.TrophyCaseSlots) and writes each one's
-- name on the case's NameplateN (on the base, right below slot N).
-- Presentation only; TrophyService decides whose trophies are shown, in
-- which order, and when.
--
-- The trophies go in a runtime "CaseTrophies" folder in the plot (not inside
-- the TrophyCase model, so PlotVisibility never tracks them) and are built
-- by TrophyModel. Each stands on its slot facing the slot's LookVector.
--
-- The nameplates, their NameplateGui (TextLabels TrophyName and PowerText),
-- and the case's light are made by tools/trophycase/generate_trophy_case.py;
-- this only changes their text and color. The light starts off, because
-- PlotVisibility does not hide lights: Show turns it on and Clear turns it
-- off.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TrophyVariants = require(ReplicatedStorage.Shared.TrophyVariants)
local TrophyModel = require(script.Parent.TrophyModel)

local TrophyCaseDisplay = {}

local FOLDER = "CaseTrophies"
local CASE_ID = "TrophyCase"
local DARK = Color3.fromRGB(40, 28, 20)
local EMPTY_COLOR = Color3.new(0.75, 0.68, 0.6) -- same as the generator's saved look

local function setLights(case: Instance?, on: boolean)
	if not case then
		return
	end
	for _, item in case:GetDescendants() do
		if item:IsA("Light") then
			item.Enabled = on
		end
	end
end

local function place(l: TextLabel, y: number, height: number)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromScale(0.9, height)
end

-- Writes slot `slot`'s nameplate: the trophy's name in its rarity color and
-- (if it has one) its power, or a dim "EMPTY" when `variantId` is nil.
local function setNameplate(case: Instance, slot: number, variantId: string?)
	local gui = case:FindFirstChild(`Nameplate{slot}`)
	gui = gui and gui:FindFirstChild("NameplateGui")
	local name = gui and gui:FindFirstChild("TrophyName")
	local power = gui and gui:FindFirstChild("PowerText")
	if not (name and name:IsA("TextLabel") and power and power:IsA("TextLabel")) then
		return
	end

	if not variantId then
		name.Text = "EMPTY"
		name.TextColor3 = EMPTY_COLOR
		name.TextTransparency = 0.4
		name.TextStrokeTransparency = 1
		place(name, 0.3, 0.4)
		power.Text = ""
		return
	end

	local variant = TrophyVariants.Get(variantId)
	local rarity = TrophyVariants.Rarities[variant.Rarity]
	local powerText = (variant :: any).PowerText
	name.Text = variant.DisplayName
	name.TextColor3 = if rarity and typeof(rarity.Color) == "Color3" then rarity.Color else Color3.new(1, 1, 1)
	name.TextTransparency = 0
	name.TextStrokeColor3 = DARK
	name.TextStrokeTransparency = 0
	power.TextStrokeColor3 = DARK
	power.TextStrokeTransparency = 0
	if typeof(powerText) == "string" and powerText ~= "" then
		place(name, 0.07, 0.48)
		power.Text = powerText
		place(power, 0.58, 0.34)
	else
		place(name, 0.2, 0.6)
		power.Text = ""
	end
end

-- Removes every trophy shown in the plot's case, sets its nameplates back
-- to "EMPTY", and turns its lights off.
function TrophyCaseDisplay.Clear(plot: Instance)
	local folder = plot:FindFirstChild(FOLDER)
	if folder then
		folder:Destroy()
	end
	local case = plot:FindFirstChild(CASE_ID)
	if case then
		for slot = 1, Config.TrophyCaseSlots do
			setNameplate(case, slot, nil)
		end
	end
	setLights(case, false)
end

-- Shows `records` in slot order (slot 1 = records[1]) on the case's slots,
-- up to Config.TrophyCaseSlots, names them on the nameplates (the rest say
-- "EMPTY"), and turns the case's lights on. Replaces whatever was shown
-- before.
function TrophyCaseDisplay.Show(plot: Instance, case: Instance, records: { { Variant: string } })
	TrophyCaseDisplay.Clear(plot)
	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	for slot = 1, math.min(Config.TrophyCaseSlots, #records) do
		local spot = case:FindFirstChild(`TrophySlot{slot}`)
		if spot and spot:IsA("BasePart") then
			local variantId = records[slot].Variant
			local trophy = TrophyModel.Build(variantId, Config.TrophyCaseScale)
			trophy.Name = `CaseTrophy{slot}`
			trophy:PivotTo(spot.CFrame * CFrame.new(0, spot.Size.Y / 2, 0))
			trophy.Parent = folder
			setNameplate(case, slot, variantId)
		end
	end
	folder.Parent = plot
	setLights(case, true)
end

return TrophyCaseDisplay
