-- FeedPromptUI (client only, ModuleScript)
-- Builds the "feed the statue" pop-up in the same cartoony style as the
-- cookie counter (CashDisplay): sunny yellow rounded panel, thick dark
-- outline, white FredokaOne text with a dark outline. Built-in UI only.
--
-- Build() returns the ScreenGui (disabled) and the pieces
-- FeedPrompt.client.luau needs. This module only makes the UI; it has no
-- logic and never talks to the server.

local FeedPromptUI = {}

-- Look (presentation only)
local PANEL_COLOR = Color3.fromRGB(255, 214, 64) -- same yellow as the cookie counter
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local COOKIE_COLOR = Color3.fromRGB(214, 160, 90)
local PREVIEW_COLOR = Color3.fromRGB(255, 232, 180) -- lighter cookie: "after this feed"
local FEED_COLOR = Color3.fromRGB(70, 200, 80)
local CANCEL_COLOR = Color3.fromRGB(235, 70, 70)
local QUICK_COLOR = Color3.fromRGB(255, 150, 40)
local FONT = Enum.Font.FredokaOne
local BAR_INSET = 4 -- px of white between the progress outline and the fill

export type Parts = {
	Gui: ScreenGui,
	Scale: UIScale,
	Title: TextLabel,
	Progress: TextLabel,
	ProgressFill: Frame, -- how fat Caleb is now
	ProgressPreview: Frame, -- how fat he'd be after feeding the amount in the box
	Have: TextLabel,
	AmountBox: TextBox,
	QuickButtons: { [string]: TextButton }, -- "10", "100", "1K", "ALL"
	Message: TextLabel,
	FeedButton: TextButton,
	CancelButton: TextButton,
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

-- White outlined text, placed by scale inside its parent.
local function label(parent: GuiObject, name: string, position: UDim2, size: UDim2, text: string): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = text
	l.TextColor3 = TEXT_COLOR
	l.TextScaled = true
	l.Parent = parent
	stroke(l, 2.5, Enum.ApplyStrokeMode.Contextual)
	return l
end

-- A chunky rounded button. The text is a child label so it can have its own
-- outline (one UIStroke outlines the button, another the text).
local function button(parent: GuiObject, name: string, position: UDim2, size: UDim2, color: Color3, text: string): TextButton
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
	label(b, "Text", UDim2.fromScale(0.08, 0.15), UDim2.fromScale(0.84, 0.7), text)
	return b
end

-- The cookie progress bar: a white rounded track with a dark outline, and
-- the Preview + Fill frames (both start empty; set their Size X scale to
-- fill them). Also used by the bar above the statue (StatueBar) so the two
-- look the same.
function FeedPromptUI.ProgressBar(parent: GuiObject, position: UDim2, size: UDim2): (Frame, Frame, Frame)
	local track = Instance.new("Frame")
	track.Name = "ProgressTrack"
	track.Position = position
	track.Size = size
	track.BackgroundColor3 = TEXT_COLOR
	track.Parent = parent
	corner(track, UDim.new(0.5, 0))
	stroke(track, 3, Enum.ApplyStrokeMode.Border)

	-- The fill and preview live in this inner area, inset BAR_INSET px from
	-- the track on every side, so they always sit inside the outline with a
	-- small white gap. (ClipsDescendants only clips to a rectangle, not to
	-- rounded corners, so a full-height fill used to poke into the outline.)
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -BAR_INSET * 2, 1, -BAR_INSET * 2)
	inner.BackgroundTransparency = 1
	inner.Parent = track

	-- Drawn under the fill, so only the part past the current fill shows.
	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Size = UDim2.fromScale(0, 1)
	preview.BackgroundColor3 = PREVIEW_COLOR
	preview.BorderSizePixel = 0
	preview.ZIndex = 1
	preview.Parent = inner
	corner(preview, UDim.new(0.5, 0))

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = COOKIE_COLOR
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = inner
	corner(fill, UDim.new(0.5, 0))

	return track, fill, preview
end

function FeedPromptUI.Build(parent: Instance): Parts
	local gui = Instance.new("ScreenGui")
	gui.Name = "FeedPrompt"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10 -- above the cookie counter

	-- Centered panel: scale-sized, fixed shape, clamped for phone and PC.
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.45)
	panel.Size = UDim2.fromScale(0.5, 0.6)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.Parent = gui
	corner(panel, UDim.new(0.08, 0))
	stroke(panel, 5, Enum.ApplyStrokeMode.Border)

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.35
	aspect.Parent = panel

	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(300, 222)
	limit.MaxSize = Vector2.new(560, 415)
	limit.Parent = panel

	local popScale = Instance.new("UIScale")
	popScale.Parent = panel

	local title = label(panel, "Title", UDim2.fromScale(0.05, 0.03), UDim2.fromScale(0.9, 0.2), "")

	local progress = label(panel, "Progress", UDim2.fromScale(0.06, 0.25), UDim2.fromScale(0.88, 0.09), "")

	local _, fill, preview = FeedPromptUI.ProgressBar(panel, UDim2.fromScale(0.06, 0.36), UDim2.fromScale(0.88, 0.07))

	local box = Instance.new("TextBox")
	box.Name = "Amount"
	box.Position = UDim2.fromScale(0.06, 0.48)
	box.Size = UDim2.fromScale(0.5, 0.14)
	box.BackgroundColor3 = TEXT_COLOR
	box.Font = FONT
	box.PlaceholderText = "How many?"
	box.PlaceholderColor3 = Color3.fromRGB(170, 160, 150)
	box.Text = ""
	box.TextColor3 = OUTLINE_COLOR
	box.TextScaled = true
	box.ClearTextOnFocus = false
	box.Parent = panel
	corner(box, UDim.new(0.3, 0))
	stroke(box, 3, Enum.ApplyStrokeMode.Border)

	local have = label(panel, "Have", UDim2.fromScale(0.59, 0.5), UDim2.fromScale(0.35, 0.1), "")

	local quick = {}
	for i, text in { "10", "100", "1K", "ALL" } do
		quick[text] = button(
			panel,
			`Quick{text}`,
			UDim2.fromScale(0.06 + (i - 1) * 0.225, 0.65),
			UDim2.fromScale(0.205, 0.11),
			QUICK_COLOR,
			text
		)
	end

	local message = label(panel, "Message", UDim2.fromScale(0.06, 0.775), UDim2.fromScale(0.88, 0.07), "")

	local cancel = button(panel, "Cancel", UDim2.fromScale(0.06, 0.86), UDim2.fromScale(0.42, 0.115), CANCEL_COLOR, "Cancel")
	local feed = button(panel, "Feed", UDim2.fromScale(0.52, 0.86), UDim2.fromScale(0.42, 0.115), FEED_COLOR, "FEED!")

	gui.Parent = parent

	return {
		Gui = gui,
		Scale = popScale,
		Title = title,
		Progress = progress,
		ProgressFill = fill,
		ProgressPreview = preview,
		Have = have,
		AmountBox = box,
		QuickButtons = quick,
		Message = message,
		FeedButton = feed,
		CancelButton = cancel,
	}
end

return FeedPromptUI
