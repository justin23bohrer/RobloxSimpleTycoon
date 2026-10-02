-- CarService (server only)
-- The drivable garage car. Decides when each plot's car exists and when it
-- is put back in its garage. CarBuild builds it; CarSeats runs its seats,
-- prompts and wheels.
--
-- * A plot's car exists while its Garage trophy build is built and the plot
--   has an owner: it is spawned on TycoonService.PurchaseApplied for the
--   trophy build whose Parts include "GarageCar" (bought or restored), and
--   removed when the plot's OwnerUserId changes (owner left, plot reset;
--   PlotStages hides the Garage then too).
-- * The car is a copy of the plot's GarageCar look, taken the first time a
--   car spawns (the look has just been shown), parked exactly where
--   GarageCar stands, so turned plots work. The anchored GarageCar is hidden
--   (PlotVisibility) while the drivable car exists; PlotStages shows it
--   again with the Garage on the next purchase/restore.
-- * Every Config.CarCheckInterval: a car below Config.CarFallY, or past the
--   Ground's edge and falling faster than Config.CarFallSpeed, is re-parked
--   in its garage and the people in it respawn (LoadCharacter, then onto the
--   spawn in front of their own plot if they own one). A car lying on its
--   side or roof, nearly still, for Config.CarFlippedSeconds, or one whose
--   parts were destroyed, is re-parked (nobody respawns).
-- * Cars live in Workspace.Cars (made by Start), named "<Plot>Car".
-- Changes no cash and no plot ownership.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local CarBuild = require(script.Parent.CarBuild)
local CarSeats = require(script.Parent.CarSeats)
local PlotVisibility = require(script.Parent.PlotVisibility)
local TycoonService = require(script.Parent.TycoonService)

local CarService = {}

local LOOK = "GarageCar"
local FLIPPED_UP = 0.3 -- the car's up vector Y below this = on its side/roof
local STILL_SPEED = 2 -- studs/s

type Slot = {
	Plot: Model,
	Template: Model?, -- a copy of the visible GarageCar look
	Car: CarBuild.Car?,
	Owner: Player?, -- whose car it is
	FlippedFor: number,
	Warned: boolean,
}

local slots: { [Model]: Slot } = {}
local carsFolder: Folder? = nil
local ground: BasePart? = nil
local started = false

-- The trophy build that shows the GarageCar (the "Garage").
local garageId: string? = nil
for _, entry in Config.TrophyBuilds do
	if table.find(entry.Parts, LOOK) then
		garageId = entry.Id
	end
end

local function removeCar(slot: Slot)
	local car = slot.Car
	slot.Car = nil
	slot.Owner = nil
	slot.FlippedFor = 0
	if car then
		car.Model:Destroy()
	end
end

local function spawnCar(slot: Slot)
	local owner = TycoonService.GetPlotOwner(slot.Plot)
	local look = slot.Plot:FindFirstChild(LOOK)
	if slot.Car or not owner or not (look and look:IsA("Model")) or not carsFolder then
		return
	end
	if not slot.Template then
		slot.Template = look:Clone()
	end
	local car = CarBuild.Build(slot.Template :: Model)
	if not car then
		if not slot.Warned then
			slot.Warned = true
			warn(`CarService: {slot.Plot.Name}'s {LOOK} has no Body or Tire parts; its car stays parked`)
		end
		return
	end
	PlotVisibility.Hide(look)
	car.Model.Name = `{slot.Plot.Name}Car`
	car.Model:SetAttribute("PlotId", slot.Plot:GetAttribute("PlotId"))
	car.Model.Parent = carsFolder
	slot.Car = car
	slot.Owner = owner
	slot.FlippedFor = 0
	CarSeats.Setup(car, owner)
end

-- PlotN's spawn: SpawnLocation for Plot 1, SpawnLocationN for the others.
local function spawnPartOf(plot: Model): BasePart?
	local id = plot:GetAttribute("PlotId")
	local name = if id == 1 then "SpawnLocation" else `SpawnLocation{id}`
	local map = Workspace:FindFirstChild("Map")
	local part = map and map:FindFirstChild(name)
	return if part and part:IsA("BasePart") then part else nil
end

local function respawn(player: Player)
	local tycoon = TycoonService.GetTycoon(player)
	local spawnPart = tycoon and spawnPartOf(tycoon.Plot)
	if spawnPart then
		player.CharacterAdded:Once(function(character)
			task.wait() -- after Roblox placed it on a spawn
			if character.Parent then
				character:PivotTo(spawnPart.CFrame + Vector3.new(0, 4, 0))
			end
		end)
	end
	if player.Parent then
		pcall(player.LoadCharacter, player)
	end
end

local function repark(slot: Slot, respawnRiders: boolean)
	local car = slot.Car
	local riders = if car then CarSeats.Riders(car) else {}
	removeCar(slot)
	if respawnRiders then
		for _, player in riders do
			task.spawn(respawn, player)
		end
	end
	spawnCar(slot)
end

local function pastGroundEdge(position: Vector3): boolean
	if not ground then
		return false
	end
	local p = ground.CFrame:PointToObjectSpace(position)
	return math.abs(p.X) > ground.Size.X / 2 or math.abs(p.Z) > ground.Size.Z / 2
end

local function check(slot: Slot)
	local car = slot.Car
	if not car then
		return
	end
	local root = car.Root
	if not root:IsDescendantOf(Workspace) then
		repark(slot, false) -- destroyed (fell past FallenPartsDestroyHeight)
		return
	end
	local position = root.Position
	local velocity = root.AssemblyLinearVelocity
	if position.Y < Config.CarFallY or (pastGroundEdge(position) and velocity.Y < -Config.CarFallSpeed) then
		repark(slot, true) -- driven off the map
		return
	end
	if root.CFrame.UpVector.Y < FLIPPED_UP and velocity.Magnitude < STILL_SPEED then
		slot.FlippedFor += Config.CarCheckInterval
		if slot.FlippedFor >= Config.CarFlippedSeconds then
			repark(slot, false)
		end
	else
		slot.FlippedFor = 0
	end
end

-- Called once by ServerMain after TycoonService.Start.
function CarService.Start()
	if started then
		return
	end
	started = true
	if not garageId then
		warn(`CarService: no Config.TrophyBuilds entry shows {LOOK}; cars are off`)
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Cars"
	folder.Parent = Workspace
	carsFolder = folder
	local map = Workspace:WaitForChild("Map")
	local groundPart = map:FindFirstChild("Ground")
	ground = if groundPart and groundPart:IsA("BasePart") then groundPart else nil

	for _, plot in map:WaitForChild("Plots"):GetChildren() do
		if plot:IsA("Model") and plot:FindFirstChild(LOOK) then
			local slot: Slot = { Plot = plot, FlippedFor = 0, Warned = false }
			slots[plot] = slot
			plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
				if slot.Car and TycoonService.GetPlotOwner(plot) ~= slot.Owner then
					removeCar(slot) -- released (owner left / reset)
				end
			end)
		end
	end
	TycoonService.PurchaseApplied:Connect(function(_player: Player, plot: Model, purchaseId: string)
		local slot = slots[plot]
		if slot and purchaseId == garageId then
			spawnCar(slot)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.CarCheckInterval)
			for _, slot in slots do
				local ok, err = pcall(check, slot)
				if not ok then
					warn(`CarService: check failed for {slot.Plot.Name}: {err}`)
				end
			end
		end
	end)
end

return CarService
