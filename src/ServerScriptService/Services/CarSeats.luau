-- CarSeats (server only)
-- Helper for CarService: getting in and out of a car, and driving it.
--
-- * Prompts: "Drive" (E) on the DriverSeat works only for the plot's owner;
--   "Ride" (F) on the PassengerSeat works for anyone. The seats can't be
--   touched, so the prompts are the only way in. A prompt hides while its
--   seat is taken.
-- * Anyone but the owner found in the DriverSeat is thrown out at once.
-- * Getting out (jump) puts the person standing beside their door.
-- * While the owner drives, the owner's client simulates the car (network
--   owner); otherwise the server does.
-- * The VehicleSeat's Throttle/Steer (sent by the driver's default Roblox
--   controls) set the wheel motors and the front wheels' steering.
-- Changes no cash and no plot ownership.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CarBuild = require(script.Parent.CarBuild)

local CarSeats = {}

local EXIT_SIDE = 6 -- studs from the car's middle to where a rider gets out
local EXIT_UP = 1 -- above the Body's center
local SIT_RANGE = 16 -- studs from the seat (prompts reach 10)

local function playerOf(humanoid: Humanoid?): Player?
	return if humanoid then Players:GetPlayerFromCharacter(humanoid.Parent) else nil
end

local function setPhysicsOwner(part: BasePart, player: Player?)
	if part:IsDescendantOf(workspace) then
		pcall(part.SetNetworkOwner, part, player)
	end
end

-- The driver simulates the car; with only a passenger, the passenger does
-- (their character is welded in); an empty car is the server's.
local function updatePhysicsOwner(car: CarBuild.Car)
	local riders = CarSeats.Riders(car)
	setPhysicsOwner(car.Root, riders[1])
end

-- Sets the wheel motors and steering from the driver's input.
local function drive(car: CarBuild.Car)
	local seat = car.DriverSeat
	local driving = seat.Occupant ~= nil
	local throttle = if driving then seat.Throttle else 0
	local steer = if driving then seat.Steer else 0
	local speed = if throttle > 0 then Config.CarMaxSpeed elseif throttle < 0 then -Config.CarReverseSpeed else 0
	for _, motor in car.Motors do
		-- Positive spin about the car's X axis rolls the car toward its nose.
		motor.AngularVelocity = speed / car.WheelRadius
		motor.MotorMaxTorque = if throttle ~= 0 then Config.CarTorque else Config.CarBrakeTorque
	end
	for _, steering in car.Steering do
		-- A positive angle turns the wheels toward the car's left (+X);
		-- Steer = 1 means turn right.
		steering.TargetAngle = -steer * Config.CarSteerAngle
	end
end

-- Stands a rider who just got out beside their door (side +1 = the car's
-- left), upright and facing the way the car points.
local function placeBeside(car: CarBuild.Car, humanoid: Humanoid, side: number)
	local character = humanoid.Parent
	local root = car.Root
	if not (character and character:IsA("Model") and character.Parent and humanoid.Health > 0) then
		return -- respawning or gone
	end
	if not root:IsDescendantOf(workspace) then
		return -- the car is being removed
	end
	local characterRoot = character:FindFirstChild("HumanoidRootPart")
	local player = playerOf(humanoid)
	if characterRoot and characterRoot:IsA("BasePart") and player then
		setPhysicsOwner(characterRoot, player) -- their own body again
	end
	local frame = root.CFrame
	local left = Vector3.new(frame.RightVector.X, 0, frame.RightVector.Z)
	local nose = Vector3.new(-frame.LookVector.X, 0, -frame.LookVector.Z)
	if left.Magnitude < 0.1 or nose.Magnitude < 0.1 then
		return -- car on its nose/tail; let them jump out normally
	end
	local position = root.Position + left.Unit * side * EXIT_SIDE + Vector3.new(0, EXIT_UP, 0)
	character:PivotTo(CFrame.lookAt(position, position + nose.Unit))
end

local function kickOut(seat: BasePart)
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
end

local function sitIn(seat: BasePart, player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart or (seat :: any).Occupant then
		return -- dead, already seated somewhere, or the seat is taken
	end
	local root = humanoid.RootPart
	if not root or (root.Position - seat.Position).Magnitude > SIT_RANGE then
		return -- never trust the prompt alone: must stand by the car
	end
	(seat :: any):Sit(humanoid)
end

local function addPrompt(seat: BasePart, action: string, objectText: string, key: Enum.KeyCode): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = key
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false -- the seat is inside the body
	prompt.Parent = seat
	return prompt
end

-- Calls onChange(occupant) when the seat's occupant changes, after
-- placing the previous rider beside the door.
local function watch(car: CarBuild.Car, seat: BasePart, side: number, onChange: (Humanoid?) -> ())
	local last: Humanoid? = nil
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local now: Humanoid? = (seat :: any).Occupant
		if last and last ~= now then
			placeBeside(car, last, side)
		end
		last = now
		onChange(now)
	end)
end

-- Wires a freshly parented car for its plot's owner. Every connection is on
-- the car's own instances, so it goes away with the car.
function CarSeats.Setup(car: CarBuild.Car, owner: Player)
	local driverSeat, passengerSeat = car.DriverSeat, car.PassengerSeat
	local drivePrompt = addPrompt(driverSeat, "Drive", `{owner.DisplayName}'s car`, Enum.KeyCode.E)
	local ridePrompt = addPrompt(passengerSeat, "Ride", `{owner.DisplayName}'s car`, Enum.KeyCode.F)
	ridePrompt.GamepadKeyCode = Enum.KeyCode.ButtonY

	drivePrompt.Triggered:Connect(function(player)
		if player == owner then
			sitIn(driverSeat, player)
		end
	end)
	ridePrompt.Triggered:Connect(function(player)
		sitIn(passengerSeat, player)
	end)

	watch(car, driverSeat, 1, function(occupant)
		local player = playerOf(occupant)
		if occupant and player ~= owner then
			kickOut(driverSeat) -- only the owner drives; fires again with nil
			return
		end
		drivePrompt.Enabled = occupant == nil
		updatePhysicsOwner(car)
		drive(car)
	end)
	watch(car, passengerSeat, -1, function(occupant)
		ridePrompt.Enabled = occupant == nil
		updatePhysicsOwner(car)
	end)
	driverSeat:GetPropertyChangedSignal("Throttle"):Connect(function()
		drive(car)
	end)
	driverSeat:GetPropertyChangedSignal("Steer"):Connect(function()
		drive(car)
	end)

	setPhysicsOwner(car.Root, nil)
	drive(car)
end

-- The players sitting in the car (driver and passenger).
function CarSeats.Riders(car: CarBuild.Car): { Player }
	local riders = {}
	for _, seat in { car.DriverSeat :: BasePart, car.PassengerSeat } do
		local player = playerOf((seat :: any).Occupant)
		if player then
			table.insert(riders, player)
		end
	end
	return riders
end

return CarSeats
