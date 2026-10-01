-- CalebEventUIBuild (client only, ModuleScript)
-- Builds the Caleb Full Event screen UI ONCE, in the same cartoony style as
-- the cookie counter and the feed pop-up: rounded panels, thick dark
-- UIStroke, white FredokaOne text with a dark outline.
--
-- Build() returns the ScreenGui and its pieces, all hidden. This module only
-- makes the UI; CalebEventUI.client.luau shows/updates it and
-- CalebEventFX.luau animates it. It never talks to the server.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local CalebEventUIBuild = {}

-- Look (presentation only, same palette as CashDisplay / FeedPromptUI)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local FULL_TEXT_COLOR = Color3.fromRGB(255, 214, 64) -- the cookie counter's yellow
local PARTY_COLOR = Color3.fromRGB(255, 90, 160) -- pink, like the cookie jar sign
local TROPHY_COLOR = Color3.fromRGB(255, 200, 40) -- gold, like the owner sign frame
local PILL_COLOR = Color3.fromRGB(150, 70, 230) -- purple, like the owner sign
local FONT = Enum.Font.FredokaOne
-- Banners sit below Roblox's top bar (the ScreenGui ignores the inset so the
-- white flash covers the whole screen).
local TOP_OFFSET = 70
local MAX_CONFETTI = 100

export type Parts = {
	Gui: ScreenGui,
	Flash: Frame,
	Confetti: { Frame },
	FullText: TextLabel,
	FullStroke: UIStroke,
	FullScale: UIScale,
	PartyBanner: Frame,
	PartyScale: UIScale,
	PartyTimer: TextLabel,
	TrophyBanner: Frame,
	TrophyScale: UIScale,
	TrophyTimer: TextLabel,
	Pill: Frame,
	PillScale: UIScale,
	PillText: TextLabel,
}

local function corner(parent: GuiObject, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function stroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = OUTLINE_COLOR
	s.Thickness = thickness
	s.ApplyStrokeMode = mode
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
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
	l.TextWrapped = true
	l.Parent = parent
	stroke(l, 2.5, Enum.ApplyStrokeMode.Contextual)
	return l
end

-- A hidden top-center rounded panel: scale-sized, fixed shape, clamped for
-- phone and PC, with a UIScale for the pop-in.
local function panel(parent: Instance, name: string, color: Color3, widthScale: number, aspectRatio: number, minSize: Vector2, maxSize: Vector2): (Frame, UIScale)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, TOP_OFFSET)
	frame.Size = UDim2.fromScale(widthScale, widthScale / aspectRatio)
	frame.BackgroundColor3 = color
	frame.Visible = false
	frame.ZIndex = 4
	frame.Parent = parent
	corner(frame, UDim.new(0.25, 0))
	stroke(frame, 4, Enum.ApplyStrokeMode.Border)

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = aspectRatio
	aspect.DominantAxis = Enum.DominantAxis.Width
	aspect.Parent = frame

	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = minSize
	limit.MaxSize = maxSize
	limit.Parent = frame

	local scale = Instance.new("UIScale")
	scale.Parent = frame
	return frame, scale
end

function CalebEventUIBuild.Build(parent: Instance): Parts
	local gui = Instance.new("ScreenGui")
	gui.Name = "CalebEventUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5 -- above the cookie counter, below the feed pop-up (10)

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = TEXT_COLOR
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Visible = false
	flash.ZIndex = 1
	flash.Parent = gui

	-- Confetti pool: created once, reused by every burst.
	local confettiLayer = Instance.new("Frame")
	confettiLayer.Name = "Confetti"
	confettiLayer.Size = UDim2.fromScale(1, 1)
	confettiLayer.BackgroundTransparency = 1
	confettiLayer.ZIndex = 2
	confettiLayer.Parent = gui
	local confetti = {}
	for i = 1, math.clamp(Config.CalebConfettiCount, 0, MAX_CONFETTI) do
		local piece = Instance.new("Frame")
		piece.Name = `Piece{i}`
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.BorderSizePixel = 0
		piece.Visible = false
		piece.Parent = confettiLayer
		corner(piece, UDim.new(0.2, 0))
		table.insert(confetti, piece)
	end

	-- The big "CALEB IS FULLLL!!!" text.
	local fullText = Instance.new("TextLabel")
	fullText.Name = "FullText"
	fullText.AnchorPoint = Vector2.new(0.5, 0.5)
	fullText.Position = UDim2.fromScale(0.5, 0.42)
	fullText.Size = UDim2.fromScale(0.92, 0.22)
	fullText.BackgroundTransparency = 1
	fullText.Font = FONT
	fullText.Text = `🍪 {string.upper(Config.StatueName)} IS FULLLL!!! 🍪`
	fullText.TextColor3 = FULL_TEXT_COLOR
	fullText.TextScaled = true
	fullText.Visible = false
	fullText.ZIndex = 3
	fullText.Parent = gui
	local fullStroke = stroke(fullText, 6, Enum.ApplyStrokeMode.Contextual)
	local fullScale = Instance.new("UIScale")
	fullScale.Parent = fullText

	-- Celebration: "COOKIE PARTY!" + time left.
	local party, partyScale = panel(gui, "PartyBanner", PARTY_COLOR, 0.4, 3.6, Vector2.new(250, 69), Vector2.new(460, 128))
	label(party, "Title", UDim2.fromScale(0.05, 0.06), UDim2.fromScale(0.9, 0.56), "🎉 COOKIE PARTY! 🎉")
	local partyTimer = label(party, "Timer", UDim2.fromScale(0.25, 0.62), UDim2.fromScale(0.5, 0.3), "")

	-- TrophyClaim, eligible player.
	local trophy, trophyScale = panel(gui, "TrophyBanner", TROPHY_COLOR, 0.45, 2.4, Vector2.new(300, 125), Vector2.new(540, 225))
	label(trophy, "Title", UDim2.fromScale(0.04, 0.05), UDim2.fromScale(0.92, 0.27), `🏆 {string.upper(Config.StatueName)} TROPHY AVAILABLE!`)
	label(trophy, "Helped", UDim2.fromScale(0.08, 0.34), UDim2.fromScale(0.84, 0.13), `You helped feed {Config.StatueName}!`)
	label(trophy, "Claim", UDim2.fromScale(0.06, 0.49), UDim2.fromScale(0.88, 0.2), `Claim your trophy on {Config.StatueName}'s podium before time runs out!`)
	local trophyTimer = label(trophy, "Timer", UDim2.fromScale(0.15, 0.73), UDim2.fromScale(0.7, 0.21), "")

	-- One-line pill: "Trophy claimed!", "resting" countdown, "TROPHY CLAIM CLOSED".
	local pill, pillScale = panel(gui, "Pill", PILL_COLOR, 0.38, 8, Vector2.new(280, 35), Vector2.new(500, 63))
	local pillText = label(pill, "Text", UDim2.fromScale(0.04, 0.14), UDim2.fromScale(0.92, 0.72), "")

	gui.Parent = parent

	return {
		Gui = gui,
		Flash = flash,
		Confetti = confetti,
		FullText = fullText,
		FullStroke = fullStroke,
		FullScale = fullScale,
		PartyBanner = party,
		PartyScale = partyScale,
		PartyTimer = partyTimer,
		TrophyBanner = trophy,
		TrophyScale = trophyScale,
		TrophyTimer = trophyTimer,
		Pill = pill,
		PillScale = pillScale,
		PillText = pillText,
	}
end

return CalebEventUIBuild
