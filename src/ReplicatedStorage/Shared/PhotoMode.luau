-- PhotoMode (shared, read-only)
-- TESTING ONLY: Config.DevPhotoMode, for taking the game's icon and
-- thumbnail screenshots in Studio. Enabled is true only when the switch is
-- on AND the game runs in Roblox Studio (RunService:IsStudio()), like
-- DevUnlimitedCash: a published game never turns it on.
--
-- Used by DevPhotoMode (server: showcase plot, no saving, sunny lighting)
-- and PhotoCamera (client: camera presets, hide UI). See README "Taking icon
-- / thumbnail screenshots (Photo Mode)".
--
-- Shots: the camera presets for keys 1-6. Eye (where the camera stands) and
-- Target (what it looks at) are in studs relative to the owner's plot Base
-- part (its CFrame), so every preset works on all 4 turned plots. In Base
-- space +Z points from the plot toward the statue (the front of the house),
-- -Z toward the backyard, +X toward the garage, +Y up; Base's center is the
-- middle of the house floor. Fov is the camera FieldOfView in degrees.
-- Tweak these numbers to frame the shots differently.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

export type Shot = {
	Name: string,
	Eye: Vector3,
	Target: Vector3,
	Fov: number,
}

local PhotoMode = {}

PhotoMode.Enabled = Config.DevPhotoMode == true and RunService:IsStudio()

PhotoMode.Shots = table.freeze({
	-- 1: the whole tycoon (house, garage, backyard) from high up, front-right.
	table.freeze({ Name = "Whole tycoon", Eye = Vector3.new(95, 85, 75), Target = Vector3.new(8, 4, -18), Fov = 55 }),
	-- 2: the front of the house, from the path toward the statue.
	table.freeze({ Name = "House front", Eye = Vector3.new(-14, 12, 62), Target = Vector3.new(0, 14, 0), Fov = 60 }),
	-- 3: the backyard (pool + hangout) from above the back fence.
	table.freeze({ Name = "Backyard", Eye = Vector3.new(0, 40, -105), Target = Vector3.new(0, 1, -55), Fov = 60 }),
	-- 4: the garage and its car.
	table.freeze({ Name = "Garage + car", Eye = Vector3.new(30, 12, 58), Target = Vector3.new(46, 6, 18), Fov = 55 }),
	-- 5: Caleb's statue with this plot behind it (camera past the statue).
	table.freeze({ Name = "Caleb statue", Eye = Vector3.new(40, 28, 135), Target = Vector3.new(0, 20, 80), Fov = 60 }),
	-- 6: droppers, conveyor and cash tank, inside the ground floor.
	table.freeze({ Name = "Droppers", Eye = Vector3.new(-6, 12, 28), Target = Vector3.new(-20, 4, 2), Fov = 65 }),
})

-- The world CFrame of a shot for a plot whose Base part is at baseCFrame.
function PhotoMode.ShotCFrame(baseCFrame: CFrame, shot: Shot): CFrame
	return CFrame.lookAt(baseCFrame:PointToWorldSpace(shot.Eye), baseCFrame:PointToWorldSpace(shot.Target))
end

return table.freeze(PhotoMode)
