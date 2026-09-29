-- Config
-- Every tunable gameplay number lives here. Change values here, not in services.
--
-- This module is in ReplicatedStorage so the client can READ it (for example,
-- to show a price). The client cannot change the server's copy, and the server
-- never trusts numbers sent by the client.

local Config = {
	-- Cash every player starts each session with.
	StartingCash = 100,

	-- Price of the one dropper a player can buy.
	DropperCost = 100,

	-- Cash value of each physical drop the dropper creates.
	DropValue = 10,

	-- Seconds between drops.
	DropInterval = 2,

	-- Must match the number of Plot models in Workspace.Map.Plots.
	-- TycoonService warns at startup if they differ.
	NumberOfTycoonPlots = 4,

	-- Studs per second a drop moves along the conveyor.
	ConveyorSpeed = 8,

	-- Seconds before a drop that never reached the collector is destroyed.
	-- Prevents lost drops from piling up forever.
	DropLifetime = 30,
}

return table.freeze(Config)
