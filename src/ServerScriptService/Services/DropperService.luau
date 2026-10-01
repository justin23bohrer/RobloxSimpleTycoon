-- DropperService (server only)
-- Runs droppers: creates physical drops on an interval and moves them along
-- the plot's conveyor toward its Collector.
--
-- * Start(plot, dropperId) places an upside-down red cup (DropperCup) named
--   dropperId at the plot's DropperSpotN (N = the dropper's position in
--   Config.Droppers); drops fall out of the cup's open end. It sets the
--   dropper's conveyor (its Config Conveyor, e.g. "Conveyor" or "Conveyor2")
--   moving toward that conveyor's collector (CollectorFor: "Collector",
--   "Collector2"),
--   and every Config.DropInterval seconds creates a "Drop" part worth that
--   dropper's Config DropValue in the plot's "Drops" folder. A drop looks like
--   a chocolate chip cookie: a flat disc with a few welded chip parts that
--   cannot touch anything, so only the disc itself reaches the Collector.
-- * Each drop's value and plot live only in server-side tables keyed by the
--   part. Nothing is read from the part or the client, so a client cannot
--   change a drop's value or move it to another plot.
-- * Trophy powers (PowerService) of the plot's OWNER (OwnerUserId attribute;
--   no owner in the server = no bonus) apply to every drop, read when the drop
--   is made so equip changes apply from the next drop:
--     value    = round(DropValue * (1 + CookieMultiplier)), and with
--                LuckyCookieChance it is worth Config.TrophyLuckyCookieMultiplier
--                times that (a "lucky" drop is gold-colored);
--     extra    = with ExtraCookieChance one more drop (same value rules, never
--                another extra) falls right under the first;
--     interval = Config.DropInterval / (1 + DropperSpeed), read every cycle.
-- * Drops are server-simulated (SetNetworkOwner(nil)) and destroyed after
--   Config.DropLifetime seconds.
-- * CollectorService calls ClaimDrop(drop, plot) to take a drop's value. A
--   drop can only be claimed once, and only by its own plot.
-- * Stop(plot, dropperId) stops one dropper; its drops already on the conveyor
--   keep going. StopAll(plot) stops every dropper on the plot and removes the
--   drops and the conveyor movement. A conveyor moves while any of its
--   droppers runs.
--   Both are safe to call if nothing is running.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TrophyPowers = require(ReplicatedStorage.Shared.TrophyPowers)
local DropperCup = require(script.Parent.DropperCup)
local PowerService = require(script.Parent.PowerService)

local DropperService = {}

-- Looks only; not gameplay tuning.
-- A Cylinder's round faces are on its X axis, so X is the cookie's thickness
-- and FLAT turns it to lie flat (X pointing up).
local COOKIE_THICKNESS = 0.4
local DROP_SIZE = Vector3.new(COOKIE_THICKNESS, 1.4, 1.4)
local FLAT = CFrame.Angles(0, 0, math.pi / 2)
local DROP_COLOR = Color3.fromRGB(214, 160, 90) -- golden-brown dough
local LUCKY_DROP_COLOR = Color3.fromRGB(255, 205, 40) -- gold: a lucky drop
local CHIP_COLOR = Color3.fromRGB(70, 40, 20) -- chocolate
local CHIP_SIZE = Vector3.new(0.3, 0.3, 0.3)
-- Chip positions on the cookie's top face, in the disc's local Y/Z plane.
local CHIP_SPOTS = {
	Vector2.new(0.3, 0.2),
	Vector2.new(-0.3, 0.3),
	Vector2.new(0.05, -0.35),
	Vector2.new(-0.35, -0.15),
}
local DROP_GAP = 0.1 -- studs between the cup's rim and a new drop

type PlotRun = {
	Drops: Folder,
	Droppers: { [string]: Model }, -- dropperId -> placed dropper cup
	ConveyorOf: { [string]: string }, -- dropperId -> name of its conveyor
}

local Stat = TrophyPowers.Stat
local rng = Random.new()

local runningByPlot: { [Model]: PlotRun } = {}
local dropValues: { [BasePart]: number } = {}
local dropPlots: { [BasePart]: Model } = {}

-- The collector at the end of a conveyor: "Conveyor" -> "Collector",
-- "Conveyor2" -> "Collector2".
function DropperService.CollectorFor(conveyorName: string): string
	return (string.gsub(conveyorName, "^Conveyor", "Collector"))
end

-- Every collector name the droppers in Config use, without repeats.
function DropperService.CollectorNames(): { string }
	local names = {}
	for _, entry in Config.Droppers do
		local name = DropperService.CollectorFor(entry.Conveyor)
		if not table.find(names, name) then
			table.insert(names, name)
		end
	end
	return names
end

-- A conveyor carries drops toward its collector, whichever way the map lays
-- it out: flat (no Y) unit direction from the conveyor's center to the
-- collector's center.
local function conveyorDirection(plot: Model, conveyor: BasePart): Vector3
	local collector = plot:FindFirstChild(DropperService.CollectorFor(conveyor.Name))
	if not collector or not collector:IsA("BasePart") then
		return Vector3.xAxis
	end
	local offset = collector.Position - conveyor.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	return if flat.Magnitude > 0 then flat.Unit else Vector3.xAxis
end

local function setConveyorMoving(plot: Model, conveyorName: string, moving: boolean)
	local conveyor = plot:FindFirstChild(conveyorName)
	if conveyor and conveyor:IsA("BasePart") then
		conveyor.AssemblyLinearVelocity = if moving
			then conveyorDirection(plot, conveyor) * Config.ConveyorSpeed
			else Vector3.zero
	end
end

-- True if any dropper still running on the plot drops onto this conveyor.
local function usesConveyor(run: PlotRun, conveyorName: string): boolean
	for _, name in run.ConveyorOf do
		if name == conveyorName then
			return true
		end
	end
	return false
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

-- The plot owner's total bonus for a trophy stat (0 if the plot has no owner
-- in this server).
local function ownerPower(plot: Model, stat: string): number
	local ownerUserId = plot:GetAttribute("OwnerUserId")
	local owner = type(ownerUserId) == "number" and Players:GetPlayerByUserId(ownerUserId)
	return if owner then PowerService.Get(owner, stat) else 0
end

-- rim: the center of the cup's open end (see DropperCup.Build). below: how
-- many cookie heights under the usual spot (0, or 1 for an extra drop).
local function spawnDrop(plot: Model, run: PlotRun, rim: CFrame, value: number, lucky: boolean, below: number)
	local offsetY = COOKIE_THICKNESS / 2 + DROP_GAP + below * (COOKIE_THICKNESS + DROP_GAP)

	local drop = Instance.new("Part")
	drop.Name = "Drop"
	drop.Shape = Enum.PartType.Cylinder
	drop.Size = DROP_SIZE
	drop.Color = if lucky then LUCKY_DROP_COLOR else DROP_COLOR
	drop.Material = Enum.Material.SmoothPlastic
	drop.Anchored = false
	drop.CFrame = rim * CFrame.new(0, -offsetY, 0) * FLAT
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

-- One drop's value with the owner's powers, and whether it rolled lucky.
-- Server-side only; integers.
local function dropValueFor(plot: Model, baseValue: number): (number, boolean)
	local value = math.floor(baseValue * (1 + ownerPower(plot, Stat.CookieMultiplier)) + 0.5)
	local lucky = rng:NextNumber() < ownerPower(plot, Stat.LuckyCookieChance)
	if lucky then
		value *= Config.TrophyLuckyCookieMultiplier
	end
	return value, lucky
end

-- Makes one dropper cycle's drops: one, plus maybe one extra (never more).
local function produce(plot: Model, run: PlotRun, rim: CFrame, baseValue: number)
	local value, lucky = dropValueFor(plot, baseValue)
	spawnDrop(plot, run, rim, value, lucky, 0)
	if rng:NextNumber() < ownerPower(plot, Stat.ExtraCookieChance) then
		local extraValue, extraLucky = dropValueFor(plot, baseValue)
		spawnDrop(plot, run, rim, extraValue, extraLucky, 1)
	end
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
	if not spot or not plot:FindFirstChild(entry.Conveyor) then
		warn(`DropperService: {plot.Name} is missing DropperSpot{index} or {entry.Conveyor}`)
		return
	end

	if not run then
		local drops = Instance.new("Folder")
		drops.Name = "Drops"
		drops.Parent = plot
		run = { Drops = drops, Droppers = {}, ConveyorOf = {} }
		runningByPlot[plot] = run
	end
	local plotRun = run :: PlotRun

	local dropper, rim = DropperCup.Build(spot, dropperId) -- named "Dropper1", "Dropper2", ...
	dropper.Parent = plot
	plotRun.Droppers[dropperId] = dropper
	plotRun.ConveyorOf[dropperId] = entry.Conveyor

	setConveyorMoving(plot, entry.Conveyor, true)

	local value = entry.DropValue
	task.spawn(function()
		while true do
			-- Read every cycle so a DropperSpeed change applies from the next drop.
			task.wait(Config.DropInterval / (1 + ownerPower(plot, Stat.DropperSpeed)))
			-- Stop/StopAll (or a stop then Start) replaces these entries; end this loop.
			if runningByPlot[plot] ~= plotRun or plotRun.Droppers[dropperId] ~= dropper then
				return
			end
			produce(plot, plotRun, rim, value)
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
	for _, conveyorName in run.ConveyorOf do
		setConveyorMoving(plot, conveyorName, false)
	end
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
	local conveyorName = run.ConveyorOf[dropperId]
	run.ConveyorOf[dropperId] = nil

	if next(run.Droppers) == nil then
		-- StopAll no longer knows this conveyor, so stop it here first.
		setConveyorMoving(plot, conveyorName, false)
		DropperService.StopAll(plot)
	elseif not usesConveyor(run, conveyorName) then
		setConveyorMoving(plot, conveyorName, false) -- none of its droppers left
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
