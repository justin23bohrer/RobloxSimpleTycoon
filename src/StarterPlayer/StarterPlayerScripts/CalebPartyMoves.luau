-- CalebPartyMoves (client only)
-- Pure math: Caleb's short party moves, laid on top of the dance pose by
-- CalebPartyPoses. Each move changes the pose in place for a moment `u`
-- (0..1 through the move), `t` seconds into it, `size` times as big, and
-- `side` (1 = his right, -1 = his left) for the one-sided moves. Moves fade
-- in and out on their own, so a move starting or ending never pops. Changes
-- nothing outside the pose it is given.
--
--   Throw  one arm winds back and flings forward, body twists into it
--   Spit   head tilts back with puffed cheeks, then snaps forward, mouth
--          drops open and crumbs spray out (Pose.Spit)
--   Laugh  head back and shaking, belly jiggling hard, bouncing (Pose.Laugh)
--   Spin   a hopping spin with arms out (two spins when size >= 1.4)
--   Jump   dip, big jump with arms up, squashy landing
--   Drum   both hands take turns drumming on his belly

local CalebPoses = require(script.Parent:WaitForChild("CalebPoses"))

type Pose = CalebPoses.Pose

local TAU = CalebPoses.TAU
local keys, hump, smooth = CalebPoses.Keys, CalebPoses.Hump, CalebPoses.Smooth

local CalebPartyMoves = {}

-- Every move, in a fixed order (CalebPartyPoses picks from these).
CalebPartyMoves.Names = table.freeze({ "Throw", "Spit", "Laugh", "Spin", "Jump", "Drum" })

-- 0 -> 1 -> 0 over a move, quick at both ends.
local function fade(u: number): number
	return smooth(u / 0.12) * smooth((1 - u) / 0.15)
end

-- Move one arm a share `w` of the way to (out, forward) radians.
local function arm(pose: Pose, side: number, out: number, forward: number, w: number)
	if side > 0 then
		pose.RightArm += (out - pose.RightArm) * w
		pose.RightArmFwd += (forward - pose.RightArmFwd) * w
	else
		pose.LeftArm += (out - pose.LeftArm) * w
		pose.LeftArmFwd += (forward - pose.LeftArmFwd) * w
	end
end

local moves: { [string]: (pose: Pose, u: number, t: number, size: number, side: number) -> () } = {}

function moves.Throw(pose, u, _t, size, side)
	local w = fade(u)
	local reach = 0.8 + 0.2 * size
	arm(pose, side, 0.35, keys(u, { { 0, 0 }, { 0.35, -0.9 }, { 0.52, 2.1 * reach }, { 0.68, 1.7 * reach }, { 1, 0 } }), w)
	arm(pose, -side, 0.9, 0, w) -- the other arm out for balance
	-- Twist: the throwing shoulder goes back, then whips forward.
	pose.BodyYaw += keys(u, { { 0, 0 }, { 0.35, -0.3 }, { 0.55, 0.25 }, { 1, 0 } }) * side * size
	pose.BodyPitch += keys(u, { { 0, 0 }, { 0.35, 0.08 }, { 0.55, -0.15 }, { 1, 0 } }) * size
	pose.HeadPitch += keys(u, { { 0, 0 }, { 0.35, 0.1 }, { 0.55, -0.12 }, { 1, 0 } })
	pose.MouthOpen += 0.8 * hump(u, 0.45, 0.85)
end

function moves.Spit(pose, u, _t, size, _side)
	local w = fade(u)
	local big = math.min(size, 1.3)
	pose.HeadPitch += keys(u, { { 0, 0 }, { 0.4, 0.45 }, { 0.52, -0.3 }, { 0.8, -0.2 }, { 1, 0 } }) * big
	pose.BodyPitch += keys(u, { { 0, 0 }, { 0.4, 0.12 }, { 0.52, -0.12 }, { 0.8, -0.08 }, { 1, 0 } })
	pose.Cheeks += keys(u, { { 0, 0 }, { 0.2, 0.6 }, { 0.42, 1.3 }, { 0.52, 0 }, { 1, 0 } }) * size
	pose.BellyScale += keys(u, { { 0, 0 }, { 0.42, 0.1 }, { 0.52, -0.03 }, { 1, 0 } })
	pose.MouthOpen += keys(u, { { 0, 0 }, { 0.45, 0 }, { 0.53, 1.6 }, { 0.8, 1.3 }, { 1, 0 } })
	local out = keys(u, { { 0, 0.8 }, { 0.45, 0.8 }, { 0.55, 1.4 }, { 1, 1 } })
	local forward = keys(u, { { 0, -0.3 }, { 0.45, -0.3 }, { 0.55, 0.2 }, { 1, 0 } })
	arm(pose, 1, out, forward, w)
	arm(pose, -1, out, forward, w)
	pose.Spit = u >= 0.5 and u <= 0.82
end

function moves.Laugh(pose, u, t, size, _side)
	local e = smooth(u / 0.1) * smooth((1 - u) / 0.2)
	local jiggle = math.sin(TAU * 5 * t)
	pose.HeadPitch += 0.3 * e
	pose.HeadYaw += 0.22 * size * math.sin(TAU * 6 * t) * e
	pose.HeadRoll += 0.1 * math.sin(TAU * 3 * t) * e
	pose.BodyUp += 0.8 * size * math.abs(math.sin(TAU * 4 * t)) * e
	pose.BodyPitch += 0.12 * e
	pose.BellyForward += 1.6 * size * math.abs(jiggle) * e
	pose.BellyUp += 0.5 * jiggle * e
	pose.BellyScale += 0.05 * size * math.abs(jiggle) * e
	pose.MouthOpen += (1 + 0.4 * math.sin(TAU * 8 * t)) * e
	-- Hands on his belly.
	arm(pose, 1, 0.15, 0.75, e)
	arm(pose, -1, 0.1, 0.4, e)
	pose.Laugh = true
end

function moves.Spin(pose, u, _t, size, side)
	local w = fade(u)
	local turns = if size >= 1.4 then 2 else 1
	local up = hump(u, 0, 1)
	pose.BodyYaw += side * TAU * turns * smooth(u)
	pose.BodyUp += 1.2 * size * up
	pose.HeadPitch += 0.15 * up
	pose.MouthOpen += 0.6 * up
	arm(pose, 1, 1.5, 0, w)
	arm(pose, -1, 1.5, 0, w)
end

function moves.Jump(pose, u, _t, size, _side)
	local w = fade(u)
	local land = hump(u, 0.62, 0.92)
	pose.BodyUp += keys(u, { { 0, 0 }, { 0.22, -0.4 }, { 0.5, 5 * size }, { 0.72, -0.3 }, { 0.88, 0 }, { 1, 0 } })
	pose.BodyPitch += keys(u, { { 0, 0 }, { 0.22, -0.12 }, { 0.5, 0.12 }, { 0.72, -0.06 }, { 1, 0 } })
	pose.BellyForward += 1.5 * land
	pose.BellyUp -= 0.8 * land
	pose.HeadPitch += 0.25 * hump(u, 0.3, 0.7)
	pose.MouthOpen += 1.2 * hump(u, 0.3, 0.75)
	local out = keys(u, { { 0, 0.3 }, { 0.22, 0.2 }, { 0.45, 2.6 }, { 0.7, 1.2 }, { 1, 0.5 } })
	arm(pose, 1, out, 0, w)
	arm(pose, -1, out, 0, w)
end

function moves.Drum(pose, u, _t, size, _side)
	local e = fade(u)
	local hit = math.sin(4 * math.pi * u) -- 4 hits, sides taking turns
	arm(pose, 1, 0.12, 0.55 + 0.45 * math.max(0, hit) * size, e)
	arm(pose, -1, 0.12, 0.55 + 0.45 * math.max(0, -hit) * size, e)
	pose.BellyForward += 1.2 * size * math.abs(hit) * e
	pose.HeadPitch -= 0.1 * math.abs(hit) * e
	pose.HeadRoll += 0.08 * hit * e
	pose.BodyUp += 0.4 * math.abs(hit) * e
	pose.MouthOpen += 0.5 * e
end

-- Lay move `name` on `pose` (unknown names do nothing).
function CalebPartyMoves.Apply(name: string, pose: Pose, u: number, t: number, size: number, side: number)
	local move = moves[name]
	if move then
		move(pose, math.clamp(u, 0, 1), t, size, side)
	end
end

return table.freeze(CalebPartyMoves)
