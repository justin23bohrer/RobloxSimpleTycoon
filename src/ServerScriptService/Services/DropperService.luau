-- DropperService (server only)
-- Runs droppers: creates physical drops on an interval and moves them along
-- the plot's conveyor toward its Collector.
--
-- * Start(plot, dropperId) places a plain part named dropperId at the plot's
--   DropperSpotN (N = the dropper's position in Config.Droppers), sets the
--   conveyor moving toward the plot's Collector,
--   and every Config.DropInterval seconds creates a "Drop" part worth that
--   dropper's Config DropValue in the plot's "Drops" folder. A drop looks like
--   a chocolate chip cookie: a flat disc with a few welded chip parts that
--   cannot touch anything, so only the disc itself reaches the Collector.
-- * Each drop's value and plot live only in server-side tables keyed by the
--   part. Nothing is read from the part or the client, so a client cannot
--   change a drop's value or move it to another plot.
-- * Drops are server-simulated (SetNetworkOwner(nil)) and destroyed after
--   Config.DropLifetime seconds.
-- * CollectorService calls ClaimDrop(drop, plot) to take a drop's value. A
--   drop can only be claimed once, and only by its own plot.
-- * Stop(plot, dropperId) stops one dropper; its drops already on the conveyor
--   keep going. StopAll(plot) stops every dropper on the plot and removes the
--   drops and the conveyor movement. The conveyor moves while any dropper runs.
--   Both are safe to call if nothing is running.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DropperService = {}

-- Looks only; not gameplay tuning.
-- A Cylinder's round faces are on its X axis, so X is the cookie's thickness
-- and FLAT turns it to lie flat (X pointing up).
local COOKIE_THICKNESS = 0.4
local DROP_SIZE = Vector3.new(COOKIE_THICKNESS, 1.4, 1.4)
local FLAT = CFrame.Angles(0, 0, math.pi / 2)
local DROP_COLOR = Color3.fromRGB(214, 160, 90) -- golden-brown dough
local CHIP_COLOR = Color3.fromRGB(70, 40, 20) -- chocolate
local CHIP_SIZE = Vector3.new(0.3, 0.3, 0.3)
-- Chip positions on the cookie's top face, in the disc's local Y/Z plane.
local CHIP_SPOTS = {
	Vector2.new(0.3, 0.2),
	Vector2.new(-0.3, 0.3),
	Vector2.new(0.05, -0.35),
	Vector2.new(-0.35, -0.15),
}
local DROPPER_COLOR = Color3.fromRGB(120, 120, 120)
local DROP_GAP = 0.1 -- studs between the dropper's bottom and a new drop

type PlotRun = {
	Drops: Folder,
	Droppers: { [string]: BasePart }, -- dropperId -> placed Dropper part
}

local runningByPlot: { [Model]: PlotRun } = {}
local dropValues: { [BasePart]: number } = {}
local dropPlots: { [BasePart]: Model } = {}


-- The conveyor carries drops toward the plot's Collector, whichever way the
-- map lays it out: flat (no Y) unit direction from the conveyor's center to
-- the Collector's center.
local function conveyorDirection(plot: Model, conveyor: BasePart): Vector3
	local collector = plot:FindFirstChild("Collector")
	if not collector or not collector:IsA("BasePart") then
		return Vector3.xAxis
	end
	local offset = collector.Position - conveyor.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	return if flat.Magnitude > 0 then flat.Unit else Vector3.xAxis
end

local function setConveyorMoving(plot: Model, moving: boolean)
	local conveyor = plot:FindFirstChild("Conveyor")
	if conveyor and conveyor:IsA("BasePart") then
		conveyor.AssemblyLinearVelocity = if moving
			then conveyorDirection(plot, conveyor) * Config.ConveyorSpeed
			else Vector3.zero
	end
end

local function forgetDrop(drop: BasePart)
	dropValues[drop] = nil
	dropPlots[drop] = nil
end

-- Chocolate chips welded on top of a cookie drop. Looks only: they cannot
-- touch, collide, or be found by raycasts, and add no mass.
local function addChips(drop: BasePart)
	for _, spot in CHIP_SPOTS do
		local chip = Instance.new("Part")
		chip.Name = "Chip"
		chip.Shape = Enum.PartType.Ball
		chip.Size = CHIP_SIZE
		chip.Color = CHIP_COLOR
		chip.Material = Enum.Material.SmoothPlastic
		chip.CanCollide = false
		chip.CanTouch = false
		chip.CanQuery = false
		chip.Massless = true
		chip.CFrame = drop.CFrame * CFrame.new(COOKIE_THICKNESS / 2, spot.X, spot.Y)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = drop
		weld.Part1 = chip
		weld.Parent = chip
		chip.Parent = drop
	end
end

local function spawnDrop(plot: Model, run: PlotRun, dropper: BasePart, value: number)
	local offsetY = dropper.Size.Y / 2 + COOKIE_THICKNESS / 2 + DROP_GAP

	local drop = Instance.new("Part")
	drop.Name = "Drop"
	drop.Shape = Enum.PartType.Cylinder
	drop.Size = DROP_SIZE
	drop.Color = DROP_COLOR
	drop.Material = Enum.Material.SmoothPlastic
	drop.Anchored = false
	drop.CFrame = dropper.CFrame * CFrame.new(0, -offsetY, 0) * FLAT
	addChips(drop)

	dropValues[drop] = value
	dropPlots[drop] = plot
	-- Covers every way a drop can disappear (lifetime, claim, StopAll, falling
	-- out of the world).
	drop.Destroying:Connect(function()
		forgetDrop(drop)
	end)

	drop.Parent = run.Drops
	drop:SetNetworkOwner(nil)

	task.delay(Config.DropLifetime, function()
		if dropValues[drop] then
			forgetDrop(drop)
			drop:Destroy()
		end
	end)
end

-- Returns a dropper's Config.Droppers entry and its position in the list, or
-- nil if the id is unknown.
function DropperService.GetConfig(dropperId: string): (any, number?)
	for index, entry in Config.Droppers do
		if entry.Id == dropperId then
			return entry, index
		end
	end
	return nil, nil
end

-- Starts one dropper on a plot. Does nothing if it is already running or the
-- id is not in Config.Droppers.
function DropperService.Start(plot: Model, dropperId: string)
	local entry, index = DropperService.GetConfig(dropperId)
	if not entry then
		warn(`DropperService: unknown dropper id '{dropperId}'`)
		return
	end
	local run = runningByPlot[plot]
	if run and run.Droppers[dropperId] then
		return
	end

	local spot = plot:FindFirstChild(`DropperSpot{index}`) :: BasePart?
	if not spot or not plot:FindFirstChild("Conveyor") then
		warn(`DropperService: {plot.Name} is missing DropperSpot{index} or Conveyor`)
		return
	end

	if not run then
		local drops = Instance.new("Folder")
		drops.Name = "Drops"
		drops.Parent = plot
		run = { Drops = drops, Droppers = {} }
		runningByPlot[plot] = run
	end
	local plotRun = run :: PlotRun

	local dropper = Instance.new("Part")
	dropper.Name = dropperId -- "Dropper1", "Dropper2", ...
	dropper.Size = spot.Size
	dropper.CFrame = spot.CFrame
	dropper.Color = DROPPER_COLOR
	dropper.Anchored = true
	dropper.Parent = plot
	plotRun.Droppers[dropperId] = dropper

	setConveyorMoving(plot, true)

	local value = entry.DropValue
	task.spawn(function()
		while true do
			task.wait(Config.DropInterval)
			-- Stop/StopAll (or a stop then Start) replaces these entries; end this loop.
			if runningByPlot[plot] ~= plotRun or plotRun.Droppers[dropperId] ~= dropper then
				return
			end
			spawnDrop(plot, plotRun, dropper, value)
		end
	end)
end

-- Stops every dropper on a plot and removes its drops. Safe to call if not running.
function DropperService.StopAll(plot: Model)
	local run = runningByPlot[plot]
	if not run then
		return
	end
	runningByPlot[plot] = nil

	for drop, dropPlot in dropPlots do
		if dropPlot == plot then
			forgetDrop(drop)
		end
	end
	run.Drops:Destroy()
	for _, dropper in run.Droppers do
		dropper:Destroy()
	end

	setConveyorMoving(plot, false)
end

-- Stops one dropper on a plot. Drops it already made stay on the conveyor.
-- If it was the last one running, behaves like StopAll. Safe to call if not running.
function DropperService.Stop(plot: Model, dropperId: string)
	local run = runningByPlot[plot]
	local dropper = run and run.Droppers[dropperId]
	if not run or not dropper then
		return
	end
	run.Droppers[dropperId] = nil
	dropper:Destroy()

	if next(run.Droppers) == nil then
		DropperService.StopAll(plot)
	end
end

-- Takes a live drop from this plot: removes and destroys it and returns its
-- value. Returns nil if the drop is not a live drop from this plot (unknown,
-- already claimed, expired, or from another plot).
function DropperService.ClaimDrop(drop: BasePart, plot: Model): number?
	local value = dropValues[drop]
	if value == nil or dropPlots[drop] ~= plot then
		return nil
	end

	forgetDrop(drop)
	drop:Destroy()
	return value
end

return DropperService
