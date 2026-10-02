-- CalebMouth (client only)
-- What comes out of Caleb's mouth, for CalebAnimator.client. Looks only:
--   * Puff: the white "I'm full" burp cloud (state Full).
--   * Sound: Config.CookiePartySounds.CalebLaugh when a laugh starts (3D,
--     from his mouth). An empty id is skipped silently.
-- One client-local Attachment in Workspace.Terrain ("CalebMouth") holds the
-- emitter and sound; it is created once and moved to his mouth whenever
-- used. Stop() turns everything off and clears every particle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CalebMouth = {}

-- Look (presentation only)
local PARTICLE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local PUFF_COLOR = Color3.fromRGB(255, 248, 235)
local SOUND_RANGE = 400 -- studs

local attachment: Attachment? = nil
local puffEmitter: ParticleEmitter? = nil
local sounds: { [string]: Sound | false } = {}
local wasLaughing = false

local function getAttachment(): Attachment
	if not attachment then
		local a = Instance.new("Attachment")
		a.Name = "CalebMouth"
		a.Parent = Workspace.Terrain
		attachment = a
	end
	return attachment :: Attachment
end

-- In front of his mouth (front, lower part of the head), facing forward.
local function place(head: CFrame, radius: number, tilt: number)
	getAttachment().WorldCFrame = head * CFrame.new(0, -radius * 0.45, -radius * 0.9) * CFrame.Angles(tilt, 0, 0)
end

local function newEmitter(): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Texture = PARTICLE_TEXTURE
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Parent = getAttachment()
	return emitter
end

local function getPuff(): ParticleEmitter
	if not puffEmitter then
		local emitter = newEmitter()
		emitter.Color = ColorSequence.new(PUFF_COLOR)
		emitter.LightEmission = 0.2
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Speed = NumberRange.new(8, 14)
		emitter.SpreadAngle = Vector2.new(25, 25)
		emitter.Drag = 3
		puffEmitter = emitter
	end
	return puffEmitter :: ParticleEmitter
end

local function play(key: string)
	local sound = sounds[key]
	if sound == nil then
		local id = Config.CookiePartySounds[key]
		if typeof(id) ~= "string" or id == "" then
			sound = false
		else
			local s = Instance.new("Sound")
			s.Name = key
			s.SoundId = id
			s.Volume = Config.CookiePartySoundVolumes[key] or 0.5
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMaxDistance = SOUND_RANGE
			s.Parent = getAttachment()
			sound = s
		end
		sounds[key] = sound
	end
	if sound then
		sound.TimePosition = 0
		sound:Play()
	end
end

-- The burp cloud, once. `head` = the Head's CFrame, `radius` = half its height.
function CalebMouth.Puff(head: CFrame, radius: number)
	place(head, radius, 0)
	getPuff():Emit(Config.CalebFullAnim.PuffParticles)
end

-- Every party frame: the laugh sound when a laugh starts. `head` is nil
-- while the Head is not loaded.
function CalebMouth.Update(head: CFrame?, radius: number, laughing: boolean)
	if head then
		place(head, radius, 0)
	end
	if laughing and not wasLaughing then
		play("CalebLaugh")
	end
	wasLaughing = laughing
end

-- Everything off and gone (no puff left in the air, no sound playing).
function CalebMouth.Stop()
	if puffEmitter then
		puffEmitter.Enabled = false
		puffEmitter:Clear()
	end
	for _, sound in sounds do
		if sound then
			sound:Stop()
		end
	end
	wasLaughing = false
end

return CalebMouth
