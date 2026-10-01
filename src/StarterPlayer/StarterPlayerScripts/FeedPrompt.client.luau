-- FeedPrompt (client only)
-- Shows the "How many cookies do you want to feed Caleb?" pop-up when the
-- local player steps on one of the statue's FeedPads, and sends the chosen
-- amount to the server through the FeedStatue RemoteFunction.
--
-- The client decides nothing: StatueService checks the amount, that the
-- player is at a pad, and that they can afford it, then spends the cookies.
-- This script only opens/closes the pop-up and shows the server's answer.
-- The UI itself is built by FeedPromptUI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local StatueGrowth = require(ReplicatedStorage.Shared.StatueGrowth)
local FeedPromptUI = require(script.Parent.FeedPromptUI)

local player = Players.LocalPlayer
local ui = FeedPromptUI.Build(player:WaitForChild("PlayerGui"))

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FeedStatue") :: RemoteFunction
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")
local padFolder = statue:WaitForChild("FeedPads")
local cookies = player:WaitForChild("leaderstats"):WaitForChild("Cookies") :: IntValue

local NAME = Config.StatueName
local MAX = Config.StatueMaxCookies
local CLOSE_DISTANCE = Config.StatueFeedRange + 2 -- walk this far from the pad and it closes
local ERROR_COLOR = Color3.fromRGB(255, 120, 120)
local OK_COLOR = Color3.fromRGB(255, 255, 255)
local PREVIEW_COLOR = ui.ProgressPreview.BackgroundColor3
local PREVIEW_TOO_MUCH_COLOR = Color3.fromRGB(255, 130, 130) -- you don't have that many
local BAR_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MAX_AMOUNT = 9_999_999_999 -- the amount box holds at most 10 digits

local currentPad: BasePart? = nil
local mustLeavePad: BasePart? = nil -- after closing, step off before it opens again
local busy = false
local feedCount = 0 -- so an old "close after success" can't close a newer feed

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

local function showMessage(text: string, isError: boolean)
	ui.Message.Text = text
	ui.Message.TextColor3 = if isError then ERROR_COLOR else OK_COLOR
end

local function typedAmount(): number
	return tonumber(ui.AmountBox.Text) or 0
end

local function setBar(bar: Frame, fraction: number)
	TweenService:Create(bar, BAR_TWEEN, { Size = UDim2.fromScale(fraction, 1) }):Play()
end

-- Updates the text and the bar. The bar shows how fat Caleb is (the same
-- curve as the statue, StatueGrowth), and a lighter "preview" part shows how
-- much fatter he'd get from the amount in the box (red if you can't afford it).
local function refresh()
	local total = eaten()
	local typed = typedAmount()
	local pending = math.min(typed, math.max(MAX - total, 0))

	if total >= MAX then
		ui.Title.Text = `{NAME} is FULL!`
		ui.Progress.Text = `He ate all {formatNumber(MAX)} cookies!`
	else
		ui.Title.Text = `How many cookies do you want to feed {NAME}?`
		local suffix = if pending > 0 then `  (+{formatNumber(pending)})` else ""
		ui.Progress.Text = `{NAME} has eaten {formatNumber(total)} / {formatNumber(MAX)}{suffix}`
	end

	setBar(ui.ProgressFill, StatueGrowth.Fatness(total))
	setBar(ui.ProgressPreview, StatueGrowth.Fatness(total + pending))
	ui.ProgressPreview.BackgroundColor3 = if typed > cookies.Value then PREVIEW_TOO_MUCH_COLOR else PREVIEW_COLOR
	ui.Have.Text = `You have {formatNumber(cookies.Value)}`
end

local function distanceTo(pad: BasePart): number
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return math.huge
	end
	local offset = root.Position - pad.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude
end

local function open(pad: BasePart)
	currentPad = pad
	ui.AmountBox.Text = ""
	showMessage("", false)
	refresh()
	ui.Gui.Enabled = true
	ui.Scale.Scale = 0.6
	TweenService:Create(ui.Scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

local function close()
	if not ui.Gui.Enabled then
		return
	end
	ui.Gui.Enabled = false
	ui.AmountBox:ReleaseFocus()
	mustLeavePad = currentPad
	currentPad = nil
end

local function feed()
	if busy then
		return
	end
	local amount = tonumber(ui.AmountBox.Text)
	if not amount or amount < 1 then
		showMessage("Type how many cookies first!", true)
		return
	end

	busy = true
	feedCount += 1
	local thisFeed = feedCount
	showMessage("Feeding...", false)
	local ok, accepted, result = pcall(remote.InvokeServer, remote, amount)
	busy = false

	if not ok then
		showMessage("Something went wrong. Try again!", true)
	elseif accepted then
		showMessage(`{NAME} ate {formatNumber(result)} cookies! Yum!`, false)
		ui.AmountBox.Text = ""
		task.delay(1.5, function()
			if feedCount == thisFeed and not busy then
				close()
			end
		end)
	else
		showMessage(tostring(result), true)
	end
	refresh()
end

-- Opening on touch -----------------------------------------------------------

local function connectPad(pad: Instance)
	if not pad:IsA("BasePart") then
		return
	end
	pad.Touched:Connect(function(hit)
		local character = player.Character
		if ui.Gui.Enabled or not character or not hit:IsDescendantOf(character) then
			return
		end
		if mustLeavePad == pad then
			return -- just closed it here; step off first
		end
		open(pad)
	end)
end

for _, pad in padFolder:GetChildren() do
	connectPad(pad)
end

-- Close when walking away; allow re-opening once off the pad.
RunService.Heartbeat:Connect(function()
	if currentPad and distanceTo(currentPad) > CLOSE_DISTANCE then
		close()
	end
	if mustLeavePad and distanceTo(mustLeavePad) > 4 then
		mustLeavePad = nil
	end
end)

-- Buttons ----------------------------------------------------------------------

-- Only digits in the amount box (max 10).
ui.AmountBox:GetPropertyChangedSignal("Text"):Connect(function()
	local digits = ui.AmountBox.Text:gsub("%D", ""):sub(1, 10)
	if digits ~= ui.AmountBox.Text then
		ui.AmountBox.Text = digits -- fires this handler again with the clean text
		return
	end
	if ui.Gui.Enabled then
		refresh() -- move the preview as the amount changes
	end
end)

-- 10 / 100 / 1K add to the amount on every click (1K, 1K, 10 -> 2,010).
-- ALL replaces it with everything you can feed.
local QUICK_AMOUNTS = { ["10"] = 10, ["100"] = 100, ["1K"] = 1000 }
for text, quickButton in ui.QuickButtons do
	quickButton.Activated:Connect(function()
		local amount
		if text == "ALL" then
			amount = math.min(cookies.Value, math.max(MAX - eaten(), 0))
		else
			amount = math.min(typedAmount() + QUICK_AMOUNTS[text], MAX_AMOUNT)
		end
		ui.AmountBox.Text = tostring(amount)
	end)
end

ui.FeedButton.Activated:Connect(feed)
ui.CancelButton.Activated:Connect(close)
ui.AmountBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		feed()
	end
end)

-- Keep the numbers live while it's open (other players feed Caleb too).
statue:GetAttributeChangedSignal("CookiesEaten"):Connect(refresh)
cookies.Changed:Connect(refresh)
