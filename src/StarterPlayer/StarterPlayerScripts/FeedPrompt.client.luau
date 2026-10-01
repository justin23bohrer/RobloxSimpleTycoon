-- FeedPrompt (client only)
-- Shows the "How many cookies do you want to feed Caleb?" pop-up when the
-- local player steps on one of the statue's FeedPads, and sends the chosen
-- amount to the server through the FeedStatue RemoteFunction.
--
-- The client decides nothing: StatueService checks the amount, that the
-- player is at a pad, and that they can afford it, then spends the cookies.
-- This script only opens/closes the pop-up and shows the server's answer.
-- The UI itself is built by FeedPromptUI.
--
-- It opens by checking every frame whether the character is standing on any
-- pad that currently exists, not with Touched on the pads found at start.
-- With content streaming on, the pads load after this script runs (and can
-- unload/reload), so pads hooked up once at start never opened anything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local FeedPromptUI = require(script.Parent:WaitForChild("FeedPromptUI"))

local player = Players.LocalPlayer
local ui = FeedPromptUI.Build(player:WaitForChild("PlayerGui"))

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FeedStatue") :: RemoteFunction
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")
local padFolder = statue:WaitForChild("FeedPads")
local cookies = player:WaitForChild("leaderstats"):WaitForChild("Cookies") :: IntValue

local NAME = Config.StatueName
local CLOSE_DISTANCE = Config.StatueFeedRange + 2 -- walk this far from the pad and it closes
local OPEN_DISTANCE = 3.5 -- pads are 6 studs wide: standing anywhere on one opens it
local LEAVE_DISTANCE = 4 -- after closing, step this far off before it opens again
local ERROR_COLOR = Color3.fromRGB(255, 120, 120)
local OK_COLOR = Color3.fromRGB(255, 255, 255)
local PREVIEW_COLOR = ui.ProgressPreview.BackgroundColor3
local PREVIEW_TOO_MUCH_COLOR = Color3.fromRGB(255, 130, 130) -- you don't have that many
local BAR_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MAX_AMOUNT = 9_999_999_999 -- the amount box holds at most 10 digits
-- Anything above 0 gets at least this much bar so you can see it (1,000,000
-- cookies is the full bar, so 10 cookies would otherwise be invisible).
-- The % in the text is always exact.
local MIN_VISIBLE_BAR = 0.006

local currentPad: BasePart? = nil
local mustLeavePad: BasePart? = nil -- after closing, step off before it opens again
local busy = false

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
	local value = statue:GetAttribute(CalebEvent.Attr.CookiesEaten)
	return if typeof(value) == "number" then value else 0
end

-- This cycle's goal, published by the server (CalebCycle), or the contract
-- default before it is set (also covers Config.DevCalebFastCycle).
local function maxCookies(): number
	local value = statue:GetAttribute(CalebEvent.Attr.MaxCookies)
	return if typeof(value) == "number" and value > 0 then value else CalebEvent.MaxCookies()
end

-- Caleb only eats in the Normal state (the server enforces this too).
local function isFull(): boolean
	return CalebEvent.GetState(statue) ~= CalebEvent.State.Normal or eaten() >= maxCookies()
end

local function showMessage(text: string, isError: boolean)
	ui.Message.Text = text
	ui.Message.TextColor3 = if isError then ERROR_COLOR else OK_COLOR
end

local function typedAmount(): number
	return tonumber(ui.AmountBox.Text) or 0
end

-- Fills the bar to exactly cookies / goal of its width.
local function setBar(bar: Frame, cookieCount: number)
	local fraction = math.clamp(cookieCount / maxCookies(), 0, 1)
	if cookieCount > 0 then
		fraction = math.max(fraction, MIN_VISIBLE_BAR)
	end
	TweenService:Create(bar, BAR_TWEEN, { Size = UDim2.fromScale(fraction, 1) }):Play()
end

-- "0.13%"
local function percent(cookieCount: number): string
	local value = math.clamp(cookieCount / maxCookies(), 0, 1) * 100
	return if value >= 10 then string.format("%.1f%%", value) else string.format("%.2f%%", value)
end

-- Updates the text and the bar. The bar is exact: cookies eaten out of
-- the goal (the full bar). A lighter "preview" part shows exactly where it will be
-- after feeding the amount in the box (red if you can't afford it).
local function refresh()
	local total = eaten()
	local typed = typedAmount()
	local max = maxCookies()
	local full = isFull()
	local pending = if full then 0 else math.min(typed, math.max(max - total, 0))

	if full then
		ui.Title.Text = `{NAME} is FULL!`
		ui.Progress.Text = `He ate all {formatNumber(max)} cookies!`
	else
		ui.Title.Text = `How many cookies do you want to feed {NAME}?`
		local suffix = if pending > 0
			then `  +{formatNumber(pending)} = {percent(total + pending)}`
			else `  ({percent(total)})`
		ui.Progress.Text = `{NAME} has eaten {formatNumber(total)} / {formatNumber(max)}{suffix}`
	end

	setBar(ui.ProgressFill, total)
	setBar(ui.ProgressPreview, total + pending)
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
	showMessage("Feeding...", false)
	local ok, accepted, result = pcall(remote.InvokeServer, remote, amount)
	busy = false

	if not ok then
		showMessage("Something went wrong. Try again!", true)
	elseif accepted then
		-- Done: close right away (step off the pad to open it again) and say
		-- thanks with a small Roblox notification in the corner.
		ui.AmountBox.Text = ""
		close()
		pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
			Title = "Yum!",
			Text = `{NAME} ate {formatNumber(result)} cookies!`,
			Duration = 3,
		})
		return
	else
		showMessage(tostring(result), true)
	end
	refresh()
end

-- Opening when standing on a pad ---------------------------------------------

-- The pad the character is standing on right now, or nil. Only looks at pads
-- that are loaded on this client at this moment (see the note at the top).
local function padUnderPlayer(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	for _, pad in padFolder:GetChildren() do
		if pad:IsA("BasePart") then
			local height = root.Position.Y - pad.Position.Y -- about 3 when standing on it
			if distanceTo(pad) <= OPEN_DISTANCE and height > -1 and height < 6 then
				return pad
			end
		end
	end
	return nil
end

RunService.Heartbeat:Connect(function()
	-- Close when walking away (or if the pad unloaded); allow re-opening once off the pad.
	if currentPad and (not currentPad.Parent or distanceTo(currentPad) > CLOSE_DISTANCE) then
		close()
	end
	if mustLeavePad and (not mustLeavePad.Parent or distanceTo(mustLeavePad) > LEAVE_DISTANCE) then
		mustLeavePad = nil
	end

	-- Caleb isn't eating (full / event running): no pop-up at all.
	if isFull() then
		if ui.Gui.Enabled and not busy then
			close()
		end
		return
	end

	if not ui.Gui.Enabled then
		local pad = padUnderPlayer()
		if pad and pad ~= mustLeavePad then
			open(pad)
		end
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
			amount = math.min(cookies.Value, if isFull() then 0 else math.max(maxCookies() - eaten(), 0))
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
statue:GetAttributeChangedSignal(CalebEvent.Attr.CookiesEaten):Connect(refresh)
statue:GetAttributeChangedSignal(CalebEvent.Attr.MaxCookies):Connect(refresh)
statue:GetAttributeChangedSignal(CalebEvent.Attr.State):Connect(refresh)
cookies.Changed:Connect(refresh)
