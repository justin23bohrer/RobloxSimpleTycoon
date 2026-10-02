-- CookiePartyFeedback (client only, ModuleScript)
-- The "you got it!" feedback for CookiePartyCookies.client: a sparkle +
-- confetti burst, a floating "+50" number (CookiePartyNumbers; bigger,
-- with "GOLDEN!" / "GIANT!!", for the special cookies), the collect sound
-- (pitch rises with the combo), and small dust puffs for landings and for
-- cookies other players grab.
--
-- Presentation only: it decides nothing. Sounds are created once (empty ids
-- in Config.CookiePartySounds are skipped). The world bits (burst emitters
-- in Terrain, the floating-number pool) are made by Setup and destroyed by
-- Teardown, so nothing is left between parties.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Numbers = require(script.Parent:WaitForChild("CookiePartyNumbers"))

local Feedback = {}

-- Looks only; not gameplay tuning.
local SOUND_COPIES = 3 -- quick collects overlap instead of cutting each other off
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local CONFETTI = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 160)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 230, 120)),
})
local TYPE_LOOK = {
	Normal = { Color = Color3.fromRGB(255, 236, 140), Size = 1, Tag = "", Sound = "Collect", Pitch = 1, Burst = 10 },
	Chocolate = { Color = Color3.fromRGB(255, 170, 90), Size = 1.15, Tag = "", Sound = "Collect", Pitch = 0.88, Burst = 14 },
	Golden = { Color = Color3.fromRGB(255, 210, 40), Size = 1.5, Tag = "GOLDEN!", Sound = "CollectGolden", Pitch = 1, Burst = 30 },
	Giant = { Color = Color3.fromRGB(255, 110, 200), Size = 1.8, Tag = "GIANT!!", Sound = "CollectGiant", Pitch = 1, Burst = 45 },
}

-- Sounds (once) ---------------------------------------------------------------

local sounds: { [string]: { Sound } } = {}
local soundTurn: { [string]: number } = {}
do
	local folder = Instance.new("Folder")
	folder.Name = "CookiePartyCookies"
	for _, name in { "Collect", "CollectGolden", "CollectGiant" } do
		local value = Config.CookiePartySounds[name]
		if typeof(value) == "string" and value ~= "" then
			local id = if value:match("^%d+$") then "rbxassetid://" .. value else value
			local list = {}
			for _ = 1, SOUND_COPIES do
				local sound = Instance.new("Sound")
				sound.Name = name
				sound.SoundId = id
				sound.Volume = Config.CookiePartySoundVolumes[name] or 0.5
				sound.Parent = folder
				table.insert(list, sound)
			end
			sounds[name] = list
			soundTurn[name] = 1
		end
	end
	folder.Parent = SoundService
end

local function playSound(name: string, pitch: number)
	local list = sounds[name]
	if not list then
		return -- no id yet: silent
	end
	local turn = soundTurn[name]
	soundTurn[name] = turn % #list + 1
	local sound = list[turn]
	sound.PlaybackSpeed = pitch
	sound.TimePosition = 0
	sound:Play()
end

-- World bits (Setup / Teardown) -------------------------------------------------

local burst: Attachment? = nil
local sparkle: ParticleEmitter? = nil
local confetti: ParticleEmitter? = nil
local puff: ParticleEmitter? = nil

local function emitter(parent: Instance, texture: string): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Rate = 0 -- bursts only (Emit)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = parent
	return e
end

function Feedback.Setup()
	if burst then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "CookiePartyBurst"
	attachment.Parent = Workspace.Terrain
	burst = attachment

	local s = emitter(attachment, SPARKLE_TEXTURE)
	s.LightEmission = 1
	s.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	s.Lifetime = NumberRange.new(0.35, 0.7)
	s.Speed = NumberRange.new(8, 16)
	s.Drag = 4
	sparkle = s

	local c = emitter(attachment, SPARKLE_TEXTURE)
	c.Color = CONFETTI
	c.Size = NumberSequence.new(0.5)
	c.Lifetime = NumberRange.new(0.7, 1.1)
	c.Speed = NumberRange.new(10, 18)
	c.Acceleration = Vector3.new(0, -35, 0)
	c.RotSpeed = NumberRange.new(-300, 300)
	c.Drag = 1.5
	confetti = c

	local p = emitter(attachment, "rbxasset://textures/particles/smoke_main.dds")
	p.Color = ColorSequence.new(Color3.fromRGB(240, 215, 170))
	p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1.8) })
	p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	p.Lifetime = NumberRange.new(0.4, 0.6)
	p.Speed = NumberRange.new(3, 6)
	p.Acceleration = Vector3.new(0, -4, 0)
	puff = p

	Numbers.Setup()
end

function Feedback.Teardown()
	if burst then
		burst:Destroy()
		burst, sparkle, confetti, puff = nil, nil, nil, nil
	end
	Numbers.Teardown()
end

-- Effects -----------------------------------------------------------------------

-- A dust puff (landings, cookies someone else grabbed).
function Feedback.Puff(position: Vector3, count: number)
	if burst and puff then
		burst.WorldPosition = position
		puff:Emit(count)
	end
end

-- The local player collected a cookie at position. combo = collects in a
-- quick row (1 = a single one).
function Feedback.Collect(cookieType: string, value: number, position: Vector3, combo: number)
	local look = TYPE_LOOK[cookieType] or TYPE_LOOK.Normal
	if burst and sparkle and confetti then
		burst.WorldPosition = position
		sparkle.Color = ColorSequence.new(look.Color)
		sparkle:Emit(look.Burst)
		confetti:Emit(math.ceil(look.Burst / 2))
	end
	Numbers.Show("+" .. Numbers.Format(value), look.Tag, look.Color, look.Size, position)
	local rise = 1 + math.min(combo - 1, 10) * 0.035
	playSound(look.Sound, look.Pitch * rise * (0.95 + math.random() * 0.1))
end

-- A cookie touched down: a puff (bigger for Giant), a twinkle for Golden.
function Feedback.Land(cookieType: string, position: Vector3)
	Feedback.Puff(position, if cookieType == "Giant" then 14 else 4)
	if cookieType == "Golden" and burst and sparkle then
		sparkle.Color = ColorSequence.new(TYPE_LOOK.Golden.Color)
		sparkle:Emit(6)
	end
end

return Feedback
