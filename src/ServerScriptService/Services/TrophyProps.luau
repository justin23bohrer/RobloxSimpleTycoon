-- TrophyProps (server only)
-- Helper for TrophyModel: the bigger props a trophy can have around its
-- figure (a giant cookie, springs, a rocket pack, a rainbow, mini Calebs).
-- Worn accessories are in TrophyAccessories. Presentation only.
--
-- Same unit space and anchors as TrophyAccessories (front is -Z). Props that
-- stand on the plinth use Anchors.Ground. Unknown names are skipped.

local TrophyAccessories = require(script.Parent.TrophyAccessories)

type MakePart = TrophyAccessories.MakePart
type Anchors = TrophyAccessories.Anchors

local TrophyProps = {}

local WHITE = Color3.fromRGB(250, 250, 250)
local DARK = Color3.fromRGB(40, 28, 20)
local COOKIE = Color3.fromRGB(196, 134, 66)
local CHIP = Color3.fromRGB(70, 40, 25)
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder's axis is X; this stands it up
local FACING = CFrame.Angles(0, math.rad(90), 0) -- turns a cylinder's flat face to the front

-- How far a prop raises the figure off the plinth.
local LIFT: { [string]: number } = {
	Springs = 0.45,
}

local builders: { [string]: (MakePart, Anchors) -> () } = {}

builders.GiantCookie = function(make, a)
	-- A cookie bigger than his head, standing up behind him like a halo.
	local center = Vector3.new(0, 2.05, a.Back.Z + 0.5)
	make("GiantCookie", Vector3.new(0.12, 1.7, 1.7), CFrame.new(center) * FACING, COOKIE, nil, CYLINDER)
	for i, angle in { 25, 70, 115, 160, 300, 345 } do
		local r = math.rad(angle)
		local chip = center + Vector3.new(math.cos(r) * 0.62, math.sin(r) * 0.62, -0.07)
		make(`GiantCookieChip{i}`, Vector3.new(0.16, 0.16, 0.16), CFrame.new(chip), CHIP, nil, BALL)
	end
end

builders.Springs = function(make, a)
	-- A metal coil spring under each shoe (the figure is lifted onto them).
	local metal = Color3.fromRGB(170, 175, 185)
	local coils = 4
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "Left" else "Right"
		for i = 1, coils do
			local y = a.Ground + (i - 0.5) * a.Lift / coils
			local x = side * 0.17 + (if i % 2 == 0 then 0.03 else -0.03)
			make(`{tag}Spring{i}`, Vector3.new(0.05, 0.3, 0.3), CFrame.new(x, y, -0.03) * UPRIGHT, metal, Enum.Material.Metal, CYLINDER)
		end
	end
end

builders.RocketPack = function(make, a)
	-- Two little rockets strapped to his back, with a small exhaust flame.
	local body, red = Color3.fromRGB(225, 225, 230), Color3.fromRGB(220, 40, 40)
	local z = a.Back.Z + 0.17
	make("RocketStrap", Vector3.new(0.22, 0.3, 0.14), CFrame.new(0, 1.5, z - 0.05), Color3.fromRGB(60, 60, 70))
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "Left" else "Right"
		local x = side * 0.2
		make(`{tag}Rocket`, Vector3.new(0.7, 0.3, 0.3), CFrame.new(x, 1.45, z) * UPRIGHT, body, Enum.Material.Metal, CYLINDER)
		make(`{tag}RocketNose`, Vector3.new(0.3, 0.3, 0.3), CFrame.new(x, 1.8, z), red, nil, BALL)
		make(`{tag}RocketFin`, Vector3.new(0.14, 0.2, 0.05), CFrame.new(x + side * 0.17, 1.17, z), red)
		make(`{tag}RocketFlame`, Vector3.new(0.2, 0.2, 0.2), CFrame.new(x, 1.04, z), Color3.fromRGB(255, 140, 30), nil, BALL)
		make(`{tag}RocketFlameCore`, Vector3.new(0.11, 0.11, 0.11), CFrame.new(x, 0.95, z), Color3.fromRGB(255, 230, 90), Enum.Material.Neon, BALL)
	end
end

builders.RainbowArch = function(make, a)
	-- A tall rainbow arching over him from behind, with a cloud at each end.
	local bands = {
		Color3.fromRGB(235, 60, 60), Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 225, 60),
		Color3.fromRGB(90, 200, 90), Color3.fromRGB(70, 140, 240),
	}
	local segments = 8
	local center = Vector3.new(0, a.Ground, a.Back.Z + 0.47)
	for b, color in bands do
		local rx, ry = 0.82 - (b - 1) * 0.09, 2.95 - (b - 1) * 0.09
		local function point(t: number): Vector3
			return center + Vector3.new(math.cos(t) * rx, math.sin(t) * ry, 0)
		end
		for s = 1, segments do
			local p0, p1 = point(math.pi * (s - 1) / segments), point(math.pi * s / segments)
			local d = p1 - p0
			local cf = CFrame.new((p0 + p1) / 2) * CFrame.Angles(0, 0, math.atan2(d.Y, d.X))
			make(`Rainbow{b}_{s}`, Vector3.new(d.Magnitude + 0.04, 0.1, 0.06), cf, color)
		end
	end
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "Left" else "Right"
		local foot = center + Vector3.new(side * 0.64, 0.12, -0.05)
		make(`{tag}Cloud`, Vector3.new(0.4, 0.4, 0.4), CFrame.new(foot), WHITE, nil, BALL)
		make(`{tag}CloudPuff`, Vector3.new(0.28, 0.28, 0.28), CFrame.new(foot + Vector3.new(side * -0.2, -0.04, 0)), WHITE, nil, BALL)
	end
end

local function miniCaleb(make: MakePart, a: Anchors, tag: string, at: Vector3)
	local color, material = a.Color, a.Material
	local hair = color:Lerp(Color3.new(0, 0, 0), 0.3)
	make(`{tag}Body`, Vector3.new(0.36, 0.36, 0.36), CFrame.new(at + Vector3.new(0, 0.2, 0)), color, material, BALL)
	make(`{tag}Head`, Vector3.new(0.36, 0.36, 0.36), CFrame.new(at + Vector3.new(0, 0.5, 0)), color, material, BALL)
	make(`{tag}Hair`, Vector3.new(0.36, 0.36, 0.36), CFrame.new(at + Vector3.new(0, 0.56, 0.05)), hair, material, BALL)
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		make(`{tag}Eye{s}`, Vector3.new(0.11, 0.11, 0.11), CFrame.new(at + Vector3.new(side * 0.06, 0.52, -0.14)), WHITE, nil, BALL)
		make(`{tag}Pupil{s}`, Vector3.new(0.04, 0.04, 0.04), CFrame.new(at + Vector3.new(side * 0.06, 0.53, -0.2)), DARK, nil, BALL)
		make(`{tag}Hand{s}`, Vector3.new(0.11, 0.11, 0.11), CFrame.new(at + Vector3.new(side * 0.2, 0.28, -0.02)), color, material, BALL)
		make(`{tag}Foot{s}`, Vector3.new(0.12, 0.12, 0.12), CFrame.new(at + Vector3.new(side * 0.08, 0.04, -0.04)), color, material, BALL)
	end
	make(`{tag}Grin`, Vector3.new(0.14, 0.04, 0.03), CFrame.new(at + Vector3.new(0, 0.43, -0.17)), DARK)
end

builders.MiniCalebs = function(make, a)
	-- Two tiny copies of him on the front corners of the plinth.
	miniCaleb(make, a, "MiniCalebLeft", Vector3.new(-0.6, a.Ground, -0.48))
	miniCaleb(make, a, "MiniCalebRight", Vector3.new(0.6, a.Ground, -0.48))
end

-- How far the figure must be raised for these props (0 = not at all).
function TrophyProps.Lift(names: { string }): number
	local lift = 0
	for _, name in names do
		lift = math.max(lift, LIFT[name] or 0)
	end
	return lift
end

-- Adds each named prop (unknown names are skipped).
function TrophyProps.Add(make: MakePart, names: { string }, anchors: Anchors)
	for _, name in names do
		local build = builders[name]
		if build then
			build(make, anchors)
		end
	end
end

return TrophyProps
