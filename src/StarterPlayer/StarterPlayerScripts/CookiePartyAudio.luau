-- CookiePartyAudio (client only, ModuleScript)
-- The Cookie Party's music, countdown ticks and finale boom, driven by
-- CalebAudio.client.luau (the one place that plays the event's sounds):
--   Music          loops during Celebration; PlaybackSpeed tweens to
--                  Config.CookiePartyMusicSpeed[phase] at each phase change
--                  and the volume swells a little with the intensity. Stops
--                  (quick fade) the moment Celebration ends.
--   CountdownTick  once per countdown number (10..1, same ceil-of-seconds-
--                  left rule as CookiePartyCountdown), pitch rising.
--   FinaleBoom     on Celebration -> TrophyClaim (only if heard live).
-- Each Sound is created once, in CalebAudio's SoundService folder; an empty
-- Config.CookiePartySounds id = that sound is skipped silently. The other
-- CookiePartySounds (collects, Caleb's laugh/spit) belong to the cookie and
-- Caleb scripts. Presentation only; never talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)

local CookiePartyAudio = {}

local NAMES = { "Music", "CountdownTick", "FinaleBoom" }
local MUSIC_FADE_IN = 1 -- seconds
local MUSIC_STOP = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SPEED_CHANGE = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local TICK_PITCH_STEP = 0.05 -- PlaybackSpeed added per second closer to 0

local sounds: { [string]: Sound } = {}
local statue: Instance? = nil
local connection: RBXScriptConnection? = nil
local phase: string? = nil
local lastNumber: number? = nil
local startedAt = 0
local speedTween: Tween? = nil
local stopTween: Tween? = nil

-- Creates the sounds (once). assetId: CalebAudio's id normalizer. Returns
-- the names with no id, for CalebAudio's single "skipped" print.
function CookiePartyAudio.Init(folder: Instance, assetId: (any) -> string?): { string }
	local missing = {}
	for _, name in NAMES do
		local id = assetId(Config.CookiePartySounds[name])
		if id then
			local sound = Instance.new("Sound")
			sound.Name = "Party" .. name
			sound.SoundId = id
			sound.Volume = Config.CookiePartySoundVolumes[name] or 0.5
			sound.Looped = name == "Music"
			sound.Parent = folder
			sounds[name] = sound
		else
			table.insert(missing, "CookiePartySounds." .. name)
		end
	end
	return missing
end

local function musicVolume(left: number): number
	local base = Config.CookiePartySoundVolumes.Music or 0.4
	local swell = 0.85 + 0.3 * CookieParty.Intensity(left)
	local fadeIn = math.clamp((os.clock() - startedAt) / MUSIC_FADE_IN, 0, 1)
	return math.min(1, base * swell * fadeIn)
end

local function step()
	if not statue then
		return
	end
	local left = CookieParty.TimeLeft(statue)
	local p = CookieParty.GetPhase(left)
	local music = sounds.Music
	if music then
		if p ~= phase then
			if speedTween then
				speedTween:Cancel()
			end
			speedTween = TweenService:Create(music, SPEED_CHANGE, { PlaybackSpeed = Config.CookiePartyMusicSpeed[p] or 1 })
			speedTween:Play()
		end
		music.Volume = musicVolume(left)
	end
	phase = p

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

-- The party started (or we joined mid-party: the music starts at the
-- current phase's speed, no catch-up ticks for numbers already passed).
function CookiePartyAudio.Start(theStatue: Instance)
	CookiePartyAudio.Stop()
	statue = theStatue
	local left = CookieParty.TimeLeft(theStatue)
	phase = CookieParty.GetPhase(left)
	lastNumber = nil
	startedAt = os.clock()
	local music = sounds.Music
	if music then
		if stopTween then
			stopTween:Cancel()
			stopTween = nil
		end
		music.PlaybackSpeed = Config.CookiePartyMusicSpeed[phase] or 1
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
	phase = nil
	if speedTween then
		speedTween:Cancel()
		speedTween = nil
	end
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
