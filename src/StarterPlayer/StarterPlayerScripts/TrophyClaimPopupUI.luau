-- TrophyClaimPopupUI (client only, ModuleScript)
-- Builds the "NEW TROPHY!" pop-up ONCE, in the trophy inventory's cartoony
-- style: sunny yellow rounded panel, thick dark UIStroke, white FredokaOne
-- text with a dark outline, a rarity-colored header and shine. Built-in UI
-- only. This module only makes the UI; TrophyClaimPopup fills and drives it.

local TrophyInventoryIcon = require(script.Parent:WaitForChild("TrophyInventoryIcon"))

local TrophyClaimPopupUI = {}

local PANEL_COLOR = Color3.fromRGB(255, 214, 64)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local CLOSE_COLOR = Color3.fromRGB(235, 70, 70)
local EQUIP_COLOR = Color3.fromRGB(70, 200, 80)
local FONT = Enum.Font.FredokaOne
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 90, 160), Color3.fromRGB(90, 170, 255), Color3.fromRGB(110, 220, 90),
	Color3.fromRGB(255, 200, 40), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 255, 255),
}
local CONFETTI_COUNT = 18

TrophyClaimPopupUI.Colors = table.freeze({
	Equip = EQUIP_COLOR,
	Disabled = Color3.fromRGB(150, 150, 150),
	Error = Color3.fromRGB(235, 70, 70),
	Info = OUTLINE_COLOR,
	Note = Color3.fromRGB(230, 110, 20),
})

export type Parts = {
	Gui: ScreenGui,
	Panel: Frame,
	Scale: UIScale,
	Header: Frame,
	Shine: Frame,
	ShineGradient: UIGradient,
	Icon: TrophyInventoryIcon.Icon,
	Name: TextLabel,
	Rarity: TextLabel,
	Power: TextLabel,
	Description: TextLabel,
	Note: TextLabel,
	Info: TextLabel,
	EquipButton: TextButton,
	EquipText: TextLabel,
	Equipped: TextLabel,
	CloseButton: TextButton,
	Confetti: { Frame },
}

local function corner(parent: GuiObject, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function stroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode)
	local s = Instance.new("UIStroke")
	s.Color = OUTLINE_COLOR
	s.Thickness = thickness
	s.ApplyStrokeMode = mode
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
end

-- Outlined (or, with plain = true, dark un-outlined) text placed by scale.
local function label(parent: GuiObject, name: string, y: number, height: number, maxSize: number, plain: boolean?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = UDim2.fromScale(0.06, y)
	l.Size = UDim2.fromScale(0.88, height)
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = ""
	l.TextColor3 = if plain then OUTLINE_COLOR else TEXT_COLOR
	l.TextScaled = true
	l.TextWrapped = true
	l.ZIndex = 2
	l.Parent = parent
	if not plain then
		stroke(l, 2, Enum.ApplyStrokeMode.Contextual)
	end
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = l
	return l
end

local function button(parent: GuiObject, name: string, x: number, color: Color3, text: string): (TextButton, TextLabel)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = UDim2.fromScale(x, 0.835)
	b.Size = UDim2.fromScale(0.42, 0.135)
	b.BackgroundColor3 = color
	b.Text = ""
	b.AutoButtonColor = true
	b.ZIndex = 2
	b.Parent = parent
	corner(b, UDim.new(0.3, 0))
	stroke(b, 3, Enum.ApplyStrokeMode.Border)
	local t = label(b, "Text", 0.15, 0.7, 30)
	t.Text = text
	return b, t
end

function TrophyClaimPopupUI.Build(parent: Instance): Parts
	local gui = Instance.new("ScreenGui")
	gui.Name = "TrophyClaimPopup"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 8 -- over the inventory (4) and event UI (5), under the feed pop-up (10)
	gui.Enabled = false

	-- Centered, taller than wide, scale-sized and clamped for phone and PC.
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.6, 0.82)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.Parent = gui
	corner(panel, UDim.new(0, 22))
	stroke(panel, 5, Enum.ApplyStrokeMode.Border)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 0.82
	aspect.Parent = panel
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(250, 305)
	limit.MaxSize = Vector2.new(400, 488)
	limit.Parent = panel
	local scale = Instance.new("UIScale")
	scale.Parent = panel

	-- Confetti pieces (pooled; TrophyClaimPopup bursts them from the icon).
	local confetti = {}
	for i = 1, CONFETTI_COUNT do
		local piece = Instance.new("Frame")
		piece.Name = "Confetti"
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Size = UDim2.fromOffset(10, 6)
		piece.BackgroundColor3 = CONFETTI_COLORS[(i - 1) % #CONFETTI_COLORS + 1]
		piece.BorderSizePixel = 0
		piece.Visible = false
		piece.ZIndex = 4
		piece.Parent = panel
		corner(piece, UDim.new(0.3, 0))
		table.insert(confetti, piece)
	end

	-- Header banner in the rarity color, sticking out over the top edge.
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.AnchorPoint = Vector2.new(0.5, 0.5)
	header.Position = UDim2.fromScale(0.5, 0.035)
	header.Size = UDim2.fromScale(0.8, 0.11)
	header.ZIndex = 3
	header.Parent = panel
	corner(header, UDim.new(0.5, 0))
	stroke(header, 4, Enum.ApplyStrokeMode.Border)
	local title = label(header, "Title", 0.12, 0.76, 40)
	title.Text = "🏆 NEW TROPHY!"
	title.ZIndex = 3

	-- Rotating shine behind the icon.
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.5, 0.24)
	shine.Size = UDim2.fromScale(0.44, 0.44)
	shine.SizeConstraint = Enum.SizeConstraint.RelativeXX
	shine.BackgroundTransparency = 0.15
	shine.Parent = panel
	corner(shine, UDim.new(0.5, 0))
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, 0.8),
		NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.75, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	gradient.Parent = shine

	local icon = TrophyInventoryIcon.New(panel, UDim2.fromScale(0.5, 0.115), UDim2.fromScale(0.3, 0.3))
	icon.Root.SizeConstraint = Enum.SizeConstraint.RelativeXX
	icon.Root.ZIndex = 2

	local name = label(panel, "Name", 0.425, 0.085, 36)
	local rarity = label(panel, "Rarity", 0.51, 0.055, 26)
	local power = label(panel, "Power", 0.57, 0.085, 40)
	local description = label(panel, "Description", 0.66, 0.065, 20, true)
	local note = label(panel, "Note", 0.728, 0.05, 20)
	local info = label(panel, "Info", 0.778, 0.05, 18, true)

	local equip, equipText = button(panel, "Equip", 0.055, EQUIP_COLOR, "EQUIP")
	local equipped = label(panel, "Equipped", 0.835, 0.135, 34)
	equipped.Position = UDim2.fromScale(0.055, 0.835)
	equipped.Size = UDim2.fromScale(0.42, 0.135)
	equipped.TextColor3 = EQUIP_COLOR
	equipped.Text = "EQUIPPED ✓"
	equipped.Visible = false
	local close = button(panel, "Close", 0.525, CLOSE_COLOR, "CLOSE")

	gui.Parent = parent

	return {
		Gui = gui,
		Panel = panel,
		Scale = scale,
		Header = header,
		Shine = shine,
		ShineGradient = gradient,
		Icon = icon,
		Name = name,
		Rarity = rarity,
		Power = power,
		Description = description,
		Note = note,
		Info = info,
		EquipButton = equip,
		EquipText = equipText,
		Equipped = equipped,
		CloseButton = close,
		Confetti = confetti,
	}
end

return TrophyClaimPopupUI
