-- CookiePartyTotalBuild (client only, ModuleScript)
-- Builds the end-of-party "YOU COLLECTED" card ONCE, hidden, inside the
-- CalebEventUI ScreenGui, for CookiePartyTotal to animate:
--   Card    dark rounded panel with a gold border (sized/placed at show time)
--     Header  "YOU COLLECTED"
--     Amount  the big "🍪 12,450" (white text tinted gold by a UIGradient
--             whose white band is the shine sweep)
--     Sub     "37 cookies grabbed" / "Next time grab some cookies!"
--     Bonus   "+5,000 PARTY BONUS!"
--   Ring    a gold ring behind the card that bursts out when the number lands
-- Same cartoony style as the rest of the event UI. Looks only.

local CookiePartyTotalBuild = {}

local FONT = Enum.Font.FredokaOne
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local PANEL_COLOR = Color3.fromRGB(70, 40, 22)
local GOLD = Color3.fromRGB(255, 214, 64)
local SUB_COLOR = Color3.fromRGB(255, 236, 200)
local BONUS_COLOR = Color3.fromRGB(120, 235, 90)

CookiePartyTotalBuild.PanelAlpha = 0.2 -- the card's BackgroundTransparency when shown

export type Parts = {
	Card: Frame,
	CardScale: UIScale,
	Amount: TextLabel,
	AmountScale: UIScale,
	Shine: UIGradient,
	Sub: TextLabel,
	SubStroke: UIStroke,
	Bonus: TextLabel,
	BonusScale: UIScale,
	Ring: Frame,
	RingStroke: UIStroke,
	-- Everything the fly-away fades: { instance, property, shown value }.
	Fades: { { any } },
}

local function text(card: Frame, fades: { { any } }, name: string, position: UDim2, size: UDim2, color: Color3, strokeSize: number): (TextLabel, UIScale, UIStroke)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = ""
	l.TextColor3 = color
	l.TextScaled = true
	l.ZIndex = 8
	l.Parent = card
	local s = Instance.new("UIStroke")
	s.Color = OUTLINE_COLOR
	s.Thickness = strokeSize
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	local scale = Instance.new("UIScale")
	scale.Parent = l
	table.insert(fades, { l, "TextTransparency", 0 })
	table.insert(fades, { s, "Transparency", 0 })
	return l, scale, s
end

function CookiePartyTotalBuild.Build(gui: ScreenGui): Parts
	local fades = {}
	local card = Instance.new("Frame")
	card.Name = "PartyTotal"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = PANEL_COLOR
	card.BackgroundTransparency = CookiePartyTotalBuild.PanelAlpha
	card.Visible = false
	card.ZIndex = 7
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = card
	local border = Instance.new("UIStroke")
	border.Color = GOLD
	border.Thickness = 4
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = card
	local cardScale = Instance.new("UIScale")
	cardScale.Parent = card
	table.insert(fades, { card, "BackgroundTransparency", CookiePartyTotalBuild.PanelAlpha })
	table.insert(fades, { border, "Transparency", 0 })

	local header = text(card, fades, "Header", UDim2.fromScale(0.5, 0.05), UDim2.fromScale(0.6, 0.16), Color3.new(1, 1, 1), 3)
	header.Text = "YOU COLLECTED"
	local amount, amountScale = text(card, fades, "Amount", UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.9, 0.38), Color3.new(1, 1, 1), 5)
	local shine = Instance.new("UIGradient")
	shine.Rotation = 20
	shine.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GOLD),
		ColorSequenceKeypoint.new(0.42, GOLD),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.58, GOLD),
		ColorSequenceKeypoint.new(1, GOLD),
	})
	shine.Offset = Vector2.new(-1, 0)
	shine.Parent = amount
	local sub, _, subStroke = text(card, fades, "Sub", UDim2.fromScale(0.5, 0.59), UDim2.fromScale(0.75, 0.12), SUB_COLOR, 2)
	local bonus, bonusScale = text(card, fades, "Bonus", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.86, 0.2), BONUS_COLOR, 3)

	local ring = Instance.new("Frame")
	ring.Name = "PartyTotalRing"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.Visible = false
	ring.ZIndex = 6
	ring.Parent = gui
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(0.5, 0)
	ringCorner.Parent = ring
	local ringStroke = Instance.new("UIStroke")
	ringStroke.Color = GOLD
	ringStroke.Thickness = 6
	ringStroke.Parent = ring

	return {
		Card = card,
		CardScale = cardScale,
		Amount = amount,
		AmountScale = amountScale,
		Shine = shine,
		Sub = sub,
		SubStroke = subStroke,
		Bonus = bonus,
		BonusScale = bonusScale,
		Ring = ring,
		RingStroke = ringStroke,
		Fades = fades,
	}
end

return CookiePartyTotalBuild
