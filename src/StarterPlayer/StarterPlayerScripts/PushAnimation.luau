-- PushAnimation (client only, ModuleScript)
-- A short two-handed shove, made procedurally (no uploaded animation): for
-- about a quarter second both shoulders swing the arms straight forward and
-- back, blended over whatever the character's Animator is playing. Works on
-- R15 (RightShoulder/LeftShoulder + elbows) and R6 ("Right Shoulder"/"Left
-- Shoulder").
--
-- Motor6D.Transform is local only, so every client animates every pusher
-- itself (Push.client: the local player on press, others on PushFX). It is
-- written in PreSimulation, after the Animator has set this frame's pose.
-- Presentation only.

local RunService = game:GetService("RunService")

local PushAnimation = {}

local DURATION = 0.28 -- seconds
local WINDUP_END = 0.07 -- arms pull back a little...
local THRUST_END = 0.13 -- ...then shoot forward...
local HOLD_END = 0.19 -- ...stay out a moment, then return by DURATION
local WINDUP_ANGLE = math.rad(-25)
local THRUST_ANGLE = math.rad(95)
local R15_ELBOW_BEND = math.rad(35) -- bent during the wind-up, straight at the thrust

type Joint = { Motor: Motor6D, Axis: Vector3, Sign: number, Elbow: boolean }
type Play = { Started: number, Joints: { Joint } }

local playing: { [Model]: Play } = {}
local connection: RBXScriptConnection? = nil

local function motor(parent: Instance?, name: string): Motor6D?
	local found = parent and parent:FindFirstChild(name)
	return if found and found:IsA("Motor6D") then found else nil
end

local function jointsFor(character: Model): { Joint }
	local joints: { Joint } = {}
	local function add(m: Motor6D?, axis: Vector3, sign: number, elbow: boolean)
		if m then
			table.insert(joints, { Motor = m, Axis = axis, Sign = sign, Elbow = elbow })
		end
	end
	local torso = character:FindFirstChild("Torso")
	if torso then
		-- R6: the shoulder joints' frames turn the arm forward around Z.
		add(motor(torso, "Right Shoulder"), Vector3.zAxis, 1, false)
		add(motor(torso, "Left Shoulder"), Vector3.zAxis, -1, false)
	else
		-- R15: around X, +90 degrees points a hanging arm forward.
		add(motor(character:FindFirstChild("RightUpperArm"), "RightShoulder"), Vector3.xAxis, 1, false)
		add(motor(character:FindFirstChild("LeftUpperArm"), "LeftShoulder"), Vector3.xAxis, 1, false)
		add(motor(character:FindFirstChild("RightLowerArm"), "RightElbow"), Vector3.xAxis, 1, true)
		add(motor(character:FindFirstChild("LeftLowerArm"), "LeftElbow"), Vector3.xAxis, 1, true)
	end
	return joints
end

-- (shoulder angle, elbow angle, blend weight) at t seconds.
local function pose(t: number): (number, number, number)
	if t < WINDUP_END then
		local a = t / WINDUP_END
		return WINDUP_ANGLE * a, R15_ELBOW_BEND * a, a
	elseif t < THRUST_END then
		local a = (t - WINDUP_END) / (THRUST_END - WINDUP_END)
		local eased = 1 - (1 - a) ^ 3
		return WINDUP_ANGLE + (THRUST_ANGLE - WINDUP_ANGLE) * eased, R15_ELBOW_BEND * (1 - eased), 1
	elseif t < HOLD_END then
		return THRUST_ANGLE, 0, 1
	end
	local a = math.clamp((t - HOLD_END) / (DURATION - HOLD_END), 0, 1)
	return THRUST_ANGLE, 0, 1 - a * a
end

local function step()
	local now = os.clock()
	for character, play in playing do
		local t = now - play.Started
		local done = t >= DURATION or not character.Parent
		local shoulder, elbow, weight = pose(t)
		for _, joint in play.Joints do
			if joint.Motor.Parent then
				if done then
					joint.Motor.Transform = CFrame.identity -- the Animator rewrites it next frame
				else
					local angle = if joint.Elbow then elbow else shoulder * joint.Sign
					local target = CFrame.fromAxisAngle(joint.Axis, angle)
					joint.Motor.Transform = joint.Motor.Transform:Lerp(target, weight)
				end
			end
		end
		if done then
			playing[character] = nil
		end
	end
	if next(playing) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Plays the shove on this character (restarts it if already playing).
function PushAnimation.Play(character: Model?)
	if not character then
		return
	end
	local joints = jointsFor(character)
	if #joints == 0 then
		return
	end
	playing[character] = { Started = os.clock(), Joints = joints }
	if not connection then
		connection = RunService.PreSimulation:Connect(step)
	end
end

return PushAnimation
