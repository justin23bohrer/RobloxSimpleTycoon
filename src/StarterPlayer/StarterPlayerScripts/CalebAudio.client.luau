-- CalebAudio (client only)
-- Sound effects for the Caleb Full Event (no music yet). Driven only by the
-- replicated attributes in Shared/CalebEvent.luau:
--   Normal -> Full         Full (once)
--   -> Celebration         CelebrationStart (once) + CookieRain (quiet loop)
--   Celebration ends       CookieRain fades out, EventEnd (once)
--   CookiesEaten goes up   Grow (quiet, rate-limited; only in Normal)
--   local player's CalebTrophyClaimed turns true    TrophyClaim (once)
--
-- Each Sound is created once (in a SoundService folder) and reused. A sound
-- whose Config.CalebSounds id is empty is skipped silently. Joining mid-event
-- plays no old one-shots; only the rain loop starts if it is Celebration.
-- Presentation only: never changes anything and never talks to the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)

local State = CalebEvent.State
local Attr = CalebEvent.Attr

local player = Players.LocalPlayer
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")

local RAIN_FADE = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Sounds ----------------------------------------------------------------------

local folder = Instance.new("Folder")
folder.Name = "CalebAudio"
folder.Parent = SoundService

-- "123" or "rbxassetid://123" -> "rbxassetid://123"; anything else -> nil.
local function assetId(value: any): string?
	if typeof(value) ~= "string" or value == "" then
		return nil
	end
	if value:match("^%d+$") then
		return "rbxassetid://" .. value
	end
	return value
end

local sounds: { [string]: Sound } = {}
local missing = {}
for _, name in { "Full", "CelebrationStart", "Grow", "CookieRain", "TrophyClaim", "EventEnd" } do
	local id = assetId(Config.CalebSounds[name])
	if id then
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		sound.Volume = Config.CalebSoundVolumes[name] or 0.5
		sound.Looped = name == "CookieRain"
		sound.Parent = folder
		sounds[name] = sound
	else
		table.insert(missing, name)
	end
end
if #missing > 0 and RunService:IsStudio() then
	print("[CalebAudio] no sound id in Config.CalebSounds for: " .. table.concat(missing, ", ")
		.. " (skipped; see tools/audio/README.md)")
end

local function playOnce(name: string)
	local sound = sounds[name]
	if sound then
		sound.TimePosition = 0
		sound:Play()
	end
end

-- Rain loop: a fade-out tween that may still be running when it starts again.
local rainFade: Tween? = nil

local function startRain()
	local sound = sounds.CookieRain
	if not sound then
		return
	end
	if rainFade then
		rainFade:Cancel()
		rainFade = nil
	end
	sound.Volume = Config.CalebSoundVolumes.CookieRain or 0.2
	if not sound.IsPlaying then
		sound:Play()
	end
end

local function stopRain()
	local sound = sounds.CookieRain
	if not sound or not sound.IsPlaying or rainFade then
		return
	end
	local fade = TweenService:Create(sound, RAIN_FADE, { Volume = 0 })
	rainFade = fade
	fade.Completed:Connect(function(playbackState)
		if rainFade == fade and playbackState == Enum.PlaybackState.Completed then
			rainFade = nil
			sound:Stop()
		end
	end)
	fade:Play()
end

-- Event state ------------------------------------------------------------------

local lastState = CalebEvent.GetState(statue)

local function onStateChanged()
	local state = CalebEvent.GetState(statue)
	if state == lastState then
		return
	end
	local previous = lastState
	lastState = state

	if state == State.Full then
		playOnce("Full")
	elseif state == State.Celebration then
		playOnce("CelebrationStart")
		startRain()
	end
	if previous == State.Celebration then
		playOnce("EventEnd")
	end
	if state ~= State.Celebration then
		stopRain() -- the loop never outlives the Celebration
	end
end

statue:GetAttributeChangedSignal(Attr.State):Connect(onStateChanged)

-- Joined mid-Celebration: only the loop, no old one-shots.
if lastState == State.Celebration then
	startRain()
end

-- Grow: Caleb was fed -------------------------------------------------------------

local function eaten(): number
	local value = statue:GetAttribute(Attr.CookiesEaten)
	return if typeof(value) == "number" then value else 0
end

local lastEaten = eaten()
local lastGrowAt = -math.huge

statue:GetAttributeChangedSignal(Attr.CookiesEaten):Connect(function()
	local now = eaten()
	local grew = now > lastEaten
	lastEaten = now -- also follows the reset back to 0
	if not grew or CalebEvent.GetState(statue) ~= State.Normal then
		return
	end
	local t = os.clock()
	if t - lastGrowAt >= Config.CalebGrowSoundInterval then
		lastGrowAt = t
		playOnce("Grow")
	end
end)

-- Trophy claimed (local player only) ----------------------------------------------

local TROPHY = CalebEvent.PlayerAttr.TrophyClaimed
local hadTrophy = player:GetAttribute(TROPHY) == true

player:GetAttributeChangedSignal(TROPHY):Connect(function()
	local has = player:GetAttribute(TROPHY) == true
	if has and not hadTrophy then
		playOnce("TrophyClaim")
	end
	hadTrophy = has
end)
