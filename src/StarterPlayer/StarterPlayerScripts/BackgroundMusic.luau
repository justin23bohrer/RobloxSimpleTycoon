-- BackgroundMusic (client only, ModuleScript)
-- The game's background music (Config.BackgroundMusic), driven by
-- CalebAudio.client.luau (the one place that knows when the Cookie Party
-- runs): FadeIn when the player joins and when the party ends, a fast
-- FadeOut (Config.MusicSuspenseCutSeconds) the moment Caleb is Full, so
-- there is no music until the party. One looping Sound, created once in
-- CalebAudio's SoundService folder. FadeOut pauses it, so FadeIn resumes
-- the song where it stopped instead of starting it over. An empty id = no
-- background music (every call does nothing). Presentation only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local BackgroundMusic = {}

local sound: Sound? = nil
local fade: Tween? = nil

local function fadeInfo(seconds: number?): TweenInfo
	return TweenInfo.new(math.max(seconds or Config.MusicFadeSeconds, 0), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
end

-- Creates the Sound (once). assetId: CalebAudio's id normalizer. Returns
-- the missing key (if any) for CalebAudio's single "skipped" print.
function BackgroundMusic.Init(folder: Instance, assetId: (any) -> string?): { string }
	local id = assetId(Config.BackgroundMusic)
	if not id then
		return { "BackgroundMusic" }
	end
	local s = Instance.new("Sound")
	s.Name = "BackgroundMusic"
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s.Parent = folder
	sound = s
	return {}
end

-- Play (or resume) and fade up to Config.BackgroundMusicVolume.
function BackgroundMusic.FadeIn()
	local s = sound
	if not s then
		return
	end
	if fade then
		fade:Cancel()
		fade = nil
	end
	if not s.IsPlaying then
		s:Resume() -- from where FadeOut paused it (0 the first time)
	end
	local tween = TweenService:Create(s, fadeInfo(), { Volume = Config.BackgroundMusicVolume })
	fade = tween
	tween:Play()
end

-- Fade to silence over `seconds` (default Config.MusicFadeSeconds), then
-- pause (keeps the song's position).
function BackgroundMusic.FadeOut(seconds: number?)
	local s = sound
	if not s or not s.IsPlaying then
		return
	end
	if fade then
		fade:Cancel()
	end
	local tween = TweenService:Create(s, fadeInfo(seconds), { Volume = 0 })
	fade = tween
	tween.Completed:Connect(function(state)
		if fade == tween and state == Enum.PlaybackState.Completed then
			fade = nil
			s:Pause()
		end
	end)
	tween:Play()
end

return BackgroundMusic
