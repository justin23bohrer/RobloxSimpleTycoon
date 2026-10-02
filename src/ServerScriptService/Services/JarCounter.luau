-- JarCounter (server only)
-- Helper for CollectorDisplay: the "🍪 1,250" counter on a plot's cookie jar.
-- It shows whatever number it is given and never reads or changes cash.
--
-- The counter is a small pink-framed plaque (a runtime Part named
-- "JarCounter" in the CashTank) sitting directly on top of the "COOKIE JAR"
-- sign, with a gold panel facing the Collect pad (the same side as the sign).
-- Its front is a hair in front of the sign's, so nothing hides it from the
-- pad. It stays clear of the 2nd floor (y 17), the sign, and the glass. Built from the TankSign's CFrame, so it works on plots
-- turned any way.
--
-- It is made in CollectorService.SetupPlot, before the plot is first hidden,
-- so PlotVisibility hides it (and disables its SurfaceGui) with the rest of
-- the CashTank and restores it on claim.

local TweenService = game:GetService("TweenService")

local JarCounter = {}

-- Looks only; not gameplay tuning.
local PLAQUE_SIZE = Vector3.new(7, 1.8, 0.6)
-- From the TankSign's center to the plaque's center, in the sign's space:
-- up so the plaque's bottom rests on the sign's top (sign half height 1.1 +
-- plaque half height 0.9), and 0.1 toward the pad (+Z) so its front face is
-- 0.2 in front of the sign's (no z-fighting) and its back touches the wall.
-- On Plot1: y 14.3..16.1, front face z -46.4.
local PLAQUE_OFFSET = Vector3.new(0, 2.0, 0.1)
local PINK = Color3.fromRGB(255, 90, 160)
local GOLD = Color3.fromRGB(255, 200, 40)
local WHITE = Color3.new(1, 1, 1)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local FONT = Enum.Font.FredokaOne
local MAX_DISTANCE = 120 -- studs; readable from anywhere in the plot
local POP_SCALE = 1.15
local POP_TIME = 0.25

local labelByPlot: { [Model]: TextLabel } = {}
local scaleByPlot: { [Model]: UIScale } = {}
local amountByPlot: { [Model]: number } = {}

-- 1250 -> "1,250"
local function formatCookies(amount: number): string
	local digits = tostring(math.floor(math.max(amount, 0)))
	local withCommas = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if withCommas:sub(1, 1) == "," then
		withCommas = withCommas:sub(2)
	end
	return withCommas
end

local function addStroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode)
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
end

-- Builds the plaque on the plot's CashTank. Does nothing if the tank has no
-- TankSign (the counter is looks only).
function JarCounter.Setup(plot: Model, tank: Model?)
	if labelByPlot[plot] then
		return
	end
	local sign = tank and tank:FindFirstChild("TankSign")
	if not tank or not sign or not sign:IsA("BasePart") then
		warn(`JarCounter: {plot.Name} has no CashTank with a TankSign; no cookie counter`)
		return
	end

	local plaque = Instance.new("Part")
	plaque.Name = "JarCounter"
	plaque.Size = PLAQUE_SIZE
	plaque.Color = PINK
	plaque.Material = Enum.Material.SmoothPlastic
	plaque.Anchored = true
	plaque.CanCollide = false
	plaque.CanTouch = false
	plaque.CanQuery = false
	plaque.CFrame = sign.CFrame * CFrame.new(PLAQUE_OFFSET)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "CounterGui"
	gui.Face = Enum.NormalId.Back -- same face as the sign's SignGui: toward the pad
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.94, 0.82)
	panel.BackgroundColor3 = GOLD
	panel.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.35, 0)
	corner.Parent = panel
	addStroke(panel, 6, Enum.ApplyStrokeMode.Border)
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	panel.Parent = gui

	local label = Instance.new("TextLabel")
	label.Name = "Amount"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.86, 0.72)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = WHITE
	label.Text = "🍪 0"
	addStroke(label, 3.5, Enum.ApplyStrokeMode.Contextual)
	label.Parent = panel

	gui.Parent = plaque
	plaque.Parent = tank

	labelByPlot[plot] = label
	scaleByPlot[plot] = scale
end

-- Shows `amount` cookies ("🍪 0" when empty). A bigger number than before
-- gives the counter a quick pop.
function JarCounter.SetAmount(plot: Model, amount: number)
	local label = labelByPlot[plot]
	if not label then
		return
	end
	local previous = amountByPlot[plot] or 0
	amountByPlot[plot] = amount
	label.Text = `🍪 {formatCookies(amount)}`

	if amount > previous then
		local scale = scaleByPlot[plot]
		scale.Scale = POP_SCALE
		TweenService:Create(scale, TweenInfo.new(POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end
end

return JarCounter
