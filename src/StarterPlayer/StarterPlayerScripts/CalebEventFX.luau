-- CalebEventFX (client only, ModuleScript)
-- Screen effects for the Caleb Full Event, used by CalebEventUI.client.luau:
-- the "CALEB IS FULLLL!!!" slam, a white flash, UI confetti (the pooled
-- frames from CalebEventUIBuild), a short camera shake, and the party
-- lighting (one ColorCorrection + one Bloom, created once).
--
-- Presentation only. Never changes game state, never talks to the server.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local CalebEventFX = {}

-- Look (presentation only)
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 214, 64),
	Color3.fromRGB(255, 90, 160),
	Color3.fromRGB(70, 200, 80),
	Color3.fromRGB(255, 150, 40),
	Color3.fromRGB(0, 162, 255),
	Color3.fromRGB(255, 255, 255),
}
local PARTY_TINT = Color3.fromRGB(255, 236, 225)
local PULSE_TINT = Color3.fromRGB(255, 215, 235) -- pinker, on the party's beat
local SLAM_IN = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLAM_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FLASH = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local t = TweenService:Create(instance, info, goal)
	t:Play()
	return t
end

function CalebEventFX.Flash(parts)
	parts.Flash.BackgroundTransparency = 0.15
	parts.Flash.Visible = true
	tween(parts.Flash, FLASH, { BackgroundTransparency = 1 }).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			parts.Flash.Visible = false
		end
	end)
end

-- A burst from the top of the screen. `count` pieces (default: the whole
-- pool) are taken round-robin, so small repeated bursts during the party
-- reuse the oldest pieces; a piece still falling is simply restarted (its
-- old tween is cancelled).
local nextPiece = 1
function CalebEventFX.Confetti(parts, count: number?)
	local pool = parts.Confetti
	if #pool == 0 then
		return
	end
	for _ = 1, math.min(count or #pool, #pool) do
		local piece = pool[nextPiece]
		nextPiece = nextPiece % #pool + 1
		local x = math.random()
		local size = math.random(10, 18)
		piece.Size = UDim2.fromOffset(size, math.floor(size * 0.6))
		piece.Position = UDim2.fromScale(x, -0.05 - math.random() * 0.3)
		piece.Rotation = math.random(0, 360)
		piece.BackgroundColor3 = CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
		piece.Visible = true
		local fall = TweenInfo.new(1.6 + math.random() * 1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(piece, fall, {
			Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.25, 1.1),
			Rotation = piece.Rotation + math.random(-540, 540),
		}).Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed then
				piece.Visible = false
			end
		end)
	end
end

-- Small shake through Humanoid.CameraOffset, restored afterwards; the
-- player's camera mode and zoom are never touched. Default strength/length:
-- Config.CalebShakeStuds / CalebShakeSeconds (the finale passes bigger ones).
local shaking = false
function CalebEventFX.Shake(studs: number?, seconds: number?)
	local power = studs or Config.CalebShakeStuds
	local length = seconds or Config.CalebShakeSeconds
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if shaking or not humanoid then
		return
	end
	shaking = true
	local original = humanoid.CameraOffset
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		if t >= length or not humanoid.Parent then
			connection:Disconnect()
			humanoid.CameraOffset = original
			shaking = false
			return
		end
		local strength = power * (1 - t / length)
		humanoid.CameraOffset = original
			+ Vector3.new((math.random() * 2 - 1) * strength, (math.random() * 2 - 1) * strength, 0)
	end)
end

-- The big text slams in (huge + tilted -> normal), then wobbles a moment.
local fullToken = 0
function CalebEventFX.SlamFullText(parts)
	fullToken += 1
	local token = fullToken
	local label = parts.FullText
	local home = UDim2.fromScale(0.5, 0.42)
	label.Position = home
	label.TextTransparency = 0
	parts.FullStroke.Transparency = 0
	label.Rotation = -25
	parts.FullScale.Scale = 3
	label.Visible = true
	tween(parts.FullScale, SLAM_IN, { Scale = 1 })
	tween(label, SLAM_IN, { Rotation = -4 })
	task.delay(SLAM_IN.Time, function()
		for i = 8, 1, -1 do
			if token ~= fullToken then
				return
			end
			label.Position = home + UDim2.fromOffset(math.random(-i, i) * 1.5, math.random(-i, i) * 1.5)
			task.wait(0.04)
		end
		label.Position = home
	end)
end

function CalebEventFX.HideFullText(parts)
	if not parts.FullText.Visible then
		return
	end
	fullToken += 1
	local token = fullToken
	tween(parts.FullScale, SLAM_OUT, { Scale = 0.6 })
	tween(parts.FullStroke, SLAM_OUT, { Transparency = 1 })
	tween(parts.FullText, SLAM_OUT, { TextTransparency = 1 }).Completed:Connect(function()
		if token == fullToken then
			parts.FullText.Visible = false
		end
	end)
end

-- Party lighting. Neutral values = no visible change; the effects are only
-- enabled while the party is on (or fading out). While on, UpdateParty
-- (called every frame by CookiePartyFX) sets the values: the base look,
-- faded in over CalebPartyFadeSeconds, plus a ramp with the party's
-- intensity and a soft pulse on the beat. Turning it off tweens from
-- wherever it is (the finale peak) back to neutral.
local color: ColorCorrectionEffect? = nil
local bloom: BloomEffect? = nil
local partyOn = false
local partyToken = 0
local partyStartedAt = 0
local fadeTweens: { Tween } = {}

local function ensureLighting(): (ColorCorrectionEffect, BloomEffect)
	if not color or not bloom then
		color = Instance.new("ColorCorrectionEffect")
		color.Name = "CalebPartyColor"
		color.Enabled = false
		color.Parent = Lighting
		bloom = Instance.new("BloomEffect")
		bloom.Name = "CalebPartyBloom"
		bloom.Intensity = 0
		bloom.Size = 24
		bloom.Threshold = 1
		bloom.Enabled = false
		bloom.Parent = Lighting
	end
	return color :: ColorCorrectionEffect, bloom :: BloomEffect
end

local function cancelFades()
	for _, t in fadeTweens do
		t:Cancel()
	end
	table.clear(fadeTweens)
end

function CalebEventFX.SetParty(on: boolean)
	if on == partyOn then
		return
	end
	partyOn = on
	partyToken += 1
	local token = partyToken
	local c, b = ensureLighting()
	cancelFades()
	if on then
		partyStartedAt = os.clock()
		c.Enabled = true
		b.Enabled = true
		CalebEventFX.UpdateParty(0, 0)
	else
		local info = TweenInfo.new(Config.CalebPartyFadeSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		table.insert(fadeTweens, tween(c, info, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0 }))
		local fade = tween(b, info, { Intensity = 0 })
		table.insert(fadeTweens, fade)
		fade.Completed:Connect(function(state)
			if token == partyToken and state == Enum.PlaybackState.Completed then
				c.Enabled = false
				b.Enabled = false
			end
		end)
	end
end

-- intensity: 0..1 over the party (CookieParty.Intensity). pulse: 0..1, the
-- beat pulse already scaled by the phase's strength. Does nothing while the
-- party is off.
function CalebEventFX.UpdateParty(intensity: number, pulse: number)
	if not partyOn or not color or not bloom then
		return
	end
	local level = math.clamp((os.clock() - partyStartedAt) / math.max(Config.CalebPartyFadeSeconds, 0.01), 0, 1)
	level = level * level * (3 - 2 * level) -- smoothstep, like the old Sine fade
	local saturation = Config.CalebPartySaturation + intensity * Config.CookiePartyExtraSaturation + pulse * 0.08
	local glow = Config.CalebPartyBloom + intensity * Config.CookiePartyExtraBloom + pulse * 0.1
	color.TintColor = Color3.new(1, 1, 1):Lerp(PARTY_TINT:Lerp(PULSE_TINT, pulse * 0.6), level)
	color.Saturation = saturation * level
	color.Contrast = (0.08 + pulse * 0.04) * level
	bloom.Intensity = glow * level
end

return CalebEventFX
