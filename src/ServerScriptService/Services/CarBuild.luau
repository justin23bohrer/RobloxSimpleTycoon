-- CarBuild (server only)
-- Helper for CarService: turns a copy of a plot's GarageCar look (anchored
-- decoration from tools/garage/id4_car.py) into one drivable physics car.
-- It only builds instances; it decides nothing.
--
-- * Root = the car's `Body` part. Its CFrame is the car's own frame on
--   every (turned) plot: +Z is the nose, +X the car's left, +Y up. Every
--   other look part is welded to it (WeldConstraint) and made Massless.
-- * 4 wheels (FrontL, FrontR, RearL, RearR): `Tire<Wheel>` is the solid,
--   heavy wheel (Config.CarWheelDensity/CarWheelFriction); its Rim, Spokes,
--   Cap and CapRing are welded to it. Each tire spins on a Motor
--   HingeConstraint `Drive<Wheel>` (axis = the car's X). A front tire hangs
--   from an invisible `Knuckle<Wheel>` that turns on a Servo hinge
--   `Steer<Wheel>` (axis = up). NoCollisionConstraints keep the tires from
--   hitting the solid body parts they overlap.
-- * An invisible VehicleSeat `DriverSeat` (car's left) and Seat
--   `PassengerSeat` (right). They can't be touched: people get in through
--   CarSeats' prompts.
-- * An `Upright` AlignOrientation (Config.CarUprightTorque) gently keeps
--   the roof up. The windows are made see-through so riders show.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CarBuild = {}

export type Car = {
	Model: Model,
	Root: BasePart,
	DriverSeat: VehicleSeat,
	PassengerSeat: Seat,
	Motors: { HingeConstraint },
	Steering: { HingeConstraint },
	WheelRadius: number,
}

local WHEELS = { "FrontL", "FrontR", "RearL", "RearR" }
local GLASS = { SideGlass = true, Windshield = true, RearWindow = true }
local GLASS_TRANSPARENCY = 0.35
-- Seats in the Body's object space (Body center is 2.4 above the car's
-- floor): seat top 1.9 above the floor, between the B-pillar and the
-- windshield. +X = the car's left (driver side).
local SEAT_X, SEAT_Y, SEAT_Z = 1.6, -0.7, -0.7
local SEAT_SIZE = Vector3.new(2, 0.4, 2)
local KNUCKLE_SIZE = Vector3.new(1, 1, 1)
local KNUCKLE_DENSITY = 20
local LIFT = 0.2 -- spawn this high so the tires never start inside the floor

-- The wheel a look part spins with, if any (Rim<Wheel>, Spoke<Wheel>N, ...).
local function wheelOf(name: string): string?
	for _, wheel in WHEELS do
		if
			name == `Rim{wheel}`
			or name == `Cap{wheel}`
			or name == `CapRing{wheel}`
			or string.match(name, `^Spoke{wheel}%d+$`)
		then
			return wheel
		end
	end
	return nil
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function attach(part: BasePart, name: string, world: CFrame): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = part.CFrame:ToObjectSpace(world)
	a.Parent = part
	return a
end

local function hinge(name: string, a0: Attachment, a1: Attachment, parent: Instance): HingeConstraint
	local h = Instance.new("HingeConstraint")
	h.Name = name
	h.Attachment0 = a0
	h.Attachment1 = a1
	h.Parent = parent
	return h
end

local function seat(className: string, name: string, root: BasePart, side: number): BasePart
	local s = Instance.new(className) :: BasePart
	s.Name = name
	s.Size = SEAT_SIZE
	-- Faces the nose (+Z of the car = -LookVector of the Body).
	s.CFrame = root.CFrame * CFrame.new(side * SEAT_X, SEAT_Y, SEAT_Z) * CFrame.Angles(0, math.pi, 0)
	s.Transparency = 1
	s.CanCollide = false
	s.CanTouch = false
	s.CanQuery = false
	s.Massless = true
	s.Parent = root.Parent
	weld(root, s)
	return s
end

-- Builds a drivable car from `template` (a GarageCar look). Returns nil if
-- the look has no Body or misses a tire. The car is not parented yet.
function CarBuild.Build(template: Model): Car?
	local model = template:Clone()
	local root = model:FindFirstChild("Body")
	if not (root and root:IsA("BasePart")) then
		model:Destroy()
		return nil
	end
	local tires: { [string]: BasePart } = {}
	local isTire: { [BasePart]: boolean } = {}
	for _, wheel in WHEELS do
		local tire = model:FindFirstChild(`Tire{wheel}`)
		if not (tire and tire:IsA("BasePart")) then
			model:Destroy()
			return nil
		end
		tires[wheel] = tire
		isTire[tire] = true
	end
	model:PivotTo(model:GetPivot() + Vector3.new(0, LIFT, 0))
	model.PrimaryPart = root

	local solid: { BasePart } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= root and not isTire[part] then
			local wheel = wheelOf(part.Name)
			weld(if wheel then tires[wheel] else root, part)
			part.Massless = true
			if GLASS[part.Name] then
				part.Transparency = GLASS_TRANSPARENCY
			end
			if part.CanCollide and not wheel then
				table.insert(solid, part)
			end
		end
	end
	table.insert(solid, root)

	local frame = root.CFrame.Rotation -- the car's axes
	local car: Car = {
		Model = model,
		Root = root,
		DriverSeat = seat("VehicleSeat", "DriverSeat", root, 1) :: any,
		PassengerSeat = seat("Seat", "PassengerSeat", root, -1) :: any,
		Motors = {},
		Steering = {},
		WheelRadius = tires.FrontL.Size.Y / 2,
	}
	car.DriverSeat.HeadsUpDisplay = false

	for _, wheel in WHEELS do
		local tire = tires[wheel]
		tire.CanCollide = true
		tire.CustomPhysicalProperties =
			PhysicalProperties.new(Config.CarWheelDensity, Config.CarWheelFriction, 0, 100, 1)
		-- Spin axis = the car's X; secondary axis up.
		local spin = CFrame.fromMatrix(tire.Position, frame.RightVector, frame.UpVector)
		local holder: BasePart = root
		if string.sub(wheel, 1, 5) == "Front" then
			local knuckle = Instance.new("Part")
			knuckle.Name = `Knuckle{wheel}`
			knuckle.Size = KNUCKLE_SIZE
			knuckle.CFrame = CFrame.new(tire.Position) * frame
			knuckle.Transparency = 1
			knuckle.CanCollide = false
			knuckle.CanTouch = false
			knuckle.CanQuery = false
			knuckle.CustomPhysicalProperties = PhysicalProperties.new(KNUCKLE_DENSITY, 0.3, 0)
			knuckle.Parent = model
			-- Turn axis = up; secondary axis = the car's X.
			local turn = CFrame.fromMatrix(tire.Position, frame.UpVector, frame.RightVector)
			local steer = hinge(`Steer{wheel}`, attach(root, `Steer{wheel}`, turn), attach(knuckle, "Steer", turn), root)
			steer.ActuatorType = Enum.ActuatorType.Servo
			steer.ServoMaxTorque = Config.CarSteerTorque
			steer.AngularSpeed = Config.CarSteerSpeed
			table.insert(car.Steering, steer)
			holder = knuckle
		end
		local drive = hinge(`Drive{wheel}`, attach(holder, `Drive{wheel}`, spin), attach(tire, "Drive", spin), root)
		drive.ActuatorType = Enum.ActuatorType.Motor
		drive.MotorMaxTorque = Config.CarBrakeTorque
		drive.MotorMaxAcceleration = Config.CarWheelAcceleration
		table.insert(car.Motors, drive)
		for _, part in solid do
			local nc = Instance.new("NoCollisionConstraint")
			nc.Part0 = tire
			nc.Part1 = part
			nc.Parent = tire
		end
	end

	local upright = Instance.new("AlignOrientation")
	upright.Name = "Upright"
	upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
	upright.AlignType = Enum.AlignType.PrimaryAxisParallel
	upright.PrimaryAxis = Vector3.yAxis
	upright.Attachment0 = attach(root, "Upright", root.CFrame * CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.zAxis))
	upright.MaxTorque = Config.CarUprightTorque
	upright.Responsiveness = 10
	upright.Enabled = Config.CarUprightTorque > 0
	upright.Parent = root

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	return car
end

return CarBuild
