-- TrophyAccessories (server only)
-- Helper for TrophyModel: adds a variant's worn accessories (hats, glasses,
-- a cookie, a bow tie, a lightning bolt, flame hair, a big brain, a cape) to
-- a trophy figure. Bigger props (springs, rocket pack, rainbow, ...) are in
-- TrophyProps. Presentation only.
--
-- Works in the figure's unit space (before scaling): the front is -Z, the
-- head is a 1-stud ball centered at Anchor.Head, and Anchor.RightHand is
-- where the right hand ended up for the pose. Unknown names are skipped.

local TrophyAccessories = {}

export type Anchors = {
	Head: Vector3, -- head center
	Neck: Vector3, -- front of the neck, just under the head
	RightHand: Vector3,
	Back: Vector3, -- middle of the torso's back surface
	Ground: number, -- Y of the plinth top in figure space (lower when lifted)
	Lift: number, -- how far the figure is raised off the plinth (springs)
	Color: Color3, -- the figure's color and material (for mini Calebs)
	Material: Enum.Material,
}

export type MakePart = (name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?) -> BasePart

local GOLD = Color3.fromRGB(255, 200, 40)
local WHITE = Color3.fromRGB(250, 250, 250)
local BLACK = Color3.fromRGB(25, 25, 30)
local COOKIE = Color3.fromRGB(196, 134, 66)
local CHIP = Color3.fromRGB(70, 40, 25)
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder's axis is X; this stands it up

local builders: { [string]: (MakePart, Anchors) -> () } = {}

builders.Crown = function(make, a)
	local y = a.Head.Y + 0.62
	make("CrownBand", Vector3.new(0.28, 0.78, 0.78), CFrame.new(a.Head.X, y, a.Head.Z + 0.05) * UPRIGHT, GOLD, Enum.Material.Foil, CYLINDER)
	for i = 0, 4 do
		local angle = math.rad(i * 72 + 90)
		local offset = Vector3.new(math.cos(angle) * 0.34, 0.22, -math.sin(angle) * 0.34 + 0.05)
		make(`CrownPoint{i + 1}`, Vector3.new(0.15, 0.15, 0.15), CFrame.new(a.Head + Vector3.new(0, 0.62, 0) + offset), GOLD, Enum.Material.Foil, BALL)
	end
	make("CrownGem", Vector3.new(0.14, 0.14, 0.06), CFrame.new(a.Head.X, y, a.Head.Z - 0.35), Color3.fromRGB(230, 30, 60), Enum.Material.Neon)
end

builders.PartyHat = function(make, a)
	local stripes = { Color3.fromRGB(255, 90, 160), Color3.fromRGB(255, 220, 60) }
	local radii = { 0.34, 0.26, 0.18, 0.1 }
	for i, radius in radii do
		local y = a.Head.Y + 0.62 + (i - 1) * 0.15
		local cf = CFrame.new(a.Head.X, y, a.Head.Z + 0.05) * UPRIGHT
		make(`PartyHat{i}`, Vector3.new(0.16, radius * 2, radius * 2), cf, stripes[(i - 1) % 2 + 1], nil, CYLINDER)
	end
	make("PartyHatPom", Vector3.new(0.16, 0.16, 0.16), CFrame.new(a.Head + Vector3.new(0, 1.17, 0.05)), WHITE, nil, BALL)
end

builders.ChefHat = function(make, a)
	make("ChefHatBand", Vector3.new(0.26, 0.76, 0.76), CFrame.new(a.Head + Vector3.new(0, 0.6, 0.05)) * UPRIGHT, WHITE, nil, CYLINDER)
	make("ChefHatPuff", Vector3.new(0.9, 0.9, 0.9), CFrame.new(a.Head + Vector3.new(0, 1.0, 0.05)), WHITE, nil, BALL)
end

builders.Sunglasses = function(make, a)
	for _, side in { -1, 1 } do
		local cf = CFrame.new(a.Head + Vector3.new(side * 0.17, 0.08, -0.6))
		make(if side < 0 then "LensLeft" else "LensRight", Vector3.new(0.3, 0.2, 0.06), cf, BLACK, Enum.Material.Glass)
	end
	make("GlassesBridge", Vector3.new(0.1, 0.05, 0.05), CFrame.new(a.Head + Vector3.new(0, 0.12, -0.6)), BLACK)
end

builders.Cookie = function(make, a)
	-- Held flat toward the front: the disc faces -Z.
	local center = CFrame.new(a.RightHand + Vector3.new(0, 0.05, -0.18)) * CFrame.Angles(0, math.rad(90), 0)
	make("Cookie", Vector3.new(0.08, 0.5, 0.5), center, COOKIE, nil, CYLINDER)
	for i, offset in { Vector3.new(0.1, 0.08, 0), Vector3.new(-0.1, -0.05, 0), Vector3.new(0.02, -0.12, 0) } do
		make(`CookieChip{i}`, Vector3.new(0.08, 0.08, 0.08), CFrame.new(a.RightHand + Vector3.new(0, 0.05, -0.23) + offset), CHIP, nil, BALL)
	end
end

builders.BowTie = function(make, a)
	local red = Color3.fromRGB(220, 30, 50)
	make("BowLeft", Vector3.new(0.18, 0.16, 0.06), CFrame.new(a.Neck + Vector3.new(-0.11, 0, 0)) * CFrame.Angles(0, 0, math.rad(-15)), red)
	make("BowRight", Vector3.new(0.18, 0.16, 0.06), CFrame.new(a.Neck + Vector3.new(0.11, 0, 0)) * CFrame.Angles(0, 0, math.rad(15)), red)
	make("BowKnot", Vector3.new(0.08, 0.08, 0.08), CFrame.new(a.Neck + Vector3.new(0, 0, -0.02)), red, nil, BALL)
end

builders.LightningBolt = function(make, a)
	-- A yellow zigzag on the belly.
	local yellow = Color3.fromRGB(255, 220, 40)
	local z = a.Neck.Z - 0.17
	make("BoltTop", Vector3.new(0.1, 0.26, 0.05), CFrame.new(0.05, 1.6, z) * CFrame.Angles(0, 0, math.rad(25)), yellow)
	make("BoltMid", Vector3.new(0.24, 0.07, 0.05), CFrame.new(0, 1.46, z - 0.01) * CFrame.Angles(0, 0, math.rad(20)), yellow)
	make("BoltBottom", Vector3.new(0.1, 0.26, 0.05), CFrame.new(-0.05, 1.32, z) * CFrame.Angles(0, 0, math.rad(25)), yellow)
end

builders.SpeedLines = function(make, a)
	-- White streaks trailing behind him.
	local streak = Color3.fromRGB(220, 240, 255)
	for i, line in { Vector3.new(-0.3, 1.25, 0), Vector3.new(0.25, 1.55, 0), Vector3.new(-0.15, 1.9, 0) } do
		make(`SpeedLine{i}`, Vector3.new(0.05, 0.05, 0.45), CFrame.new(line.X, line.Y, a.Back.Z + 0.35), streak)
	end
end

builders.FlameHair = function(make, a)
	-- A cartoon flame of stacked balls on top of the head (FlameTop gets
	-- TrophyModel's small "Flame" particles).
	local orange, amber, yellow = Color3.fromRGB(255, 110, 20), Color3.fromRGB(255, 160, 30), Color3.fromRGB(255, 225, 70)
	make("FlameBase", Vector3.new(0.62, 0.62, 0.62), CFrame.new(a.Head + Vector3.new(0, 0.55, 0.05)), orange, nil, BALL)
	for _, side in { -1, 1 } do
		make(if side < 0 then "FlameLickLeft" else "FlameLickRight", Vector3.new(0.32, 0.32, 0.32), CFrame.new(a.Head + Vector3.new(side * 0.27, 0.62, 0.05)), orange, nil, BALL)
	end
	make("FlameMiddle", Vector3.new(0.42, 0.42, 0.42), CFrame.new(a.Head + Vector3.new(0, 0.87, 0.05)), amber, nil, BALL)
	make("FlameTop", Vector3.new(0.24, 0.24, 0.24), CFrame.new(a.Head + Vector3.new(0, 1.1, 0.05)), yellow, nil, BALL)
	make("FlameCore", Vector3.new(0.18, 0.18, 0.18), CFrame.new(a.Head + Vector3.new(0, 0.72, -0.22)), yellow, Enum.Material.Neon, BALL)
end

builders.BigBrain = function(make, a)
	-- A big pink brain bulging out of the top of the head.
	local pink, groove = Color3.fromRGB(255, 160, 190), Color3.fromRGB(215, 100, 140)
	local lobes = {
		{ 0.2, 0.5, 0.08, 0.78 }, { 0.22, 0.45, -0.2, 0.5 }, { 0.18, 0.5, 0.36, 0.56 }, { 0.15, 0.74, 0.06, 0.6 },
	}
	for i, lobe in lobes do
		for _, side in { -1, 1 } do
			local tag = if side < 0 then "Left" else "Right"
			make(`Brain{tag}{i}`, Vector3.one * lobe[4], CFrame.new(a.Head + Vector3.new(side * lobe[1], lobe[2], lobe[3])), pink, nil, BALL)
		end
	end
	make("BrainGroove", Vector3.new(0.05, 0.38, 0.95), CFrame.new(a.Head + Vector3.new(0, 0.86, 0.08)), groove)
end

builders.Cape = function(make, a)
	-- A royal red cape from the shoulders, a white fur collar, a gold clasp.
	local red, fur = Color3.fromRGB(190, 20, 40), Color3.fromRGB(250, 248, 240)
	make("Cape", Vector3.new(0.95, 1.3, 0.06), CFrame.new(0, 1.25, a.Back.Z + 0.12) * CFrame.Angles(math.rad(-8), 0, 0), red, Enum.Material.Fabric)
	for i = -2, 2 do
		make(`CapeFur{i + 3}`, Vector3.new(0.2, 0.2, 0.2), CFrame.new(i * 0.2, 1.9, a.Back.Z - 0.02), fur, Enum.Material.Fabric, BALL)
	end
	make("CapeClasp", Vector3.new(0.12, 0.12, 0.12), CFrame.new(a.Neck + Vector3.new(0, 0.02, -0.02)), GOLD, Enum.Material.Foil, BALL)
end

-- Adds each named accessory (unknown names are skipped).
function TrophyAccessories.Add(make: MakePart, names: { string }, anchors: Anchors)
	for _, name in names do
		local build = builders[name]
		if build then
			build(make, anchors)
		end
	end
end

return TrophyAccessories
