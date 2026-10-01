-- CalebEventUI (client only)
-- The Caleb Full Event's screen UI and screen effects:
--   Full         "🍪 CALEB IS FULLLL!!! 🍪" slams in, white flash, camera
--                shake, confetti.
--   Celebration  "COOKIE PARTY!" banner with the time left; party lighting.
--   TrophyClaim  eligible: trophy banner with "TROPHY CLAIM: 4:32";
--                claimed: "Trophy claimed! 🏆"; not eligible: "CALEB IS
--                RESTING — new round soon" with the countdown.
--   Normal       nothing ("TROPHY CLAIM CLOSED" for a few seconds right
--                after a trophy claim ends). StatueBar shows the total.
--
-- Display only: driven by the statue's CalebState / CalebStateEndsAt
-- attributes and the local player's CalebFed / CalebTrophyClaimed (all set
-- by the server; see Shared/CalebEvent.luau). Reads them at start, so joining
-- mid-event shows the right thing, and handles any state jump. The UI is
-- built once (CalebEventUIBuild) and only updated here; effects live in
-- CalebEventFX.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local CalebEventUIBuild = require(script.Parent.CalebEventUIBuild)
local CalebEventFX = require(script.Parent.CalebEventFX)

local State = CalebEvent.State
local NAME = string.upper(Config.StatueName)

local player = Players.LocalPlayer
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")
local parts = CalebEventUIBuild.Build(player:WaitForChild("PlayerGui"))

local POP_IN = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local current: string? = nil -- statue state we are showing (nil until the first read)
local trophyView: string? = nil -- "Eligible" / "Claimed" / "Resting" during TrophyClaim
local closedToken = 0

-- 272.3 -> "4:33"
local function formatTime(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

local function popIn(frame: Frame, scale: UIScale)
	frame.Visible = true
	scale.Scale = 0.5
	TweenService:Create(scale, POP_IN, { Scale = 1 }):Play()
end

local function showPill(text: string)
	parts.PillText.Text = text
	if not parts.Pill.Visible then
		popIn(parts.Pill, parts.PillScale)
	end
end

local function updateTimers()
	local left = formatTime(CalebEvent.TimeLeft(statue))
	if current == State.Celebration then
		parts.PartyTimer.Text = left
	elseif current == State.TrophyClaim then
		parts.TrophyTimer.Text = `TROPHY CLAIM: {left}`
		if trophyView == "Resting" then
			parts.PillText.Text = `{NAME} IS RESTING — new round soon  {left}`
		end
	end
end

local function getTrophyView(): string
	if player:GetAttribute(CalebEvent.PlayerAttr.TrophyClaimed) == true then
		return "Claimed"
	end
	local fed = player:GetAttribute(CalebEvent.PlayerAttr.Fed)
	if typeof(fed) == "number" and fed > 0 then
		return "Eligible"
	end
	return "Resting"
end

-- Which TrophyClaim panel to show; only re-pops when the view changes
-- (e.g. Eligible -> Claimed after the player claims).
local function refreshTrophy()
	local view = getTrophyView()
	if view == trophyView then
		return
	end
	trophyView = view
	parts.TrophyBanner.Visible = false
	parts.Pill.Visible = false
	if view == "Eligible" then
		popIn(parts.TrophyBanner, parts.TrophyScale)
	elseif view == "Claimed" then
		showPill("Trophy claimed! 🏆")
	else
		showPill(`{NAME} IS RESTING — new round soon`)
	end
	updateTimers()
end

local function showClosed()
	closedToken += 1
	local token = closedToken
	showPill("TROPHY CLAIM CLOSED")
	task.delay(Config.CalebClosedMessageSeconds, function()
		if token == closedToken then
			parts.Pill.Visible = false
		end
	end)
end

-- Switch the UI to `state`. `joining` = first read when this script starts
-- (mid-event join): no flash or camera shake then.
local function enter(state: string, previous: string?, joining: boolean)
	-- Clear whatever the previous state showed.
	closedToken += 1
	trophyView = nil
	parts.Pill.Visible = false
	parts.TrophyBanner.Visible = false
	if state ~= State.Full then
		CalebEventFX.HideFullText(parts)
	end
	if state ~= State.Celebration then
		parts.PartyBanner.Visible = false
		CalebEventFX.SetParty(false)
	end

	if state == State.Full then
		CalebEventFX.SlamFullText(parts)
		CalebEventFX.Confetti(parts)
		if not joining then
			CalebEventFX.Flash(parts)
			CalebEventFX.Shake()
		end
	elseif state == State.Celebration then
		popIn(parts.PartyBanner, parts.PartyScale)
		CalebEventFX.SetParty(true)
	elseif state == State.TrophyClaim then
		refreshTrophy()
	elseif previous == State.TrophyClaim then
		showClosed()
	end
	updateTimers()
end

local function onStateChanged()
	local state = CalebEvent.GetState(statue)
	if state == current then
		return
	end
	local previous = current
	current = state
	enter(state, previous, previous == nil)
end

-- Reconcile now (joining mid-event) and on every change.
onStateChanged()
statue:GetAttributeChangedSignal(CalebEvent.Attr.State):Connect(onStateChanged)
statue:GetAttributeChangedSignal(CalebEvent.Attr.StateEndsAt):Connect(updateTimers)

local function onPlayerAttr()
	if current == State.TrophyClaim then
		refreshTrophy()
	end
end
player:GetAttributeChangedSignal(CalebEvent.PlayerAttr.Fed):Connect(onPlayerAttr)
player:GetAttributeChangedSignal(CalebEvent.PlayerAttr.TrophyClaimed):Connect(onPlayerAttr)

-- Countdown: a few times per second, only while a timed banner is up.
task.spawn(function()
	while true do
		task.wait(Config.CalebUITickSeconds)
		if current == State.Celebration or current == State.TrophyClaim then
			updateTimers()
		end
	end
end)
