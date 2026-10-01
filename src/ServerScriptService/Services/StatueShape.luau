-- StatueShape (server only)
-- Helper for StatueService: makes the statue (Caleb) fatter. Presentation only;
-- it never reads or changes cookies.
--
-- Apply(fatness, seconds) takes fatness from 0 (as built) to 1 (fully fed)
-- and moves/resizes parts from their ORIGINAL map positions, so calling it
-- again with any value is always safe:
--   * Torso and Belt get wider and deeper; arms and legs move out with them
--     and get thicker.
--   * Belly, RightCheek, LeftCheek, and Chin start hidden inside the body and
--     grow out of it.
--   * The gold chain rides on top of the torso/belly.
-- The statue is unrotated (faces -Z), so statue axes are world axes.
--
-- tools/statue/generate_statue.py places the hidden parts where this file
-- puts them at fatness 0; keep the two in sync if you change the numbers.

local TweenService = game:GetService("TweenService")

local StatueShape = {}

type Original = { Position: Vector3, Rotation: CFrame, Size: Vector3 }

local originals: { [BasePart]: Original } = {}
local partsByName: { [string]: BasePart } = {}
local chain: { BasePart } = {}

-- Remembers every statue part's map position and size. Call once at start.
function StatueShape.Setup(statue: Model)
	local feedPads = statue:FindFirstChild("FeedPads")
	for _, item in statue:GetDescendants() do
		if item:IsA("BasePart") and not (feedPads and item:IsDescendantOf(feedPads)) then
			originals[item] = { Position = item.Position, Rotation = item.CFrame.Rotation, Size = item.Size }
			partsByName[item.Name] = item
			if item.Name:match("^ChainBead") or item.Name == "ChainPendant" then
				table.insert(chain, item)
			end
		end
	end
	for _, name in { "Torso", "Belt", "Head", "Belly", "RightCheek", "LeftCheek", "Chin" } do
		if not partsByName[name] then
			warn(`StatueShape: the statue has no '{name}' part; it will not grow there`)
		end
	end
end

local function move(part: BasePart?, position: Vector3, size: Vector3, seconds: number)
	if not part then
		return
	end
	local goal = { CFrame = CFrame.new(position) * originals[part].Rotation, Size = size }
	if seconds <= 0 then
		part.CFrame = goal.CFrame
		part.Size = goal.Size
	else
		TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out), goal):Play()
	end
end

-- Moves a part sideways by dx and scales its size (X and Z by thick, or all
-- three for balls).
local function shiftAndThicken(name: string, dx: number, thick: number, seconds: number)
	local part = partsByName[name]
	if not part then
		return
	end
	local o = originals[part]
	local size = if part:IsA("Part") and part.Shape == Enum.PartType.Ball
		then o.Size * thick
		else Vector3.new(o.Size.X * thick, o.Size.Y, o.Size.Z * thick)
	move(part, o.Position + Vector3.new(dx, 0, 0), size, seconds)
end

-- A ball that grows out of a center point along a direction.
local function grow(name: string, center: Vector3, direction: Vector3, distance: number, diameter: number, seconds: number)
	move(partsByName[name], center + direction.Unit * distance, Vector3.one * diameter, seconds)
end

function StatueShape.Apply(fatness: number, seconds: number)
	local f = math.clamp(fatness, 0, 1)
	local torso = partsByName.Torso
	if not torso then
		return
	end
	local t = originals[torso]
	local width = t.Size.X * (1 + 0.9 * f)
	local depth = t.Size.Z * (1 + 1.6 * f)
	local dx = (width - t.Size.X) / 2
	local torsoBottom = t.Position.Y - t.Size.Y / 2

	move(torso, t.Position, Vector3.new(width, t.Size.Y, depth), seconds)
	local belt = partsByName.Belt
	if belt then
		local b = originals[belt]
		move(belt, b.Position, Vector3.new(width + 0.1, b.Size.Y, depth + 0.1), seconds)
	end

	-- Arms move out with the torso; the left hand stays on the (wider) hip.
	local arm = 1 + 0.6 * f
	for _, name in { "RightArm", "RightHand" } do
		shiftAndThicken(name, dx, arm, seconds)
	end
	for _, name in { "LeftUpperArm", "LeftForearm", "LeftElbow", "LeftHand" } do
		shiftAndThicken(name, -dx, arm, seconds)
	end

	local leg = 1 + 0.8 * f
	for side, sign in { Right = 1, Left = -1 } do
		shiftAndThicken(`{side}Leg`, sign * 0.6 * dx, leg, seconds)
		for _, piece in { "Shoe", "Sole" } do
			local part = partsByName[`{side}{piece}`]
			if part then
				local o = originals[part]
				move(part, o.Position + Vector3.new(sign * 0.6 * dx, 0, 0), Vector3.new(o.Size.X * (1 + 0.6 * f), o.Size.Y, o.Size.Z), seconds)
			end
		end
	end

	local neck = partsByName.Neck
	if neck then
		local o = originals[neck] -- a cylinder: X is its length
		move(neck, o.Position, Vector3.new(o.Size.X, o.Size.Y * leg, o.Size.Z * leg), seconds)
	end

	-- Belly: hidden inside the torso at 0, sticks out up to 3.7 studs at 1.
	local bellySize = 5 + 8 * f
	local bellyY = torsoBottom + 3
	local bellyFront = t.Position.Z - depth / 2 - (-0.3 + 4 * f)
	local bellyZ = bellyFront + bellySize / 2
	move(partsByName.Belly, Vector3.new(t.Position.X, bellyY, bellyZ), Vector3.one * bellySize, seconds)

	-- The chain sits on whichever is further forward: the torso or the belly.
	for _, bead in chain do
		local o = originals[bead]
		local front = t.Position.Z - depth / 2
		local dy = o.Position.Y - bellyY
		local radius = bellySize / 2
		if math.abs(dy) < radius then
			front = math.min(front, bellyZ - math.sqrt(radius * radius - dy * dy))
		end
		local gap = if bead.Name == "ChainPendant" then 0.1 else 0.05
		move(bead, Vector3.new(o.Position.X, o.Position.Y, front - gap), o.Size, seconds)
	end

	local head = partsByName.Head
	if head then
		local center = originals[head].Position
		grow("RightCheek", center, Vector3.new(5.0, -1.4, -3.4), 4.6 + 1.6 * f, 2 + 2.8 * f, seconds)
		grow("LeftCheek", center, Vector3.new(-5.0, -1.4, -3.4), 4.6 + 1.6 * f, 2 + 2.8 * f, seconds)
		grow("Chin", center, Vector3.new(0, -0.93, -0.37), 4.0 + 2.2 * f, 3 + 3.0 * f, seconds)
	end
end

return StatueShape
