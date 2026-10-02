-- CalebAnimator (client only)
-- Caleb's "I'm completely full" animation (state Full) and his Cookie Party
-- (state Celebration: the dance that ramps up per phase, moves, and the
-- "I'M FULL!" wind-up). Looks only: driven ONLY by the statue's CalebState,
-- CalebStateEndsAt and CalebCycleId attributes (Shared/CalebEvent); it never
-- talks to the server and changes nothing the server owns.
--
-- How it moves anchored parts without fighting the server:
--   * Every frame while animating, each body part (Shared/CalebBody; never
--     the pedestal, FeedPads, or Podium) is set locally to
--       pose offset * base
--     where base is the part's CFrame as the server last replicated it.
--     The Belly's Size is set the same way (base size * pose.BellyScale).
--   * A part whose CFrame (or the Belly's Size) is not what we wrote last
--     frame was changed by the server (or just streamed in): that value
--     becomes its new base. So a server tween (growth) is followed, not undone.
--   * In any other state we stop, put back every part's base CFrame and Size
--     (unless the server already changed it), stop the mouth effects
--     (CalebMouth), and disconnect from RenderStepped.
-- Timing comes from CalebStateEndsAt (server time) and the party's moves
-- from CalebCycleId, so a late joiner and everyone else see the same moment.
-- Poses are in CalebPoses (Full, the base dance) and CalebPartyPoses /
-- CalebPartyMoves (the party); numbers in Config.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CalebBody = require(ReplicatedStorage.Shared.CalebBody)
local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local CalebPoses = require(script.Parent:WaitForChild("CalebPoses"))
local CalebPartyPoses = require(script.Parent:WaitForChild("CalebPartyPoses"))
local CalebMouth = require(script.Parent:WaitForChild("CalebMouth"))

local State = CalebEvent.State
local map = Workspace:WaitForChild("Map")

local statue: Instance? = nil
local statueConnections: { RBXScriptConnection } = {}
local parts: { [BasePart]: string | false } = {} -- loaded body part -> pose group
local byName: { [string]: BasePart } = {}
local base: { [BasePart]: CFrame } = {}
local written: { [BasePart]: CFrame } = {}
local baseSize: { [BasePart]: Vector3 } = {} -- Belly group only
local writtenSize: { [BasePart]: Vector3 } = {}
local stepConnection: RBXScriptConnection? = nil
local animState: string? = nil
local localStart = 0
local puffed = false
local seed = 0

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
	writtenSize[part] = nil
	if parts[part] == "Belly" then
		baseSize[part] = part.Size
	end
end

local function removePart(item: Instance)
	if not item:IsA("BasePart") or parts[item] == nil then
		return
	end
	parts[item] = nil
	base[item] = nil
	written[item] = nil
	baseSize[item] = nil
	writtenSize[item] = nil
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

-- Seconds into the current state.
local function elapsedIn(s: Instance, state: string): number
	local endsAt = s:GetAttribute(CalebEvent.Attr.StateEndsAt)
	if typeof(endsAt) == "number" and endsAt > 0 then
		return math.max(0, CalebEvent.Duration(state) - CalebEvent.TimeLeft(s))
	end
	return os.clock() - localStart
end

local function step()
	local s = statue
	if not s or not animState then
		return
	end
	local elapsed = elapsedIn(s, animState)
	local pose = if animState == State.Full
		then CalebPoses.Full(elapsed, CalebEvent.Duration(State.Full))
		else CalebPartyPoses.Pose(elapsed, seed)

	-- Pick up anything the server moved or resized (or that just streamed in).
	local lowest = math.huge
	for part, group in parts do
		local w = written[part]
		if w == nil or part.CFrame ~= w then
			base[part] = part.CFrame
		end
		if group == "Belly" then
			local ws = writtenSize[part]
			if ws == nil or part.Size ~= ws then
				baseSize[part] = part.Size
			end
		end
		lowest = math.min(lowest, base[part].Position.Y - (baseSize[part] or part.Size).Y / 2)
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
	local belly = byName.Belly
	-- A bigger belly grows mostly forward (its back stays in the torso).
	local bellyPush = if belly and baseSize[belly] then (pose.BellyScale - 1) * baseSize[belly].Z * 0.35 else 0

	local body = about(feet, CFrame.new(0, pose.BodyUp, 0) * CFrame.Angles(0, pose.BodyYaw, 0) * CFrame.Angles(pose.BodyPitch, 0, pose.BodyRoll))
	local headTurn = about(neck, CFrame.Angles(pose.HeadPitch, pose.HeadYaw, pose.HeadRoll))
	local groups = {
		RightArm = about(topEnd(byName.RightArm), CFrame.Angles(pose.RightArmFwd, 0, pose.RightArm)),
		LeftArm = about(topEnd(byName.LeftUpperArm), CFrame.Angles(pose.LeftArmFwd, 0, -pose.LeftArm)),
		Head = headTurn,
		Mouth = headTurn * CFrame.new(0, -pose.MouthOpen, -pose.MouthOpen * 0.3),
		RightCheek = headTurn * CFrame.new(pose.Cheeks, 0, -pose.Cheeks * 0.5),
		LeftCheek = headTurn * CFrame.new(-pose.Cheeks, 0, -pose.Cheeks * 0.5),
		Belly = CFrame.new(0, pose.BellyUp, -pose.BellyForward - bellyPush),
	}

	for part, group in parts do
		local offset = if group then body * groups[group] else body
		part.CFrame = offset * base[part]
		written[part] = part.CFrame
		if group == "Belly" then
			part.Size = baseSize[part] * math.max(pose.BellyScale, 0.5)
			writtenSize[part] = part.Size
		end
	end

	local headLoaded = head ~= nil and parts[head] ~= nil
	if pose.Puff and not puffed and headLoaded then
		puffed = true
		CalebMouth.Puff((head :: BasePart).CFrame, (head :: BasePart).Size.Y / 2)
	end
	if animState == State.Celebration then
		local headCFrame = if headLoaded then (head :: BasePart).CFrame else nil
		CalebMouth.Update(headCFrame, if headLoaded then (head :: BasePart).Size.Y / 2 else 0, pose.Spit, pose.Laugh)
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
		local ws = writtenSize[part]
		if ws ~= nil and part.Size == ws and baseSize[part] then
			part.Size = baseSize[part]
		end
		writtenSize[part] = nil
	end
	CalebMouth.Stop()
	animState = nil
end

local function refresh()
	local s = statue
	local state = if s then CalebEvent.GetState(s) else nil
	if not s or (state ~= State.Full and state ~= State.Celebration) then
		stop()
		return
	end
	if state ~= animState then
		animState = state
		localStart = os.clock()
		puffed = false
		local cycleId = s:GetAttribute(CalebEvent.Attr.CycleId)
		seed = CalebPartyPoses.Seed(if typeof(cycleId) == "string" then cycleId else nil)
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
	table.clear(baseSize)
	table.clear(writtenSize)
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
