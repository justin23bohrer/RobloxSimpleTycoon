-- CookiePartyTotal (client only, ModuleScript)
-- The end-of-party celebration of YOUR total, shown by CookiePartyFX when
-- the server's CookiePartyFinale(reward) remote arrives (the Celebration ->
-- TrophyClaim switch). One short center-screen card, about 3.5 s:
--   "YOU COLLECTED" + a big "🍪 12,450" counting up fast from 0 to the
--   local player's CookiePartyEarned (ticking sound), landing with a scale
--   bump, a shine sweep, a ring burst and a little confetti; "37 cookies
--   grabbed" (CookiePartyCount) under it; then "+5,000 PARTY BONUS!" slams
--   in; then the card flies down toward the cookie counter and fades.
--   0 collected: "🍪 0" + "Next time grab some cookies!" (shorter).
-- It sits between the trophy banner / pill (top) and the CashDisplay
-- (bottom center), measured when it shows, so it never covers either.
-- No buttons, never blocks anything. Players who join during TrophyClaim
-- never get the remote, so they see nothing.
-- The card itself is built by CookiePartyTotalBuild.
-- Looks only: reads the server's attributes, never talks to the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)
local CalebEventFX = require(script.Parent:WaitForChild("CalebEventFX"))
local Numbers = require(script.Parent:WaitForChild("CookiePartyNumbers"))
local CookiePartyTotalBuild = require(script.Parent:WaitForChild("CookiePartyTotalBuild"))

local CookiePartyTotal = {}

-- Look (presentation only)
local ASPECT = 2.6 -- card width / height
local MIN_HEIGHT, MAX_HEIGHT = 80, 240 -- pixels
local GAP = 8 -- pixels kept clear above and below the card
local CASH_FALLBACK = 120 -- pixels reserved at the bottom if CashDisplay is missing
local TICK_EVERY = 0.06 -- seconds between count-up ticks
local LAND_CONFETTI = 24
local POP = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BUMP = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLAM = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SHINE = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RING = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLY = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local ui = nil -- CalebEventUIBuild parts (set by Init)
local card: Frame, cardScale: UIScale
local amount: TextLabel, amountScale: UIScale, shine: UIGradient
local sub: TextLabel, subStroke: UIStroke, bonus: TextLabel, bonusScale: UIScale
local ring: Frame, ringStroke: UIStroke
local fades: { { any } } = {} -- { instance, property, shown value }
local sounds: { [string]: Sound } = {}
local token = 0

local function tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local t = TweenService:Create(instance, info, goal)
	t:Play()
	return t
end

local function loadSound(name: string): Sound?
	local value = Config.CookiePartySounds[name]
	if typeof(value) ~= "string" or value == "" then
		return nil -- no id yet: silent
	end
	local sound = Instance.new("Sound")
	sound.Name = "PartyTotal" .. name
	sound.SoundId = if value:match("^%d+$") then "rbxassetid://" .. value else value
	sound.Volume = Config.CookiePartySoundVolumes[name] or 0.5
	sound.Parent = SoundService
	return sound
end

local function play(name: string, pitch: number)
	local sound = sounds[name]
	if sound then
		sound.PlaybackSpeed = pitch
		sound.TimePosition = 0
		sound:Play()
	end
end

local function attr(name: string): number
	local value = Players.LocalPlayer:GetAttribute(name)
	if typeof(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return 0
	end
	return math.floor(value)
end

-- Size and place the card in the free band between the lowest top panel
-- (trophy banner or pill, even if not shown yet) and the cookie counter.
local function place()
	local screen = ui.Gui.AbsoluteSize
	local top = 0
	for _, pair in { { ui.TrophyBanner, ui.TrophyScale }, { ui.Pill, ui.PillScale } } do
		local frame, scale = pair[1], pair[2]
		-- Unscaled height (dividing by a pop-in UIScale < 1 only over-estimates).
		local height = frame.AbsoluteSize.Y / math.max(scale.Scale, 0.1)
		top = math.max(top, frame.Position.Y.Scale * screen.Y + frame.Position.Y.Offset + height)
	end
	local reserve = CASH_FALLBACK
	local cash = Players.LocalPlayer.PlayerGui:FindFirstChild("CashDisplay")
	local cashPanel = cash and cash:FindFirstChild("Panel")
	if cashPanel and cashPanel:IsA("GuiObject") and cashPanel.AbsoluteSize.Y > 0 then
		reserve = cashPanel.AbsoluteSize.Y - cashPanel.Position.Y.Offset -- Position is (1, -20)
	end
	local bottom = screen.Y - reserve
	local height = math.clamp(bottom - top - GAP * 2, MIN_HEIGHT, MAX_HEIGHT)
	local width = math.min(height * ASPECT, screen.X * 0.94)
	height = width / ASPECT
	card.Size = UDim2.fromOffset(width, height)
	card.Position = UDim2.fromOffset(screen.X / 2, (top + bottom) / 2)
	ring.Position = card.Position
end

local function landFX(big: boolean)
	amountScale.Scale = if big then 1.5 else 1.25
	tween(amountScale, BUMP, { Scale = 1 })
	play("TotalLand", 1)
	if not big then
		return
	end
	shine.Offset = Vector2.new(-1, 0)
	tween(shine, SHINE, { Offset = Vector2.new(1, 0) })
	ring.Size = card.Size
	ringStroke.Transparency = 0
	ring.Visible = true
	tween(ring, RING, { Size = UDim2.fromOffset(card.Size.X.Offset * 1.5, card.Size.Y.Offset * 1.9) })
	tween(ringStroke, RING, { Transparency = 1 })
	CalebEventFX.Confetti(ui, LAND_CONFETTI)
end

local function run(my: number, reward: number, earned: number, count: number)
	local function alive(): boolean
		return my == token
	end
	task.wait(0.2) -- the card's pop-in
	if not alive() then
		return
	end
	if earned > 0 then
		local start, lastTick = os.clock(), 0
		local seconds = math.max(Config.CookiePartyTotalCountSeconds, 0.1)
		while true do
			local a = math.min((os.clock() - start) / seconds, 1)
			amount.Text = "🍪 " .. Numbers.Format(earned * (1 - (1 - a) ^ 3))
			if os.clock() - lastTick >= TICK_EVERY and a < 1 then
				lastTick = os.clock()
				play("TotalTick", 0.9 + 0.6 * a)
			end
			if a >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
			if not alive() then
				return
			end
		end
		sub.Text = if count == 1 then "1 cookie grabbed" else `{Numbers.Format(count)} cookies grabbed`
	else
		amount.Text = "🍪 0"
		sub.Text = "Next time grab some cookies!"
	end
	landFX(earned > 0)
	tween(sub, POP, { TextTransparency = 0 })
	tween(subStroke, POP, { Transparency = 0 })

	task.wait(0.35)
	if not alive() then
		return
	end
	if reward > 0 then
		bonus.Text = `+{Numbers.Format(reward)} PARTY BONUS!`
		bonusScale.Scale = 2.2
		bonus.Rotation = -10
		bonus.Visible = true
		tween(bonusScale, SLAM, { Scale = 1 })
		tween(bonus, SLAM, { Rotation = 0 })
		play("TotalLand", 1.25)
	end

	task.wait(Config.CookiePartyTotalHoldSeconds)
	if not alive() then
		return
	end
	-- Fly down toward the cookie counter (bottom center) and fade.
	local screen = ui.Gui.AbsoluteSize
	tween(card, FLY, { Position = UDim2.fromOffset(screen.X / 2, screen.Y - 70) })
	tween(cardScale, FLY, { Scale = 0.25 })
	for _, f in fades do
		tween(f[1], FLY, { [f[2]] = 1 })
	end
	task.wait(FLY.Time)
	if alive() then
		card.Visible = false
	end
end

-- Call once with the CalebEventUIBuild parts; builds the hidden card.
function CookiePartyTotal.Init(uiParts)
	ui = uiParts
	local p = CookiePartyTotalBuild.Build(ui.Gui)
	card, cardScale = p.Card, p.CardScale
	amount, amountScale, shine = p.Amount, p.AmountScale, p.Shine
	sub, subStroke, bonus, bonusScale = p.Sub, p.SubStroke, p.Bonus, p.BonusScale
	ring, ringStroke = p.Ring, p.RingStroke
	fades = p.Fades
	sounds.TotalTick = loadSound("TotalTick")
	sounds.TotalLand = loadSound("TotalLand")
end

-- The finale: show the local player's total and the party bonus (`reward`
-- from the remote; anything that is not a sane number counts as 0).
function CookiePartyTotal.Show(reward: any)
	if typeof(reward) ~= "number" or reward ~= reward or reward < 0 or reward == math.huge then
		reward = 0
	end
	token += 1
	place()
	for _, f in fades do
		f[1][f[2]] = f[3]
	end
	amount.Text = "🍪 0"
	sub.TextTransparency = 1
	subStroke.Transparency = 1
	bonus.Visible = false
	amountScale.Scale = 1
	ring.Visible = false
	cardScale.Scale = 0.3
	card.Visible = true
	tween(cardScale, POP, { Scale = 1 })
	task.spawn(run, token, math.floor(reward), attr(CookieParty.PlayerAttr.Earned), attr(CookieParty.PlayerAttr.Collected))
end

-- Stop and hide it at once (a new party starting).
function CookiePartyTotal.Hide()
	token += 1
	if card then
		card.Visible = false
		ring.Visible = false
	end
end

return CookiePartyTotal
