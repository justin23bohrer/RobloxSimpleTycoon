-- CookiePartyHUD (client only, ModuleScript)
-- The party earnings counter for CookiePartyCookies.client: a cartoony
-- yellow pill at the right side, upper-middle, "🍪 +12,450" (what the local
-- player earned from party cookies, the server's CookiePartyEarned
-- attribute), popping on every change, with a "x5 COMBO!" flair under it
-- when collecting fast. Same style as the CashDisplay counter.
--
-- Display only. Built once (ResetOnSpawn = false), shown only during the
-- Cookie Party; no summary screen when it ends, it just hides.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Numbers = require(script.Parent:WaitForChild("CookiePartyNumbers"))

local HUD = {}

-- Looks only.
local PANEL_COLOR = Color3.fromRGB(255, 214, 64) -- sunny yellow (as CashDisplay)
local COMBO_COLOR = Color3.fromRGB(255, 120, 60)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local FONT = Enum.Font.FredokaOne
local POP_SCALE = 1.2
local POP_TIME = 0.25
local COMBO_MIN = 3 -- show the flair from this many collects in a row
local COMBO_SHOW_SECONDS = 1.4

local function addStroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode)
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CookiePartyHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 3 -- under the trophy inventory (4) and the event UI (5)
screenGui.Enabled = false

-- Right side, upper-middle: top-center is the party banner, bottom-center
-- the cash display, left-middle the trophies button.
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -16, 0.34, 0)
panel.Size = UDim2.fromScale(0.2, 0.08)
panel.BackgroundColor3 = PANEL_COLOR
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = panel
addStroke(panel, 4, Enum.ApplyStrokeMode.Border)

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 3.2
aspect.DominantAxis = Enum.DominantAxis.Width
aspect.Parent = panel

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(150, 47)
sizeLimit.MaxSize = Vector2.new(280, 88)
sizeLimit.Parent = panel

local popScale = Instance.new("UIScale")
popScale.Parent = panel

local amountLabel = Instance.new("TextLabel")
amountLabel.Name = "Amount"
amountLabel.AnchorPoint = Vector2.new(0.5, 0.5)
amountLabel.Position = UDim2.fromScale(0.5, 0.5)
amountLabel.Size = UDim2.fromScale(0.88, 0.66)
amountLabel.BackgroundTransparency = 1
amountLabel.Font = FONT
amountLabel.Text = "🍪 +0"
amountLabel.TextColor3 = Color3.new(1, 1, 1)
amountLabel.TextScaled = true
amountLabel.Parent = panel
addStroke(amountLabel, 3, Enum.ApplyStrokeMode.Contextual)

local comboLabel = Instance.new("TextLabel")
comboLabel.Name = "Combo"
comboLabel.AnchorPoint = Vector2.new(0.5, 0)
comboLabel.Position = UDim2.new(0.5, 0, 1, 8)
comboLabel.Size = UDim2.fromScale(0.85, 0.6)
comboLabel.Rotation = -6
comboLabel.BackgroundTransparency = 1
comboLabel.Font = FONT
comboLabel.TextColor3 = COMBO_COLOR
comboLabel.TextScaled = true
comboLabel.Visible = false
comboLabel.Parent = panel
addStroke(comboLabel, 3, Enum.ApplyStrokeMode.Contextual)

local comboScale = Instance.new("UIScale")
comboScale.Parent = comboLabel

screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local popTween = TweenService:Create(
	popScale,
	TweenInfo.new(POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{ Scale = 1 }
)
local comboTween = TweenService:Create(
	comboScale,
	TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	{ Scale = 1 }
)
local comboToken = 0

local function setText(earned: number)
	amountLabel.Text = "🍪 +" .. Numbers.Format(earned)
end

-- Shows the counter (party started, or joined mid-party).
function HUD.Show(earned: number)
	setText(earned)
	popScale.Scale = 1
	comboLabel.Visible = false
	screenGui.Enabled = true
end

function HUD.Hide()
	screenGui.Enabled = false
	comboLabel.Visible = false
	comboToken += 1
end

-- The earned amount changed: new text + a pop.
function HUD.SetEarned(earned: number)
	setText(earned)
	popTween:Cancel()
	popScale.Scale = POP_SCALE
	popTween:Play()
end

-- The local player's collect streak (presentation only).
function HUD.Combo(combo: number)
	if combo < COMBO_MIN or not screenGui.Enabled then
		return
	end
	comboLabel.Text = "x" .. combo .. " COMBO!"
	comboLabel.Visible = true
	comboTween:Cancel()
	comboScale.Scale = 1.6
	comboTween:Play()
	comboToken += 1
	local token = comboToken
	task.delay(COMBO_SHOW_SECONDS, function()
		if comboToken == token then
			comboLabel.Visible = false
		end
	end)
end

return HUD
