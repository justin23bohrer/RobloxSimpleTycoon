-- PushService (server only)
-- STUB from the House Raid contract (ARCHITECTURE.md "House Raid
-- (contract)"). The Push worker replaces the body; keep this API.
-- Handles the PushRequest remote: finds a target in front of the pusher,
-- validates range/cooldown, knocks back, and stops a thief
-- (TheftService.StopThief).

local PushService = {}

-- Called once by ServerMain.
function PushService.Start() end

function PushService.OnPlayerRemoving(_player: Player) end

return PushService
