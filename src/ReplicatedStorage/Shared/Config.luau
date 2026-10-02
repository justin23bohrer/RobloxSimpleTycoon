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
	--                Walls -> TrophyCase (side branch)
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
	-- While Caleb is not eating (Full, Celebration, TrophyClaim) the feed pads
	-- turn these colors (pad, ring, sign) and the feed pop-up won't open.
	StatueFeedPadOffColor = Color3.fromRGB(150, 150, 150),
	StatueFeedPadOffRingColor = Color3.fromRGB(90, 90, 90),
	StatueFeedPadOffSignColor = Color3.fromRGB(120, 120, 120),
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
	CalebPartyBloom = 0.12,
	CalebPartyFadeSeconds = 1.5,
	-- Volume (0..1) of each sound above (CalebAudio.client). CookieRain loops
	-- for the whole Celebration, so keep it quiet; Grow plays on every feed.
	CalebSoundVolumes = table.freeze({
		Full = 0.8,
		CelebrationStart = 0.7,
		Grow = 0.25,
		CookieRain = 0.2,
		TrophyClaim = 0.7,
		EventEnd = 0.5,
	}),
	-- Fewest seconds between two Grow sounds (feeds in between are silent).
	CalebGrowSoundInterval = 0.35,

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
	-- Share (0..1) of collectable cookies Caleb throws / spits out of his
	-- mouth (they arc from his head) instead of falling from the sky.
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
	-- Party sounds (client only), same rules as CalebSounds: Roblox asset id
	-- strings, empty = skipped. Music loops for the whole party and speeds up
	-- per phase (CookiePartyMusicSpeed). Original effects: tools/audio/.
	CookiePartySounds = table.freeze({
		Music = "",
		Collect = "",
		CollectGolden = "",
		CollectGiant = "",
		CountdownTick = "",
		FinaleBoom = "",
		CalebLaugh = "",
		CalebSpit = "",
	}),
	CookiePartySoundVolumes = table.freeze({
		Music = 0.4,
		Collect = 0.5,
		CollectGolden = 0.6,
		CollectGiant = 0.7,
		CountdownTick = 0.6,
		FinaleBoom = 0.9,
		CalebLaugh = 0.5,
		CalebSpit = 0.4,
	}),
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
	-- CookiePartyFinale / CalebAudio). The music's tempo at PlaybackSpeed 1
	-- (tools/audio party_music.wav); the lighting and banner pulse once every
	-- 2 beats, so never more than ~1.2 pulses per second.
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

	-- Saving (DataService, DataStore). Bump the name only to wipe all saves.
	DataStoreName = "SimpleTycoon_v1",
	-- Seconds between autosaves of each player's data.
	DataAutosaveSeconds = 120,
	-- Trophy Case (a build in every house): how many TrophySlotN parts it has
	-- (two rows of 5; only the first TrophyActiveSlots are used for now). Keep
	-- equal to SLOTS in tools/trophycase/generate_trophy_case.py.
	TrophyCaseSlots = 10,
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
	-- Most a stat's total bonus can reach (see TrophyPowers for stacking).
	TrophyStatCaps = table.freeze({
		CookieMultiplier = 2, -- at most 3x cookies
		DropperSpeed = 1, -- at most 2x drop rate
		ExtraCookieChance = 0.5,
		LuckyCookieChance = 0.25,
		CollectBonus = 0.5,
		WalkSpeed = 0.5,
		JumpHeight = 1,
		DoubleJump = 1,
	}),
	-- A "lucky" drop (LuckyCookieChance) is worth this many times its value.
	TrophyLuckyCookieMultiplier = 5,
	-- Fewest seconds between two equip/unequip requests from one player.
	TrophyEquipCooldown = 0.25,
	-- Size of each trophy in the Trophy Case (1 = about 3.8 studs tall with a
	-- hat; each shelf row is 4.9 studs tall, so keep this at 1.2 or less).
	TrophyCaseScale = 1.2,
	-- The big claim trophy on Caleb's pedestal during TrophyClaim
	-- (TrophyService): its size, and its "Claim Caleb Trophy" prompt (studs
	-- from the trophy's base, and seconds to hold the key).
	TrophyPodiumScale = 6,
	TrophyClaimPromptDistance = 22,
	TrophyClaimHoldSeconds = 0.5,

	-- TESTING ONLY (Studio only, like DevUnlimitedCash): a fast Caleb cycle.
	-- Goal DevCalebFastMaxCookies; Full 3 s, Celebration 60 s, TrophyClaim
	-- 30 s (see CalebEvent.Duration; the Cookie Party always lasts the full
	-- CalebCelebrationSeconds). Keep this false in commits.
	DevCalebFastCycle = false,
	DevCalebFastMaxCookies = 1_000,

	-- TESTING ONLY. When true, players start with DevStartingCash instead of
	-- StartingCash, but only inside Roblox Studio (RunService:IsStudio()). It
	-- never applies in a published game. Keep this false in commits.
	DevUnlimitedCash = false,
	DevStartingCash = 1_000_000_000,
}

return table.freeze(Config)
