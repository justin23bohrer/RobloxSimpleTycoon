-- TheftCarry (server only)
-- Helper for TheftService: the thief's side of a theft. Decides nothing.
--
-- * Attach(character, variantId) builds the stolen trophy (TrophyModel) and
--   welds it above the thief's head as HouseRaid.CarriedModelName inside the
--   character, so every player sees it. Every part is unanchored, Massless,
--   and has CanCollide/CanTouch/CanQuery off, so it never changes how the
--   character moves or blocks anything. Detach(model) removes it.
-- * FindStash(plot) finds the plot's HouseRaid.Part.TrophyStash (a part, or a
--   model of parts, anywhere in the plot; made by the Security worker's map
--   change) and says whether it is shown (the map hides it, Transparency 1,
--   until the house is built). IsOnStash(stash, rootPosition) is true while
--   the thief's HumanoidRootPart stands on (or just above) it.
-- * NewTracker / MovedTooFast: the anti-teleport check. Average horizontal
--   speed over the last SPEED_WINDOW seconds above `maxSpeed`, or one step
--   longer than a whole second of `maxSpeed`, counts as too fast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HouseRaid = require(ReplicatedStorage.Shared.HouseRaid)
local TrophyModel = require(script.Parent.TrophyModel)

local TheftCarry = {}

-- Looks and tolerances, not gameplay tuning.
local CARRY_SCALE = 1 -- the carried trophy's size (TrophyModel scale)
local HEAD_GAP = 0.4 -- studs between the top of the head and the plinth
local STASH_MARGIN = 0.5 -- studs around the stash's footprint that still count
local STASH_HEIGHT = 7 -- the root may be this far above the stash's top (a standing player's root is ~3)
local SPEED_WINDOW = 0.5 -- seconds the average speed is taken over
local FLAT = Vector3.new(1, 0, 1)

export type Tracker = { { Time: number, Position: Vector3 } }

-- Welds a trophy of this variant above the character's head. Returns the
-- model, or nil if the character has no HumanoidRootPart.
function TheftCarry.Attach(character: Model, variantId: string): Model?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	local head = character:FindFirstChild("Head")
	local top = if head and head:IsA("BasePart") then head.Position.Y + head.Size.Y / 2 else root.Position.Y + 2.5

	local model = TrophyModel.Build(variantId, CARRY_SCALE)
	model.Name = HouseRaid.CarriedModelName
	-- Same facing as the character; welded to the root (steadier than the head).
	model:PivotTo(root.CFrame * CFrame.new(0, top - root.Position.Y + HEAD_GAP, 0))
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = false -- an anchored part would freeze the thief
			item.Massless = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = item
			weld.Parent = item
		end
	end
	model.Parent = character
	return model
end

-- Removes a carried trophy (its welds go with it).
function TheftCarry.Detach(model: Model?)
	if model then
		model:Destroy()
	end
end

-- The plot's TrophyStash (or nil if the map has none) and whether it is shown.
function TheftCarry.FindStash(plot: Instance): (Instance?, boolean)
	local stash = plot:FindFirstChild(HouseRaid.Part.TrophyStash, true)
	if not stash then
		return nil, false
	end
	return stash, TheftCarry.IsShown(stash)
end

-- True if any part of the stash is visible (not hidden by PlotVisibility).
function TheftCarry.IsShown(stash: Instance): boolean
	if stash:IsA("BasePart") then
		return stash.Transparency < 1
	end
	for _, item in stash:GetDescendants() do
		if item:IsA("BasePart") and item.Transparency < 1 then
			return true
		end
	end
	return false
end

-- True if a HumanoidRootPart at `position` stands on the stash. Uses the
-- stash's box in world axes, so a pad turned any way (e.g. a round Cylinder
-- lying flat) works.
function TheftCarry.IsOnStash(stash: Instance, position: Vector3): boolean
	local cframe, size
	if stash:IsA("BasePart") then
		cframe, size = stash.CFrame, stash.Size
	elseif stash:IsA("Model") then
		cframe, size = stash:GetBoundingBox()
	else
		return false
	end
	local half = size / 2
	local right, up, look = cframe.RightVector, cframe.UpVector, cframe.LookVector
	local extentX = math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z
	local extentY = math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z
	local extentZ = math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z
	local offset = position - cframe.Position
	return math.abs(offset.X) <= extentX + STASH_MARGIN
		and math.abs(offset.Z) <= extentZ + STASH_MARGIN
		and offset.Y >= -extentY
		and offset.Y <= extentY + STASH_HEIGHT
end

function TheftCarry.NewTracker(position: Vector3, now: number): Tracker
	return { { Time = now, Position = position } }
end

-- Records the root's position; true if the thief moved faster than
-- `maxSpeed` studs/s horizontally (averaged), or jumped more than one
-- second's worth of it in a single step (a teleport).
function TheftCarry.MovedTooFast(tracker: Tracker, position: Vector3, now: number, maxSpeed: number): boolean
	local last = tracker[#tracker]
	if ((position - last.Position) * FLAT).Magnitude > maxSpeed then
		return true
	end
	table.insert(tracker, { Time = now, Position = position })
	-- Keep exactly one sample at least SPEED_WINDOW old as the start.
	while #tracker > 2 and now - tracker[2].Time >= SPEED_WINDOW do
		table.remove(tracker, 1)
	end
	local first = tracker[1]
	local span = now - first.Time
	return span >= SPEED_WINDOW and ((position - first.Position) * FLAT).Magnitude / span > maxSpeed
end

return TheftCarry
