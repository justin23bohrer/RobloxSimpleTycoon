-- CalebPoses (client only)
-- Pure math for CalebAnimator.client: Caleb's pose at a moment of the "I'm
-- full" animation or the dance, plus small helpers the party poses
-- (CalebPartyPoses, CalebPartyMoves) share. It reads Config and changes
-- nothing.
--
-- A Pose is a flat set of numbers (offsets from where the server put each
-- part), so poses can be blended:
--   BodyUp, BodyPitch, BodyYaw, BodyRoll   the whole body, about his feet
--                                          (top of the pedestal); studs/radians
--   HeadPitch, HeadYaw, HeadRoll           the head group, about the neck
--   RightArm, LeftArm                      radians an arm swings OUT (sideways)
--   RightArmFwd, LeftArmFwd                radians it then swings FORWARD
--   BellyUp, BellyForward                  studs the Belly ball moves
--   BellyScale                             the Belly's size (1 = as the server set it)
--   MouthOpen                              studs the mouth, teeth and chin drop
--   Cheeks                                 studs each cheek puffs out
--   Puff / Laugh                           flags for CalebMouth (burp puff,
--                                          laugh sound)
-- Caleb faces -Z, his right side is +X. A positive pitch leans back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CalebPoses = {}

export type Pose = {
	BodyUp: number,
	BodyPitch: number,
	BodyYaw: number,
	BodyRoll: number,
	HeadPitch: number,
	HeadYaw: number,
	HeadRoll: number,
	RightArm: number,
	RightArmFwd: number,
	LeftArm: number,
	LeftArmFwd: number,
	BellyUp: number,
	BellyForward: number,
	BellyScale: number,
	MouthOpen: number,
	Cheeks: number,
	Puff: boolean,
	Laugh: boolean,
}

local TAU = 2 * math.pi
CalebPoses.TAU = TAU

-- Which pose group a body part belongs to (by its map name), or nil.
local HEAD_PATTERNS = {
	"^Head$", "Ear$", "Eye$", "Pupil$", "Brow$", "^Nose$", "^HairCap$", "^Hair%d+$",
}
local OTHER_GROUPS = {
	RightArm = "RightArm", RightHand = "RightArm",
	LeftUpperArm = "LeftArm", LeftForearm = "LeftArm", LeftElbow = "LeftArm", LeftHand = "LeftArm",
	Belly = "Belly", Chin = "Mouth", RightCheek = "RightCheek", LeftCheek = "LeftCheek",
}

function CalebPoses.GroupOf(name: string): string?
	if OTHER_GROUPS[name] then
		return OTHER_GROUPS[name]
	elseif name:match("^Mouth%d+$") or name:match("^Tooth%d+$") then
		return "Mouth"
	end
	for _, pattern in HEAD_PATTERNS do
		if name:match(pattern) then
			return "Head"
		end
	end
	return nil
end

-- Helpers ------------------------------------------------------------------

-- 0 outside [a, b]; a smooth 0 -> 1 -> 0 hump inside.
function CalebPoses.Hump(u: number, a: number, b: number): number
	if u <= a or u >= b then
		return 0
	end
	return math.sin(math.pi * (u - a) / (b - a))
end

function CalebPoses.Smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- Smoothly through the keyframes { {u, value}, ... } (u ascending); holds
-- the first/last value outside them.
function CalebPoses.Keys(u: number, keys: { { number } }): number
	if u <= keys[1][1] then
		return keys[1][2]
	end
	for i = 2, #keys do
		local a, b = keys[i - 1], keys[i]
		if u <= b[1] then
			return a[2] + (b[2] - a[2]) * CalebPoses.Smooth((u - a[1]) / (b[1] - a[1]))
		end
	end
	return keys[#keys][2]
end

-- Standing still, as the server placed him.
function CalebPoses.Rest(): Pose
	return {
		BodyUp = 0, BodyPitch = 0, BodyYaw = 0, BodyRoll = 0,
		HeadPitch = 0, HeadYaw = 0, HeadRoll = 0,
		RightArm = 0, RightArmFwd = 0, LeftArm = 0, LeftArmFwd = 0,
		BellyUp = 0, BellyForward = 0, BellyScale = 1,
		MouthOpen = 0, Cheeks = 0,
		Puff = false, Laugh = false,
	}
end

-- Moves every number of `pose` a share `w` (0..1) of the way to `target`'s.
-- Flags are left alone.
function CalebPoses.Blend(pose: Pose, target: Pose, w: number)
	if w <= 0 then
		return
	end
	local p = pose :: any
	for key, value in target :: any do
		if typeof(value) == "number" then
			p[key] += (value - p[key]) * w
		end
	end
end

local hump = CalebPoses.Hump

-- Poses ----------------------------------------------------------------------

-- "I'm completely full": elapsed seconds into a state lasting `duration`.
function CalebPoses.Full(elapsed: number, duration: number): Pose
	local c = Config.CalebFullAnim
	local u = math.clamp(elapsed / math.max(duration, 0.1), 0, 1)
	local fade = 1 - u
	local wobble = math.rad(c.WobbleDegrees) * math.sin(TAU * c.WobblesPerSecond * elapsed) * fade * fade
	local arms = math.rad(c.ArmsOutDegrees) * hump(u, 0.2, 0.92)
	local bounce = c.BellyBounce * math.abs(math.sin(TAU * c.BellyBouncesPerSecond * elapsed)) * (0.3 + 0.7 * fade)
	local pose = CalebPoses.Rest()
	pose.BodyPitch = math.rad(c.LeanBackDegrees) * hump(u, 0.15, 0.97)
	pose.BodyRoll = wobble
	pose.HeadPitch = math.rad(c.HeadJoltDegrees) * hump(u, c.PuffAt - 0.03, c.PuffAt + 0.2)
	pose.HeadRoll = -wobble * 0.5
	pose.RightArm = arms
	pose.LeftArm = arms * 0.6
	pose.BellyUp = bounce * 0.3
	pose.BellyForward = bounce
	pose.Puff = u >= c.PuffAt and u < c.PuffAt + 0.1
	return pose
end

-- The dance at `beat` beats in (one sway to a side per beat), `size` times
-- as big as Config.CalebDance, faded in by `ease` (0..1). The party
-- (CalebPartyPoses) picks beat/size/ease and adds its moves on top.
function CalebPoses.Dance(beat: number, size: number, ease: number): Pose
	local c = Config.CalebDance
	local amp = size * ease
	local side = math.sin(math.pi * beat) -- -1..1, one side per beat
	local sway = math.rad(c.SwayDegrees) * side * amp
	local wiggle = math.rad(c.ArmWiggleDegrees) * math.sin(TAU * 2 * beat)
	local arm = math.rad(c.ArmDegrees)

	local pose = CalebPoses.Rest()
	pose.BodyUp = c.HopHeight * math.abs(side) * amp
	pose.BodyRoll = sway
	pose.HeadPitch = math.rad(c.HeadBobDegrees) * math.sin(TAU * beat) * amp
	pose.HeadRoll = -sway * 0.8
	pose.RightArm = (arm * (0.5 + 0.5 * side) + wiggle) * amp
	pose.LeftArm = (arm * (0.5 - 0.5 * side) - wiggle) * amp
	pose.BellyForward = c.BellyJiggle * math.abs(math.sin(TAU * beat)) * amp
	return pose
end

return table.freeze(CalebPoses)
