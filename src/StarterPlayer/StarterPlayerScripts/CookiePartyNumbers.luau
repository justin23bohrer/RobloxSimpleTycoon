-- CookiePartyNumbers (client only, ModuleScript)
-- The floating numbers over collected Cookie Party cookies ("+50", bigger
-- with "GOLDEN!" / "GIANT!!" for the special ones): each pops in, rises and
-- fades. A small pool of BillboardGuis (in PlayerGui, AlwaysOnTop) adorned to
-- Attachments in Terrain, reused oldest first; made by Setup at party start
-- and destroyed by Teardown when it ends. Also Format ("12450" -> "12,450").
--
-- Presentation only: it shows what it is told.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Numbers = {}

-- Looks only.
local POOL_SIZE = 10
local FONT = Enum.Font.FredokaOne
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)

-- "12450" -> "12,450"
function Numbers.Format(amount: number): string
	local digits = tostring(math.floor(math.abs(amount)))
	local withCommas = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if withCommas:sub(1, 1) == "," then
		withCommas = withCommas:sub(2)
	end
	return (if amount < 0 then "-" else "") .. withCommas
end

type Number = {
	Gui: BillboardGui,
	Anchor: Attachment,
	Scale: UIScale,
	Amount: TextLabel,
	Tag: TextLabel,
	Tweens: { Tween },
}

local numbers: { Number } = {}
local nextNumber = 1

local function label(parent: Instance, y: number, height: number): TextLabel
	local text = Instance.new("TextLabel")
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = UDim2.fromScale(0.5, y)
	text.Size = UDim2.fromScale(1, height)
	text.BackgroundTransparency = 1
	text.Font = FONT
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = 3
	stroke.Parent = text
	return text
end

local function buildNumber(playerGui: Instance): Number
	local anchor = Instance.new("Attachment")
	anchor.Name = "CookiePartyNumber"
	anchor.Parent = Workspace.Terrain
	local gui = Instance.new("BillboardGui")
	gui.Name = "CookiePartyNumber"
	gui.Adornee = anchor
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(180, 80)
	gui.MaxDistance = 200
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local tag = label(gui, 0, 0.38)
	local amount = label(gui, 0.34, 0.66)
	gui.Parent = playerGui

	local n: Number = { Gui = gui, Anchor = anchor, Scale = scale, Amount = amount, Tag = tag, Tweens = {} }
	local rise = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fade = TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.6)
	table.insert(n.Tweens, TweenService:Create(gui, rise, { StudsOffset = Vector3.new(0, 6, 0) }))
	table.insert(n.Tweens, TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }))
	for _, text in { amount, tag } do
		table.insert(n.Tweens, TweenService:Create(text, fade, { TextTransparency = 1 }))
		table.insert(n.Tweens, TweenService:Create(text:FindFirstChildOfClass("UIStroke") :: UIStroke, fade, { Transparency = 1 }))
	end
	n.Tweens[3].Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			gui.Enabled = false
		end
	end)
	return n
end

-- Builds the pool (party start).
function Numbers.Setup()
	if #numbers > 0 then
		return
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _ = 1, POOL_SIZE do
		table.insert(numbers, buildNumber(playerGui))
	end
end

-- Destroys the pool (party over).
function Numbers.Teardown()
	for _, n in numbers do
		n.Gui:Destroy()
		n.Anchor:Destroy()
	end
	numbers = {}
	nextNumber = 1
end

-- A floating number at a world position that pops in, rises and fades
-- (pooled; the oldest is reused). size 1 = normal.
function Numbers.Show(text: string, tag: string, color: Color3, size: number, position: Vector3)
	local n = numbers[nextNumber]
	if not n then
		return
	end
	nextNumber = nextNumber % #numbers + 1
	for _, tween in n.Tweens do
		tween:Cancel()
	end
	n.Anchor.WorldPosition = position
	n.Gui.Size = UDim2.fromOffset(180 * size, 80 * size)
	n.Gui.StudsOffset = Vector3.new(0, 1.5, 0)
	n.Scale.Scale = 0.3
	n.Amount.Text = text
	n.Amount.TextColor3 = color
	n.Tag.Text = tag
	n.Tag.TextColor3 = color
	for _, line in { n.Amount, n.Tag } do
		line.TextTransparency = 0
		local stroke = line:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
	end
	n.Gui.Enabled = true
	for _, tween in n.Tweens do
		tween:Play()
	end
end

return Numbers
