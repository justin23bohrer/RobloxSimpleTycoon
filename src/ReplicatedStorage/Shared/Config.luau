-- Config
-- Every tunable gameplay number lives here. Change values here, not in services.
--
-- This module is in ReplicatedStorage so the client can READ it (for example,
-- to show a price). The client cannot change the server's copy, and the server
-- never trusts numbers sent by the client.

-- Currency: players see "Cookies". In code and here it is called "cash"
-- (StartingCash, DropValue, Cost are all counted in cookies).

local Config = {
	-- Cookies every player starts each session with.
	StartingCash = 100,

	-- The droppers a player can buy, in order: each one unlocks the next. Entry N uses the plot's
	-- DropperSpotN and BuyButtonN parts, so the map must have one of each per
	-- entry (TycoonService checks this at startup).
	--   Id        - purchase id (tycoon.Purchased[Id]); must be unique.
	--   Cost      - price, spent through EconomyService.TrySpend. 0 = free.
	--   DropValue - cookies each physical cookie drop from this dropper is worth.
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

	-- Feeding the statue (StatueService). Players spend cookies on the four
	-- feed pads around the statue; the more Caleb has eaten (all players
	-- together, this server session), the fatter he gets. He stops growing
	-- and stops eating at StatueMaxCookies.
	StatueName = "Caleb",
	StatueMaxCookies = 1_000_000,
	-- How close (studs, flat distance) a player must be to a feed pad's center
	-- for the server to accept a feed.
	StatueFeedRange = 12,
	-- Seconds a player must wait between feeds (anti-spam).
	StatueFeedCooldown = 0.5,

	-- TESTING ONLY. When true, players start with DevStartingCash instead of
	-- StartingCash, but only inside Roblox Studio (RunService:IsStudio()). It
	-- never applies in a published game. Keep this false in commits.
	DevUnlimitedCash = false,
	DevStartingCash = 1_000_000_000,
}

return table.freeze(Config)
