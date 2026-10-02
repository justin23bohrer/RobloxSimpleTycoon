-- Config
-- Every tunable gameplay number lives here. Change values here, not in services.
--
-- This module is in ReplicatedStorage so the client can READ it (for example,
-- to show a price). The client cannot change the server's copy, and the server
-- never trusts numbers sent by the client.

-- Currency: players see "Cookies". In code and here it is called "cash"
-- (StartingCash, DropValue, Cost are all counted in cookies).

local Config = {
	-- ===================== MUSIC (paste your Roblox audio ids here) =====================
	-- Format: "rbxassetid://123456789" (or just the number). Empty "" = silent.
	-- See tools/audio/README.md "Your music" for how to find an asset id.
	BackgroundMusic = "rbxassetid://139132289200391", -- "Tender Static": loops all game, fades out during the Cookie Party
	CookiePartyStartSound = "rbxassetid://118248543183940", -- "Air Horn": plays once when the Cookie Party starts
	CookiePartyMusic = "rbxassetid://110869546630610", -- "NO PARTY": loops during the 60 s Cookie Party
	BackgroundMusicVolume = 0.3, -- 0..1
	CookiePartyMusicVolume = 0.5, -- 0..1 (swells a little toward the end)
	CookiePartyStartVolume = 0.8, -- 0..1
	MusicFadeSeconds = 1.5, -- background fades back in over this after the party
	MusicSuspenseCutSeconds = 0.3, -- "CALEB IS FULLLL!!!": the background cuts out this fast (suspense, no music while Full)
	PartyMusicDelaySeconds = 1.0, -- silence between the Air Horn and the party music starting
	-- ====================================================================================

	-- Cookies every player starts each session with.
	StartingCash = 100,

	-- Everything a player can buy is unlocked step by step: a purchase's button
	-- appears only after the purchase named in its After field is bought
	-- (After = nil: it appears as soon as the plot is claimed). The server
	-- refuses to sell anything whose After is not bought yet. Today's chain:
	--   Dropper1-4 -> Walls -> Stairs -> SecondFloor -> Dropper5-8
	--                Walls -> TrophyCase (side branch)
	--                SecondFloor -> Bed, Gaming Desk, Shelves + TV, Mini
	--                               Fridge, Ninja Kitchen (any order)
	--                Walls -> Pool, Path, Hangout (TrophyBuilds buttons)
	-- Once the house is MAXED (every Droppers and Builds entry bought), the
	-- TrophyBuilds buttons with no After appear (Garage).
	-- Every Id (droppers, builds and trophy builds together) must be unique.

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
		-- BackDoor: the locked back door to the backyard (BackyardGate).
		-- BackyardFence: the backyard's picket fence, which comes with the walls.
		table.freeze({
			Id = "Walls",
			Name = "Build Walls",
			Cost = 5000,
			After = "Dropper4",
			Parts = table.freeze({ "Walls", "BackDoor", "BackyardFence" }),
		}),
		table.freeze({ Id = "Stairs", Name = "Build Stairs", Cost = 5000, After = "Walls", Parts = table.freeze({ "Stairs" }) }),
		table.freeze({
			Id = "SecondFloor",
			Name = "2nd Floor",
			Cost = 10000,
			After = "Stairs",
			Parts = table.freeze({ "SecondFloor", "Conveyor2", "Collector2" }),
		}),
		-- Shows the owner's Caleb Trophies (TrophyService). Its model holds
		-- TrophySlot1..TrophySlotN (N = TrophyCaseSlots).
		table.freeze({ Id = "TrophyCase", Name = "Trophy Case", Cost = 7500, After = "Walls", Parts = table.freeze({ "TrophyCase" }) }),
		-- Second-floor furniture (tools/furniture/generate_furniture.py). All
		-- unlock with the 2nd Floor, together with Dropper 5, so they can be
		-- bought in any order alongside the second-floor droppers. Names are
		-- RichText on the button sign: no "&" or "<".
		table.freeze({ Id = "Bed", Name = "Bed", Cost = 12000, After = "SecondFloor", Parts = table.freeze({ "Bed" }) }),
		table.freeze({ Id = "GamingDesk", Name = "Gaming Desk", Cost = 25000, After = "SecondFloor", Parts = table.freeze({ "GamingDesk" }) }),
		table.freeze({ Id = "ShelvesTV", Name = "Shelves + TV", Cost = 18000, After = "SecondFloor", Parts = table.freeze({ "ShelvesTV" }) }),
		table.freeze({ Id = "MiniFridge", Name = "Mini Fridge", Cost = 8000, After = "SecondFloor", Parts = table.freeze({ "MiniFridge" }) }),
		table.freeze({ Id = "Kitchen", Name = "Ninja Kitchen", Cost = 10000, After = "SecondFloor", Parts = table.freeze({ "KitchenCounter" }) }),
	}),

	-- Garage + Backyard: free builds for Caleb Trophy owners (entry N uses
	-- the plot's TrophyButtonN). Its button appears once the house purchase
	-- named in After is bought, or, with no After, once the house is maxed
	-- (see above). Stepping on one buys it for no cookies if the owner OWNS
	-- at least Trophies Caleb Trophies (inventory count, equipped or not);
	-- trophies are not spent. Saved like other purchases. Any order.
	--   Id       - purchase id (tycoon.Purchased[Id]).
	--   Name     - text on the button's sign ("Must have N Caleb Trophies"
	--              goes under it).
	--   Trophies - Caleb Trophies the owner must own.
	--   After    - optional house purchase id (a Droppers/Builds Id) that
	--              unlocks its button; nil = the house is maxed.
	--   Parts    - plot parts/models that appear once it is built.
	TrophyBuilds = table.freeze({
		table.freeze({ Id = "Garage", Name = "Garage", Trophies = 1, Parts = table.freeze({ "Garage", "GarageCar" }) }),
		-- The backyard pads appear with the Walls (and the BackDoor and
		-- BackyardFence), waiting behind the locked door.
		table.freeze({ Id = "Pool", Name = "Pool", Trophies = 5, After = "Walls", Parts = table.freeze({ "Pool" }) }),
		table.freeze({
			Id = "BackyardPath",
			Name = "Path",
			Trophies = 5,
			After = "Walls",
			Parts = table.freeze({ "BackyardPath" }),
		}),
		table.freeze({
			Id = "Hangout",
			Name = "Fire Pit Hangout",
			Trophies = 5,
			After = "Walls",
			Parts = table.freeze({ "Hangout" }),
		}),
	}),
	-- A plot's BackDoor (the back door to the backyard) stays closed for
	-- everyone until the plot's owner owns this many Caleb Trophies
	-- (BackyardGate). Unclaimed plots are always closed. Only the door is
	-- locked: nobody is pushed out of the yard (walking around the house
	-- before the walls/fence exist, or jumping the fence, is fine).
	BackyardTrophies = 5,

	-- The drivable garage car (CarService, CarBuild, CarSeats). Once a plot's
	-- Garage is built, its car can be driven by the plot's owner (plus one
	-- passenger, anyone). Physics knobs: tune in Studio.
	--   CarMaxSpeed / CarReverseSpeed - top speed forward / backward (studs/s).
	--   CarTorque      - each wheel motor's max torque while driving.
	--   CarBrakeTorque - each wheel motor's torque holding the wheels still
	--                    when nobody presses gas (0 = roll freely).
	--   CarWheelAcceleration - how fast the wheels spin up (rad/s per s);
	--                    lower = gentler starts, fewer wheelies.
	--   CarSteerAngle  - front wheels' max turn (degrees); CarSteerSpeed how
	--                    fast they turn to it (rad/s), with at most
	--                    CarSteerTorque.
	--   CarWheelDensity / CarWheelFriction - tires (heavy tires keep the
	--                    car low and stable; friction 0..2).
	--   CarUprightTorque - a gentle torque that keeps the car's roof up
	--                    (0 = off). Too high and it fights ramps.
	CarMaxSpeed = 60,
	CarReverseSpeed = 25,
	CarTorque = 30_000,
	CarBrakeTorque = 3_000,
	CarWheelAcceleration = 40,
	CarSteerAngle = 30,
	CarSteerSpeed = 4,
	CarSteerTorque = 100_000,
	CarWheelDensity = 4,
	CarWheelFriction = 1.2,
	CarUprightTorque = 150_000,
	-- Getting out (jump): the rider stands beside their door,
	-- CarExitClearance studs past the car's widest point (the mirrors), on
	-- whatever a ray straight down finds there (cast from CarExitRayUp above
	-- the car's Body, reaching CarExitRayDown below the car's bottom),
	-- CarExitHeightMargin above it. CarExitSettleTime seconds later the
	-- server checks once more and re-places a rider who ended up under or in
	-- the car or sunk into the ground.
	CarExitClearance = 2,
	CarExitRayUp = 6,
	CarExitRayDown = 30,
	CarExitHeightMargin = 0.3,
	CarExitSettleTime = 0.3,
	-- CarService checks every car each CarCheckInterval seconds. A car below
	-- CarFallY (the ground's top is y 1), or past the ground's edge and
	-- falling faster than CarFallSpeed, is re-parked in its garage and the
	-- people in it respawn. A car lying on its side/roof, nearly still, for
	-- CarFlippedSeconds is re-parked too (nobody respawns).
	CarCheckInterval = 0.5,
	CarFallY = -20,
	CarFallSpeed = 10,
	CarFlippedSeconds = 4,

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
	-- and stops eating at his goal (CalebCycle):
	--   goal = CalebGoalPerPlayer x players in the server (at least 1),
	--          never more than StatueMaxCookies.
	-- In Normal the goal follows players joining and leaving; it is locked
	-- during Full / Celebration / TrophyClaim and recomputed for each cycle.
	StatueName = "Caleb",
	-- Cookies each player in the server adds to the goal (about 3-4 minutes
	-- of feeding at any server size).
	CalebGoalPerPlayer = 350_000,
	-- The most the goal can ever be (3+ players).
	StatueMaxCookies = 1_000_000,
	-- How close (studs, flat distance) a player must be to a feed pad's center
	-- for the server to accept a feed.
	StatueFeedRange = 12,
	-- Seconds a player must wait between feeds (anti-spam).
	StatueFeedCooldown = 0.5,
	-- While Caleb is not eating (Full, Celebration, TrophyClaim) the feed pads
	-- turn these colors (pad, ring, sign) and the feed pop-up won't open.
	StatueFeedPadOffColor = Color3.fromRGB(150, 150, 150),
	StatueFeedPadOffRingColor = Color3.fromRGB(90, 90, 90),
	StatueFeedPadOffSignColor = Color3.fromRGB(120, 120, 120),
	-- The "Caleb: N / goal" bar floating above the statue (client only,
	-- StatueBar.client.luau). Height is studs above the top of his Head (his
	-- head never grows, so this stays clear of him at any size). Size is in
	-- screen pixels, so it reads the same from near and far. MaxDistance is
	-- studs from the camera (the map is 400 x 400).
	StatueBarHeight = 9,
	StatueBarSize = Vector2.new(300, 80),
	StatueBarMaxDistance = 500,

	-- Caleb Full Event (see Shared/CalebEvent.luau and ARCHITECTURE.md).
	-- When the shared total reaches the goal: Full (his "I'm full"
	-- animation) -> Celebration (dance, cookie rain) -> TrophyClaim (Caleb
	-- hidden, contributors claim a trophy) -> reset to 0 and a new cycle.
	CalebFullSeconds = 5,
	CalebCelebrationSeconds = 60, -- 0:05 -> 1:05
	CalebTrophyClaimSeconds = 120, -- 1:05 -> 3:05
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
	-- arms take turns waving, head bobs, belly jiggles. These are the sizes at
	-- energy 1; the Cookie Party speeds it up and mixes in moves (spins,
	-- throws, ...): see CookiePartyDanceEnergy and CookiePartyCaleb.
	CalebDance = table.freeze({
		BeatSeconds = 0.55,
		SwayDegrees = 9,
		HopHeight = 1.5,
		ArmDegrees = 75,
		ArmWiggleDegrees = 12,
		HeadBobDegrees = 7,
		BellyJiggle = 0.8,
	}),
	-- Podium "CALEB'S TOP FEEDERS" board: how many rows, and the fewest
	-- seconds between leaderboard updates (feeds in between are batched).
	CalebLeaderboardSize = 10,
	CalebLeaderboardInterval = 1,
	-- Cookie rain (client only, visual): most falling cookies alive at once
	-- per client (during the Cookie Party: CookiePartyRainMaxCookies), and
	-- the radius (studs, around the statue) they fall in.
	CookieRainMaxCookies = 120,
	CookieRainRadius = 150,
	-- New cookies per second (times CookiePartyRainRate for the party phase;
	-- fewer if the pool is all in use),
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
	-- tools/audio/ for the original effects to upload. The music and the
	-- party's start sound are in the MUSIC block at the top of this file.
	CalebSounds = table.freeze({
		Full = "rbxassetid://93235179593518",
		Grow = "rbxassetid://110164237125533",
		CookieRain = "rbxassetid://87575437616837",
		TrophyClaim = "rbxassetid://73645199784994",
		EventEnd = "rbxassetid://81676941695748",
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
	CalebPartyBloom = 0.12,
	CalebPartyFadeSeconds = 1.5,
	-- Volume (0..1) of each sound above (CalebAudio.client). CookieRain loops
	-- for the whole Celebration, so keep it quiet; Grow plays on every feed.
	CalebSoundVolumes = table.freeze({
		Full = 0.8,
		Grow = 0.25,
		CookieRain = 0.2,
		TrophyClaim = 0.7,
		EventEnd = 0.5,
	}),
	-- Fewest seconds between two Grow sounds (feeds in between are silent).
	CalebGrowSoundInterval = 0.35,
	-- Tycoon sound effects, same rules as CalebSounds: Roblox asset id
	-- strings, empty = skipped silently. Original effects: tools/audio/out/
	-- (purchase.wav, purchase_build.wav, cant_afford.wav, collect_cookies.wav,
	-- drop_in_jar.wav; see tools/audio/README.md). Played by TycoonSounds
	-- (server): 3D at the plot, heard by players nearby, except CantAfford,
	-- which only the player who touched the button hears.
	--   Purchase       a dropper is bought (at its button)
	--   PurchaseBuild  a house part is built (at its button); empty = uses Purchase
	--   CantAfford     you step on a button you can't afford
	--   Collect        Collect pad payout (pitch rises a little with the payout)
	--   DropInJar      a cookie drop reaches the collector (quiet, at the jar)
	TycoonSounds = table.freeze({
		Purchase = "rbxassetid://96076101525911",
		PurchaseBuild = "rbxassetid://96293552248472",
		CantAfford = "rbxassetid://70416757906686",
		Collect = "rbxassetid://128141289525872",
		DropInJar = "", -- off: the user found the per-drop plink annoying (was rbxassetid://118671085931300)
	}),
	-- Volume (0..1) of each sound above. DropInJar plays often: keep it quiet.
	TycoonSoundVolumes = table.freeze({
		Purchase = 0.4,
		PurchaseBuild = 0.8,
		CantAfford = 0.5,
		Collect = 0.8,
		DropInJar = 0.15,
	}),
	-- Fewest seconds between two CantAfford sounds for one player on one button.
	TycoonCantAffordSoundInterval = 1.5,
	-- At most this many DropInJar plinks per second per plot (the rest are silent).
	TycoonDropSoundsPerSecond = 6,
	-- Collect sound pitch: +PitchPerTenfold for every x10 of the payout above
	-- 10 cookies, up to PitchMax (1 = normal pitch).
	TycoonCollectPitchPerTenfold = 0.05,
	TycoonCollectPitchMax = 1.25,

	-- Cookie Party (CalebState "Celebration", exactly CalebCelebrationSeconds
	-- = 60 s). See Shared/CookieParty.luau and ARCHITECTURE.md "Cookie Party
	-- (contract)". The server (CookiePartyService) decides every collectable
	-- cookie and pays for it; clients only draw them.
	-- Phase boundaries, in seconds LEFT: Start 60..Hype, Hype..Frenzy,
	-- Frenzy..Countdown, Countdown..0.
	CookiePartyPhases = table.freeze({ Hype = 40, Frenzy = 20, Countdown = 10 }),
	-- Cookie types. Value = cookies (cash) paid. CollectRadius = studs
	-- (horizontal) from the player's HumanoidRootPart to the cookie's landing
	-- spot for the server to accept the collect (the client may use a little
	-- less). Weights = relative spawn chance in each phase.
	CookiePartyTypes = table.freeze({
		Normal = table.freeze({
			Value = 50,
			CollectRadius = 6,
			Weights = table.freeze({ Start = 80, Hype = 55, Frenzy = 35, Countdown = 30 }),
		}),
		Chocolate = table.freeze({
			Value = 150,
			CollectRadius = 6,
			Weights = table.freeze({ Start = 20, Hype = 35, Frenzy = 35, Countdown = 32 }),
		}),
		Golden = table.freeze({
			Value = 1_000,
			CollectRadius = 6,
			Weights = table.freeze({ Start = 0, Hype = 8, Frenzy = 25, Countdown = 30 }),
		}),
		Giant = table.freeze({
			Value = 5_000,
			CollectRadius = 10,
			Weights = table.freeze({ Start = 0, Hype = 2, Frenzy = 5, Countdown = 8 }),
		}),
	}),
	-- New collectable cookies per second (whole server) in each phase, plus
	-- this many more per extra player; never more than MaxAlive at once.
	CookiePartySpawnPerSecond = table.freeze({ Start = 4, Hype = 7, Frenzy = 11, Countdown = 15 }),
	CookiePartySpawnPerExtraPlayer = 0.5,
	CookiePartyMaxAlive = 80,
	-- Share (0..1) of collectable cookies Caleb throws out of his mouth (they
	-- arc from his head) instead of falling from the sky.
	CookiePartyFromCalebShare = table.freeze({ Start = 0.15, Hype = 0.25, Frenzy = 0.35, Countdown = 0.4 }),
	-- Where they land: within SpawnRadius studs of the statue; NearPlayerShare
	-- of them within NearPlayerRadius studs of a random player.
	CookiePartySpawnRadius = 140,
	CookiePartyNearPlayerShare = 0.6,
	CookiePartyNearPlayerRadius = 35,
	-- Seconds from spawn to landing (sky and Caleb throws), and seconds a
	-- landed cookie stays collectable before it disappears.
	CookiePartyFallSeconds = 1.6,
	CookiePartyLifetime = 8,
	-- Most collect requests per player per second the server will look at.
	CookiePartyMaxCollectsPerSecond = 12,
	-- Seconds between the server's spawn/expire ticks while the party runs
	-- (CookiePartyService). Each tick's new cookies go out as one batch.
	CookiePartyTickSeconds = 0.25,
	-- Paid to every player in the server when the party ends (the finale).
	CookiePartyFinalReward = 5_000,
	-- Caleb's party dance gets faster/bigger per phase (CalebAnimator):
	-- multipliers on CalebDance's beat speed and move sizes.
	CookiePartyDanceEnergy = table.freeze({ Start = 1, Hype = 1.25, Frenzy = 1.6, Countdown = 2 }),
	-- Caleb at the party (CalebAnimator + CalebPartyPoses/CalebPartyMoves,
	-- client only, looks only). Everything is timed from CalebStateEndsAt,
	-- so every player sees the same move at the same moment.
	--   EnergyRampSeconds: the dance blends into a new phase's energy over
	--     this many seconds (no pop). CountdownEnergy: the Countdown phase's
	--     energy keeps rising to this by the wind-up (faster and faster).
	--   SizeShare: how much of the energy also makes the dance bigger
	--     (0 = only faster, 1 = as much bigger as faster). ArmMaxDegrees: the
	--     dance never swings an arm out further than this.
	--   Moves: a new move may start every MoveEvery[phase] seconds (counted
	--     from the phase's start). It lasts MoveSeconds[move] / MoveSpeed[phase]
	--     (at most MoveEvery) and is MoveSize[phase] times bigger. MoveWeights
	--     [move][phase] = relative chance (0 = never in that phase). The party
	--     always opens with a Laugh.
	--   ShakeDegrees[phase]: a wobble on top of everything ("goes crazy").
	--   CountdownBelly: how much bigger (share) the belly swells during the
	--     Countdown. WindUpSeconds: the "I'M FULL!" wind-up at the very end (no
	--     moves then); its last PeakSeconds are the pop (arms flung wide, head
	--     back, belly PeakBelly bigger, body PeakHeight studs up) landing at 0.
	CookiePartyCaleb = table.freeze({
		EnergyRampSeconds = 1,
		CountdownEnergy = 2.3,
		SizeShare = 0.6,
		ArmMaxDegrees = 150,
		MoveEvery = table.freeze({ Start = 3.5, Hype = 2.4, Frenzy = 1.2, Countdown = 1.8 }),
		MoveSpeed = table.freeze({ Start = 1, Hype = 1.15, Frenzy = 1.5, Countdown = 1.3 }),
		MoveSize = table.freeze({ Start = 1, Hype = 1.2, Frenzy = 1.5, Countdown = 1.35 }),
		MoveSeconds = table.freeze({ Throw = 1.2, Laugh = 1.6, Spin = 1.3, Jump = 1.1, Drum = 1.4 }),
		MoveWeights = table.freeze({
			Throw = table.freeze({ Start = 5, Hype = 5, Frenzy = 4, Countdown = 3 }),
			Laugh = table.freeze({ Start = 4, Hype = 3, Frenzy = 3, Countdown = 4 }),
			Spin = table.freeze({ Start = 1, Hype = 3, Frenzy = 4, Countdown = 1 }),
			Jump = table.freeze({ Start = 1, Hype = 2, Frenzy = 4, Countdown = 1 }),
			Drum = table.freeze({ Start = 2, Hype = 2, Frenzy = 2, Countdown = 4 }),
		}),
		ShakeDegrees = table.freeze({ Start = 0, Hype = 0, Frenzy = 4, Countdown = 3 }),
		CountdownBelly = 0.12,
		WindUpSeconds = 2.5,
		PeakSeconds = 0.3,
		PeakBelly = 0.35,
		PeakHeight = 3,
	}),
	-- Caleb's speech bubbles (CalebPartyBubble.client): a new line every
	-- CookiePartyCalebLineSeconds[phase] seconds (counted from the phase's
	-- start), shown for most of that time, then FinalLine for the last
	-- FinalLineSeconds. Lines play in list order (Start/Hype/Frenzy begin at
	-- a different line each party), so every player sees the same one.
	CookiePartyCalebLines = table.freeze({
		Start = table.freeze({ "I'M SO FULL!!", "COOKIE PARTYYY!", "GRAB 'EM!", "WHEEEE!" }),
		Hype = table.freeze({ "MORE COOKIES!!", "HAHAHAHA", "CATCH!", "YUMMY YUMMY!" }),
		Frenzy = table.freeze({ "GOLDEN COOKIES!!!", "I CAN'T STOP!!", "AAAAAA!", "COOKIES EVERYWHERE!!" }),
		Countdown = table.freeze({ "SOMETHING'S HAPPENING...", "TOO... MANY... COOKIES...", "UH OH..." }),
	}),
	CookiePartyCalebLineSeconds = table.freeze({ Start = 4, Hype = 3, Frenzy = 2, Countdown = 3 }),
	CookiePartyCalebFinalLine = "I'M FULL!!!",
	CookiePartyCalebFinalLineSeconds = 1,
	-- Party sound effects (client only), same rules as CalebSounds: Roblox
	-- asset id strings, empty = skipped. Original effects: tools/audio/. The
	-- party music itself is Config.CookiePartyMusic (MUSIC block at the top).
	CookiePartySounds = table.freeze({
		Collect = "rbxassetid://137978882868933",
		CollectGolden = "rbxassetid://106482616868600",
		CollectGiant = "rbxassetid://87166145037610",
		CountdownTick = "rbxassetid://135083761529590",
		FinaleBoom = "rbxassetid://120290553484245",
		CalebLaugh = "rbxassetid://131547940956663",
		TotalTick = "",
		TotalLand = "",
	}),
	CookiePartySoundVolumes = table.freeze({
		Collect = 0.5,
		CollectGolden = 0.6,
		CollectGiant = 0.7,
		CountdownTick = 0.6,
		FinaleBoom = 0.9,
		CalebLaugh = 0.5,
		TotalTick = 0.4,
		TotalLand = 0.7,
	}),
	-- Per-phase tempo of the party's light/banner pulse (CookiePartyFX). The
	-- party music itself always plays at normal speed: speeding up a real
	-- song raises its pitch too (chipmunk effect).
	CookiePartyMusicSpeed = table.freeze({ Start = 1, Hype = 1.06, Frenzy = 1.12, Countdown = 1.18 }),
	-- Collectable cookies on each client (CookiePartyCookies.client). The
	-- client asks to collect when the player is this many studs inside the
	-- type's CollectRadius, sends at most ClientCollectsPerSecond requests
	-- (keep it under CookiePartyMaxCollectsPerSecond), and gives the server
	-- ClientCollectTimeout seconds to confirm before the cookie goes back and
	-- may be asked for again (one request in flight per cookie, at most
	-- ClientCollectTries requests per cookie in all).
	CookiePartyClientCollectMargin = 1,
	CookiePartyClientCollectsPerSecond = 10,
	CookiePartyClientCollectTimeout = 1,
	CookiePartyClientCollectTries = 3,
	-- Collects this many seconds apart (or closer) grow the "x5 COMBO!"
	-- streak and raise the collect sound's pitch. Presentation only.
	CookiePartyComboSeconds = 1.2,
	-- The visual rain (CookieRain.client) ramps with the party, per phase:
	-- CookieRainPerSecond is multiplied by RainRate, the pool may grow to
	-- RainMaxCookies (keep it ≤ 200: each rain cookie is 6 parts moved every
	-- frame), and RainGoldenShare (0..1) of new rain cookies look golden
	-- (still visual only, not collectable).
	CookiePartyRainRate = table.freeze({ Start = 0.6, Hype = 1, Frenzy = 1.6, Countdown = 2 }),
	CookiePartyRainMaxCookies = table.freeze({ Start = 120, Hype = 120, Frenzy = 160, Countdown = 170 }),
	CookiePartyRainGoldenShare = table.freeze({ Start = 0, Hype = 0.08, Frenzy = 0.2, Countdown = 0.3 }),
	-- Party FX (client only, looks only: CalebEventUI / CookiePartyFX /
	-- CookiePartyFinale / CalebAudio). The party music's tempo (set it to
	-- the song's BPM for an on-beat pulse); the lighting and banner pulse
	-- once every 2 beats, so never more than ~1.2 pulses per second.
	CookiePartyMusicBPM = 120,
	-- Per phase: pulse strength (0..1), seconds between UI confetti bursts,
	-- and pieces per burst (taken from the CalebConfettiCount pool).
	CookiePartyPulse = table.freeze({ Start = 0.15, Hype = 0.45, Frenzy = 0.75, Countdown = 1 }),
	CookiePartyConfettiEvery = table.freeze({ Start = 8, Hype = 5, Frenzy = 3, Countdown = 2 }),
	CookiePartyConfettiPieces = 20,
	-- Added on top of CalebPartySaturation / CalebPartyBloom as the party
	-- goes from 0 to 1 (CookieParty.Intensity).
	CookiePartyExtraSaturation = 0.2,
	CookiePartyExtraBloom = 0.25,
	-- Countdown 10..1: camera FieldOfView punch in degrees (Big = 3, 2, 1).
	CookiePartyCountdownFOVPunch = 2,
	CookiePartyCountdownFOVPunchBig = 4,
	-- Finale explosion (CookiePartyFinale): cookies thrown out of Caleb, how
	-- long it lasts before everything is removed, launch speed range
	-- (studs/s), gravity (studs/s²), and the camera shake.
	CookiePartyFinaleCookies = 48,
	CookiePartyFinaleSeconds = 2.5,
	CookiePartyFinaleSpeedMin = 30,
	CookiePartyFinaleSpeedMax = 65,
	CookiePartyFinaleGravity = 80,
	CookiePartyFinaleShakeStuds = 1.4,
	CookiePartyFinaleShakeSeconds = 0.8,
	-- End-of-party "YOU COLLECTED" card (CookiePartyTotal): count-up length,
	-- and how long it holds after the bonus before flying away (seconds).
	CookiePartyTotalCountSeconds = 1.1,
	CookiePartyTotalHoldSeconds = 1.3,

	-- Saving (DataService, DataStore). Bump the name only to wipe all saves.
	DataStoreName = "SimpleTycoon_v1",
	-- Seconds between autosaves of each player's data.
	DataAutosaveSeconds = 120,
	-- Trophy Case (a build in every house): how many TrophySlotN parts (one
	-- row, each with a NameplateN below it) it has; one per active slot. Keep
	-- equal to SLOTS in tools/trophycase/generate_trophy_case.py.
	TrophyCaseSlots = 5,
	-- Trophy powers (TrophyPowers / PowerService). How many trophies a player
	-- can have equipped (displayed in their Trophy Case) at once; only those
	-- give powers, and only while the TrophyCase build is bought.
	TrophyActiveSlots = 5,
	-- Claim reward: chance (percent) of each rarity, then a trophy of that
	-- rarity (preferring ones the player doesn't own). Server-side only.
	TrophyRarityChances = table.freeze({
		Common = 60,
		Uncommon = 20,
		Rare = 10,
		Epic = 6,
		Legendary = 3,
		Mythic = 1,
	}),
	-- Trophy power totals have no upper limit (duplicates stack too; see
	-- TrophyPowers). Only the chance stats stop at 100%.
	-- Glowing feet while a WalkSpeed trophy is displayed (PowerVisuals, made on
	-- the server so everyone sees it). Each value goes from Min (smallest
	-- bonus) to Max (bonus at TrophySpeedGlowFullAt or more). Brightness/Range
	-- are the PointLight at each foot; Rate is sparkles per second per foot.
	-- Looks only: the speed itself keeps growing past TrophySpeedGlowFullAt.
	TrophySpeedGlowFullAt = 1.5, -- +150% walk speed = full glow (and full trail)
	TrophySpeedGlowColor = Color3.fromRGB(90, 200, 255),
	TrophySpeedGlowBrightnessMin = 1,
	TrophySpeedGlowBrightnessMax = 2.4,
	TrophySpeedGlowRangeMin = 5,
	TrophySpeedGlowRangeMax = 8,
	TrophySpeedGlowRateMin = 8,
	TrophySpeedGlowRateMax = 24,
	-- Fast electric sparks crackling at each foot (per second per foot).
	TrophySpeedGlowEnergyRateMin = 6,
	TrophySpeedGlowEnergyRateMax = 22,
	-- Speed trail: a glowing ribbon behind the player (Trail on the
	-- HumanoidRootPart, built by PowerVisuals). Every client shows it only
	-- while that player runs faster than TrophySpeedTrailMinSpeed (studs/s,
	-- sideways only; normal walking is 16, so it means "running with super
	-- speed"). Colors go from the player (Color) to the tail (ColorEnd).
	-- Min..Max scale with the bonus like the glow (full at
	-- TrophySpeedGlowFullAt). MaxLength (studs) keeps it short enough that it
	-- never reaches your own camera. Opacity 1 = solid, 0 = invisible.
	TrophySpeedTrailMinSpeed = 19,
	TrophySpeedTrailColor = Color3.fromRGB(190, 250, 255),
	TrophySpeedTrailColorEnd = Color3.fromRGB(40, 110, 255),
	TrophySpeedTrailLifetimeMin = 0.25,
	TrophySpeedTrailLifetimeMax = 0.5,
	TrophySpeedTrailMaxLengthMin = 5,
	TrophySpeedTrailMaxLengthMax = 10,
	TrophySpeedTrailOpacityMin = 0.45,
	TrophySpeedTrailOpacityMax = 0.85,
	-- Speed lines that whoosh out behind you when you start sprinting.
	TrophySpeedBurstCount = 12,
	-- Jump looks (JumpHeight trophies): a springy ring on the ground and a
	-- sparkle burst on takeoff, and soft glowing sparkles while in the air.
	-- Min..Max scale with the JumpHeight bonus, full at TrophyJumpLookFullAt
	-- (looks only; the jump has no limit). Ring radius is in studs, burst is
	-- particles per jump, air glow is particles per second.
	TrophyJumpLookFullAt = 1.0, -- +100% jump height = full look
	TrophyJumpLookColor = Color3.fromRGB(110, 255, 170),
	TrophyJumpRingRadiusMin = 3,
	TrophyJumpRingRadiusMax = 6,
	TrophyJumpBurstMin = 10,
	TrophyJumpBurstMax = 26,
	TrophyJumpAirGlowRateMin = 6,
	TrophyJumpAirGlowRateMax = 18,
	-- Double jump (CanDoubleJump): a ring of light and a puff in mid-air when
	-- the air jump fires. Radius in studs, puff in particles.
	TrophyDoubleJumpColor = Color3.fromRGB(255, 170, 60),
	TrophyDoubleJumpRingRadius = 5,
	TrophyDoubleJumpPuffCount = 14,
	-- A "lucky" drop (LuckyCookieChance) is worth this many times its value.
	TrophyLuckyCookieMultiplier = 5,
	-- Fewest seconds between two equip/unequip requests from one player.
	TrophyEquipCooldown = 0.25,
	-- Size of each trophy in the Trophy Case (1 = about 3.8 studs tall with a
	-- hat). The middle riser leaves 7.1 studs under the case's gold valance
	-- and the slots are 4.48 apart, so keep this at 1.6 or less.
	TrophyCaseScale = 1.6,
	-- The big claim trophy on Caleb's pedestal during TrophyClaim
	-- (TrophyService): its size, and its "Claim Caleb Trophy" prompt (studs
	-- from the trophy's base, and seconds to hold the key).
	TrophyPodiumScale = 6,
	TrophyClaimPromptDistance = 22,
	TrophyClaimHoldSeconds = 0.5,
	-- The "NEW TROPHY!" pop-up after a claim (TrophyClaimPopup, client only):
	-- closes by itself after this many seconds; its sound is a Roblox audio
	-- asset id ("rbxassetid://123..."), empty = no sound. (CalebSounds
	-- .TrophyClaim already plays on a claim, so leave this empty unless a
	-- different jingle is wanted.)
	TrophyPopupSeconds = 20,
	TrophyPopupSound = "",
	TrophyPopupVolume = 0.6,

	-- TESTING ONLY (Studio only, like DevUnlimitedCash): a fast Caleb cycle.
	-- Goal DevCalebFastMaxCookies (fixed, not scaled by players); Full 3 s, Celebration 60 s, TrophyClaim
	-- 30 s (see CalebEvent.Duration; the Cookie Party always lasts the full
	-- CalebCelebrationSeconds). Keep this false in commits.
	DevCalebFastCycle = false,
	DevCalebFastMaxCookies = 1_000,

	-- TESTING ONLY. When true, players start with DevStartingCash instead of
	-- StartingCash, but only inside Roblox Studio (RunService:IsStudio()). It
	-- never applies in a published game. Keep this false in commits.
	DevUnlimitedCash = false,
	DevStartingCash = 1_000_000_000,

	-- TESTING ONLY. When true, every player gets DevAllTrophiesCopies copies
	-- of every collectable trophy (Weight > 0) once their data load finishes,
	-- but only inside Roblox Studio (RunService:IsStudio()). They are
	-- session only (never saved) and not auto-equipped (see DevTrophies). It
	-- never applies in a published game. Keep this false in commits.
	DevAllTrophies = false,
	DevAllTrophiesCopies = 5,

	-- TESTING ONLY. Photo Mode for icon / thumbnail screenshots, only inside
	-- Roblox Studio (RunService:IsStudio()); it never applies in a published
	-- game. When true: each player gets the first free plot fully built for
	-- free (every dropper, build and trophy build, back door open: dev
	-- trophies are given as with DevAllTrophies), NOTHING is loaded or saved
	-- to the DataStore all session, the time of day is DevPhotoClockTime,
	-- and keys 1-6 / 0 / H move the camera and hide the UI (PhotoCamera).
	-- See README "Taking icon / thumbnail screenshots". Camera presets are in
	-- Shared/PhotoMode. Keep this false in commits.
	DevPhotoMode = false,
	DevPhotoClockTime = 14, -- Lighting.ClockTime in Photo Mode (14 = 2 pm, bright sun)
}

return table.freeze(Config)
