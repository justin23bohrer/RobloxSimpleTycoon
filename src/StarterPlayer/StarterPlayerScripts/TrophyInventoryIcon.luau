-- TrophyInventoryIcon (client only, ModuleScript)
-- A tiny cartoony trophy icon drawn from plain frames (no ViewportFrame, so
-- a grid of 100+ trophies stays cheap): a plinth in the variant's Base color,
-- a round-headed mini Caleb in its Figure color, a hat for Crown / PartyHat /
-- ChefHat, and a sparkle when it has an effect. Presentation only.
--
-- New() makes one (blank); Paint() recolors it for a variant, so pooled
-- tiles are reused instead of rebuilt.

local TrophyInventoryIcon = {}

local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local EYE_COLOR = Color3.fromRGB(40, 28, 20)
local HAT_COLORS = {
	Crown = Color3.fromRGB(255, 200, 40),
	PartyHat = Color3.fromRGB(255, 90, 160),
	ChefHat = Color3.fromRGB(255, 255, 255),
}
local HAT_ORDER = { "Crown", "PartyHat", "ChefHat" }

export type Icon = {
	Root: Frame,
	Base: Frame,
	Body: Frame,
	Head: Frame,
	Hat: Frame,
	Sparkle: TextLabel,
}

local function part(parent: GuiObject, name: string, position: UDim2, size: UDim2, radius: UDim, outline: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = position
	f.Size = size
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = f
	if outline then
		local s = Instance.new("UIStroke")
		s.Color = OUTLINE_COLOR
		s.Thickness = outline
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = f
	end
	return f
end

-- position = top-center of the icon; size is kept square.
function TrophyInventoryIcon.New(parent: GuiObject, position: UDim2, size: UDim2): Icon
	local root = Instance.new("Frame")
	root.Name = "Icon"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = position
	root.Size = size
	root.BackgroundTransparency = 1
	root.Parent = parent
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = root

	local base = part(root, "Base", UDim2.fromScale(0.14, 0.8), UDim2.fromScale(0.72, 0.18), UDim.new(0.3, 0), 2)
	local body = part(root, "Body", UDim2.fromScale(0.27, 0.46), UDim2.fromScale(0.46, 0.36), UDim.new(0.45, 0), 2)
	local head = part(root, "Head", UDim2.fromScale(0.24, 0.1), UDim2.fromScale(0.52, 0.44), UDim.new(0.5, 0), 2)
	for _, x in { 0.27, 0.57 } do
		local eye = part(head, "Eye", UDim2.fromScale(x, 0.36), UDim2.fromScale(0.16, 0.2), UDim.new(0.5, 0))
		eye.BackgroundColor3 = EYE_COLOR
	end
	local mouth = part(head, "Mouth", UDim2.fromScale(0.32, 0.68), UDim2.fromScale(0.36, 0.1), UDim.new(0.5, 0))
	mouth.BackgroundColor3 = EYE_COLOR

	local hat = part(root, "Hat", UDim2.fromScale(0.34, 0), UDim2.fromScale(0.32, 0.16), UDim.new(0.25, 0), 2)
	hat.Visible = false

	local sparkle = Instance.new("TextLabel")
	sparkle.Name = "Sparkle"
	sparkle.Position = UDim2.fromScale(0.7, 0)
	sparkle.Size = UDim2.fromScale(0.3, 0.3)
	sparkle.BackgroundTransparency = 1
	sparkle.Text = "✨"
	sparkle.TextScaled = true
	sparkle.Visible = false
	sparkle.Parent = root

	return { Root = root, Base = base, Body = body, Head = head, Hat = hat, Sparkle = sparkle }
end

-- variant: a TrophyVariants definition (any missing field is skipped).
function TrophyInventoryIcon.Paint(icon: Icon, variant: any)
	local figure = if type(variant.Figure) == "table" then variant.Figure.Color else nil
	local base = if type(variant.Base) == "table" then variant.Base.Color else nil
	local figureColor = if typeof(figure) == "Color3" then figure else Color3.fromRGB(160, 160, 165)
	icon.Body.BackgroundColor3 = figureColor
	icon.Head.BackgroundColor3 = figureColor
	icon.Base.BackgroundColor3 = if typeof(base) == "Color3" then base else Color3.fromRGB(92, 60, 38)

	local hatColor: Color3? = nil
	if type(variant.Accessories) == "table" then
		for _, name in HAT_ORDER do
			if table.find(variant.Accessories, name) then
				hatColor = HAT_COLORS[name]
				break
			end
		end
	end
	icon.Hat.Visible = hatColor ~= nil
	if hatColor then
		icon.Hat.BackgroundColor3 = hatColor
	end
	icon.Sparkle.Visible = type(variant.Effect) == "string" and variant.Effect ~= "None"
end

return TrophyInventoryIcon
