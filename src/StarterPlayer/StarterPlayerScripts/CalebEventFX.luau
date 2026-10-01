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

-- A burst from the top of the screen. Pieces still falling from the last
-- burst are simply restarted (their old tween is cancelled).
function CalebEventFX.Confetti(parts)
	for _, piece in parts.Confetti do
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
-- player's camera mode and zoom are never touched.
local shaking = false
function CalebEventFX.Shake()
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
		if t >= Config.CalebShakeSeconds or not humanoid.Parent then
			connection:Disconnect()
			humanoid.CameraOffset = original
			shaking = false
			return
		end
		local strength = Config.CalebShakeStuds * (1 - t / Config.CalebShakeSeconds)
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
-- enabled while the party is on (or fading out).
local color: ColorCorrectionEffect? = nil
local bloom: BloomEffect? = nil
local partyOn = false
local partyToken = 0

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

function CalebEventFX.SetParty(on: boolean)
	if on == partyOn then
		return
	end
	partyOn = on
	partyToken += 1
	local token = partyToken
	local c, b = ensureLighting()
	local info = TweenInfo.new(Config.CalebPartyFadeSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	if on then
		c.Enabled = true
		b.Enabled = true
		tween(c, info, { TintColor = PARTY_TINT, Saturation = Config.CalebPartySaturation, Contrast = 0.08 })
		tween(b, info, { Intensity = Config.CalebPartyBloom })
	else
		tween(c, info, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0 })
		tween(b, info, { Intensity = 0 }).Completed:Connect(function()
			if token == partyToken then
				c.Enabled = false
				b.Enabled = false
			end
		end)
	end
end

return CalebEventFX
