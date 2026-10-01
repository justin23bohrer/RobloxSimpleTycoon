-- CalebPoses (client only)
-- Pure math for CalebAnimator.client: Caleb's pose at a moment of the "I'm
-- full" animation or the dance. It reads Config and changes nothing.
--
-- A Pose is a set of offsets from where the server put each part:
--   Body      moves/turns the whole body about his feet (top of the pedestal)
--   Head      turns the head group about the bottom of the head
--   RightArm  radians the right arm swings out at the shoulder
--   LeftArm   radians the left arm swings out at the shoulder
--   Belly     studs the Belly ball moves (statue space; -Z is forward)
--   Puff      true while the "I'm full" puff should fire
-- Caleb faces -Z, his right side is +X. CFrame.Angles(+a, 0, 0) leans back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CalebPoses = {}

export type Pose = {
	Body: CFrame,
	Head: CFrame,
	RightArm: number,
	LeftArm: number,
	Belly: Vector3,
	Puff: boolean,
}

local TAU = 2 * math.pi

-- Which pose group a body part belongs to (by its map name), or nil.
local HEAD_PATTERNS = {
	"^Head$", "Ear$", "Eye$", "Pupil$", "Brow$", "^Nose$", "Cheek$", "^Chin$",
	"^Mouth%d+$", "^Tooth%d+$", "^HairCap$", "^Hair%d+$",
}
local ARM_GROUPS = {
	RightArm = "RightArm", RightHand = "RightArm",
	LeftUpperArm = "LeftArm", LeftForearm = "LeftArm", LeftElbow = "LeftArm", LeftHand = "LeftArm",
}

function CalebPoses.GroupOf(name: string): string?
	if ARM_GROUPS[name] then
		return ARM_GROUPS[name]
	elseif name == "Belly" then
		return "Belly"
	end
	for _, pattern in HEAD_PATTERNS do
		if name:match(pattern) then
			return "Head"
		end
	end
	return nil
end

-- 0 outside [a, b]; a smooth 0 -> 1 -> 0 hump inside.
local function hump(u: number, a: number, b: number): number
	if u <= a or u >= b then
		return 0
	end
	return math.sin(math.pi * (u - a) / (b - a))
end

local function smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- "I'm completely full": elapsed seconds into a state lasting `duration`.
function CalebPoses.Full(elapsed: number, duration: number): Pose
	local c = Config.CalebFullAnim
	local u = math.clamp(elapsed / math.max(duration, 0.1), 0, 1)
	local fade = 1 - u
	local wobble = math.rad(c.WobbleDegrees) * math.sin(TAU * c.WobblesPerSecond * elapsed) * fade * fade
	local lean = math.rad(c.LeanBackDegrees) * hump(u, 0.15, 0.97)
	local arms = math.rad(c.ArmsOutDegrees) * hump(u, 0.2, 0.92)
	local bounce = c.BellyBounce * math.abs(math.sin(TAU * c.BellyBouncesPerSecond * elapsed)) * (0.3 + 0.7 * fade)
	local jolt = math.rad(c.HeadJoltDegrees) * hump(u, c.PuffAt - 0.03, c.PuffAt + 0.2)
	return {
		Body = CFrame.Angles(lean, 0, wobble),
		Head = CFrame.Angles(jolt, 0, -wobble * 0.5),
		RightArm = arms,
		LeftArm = arms * 0.6,
		Belly = Vector3.new(0, bounce * 0.3, -bounce),
		Puff = u >= c.PuffAt and u < c.PuffAt + 0.1,
	}
end

-- The dance: elapsed seconds into Celebration, timeLeft seconds until it ends.
-- Eases in over the first beat and out over the last one.
function CalebPoses.Dance(elapsed: number, timeLeft: number): Pose
	local c = Config.CalebDance
	local beat = elapsed / c.BeatSeconds
	local amp = smooth(math.min(elapsed, timeLeft) / c.BeatSeconds)

	local side = math.sin(math.pi * beat) -- -1..1, one side per beat
	local sway = math.rad(c.SwayDegrees) * side * amp
	local hop = c.HopHeight * math.abs(side) * amp
	local wiggle = math.rad(c.ArmWiggleDegrees) * math.sin(TAU * 2 * beat)
	local arm = math.rad(c.ArmDegrees)

	-- A full spin near the end of every SpinEverySeconds, unless the state
	-- would end before it finishes.
	local yaw = 0
	local cycleStart = elapsed - elapsed % c.SpinEverySeconds
	local spinStart = cycleStart + c.SpinEverySeconds - c.SpinSeconds
	if elapsed >= spinStart and spinStart + c.SpinSeconds <= elapsed + timeLeft then
		yaw = TAU * smooth((elapsed - spinStart) / c.SpinSeconds)
	end

	return {
		Body = CFrame.new(0, hop, 0) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, sway),
		Head = CFrame.Angles(math.rad(c.HeadBobDegrees) * math.sin(TAU * beat) * amp, 0, -sway * 0.8),
		RightArm = (arm * (0.5 + 0.5 * side) + wiggle) * amp,
		LeftArm = (arm * (0.5 - 0.5 * side) - wiggle) * amp,
		Belly = Vector3.new(0, 0, -c.BellyJiggle * math.abs(math.sin(TAU * beat)) * amp),
		Puff = false,
	}
end

return table.freeze(CalebPoses)
