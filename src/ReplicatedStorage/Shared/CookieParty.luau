-- CookieParty (shared: server and client)
-- The contract for the 60-second Cookie Party (CalebState "Celebration"):
-- cookie types, phase names, remote names, the spawn record the server
-- sends, and timing helpers. It decides nothing and changes nothing; the
-- server's CookiePartyService owns the real collectable cookies and rewards.
--
-- Timeline (seconds LEFT in Celebration, Config.CookiePartyPhases):
--   Start      60..40  Caleb celebrates, rain begins, mostly Normal cookies
--   Hype       40..20  more cookies, more valuable, Caleb more energetic
--   Frenzy     20..10  heavy rain, lots of Golden, Caleb goes crazy
--   Countdown  10..0   big 10..1 countdown, everything peaks
--   (0)        finale: the server pays the final reward and CalebCycle moves
--              to TrophyClaim; clients play the explosion on that change.
-- Celebration always lasts Config.CalebCelebrationSeconds (60), even with
-- DevCalebFastCycle, so these phases are always real seconds.
--
-- See ARCHITECTURE.md "Cookie Party (contract)".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CalebEvent = require(script.Parent.CalebEvent)
local Config = require(script.Parent.Config)

local CookieParty = {}

-- Cookie types, cheapest first. Values/weights/radii are in
-- Config.CookiePartyTypes[type].
CookieParty.Types = table.freeze({ "Normal", "Chocolate", "Golden", "Giant" })

CookieParty.Phase = table.freeze({
	Start = "Start",
	Hype = "Hype",
	Frenzy = "Frenzy",
	Countdown = "Countdown",
})
CookieParty.PhaseOrder = table.freeze({ "Start", "Hype", "Frenzy", "Countdown" })

-- RemoteEvents in ReplicatedStorage.Remotes.
CookieParty.Remote = table.freeze({
	-- server -> all clients: (spawns: { Spawn }) a batch of new collectable cookies
	Spawn = "CookiePartySpawn",
	-- client -> server: (id: number) "I touched this cookie" (untrusted)
	Collect = "CookiePartyCollect",
	-- server -> all clients: (id: number, userId: number, value: number, cookieType: string)
	-- a cookie was collected (or id with userId 0 = it expired / was removed)
	Collected = "CookiePartyCollected",
	-- server -> each player: (reward: number) the final reward just paid
	Finale = "CookiePartyFinale",
})

-- Attributes on each Player. Written only by the server.
CookieParty.PlayerAttr = table.freeze({
	Earned = "CookiePartyEarned", -- number: cookies this player earned from party cookies this party (0 at party start)
	Collected = "CookiePartyCount", -- number: how many party cookies this player collected this party
})

-- One collectable cookie as sent in CookiePartySpawn. Times are
-- Workspace:GetServerTimeNow() values. Position is where it lands (on the
-- ground); clients animate the fall (from the sky, or from Caleb's mouth when
-- FromCaleb) so that it touches down at LandAt.
export type Spawn = {
	Id: number,
	Type: string, -- one of CookieParty.Types
	Position: Vector3,
	LandAt: number,
	ExpiresAt: number,
	FromCaleb: boolean,
}

-- Seconds left in the party (0 when it is not Celebration).
function CookieParty.TimeLeft(statue: Instance): number
	if CalebEvent.GetState(statue) ~= CalebEvent.State.Celebration then
		return 0
	end
	return CalebEvent.TimeLeft(statue)
end

-- The phase for a number of seconds left.
function CookieParty.GetPhase(timeLeft: number): string
	local phases = Config.CookiePartyPhases
	if timeLeft <= phases.Countdown then
		return CookieParty.Phase.Countdown
	elseif timeLeft <= phases.Frenzy then
		return CookieParty.Phase.Frenzy
	elseif timeLeft <= phases.Hype then
		return CookieParty.Phase.Hype
	end
	return CookieParty.Phase.Start
end

-- 0 at the start of the party, 1 at the end (linear). For smooth ramps.
function CookieParty.Intensity(timeLeft: number): number
	local total = Config.CalebCelebrationSeconds
	return math.clamp(1 - timeLeft / total, 0, 1)
end

-- Most studs between a player's HumanoidRootPart and a cookie's landing spot
-- (vertically) for a collect: CookiePartyCollectMaxVertical plus how high the
-- player can jump (Humanoid.JumpHeight, twice with "CanDoubleJump"), at most
-- CookiePartyCollectJumpAllowanceMax more. The server and the client use the
-- same rule (the client asks a little inside it).
function CookieParty.VerticalReach(player: Player, humanoid: Humanoid?): number
	local jump = if humanoid then math.max(0, humanoid.JumpHeight) else 0
	if player:GetAttribute("CanDoubleJump") == true then
		jump *= 2
	end
	return Config.CookiePartyCollectMaxVertical + math.min(jump, Config.CookiePartyCollectJumpAllowanceMax)
end

-- The RemoteEvent with this CookieParty.Remote name (waits for it).
function CookieParty.GetRemote(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name) :: RemoteEvent
end

return table.freeze(CookieParty)
