-- CookiePartyUIBuild (client only, ModuleScript)
-- Builds the Cookie Party's extra screen pieces ONCE, inside the
-- CalebEventUI ScreenGui (CalebEventUIBuild), all hidden:
--   Countdown  the huge 10..1 numbers in the middle of the screen
--   Callout    the short phase slam ("MORE COOKIES!", "GOLDEN COOKIE FRENZY!")
--   EdgeGlow   four soft gradient strips on the screen edges (3, 2, 1)
-- Same cartoony style as the rest of the event UI. CookiePartyFX animates
-- them. Looks only; never talks to the server.

local CookiePartyUIBuild = {}

local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local GLOW_COLOR = Color3.fromRGB(255, 200, 60)
local FONT = Enum.Font.FredokaOne
local GLOW_DEPTH = 0.14 -- how far each edge strip reaches in (share of the screen)

export type Parts = {
	Countdown: TextLabel,
	CountdownScale: UIScale,
	CountdownStroke: UIStroke,
	Callout: TextLabel,
	CalloutScale: UIScale,
	CalloutStroke: UIStroke,
	EdgeGlow: { Frame },
}

local function bigText(parent: Instance, name: string, position: UDim2, size: UDim2, strokeSize: number, zIndex: number): (TextLabel, UIScale, UIStroke)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = ""
	l.TextColor3 = TEXT_COLOR
	l.TextScaled = true
	l.Visible = false
	l.ZIndex = zIndex
	l.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = OUTLINE_COLOR
	s.Thickness = strokeSize
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	local scale = Instance.new("UIScale")
	scale.Parent = l
	return l, scale, s
end

-- One edge strip; the UIGradient makes it fade from the edge inward.
-- rotation: 0 = left edge, 180 = right, 90 = top, 270 = bottom.
local function edge(parent: Instance, name: string, position: UDim2, size: UDim2, anchor: Vector2, rotation: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = anchor
	f.Position = position
	f.Size = size
	f.BackgroundColor3 = GLOW_COLOR
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Visible = false
	f.ZIndex = 1
	f.Parent = parent
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = f
	return f
end

function CookiePartyUIBuild.Build(gui: ScreenGui): Parts
	local countdown, countdownScale, countdownStroke =
		bigText(gui, "PartyCountdown", UDim2.fromScale(0.5, 0.45), UDim2.fromScale(0.5, 0.32), 8, 3)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.4
	aspect.Parent = countdown

	local callout, calloutScale, calloutStroke =
		bigText(gui, "PartyCallout", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.86, 0.12), 6, 3)

	local glow = {
		edge(gui, "GlowLeft", UDim2.fromScale(0, 0), UDim2.fromScale(GLOW_DEPTH, 1), Vector2.zero, 0),
		edge(gui, "GlowRight", UDim2.fromScale(1, 0), UDim2.fromScale(GLOW_DEPTH, 1), Vector2.new(1, 0), 180),
		edge(gui, "GlowTop", UDim2.fromScale(0, 0), UDim2.fromScale(1, GLOW_DEPTH), Vector2.zero, 90),
		edge(gui, "GlowBottom", UDim2.fromScale(0, 1), UDim2.fromScale(1, GLOW_DEPTH), Vector2.new(0, 1), 270),
	}

	return {
		Countdown = countdown,
		CountdownScale = countdownScale,
		CountdownStroke = countdownStroke,
		Callout = callout,
		CalloutScale = calloutScale,
		CalloutStroke = calloutStroke,
		EdgeGlow = glow,
	}
end

return CookiePartyUIBuild
