-- Config
-- Every tunable gameplay number lives here. Change values here, not in services.
--
-- This module is in ReplicatedStorage so the client can READ it (for example,
-- to show a price). The client cannot change the server's copy, and the server
-- never trusts numbers sent by the client.

local Config = {
	-- Cash every player starts each session with.
	StartingCash = 100,

	-- The droppers a player can buy, in order: each one unlocks the next. Entry N uses the plot's
	-- DropperSpotN and BuyButtonN parts, so the map must have one of each per
	-- entry (TycoonService checks this at startup).
	--   Id        - purchase id (tycoon.Purchased[Id]); must be unique.
	--   Cost      - price, spent through EconomyService.TrySpend. 0 = free.
	--   DropValue - cash value of each physical drop this dropper creates.
	Droppers = table.freeze({
		table.freeze({ Id = "Dropper1", Cost = 0, DropValue = 10 }),
		table.freeze({ Id = "Dropper2", Cost = 300, DropValue = 25 }),
		table.freeze({ Id = "Dropper3", Cost = 1000, DropValue = 60 }),
		table.freeze({ Id = "Dropper4", Cost = 3000, DropValue = 150 }),
	}),

	-- Seconds between drops (shared by all droppers).
	DropInterval = 2,

	-- Must match the number of Plot models in Workspace.Map.Plots.
	-- TycoonService warns at startup if they differ.
	NumberOfTycoonPlots = 1,

	-- Studs per second a drop moves along the conveyor.
	ConveyorSpeed = 8,

	-- Seconds before a drop that never reached the collector is destroyed.
	-- Prevents lost drops from piling up forever.
	DropLifetime = 30,

	-- TESTING ONLY. When true, players start with DevStartingCash instead of
	-- StartingCash, but only inside Roblox Studio (RunService:IsStudio()). It
	-- never applies in a published game. Keep this false in commits.
	DevUnlimitedCash = false,
	DevStartingCash = 1_000_000_000,
}

return table.freeze(Config)
