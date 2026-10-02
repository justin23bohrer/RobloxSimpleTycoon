-- BackyardGate (server only)
-- Locks each plot's backyard until the plot's owner owns enough Caleb
-- Trophies. It reads ownership (TycoonService) and trophies
-- (TrophyInventory); it changes neither.
--
-- * A plot's backyard is LOCKED unless the plot has an owner who owns at
--   least Config.BackyardTrophies trophies (inventory count, equipped or
--   not, session/dev trophies included). Unclaimed plots are locked. Once
--   open, anyone may walk in (like the house).
-- * The look (door closed/swung open, the "x/5 Caleb Trophies" sign) is
--   BackyardDoor. Updated on claim/release (the plot's OwnerUserId
--   attribute), DataService.TrophiesChanged, and the owner's
--   TrophyInventory attribute (TrophyService republishes it on data load,
--   dev trophies, and session-only claims).
-- * Enforcement: every Config.BackyardCheckInterval seconds, any character
--   whose HumanoidRootPart is inside a LOCKED plot's BackyardZone (checked
--   in the zone's object space, so turned plots work) is put back just
--   inside the house: Config.BackyardPushOutDistance past the zone's
--   house-side face (the face nearest the plot's Base), in front of the
--   back door, upright and facing into the house. Jump powers can clear
--   the fence; this still catches them. Works while the BackDoor is hidden
--   (Walls not built).
-- * A plot without a BackyardZone (map not merged yet) is skipped with one
--   warning; one without the BackDoor parts still enforces the zone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local BackyardDoor = require(script.Parent.BackyardDoor)
local DataService = require(script.Parent.DataService)
local TrophyInventory = require(script.Parent.TrophyInventory)
local TycoonService = require(script.Parent.TycoonService)

local BackyardGate = {}

type Gate = {
	Plot: Model,
	Zone: BasePart,
	Door: BackyardDoor.Door?,
	Locked: boolean,
	-- The zone's house-side face in its object space: axis "X" or "Z" and
	-- the side (+1/-1) it is on.
	HouseAxis: string,
	HouseSide: number,
}

local gates: { [Model]: Gate } = {}
local started = false

-- Re-reads the plot's owner and their trophy count; updates lock + look.
local function refresh(gate: Gate)
	local owner = TycoonService.GetPlotOwner(gate.Plot)
	local owned = if owner then #TrophyInventory.GetOwned(owner) else nil
	gate.Locked = owned == nil or owned < Config.BackyardTrophies
	if gate.Door then
		BackyardDoor.Show(gate.Door, gate.Locked, owned, Config.BackyardTrophies)
	end
end

local function refreshPlayer(player: Player)
	local tycoon = TycoonService.GetTycoon(player)
	local gate = tycoon and gates[tycoon.Plot]
	if gate then
		refresh(gate)
	end
end

-- A vector's X or Z, or a vector along X or Z.
local function along(v: Vector3, axis: string): number
	return if axis == "X" then v.X else v.Z
end
local function onAxis(axis: string, value: number, y: number, other: number): Vector3
	return if axis == "X" then Vector3.new(value, y, other) else Vector3.new(other, y, value)
end

-- Where to put a character found inside a locked backyard: just past the
-- house-side face, in front of the door (or level with them if the plot
-- has no door), standing upright and facing into the house.
local function pushOutCFrame(gate: Gate, insideLocal: Vector3): CFrame
	local zone = gate.Zone
	local half = zone.Size / 2
	local sideAxis = if gate.HouseAxis == "X" then "Z" else "X"
	local side = along(insideLocal, sideAxis)
	if gate.Door then
		side = along(zone.CFrame:PointToObjectSpace(gate.Door.Position), sideAxis)
	end
	local limit = math.max(0, along(half, sideAxis) - 2)
	side = math.clamp(side, -limit, limit)
	local out = gate.HouseSide * (along(half, gate.HouseAxis) + Config.BackyardPushOutDistance)
	local y = -half.Y + Config.BackyardPushOutHeight
	local position = zone.CFrame:PointToWorldSpace(onAxis(gate.HouseAxis, out, y, side))
	local inward = zone.CFrame:VectorToWorldSpace(onAxis(gate.HouseAxis, gate.HouseSide, 0, 0))
	local facing = Vector3.new(inward.X, 0, inward.Z).Unit
	return CFrame.lookAt(position, position + facing)
end

local function isInside(zone: BasePart, point: Vector3): (boolean, Vector3)
	local p = zone.CFrame:PointToObjectSpace(point)
	local half = zone.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z, p
end

local function enforce()
	for _, gate in gates do
		if gate.Locked then
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local inside, localPoint = isInside(gate.Zone, root.Position)
					if inside then
						(character :: Model):PivotTo(pushOutCFrame(gate, localPoint))
						root.AssemblyLinearVelocity = Vector3.zero
					end
				end
			end
		end
	end
end

local function setupPlot(plot: Model)
	local zone = plot:FindFirstChild("BackyardZone")
	local base = plot:FindFirstChild("Base")
	if not (zone and zone:IsA("BasePart") and base and base:IsA("BasePart")) then
		warn(`BackyardGate: {plot.Name} has no BackyardZone part; its backyard is not locked`)
		return
	end
	local door, missing = BackyardDoor.Find(plot, base.Position)
	if #missing > 0 then
		warn(`BackyardGate: {plot.Name} has no {table.concat(missing, ", ")}; the backyard is still locked, without a door/sign`)
	end

	-- The house-side face: the one the Base center is furthest out toward.
	local baseLocal = zone.CFrame:PointToObjectSpace(base.Position)
	local half = zone.Size / 2
	local axis = if math.abs(baseLocal.X) / half.X > math.abs(baseLocal.Z) / half.Z then "X" else "Z"
	local gate: Gate = {
		Plot = plot,
		Zone = zone,
		Door = door,
		Locked = true,
		HouseAxis = axis,
		HouseSide = if along(baseLocal, axis) >= 0 then 1 else -1,
	}
	gates[plot] = gate
	refresh(gate)
	plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		refresh(gate) -- claimed or released
	end)
end

local function onPlayerAdded(player: Player)
	player:GetAttributeChangedSignal(TrophyInventory.ATTRIBUTE):Connect(function()
		refreshPlayer(player)
	end)
end

-- Called once by ServerMain after TycoonService.Start.
function BackyardGate.Start()
	if started then
		return
	end
	started = true
	for _, plot in Workspace:WaitForChild("Map"):WaitForChild("Plots"):GetChildren() do
		if plot:IsA("Model") then
			setupPlot(plot)
		end
	end
	DataService.TrophiesChanged:Connect(refreshPlayer)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	task.spawn(function()
		while true do
			task.wait(Config.BackyardCheckInterval)
			local ok, err = pcall(enforce)
			if not ok then
				warn(`BackyardGate: check failed: {err}`)
			end
		end
	end)
end

return BackyardGate
