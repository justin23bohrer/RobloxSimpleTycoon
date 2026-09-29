-- CollectorService (server only)
-- Handles each plot's Collector and CollectPad:
--   1. A drop touching plot.Collector adds its value to that plot's stored
--      (uncollected) cash, then the drop is destroyed.
--   2. The plot's owner touching plot.CollectPad moves the stored cash into
--      their cash via EconomyService.AddCash.
--
-- Named CollectorService (not CollectionService) to avoid confusion with
-- Roblox's built-in game:GetService("CollectionService") tagging service.
--
-- STATUS: stub. The functions below define the interface TycoonService uses.
--
-- Implementation notes for the next agent:
-- * On Collector.Touched, call DropperService.ClaimDrop(hit, plot). It returns
--   the drop's server-side value (or nil for anything that isn't a valid drop
--   from THIS plot). Never read a value from the part itself.
-- * Only pay out if plot:GetAttribute("OwnerUserId") == player.UserId.
-- * Set stored cash to 0 BEFORE paying out so a double touch cannot pay twice.

local CollectorService = {}

-- Connects the Collector and CollectPad touch handlers for a plot. Called once
-- per plot at server start.
function CollectorService.SetupPlot(plot: Model)
	-- Not implemented yet.
end

-- Clears a plot's stored cash (called when the plot is released).
function CollectorService.ResetPlot(plot: Model)
	-- Not implemented yet. No cash is stored, so there is nothing to reset.
end

return CollectorService
