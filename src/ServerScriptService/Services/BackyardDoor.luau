-- BackyardDoor (server only)
-- Helper for BackyardGate: the look of one plot's back door (the BackDoor
-- model, shown with the Walls build). Presentation only; BackyardGate
-- decides whether the backyard is locked.
--
-- * Locked: the Door (and its child parts: window, knob, panels) stands
--   closed in the back wall, exactly as the map built it.
-- * Open: the Door swings 90 degrees on its hinge edge, out into the
--   backyard, so the doorway is free. Only CFrames change: Transparency and
--   CanCollide stay with PlotVisibility (the BackDoor is hidden until the
--   Walls are built), so the two never fight.
-- * DoorSign (facing into the house): its TextLabel says "🔒 Unlock this
--   door once you have 5 Caleb Trophies" (the number from Config, "Caleb
--   Trophy" if it is 1), and its smaller ProgressLabel the owner's gold
--   "🏆 x/5" (empty on an unclaimed plot). Open: "BACKYARD OPEN!" and no
--   progress. A sign without a ProgressLabel shows the progress on the
--   TextLabel's second line instead.

local BackyardDoor = {}

local TROPHY_COLOR = "#FFC83D" -- trophy gold, like the trophy buy buttons

export type Door = {
	Parts: { BasePart }, -- the Door and every BasePart inside it
	Closed: { CFrame }, -- each part's CFrame as the map built it
	Swing: CFrame, -- world transform from closed to open
	Position: Vector3, -- the closed Door's center
	Labels: { TextLabel }, -- the main text (every TextLabel but ProgressLabel)
	Progress: TextLabel?, -- the small "🏆 x/5" line
}

-- The Door's widest horizontal axis (its width) and that size.
local function widthAxis(door: BasePart): (Vector3, number)
	local axes = {
		{ door.CFrame.RightVector, door.Size.X },
		{ door.CFrame.UpVector, door.Size.Y },
		{ door.CFrame.LookVector, door.Size.Z },
	}
	-- Drop the axis closest to vertical (the door's height).
	table.sort(axes, function(a, b)
		return math.abs(a[1].Y) < math.abs(b[1].Y)
	end)
	local first, second = axes[1], axes[2]
	local best = if first[2] >= second[2] then first else second
	return Vector3.new(best[1].X, 0, best[1].Z).Unit, best[2]
end

-- Rotation by `angle` around the vertical line through `hinge`.
local function swingAround(hinge: Vector3, angle: number): CFrame
	return CFrame.new(hinge) * CFrame.Angles(0, angle, 0) * CFrame.new(-hinge)
end

-- Finds the plot's BackDoor parts. Returns nil and a list of the missing
-- names if the BackDoor, Door, or DoorSign is not there. `houseCenter` is
-- where the house is (the plot's Base), so the door swings away from it.
function BackyardDoor.Find(plot: Model, houseCenter: Vector3): (Door?, { string })
	local backDoor = plot:FindFirstChild("BackDoor")
	if not backDoor then
		return nil, { "BackDoor" }
	end
	local door = backDoor:FindFirstChild("Door", true)
	local sign = backDoor:FindFirstChild("DoorSign", true)
	local missing = {}
	if not (door and door:IsA("BasePart")) then
		table.insert(missing, "BackDoor.Door")
	end
	if not sign then
		table.insert(missing, "BackDoor.DoorSign")
	end
	if #missing > 0 then
		return nil, missing
	end
	local doorPart = door :: BasePart

	local parts, closed = { doorPart }, { doorPart.CFrame }
	for _, item in doorPart:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(parts, item)
			table.insert(closed, item.CFrame)
		end
	end

	-- Hinge on one end of the door's width; swing whichever way moves the
	-- door's center away from the house (into the backyard).
	local axis, width = widthAxis(doorPart)
	local hinge = doorPart.Position + axis * (width / 2)
	local swing = swingAround(hinge, math.pi / 2)
	local other = swingAround(hinge, -math.pi / 2)
	local function flatDistance(point: Vector3): number
		return Vector3.new(point.X - houseCenter.X, 0, point.Z - houseCenter.Z).Magnitude
	end
	if flatDistance(other * doorPart.Position) > flatDistance(swing * doorPart.Position) then
		swing = other
	end

	local labels, progress = {}, nil
	for _, item in (sign :: Instance):GetDescendants() do
		if item:IsA("TextLabel") then
			if item.Name == "ProgressLabel" then
				progress = item
			else
				table.insert(labels, item)
			end
		end
	end

	return {
		Parts = parts,
		Closed = closed,
		Swing = swing,
		Position = doorPart.Position,
		Labels = labels,
		Progress = progress,
	}, {}
end

-- Shows the door closed or open, and the sign. `owned` = the owner's Caleb
-- Trophy count (nil = unclaimed plot); `needed` = Config.BackyardTrophies.
function BackyardDoor.Show(door: Door, locked: boolean, owned: number?, needed: number)
	for i, part in door.Parts do
		part.CFrame = if locked then door.Closed[i] else door.Swing * door.Closed[i]
	end
	local text, progress = "BACKYARD OPEN!", ""
	if locked then
		local noun = if needed == 1 then "Caleb Trophy" else "Caleb Trophies"
		text = `🔒 Unlock this door once you have {needed} {noun}`
		if owned then
			progress = `<font color="{TROPHY_COLOR}">🏆 {owned}/{needed}</font>`
		end
	end
	if door.Progress then
		door.Progress.RichText = true
		door.Progress.Text = progress
		door.Progress.Visible = progress ~= ""
	elseif progress ~= "" then
		text = `{text}\n{progress}`
	end
	for _, label in door.Labels do
		label.RichText = true
		label.Text = text
	end
end

return BackyardDoor
