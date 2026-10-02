-- CookiePartyCountdown (client only, ModuleScript)
-- The Cookie Party's big center-screen text, used by CookiePartyFX:
--   ShowCallout(phase)  "MORE COOKIES!" (Hype) / "GOLDEN COOKIE FRENZY!"
--                       (Frenzy) slams in, holds, fades.
--   ShowNumber(n)       one countdown number (10..1) slams in with a color
--                       from the cycle and a small camera FieldOfView punch;
--                       3, 2, 1 are red, bigger, with a screen-edge glow.
--   ShowReward(reward)  "+5,000 🍪 PARTY BONUS!" pops, then flies down to
--                       the cookie counter and fades (gone within ~2 s).
--   Hide()              hides it all and puts the camera FOV back.
-- Looks only; never talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CookiePartyCountdown = {}

-- Look (presentation only)
local CALLOUTS = {
	Hype = { Text = "MORE COOKIES! 🍪", Color = Color3.fromRGB(255, 150, 40) },
	Frenzy = { Text = "✨ GOLDEN COOKIE FRENZY! ✨", Color = Color3.fromRGB(255, 214, 64) },
}
local COUNT_COLORS = {
	Color3.fromRGB(255, 214, 64),
	Color3.fromRGB(255, 90, 160),
	Color3.fromRGB(0, 190, 255),
	Color3.fromRGB(110, 220, 90),
	Color3.fromRGB(255, 150, 40),
}
local FINAL_COLOR = Color3.fromRGB(255, 70, 60) -- 3, 2, 1
local SLAM = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local GLOW = TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FOV_BACK = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLY = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local party = nil -- CookiePartyUIBuild parts (set by Init)
local countToken = 0
local calloutToken = 0
local toastToken = 0
local fovBase: number? = nil -- the camera's FOV before our punch
local fovTween: Tween? = nil

local function tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local t = TweenService:Create(instance, info, goal)
	t:Play()
	return t
end

-- Slam a big label in (`from` scale + tilted -> `to`), then fade it out
-- after `hold` seconds, unless isCurrent() says a newer slam took over.
local function slam(label: TextLabel, scale: UIScale, s: UIStroke, from: number, to: number, hold: number, isCurrent: () -> boolean)
	label.TextTransparency = 0
	s.Transparency = 0
	scale.Scale = from
	label.Rotation = (math.random() < 0.5 and -1 or 1) * math.random(8, 18)
	label.Visible = true
	tween(scale, SLAM, { Scale = to })
	tween(label, SLAM, { Rotation = 0 })
	task.delay(hold, function()
		if not isCurrent() then
			return
		end
		tween(s, FADE, { Transparency = 1 })
		tween(scale, FADE, { Scale = to * 0.75 })
		tween(label, FADE, { TextTransparency = 1 }).Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and isCurrent() then
				label.Visible = false
			end
		end)
	end)
end

local function fovPunch(degrees: number)
	local camera = Workspace.CurrentCamera
	if not camera or degrees <= 0 then
		return
	end
	if fovTween then
		fovTween:Cancel()
	end
	fovBase = fovBase or camera.FieldOfView
	camera.FieldOfView = (fovBase :: number) - degrees
	local t = tween(camera, FOV_BACK, { FieldOfView = fovBase })
	fovTween = t
	t.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and fovTween == t then
			fovTween = nil
			fovBase = nil
		end
	end)
end

local function restoreFov()
	if fovTween then
		fovTween:Cancel()
		fovTween = nil
	end
	local camera = Workspace.CurrentCamera
	if camera and fovBase then
		camera.FieldOfView = fovBase
	end
	fovBase = nil
end

function CookiePartyCountdown.ShowCallout(p: string)
	local callout = CALLOUTS[p]
	if not callout then
		return
	end
	calloutToken += 1
	local token = calloutToken
	party.Callout.Text = callout.Text
	party.Callout.TextColor3 = callout.Color
	slam(party.Callout, party.CalloutScale, party.CalloutStroke, 2.6, 1, 1.6, function()
		return token == calloutToken
	end)
end

function CookiePartyCountdown.ShowNumber(n: number)
	countToken += 1
	local token = countToken
	local final = n <= 3
	local label = party.Countdown
	label.Text = tostring(n)
	label.TextColor3 = if final then FINAL_COLOR else COUNT_COLORS[(10 - n) % #COUNT_COLORS + 1]
	slam(label, party.CountdownScale, party.CountdownStroke, if final then 3.2 else 2.4, if final then 1.35 else 1, 0.62, function()
		return token == countToken
	end)
	fovPunch(if final then Config.CookiePartyCountdownFOVPunchBig else Config.CookiePartyCountdownFOVPunch)
	if final then
		for _, strip in party.EdgeGlow do
			strip.BackgroundTransparency = 0.15
			strip.Visible = true
			tween(strip, GLOW, { BackgroundTransparency = 1 })
		end
	end
end

-- 5000 -> "5,000"
local function commas(n: number): string
	local digits = tostring(math.floor(n))
	local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

function CookiePartyCountdown.ShowReward(reward: any)
	if typeof(reward) ~= "number" or reward ~= reward or reward <= 0 or reward == math.huge then
		return
	end
	toastToken += 1
	local token = toastToken
	local toast = party.Toast
	toast.Text = `+{commas(reward)} 🍪 PARTY BONUS!`
	toast.Position = UDim2.fromScale(0.5, 0.42)
	toast.TextTransparency = 0
	party.ToastStroke.Transparency = 0
	party.ToastScale.Scale = 0.2
	toast.Rotation = -8
	toast.Visible = true
	tween(party.ToastScale, SLAM, { Scale = 1.15 })
	tween(toast, SLAM, { Rotation = 0 })
	task.delay(0.9, function()
		if token ~= toastToken then
			return
		end
		tween(party.ToastScale, FLY, { Scale = 0.35 })
		tween(party.ToastStroke, FLY, { Transparency = 1 })
		-- Down to the cookie counter (CashDisplay, bottom center).
		tween(toast, FLY, { Position = UDim2.new(0.5, 0, 1, -70), TextTransparency = 1 }).Completed:Connect(function()
			if token == toastToken then
				toast.Visible = false
			end
		end)
	end)
end

-- Call once with the CookiePartyUIBuild parts.
function CookiePartyCountdown.Init(partyParts)
	party = partyParts
end

-- Hide the countdown, callout and edge glow (not the reward toast: it
-- plays on into TrophyClaim) and put the camera FOV back.
function CookiePartyCountdown.Hide()
	countToken += 1
	calloutToken += 1
	party.Countdown.Visible = false
	party.Callout.Visible = false
	for _, strip in party.EdgeGlow do
		strip.Visible = false
	end
	restoreFov()
end

return CookiePartyCountdown
