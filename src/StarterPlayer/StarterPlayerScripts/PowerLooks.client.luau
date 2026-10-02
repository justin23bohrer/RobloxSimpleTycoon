-- PowerLooks (client only)
-- Animates every player's body power effects on this screen. The server's
-- PowerVisuals builds them inside each character (so they replicate to
-- everyone, late joiners too) and tags them (Shared/PowerLooks); this script
-- only switches them on and plays them. It never creates or keeps anything
-- in a character.
--
-- * Speed trail (tag PowerSpeedTrail): on while that player's sideways speed
--   is over Config.TrophySpeedTrailMinSpeed (off again a bit below it, so it
--   doesn't flicker), measured from the HumanoidRootPart's movement. When it
--   turns on, the SpeedBurst emitter shoots a few speed lines.
-- * Jumps (tag PowerJumpFX): from that character's Humanoid.StateChanged
--   (humanoid states replicate, so this works for other players too):
--     - Jumping from the ground -> JumpBurst sparkles + a springy double ring
--       on the ground (PowerLooksRings), sized by the Strength attribute.
--     - Jumping while in Freefall (only DoubleJump.client's air jump does
--       that) -> AirBurst puff + an orange ring of light in mid-air.
--     - AirGlow is on from a jump until the character is out of the air.
--   No remote: the jumper's own client and everyone else's see the same
--   state change.
--
-- Nothing runs for players without powers: the Heartbeat loop exists only
-- while some tagged trail exists, and only tagged JumpFX get a StateChanged
-- connection (dropped when the tag's instance goes away).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PowerLooks = require(ReplicatedStorage.Shared.PowerLooks)
local PowerLooksRings = require(script.Parent:WaitForChild("PowerLooksRings"))

-- Looks only; not gameplay tuning.
local OFF_FACTOR = 0.85 -- trail turns off below MinSpeed * this
local SMOOTHING = 12 -- speed smoothing (higher = reacts faster)
local TELEPORT_SPEED = 400 -- studs/s: faster is a teleport/respawn, ignored
local BURST_COOLDOWN = 0.8 -- seconds between speed-line bursts
local JUMP_RING_SECONDS = 0.45
local INNER_RING_SCALE = 0.55 -- second, smaller ring of the jump
local AIR_RING_SECONDS = 0.4
local GROUND_RAY = 8 -- studs to look down for the ground under a jump

local Freefall = Enum.HumanoidStateType.Freefall
local Jumping = Enum.HumanoidStateType.Jumping

type TrailState = { root: BasePart, lastPos: Vector3?, speed: number, burstAt: number }

local trails: { [Trail]: TrailState } = {}
local trailLoop: RBXScriptConnection? = nil
local jumpConnections: { [Attachment]: RBXScriptConnection } = {}
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude

local lerp = PowerLooks.Lerp

-- Speed trails -----------------------------------------------------------

local function stepTrails(dt: number)
	if dt <= 0 then
		return
	end
	local minSpeed = Config.TrophySpeedTrailMinSpeed
	local blend = 1 - math.exp(-SMOOTHING * dt)
	local now = os.clock()
	for trail, state in trails do
		local pos = state.root.Position
		local last = state.lastPos
		state.lastPos = pos
		if not last then
			continue
		end
		local measured = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude / dt
		if measured > TELEPORT_SPEED then
			continue
		end
		state.speed += (measured - state.speed) * blend
		local on = state.speed >= minSpeed or (trail.Enabled and state.speed >= minSpeed * OFF_FACTOR)
		if on == trail.Enabled then
			continue
		end
		trail.Enabled = on
		if on and now - state.burstAt >= BURST_COOLDOWN then
			state.burstAt = now
			local burst = trail.Parent and trail.Parent:FindFirstChild(PowerLooks.SpeedBurst)
			if burst and burst:IsA("ParticleEmitter") then
				burst:Emit(Config.TrophySpeedBurstCount)
			end
		end
	end
end

local function addTrail(instance: Instance)
	if not instance:IsA("Trail") or trails[instance] then
		return
	end
	local top = instance.Parent
	local root = top and top.Parent
	if not (root and root:IsA("BasePart")) then
		return
	end
	instance.Enabled = false
	trails[instance] = { root = root, lastPos = nil, speed = 0, burstAt = -math.huge }
	if not trailLoop then
		trailLoop = RunService.Heartbeat:Connect(stepTrails)
	end
end

local function removeTrail(instance: Instance)
	if not instance:IsA("Trail") then
		return
	end
	trails[instance] = nil
	if trailLoop and next(trails) == nil then
		trailLoop:Disconnect()
		trailLoop = nil
	end
end

-- Jumps ------------------------------------------------------------------

local function emit(fx: Attachment, name: string, count: number): boolean
	local emitter = fx:FindFirstChild(name)
	if not (emitter and emitter:IsA("ParticleEmitter")) then
		return false
	end
	if count > 0 then
		emitter:Emit(count)
	end
	return true
end

-- The ground under the jump (the state change can arrive a moment after
-- takeoff for other players), or the feet if there is none close.
local function groundBelow(fx: Attachment, character: Model): Vector3
	local feet = fx.WorldPosition
	groundParams.FilterDescendantsInstances = { character }
	local hit = Workspace:Raycast(feet + Vector3.new(0, 1, 0), Vector3.new(0, -GROUND_RAY, 0), groundParams)
	return if hit then hit.Position + Vector3.new(0, 0.05, 0) else feet
end

local function onState(fx: Attachment, character: Model, old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
	local glow = fx:FindFirstChild(PowerLooks.AirGlow)
	local airGlow = if glow and glow:IsA("ParticleEmitter") then glow else nil
	if new == Jumping then
		local strength = fx:GetAttribute(PowerLooks.StrengthAttr)
		local t = if type(strength) == "number" then math.clamp(strength :: number, 0, 1) else 0
		if old == Freefall and emit(fx, PowerLooks.AirBurst, Config.TrophyDoubleJumpPuffCount) then
			-- The air jump: a ring of light and a puff right where it fires.
			PowerLooksRings.Play(fx.WorldPosition, Config.TrophyDoubleJumpColor, Config.TrophyDoubleJumpRingRadius, AIR_RING_SECONDS)
		elseif emit(fx, PowerLooks.JumpBurst, math.round(lerp(Config.TrophyJumpBurstMin, Config.TrophyJumpBurstMax, t))) then
			local ground = groundBelow(fx, character)
			local radius = lerp(Config.TrophyJumpRingRadiusMin, Config.TrophyJumpRingRadiusMax, t)
			PowerLooksRings.Play(ground, Config.TrophyJumpLookColor, radius, JUMP_RING_SECONDS)
			PowerLooksRings.Play(ground, Config.TrophyJumpLookColor, radius * INNER_RING_SCALE, JUMP_RING_SECONDS * 0.8)
		end
		if airGlow then
			airGlow.Enabled = true
		end
	elseif new ~= Freefall and airGlow then
		airGlow.Enabled = false -- landed, running, climbing, swimming, seated, dead...
	end
end

local function addJump(instance: Instance)
	if not instance:IsA("Attachment") or jumpConnections[instance] then
		return
	end
	local character = instance:FindFirstAncestorOfClass("Model")
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		-- Rare: the effect arrived before the Humanoid. Try once more.
		task.spawn(function()
			if character:WaitForChild("Humanoid", 5) and CollectionService:HasTag(instance, PowerLooks.JumpTag) and instance:IsDescendantOf(Workspace) then
				addJump(instance)
			end
		end)
		return
	end
	local fx = instance :: Attachment
	jumpConnections[fx] = humanoid.StateChanged:Connect(function(old, new)
		onState(fx, character, old, new)
	end)
end

local function removeJump(instance: Instance)
	local connection = jumpConnections[instance :: any]
	if connection then
		connection:Disconnect()
		jumpConnections[instance :: any] = nil
	end
end

-- Hook up ------------------------------------------------------------------

CollectionService:GetInstanceAddedSignal(PowerLooks.TrailTag):Connect(addTrail)
CollectionService:GetInstanceRemovedSignal(PowerLooks.TrailTag):Connect(removeTrail)
CollectionService:GetInstanceAddedSignal(PowerLooks.JumpTag):Connect(addJump)
CollectionService:GetInstanceRemovedSignal(PowerLooks.JumpTag):Connect(removeJump)
for _, instance in CollectionService:GetTagged(PowerLooks.TrailTag) do
	addTrail(instance)
end
for _, instance in CollectionService:GetTagged(PowerLooks.JumpTag) do
	addJump(instance)
end
