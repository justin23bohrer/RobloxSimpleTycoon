-- CalebMouth (client only)
-- What comes out of Caleb's mouth, for CalebAnimator.client. Looks only:
--   * Puff: the white "I'm full" burp cloud (state Full).
--   * Spray: cookie crumbs flying out while he spits at the party.
--   * Sounds: Config.CookiePartySounds.CalebLaugh / CalebSpit when a laugh
--     or spit starts (3D, from his mouth). Empty ids are skipped silently.
-- One client-local Attachment in Workspace.Terrain ("CalebMouth") holds the
-- emitters and sounds; it is created once and moved to his mouth whenever
-- used. Stop() turns everything off and clears every particle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CalebMouth = {}

-- Look (presentation only)
local PARTICLE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local PUFF_COLOR = Color3.fromRGB(255, 248, 235)
local CRUMB_LIGHT = Color3.fromRGB(222, 170, 98)
local CRUMB_DARK = Color3.fromRGB(92, 56, 30)
local SPRAY_TILT = math.rad(20) -- crumbs fly forward and a little up
local SOUND_RANGE = 400 -- studs

local attachment: Attachment? = nil
local puffEmitter: ParticleEmitter? = nil
local sprayEmitter: ParticleEmitter? = nil
local sounds: { [string]: Sound | false } = {}
local wasSpitting = false
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

local function getSpray(): ParticleEmitter
	if not sprayEmitter then
		local emitter = newEmitter()
		emitter.Color = ColorSequence.new(CRUMB_LIGHT, CRUMB_DARK)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0.8) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.9, 1.3)
		emitter.Speed = NumberRange.new(35, 55)
		emitter.SpreadAngle = Vector2.new(18, 18)
		emitter.Acceleration = Vector3.new(0, -70, 0)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-200, 200)
		emitter.Rate = Config.CookiePartyCaleb.SpitCrumbsPerSecond
		sprayEmitter = emitter
	end
	return sprayEmitter :: ParticleEmitter
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

-- Every party frame: spray while `spitting`, sounds when a spit or laugh
-- starts. `head` is nil while the Head is not loaded.
function CalebMouth.Update(head: CFrame?, radius: number, spitting: boolean, laughing: boolean)
	if head then
		place(head, radius, SPRAY_TILT)
	end
	local spray = spitting and head ~= nil
	if spray ~= (sprayEmitter ~= nil and sprayEmitter.Enabled) then
		getSpray().Enabled = spray
	end
	if spitting and not wasSpitting then
		play("CalebSpit")
	end
	if laughing and not wasLaughing then
		play("CalebLaugh")
	end
	wasSpitting, wasLaughing = spitting, laughing
end

-- Everything off and gone (no particles left in the air, no sound playing).
function CalebMouth.Stop()
	for _, emitter in { puffEmitter, sprayEmitter } do
		if emitter then
			emitter.Enabled = false
			emitter:Clear()
		end
	end
	for _, sound in sounds do
		if sound then
			sound:Stop()
		end
	end
	wasSpitting, wasLaughing = false, false
end

return CalebMouth
