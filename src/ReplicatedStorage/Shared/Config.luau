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

	-- Everything a player can buy is unlocked step by step: a purchase's button
	-- appears only after the purchase named in its After field is bought
	-- (After = nil: it appears as soon as the plot is claimed). The server
	-- refuses to sell anything whose After is not bought yet. Today's chain:
	--   Dropper1-4 -> Walls -> Stairs -> SecondFloor -> Dropper5-8
	-- Every Id (droppers and builds together) must be unique.

	-- The droppers a player can buy. Entry N uses the plot's DropperSpotN and
	-- BuyButtonN parts, so the map must have one of each per entry
	-- (TycoonService checks this at startup).
	--   Id        - purchase id (tycoon.Purchased[Id]).
	--   Cost      - price, spent through EconomyService.TrySpend. 0 = free.
	--   DropValue - cookies each physical cookie drop from this dropper is worth.
	--   After     - purchase id that unlocks this one (see above).
	--   Conveyor  - plot part the drops land on. Its collector is the part with
	--               "Conveyor" swapped for "Collector" (Conveyor2 -> Collector2).
	Droppers = table.freeze({
		table.freeze({ Id = "Dropper1", Cost = 0, DropValue = 10, After = nil, Conveyor = "Conveyor" }),
		table.freeze({ Id = "Dropper2", Cost = 300, DropValue = 25, After = "Dropper1", Conveyor = "Conveyor" }),
		table.freeze({ Id = "Dropper3", Cost = 1000, DropValue = 60, After = "Dropper2", Conveyor = "Conveyor" }),
		table.freeze({ Id = "Dropper4", Cost = 3000, DropValue = 150, After = "Dropper3", Conveyor = "Conveyor" }),
		-- Second floor (on Conveyor2, above the first conveyor).
		table.freeze({ Id = "Dropper5", Cost = 20000, DropValue = 300, After = "SecondFloor", Conveyor = "Conveyor2" }),
		table.freeze({ Id = "Dropper6", Cost = 35000, DropValue = 450, After = "Dropper5", Conveyor = "Conveyor2" }),
		table.freeze({ Id = "Dropper7", Cost = 60000, DropValue = 700, After = "Dropper6", Conveyor = "Conveyor2" }),
		table.freeze({ Id = "Dropper8", Cost = 100000, DropValue = 1000, After = "Dropper7", Conveyor = "Conveyor2" }),
	}),

	-- Things a player can build. Entry N uses the plot's BuildButtonN part.
	--   Id    - purchase id (tycoon.Purchased[Id]).
	--   Name  - text on the button's sign (the price goes under it).
	--   Cost  - price in cookies.
	--   After - purchase id that unlocks this one (see above).
	--   Parts - plot parts/models that appear once it is built (hidden before).
	Builds = table.freeze({
		table.freeze({ Id = "Walls", Name = "Build Walls", Cost = 5000, After = "Dropper4", Parts = table.freeze({ "Walls" }) }),
		table.freeze({ Id = "Stairs", Name = "Build Stairs", Cost = 8000, After = "Walls", Parts = table.freeze({ "Stairs" }) }),
		table.freeze({
			Id = "SecondFloor",
			Name = "2nd Floor",
			Cost = 15000,
			After = "Stairs",
			Parts = table.freeze({ "SecondFloor", "Conveyor2", "Collector2" }),
		}),
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
