-- CarSeats (server only)
-- Helper for CarService: getting in and out of a car, and driving it.
--
-- * Prompts: "Drive" (E) on the DriverSeat works only for the plot's owner;
--   "Ride" (F) on the PassengerSeat works for anyone. The seats can't be
--   touched, so the prompts are the only way in. A prompt hides while its
--   seat is taken.
-- * Anyone but the owner found in the DriverSeat is thrown out at once.
-- * Getting out (jump) puts the person standing beside their door, clear of
--   the car, on whatever ground is there (see placeBeside).
-- * While the owner drives, the owner's client simulates the car (network
--   owner); otherwise the server does.
-- * The VehicleSeat's Throttle/Steer (sent by the driver's default Roblox
--   controls) set the wheel motors and the front wheels' steering.
-- Changes no cash and no plot ownership.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local CarBuild = require(script.Parent.CarBuild)

local CarSeats = {}

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

-- The car's size in the Body's object space: every visible part, mirrors
-- and tires included. Center = the box's middle, Half = half its size.
type Box = { Center: Vector3, Half: Vector3 }

local function measure(car: CarBuild.Car): Box
	local toCar = car.Root.CFrame:Inverse()
	local lo, hi = -car.Root.Size / 2, car.Root.Size / 2
	for _, part in car.Model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local frame = toCar * part.CFrame
			local half = part.Size / 2
			local reach = (frame.RightVector * half.X):Abs()
				+ (frame.UpVector * half.Y):Abs()
				+ (frame.LookVector * half.Z):Abs()
			lo = lo:Min(frame.Position - reach)
			hi = hi:Max(frame.Position + reach)
		end
	end
	return { Center = (lo + hi) / 2, Half = (hi - lo) / 2 }
end

-- Height of a standing character's HumanoidRootPart center above its feet.
local function standHeight(humanoid: Humanoid, characterRoot: BasePart): number
	local legs = if humanoid.RigType == Enum.HumanoidRigType.R6 then 2 else humanoid.HipHeight
	return legs + characterRoot.Size.Y / 2
end

-- Where a rider getting out of `seat` stands (their HumanoidRootPart's
-- CFrame): beside the door (side +1 = the car's left), clear of the car,
-- on top of whatever is there, facing the way the car points. Nil if the
-- car lies on its nose/tail.
local function exitFrame(car: CarBuild.Car, box: Box, seat: BasePart, side: number, humanoid: Humanoid, characterRoot: BasePart): CFrame?
	local frame = car.Root.CFrame
	local nose = Vector3.new(-frame.LookVector.X, 0, -frame.LookVector.Z)
	if nose.Magnitude < 0.1 or Vector3.new(frame.RightVector.X, 0, frame.RightVector.Z).Magnitude < 0.1 then
		return nil
	end
	local x = box.Center.X + side * (box.Half.X + Config.CarExitClearance)
	local z = frame:PointToObjectSpace(seat.Position).Z
	-- Under the exit spot, level with the car's lowest point (its tires).
	local floor = frame:PointToWorldSpace(Vector3.new(x, box.Center.Y - box.Half.Y, z))
	local top = math.max(frame.Position.Y, floor.Y) + Config.CarExitRayUp
	local ignore: { Instance } = { car.Model }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true -- zones, water and seats aren't ground
	local start = Vector3.new(floor.X, top, floor.Z)
	local hit = workspace:Raycast(start, Vector3.new(0, floor.Y - top - Config.CarExitRayDown, 0), params)
	local ground = if hit then hit.Position.Y else floor.Y -- nothing below: level with the tires
	local position = Vector3.new(floor.X, ground + standHeight(humanoid, characterRoot) + Config.CarExitHeightMargin, floor.Z)
	return CFrame.lookAt(position, position + nose.Unit)
end

-- True if `point` is in or under the car's footprint (up to its roof).
local function underOrInCar(car: CarBuild.Car, box: Box, point: Vector3): boolean
	local p = car.Root.CFrame:PointToObjectSpace(point) - box.Center
	return math.abs(p.X) < box.Half.X and math.abs(p.Z) < box.Half.Z and p.Y < box.Half.Y
end

-- Stands a rider who just got out beside their door. Runs a frame after the
-- seat let go (the SeatWeld is gone everywhere by then), with the server
-- owning their body while it moves them so the client's mid-jump physics
-- can't undo it; then they own their body again. Checks once more after
-- Config.CarExitSettleTime. Does nothing if they sat down again, died, or
-- the car is gone.
local function placeBeside(car: CarBuild.Car, box: Box, seat: BasePart, humanoid: Humanoid, side: number, recheck: boolean)
	local character = humanoid.Parent
	if not (character and character:IsA("Model") and character.Parent and humanoid.Health > 0) then
		return -- respawning or gone
	end
	if humanoid.SeatPart or not car.Root:IsDescendantOf(workspace) then
		return -- seated again, or the car is being removed
	end
	local characterRoot = humanoid.RootPart
	local player = playerOf(humanoid)
	if not (characterRoot and player) then
		return
	end
	local target = exitFrame(car, box, seat, side, humanoid, characterRoot)
	if not target then
		return -- car on its nose/tail; let them jump out normally
	end
	local offset = characterRoot.Position - target.Position
	local sunk = Vector3.new(offset.X, 0, offset.Z).Magnitude < Config.CarExitClearance
		and offset.Y < -standHeight(humanoid, characterRoot) / 2 -- still at the exit spot, but in the ground
	if recheck and not sunk and not underOrInCar(car, box, characterRoot.Position) then
		return -- they landed fine
	end
	setPhysicsOwner(characterRoot, nil)
	characterRoot.AssemblyLinearVelocity = Vector3.zero
	characterRoot.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(target)
	setPhysicsOwner(characterRoot, player) -- their own body again, starting here
	if not recheck then
		task.delay(Config.CarExitSettleTime, placeBeside, car, box, seat, humanoid, side, true)
	end
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

-- Calls onChange(occupant) when the seat's occupant changes; the previous
-- rider is placed beside the door on the next frame.
local function watch(car: CarBuild.Car, box: Box, seat: BasePart, side: number, onChange: (Humanoid?) -> ())
	local last: Humanoid? = nil
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local now: Humanoid? = (seat :: any).Occupant
		local left = last
		if left and left ~= now then
			RunService.Heartbeat:Once(function()
				placeBeside(car, box, seat, left, side, false)
			end)
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

	local box = measure(car)
	watch(car, box, driverSeat, 1, function(occupant)
		local player = playerOf(occupant)
		if occupant and player ~= owner then
			kickOut(driverSeat) -- only the owner drives; fires again with nil
			return
		end
		drivePrompt.Enabled = occupant == nil
		updatePhysicsOwner(car)
		drive(car)
	end)
	watch(car, box, passengerSeat, -1, function(occupant)
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
