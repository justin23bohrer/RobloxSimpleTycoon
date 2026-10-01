-- CollectorDisplay (server only)
-- Helper for CollectorService: the fun, presentation-only side of a plot's
-- collect area. It never reads or changes cash.
--
-- * Every drop the Collector accepts drops a small cookie into the plot's
--   glass CashTank (the "COOKIE JAR" on the wall behind the CollectPad), so
--   the jar fills up as cookies wait to be picked up. No amounts are shown as
--   text.
-- * While cash is waiting, the CollectPad sparkles and glows.
-- * A bouncing arrow above the pad invites the owner to step on it.
-- * On payout the tank empties with a burst of gold sparkles.
--
-- Everything is made on the server so every player sees the same thing.
-- Missing CashTank parts only skip the cubes; the pad still works.

local TweenService = game:GetService("TweenService")

local CollectorDisplay = {}

-- Looks only; not gameplay tuning.
local MAX_TANK_CUBES = 60 -- tank looks full past this; stops adding cookies
local CUBE_SIZE = Vector3.new(0.3, 0.9, 0.9) -- a Cylinder: X is the cookie's thickness
local CUBE_COLOR = Color3.fromRGB(214, 160, 90) -- same dough color as the drops
local GOLD = Color3.fromRGB(255, 215, 60)
-- Where new cubes appear, in the TankLid's own space (so it works on plots
-- turned any way): just under the lid, anywhere across the tank's inside
-- (6 studs wide along the lid's X, 2.4 deep along its Z) with room so a cube
-- never starts inside the glass. The lid also covers the front glass, so the
-- inside is centered 0.2 studs behind the lid's center.
local CUBE_SPAWN_OFFSET = Vector3.new(0, -1.1, -0.2)
local CUBE_SPREAD_X = 2.2
local CUBE_SPREAD_Z = 0.4
local BURST_SECONDS = 0.4

type Display = {
	Tank: Model?,
	Cubes: Folder?,
	Sparkles: ParticleEmitter,
	Burst: ParticleEmitter,
	Glow: PointLight,
	Count: number,
}

local displayByPlot: { [Model]: Display } = {}

local function makeEmitter(name: string, rate: number, speed: number): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Color = ColorSequence.new(GOLD)
	emitter.LightEmission = 0.8
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(speed, speed * 2)
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Size = NumberSequence.new(0.4, 0)
	emitter.EmissionDirection = Enum.NormalId.Right -- the pad is a Cylinder turned so +X points up
	emitter.Enabled = false
	return emitter
end

local function makeArrow(pad: BasePart)
	local arrow = Instance.new("BillboardGui")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.fromScale(2.5, 2.5)
	arrow.StudsOffset = Vector3.new(0, 5, 0)
	arrow.AlwaysOnTop = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "▼"
	label.TextScaled = true
	label.TextColor3 = GOLD
	label.TextStrokeTransparency = 0
	label.Parent = arrow
	arrow.Parent = pad

	-- Bounce forever between 5 and 6 studs above the pad.
	TweenService:Create(
		arrow,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ StudsOffset = Vector3.new(0, 6, 0) }
	):Play()
end

-- Builds the effects for a plot's collect area. Called once per plot.
function CollectorDisplay.Setup(plot: Model)
	if displayByPlot[plot] then
		return
	end
	local pad = plot.CollectPad :: BasePart

	local sparkles = makeEmitter("Sparkles", 12, 2)
	sparkles.Parent = pad
	local burst = makeEmitter("Burst", 250, 8)
	burst.Parent = pad

	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Color = GOLD
	glow.Brightness = 3
	glow.Range = 10
	glow.Enabled = false
	glow.Parent = pad

	makeArrow(pad)

	local tank = plot:FindFirstChild("CashTank") :: Model?
	local cubes: Folder? = nil
	if tank and tank:FindFirstChild("TankLid") then
		cubes = Instance.new("Folder")
		cubes.Name = "TankCubes"
		cubes.Parent = tank
	else
		warn(`CollectorDisplay: {plot.Name} has no CashTank with a TankLid; the tank will stay empty`)
	end

	displayByPlot[plot] = {
		Tank = tank,
		Cubes = cubes,
		Sparkles = sparkles,
		Burst = burst,
		Glow = glow,
		Count = 0,
	}
end

-- Shows one more collected drop: a cookie falls into the tank and the pad
-- starts sparkling.
function CollectorDisplay.AddCube(plot: Model)
	local display = displayByPlot[plot]
	if not display then
		return
	end
	display.Sparkles.Enabled = true
	display.Glow.Enabled = true

	local cubes = display.Cubes
	if not cubes or not display.Tank or display.Count >= MAX_TANK_CUBES then
		return
	end
	display.Count += 1

	local lid = display.Tank.TankLid :: BasePart
	local offset = CUBE_SPAWN_OFFSET
		+ Vector3.new((math.random() * 2 - 1) * CUBE_SPREAD_X, 0, (math.random() * 2 - 1) * CUBE_SPREAD_Z)

	local cube = Instance.new("Part")
	cube.Name = "TankCookie"
	cube.Shape = Enum.PartType.Cylinder
	cube.Size = CUBE_SIZE
	cube.Color = CUBE_COLOR
	cube.Material = Enum.Material.SmoothPlastic
	cube.CanTouch = false -- never reaches the Collector or any Touched handler
	cube.CanQuery = false
	cube.CFrame = lid.CFrame
		* CFrame.new(offset)
		* CFrame.Angles(0, math.random() * math.pi, math.pi / 2 + (math.random() - 0.5)) -- roughly flat, tilted; tumbles onto the pile
	cube.Parent = cubes
	cube:SetNetworkOwner(nil)
end

-- Empties the tank and stops the sparkles. With celebrate = true (a payout)
-- the pad also bursts with gold sparkles.
function CollectorDisplay.Clear(plot: Model, celebrate: boolean)
	local display = displayByPlot[plot]
	if not display then
		return
	end
	if display.Cubes then
		display.Cubes:ClearAllChildren()
	end
	display.Count = 0
	display.Sparkles.Enabled = false
	display.Glow.Enabled = false

	if celebrate then
		-- ParticleEmitter:Emit() would only show on the server, so turn the
		-- emitter on briefly instead; Enabled replicates to every player.
		display.Burst.Enabled = true
		task.delay(BURST_SECONDS, function()
			display.Burst.Enabled = false
		end)
	end
end

return CollectorDisplay
