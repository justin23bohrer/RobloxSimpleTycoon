-- TrophyCaseDisplay (server only)
-- Helper for TrophyService: puts trophy models on a plot's Trophy Case
-- slots (TrophySlot1..N, N = Config.TrophyCaseSlots), each with a small
-- nameplate in front of it. Presentation only; TrophyService decides whose
-- trophies are shown, in which order, and when.
--
-- The trophies go in a runtime "CaseTrophies" folder in the plot (not inside
-- the TrophyCase model, so PlotVisibility never tracks them) and are built
-- by TrophyModel. Each stands on its slot facing the slot's LookVector.
--
-- The case's lights (made by tools/trophycase/generate_trophy_case.py) start
-- off, because PlotVisibility does not hide lights: Show turns them on and
-- Clear turns them off.
--
-- House Raid: each shown trophy Model carries its owner's UserId and its
-- InstanceId (HouseRaid.TrophyAttr) and a server ProximityPrompt
-- (HouseRaid.StealPromptName, "Steal Trophy"). A trigger only fires the
-- StealTriggered signal (player, trophyModel); TheftService listens and
-- decides everything. This module never requires TheftService (no cycle).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseRaid = require(ReplicatedStorage.Shared.HouseRaid)
local TrophyVariants = require(ReplicatedStorage.Shared.TrophyVariants)
local TrophyModel = require(script.Parent.TrophyModel)

local TrophyCaseDisplay = {}

local stealTriggered = Instance.new("BindableEvent")
-- Fires (player, trophyModel) when someone finishes holding a StealPrompt.
-- Untrusted: TheftService re-checks everything.
TrophyCaseDisplay.StealTriggered = stealTriggered.Event

local FOLDER = "CaseTrophies"
local CASE_ID = "TrophyCase"
local GOLD = Color3.fromRGB(255, 200, 40)
local DARK = Color3.fromRGB(40, 28, 20)
local PLATE_SIZE = Vector3.new(3.4, 1, 0.12)
local PLATE_TILT = math.rad(25) -- leans back so it faces up at the player
local PLATE_INSET = 0.3 -- from the slot's front edge
local PLATE_MAX_DISTANCE = 60

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

local function label(parent: Instance, name: string, text: string, y: number, height: number, color: Color3)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Text = text
	l.RichText = false
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color
	l.TextStrokeColor3 = DARK
	l.TextStrokeTransparency = 0
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromScale(0.9, height)
	l.Parent = parent
end

-- A gold-rimmed dark plaque standing at the front of the slot: the trophy's
-- name in its rarity color and (if it has one) its power.
local function makeNameplate(spot: BasePart, variantId: string): BasePart
	local variant = TrophyVariants.Get(variantId)
	local rarity = TrophyVariants.Rarities[variant.Rarity]
	local powerText = (variant :: any).PowerText

	local plate = Instance.new("Part")
	plate.Name = "Nameplate"
	plate.Size = PLATE_SIZE
	plate.Color = GOLD
	plate.Material = Enum.Material.SmoothPlastic
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanTouch = false
	plate.CanQuery = false
	plate.CFrame = spot.CFrame
		* CFrame.new(0, -spot.Size.Y / 2 + PLATE_SIZE.Y * math.cos(PLATE_TILT) / 2, -spot.Size.Z / 2 + PLATE_INSET)
		* CFrame.Angles(PLATE_TILT, 0, 0)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "NameplateGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 100
	gui.LightInfluence = 0
	gui.MaxDistance = PLATE_MAX_DISTANCE
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.94, 0.86)
	panel.BackgroundColor3 = DARK
	panel.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = panel
	panel.Parent = gui

	local nameColor = if rarity and typeof(rarity.Color) == "Color3" then rarity.Color else Color3.new(1, 1, 1)
	if typeof(powerText) == "string" and powerText ~= "" then
		label(panel, "TrophyName", variant.DisplayName, 0.06, 0.5, nameColor)
		label(panel, "PowerText", powerText, 0.58, 0.34, Color3.new(1, 1, 1))
	else
		label(panel, "TrophyName", variant.DisplayName, 0.15, 0.7, nameColor)
	end
	gui.Parent = plate
	return plate
end

local function addStealPrompt(trophy: Model, displayName: string)
	local plinth = trophy:FindFirstChild("Plinth")
	if not plinth then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = HouseRaid.StealPromptName
	prompt.ActionText = "Steal Trophy"
	prompt.ObjectText = displayName
	prompt.HoldDuration = Config.TheftHoldSeconds
	prompt.MaxActivationDistance = Config.TheftPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = plinth
	prompt.Triggered:Connect(function(player: Player)
		stealTriggered:Fire(player, trophy)
	end)
end

-- Removes every trophy shown in the plot's case and turns its lights off.
function TrophyCaseDisplay.Clear(plot: Instance)
	local folder = plot:FindFirstChild(FOLDER)
	if folder then
		folder:Destroy()
	end
	setLights(plot:FindFirstChild(CASE_ID), false)
end

-- Shows `records` by slot (slot N = records[N]; a missing N leaves that
-- slot empty, e.g. while its trophy is being carried by a thief) on the
-- case's slots, up to Config.TrophyCaseSlots, and turns the case's lights
-- on. Each trophy is tagged with `ownerUserId` and its InstanceId and gets a
-- StealPrompt. A slot that already shows exactly that trophy is left alone
-- (so a refresh never cancels someone holding its StealPrompt); every other
-- slot is rebuilt or emptied.
function TrophyCaseDisplay.Show(plot: Instance, case: Instance, records: { [number]: { Variant: string, InstanceId: string } }, ownerUserId: number)
	local folder = plot:FindFirstChild(FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = plot
	end
	for slot = 1, Config.TrophyCaseSlots do
		local record = records[slot]
		local spot = case:FindFirstChild(`TrophySlot{slot}`)
		local shown = (folder :: Instance):FindFirstChild(`CaseTrophy{slot}`)
		if not (record and spot and spot:IsA("BasePart")) then
			if shown then
				shown:Destroy()
			end
			continue
		end
		if shown then
			if shown:GetAttribute(HouseRaid.TrophyAttr.InstanceId) == record.InstanceId
				and shown:GetAttribute(HouseRaid.TrophyAttr.OwnerUserId) == ownerUserId
				and shown:GetAttribute("Variant") == record.Variant
			then
				continue -- already showing this trophy
			end
			shown:Destroy()
		end
		local variantId = record.Variant
		local trophy = TrophyModel.Build(variantId, Config.TrophyCaseScale)
		trophy.Name = `CaseTrophy{slot}`
		trophy:SetAttribute(HouseRaid.TrophyAttr.OwnerUserId, ownerUserId)
		trophy:SetAttribute(HouseRaid.TrophyAttr.InstanceId, record.InstanceId)
		trophy:PivotTo(spot.CFrame * CFrame.new(0, spot.Size.Y / 2, 0))
		makeNameplate(spot, variantId).Parent = trophy
		addStealPrompt(trophy, TrophyVariants.Get(variantId).DisplayName)
		trophy.Parent = folder
	end
	setLights(case, true)
end

return TrophyCaseDisplay
