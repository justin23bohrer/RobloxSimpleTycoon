-- CashDisplay (client only)
-- Shows the local player's cash in a cartoony panel at the bottom-center of
-- the screen, e.g. "$1,250", and gives it a quick "pop" when the value changes.
--
-- Display only: reads the replicated leaderstats.Cash value. It never changes
-- cash and never talks to the server. The built-in player list is untouched.
--
-- Lives in StarterPlayerScripts, so it runs once per session. The ScreenGui is
-- created here with ResetOnSpawn = false so respawning does not rebuild it.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Look (presentation only, so these stay here rather than in Config)
local PANEL_COLOR = Color3.fromRGB(255, 214, 64) -- sunny yellow
local COIN_COLOR = Color3.fromRGB(88, 214, 96) -- money green
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20) -- thick dark outline
local FONT = Enum.Font.FredokaOne

local POP_SCALE = 1.15
local POP_TIME = 0.25

-- "1250" -> "1,250"; "-1250" -> "-1,250"
local function formatCash(amount: number): string
	local digits = tostring(math.floor(math.abs(amount)))
	local withCommas = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if withCommas:sub(1, 1) == "," then
		withCommas = withCommas:sub(2)
	end
	local sign = if amount < 0 then "-" else ""
	return sign .. "$" .. withCommas
end

local function addCorner(parent: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
end

local function addStroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode)
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
end

-- Build the UI -------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CashDisplay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- The panel is sized as a fraction of the screen, kept to a fixed shape by the
-- aspect ratio, and clamped so it is readable on phones and not huge on PC.
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -20)
panel.Size = UDim2.fromScale(0.25, 0.1)
panel.BackgroundColor3 = PANEL_COLOR
panel.Parent = screenGui

addCorner(panel, UDim.new(0.5, 0))
addStroke(panel, 4, Enum.ApplyStrokeMode.Border)

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 3.2
aspect.DominantAxis = Enum.DominantAxis.Width
aspect.Parent = panel

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(170, 53)
sizeLimit.MaxSize = Vector2.new(320, 100)
sizeLimit.Parent = panel

-- Scaling the whole panel from its center is what makes the "pop".
local popScale = Instance.new("UIScale")
popScale.Scale = 1
popScale.Parent = panel

-- Round green coin with a "$" on the left.
local coin = Instance.new("TextLabel")
coin.Name = "Coin"
coin.AnchorPoint = Vector2.new(0, 0.5)
coin.Position = UDim2.fromScale(0.05, 0.5)
coin.Size = UDim2.fromScale(0.7, 0.7)
coin.SizeConstraint = Enum.SizeConstraint.RelativeYY
coin.BackgroundColor3 = COIN_COLOR
coin.Font = FONT
coin.Text = "$"
coin.TextColor3 = TEXT_COLOR
coin.TextScaled = true
coin.Parent = panel

addCorner(coin, UDim.new(0.5, 0))
addStroke(coin, 3, Enum.ApplyStrokeMode.Border)

local amountLabel = Instance.new("TextLabel")
amountLabel.Name = "Amount"
amountLabel.AnchorPoint = Vector2.new(0, 0.5)
amountLabel.Position = UDim2.fromScale(0.32, 0.5)
amountLabel.Size = UDim2.fromScale(0.62, 0.62)
amountLabel.BackgroundTransparency = 1
amountLabel.Font = FONT
amountLabel.Text = "$0"
amountLabel.TextColor3 = TEXT_COLOR
amountLabel.TextScaled = true
amountLabel.TextXAlignment = Enum.TextXAlignment.Center
amountLabel.Parent = panel

-- Dark outline around the white digits (Contextual = outlines the text).
addStroke(amountLabel, 3, Enum.ApplyStrokeMode.Contextual)

screenGui.Parent = playerGui

-- Hook up to cash -----------------------------------------------------------

local popTween: Tween? = nil

local function pop()
	if popTween then
		popTween:Cancel()
	end
	popScale.Scale = POP_SCALE
	popTween = TweenService:Create(
		popScale,
		TweenInfo.new(POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	popTween:Play()
end

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash") :: IntValue

amountLabel.Text = formatCash(cash.Value)

cash.Changed:Connect(function(newValue: number)
	amountLabel.Text = formatCash(newValue)
	pop()
end)
