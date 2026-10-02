-- HouseSecurityService (server only)
-- STUB from the House Raid contract (ARCHITECTURE.md "House Raid
-- (contract)"). The Security worker replaces the body; keep this API.
-- Owns each plot's security state: the owner steps on the green SecurityPad,
-- the red SecurityBars rise for exactly Config.HouseSecuritySeconds, then
-- drop again. No cooldown.

local HouseSecurityService = {}

-- Called once by ServerMain after TycoonService.Start().
function HouseSecurityService.Start() end

-- True while the plot's bars are up (other players can't enter, no theft).
function HouseSecurityService.IsProtected(_plot: Model): boolean
	return false
end

-- Bars down, pad green, timer cancelled (plot released or reset).
function HouseSecurityService.ResetPlot(_plot: Model) end

return HouseSecurityService
