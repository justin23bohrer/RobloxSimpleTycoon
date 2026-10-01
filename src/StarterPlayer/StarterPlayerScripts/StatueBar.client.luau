-- StatueBar (client only)
-- A cartoony progress bar floating above Caleb's head that everyone can see:
-- "Caleb: 12,345 / 1,000,000 🍪" over the same cookie bar as the feed pop-up
-- (FeedPromptUI.ProgressBar), and "Caleb is FULL!" at the max.
--
-- Display only: reads the statue's replicated CookiesEaten attribute (set by
-- StatueService). It never changes anything and never talks to the server.
--
-- The BillboardGui is adorned to an Attachment in Terrain placed above the
-- Head, not to the Head itself: with content streaming the statue's parts can
-- unload when you are far away, and the bar should stay visible anyway.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local FeedPromptUI = require(script.Parent.FeedPromptUI)

local player = Players.LocalPlayer
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")

local NAME = Config.StatueName
local MAX = Config.StatueMaxCookies

-- Look (presentation only, same as CashDisplay / FeedPromptUI)
local PANEL_COLOR = Color3.fromRGB(255, 214, 64)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local FONT = Enum.Font.FredokaOne
local BAR_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_SCALE = 1.1
local POP_TIME = 0.25
-- Same as the feed pop-up: anything above 0 gets at least a thin sliver.
local MIN_VISIBLE_BAR = 0.006

-- "1250" -> "1,250"
local function formatNumber(amount: number): string
	local digits = tostring(math.floor(math.abs(amount)))
	local withCommas = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if withCommas:sub(1, 1) == "," then
		withCommas = withCommas:sub(2)
	end
	return withCommas
end

local function eaten(): number
	local value = statue:GetAttribute("CookiesEaten")
	return if typeof(value) == "number" then value else 0
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

local anchor = Instance.new("Attachment")
anchor.Name = "StatueBarAnchor"
anchor.Parent = Workspace.Terrain

local billboard = Instance.new("BillboardGui")
billboard.Name = "StatueBar"
billboard.ResetOnSpawn = false
billboard.Adornee = anchor
billboard.Size = UDim2.fromOffset(Config.StatueBarSize.X, Config.StatueBarSize.Y)
billboard.AlwaysOnTop = true -- readable over roofs and trees from the plots
billboard.LightInfluence = 0
billboard.MaxDistance = Config.StatueBarMaxDistance
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.Enabled = false -- until the anchor is placed above the head

-- Inset a little so the panel's outline and the pop never get cut off.
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(1, -16, 1, -12)
panel.BackgroundColor3 = PANEL_COLOR
panel.Parent = billboard

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.3, 0)
corner.Parent = panel
addStroke(panel, 4, Enum.ApplyStrokeMode.Border)

local popScale = Instance.new("UIScale")
popScale.Parent = panel

local label = Instance.new("TextLabel")
label.Name = "Progress"
label.Position = UDim2.fromScale(0.06, 0.1)
label.Size = UDim2.fromScale(0.88, 0.42)
label.BackgroundTransparency = 1
label.Font = FONT
label.Text = ""
label.TextColor3 = TEXT_COLOR
label.TextScaled = true
label.Parent = panel
addStroke(label, 2.5, Enum.ApplyStrokeMode.Contextual)

local _, fill = FeedPromptUI.ProgressBar(panel, UDim2.fromScale(0.06, 0.6), UDim2.fromScale(0.88, 0.26))

billboard.Parent = player:WaitForChild("PlayerGui")

-- Keep it above the head --------------------------------------------------

-- The Head never moves or grows (StatueShape only grows the cheeks, chin and
-- body), but follow it anyway in case that changes.
local function placeAbove(head: BasePart)
	local top = head.Position.Y + head.Size.Y / 2
	anchor.WorldPosition = Vector3.new(head.Position.X, top + Config.StatueBarHeight, head.Position.Z)
	billboard.Enabled = true
end

local function watchHead(head: Instance)
	if head.Name ~= "Head" or not head:IsA("BasePart") then
		return
	end
	placeAbove(head)
	head:GetPropertyChangedSignal("CFrame"):Connect(function()
		placeAbove(head)
	end)
	head:GetPropertyChangedSignal("Size"):Connect(function()
		placeAbove(head)
	end)
end

-- The Head may not be streamed in yet (or may stream out and back in).
statue.ChildAdded:Connect(watchHead)
local head = statue:FindFirstChild("Head")
if head then
	watchHead(head)
end

-- Hook up to Caleb's total ---------------------------------------------------

local popTween: Tween? = nil

local function pop()
	if popTween then
		popTween:Cancel()
	end
	popScale.Scale = POP_SCALE
	popTween = TweenService:Create(popScale, TweenInfo.new(POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	})
	popTween:Play()
end

local function refresh()
	local total = eaten()
	if total >= MAX then
		label.Text = `{NAME} is FULL! {formatNumber(MAX)} 🍪`
	else
		label.Text = `{NAME}: {formatNumber(total)} / {formatNumber(MAX)} 🍪`
	end

	local fraction = math.clamp(total / MAX, 0, 1)
	if total > 0 then
		fraction = math.max(fraction, MIN_VISIBLE_BAR)
	end
	TweenService:Create(fill, BAR_TWEEN, { Size = UDim2.fromScale(fraction, 1) }):Play()
end

-- A late joiner gets the current value from the replicated attribute here.
refresh()
statue:GetAttributeChangedSignal("CookiesEaten"):Connect(function()
	refresh()
	pop()
end)
