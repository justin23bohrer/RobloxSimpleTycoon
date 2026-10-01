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
	NumberOfTycoonPlots = 4,

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
	-- The "Caleb: N / 1,000,000" bar floating above the statue (client only,
	-- StatueBar.client.luau). Height is studs above the top of his Head (his
	-- head never grows, so this stays clear of him at any size). Size is in
	-- screen pixels, so it reads the same from near and far. MaxDistance is
	-- studs from the camera (the map is 300 x 300).
	StatueBarHeight = 9,
	StatueBarSize = Vector2.new(300, 80),
	StatueBarMaxDistance = 500,

	-- Caleb Full Event (see Shared/CalebEvent.luau and ARCHITECTURE.md).
	-- When the shared total reaches StatueMaxCookies: Full (his "I'm full"
	-- animation) -> Celebration (dance, cookie rain) -> TrophyClaim (Caleb
	-- hidden, contributors claim a trophy) -> reset to 0 and a new cycle.
	CalebFullSeconds = 5,
	CalebCelebrationSeconds = 115, -- 0:05 -> 2:00
	CalebTrophyClaimSeconds = 300, -- 2:00 -> 7:00
	-- Caleb's overall size: MinScale at 0 cookies, MaxScale at the goal,
	-- smooth in between (on top of the existing fatness). Scaled around the
	-- top of the pedestal, so his feet stay on it. Seconds = growth tween.
	CalebMinScale = 1,
	CalebMaxScale = 1.6,
	CalebGrowSeconds = 1.2,
	-- Growth curves (StatueShape, progress = cookies / goal, 0..1):
	--   fatness = log(1 + progress * FatnessCurve) / log(1 + FatnessCurve)
	--     (front-loaded: the first feeds show; bigger = more front-loaded)
	--   scale = MinScale + (MaxScale - MinScale - FinalPopScale) * progress ^ ScaleCurve
	--     below the goal, and exactly MaxScale at the goal (a last visible pop).
	CalebFatnessCurve = 100_000,
	CalebScaleCurve = 2,
	CalebFinalPopScale = 0.1,
	-- Caleb's animations (CalebAnimator.client, client only, looks only).
	-- Degrees are angles; Height/Bounce/Jiggle are studs.
	-- Full: "I'm completely full" over CalebEvent.Duration("Full") seconds:
	-- a waddle that dies down, leaning back with arms out, belly bouncing,
	-- then a puff (burp) at PuffAt (0..1 of the way through) and his head
	-- jolts back.
	CalebFullAnim = table.freeze({
		WobbleDegrees = 7,
		WobblesPerSecond = 2.5,
		LeanBackDegrees = 12,
		ArmsOutDegrees = 40,
		BellyBounce = 1.6,
		BellyBouncesPerSecond = 2,
		PuffAt = 0.55,
		HeadJoltDegrees = 14,
		PuffParticles = 30,
	}),
	-- Celebration: a dance loop. One sway to a side and one hop per beat,
	-- arms take turns waving, head bobs, belly jiggles, and a full spin every
	-- SpinEverySeconds (lasting SpinSeconds).
	CalebDance = table.freeze({
		BeatSeconds = 0.55,
		SwayDegrees = 9,
		HopHeight = 1.5,
		ArmDegrees = 75,
		ArmWiggleDegrees = 12,
		HeadBobDegrees = 7,
		BellyJiggle = 0.8,
		SpinEverySeconds = 8,
		SpinSeconds = 1.2,
	}),
	-- Podium "CALEB'S TOP FEEDERS" board: how many rows, and the fewest
	-- seconds between leaderboard updates (feeds in between are batched).
	CalebLeaderboardSize = 10,
	CalebLeaderboardInterval = 1,
	-- Cookie rain (client only, visual): most falling cookies alive at once
	-- per client, and the radius (studs, around the statue) they fall in.
	CookieRainMaxCookies = 120,
	CookieRainRadius = 150,
	-- New cookies per second (fewer if CookieRainMaxCookies are all in use),
	-- fall speed (studs/s), height above the landing spot they start at
	-- (studs), and spin (radians/s); each cookie varies these a little.
	CookieRainPerSecond = 25,
	CookieRainFallSpeed = 30,
	CookieRainHeight = 80,
	CookieRainSpinSpeed = 3,
	-- Share (0..1) of cookies aimed within NearPlayerRadius studs of the local
	-- player, so everyone sees plenty around them; the rest fall anywhere.
	CookieRainNearPlayerShare = 0.6,
	CookieRainNearPlayerRadius = 45,
	-- Sound effects (client only). Each is a Roblox audio asset id string
	-- ("rbxassetid://123..."). Empty = that sound is skipped. See
	-- tools/audio/ for the original effects to upload. Music comes later.
	CalebSounds = table.freeze({
		Full = "",
		CelebrationStart = "",
		Grow = "",
		CookieRain = "",
		TrophyClaim = "",
		EventEnd = "",
	}),
	-- Event UI + screen effects (client only, CalebEventUI.client.luau).
	-- TickSeconds: how often the countdowns refresh. ConfettiCount: pooled
	-- UI confetti pieces per burst (capped at 100). Shake: camera shake
	-- strength (studs) and length when Caleb gets full. ClosedMessage: how
	-- long "TROPHY CLAIM CLOSED" stays. Party*: Celebration lighting
	-- (ColorCorrection saturation, Bloom intensity, fade in/out seconds).
	CalebUITickSeconds = 0.25,
	CalebConfettiCount = 60,
	CalebShakeStuds = 0.6,
	CalebShakeSeconds = 0.5,
	CalebClosedMessageSeconds = 4,
	CalebPartySaturation = 0.25,
	CalebPartyBloom = 0.4,
	CalebPartyFadeSeconds = 1.5,

	-- Saving (DataService, DataStore). Bump the name only to wipe all saves.
	DataStoreName = "SimpleTycoon_v1",
	-- Seconds between autosaves of each player's data.
	DataAutosaveSeconds = 120,
	-- Trophy Case (a build in every house): how many trophies it shows.
	TrophyCaseSlots = 5,

	-- TESTING ONLY (Studio only, like DevUnlimitedCash): a fast Caleb cycle.
	-- Goal DevCalebFastMaxCookies; Full 3 s, Celebration 20 s, TrophyClaim
	-- 30 s (see CalebEvent.Duration). Keep this false in commits.
	DevCalebFastCycle = false,
	DevCalebFastMaxCookies = 1_000,

	-- TESTING ONLY. When true, players start with DevStartingCash instead of
	-- StartingCash, but only inside Roblox Studio (RunService:IsStudio()). It
	-- never applies in a published game. Keep this false in commits.
	DevUnlimitedCash = false,
	DevStartingCash = 1_000_000_000,
}

return table.freeze(Config)
