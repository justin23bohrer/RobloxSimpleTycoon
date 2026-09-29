-- DropperService (server only)
-- Runs droppers: creates physical drops on an interval and moves them along
-- the plot's conveyor toward its Collector.
--
-- * Start(plot) places a plain "Dropper" part at plot.DropperSpot, sets the
--   conveyor moving toward +X (plots are unrotated; the Collector is at +X),
--   and every Config.DropInterval seconds creates a "Drop" part in the plot's
--   "Drops" folder.
-- * Each drop's value and plot live only in server-side tables keyed by the
--   part. Nothing is read from the part or the client, so a client cannot
--   change a drop's value or move it to another plot.
-- * Drops are server-simulated (SetNetworkOwner(nil)) and destroyed after
--   Config.DropLifetime seconds.
-- * CollectorService calls ClaimDrop(drop, plot) to take a drop's value. A
--   drop can only be claimed once, and only by its own plot.
-- * Stop(plot) stops the loop and removes the dropper, the drops, and the
--   conveyor movement. Safe to call if not running.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DropperService = {}

-- Looks only; not gameplay tuning.
local DROP_SIZE = Vector3.new(1, 1, 1)
local DROP_COLOR = Color3.fromRGB(245, 205, 48)
local DROPPER_COLOR = Color3.fromRGB(120, 120, 120)
local DROP_GAP = 0.1 -- studs between the dropper's bottom and a new drop

type Running = {
	Dropper: BasePart,
	Drops: Folder,
}

local runningByPlot: { [Model]: Running } = {}
local dropValues: { [BasePart]: number } = {}
local dropPlots: { [BasePart]: Model } = {}

local function forgetDrop(drop: BasePart)
	dropValues[drop] = nil
	dropPlots[drop] = nil
end

local function spawnDrop(plot: Model, running: Running)
	local dropper = running.Dropper
	local offsetY = dropper.Size.Y / 2 + DROP_SIZE.Y / 2 + DROP_GAP

	local drop = Instance.new("Part")
	drop.Name = "Drop"
	drop.Size = DROP_SIZE
	drop.Color = DROP_COLOR
	drop.Anchored = false
	drop.CFrame = dropper.CFrame * CFrame.new(0, -offsetY, 0)

	dropValues[drop] = Config.DropValue
	dropPlots[drop] = plot
	-- Covers every way a drop can disappear (lifetime, claim, Stop, falling
	-- out of the world).
	drop.Destroying:Connect(function()
		forgetDrop(drop)
	end)

	drop.Parent = running.Drops
	drop:SetNetworkOwner(nil)

	task.delay(Config.DropLifetime, function()
		if dropValues[drop] then
			forgetDrop(drop)
			drop:Destroy()
		end
	end)
end

-- Starts the dropper on a plot. Does nothing if it is already running.
function DropperService.Start(plot: Model)
	if runningByPlot[plot] then
		return
	end

	local spot = plot:FindFirstChild("DropperSpot") :: BasePart?
	local conveyor = plot:FindFirstChild("Conveyor") :: BasePart?
	if not spot or not conveyor then
		warn(`DropperService: {plot.Name} is missing DropperSpot or Conveyor`)
		return
	end

	local dropper = Instance.new("Part")
	dropper.Name = "Dropper"
	dropper.Size = spot.Size
	dropper.CFrame = spot.CFrame
	dropper.Color = DROPPER_COLOR
	dropper.Anchored = true
	dropper.Parent = plot

	local drops = Instance.new("Folder")
	drops.Name = "Drops"
	drops.Parent = plot

	local running: Running = { Dropper = dropper, Drops = drops }
	runningByPlot[plot] = running

	conveyor.AssemblyLinearVelocity = Vector3.new(Config.ConveyorSpeed, 0, 0)

	task.spawn(function()
		while true do
			task.wait(Config.DropInterval)
			-- Stop (or a Stop then Start) replaces this entry; end this loop.
			if runningByPlot[plot] ~= running then
				return
			end
			spawnDrop(plot, running)
		end
	end)
end

-- Stops the dropper on a plot and removes its drops. Safe to call if not running.
function DropperService.Stop(plot: Model)
	local running = runningByPlot[plot]
	if not running then
		return
	end
	runningByPlot[plot] = nil

	for drop, dropPlot in dropPlots do
		if dropPlot == plot then
			forgetDrop(drop)
		end
	end
	running.Drops:Destroy()
	running.Dropper:Destroy()

	local conveyor = plot:FindFirstChild("Conveyor")
	if conveyor and conveyor:IsA("BasePart") then
		conveyor.AssemblyLinearVelocity = Vector3.zero
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
