-- StatueShape (server only)
-- Helper for StatueService / CalebCycle: how big and fat the statue (Caleb)
-- looks, and hiding him. Presentation only; it never reads or changes cookies.
--
-- Apply(progress, seconds) takes progress from 0 (nothing eaten) to 1 (the
-- goal: cookies / CalebEvent.MaxCookies()). Two curves, both in Config:
--   * Fatness, front-loaded so the first feeds show:
--       log(1 + progress * CalebFatnessCurve) / log(1 + CalebFatnessCurve)
--     (with 100,000: 0.01% -> 0.21, 0.1% -> 0.40, 1% -> 0.60, 25% -> 0.88,
--      50% -> 0.94, 100% -> 1; about the old cookie-count log curve)
--       - Torso and Belt get wider and deeper; arms and legs move out with
--         them and get thicker.
--       - Belly, RightCheek, LeftCheek, and Chin start hidden inside the body
--         and grow out of it.
--       - The gold chain rides on top of the torso/belly.
--   * Overall scale, back-loaded so the late feeds show too:
--       below the goal: CalebMinScale + (CalebMaxScale - CalebMinScale -
--         CalebFinalPopScale) * progress ^ CalebScaleCurve
--       at the goal: CalebMaxScale (one last visible "pop")
--     (with 1 / 1.6 / 0.1 / 2: 25% -> 1.03, 50% -> 1.13, 75% -> 1.28,
--      90% -> 1.41, 99% -> 1.49, 100% -> 1.6)
--     Every body part is scaled about the top of the pedestal under Caleb, so
--     his feet stay on it.
-- Everything is computed from the ORIGINAL map positions and sizes, so
-- calling Apply again with any value is always safe. Changes tween over
-- `seconds` (0 = instant).
--
-- SetHidden(hidden) hides/shows only Caleb's body (PlotVisibility), never the
-- Pedestal* parts, FeedPads, or Podium (see Shared/CalebBody).
--
-- The statue is unrotated (faces -Z), so statue axes are world axes.
-- tools/statue/generate_statue.py places the hidden parts where this file
-- puts them at fatness 0; keep the two in sync if you change the numbers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CalebBody = require(ReplicatedStorage.Shared.CalebBody)
local Config = require(ReplicatedStorage.Shared.Config)
local PlotVisibility = require(script.Parent.PlotVisibility)

local StatueShape = {}

type Original = { Position: Vector3, Rotation: CFrame, Size: Vector3 }
type Target = { Position: Vector3, Size: Vector3 }

local originals: { [BasePart]: Original } = {}
local bodyParts: { BasePart } = {}
local partsByName: { [string]: BasePart } = {}
local chain: { BasePart } = {}
local pivot = Vector3.zero -- top of the pedestal, under Caleb's feet

-- Remembers every body part's map position and size. Call once at start.
function StatueShape.Setup(statue: Model)
	local feetY = math.huge
	for _, part in CalebBody.GetParts(statue) do
		originals[part] = { Position = part.Position, Rotation = part.CFrame.Rotation, Size = part.Size }
		table.insert(bodyParts, part)
		partsByName[part.Name] = part
		if part.Name:match("^ChainBead") or part.Name == "ChainPendant" then
			table.insert(chain, part)
		end
		feetY = math.min(feetY, part.Position.Y - part.Size.Y / 2)
	end
	for _, name in { "Torso", "Belt", "Head", "Belly", "RightCheek", "LeftCheek", "Chin" } do
		if not partsByName[name] then
			warn(`StatueShape: the statue has no '{name}' part; it will not grow there`)
		end
	end

	-- Scale about the pedestal's top (or his lowest point if there is none).
	local pedestalTop = -math.huge
	for _, child in statue:GetChildren() do
		if child:IsA("BasePart") and child.Name:match("^Pedestal") then
			pedestalTop = math.max(pedestalTop, child.Position.Y + child.Size.Y / 2)
		end
	end
	local torso = partsByName.Torso
	local center = if torso then torso.Position else statue:GetPivot().Position
	pivot = Vector3.new(center.X, if pedestalTop > -math.huge then pedestalTop else feetY, center.Z)
end

local function fatnessFor(progress: number): number
	local k = Config.CalebFatnessCurve
	return math.log(1 + progress * k) / math.log(1 + k)
end

local function scaleFor(progress: number): number
	if progress >= 1 then
		return Config.CalebMaxScale
	end
	local range = Config.CalebMaxScale - Config.CalebMinScale - Config.CalebFinalPopScale
	return Config.CalebMinScale + range * progress ^ Config.CalebScaleCurve
end

-- Builds the fattened (unscaled) shape into `targets`. Parts not set here
-- keep their original position and size.
local function fatten(f: number, targets: { [BasePart]: Target })
	local function set(part: BasePart?, position: Vector3, size: Vector3)
		if part then
			targets[part] = { Position = position, Size = size }
		end
	end

	-- Moves a part sideways by dx and scales its size (X and Z by thick, or
	-- all three for balls).
	local function shiftAndThicken(name: string, dx: number, thick: number)
		local part = partsByName[name]
		if not part then
			return
		end
		local o = originals[part]
		local size = if part:IsA("Part") and part.Shape == Enum.PartType.Ball
			then o.Size * thick
			else Vector3.new(o.Size.X * thick, o.Size.Y, o.Size.Z * thick)
		set(part, o.Position + Vector3.new(dx, 0, 0), size)
	end

	-- A ball that grows out of a center point along a direction.
	local function grow(name: string, center: Vector3, direction: Vector3, distance: number, diameter: number)
		set(partsByName[name], center + direction.Unit * distance, Vector3.one * diameter)
	end

	local torso = partsByName.Torso
	if not torso then
		return
	end
	local t = originals[torso]
	local width = t.Size.X * (1 + 0.9 * f)
	local depth = t.Size.Z * (1 + 1.6 * f)
	local dx = (width - t.Size.X) / 2
	local torsoBottom = t.Position.Y - t.Size.Y / 2

	set(torso, t.Position, Vector3.new(width, t.Size.Y, depth))
	local belt = partsByName.Belt
	if belt then
		local b = originals[belt]
		set(belt, b.Position, Vector3.new(width + 0.1, b.Size.Y, depth + 0.1))
	end

	-- Arms move out with the torso; the left hand stays on the (wider) hip.
	local arm = 1 + 0.6 * f
	for _, name in { "RightArm", "RightHand" } do
		shiftAndThicken(name, dx, arm)
	end
	for _, name in { "LeftUpperArm", "LeftForearm", "LeftElbow", "LeftHand" } do
		shiftAndThicken(name, -dx, arm)
	end

	local leg = 1 + 0.8 * f
	for side, sign in { Right = 1, Left = -1 } do
		shiftAndThicken(`{side}Leg`, sign * 0.6 * dx, leg)
		for _, piece in { "Shoe", "Sole" } do
			local part = partsByName[`{side}{piece}`]
			if part then
				local o = originals[part]
				set(part, o.Position + Vector3.new(sign * 0.6 * dx, 0, 0), Vector3.new(o.Size.X * (1 + 0.6 * f), o.Size.Y, o.Size.Z))
			end
		end
	end

	local neck = partsByName.Neck
	if neck then
		local o = originals[neck] -- a cylinder: X is its length
		set(neck, o.Position, Vector3.new(o.Size.X, o.Size.Y * leg, o.Size.Z * leg))
	end

	-- Belly: hidden inside the torso at 0, sticks out up to 3.7 studs at 1.
	local bellySize = 5 + 8 * f
	local bellyY = torsoBottom + 3
	local bellyFront = t.Position.Z - depth / 2 - (-0.3 + 4 * f)
	local bellyZ = bellyFront + bellySize / 2
	set(partsByName.Belly, Vector3.new(t.Position.X, bellyY, bellyZ), Vector3.one * bellySize)

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
		set(bead, Vector3.new(o.Position.X, o.Position.Y, front - gap), o.Size)
	end

	local head = partsByName.Head
	if head then
		local center = originals[head].Position
		grow("RightCheek", center, Vector3.new(5.0, -1.4, -3.4), 4.6 + 1.6 * f, 2 + 2.8 * f)
		grow("LeftCheek", center, Vector3.new(-5.0, -1.4, -3.4), 4.6 + 1.6 * f, 2 + 2.8 * f)
		grow("Chin", center, Vector3.new(0, -0.93, -0.37), 4.0 + 2.2 * f, 3 + 3.0 * f)
	end
end

function StatueShape.Apply(progress: number, seconds: number)
	local p = math.clamp(progress, 0, 1)
	local s = scaleFor(p)
	local targets: { [BasePart]: Target } = {}
	fatten(fatnessFor(p), targets)

	local info = TweenInfo.new(math.max(seconds, 0), Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	for _, part in bodyParts do
		local o = originals[part]
		local target = targets[part] or o
		local goal = {
			CFrame = CFrame.new(pivot + (target.Position - pivot) * s) * o.Rotation,
			Size = target.Size * s,
		}
		if seconds <= 0 then
			part.CFrame = goal.CFrame
			part.Size = goal.Size
		else
			TweenService:Create(part, info, goal):Play()
		end
	end
end

function StatueShape.SetHidden(hidden: boolean)
	for _, part in bodyParts do
		if hidden then
			PlotVisibility.Hide(part)
		else
			PlotVisibility.Show(part)
		end
	end
end

return StatueShape
