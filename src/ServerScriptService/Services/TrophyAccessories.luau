-- TrophyAccessories (server only)
-- Helper for TrophyModel: adds a variant's accessories (hats, glasses, a
-- cookie, a bow tie) to a trophy figure. Presentation only.
--
-- Works in the trophy's unit space (before scaling): the front is -Z, the
-- head is a 1-stud ball centered at Anchor.Head, and Anchor.RightHand is
-- where the right hand ended up for the pose. Unknown names are skipped.

local TrophyAccessories = {}

export type Anchors = {
	Head: Vector3, -- head center
	Neck: Vector3, -- front of the neck, just under the head
	RightHand: Vector3,
}

type MakePart = (name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?) -> BasePart

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
