-- TrophyInventoryUI (client only, ModuleScript)
-- Builds the "MY CALEB TROPHIES" panel ONCE, in the same cartoony style as
-- the cookie counter and the feed pop-up: sunny yellow rounded panels, thick
-- dark UIStroke, white FredokaOne text with a dark outline. Built-in UI only.
--
-- Build() returns the ScreenGui (button shown, panel hidden) and its pieces.
-- Tiles for the trophy grid come from NewTile() (the client script pools and
-- reuses them). Icons are drawn from plain frames (TrophyInventoryIcon). This
-- module only makes the UI; it has no logic and never talks to the server.

local TrophyInventoryIcon = require(script.Parent:WaitForChild("TrophyInventoryIcon"))

local TrophyInventoryUI = {}

-- Look (presentation only, same palette as CashDisplay / FeedPromptUI)
local PANEL_COLOR = Color3.fromRGB(255, 214, 64) -- the cookie counter's yellow
local INNER_COLOR = Color3.fromRGB(255, 236, 160) -- lighter yellow for the grid / details
local TILE_FACE_COLOR = Color3.fromRGB(255, 248, 225)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local CLOSE_COLOR = Color3.fromRGB(235, 70, 70)
local NOTE_COLOR = Color3.fromRGB(255, 150, 40) -- the feed pop-up's quick-button orange
local EQUIPPED_COLOR = Color3.fromRGB(70, 200, 80) -- the FEED! green
local FONT = Enum.Font.FredokaOne

-- Colors the client script switches between (tile selection, equip button).
TrophyInventoryUI.Colors = table.freeze({
	TileFace = TILE_FACE_COLOR,
	TileSelected = PANEL_COLOR,
	Equip = EQUIPPED_COLOR,
	Unequip = CLOSE_COLOR,
	Disabled = Color3.fromRGB(150, 150, 150),
	Error = Color3.fromRGB(235, 70, 70),
	Success = EQUIPPED_COLOR,
	UnknownRarity = Color3.fromRGB(235, 235, 235),
})

export type Tile = {
	Button: TextButton,
	Face: Frame,
	Icon: TrophyInventoryIcon.Icon,
	Name: TextLabel,
	Rarity: TextLabel,
	Badge: Frame,
	Scale: UIScale,
}

export type Parts = {
	Gui: ScreenGui,
	ToggleButton: TextButton,
	Panel: Frame,
	PanelScale: UIScale,
	CloseButton: TextButton,
	Collection: TextLabel,
	Active: TextLabel,
	CaseNote: Frame,
	Grid: ScrollingFrame,
	GridLayout: UIGridLayout,
	Empty: TextLabel,
	Details: Frame,
	Placeholder: TextLabel,
	DetailIcon: TrophyInventoryIcon.Icon,
	DetailName: TextLabel,
	DetailRarity: TextLabel,
	DetailPower: TextLabel,
	DetailDescription: TextLabel,
	Message: TextLabel,
	EquipButton: TextButton,
	EquipText: TextLabel,
	Powers: TextLabel,
	SavedNote: TextLabel,
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

-- White outlined text, placed by scale inside its parent. maxSize keeps
-- TextScaled from getting huge on big screens.
local function label(parent: GuiObject, name: string, position: UDim2, size: UDim2, text: string, maxSize: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = text
	l.RichText = false
	l.TextColor3 = TEXT_COLOR
	l.TextScaled = true
	l.TextWrapped = true
	l.Parent = parent
	stroke(l, 2, Enum.ApplyStrokeMode.Contextual)
	if maxSize then
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = maxSize
		limit.Parent = l
	end
	return l
end

-- A chunky rounded button with an outlined text label child.
local function button(parent: GuiObject, name: string, position: UDim2, size: UDim2, color: Color3, text: string): (TextButton, TextLabel)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = position
	b.Size = size
	b.BackgroundColor3 = color
	b.Text = ""
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, UDim.new(0.3, 0))
	stroke(b, 3, Enum.ApplyStrokeMode.Border)
	local t = label(b, "Text", UDim2.fromScale(0.08, 0.15), UDim2.fromScale(0.84, 0.7), text, 28)
	return b, t
end

local function box(parent: GuiObject, name: string, position: UDim2, size: UDim2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = position
	f.Size = size
	f.BackgroundColor3 = INNER_COLOR
	f.Parent = parent
	corner(f, UDim.new(0, 12))
	stroke(f, 3, Enum.ApplyStrokeMode.Border)
	return f
end

-- One grid tile: the button's background is the rarity border, the cream
-- Face sits inside it with the icon, rarity and name; "EQUIPPED" badge on top.
function TrophyInventoryUI.NewTile(grid: ScrollingFrame): Tile
	local b = Instance.new("TextButton")
	b.Name = "Tile"
	b.Text = ""
	b.AutoButtonColor = true
	b.BackgroundColor3 = TEXT_COLOR
	b.Parent = grid
	corner(b, UDim.new(0.14, 0))
	stroke(b, 3, Enum.ApplyStrokeMode.Border)

	local scale = Instance.new("UIScale")
	scale.Parent = b

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.new(1, -8, 1, -8)
	face.BackgroundColor3 = TILE_FACE_COLOR
	face.Parent = b
	corner(face, UDim.new(0.12, 0))

	local icon = TrophyInventoryIcon.New(face, UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.62, 0.5))
	local rarity = label(face, "Rarity", UDim2.fromScale(0.04, 0.56), UDim2.fromScale(0.92, 0.13), "", 14)
	local name = label(face, "Name", UDim2.fromScale(0.04, 0.69), UDim2.fromScale(0.92, 0.29), "", 18)

	local badge = Instance.new("Frame")
	badge.Name = "Equipped"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.5, 0.03)
	badge.Size = UDim2.fromScale(0.86, 0.17)
	badge.BackgroundColor3 = EQUIPPED_COLOR
	badge.Visible = false
	badge.ZIndex = 3
	badge.Parent = b
	corner(badge, UDim.new(0.5, 0))
	stroke(badge, 2, Enum.ApplyStrokeMode.Border)
	local badgeText = label(badge, "Text", UDim2.fromScale(0.06, 0.12), UDim2.fromScale(0.88, 0.76), "EQUIPPED", 14)
	badgeText.ZIndex = 3

	return { Button = b, Face = face, Icon = icon, Name = name, Rarity = rarity, Badge = badge, Scale = scale }
end

function TrophyInventoryUI.Build(parent: Instance): Parts
	local gui = Instance.new("ScreenGui")
	gui.Name = "TrophyInventory"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 4 -- under the Caleb event UI (5) and the feed pop-up (10)

	-- Toggle button: left middle, clear of the cookie counter (bottom-center)
	-- and of the phone thumbstick (bottom-left).
	local toggle = button(gui, "TrophiesButton", UDim2.new(0, 12, 0.5, 0), UDim2.fromScale(0.13, 0.07), PANEL_COLOR, "🏆 TROPHIES")
	toggle.AnchorPoint = Vector2.new(0, 0.5)
	local toggleAspect = Instance.new("UIAspectRatioConstraint")
	toggleAspect.AspectRatio = 2.8
	toggleAspect.Parent = toggle
	local toggleLimit = Instance.new("UISizeConstraint")
	toggleLimit.MinSize = Vector2.new(112, 40)
	toggleLimit.MaxSize = Vector2.new(196, 70)
	toggleLimit.Parent = toggle

	-- Centered panel: scale-sized, fixed shape, clamped for phone and PC.
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.8, 0.82)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.Visible = false
	panel.Parent = gui
	corner(panel, UDim.new(0, 20))
	stroke(panel, 5, Enum.ApplyStrokeMode.Border)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.7
	aspect.Parent = panel
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(400, 235)
	limit.MaxSize = Vector2.new(880, 518)
	limit.Parent = panel
	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel

	-- Header
	label(panel, "Title", UDim2.fromScale(0.03, 0.02), UDim2.fromScale(0.8, 0.11), "MY CALEB TROPHIES", 44)
	local close = button(panel, "Close", UDim2.fromScale(0.97, 0.03), UDim2.fromScale(0.1, 0.1), CLOSE_COLOR, "X")
	close.AnchorPoint = Vector2.new(1, 0)
	close.SizeConstraint = Enum.SizeConstraint.RelativeYY
	local collection = label(panel, "Collection", UDim2.fromScale(0.03, 0.14), UDim2.fromScale(0.46, 0.07), "", 26)
	collection.TextXAlignment = Enum.TextXAlignment.Left
	local active = label(panel, "Active", UDim2.fromScale(0.51, 0.14), UDim2.fromScale(0.46, 0.07), "", 26)
	active.TextXAlignment = Enum.TextXAlignment.Right

	local caseNote = Instance.new("Frame")
	caseNote.Name = "CaseNote"
	caseNote.Position = UDim2.fromScale(0.03, 0.225)
	caseNote.Size = UDim2.fromScale(0.94, 0.07)
	caseNote.BackgroundColor3 = NOTE_COLOR
	caseNote.Visible = false
	caseNote.Parent = panel
	corner(caseNote, UDim.new(0.5, 0))
	stroke(caseNote, 3, Enum.ApplyStrokeMode.Border)
	label(caseNote, "Text", UDim2.fromScale(0.03, 0.12), UDim2.fromScale(0.94, 0.76),
		"Build your Trophy Case at home to activate trophy powers!", 22)

	-- Grid of owned trophies (scrolls; the client sets the cell size)
	local gridBox = box(panel, "GridBox", UDim2.fromScale(0.03, 0.31), UDim2.fromScale(0.57, 0.56))
	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Grid"
	grid.AnchorPoint = Vector2.new(0.5, 0.5)
	grid.Position = UDim2.fromScale(0.5, 0.5)
	grid.Size = UDim2.new(1, -8, 1, -8)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid.ScrollBarThickness = 8
	grid.ScrollBarImageColor3 = OUTLINE_COLOR
	grid.Parent = gridBox
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10) -- room for the EQUIPPED badge
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = grid
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(8, 14)
	layout.CellSize = UDim2.fromOffset(80, 100)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	local empty = label(gridBox, "Empty", UDim2.fromScale(0.08, 0.3), UDim2.fromScale(0.84, 0.4),
		"No trophies yet!\nFeed Caleb to earn one 🏆", 30)

	-- Details of the selected trophy
	local details = box(panel, "Details", UDim2.fromScale(0.62, 0.31), UDim2.fromScale(0.35, 0.56))
	local placeholder = label(details, "Placeholder", UDim2.fromScale(0.08, 0.3), UDim2.fromScale(0.84, 0.4),
		"Tap a trophy to see its power!", 30)
	local detailIcon = TrophyInventoryIcon.New(details, UDim2.fromScale(0.2, 0.04), UDim2.fromScale(0.34, 0.28))
	local detailName = label(details, "Name", UDim2.fromScale(0.38, 0.04), UDim2.fromScale(0.59, 0.17), "", 30)
	local detailRarity = label(details, "Rarity", UDim2.fromScale(0.38, 0.21), UDim2.fromScale(0.59, 0.09), "", 22)
	local detailPower = label(details, "Power", UDim2.fromScale(0.05, 0.34), UDim2.fromScale(0.9, 0.17), "", 34)
	local detailDescription = label(details, "Description", UDim2.fromScale(0.06, 0.52), UDim2.fromScale(0.88, 0.16), "", 20)
	detailDescription.TextColor3 = OUTLINE_COLOR
	local descStroke = detailDescription:FindFirstChildOfClass("UIStroke")
	if descStroke then
		descStroke:Destroy() -- dark quote text reads better without an outline
	end
	local message = label(details, "Message", UDim2.fromScale(0.05, 0.69), UDim2.fromScale(0.9, 0.09), "", 20)
	local equip, equipText = button(details, "Equip", UDim2.fromScale(0.08, 0.8), UDim2.fromScale(0.84, 0.16), EQUIPPED_COLOR, "EQUIP")

	-- Footer
	local powers = label(panel, "Powers", UDim2.fromScale(0.03, 0.885), UDim2.fromScale(0.68, 0.09), "", 24)
	powers.TextXAlignment = Enum.TextXAlignment.Left
	local savedNote = label(panel, "SavedNote", UDim2.fromScale(0.72, 0.9), UDim2.fromScale(0.25, 0.06),
		"Saving is off this session", 18)
	savedNote.TextXAlignment = Enum.TextXAlignment.Right
	savedNote.Visible = false

	gui.Parent = parent

	return {
		Gui = gui,
		ToggleButton = toggle,
		Panel = panel,
		PanelScale = panelScale,
		CloseButton = close,
		Collection = collection,
		Active = active,
		CaseNote = caseNote,
		Grid = grid,
		GridLayout = layout,
		Empty = empty,
		Details = details,
		Placeholder = placeholder,
		DetailIcon = detailIcon,
		DetailName = detailName,
		DetailRarity = detailRarity,
		DetailPower = detailPower,
		DetailDescription = detailDescription,
		Message = message,
		EquipButton = equip,
		EquipText = equipText,
		Powers = powers,
		SavedNote = savedNote,
	}
end

return TrophyInventoryUI
