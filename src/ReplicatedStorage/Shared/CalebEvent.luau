-- CalebEvent (shared: server and client)
-- The contract for the Caleb Full Event: state names, the attributes the
-- server publishes, and timing helpers. It decides nothing and changes
-- nothing; the server's CalebCycle module owns the real state.
--
-- Cycle: Normal -> Full -> Celebration -> TrophyClaim -> (reset) -> Normal.
--   Normal       players feed Caleb; he grows; the leaderboard fills.
--   Full         Caleb just hit the max: "I'm full" animation, big message.
--   Celebration  Caleb dances, cookie rain, VFX, sound.
--   TrophyClaim  Caleb is hidden; contributors claim a trophy on the podium.
-- After TrophyClaim the server resets the total, contributions, and Caleb's
-- size, makes a new cycle id, and goes back to Normal.
--
-- Clients never decide the state. They read the statue's attributes (see
-- Attr) and reconcile to them, including when they join mid-event.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)

local CalebEvent = {}

CalebEvent.State = table.freeze({
	Normal = "Normal",
	Full = "Full",
	Celebration = "Celebration",
	TrophyClaim = "TrophyClaim",
})

-- Attributes on Workspace.Map.Statue. Written only by the server (CalebCycle
-- / StatueService); read by anyone.
CalebEvent.Attr = table.freeze({
	CookiesEaten = "CookiesEaten", -- number: shared total this cycle
	MaxCookies = "CalebMaxCookies", -- number: the goal (CalebEvent.MaxCookies())
	State = "CalebState", -- string: one of CalebEvent.State
	CycleId = "CalebCycleId", -- string: unique id of the current cycle
	StateEndsAt = "CalebStateEndsAt", -- number: Workspace:GetServerTimeNow() when this state ends (0 in Normal)
	TopFeeders = "CalebTopFeeders", -- string: JSON list of { UserId, Name, Cookies }, best first, at most Config.CalebLeaderboardSize
})

-- Attributes on each Player. Written only by the server.
CalebEvent.PlayerAttr = table.freeze({
	Fed = "CalebFed", -- number: cookies this player fed Caleb in the current cycle (restored on rejoin)
	TrophyClaimed = "CalebTrophyClaimed", -- boolean: claimed this cycle's trophy
})

-- Studio-only fast test cycle (Config.DevCalebFastCycle). Never applies in a
-- published game, same rule as DevUnlimitedCash.
local fast = Config.DevCalebFastCycle and RunService:IsStudio()

-- The cookie goal for a cycle.
function CalebEvent.MaxCookies(): number
	return if fast then Config.DevCalebFastMaxCookies else Config.StatueMaxCookies
end

-- Seconds each timed state lasts.
function CalebEvent.Duration(state: string): number
	if state == CalebEvent.State.Full then
		return if fast then 3 else Config.CalebFullSeconds
	elseif state == CalebEvent.State.Celebration then
		return if fast then 20 else Config.CalebCelebrationSeconds
	elseif state == CalebEvent.State.TrophyClaim then
		return if fast then 30 else Config.CalebTrophyClaimSeconds
	end
	return 0
end

-- Seconds left in the statue's current state (0 in Normal or if unknown).
function CalebEvent.TimeLeft(statue: Instance): number
	local endsAt = statue:GetAttribute(CalebEvent.Attr.StateEndsAt)
	if typeof(endsAt) ~= "number" or endsAt <= 0 then
		return 0
	end
	return math.max(0, endsAt - Workspace:GetServerTimeNow())
end

-- The statue's current state ("Normal" if not set yet).
function CalebEvent.GetState(statue: Instance): string
	local state = statue:GetAttribute(CalebEvent.Attr.State)
	return if typeof(state) == "string" and CalebEvent.State[state] then state else CalebEvent.State.Normal
end

-- 0..1 progress toward the goal.
function CalebEvent.Progress(statue: Instance): number
	local eaten = statue:GetAttribute(CalebEvent.Attr.CookiesEaten)
	local max = statue:GetAttribute(CalebEvent.Attr.MaxCookies)
	if typeof(eaten) ~= "number" then
		return 0
	end
	if typeof(max) ~= "number" or max <= 0 then
		max = CalebEvent.MaxCookies()
	end
	return math.clamp(eaten / max, 0, 1)
end

return table.freeze(CalebEvent)
