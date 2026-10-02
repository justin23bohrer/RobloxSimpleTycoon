-- PushButton (client only, ModuleScript)
-- Builds the round on-screen "PUSH" button for touch devices, in the same
-- cartoony style as the cookie counter (thick dark outline, FredokaOne white
-- text with an outline). It sits right above Roblox's jump button (bottom
-- right) and follows its size rules, so it never covers the jump button, the
-- thumbstick (bottom left), the cookie counter (bottom center) or the
-- trophies button (left middle).
--
-- Build(onPress) returns a Parts table; StartCooldown(parts, seconds) shows
-- a dark disc that shrinks away while the push recharges. UI only: the
-- client script decides what a press does.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local PushButton = {}

-- Look (presentation only)
local BUTTON_COLOR = Color3.fromRGB(255, 120, 60) -- punchy orange
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local FONT = Enum.Font.FredokaOne
local GAP = 12 -- pixels between this button and the jump button

export type Parts = {
	Gui: ScreenGui,
	Button: TextButton,
	Cooldown: Frame,
	Scale: UIScale,
}

-- Roblox's touch jump button: 70 px on small screens (shortest side <= 500),
-- else 120 px, with its top-left at (1, -size * 1.5 + 10) x and
-- (1, -size - 20) / (1, -size * 1.75) y. This button goes on top of it.
local function layout(button: TextButton)
	local camera = Workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1024, 768)
	local small = math.min(viewport.X, viewport.Y) <= 500
	local jumpSize = if small then 70 else 120
	local jumpTop = if small then jumpSize + 20 else jumpSize * 1.75
	local size = math.floor(jumpSize * 0.8)
	button.Size = UDim2.fromOffset(size, size)
	-- Centered over the jump button.
	button.Position = UDim2.new(1, -(jumpSize * 1.5 - 10) + jumpSize / 2, 1, -(jumpTop + GAP))
end

local function corner(parent: GuiObject)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = parent
end

function PushButton.Build(onPress: () -> ()): Parts
	local gui = Instance.new("ScreenGui")
	gui.Name = "PushButton"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local button = Instance.new("TextButton")
	button.Name = "Push"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.BackgroundColor3 = BUTTON_COLOR
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = gui
	corner(button)

	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button

	local scale = Instance.new("UIScale")
	scale.Parent = button

	-- The recharge disc: dark, centered, shrinks from full size to nothing.
	local cooldown = Instance.new("Frame")
	cooldown.Name = "Cooldown"
	cooldown.AnchorPoint = Vector2.new(0.5, 0.5)
	cooldown.Position = UDim2.fromScale(0.5, 0.5)
	cooldown.Size = UDim2.fromScale(0, 0)
	cooldown.BackgroundColor3 = OUTLINE_COLOR
	cooldown.BackgroundTransparency = 0.45
	cooldown.BorderSizePixel = 0
	cooldown.ZIndex = 3
	cooldown.Parent = button
	corner(cooldown)

	local fist = Instance.new("TextLabel")
	fist.Name = "Icon"
	fist.AnchorPoint = Vector2.new(0.5, 0)
	fist.Position = UDim2.fromScale(0.5, 0.1)
	fist.Size = UDim2.fromScale(0.5, 0.42)
	fist.BackgroundTransparency = 1
	fist.Font = FONT
	fist.Text = "👊"
	fist.TextScaled = true
	fist.ZIndex = 2
	fist.Parent = button

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 0.86)
	label.Size = UDim2.fromScale(0.78, 0.34)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.Text = "PUSH"
	label.TextColor3 = TEXT_COLOR
	label.TextScaled = true
	label.ZIndex = 2
	label.Parent = button

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = OUTLINE_COLOR
	textStroke.Thickness = 2
	textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	textStroke.Parent = label

	layout(button)
	local function watchCamera()
		local camera = Workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				layout(button)
			end)
		end
		layout(button)
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()

	-- Fire on touch-down (feels instant, like the jump button).
	button.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			onPress()
		end
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return { Gui = gui, Button = button, Cooldown = cooldown, Scale = scale }
end

-- Press "pop" plus the shrinking recharge disc.
function PushButton.StartCooldown(parts: Parts, seconds: number)
	parts.Scale.Scale = 0.85
	TweenService:Create(parts.Scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	parts.Cooldown.Size = UDim2.fromScale(1, 1)
	TweenService:Create(parts.Cooldown, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 0) })
		:Play()
end

return PushButton
