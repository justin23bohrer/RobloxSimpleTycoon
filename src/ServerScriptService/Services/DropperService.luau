-- DropperService (server only)
-- Runs droppers: creates physical drops on an interval and moves them along
-- the plot's conveyor toward its Collector.
--
-- STATUS: stub. The functions below define the interface TycoonService uses.
--
-- Implementation notes for the next agent:
-- * Start(plot): every Config.DropInterval seconds, create a small Part at
--   plot.DropperSpot, above the start of plot.Conveyor.
-- * Give each drop its value on the SERVER: store it in a server-side table
--   keyed by the part, or as an attribute set by the server. Never read a
--   value the client could have supplied.
-- * Call drop:SetNetworkOwner(nil) after parenting so the server (not a
--   nearby client) simulates the drop's physics.
-- * Move drops by setting plot.Conveyor.AssemblyLinearVelocity to
--   Config.ConveyorSpeed along the conveyor (anchored conveyor, unanchored drops).
-- * Destroy drops after Config.DropLifetime seconds so they cannot pile up.
-- * Tag each drop with its plot so CollectorService only accepts drops from
--   the same plot.
-- * Stop(plot) must stop the loop and destroy that plot's drops.

local DropperService = {}

-- Starts the dropper on a plot. Safe to call only once per plot.
function DropperService.Start(plot: Model)
	warn(`DropperService.Start is not implemented yet (plot {plot.Name})`)
end

-- Stops the dropper on a plot and removes its drops. Safe to call if not running.
function DropperService.Stop(plot: Model)
	-- Not implemented yet. Nothing is running, so there is nothing to stop.
end

return DropperService
