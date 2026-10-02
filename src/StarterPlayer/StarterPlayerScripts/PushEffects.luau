-- PushEffects (client only, ModuleScript)
-- The push's hit feedback, drawn by every client from PushFX (Push.client):
--   Swing(position)        whoosh sound (Config.PushSounds.Swing)
--   Hit(character, thief)  a punchy star + puff burst at the target, the hit
--                          sound, and a cartoony pop over its head: "POW!"
--                          for anyone, a big "STOPPED!" when it was a thief.
-- One anchored, invisible FX part (two pooled ParticleEmitters, both sounds)
-- is moved to the spot and Emit()s, so nothing is created per hit; the pops
-- reuse a small pool of BillboardGuis. Empty sound ids are skipped.
-- Presentation only; never talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local PushEffects = {}

-- Look (presentation only, same palette as the cookie counter)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local POW_COLOR = Color3.fromRGB(255, 214, 64) -- sunny yellow
local STOPPED_COLOR = Color3.fromRGB(235, 70, 70)
local FONT = Enum.Font.FredokaOne
local STAR_COUNT = 14
local PUFF_COUNT = 8
local POP_SECONDS = 0.8
local POP_POOL = 4

local function assetId(value: any): string?
	if typeof(value) ~= "string" or value == "" then
		return nil
	end
	return if value:match("^%d+$") then "rbxassetid://" .. value else value
end

local fxPart = Instance.new("Part")
fxPart.Name = "PushFX"
fxPart.Anchored = true
fxPart.CanCollide = false
fxPart.CanQuery = false
fxPart.CanTouch = false
fxPart.Transparency = 1
fxPart.Size = Vector3.one
fxPart.Parent = Workspace

local stars = Instance.new("ParticleEmitter")
stars.Name = "Stars"
stars.Texture = "rbxasset://textures/particles/sparkles_main.dds"
stars.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 150, 40))
stars.LightEmission = 0.6
stars.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
stars.Lifetime = NumberRange.new(0.25, 0.45)
stars.Speed = NumberRange.new(18, 30)
stars.SpreadAngle = Vector2.new(180, 180)
stars.Drag = 6
stars.Rate = 0
stars.Parent = fxPart

local puffs = Instance.new("ParticleEmitter")
puffs.Name = "Puffs"
puffs.Texture = "rbxasset://textures/particles/smoke_main.dds"
puffs.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
puffs.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
puffs.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3.5) })
puffs.Lifetime = NumberRange.new(0.3, 0.5)
puffs.Speed = NumberRange.new(6, 10)
puffs.SpreadAngle = Vector2.new(180, 180)
puffs.Drag = 5
puffs.Rate = 0
puffs.Parent = fxPart

local sounds: { [string]: Sound } = {}
for _, name in { "Swing", "Hit" } do
	local id = assetId(Config.PushSounds[name])
	if id then
		local sound = Instance.new("Sound")
		sound.Name = "Push" .. name
		sound.SoundId = id
		sound.Volume = Config.PushSoundVolumes[name] or 0.6
		sound.RollOffMaxDistance = 120
		sound.Parent = fxPart
		sounds[name] = sound
	end
end

local function playAt(name: string, position: Vector3)
	local sound = sounds[name]
	if not sound then
		return
	end
	-- A world-space attachment (in Terrain) at the spot, so moving the FX
	-- part for the next hit doesn't drag this sound along.
	local spot = Instance.new("Attachment")
	spot.Name = "PushSound"
	spot.Position = position
	spot.Parent = Workspace.Terrain
	local copy = sound:Clone()
	copy.Parent = spot
	copy.Ended:Once(function()
		spot:Destroy()
	end)
	copy:Play()
	task.delay(3, function()
		if spot.Parent then
			spot:Destroy()
		end
	end)
end

-- Pops ----------------------------------------------------------------------

type Pop = { Gui: BillboardGui, Label: TextLabel, Stroke: UIStroke, Scale: UIScale, Token: number }
local pops: { Pop } = {}
local nextPop = 1

for i = 1, POP_POOL do
	local gui = Instance.new("BillboardGui")
	gui.Name = "PushPop" .. i
	gui.Size = UDim2.fromOffset(220, 80)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.Enabled = false
	gui.Parent = fxPart

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = 4
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label

	local scale = Instance.new("UIScale")
	scale.Parent = label

	table.insert(pops, { Gui = gui, Label = label, Stroke = stroke, Scale = scale, Token = 0 })
end

local function showPop(adornee: BasePart, thief: boolean)
	local pop = pops[nextPop]
	nextPop = nextPop % #pops + 1
	pop.Token += 1
	local token = pop.Token

	pop.Label.Text = if thief then "STOPPED!" else "POW!"
	pop.Label.TextColor3 = if thief then STOPPED_COLOR else POW_COLOR
	pop.Label.TextTransparency = 0
	pop.Stroke.Transparency = 0
	pop.Label.Rotation = math.random(-10, 10)
	pop.Gui.Size = if thief then UDim2.fromOffset(260, 90) else UDim2.fromOffset(150, 60)
	pop.Gui.Adornee = adornee
	pop.Gui.Enabled = true
	pop.Scale.Scale = 0.3
	TweenService:Create(pop.Scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()

	local fade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, POP_SECONDS - 0.25)
	TweenService:Create(pop.Label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(pop.Stroke, fade, { Transparency = 1 }):Play()
	task.delay(POP_SECONDS, function()
		if pop.Token == token then
			pop.Gui.Enabled = false
			pop.Gui.Adornee = nil
		end
	end)
end

-- API -------------------------------------------------------------------------

function PushEffects.Swing(position: Vector3)
	playAt("Swing", position)
end

function PushEffects.Hit(character: Model, thief: boolean)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local head = character:FindFirstChild("Head")
	fxPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 1, 0))
	stars:Emit(if thief then STAR_COUNT * 2 else STAR_COUNT)
	puffs:Emit(PUFF_COUNT)
	playAt("Hit", root.Position)
	showPop(if head and head:IsA("BasePart") then head else root, thief)
end

return PushEffects
