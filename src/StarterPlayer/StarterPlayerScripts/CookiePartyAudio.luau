-- CookiePartyAudio (client only, ModuleScript)
-- The Cookie Party's music, countdown ticks and finale boom, driven by
-- CalebAudio.client.luau (the one place that plays the event's sounds):
--   Music          Config.CookiePartyMusic ("NO PARTY"): loops during
--                  Celebration at normal speed (a real song, so no speed-up:
--                  that would raise its pitch); the volume fades in and
--                  swells a little with the intensity. Stops (quick fade)
--                  the moment Celebration ends.
--   CountdownTick  once per countdown number (10..1, same ceil-of-seconds-
--                  left rule as CookiePartyCountdown), pitch rising.
--   FinaleBoom     on Celebration -> TrophyClaim (only if heard live).
-- Each Sound is created once, in CalebAudio's SoundService folder; an empty
-- id = that sound is skipped silently. The other CookiePartySounds
-- (collects, Caleb's laugh) belong to the cookie and Caleb scripts.
-- Presentation only; never talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)

local CookiePartyAudio = {}

local MUSIC_FADE_IN = 1 -- seconds
local MUSIC_STOP = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TICK_PITCH_STEP = 0.05 -- PlaybackSpeed added per second closer to 0

local sounds: { [string]: Sound } = {}
local statue: Instance? = nil
local connection: RBXScriptConnection? = nil
local lastNumber: number? = nil
local startedAt = 0
local stopTween: Tween? = nil

-- Creates the sounds (once). assetId: CalebAudio's id normalizer. Returns
-- the names with no id, for CalebAudio's single "skipped" print.
function CookiePartyAudio.Init(folder: Instance, assetId: (any) -> string?): { string }
	local missing = {}
	local function add(name: string, key: string, value: any, volume: number?)
		local id = assetId(value)
		if id then
			local sound = Instance.new("Sound")
			sound.Name = "Party" .. name
			sound.SoundId = id
			sound.Volume = volume or 0.5
			sound.Looped = name == "Music"
			sound.Parent = folder
			sounds[name] = sound
		else
			table.insert(missing, key)
		end
	end
	add("Music", "CookiePartyMusic", Config.CookiePartyMusic, Config.CookiePartyMusicVolume)
	for _, name in { "CountdownTick", "FinaleBoom" } do
		add(name, "CookiePartySounds." .. name, Config.CookiePartySounds[name], Config.CookiePartySoundVolumes[name])
	end
	return missing
end

local function musicVolume(left: number): number
	local base = Config.CookiePartyMusicVolume
	local swell = 0.85 + 0.3 * CookieParty.Intensity(left)
	local fadeIn = math.clamp((os.clock() - startedAt) / MUSIC_FADE_IN, 0, 1)
	return math.min(1, base * swell * fadeIn)
end

local function step()
	if not statue then
		return
	end
	local left = CookieParty.TimeLeft(statue)
	local music = sounds.Music
	if music then
		music.Volume = musicVolume(left)
	end

	local n = math.ceil(left)
	local tickSound = sounds.CountdownTick
	if left > 0 and n <= Config.CookiePartyPhases.Countdown and n ~= lastNumber then
		lastNumber = n
		if tickSound then
			tickSound.PlaybackSpeed = 1 + (Config.CookiePartyPhases.Countdown - n) * TICK_PITCH_STEP
			tickSound.TimePosition = 0
			tickSound:Play()
		end
	end
end

-- The party started (or we joined mid-party: the music starts from the
-- top, no catch-up ticks for numbers already passed).
function CookiePartyAudio.Start(theStatue: Instance)
	CookiePartyAudio.Stop()
	statue = theStatue
	lastNumber = nil
	startedAt = os.clock()
	local music = sounds.Music
	if music then
		if stopTween then
			stopTween:Cancel()
			stopTween = nil
		end
		music.Volume = 0
		music.TimePosition = 0
		music:Play()
	end
	connection = RunService.Heartbeat:Connect(step)
end

-- The party is over: the music stops right away (tiny fade, no click).
function CookiePartyAudio.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	statue = nil
	local music = sounds.Music
	if music and music.IsPlaying and not stopTween then
		local fade = TweenService:Create(music, MUSIC_STOP, { Volume = 0 })
		stopTween = fade
		fade.Completed:Connect(function(state)
			if stopTween == fade and state == Enum.PlaybackState.Completed then
				stopTween = nil
				music:Stop()
			end
		end)
		fade:Play()
	end
end

-- The finale. Returns true if a boom actually played.
function CookiePartyAudio.Boom(): boolean
	local boom = sounds.FinaleBoom
	if not boom then
		return false
	end
	boom.TimePosition = 0
	boom:Play()
	return true
end

return CookiePartyAudio
