-- DropperCup (server only)
-- Helper for DropperService: builds what a bought dropper looks like, an
-- upside-down red party cup. Presentation only; it decides nothing.
--
-- Build(spot, name) makes a Model called `name` that fills the dropper
-- spot's box: the cup's open end (its rim) is at the bottom, so cookies fall
-- out of it, and the cup's base is at the top. It returns the model (not yet
-- parented) and the CFrame of the center of the rim.
--
-- The cup is stacked cylinders that get narrower toward the top, with two
-- darker ridges, a rolled lip, and a white disc inside the opening. Built on
-- the server so every player sees it.

local DropperCup = {}

-- Looks only; not gameplay tuning.
local CUP_RED = Color3.fromRGB(205, 25, 35)
local RIDGE_RED = Color3.fromRGB(160, 15, 25)
local INSIDE_WHITE = Color3.fromRGB(245, 245, 245)
local SLICES = 8
local RIM_SCALE = 0.9 -- rim diameter, as a fraction of the spot's width
local BASE_SCALE = 0.65 -- base diameter (the top, now that it is upside down)
local RIDGE_HEIGHTS = { 0.55, 0.75 } -- fraction of the cup's height above the rim
-- A Cylinder's round faces are on its X axis; this stands it upright.
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)

local function disc(name: string, center: CFrame, height: number, diameter: number, color: Color3, parent: Instance)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height, diameter, diameter)
	part.CFrame = center * UPRIGHT
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
end

function DropperCup.Build(spot: BasePart, name: string): (Model, CFrame)
	local cup = Instance.new("Model")
	cup.Name = name

	local height = spot.Size.Y
	local width = math.min(spot.Size.X, spot.Size.Z)
	local rimDiameter = width * RIM_SCALE
	local baseDiameter = width * BASE_SCALE
	local function diameterAt(t: number): number -- t = 0 at the rim, 1 at the base
		return rimDiameter + (baseDiameter - rimDiameter) * t
	end
	local rim = spot.CFrame * CFrame.new(0, -height / 2, 0)

	local sliceHeight = height / SLICES
	for i = 1, SLICES do
		local t = (i - 0.5) / SLICES
		disc(`Side{i}`, rim * CFrame.new(0, t * height, 0), sliceHeight, diameterAt(t), CUP_RED, cup)
	end
	for i, t in RIDGE_HEIGHTS do
		disc(`Ridge{i}`, rim * CFrame.new(0, t * height, 0), 0.15, diameterAt(t) + 0.15, RIDGE_RED, cup)
	end
	-- Rolled lip around the opening, and the white inside seen from below.
	disc("Lip", rim * CFrame.new(0, 0.12, 0), 0.24, rimDiameter + 0.2, CUP_RED, cup)
	disc("Inside", rim * CFrame.new(0, -0.02, 0), 0.04, rimDiameter - 0.3, INSIDE_WHITE, cup)

	return cup, rim
end

return DropperCup
