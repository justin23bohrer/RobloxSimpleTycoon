-- TheftService (server only)
-- STUB from the House Raid contract (ARCHITECTURE.md "House Raid
-- (contract)"). The Theft worker replaces the body; keep this API.
-- Owns trophy thefts: the StealPrompt on displayed trophies, the carrying
-- state, extraction at the thief's TrophyStash, the permanent transfer, and
-- every cancel (push, death, leave, ...). Exactly one owner at all times.

local TheftService = {}

-- Called once by ServerMain after TrophyService.Start().
function TheftService.Start() end

-- True while this player carries a stolen trophy.
function TheftService.IsCarrying(_player: Player): boolean
	return false
end

-- A push hit the thief: cancel the theft and return the trophy to its owner's
-- display. Returns true if a theft was cancelled (false if not carrying, or
-- the theft already finished this frame). Called by PushService.
function TheftService.StopThief(_thief: Player, _byPlayer: Player?): boolean
	return false
end

-- True if this trophy instance is being carried right now (not displayed,
-- gives its owner no power until it is back). Used by TrophyService.
function TheftService.IsInTransit(_instanceId: string): boolean
	return false
end

function TheftService.OnPlayerRemoving(_player: Player) end

return TheftService
