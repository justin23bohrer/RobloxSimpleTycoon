-- CalebPartyPoses (client only)
-- Pure math for CalebAnimator.client: Caleb's pose at a moment of the
-- 60-second Cookie Party (CalebState "Celebration"). Reads Config and
-- changes nothing. Everything is a function of `elapsed` (seconds into the
-- party, from CalebStateEndsAt) and the party's seed (from CalebCycleId), so
-- every player, including a late joiner, sees the same pose at the same time.
--
--   * Dance energy (Config.CookiePartyDanceEnergy per phase) is a smooth
--     curve: it ramps into each phase's value over EnergyRampSeconds, and in
--     Countdown keeps rising to CountdownEnergy. The beat is the curve's
--     integral (seconds x speed added up), worked out exactly, so changing
--     speed never jumps the dance and every client is on the same beat.
--   * Moves (CalebPartyMoves) start on a per-phase grid (MoveEvery); which
--     move is a weighted pick from hash(seed, slot), never the same move
--     twice in a row. A move never runs past its phase's end or into the
--     wind-up. The schedule is worked out once per party (per seed).
--   * Frenzy/Countdown add a shake; Countdown swells the belly.
--   * The last WindUpSeconds: the "I'M FULL!" wind-up (crouch, arms in,
--     trembling, belly puffing faster), ending in the pop at elapsed = the
--     party's length (time left 0), which is held until the state changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)
local CalebPoses = require(script.Parent:WaitForChild("CalebPoses"))
local CalebPartyMoves = require(script.Parent:WaitForChild("CalebPartyMoves"))

type Pose = CalebPoses.Pose

local TAU = CalebPoses.TAU
local smooth = CalebPoses.Smooth
local c = Config.CookiePartyCaleb

local CalebPartyPoses = {}

local DURATION = Config.CalebCelebrationSeconds
local PHASES = CookieParty.PhaseOrder
local FIRST_MOVE = "Laugh" -- the party always opens with a big laugh
local WIND_UP_AT = DURATION - c.WindUpSeconds

-- Elapsed seconds at which each phase starts, and its index.
local phaseStart: { [string]: number } = { Start = 0 }
local phaseIndex: { [string]: number } = {}
for i, name in PHASES do
	phaseIndex[name] = i
	if i > 1 then
		phaseStart[name] = DURATION - Config.CookiePartyPhases[name]
	end
end

-- Where a phase's moves must have finished.
local function phaseEnd(phase: string): number
	local nextPhase = PHASES[phaseIndex[phase] + 1]
	return math.min(if nextPhase then phaseStart[nextPhase] else DURATION, WIND_UP_AT)
end

-- Curves ---------------------------------------------------------------------

-- Knots { {elapsed, value} } of a piecewise-linear curve that holds each
-- phase's value and ramps into the next one over EnergyRampSeconds from that
-- phase's start; after Countdown starts it heads to `final` by the wind-up.
local function phaseCurve(values: { [string]: number }, final: number): { { number } }
	local knots = { { 0, values.Start } }
	for i = 2, #PHASES do
		local at = phaseStart[PHASES[i]]
		table.insert(knots, { at, values[PHASES[i - 1]] })
		table.insert(knots, { at + c.EnergyRampSeconds, values[PHASES[i]] })
	end
	local last = knots[#knots][1]
	table.insert(knots, { math.max(WIND_UP_AT, last + 0.01), final })
	table.insert(knots, { DURATION + 3600, final })
	return knots
end

local function valueAt(knots: { { number } }, x: number): number
	for i = 2, #knots do
		local a, b = knots[i - 1], knots[i]
		if x <= b[1] then
			return a[2] + (b[2] - a[2]) * math.clamp((x - a[1]) / math.max(b[1] - a[1], 1e-6), 0, 1)
		end
	end
	return knots[#knots][2]
end

-- The area under the curve from 0 to x.
local function integral(knots: { { number } }, x: number): number
	local sum = 0
	for i = 2, #knots do
		local a, b = knots[i - 1], knots[i]
		if x <= a[1] then
			break
		end
		local to = math.min(x, b[1])
		sum += (to - a[1]) * (a[2] + valueAt(knots, to)) / 2
	end
	return sum
end

local energyCurve = phaseCurve(Config.CookiePartyDanceEnergy, c.CountdownEnergy)
local shakeCurve = phaseCurve(c.ShakeDegrees, c.ShakeDegrees.Countdown)

-- Deterministic picks ---------------------------------------------------------

-- A number for a party (the same on every client), from its CalebCycleId.
function CalebPartyPoses.Seed(cycleId: string?): number
	local h = 7
	for i = 1, #(cycleId or "") do
		h = (h * 31 + string.byte(cycleId :: string, i)) % 0x100000000
	end
	return h
end

-- A well-mixed 32-bit integer from (seed, n). Integer-only math, so every
-- client gets the same answer.
local function hash(seed: number, n: number): number
	local x = bit32.bxor(seed, (n * 0x45D9F3B) % 0x100000000, 0x9E3779B9)
	for _ = 1, 3 do
		x = bit32.bxor(x, bit32.lshift(x, 13))
		x = bit32.bxor(x, bit32.rshift(x, 17))
		x = bit32.bxor(x, bit32.lshift(x, 5))
	end
	return x
end

local function pick(seed: number, key: number, phase: string, skip: string?): string?
	local total = 0
	for _, name in CalebPartyMoves.Names do
		if name ~= skip then
			total += c.MoveWeights[name][phase] or 0
		end
	end
	if total <= 0 then
		return nil
	end
	local r = (bit32.rshift(hash(seed, key), 8) % 100000) / 100000 * total
	for _, name in CalebPartyMoves.Names do
		if name ~= skip then
			r -= c.MoveWeights[name][phase] or 0
			if r < 0 then
				return name
			end
		end
	end
	return nil
end

type Move = { Name: string, Start: number, Duration: number, Size: number, Side: number }

-- The whole party's moves for a seed, in time order: on each phase's grid
-- (MoveEvery), a weighted pick that is never the same as the move before.
-- A move that would run past its phase's end or into the wind-up is dropped.
local function buildSchedule(seed: number): { Move }
	local schedule: { Move } = {}
	local previous: string? = nil
	for i, phase in PHASES do
		local every = c.MoveEvery[phase]
		local slot = 0
		while phaseStart[phase] + slot * every < phaseEnd(phase) do
			local key = i * 1000 + slot
			local name = if i == 1 and slot == 0 then FIRST_MOVE else pick(seed, key, phase, previous)
			local start = phaseStart[phase] + slot * every
			if name then
				local duration = math.min(c.MoveSeconds[name] / c.MoveSpeed[phase], every)
				if start + duration <= phaseEnd(phase) then
					local side = if bit32.extract(hash(seed, key + 500), 20) == 0 then 1 else -1
					table.insert(schedule, { Name = name, Start = start, Duration = duration, Size = c.MoveSize[phase], Side = side })
					previous = name
				end
			end
			slot += 1
		end
	end
	return schedule
end

local cachedSeed: number? = nil
local cachedSchedule: { Move } = {}

-- The move playing at `elapsed`, or nil.
local function moveAt(elapsed: number, seed: number): Move?
	if seed ~= cachedSeed then
		cachedSeed = seed
		cachedSchedule = buildSchedule(seed)
	end
	for _, move in cachedSchedule do
		if elapsed < move.Start then
			return nil
		elseif elapsed < move.Start + move.Duration then
			return move
		end
	end
	return nil
end

-- Poses ------------------------------------------------------------------------

-- The "I'M FULL!" wind-up, v = 0..1 through it; s = seconds into it.
local function windUp(v: number, s: number): Pose
	local pose = CalebPoses.Rest()
	local peakAt = 1 - c.PeakSeconds / c.WindUpSeconds
	local x = math.clamp((v - peakAt) / (1 - peakAt), 0, 1)
	local pop = 1 - (1 - x) ^ 3 -- fast out, settling exactly on the peak at 0
	local hold = smooth(v / 0.3) * (1 - pop) -- crouched, holding it in
	local tremble = math.rad(1 + 4 * v) * (1 - 0.7 * pop)
	local a, b = math.sin(TAU * 17 * s), math.sin(TAU * 13 * s + 0.7)
	-- Puffing 2/s at the start, 8/s at the end (phase = integral of the rate).
	local puffing = math.sin(TAU * (2 * s + 3 * s * s / c.WindUpSeconds))

	pose.BodyUp = -0.4 * hold + c.PeakHeight * pop
	pose.BodyPitch = -0.15 * hold + 0.2 * pop + tremble * b
	pose.BodyRoll = tremble * a
	pose.HeadPitch = -0.2 * hold + 0.5 * pop
	pose.HeadRoll = tremble * b
	-- Arms hug the belly, then fling wide.
	pose.RightArm = -0.05 * hold + 2.6 * pop
	pose.LeftArm = pose.RightArm
	pose.RightArmFwd = 0.6 * hold + 0.15 * pop
	pose.LeftArmFwd = pose.RightArmFwd
	pose.BellyScale = 1 + c.CountdownBelly + (0.08 * v + 0.04 * v * puffing) * (1 - pop) + c.PeakBelly * pop
	pose.BellyForward = pop
	pose.Cheeks = 1.3 * hold + 0.4 * pop
	pose.MouthOpen = 2.2 * pop
	return pose
end

-- Caleb's pose `elapsed` seconds into the party with this seed.
function CalebPartyPoses.Pose(elapsed: number, seed: number): Pose
	local e = math.clamp(elapsed, 0, DURATION)
	local beatSeconds = Config.CalebDance.BeatSeconds
	local energy = valueAt(energyCurve, e)
	local size = 1 + (energy - 1) * c.SizeShare
	local pose = CalebPoses.Dance(integral(energyCurve, e) / beatSeconds, size, smooth(e / beatSeconds))
	local armMax = math.rad(c.ArmMaxDegrees)
	pose.RightArm = math.min(pose.RightArm, armMax)
	pose.LeftArm = math.min(pose.LeftArm, armMax)

	local move = moveAt(e, seed)
	if move then
		local t = e - move.Start
		CalebPartyMoves.Apply(move.Name, pose, t / move.Duration, t, move.Size, move.Side)
	end

	-- Countdown: the belly swells and jiggles more and more.
	local k = math.clamp((e - phaseStart.Countdown) / math.max(WIND_UP_AT - phaseStart.Countdown, 0.1), 0, 1)
	if k > 0 then
		pose.BellyScale += c.CountdownBelly * smooth(k) + 0.04 * k * math.abs(math.sin(TAU * 3 * e))
		pose.BellyForward += 0.8 * k * math.abs(math.sin(TAU * 2.5 * e))
	end

	-- Frenzy/Countdown: going crazy, a wobble on top of everything.
	local shake = math.rad(valueAt(shakeCurve, e))
	if shake > 0 then
		local a = 0.6 * math.sin(TAU * 9 * e) + 0.4 * math.sin(TAU * 14.3 * e + 1.3)
		local b = 0.6 * math.sin(TAU * 11.7 * e + 0.4) + 0.4 * math.sin(TAU * 6.1 * e)
		pose.BodyRoll += shake * a
		pose.BodyPitch += shake * 0.5 * b
		pose.HeadYaw += shake * 1.5 * b
		pose.HeadRoll += shake * a
	end

	if e > WIND_UP_AT then
		local s = e - WIND_UP_AT
		local target = windUp(s / c.WindUpSeconds, s)
		CalebPoses.Blend(pose, target, smooth(s / 0.4))
		pose.Puff, pose.Spit, pose.Laugh = false, false, false
	end
	return pose
end

return table.freeze(CalebPartyPoses)
