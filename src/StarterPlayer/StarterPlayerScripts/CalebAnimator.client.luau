-- CalebAnimator (client only)
-- Caleb's "I'm completely full" animation (state Full) and his dance (state
-- Celebration). Looks only: driven ONLY by the statue's CalebState and
-- CalebStateEndsAt attributes (Shared/CalebEvent); it never talks to the
-- server and changes nothing the server owns.
--
-- How it moves anchored parts without fighting the server:
--   * Every frame while animating, each body part (Shared/CalebBody; never
--     the pedestal, FeedPads, or Podium) is set locally to
--       pose offset * base
--     where base is the part's CFrame as the server last replicated it.
--   * A part whose CFrame is not what we wrote last frame was moved by the
--     server (or just streamed in): that value becomes its new base. So a
--     server tween (growth) during the animation is followed, not undone.
--   * In any other state we stop, put back every part's base CFrame (unless
--     the server already moved it), and disconnect from RenderStepped.
-- Timing comes from CalebStateEndsAt (server time), so a late joiner and
-- everyone else see the same moment of the dance.
-- Poses (the actual moves) are in CalebPoses; numbers in Config.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CalebBody = require(ReplicatedStorage.Shared.CalebBody)
local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local CalebPoses = require(script.Parent:WaitForChild("CalebPoses"))

local State = CalebEvent.State
local map = Workspace:WaitForChild("Map")

-- Puff look (presentation only)
local PUFF_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local PUFF_COLOR = Color3.fromRGB(255, 248, 235)

local statue: Instance? = nil
local statueConnections: { RBXScriptConnection } = {}
local parts: { [BasePart]: string | false } = {} -- loaded body part -> pose group
local byName: { [string]: BasePart } = {}
local base: { [BasePart]: CFrame } = {}
local written: { [BasePart]: CFrame } = {}
local stepConnection: RBXScriptConnection? = nil
local animState: string? = nil
local localStart = 0
local puffed = false
local puffEmitter: ParticleEmitter? = nil

local function addPart(item: Instance)
	local s = statue
	if not s or not CalebBody.IsBodyPart(s, item) then
		return
	end
	local part = item :: BasePart
	parts[part] = CalebPoses.GroupOf(part.Name) or false
	byName[part.Name] = part
	base[part] = part.CFrame
	written[part] = nil
end

local function removePart(item: Instance)
	if not item:IsA("BasePart") or parts[item] == nil then
		return
	end
	parts[item] = nil
	base[item] = nil
	written[item] = nil
	if byName[item.Name] == item then
		byName[item.Name] = nil
	end
end

-- The higher end (along its own Y axis) of a part's base CFrame: a shoulder.
local function topEnd(part: BasePart?): Vector3?
	local cf = part and base[part]
	if not part or not cf then
		return nil
	end
	local a = cf * Vector3.new(0, part.Size.Y / 2, 0)
	local b = cf * Vector3.new(0, -part.Size.Y / 2, 0)
	return if a.Y >= b.Y then a else b
end

-- Turn `rotation` about a world point.
local function about(point: Vector3?, rotation: CFrame): CFrame
	if not point then
		return CFrame.identity
	end
	return CFrame.new(point) * rotation * CFrame.new(-point)
end

local function puff(head: BasePart)
	local emitter = puffEmitter
	if not emitter then
		local attachment = Instance.new("Attachment")
		attachment.Name = "CalebPuff"
		attachment.Parent = Workspace.Terrain
		emitter = Instance.new("ParticleEmitter")
		emitter.Enabled = false
		emitter.Texture = PUFF_TEXTURE
		emitter.Color = ColorSequence.new(PUFF_COLOR)
		emitter.LightEmission = 0.2
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Speed = NumberRange.new(8, 14)
		emitter.SpreadAngle = Vector2.new(25, 25)
		emitter.Drag = 3
		emitter.EmissionDirection = Enum.NormalId.Front
		emitter.Parent = attachment
		puffEmitter = emitter
	end
	local attachment = emitter.Parent :: Attachment
	-- In front of his mouth (front, lower part of the head).
	local radius = head.Size.Y / 2
	attachment.WorldCFrame = head.CFrame * CFrame.new(0, -radius * 0.45, -radius * 0.9)
	emitter:Emit(Config.CalebFullAnim.PuffParticles)
end

-- Seconds into the current state, and seconds left.
local function timing(s: Instance, state: string): (number, number)
	local duration = CalebEvent.Duration(state)
	local endsAt = s:GetAttribute(CalebEvent.Attr.StateEndsAt)
	if typeof(endsAt) == "number" and endsAt > 0 then
		local left = CalebEvent.TimeLeft(s)
		return math.max(0, duration - left), left
	end
	local elapsed = os.clock() - localStart
	return elapsed, math.max(0, duration - elapsed)
end

local function step()
	local s = statue
	if not s or not animState then
		return
	end
	local elapsed, left = timing(s, animState)
	local pose = if animState == State.Full
		then CalebPoses.Full(elapsed, CalebEvent.Duration(State.Full))
		else CalebPoses.Dance(elapsed, left)

	-- Pick up anything the server moved (or that just streamed in).
	local lowest = math.huge
	for part in parts do
		local w = written[part]
		if w == nil or part.CFrame ~= w then
			base[part] = part.CFrame
		end
		lowest = math.min(lowest, base[part].Position.Y - part.Size.Y / 2)
	end
	if lowest == math.huge then
		return -- nothing loaded
	end

	-- Pivots, from the server's (unanimated) positions.
	local torso = byName.Torso
	local center = if torso and base[torso] then base[torso].Position else Vector3.zero
	local feet = Vector3.new(center.X, lowest, center.Z)
	local head = byName.Head
	local neck = if head and base[head] then base[head].Position - Vector3.new(0, head.Size.Y * 0.4, 0) else nil

	local body = about(feet, pose.Body)
	local groups = {
		RightArm = about(topEnd(byName.RightArm), CFrame.Angles(0, 0, pose.RightArm)),
		LeftArm = about(topEnd(byName.LeftUpperArm), CFrame.Angles(0, 0, -pose.LeftArm)),
		Head = about(neck, pose.Head),
		Belly = CFrame.new(pose.Belly),
	}

	for part, group in parts do
		local offset = if group then body * groups[group] else body
		part.CFrame = offset * base[part]
		written[part] = part.CFrame
	end

	if pose.Puff and not puffed and head and parts[head] ~= nil then
		puffed = true
		puff(head)
	end
end

local function stop()
	if stepConnection then
		stepConnection:Disconnect()
		stepConnection = nil
	end
	for part in parts do
		local w = written[part]
		if w ~= nil and part.CFrame == w then
			part.CFrame = base[part] -- the server has not moved it since: put it back
		end
		written[part] = nil
	end
	animState = nil
end

local function refresh()
	local s = statue
	local state = if s then CalebEvent.GetState(s) else nil
	if state ~= State.Full and state ~= State.Celebration then
		stop()
		return
	end
	if state ~= animState then
		animState = state
		localStart = os.clock()
		puffed = false
	end
	if not stepConnection then
		stepConnection = RunService.RenderStepped:Connect(step)
	end
end

local function unbind()
	stop()
	for _, connection in statueConnections do
		connection:Disconnect()
	end
	table.clear(statueConnections)
	table.clear(parts)
	table.clear(byName)
	table.clear(base)
	table.clear(written)
	statue = nil
end

local function bind(s: Instance)
	if s.Name ~= "Statue" or s == statue then
		return
	end
	unbind()
	statue = s
	table.insert(statueConnections, s:GetAttributeChangedSignal(CalebEvent.Attr.State):Connect(refresh))
	table.insert(statueConnections, s.DescendantAdded:Connect(addPart))
	table.insert(statueConnections, s.DescendantRemoving:Connect(removePart))
	for _, item in s:GetDescendants() do
		addPart(item)
	end
	refresh()
end

-- The statue model can be (re)created or stream in later.
map.ChildAdded:Connect(bind)
map.ChildRemoved:Connect(function(child)
	if child == statue then
		unbind()
	end
end)
local existing = map:FindFirstChild("Statue")
if existing then
	bind(existing)
end
