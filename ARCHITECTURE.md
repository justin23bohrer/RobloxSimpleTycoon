# SimpleTycoon Architecture

Small on purpose. Plain ModuleScripts, one server entry script, no frameworks.

## Project structure

```
src/
├── ReplicatedStorage/          → ReplicatedStorage (server + client can read)
│   ├── Shared/
│   │   ├── Config.luau         → ModuleScript: all tunable numbers
│   │   ├── CalebEvent.luau     → Caleb Full Event contract (state names, attributes, timing)
│   │   ├── CalebBody.luau      → which statue parts are Caleb's body (not pedestal/FeedPads/Podium)
│   │   └── TrophyVariants.luau → every Caleb Trophy look (data) + PickVariant
│   └── Remotes/                → Folder: remotes
│       └── FeedStatue.model.json → RemoteFunction: client asks to feed the statue
├── ServerScriptService/        → ServerScriptService (server only)
│   ├── ServerMain.server.luau  → Script: entry point, starts services
│   └── Services/
│       ├── PlayerDataService.luau
│       ├── DataService.luau    → saving: house purchases + trophies (DataStore)
│       ├── DataSchema.luau     → helper for DataService (saved shape, cleaning, migration)
│       ├── EconomyService.luau
│       ├── TycoonService.luau
│       ├── PlotStages.luau     → helper for TycoonService (what a plot shows at each stage)
│       ├── PlotVisibility.luau → helper: hide/show a part or model and restore it
│       ├── BuyButtons.luau     → helper for TycoonService (buy button labels/touches/visibility)
│       ├── Purchases.luau      → read-only catalog of droppers + builds (ids, buttons, unlock order)
│       ├── DropperService.luau
│       ├── DropperCup.luau     → helper for DropperService (builds the red cup dropper)
│       ├── CollectorService.luau
│       ├── CollectorDisplay.luau → helper for CollectorService (cash tank + pad effects)
│       ├── JarCounter.luau     → helper for CollectorDisplay ("🍪 1,250" counter on the cookie jar)
│       ├── PowerService.luau   → active Caleb Trophy powers per player (+ movement)
│       ├── StatueService.luau  → feeding the statue (validates, spends cookies)
│       ├── CalebCycle.luau     → Caleb Full Event state machine (total, contributions, trophy eligibility)
│       ├── CookiePartyService.luau → Cookie Party collectable cookies (server table, no parts) + rewards
│       ├── CookiePartySpawner.luau → helper for CookiePartyService (cookie type + landing spot)
│       ├── StatueShape.luau    → helper: Caleb's fatness + overall scale, and hiding him
│       ├── TrophyService.luau  → Caleb Trophy claim on the podium + Trophy Case display
│       ├── TrophyInventory.luau → helper for TrophyService (owned/equipped, TrophyEquip rules, TrophyInventory attribute)
│       ├── TrophyModel.luau    → helper for TrophyService (builds a trophy Model from a variant)
│       ├── TrophyCaseDisplay.luau → helper for TrophyService (puts trophies on a Trophy Case's slots)
│       └── TrophyAccessories.luau → helper for TrophyModel (hats, glasses, cookie, bow tie)
├── StarterPlayer/
│   └── StarterPlayerScripts/   → client LocalScripts
│       ├── CashDisplay.client.luau → LocalScript: bottom-center cookie counter
│       ├── DoubleJump.client.luau  → LocalScript: Rocket Caleb's air jump (CanDoubleJump)
│       ├── FeedPrompt.client.luau  → LocalScript: "feed Caleb" pop-up logic
│       ├── FeedPromptUI.luau       → ModuleScript: builds the feed pop-up (+ the shared cookie progress bar)
│       ├── StatueBar.client.luau   → LocalScript: progress bar floating above the statue
│       ├── CookieRain.client.luau  → LocalScript: cookie rain during Caleb's Celebration (visual only)
│       ├── CookieRainLook.luau     → ModuleScript: builds a rain cookie (+ golden variant) + the landing puff
│       ├── CookiePartyCookies.client.luau → LocalScript: Cookie Party collectable cookies (draws server spawns, asks to collect)
│       ├── CookiePartyLook.luau    → ModuleScript: builds the 4 collectable cookie looks + ground beacons
│       ├── CookiePartyMotion.luau  → ModuleScript: per-frame fall / throw / bounce / bob / pop / fade math
│       ├── CookiePartyFeedback.luau → ModuleScript: collect burst, puffs, collect sounds
│       ├── CookiePartyNumbers.luau → ModuleScript: pooled floating "+50" numbers
│       ├── CookiePartyHUD.luau     → ModuleScript: party earnings counter "🍪 +12,450" + combo flair
│       ├── CalebEventUI.client.luau → LocalScript: Caleb Full Event screen messages + countdowns
│       ├── CalebEventUIBuild.luau  → ModuleScript: builds the event ScreenGui once
│       ├── CalebEventFX.luau       → ModuleScript: event screen effects (slam, flash, confetti, shake, party lighting)
│       ├── CookiePartyUIBuild.luau → ModuleScript: builds the party countdown / callout / edge glow / bonus toast once
│       ├── CookiePartyFX.luau      → ModuleScript: the Cookie Party's per-frame screen show (phases, banner, lighting ramp, confetti)
│       ├── CookiePartyCountdown.luau → ModuleScript: 10…1 numbers, phase callouts, FOV punch, "+N PARTY BONUS!" toast
│       ├── CookiePartyFinale.luau  → ModuleScript: the finale's 3D cookie explosion (pooled, client-local)
│       ├── CalebAnimator.client.luau → LocalScript: Caleb's "I'm full" animation + Cookie Party dance (from CalebState)
│       ├── CalebPoses.luau         → ModuleScript: the pose math for CalebAnimator (Full, base dance, blend helpers)
│       ├── CalebPartyPoses.luau    → ModuleScript: Caleb's party pose (energy ramp, move schedule, "I'M FULL!" wind-up)
│       ├── CalebPartyMoves.luau    → ModuleScript: the party moves (throw, spit, laugh, spin, jump, belly drum)
│       ├── CalebMouth.luau         → ModuleScript: burp puff, crumb spray, laugh/spit sounds from Caleb's mouth
│       ├── CalebPartyBubble.client.luau → LocalScript: Caleb's speech bubbles during the Cookie Party
│       ├── CalebLeaderboard.client.luau → LocalScript: "CALEB'S TOP FEEDERS" boards on the podium
│       ├── CalebAudio.client.luau  → LocalScript: Caleb Full Event sound effects + Cookie Party music
│       ├── CookiePartyAudio.luau   → ModuleScript: party music, countdown ticks, finale boom (for CalebAudio)
│       ├── TrophyPrompt.client.luau → LocalScript: hides the trophy claim prompt for non-eligible players; claim messages
│       ├── TrophyInventory.client.luau → LocalScript: "🏆 TROPHIES" button + "MY CALEB TROPHIES" panel (equip/unequip)
│       ├── TrophyInventoryUI.luau  → ModuleScript: builds that panel once (+ grid tiles for the pool)
│       ├── TrophyInventoryIcon.luau → ModuleScript: tiny trophy icon drawn from frames, recolored per variant
│       └── TrophyInventoryData.luau → ModuleScript: pure helpers (parse the attributes, sort, powers line)
├── StarterGui/                 → client UI (empty; UI is built by LocalScripts)
└── Workspace/
    └── Map/                    → Folder in Workspace
        ├── Ground.model.json
        ├── SpawnLocation.model.json  → spawn in front of Plot1
        ├── SpawnLocation2-4.model.json → GENERATED by tools/plots/generate_plots.py (do not hand-edit)
        ├── Statue.model.json → GENERATED by tools/statue/generate_statue.py (do not hand-edit)
        └── Plots/
            ├── Plot1.model.json      → the plot everyone edits (its `Walls` and `SecondFloor` children are GENERATED by tools/house/generate_house.py; the furniture models and `BuildButton5`–`9` by tools/furniture/generate_furniture.py; the `TrophyCase` model by tools/trophycase/generate_trophy_case.py)
            └── Plot2-4.model.json    → GENERATED by tools/plots/generate_plots.py: Plot1 turned 90/180/270° around the statue (do not hand-edit)
```

Rojo file naming (important):

| File                 | Becomes in Studio |
| -------------------- | ----------------- |
| `Name.server.luau`   | `Script` (runs on the server) |
| `Name.client.luau`   | `LocalScript` (runs on the client) |
| `Name.luau`          | `ModuleScript` (runs only when required) |
| `Name.model.json`    | Any instance(s) described in JSON |
| folder               | `Folder` |
| `README.md`          | Ignored by Rojo (documentation only) |

`default.project.json` maps each `src/<Service>` folder to that Roblox service.
`Workspace` has `$ignoreUnknownInstances: true` so Rojo does not delete Studio's
own `Camera`/`Terrain`. Every other mapped folder is fully managed by Rojo:
instances added there only in Studio will be removed on sync.

`tools/` is not synced by Rojo. `tools/statue/generate_statue.py` (plain
Python 3, no packages) writes `Statue.model.json`; change the statue by
editing the script and re-running `python3 tools/statue/generate_statue.py`.
`tools/house/generate_house.py` (same idea) rewrites only the `Walls` and
`SecondFloor` children of `Plot1.model.json` (the brick house look); edit the
script and re-run `python3 tools/house/generate_house.py` instead of
hand-editing those parts. Everything else in the plot file is left alone.
`tools/furniture/generate_furniture.py` (same idea) rewrites only the
second-floor furniture models (`Bed`, `GamingDesk`, `ShelvesTV`,
`MiniFridge`, `KitchenCounter`) and their `BuildButton5`–`9`; they are
ordinary builds (`Config.Builds` entries 5–9, `After = "SecondFloor"`), so
no server code knows about them.
`tools/trophycase/generate_trophy_case.py` (same idea) rewrites only the
`TrophyCase` model (in place): the big display cabinet, its sign, its two
warm `SurfaceLight`s (saved disabled; `TrophyCaseDisplay` switches them,
because `PlotVisibility` does not hide lights), and `TrophySlot1`–`N`
(`SLOTS` there must equal `Config.TrophyCaseSlots`). It does not touch
`BuildButton4`.
`tools/plots/generate_plots.py` then copies Plot1 (and the first spawn)
three times, turned around the statue's center, into `Plot2`–`Plot4` (with
`PlotId` 2–4) and `SpawnLocation2`–`4`. **After any change to Plot1 or the
spawn, re-run it**: `python3 tools/house/generate_house.py` (if the house
changed), `python3 tools/furniture/generate_furniture.py` (if the furniture
changed), `python3 tools/trophycase/generate_trophy_case.py` (if the Trophy
Case changed), then `python3 tools/plots/generate_plots.py`.

`tools/audio/generate_sfx.py` (plain Python 3 standard library) synthesizes
the original Caleb Full Event sound effects into `tools/audio/out/*.wav`
(committed). They are not synced by Rojo: the user uploads them to Roblox and
pastes the asset ids into `Config.CalebSounds` (steps in
`tools/audio/README.md`).

## Server / client responsibilities

| Server owns (authoritative)          | Client may do              |
| ------------------------------------ | -------------------------- |
| Player cash                          | UI                         |
| Plot ownership                       | Visual feedback / effects  |
| Purchases                            | Read input                 |
| Dropper production and drop values   | Presentation               |
| Collection rewards                   |                            |

The client can *read* replicated state (`leaderstats.Cookies`, the plot
`OwnerUserId` attribute, `Config`). Changes a client makes to those never
reach the server.

## Services (server only)

`ServerMain.server.luau` is the only server Script. It calls
`TycoonService.Start()`, `StatueService.Start()`, `CalebCycle.Start(statue)`,
`CookiePartyService.Start(statue)`, `TrophyService.Start(statue)`, then
routes join/leave in a fixed order:

- Join: `PlayerDataService.OnPlayerAdded` → `CalebCycle.OnPlayerAdded` →
  `CookiePartyService.OnPlayerAdded` → `PowerService.OnPlayerAdded` →
  `DataService.OnPlayerAdded`
  (starts loading in the background; no plot yet; plots are claimed on the
  `ClaimPad`, see TycoonService)
- Leave: `TycoonService.OnPlayerRemoving` → `StatueService.OnPlayerRemoving`
  → `CookiePartyService.OnPlayerRemoving` → `PlayerDataService.OnPlayerRemoving`
  → `PowerService.OnPlayerRemoving` → `DataService.OnPlayerRemoving`
  (saves and releases in the background; never yields)

| Service | Responsibility | Status |
| ------- | -------------- | ------ |
| `PlayerDataService` | Creates `leaderstats.Cookies` at `StartingCash` on join (or `DevStartingCash` when `DevUnlimitedCash` is on **and** `RunService:IsStudio()`); forgets it on leave. | Implemented |
| `DataService` | Saves/loads each player's house purchases, Caleb trophies, and equipped trophy ids (not cookies) with a DataStore. Contract API (see "Caleb Full Event (contract)"). Retries, session lock, autosave, `BindToClose`; see **Persistence** below. | Implemented |
| `DataSchema` (helper) | Used only by `DataService`: `Default()`, `FromStored(raw)` (migrate by `Version`, drop unknown purchase ids, bad/duplicate trophies, and bad `Equipped` ids; refuses non-tables and newer versions), `ToStored(data)`, `CleanTrophy(record)`, `CopyTrophies`, `NewInstanceId()`, `IsInstanceId(value)`. | Implemented |
| `EconomyService` | **Only** writer of cash: `GetCash`, `AddCash`, `TrySpend` (positive whole numbers, no overspending). | Implemented |
| `TycoonService` | Finds and validates plots, gives a free plot to a player who touches its `ClaimPad` (`TryClaimPlot(player, plot)`; one plot per player), releases and resets it on leave, holds tycoon data, decides purchases (`TryPurchase(player, purchaseId)` for droppers and builds; only after the purchase in the entry's `After` is bought; `Cost = 0` spends nothing; a dropper is started with `DropperService.Start`; records it with `DataService.SetPurchased`). On claim, `RestorePurchases(player)` rebuilds the player's saved house for free. Tells `PlotStages` what to show. `PurchaseApplied: RBXScriptSignal` fires `(player, plot, purchaseId)` from `applyPurchase`, i.e. both when something is bought and when a saved purchase is restored (used by `TrophyService` for the Trophy Case). | Implemented (claiming + ordered purchases) |
| `PlotStages` (helper) | Used only by `TycoonService`: `ShowUnclaimed(plot)` (only `Base` + `ClaimPad`), `ShowClaimed(plot)` (hides `ClaimPad`; shows `OwnerSign`, `Conveyor`, `Collector`, `CollectPad`, `CashTank`, and the buttons of purchases with no `After`), `ShowAfterPurchase(plot, purchaseId)` (hides that button, shows a build's `Parts`, shows the buttons it unlocks). `ShowUnclaimed` also hides every build's `Parts`. Decides nothing. | Implemented |
| `PlotVisibility` (helper) | `Hide(root)` / `Show(root)` for a part or model and all its descendants: hidden parts get `Transparency = 1` and no collide/touch/query; Billboard/Surface GUIs are disabled. Original values are saved and restored exactly. A hidden part cannot fire `Touched`. | Implemented |
| `Purchases` (helper) | Read-only catalog built from `Config.Droppers` + `Config.Builds`: `Get(id)`, `All()`, `UnlockedBy(id?)`. Each purchase has `Id`, `Kind` (`"Dropper"`/`"Build"`), `Index` (in its own list), `Entry` (the Config entry), `ButtonName` (`BuyButtonN` / `BuildButtonN`). Warns at startup about duplicate ids or an `After` that names no purchase. | Implemented |
| `BuyButtons` (helper) | Used only by `TycoonService`/`PlotStages`: connects every purchase button's touch to a callback with the purchase id, sets RichText labels from `Config` ("Dropper N" or the build's `Name`, over a yellow "🍪 Cost" / "FREE!"), resets colors (droppers red, builds orange), and hides/shows each button (a dropper's together with its `DropperSpotN`) by purchase id (`HideAll`, `Show`, `SetPurchased`). Decides nothing. | Implemented |
| `DropperService` | Runs a plot's droppers: `Start(plot, dropperId)` places an upside-down red cup (a Model named after the id, built by `DropperCup`) at `DropperSpotN`, spawns cookie-shaped `Drop` parts (a Cylinder disc with welded `Chip` balls that have `CanTouch`/`CanQuery`/`CanCollide` off and are `Massless`) worth that dropper's `DropValue` into the plot's `Drops` folder every `DropInterval`; each dropper drops onto its Config `Conveyor` (`Conveyor` or `Conveyor2`), and a conveyor moves while any of its droppers runs; drops are destroyed after `DropLifetime`. Drop value and plot live only in server tables; `ClaimDrop(drop, plot)` returns the value once, only for the drop's own plot. `GetConfig(dropperId)` returns the Config entry and index. `CollectorFor(conveyorName)` names a conveyor's collector (`Conveyor2` → `Collector2`); `CollectorNames()` lists every collector the droppers use. | Implemented (`Start`, `Stop`, `StopAll`, `ClaimDrop`, `GetConfig`, `CollectorFor`, `CollectorNames`) |
| `DropperCup` (helper) | Used only by `DropperService`; presentation only. `Build(spot, name)` returns a Model that fills the spot's box (stacked red cylinders narrowing toward the top, two darker ridges, a rolled lip, a white inside disc) and the CFrame of the center of its open rim, where drops start. Parts are anchored with `CanTouch`/`CanQuery` off. | Implemented |
| `CollectorService` | Stores drop value per plot (one server-side total for all floors) when `DropperService.ClaimDrop` accepts a drop at any of the plot's collectors (`DropperService.CollectorNames()`: `Collector`, `Collector2`); pays the owner on the Collect pad via `EconomyService.AddCash`. Every time the stored amount changes (drop collected, payout, failed payout put back, `ResetPlot`) it calls `CollectorDisplay.SetAmount(plot, amount)` so the jar's counter shows it. The counter shows the stored amount; the owner's CollectBonus is added on top at payout. | Implemented (`SetupPlot`, `ResetPlot`) |
| `StatueService` | Feeding the statue (Caleb). Handles the `FeedStatue` RemoteFunction: validates the amount (whole number ≥ 1), that the player stands within `StatueFeedRange` of a `FeedPad`, a per-player `StatueFeedCooldown`, `CalebCycle.CanFeed()` (Normal only), and room left under `CalebEvent.MaxCookies()`; spends with `EconomyService.TrySpend` (only what Caleb still has room for), then `CalebCycle.AddCookies` (which owns the total and `CookiesEaten`), and calls `StatueShape.Apply(eaten / goal, Config.CalebGrowSeconds)`. On `CalebCycle.StateChanged`: pad signs "FEED CALEB!" in Normal, "CALEB IS FULL!" otherwise; `StatueShape.SetHidden(true)` in TrophyClaim; `SetHidden(false)` + `Apply(0)` on reset. Total is per server session (no saving). | Implemented (`Start(): Model?`, `OnPlayerRemoving`) |
| `CalebCycle` | Caleb Full Event state machine (see "Caleb Full Event (contract)"). Owns the shared total, contributions by UserId (+ display name), trophy claims, cycle id, and the timed states (`task.delay` timers guarded by cycle id + state). Publishes all statue/player attributes; `CalebTopFeeders` is throttled to `Config.CalebLeaderboardInterval` (batched, last value always published, immediate on reset). | Implemented |
| `CookiePartyService` | The Cookie Party's collectable cookies and rewards (see "Cookie Party (contract)"). On `CalebCycle.StateChanged` → `Celebration` (or `Start` mid-party) it zeroes every player's `CookiePartyEarned`/`CookiePartyCount` and runs one task loop every `Config.CookiePartyTickSeconds`: expires cookies past `ExpiresAt` + 0.5 s (`CookiePartyCollected(id, 0, 0, type)`), then spawns at the phase's rate (fractional budget, ≤ `CookiePartyMaxAlive`; none once fewer than `CookiePartyFallSeconds` are left, since they could not land in time) and sends the tick's new cookies as one `CookiePartySpawn` batch. Cookies live only in a server table (no parts). Handles `CookiePartyCollect` (all contract checks + a 1-second-bucket rate limit, alive Humanoid; first valid collect wins, paid with `EconomyService.AddCash`; a player without cash data leaves the cookie available). On leaving `Celebration` it stops, clears every alive cookie, and on `TrophyClaim` of the same cycle pays `CookiePartyFinalReward` once to each player in the server (`AddCash` true) and fires `CookiePartyFinale(reward)` to them; guarded by cycle id. Late joiners get the alive cookies with `FireClient`. | Implemented (`Start(statue)`, `OnPlayerAdded`, `OnPlayerRemoving`) |
| `CookiePartySpawner` (helper) | Used only by `CookiePartyService`; creates nothing. `Setup(statue)` (center = bottom of `PedestalBase`), `BeginTick()` (rays ignore characters), `PickType(phase)` (weighted by `CookiePartyTypes[t].Weights[phase]`, `CookieParty.Types` order), `PickSpot(): Vector3?` (`CookiePartyNearPlayerShare` near a random player within `CookiePartyNearPlayerRadius`, else uniform in `CookiePartySpawnRadius`; downward raycast that skips near-invisible parts like `CookieRain`, and retries spots that hit Caleb's body. Near-player spots cast from 8 studs above that player's root, at most 40 studs down, so they land on the player's own floor inside a house; if that hits nothing they use the sky cast like random spots). | Implemented |
| `StatueShape` (helper) | Presentation only. `Setup(statue)` remembers every body part's map position/size (body = `Shared/CalebBody`: not `Pedestal*`, `FeedPads`, `Podium`) and the pedestal top. `Apply(progress 0..1, seconds)` (progress = cookies / goal) tweens, from the original map values: fatness (Torso/Belt wider and deeper, arms/legs out and thicker, the hidden `Belly`, `RightCheek`, `LeftCheek`, `Chin` grow out, chain stays on the belly) with fatness = log(1 + p·`CalebFatnessCurve`)/log(1 + `CalebFatnessCurve`) (front-loaded), then scales every body part about the pedestal top by `CalebMinScale` → `CalebMaxScale` (p^`CalebScaleCurve`, plus a last `CalebFinalPopScale` jump at exactly the goal). `SetHidden(hidden)` hides/shows the body with `PlotVisibility`. | Implemented |
| `StatueShape` (helper) | Used only by `StatueService`; presentation only. `Setup(statue)` remembers every statue part's map position/size; `Apply(fatness 0..1, seconds)` tweens Torso/Belt wider and deeper, moves arms/legs out and thickens them, grows the hidden `Belly`, `RightCheek`, `LeftCheek`, `Chin`, and keeps the chain on the belly. `StatueService` passes progress = eaten / goal (linear). | Implemented |
| `TrophyService` | Caleb Trophies. On `CalebCycle.StateChanged` → `TrophyClaim` puts a big golden trophy (`Workspace.Map.CalebClaimTrophy`, `Config.TrophyPodiumScale`) on top of the highest `Pedestal*` part with a server `ProximityPrompt` "Claim Caleb Trophy"; any other state (and `Start`) removes it. `Triggered`: `CalebCycle.IsEligible` → (waits only if the player's data is still loading, then re-checks) → `TrophyVariants.RollReward(ownedVariantIds)` → `DataService.AddTrophy` (or, if data is not loaded, `TrophyInventory.AddSessionTrophy`: kept by UserId until the server closes) → `CalebCycle.MarkTrophyClaimed`, with no yield between the last check and the mark. Reports the result in the `CalebTrophyNotice` player attribute. Handles the `TrophyEquip` remote (rules in `TrophyInventory`). **Display rule:** only equipped trophies in a **built** Trophy Case are displayed, and only displayed trophies give powers. On join/load, trophy added, equip change, `PurchaseApplied("TrophyCase")` (buy or restore), and plot claimed/released (`OwnerUserId`), it calls `TrophyCaseDisplay.Show(plot, case, equippedRecordsInSlotOrder)` (or `Clear`), `PowerService.SetDisplayed(player, displayedVariantIds)` (empty without a built case, after release, and on leave), and republishes the `TrophyInventory` attribute; refreshes are batched per frame. | Implemented (`Start(statue?)`) |
| `TrophyInventory` (helper) | Used only by `TrophyService`. Owned = saved (`DataService`) + session-only trophies; Equipped = saved list then equipped session-only ones (≤ `TrophyActiveSlots`). `NewRecord`, `GetOwned`, `GetEquipped`, `GetEquippedRecords`, `AddSessionTrophy` (auto-equips into a free slot), `SetEquippedState`, `HandleRequest(player, action, instanceId)` (the remote's checks), `Publish(player, caseBuilt)`, `OnPlayerRemoving`. | Implemented |
| `TrophyModel` (helper) | Used only by `TrophyService`; presentation only. `Build(variantId, scale?, label?)` returns an anchored, non-colliding Model (pivot = bottom center of the plinth, facing -Z): plinth + gold trim + "CALEB TROPHY" nameplate (variant name in its rarity color, or `label`), a mini Caleb in the statue's style in the variant's color/material and pose (arm angles per pose), accessories, and effect (`Sparkles` on the head or a `PointLight` glow). Unknown variant ids use `TrophyVariants.Fallback`. | Implemented |
| `TrophyCaseDisplay` (helper) | Used only by `TrophyService`; presentation only. `Show(plot, case, records)` shows `records` **in slot order** (slot 1 = `records[1]`), up to `Config.TrophyCaseSlots`: each is built with `TrophyModel` (`Config.TrophyCaseScale`), stood on `TrophySlotN` facing the slot's LookVector, with a tilted gold-rimmed `Nameplate` part at the slot's front edge (SurfaceGui, `LightInfluence = 0`, `MaxDistance = 60`: `DisplayName` in `TrophyVariants.Rarities[rarity].Color` (white if missing) and the definition's `PowerText` if it has one), all in a runtime `CaseTrophies` folder in the plot (outside the `TrophyCase` model, so `PlotVisibility` never tracks them); then it enables the case's `Light`s. Built once per call, no loops. `Clear(plot)` destroys that folder and disables the plot's `TrophyCase` lights. | Implemented |
| `TrophyAccessories` (helper) | Used only by `TrophyModel`: `Add(make, names, anchors)` builds `Crown`, `PartyHat`, `ChefHat`, `Sunglasses`, `Cookie` (right hand), `BowTie`; unknown names are skipped. | Implemented |
| `PowerService` | A player's active Caleb Trophy powers. `SetDisplayed(player, variantIds)` (called by `TrophyService`) stores `TrophyPowers.Compute(variantIds)`, publishes the `TrophyStats` (JSON) and `CanDoubleJump` player attributes, and applies movement: `WalkSpeed = base × (1 + WalkSpeed)`, `JumpHeight = base × (1 + JumpHeight)` with `UseJumpPower = false`; the base is the Humanoid's own spawn value, saved as `BaseWalkSpeed` / `BaseJumpHeight` attributes on it so re-applying never compounds. `Get(player, stat)` is the capped total (0 if none). `OnPlayerAdded` re-applies on every `CharacterAdded`; `OnPlayerRemoving` forgets. Event-driven, no loops. | Implemented |
| `CollectorDisplay` (helper) | Used only by `CollectorService`: presentation only, never changes cash (it only shows the amount it is given). `Setup(plot)` adds the pad's sparkles, glow, and bouncing arrow, and the jar counter (`JarCounter.Setup`); `AddCube(plot)` drops a small cookie (`TankCookie`) into the plot's `CashTank` (max 60) and turns sparkles/glow on; `SetAmount(plot, amount)` shows the stored amount on the counter; `Clear(plot, celebrate)` empties the tank and, on payout, bursts sparkles. Built on the server so all players see it. | Implemented |
| `JarCounter` (helper) | Used only by `CollectorDisplay`: `Setup(plot, tank)` builds a runtime `JarCounter` Part in the `CashTank` (pink frame, 7 × 1.8 × 0.6, directly on top of `TankSign`, its front 0.2 studs in front of the sign's, placed from the sign's CFrame) with a `SurfaceGui` `CounterGui` on the pad-facing face (gold panel, FredokaOne white text, thick dark outlines, `MaxDistance` 120); `SetAmount(plot, amount)` shows "🍪 1,250" ("🍪 0" when empty) and pops a `UIScale` when the number goes up. Made in `SetupPlot` before the plot is first hidden, so `PlotVisibility` hides/restores it with the `CashTank`. Never changes cash. | Implemented |

`CollectorService` is deliberately not named `CollectionService`, which is a
built-in Roblox service.

Conveyor direction: `DropperService` moves each conveyor toward its
collector (flat unit vector from the conveyor's center to the collector's
center; `ConveyorN` pairs with `CollectorN`), so the map can lay a conveyor
out in any horizontal direction. Layout and positions are in `GAME_DESIGN.md` → Plot layout.

Dependencies (no cycles): `TycoonService` → `PlotStages`, `BuyButtons`, `Purchases`, `DropperService`,
`CollectorService`, `EconomyService`, `DataService`. `DataService` → `DataSchema`, `Purchases`, `Config`
(never `TycoonService`). `DataSchema` → `Purchases`. `PlotStages` → `BuyButtons`, `PlotVisibility`, `Purchases`.
`BuyButtons` → `PlotVisibility`, `Purchases`. `Purchases` → `Config` only.
`CollectorService` → `CollectorDisplay` (→ `JarCounter`), `DropperService` (`ClaimDrop`), `EconomyService` and `PowerService` (`Get`). `DropperService` → `DropperCup`, `PowerService` (`Get`).
`PowerService` → Shared only (`TrophyPowers`, which requires `Config` and, lazily inside `Compute`, `TrophyVariants`). `EconomyService` →
`PlayerDataService`. `DropperService` and `CollectorService` never require
`TycoonService`; they receive the plot and check ownership through the plot's
`OwnerUserId` attribute. `DropperService` never requires `CollectorService`.
`CalebCycle` → `CalebEvent`, `Config` only (it changes no cash); `ServerMain` starts it with the statue `StatueService.Start()` returns.
`CookiePartyService` → `CalebCycle`, `CookiePartySpawner`, `EconomyService`, Shared (`CalebEvent`, `CookieParty`, `Config`); `CookiePartySpawner` → Shared only (`CalebBody`, `CookieParty`, `Config`); nothing requires `CookiePartyService` except `ServerMain`.
`StatueService` → `EconomyService`, `StatueShape`, `CalebCycle`; `StatueShape` → `PlotVisibility`, `Shared/CalebBody`; nothing requires `StatueService` except `ServerMain`.
`TrophyService` → `CalebCycle`, `DataService`, `PowerService`, `TrophyInventory`, `TycoonService` (read-only: `GetTycoon`, `HasPurchased`, `PurchaseApplied`), `TrophyCaseDisplay`, `TrophyModel`, `TrophyVariants`; `TrophyInventory` → `DataService`, `DataSchema`, `Config`; nothing requires `TrophyService` except `ServerMain`. `TrophyCaseDisplay` → `TrophyModel`, `Config`. `TrophyModel` → `TrophyAccessories`, `TrophyVariants`.

## Client

Client code is presentation only. It reads replicated state and never
changes cash, ownership, or purchases, and never talks to the server
(except the `FeedStatue`, `TrophyEquip` and `CookiePartyCollect` remotes and Roblox's own
`ProximityPrompt` triggering, which the server validates).

| Script | What it does |
| ------ | ------------ |
| `StarterPlayerScripts/CashDisplay.client.luau` | Builds a `CashDisplay` ScreenGui (`ResetOnSpawn = false`) with a cartoony panel at the bottom-center. Waits for `leaderstats.Cookies`, shows it as `1,250` (comma separators) next to a cookie icon, and on `.Changed` updates the text and plays a short `UIScale` "pop" tween. Built-in UI only (UICorner, UIStroke, FredokaOne, a cookie icon drawn from round `Frame`s). Scale sizing + `UIAspectRatioConstraint` + `UISizeConstraint` keep it readable on phone and PC. The built-in player list still shows cash too. |
| `StarterPlayerScripts/FeedPrompt.client.luau` + `FeedPromptUI.luau` | When the local character stands on one of the statue's `FeedPads` (checked every frame against the pads loaded right now, so it works with content streaming; not `Touched` on pads found at start), shows a cartoony pop-up (same style as the cookie counter): "How many cookies do you want to feed Caleb?", progress `eaten / max` with a bar, an amount box (digits only), quick buttons 10 / 100 / 1K (each click **adds** that amount) / ALL (sets everything you can feed), Cancel and FEED!. The bar (fill + preview inside an `Inner` frame inset 4 px so they never touch the outline) is exact (eaten / the statue's `CalebMaxCookies` goal, with a thin minimum sliver above 0; shows "FULL" whenever `CalebState` is not Normal) plus a lighter preview of eaten + typed amount (red if unaffordable), and the text shows the exact %. FEED! invokes `Remotes.FeedStatue` with the amount and shows the server's answer. Closes on Cancel, right after a successful feed (with a `SendNotification` "Caleb ate N cookies!"), or when the player walks away; won't reopen until they step off the pad. Decides nothing. `FeedPromptUI.ProgressBar(parent, position, size)` builds that bar (track, fill, preview) and is reused by `StatueBar`. |
| `StarterPlayerScripts/CookieRain.client.luau` + `CookieRainLook.luau` | Cookie rain while the statue's `CalebState` is `Celebration` (`CalebEvent.GetState`; checked at start for mid-event joiners and on the attribute's changed signal). Visual only: no remotes, no rewards, nothing on the server. Creates a client-local `Workspace.CookieRain` folder (never replicated) and a `CookieRainPuff` attachment in `Terrain`. Ramps with the Cookie Party phase (`CookieParty.GetPhase(CookieParty.TimeLeft(statue))`, read each frame): spawn rate = `CookieRainPerSecond × CookiePartyRainRate[phase]`, pool cap = `CookiePartyRainMaxCookies[phase]` (hard limit 200), and `CookiePartyRainGoldenShare[phase]` of new cookies are recolored golden (`CookieRainLook.SetGolden`: gold Foil, not Neon, so they don't look like the collectable Golden ones). Cookies come from a pool that grows up to that cap and is reused (each cookie = 1 disc + 5 chip parts, all anchored, `CanCollide`/`CanTouch`/`CanQuery` off, built by `CookieRainLook.Build`). One `Heartbeat` connection (only while cookies exist) spawns them, picks spots in `CookieRainRadius` around the statue (`CookieRainNearPlayerShare` of them within `CookieRainNearPlayerRadius` of the local player), finds the landing height with a downward raycast per cookie (skipping invisible parts such as spawn areas), and moves every part with one `Workspace:BulkMoveTo`. Landing: hop, `ParticleEmitter:Emit` puff, fade. When the state leaves Celebration it stops spawning, lets the falling cookies finish, then disconnects and destroys the folder, pool, and puff. |
| `StarterPlayerScripts/CookiePartyCookies.client.luau` + `CookiePartyLook.luau` + `CookiePartyMotion.luau` + `CookiePartyFeedback.luau` + `CookiePartyNumbers.luau` + `CookiePartyHUD.luau` | The Cookie Party's collectable cookies on screen. Active only while `CalebState` is `Celebration` (read at start for mid-party joiners and on change). Listens to `CookiePartySpawn` (batches of `CookieParty.Spawn`; a batch that arrives just before the state change is queued, ≤ 100) and `CookiePartyCollected`. Each cookie is a pooled set of parts (`CookiePartyLook.Build`: Normal / Chocolate / Golden with Neon + `PointLight` + sparkle emitter / Giant ~2.7×; plus a ground beacon disc, and a light pillar for Golden/Giant; all anchored, `CanCollide`/`CanTouch`/`CanQuery` off) in a client-local `Workspace.CookiePartyCookies` folder, pooled per type, at most `CookiePartyMaxAlive × 2` built. `CookiePartyMotion.Step` places it each frame from `Workspace:GetServerTimeNow()`: falls from the sky (or, when `FromCaleb`, arcs from the center of Caleb's `Mouth*` parts → `Head` → last known → statue top) to touch down exactly at `LandAt`, bounces, bobs + spins (Giant hops), blinks in the last 1.5 s, fades at `ExpiresAt`. One `Heartbeat` moves everything with one `BulkMoveTo` and checks the local `HumanoidRootPart`: when `now ≥ LandAt − 0.3`, horizontally within the type's `CollectRadius − CookiePartyClientCollectMargin` and within 20 studs vertically, it fires `CookiePartyCollect(id)` with **at most one request in flight per cookie** (≤ `CookiePartyClientCollectsPerSecond` overall) and leans the cookie toward the player; no answer in `CookiePartyClientCollectTimeout` s → it goes back and may be asked for again, up to `CookiePartyClientCollectTries` (3) requests per cookie in all (a server reject from edge-of-radius lag, clock offset, or the rate limit is retried; a cookie that is really gone doesn't spam the server). `Collected(id, userId, value, type)`: local player → pop (grow, shrink into the player) + sparkle/confetti `Emit` (`CookiePartyFeedback`, one `CookiePartyBurst` attachment in `Terrain`) + floating "+N" (`CookiePartyNumbers`, a pool of 10 `BillboardGui`s in PlayerGui adorned to `Terrain` attachments; "GOLDEN!" / "GIANT!!") + collect sound (`Config.CookiePartySounds` Collect / CollectGolden / CollectGiant, 3 copies each in `SoundService.CookiePartyCookies`, created once, empty id = silent; pitch rises with the combo) + "x5 COMBO!" (collects ≤ `CookiePartyComboSeconds` apart; presentation only); another player → puff; `userId` 0 → quick fade. `CookiePartyHUD`: a `CookiePartyHUD` ScreenGui (`ResetOnSpawn = false`, `DisplayOrder` 3) with a yellow pill at the right side, upper-middle, "🍪 +12,450" from the local player's `CookiePartyEarned` attribute (pop on change), shown only during Celebration. Leaving Celebration: HUD hides (no summary), every cookie not mid-pop is released, and after the pops (≤ 0.6 s) the Heartbeat is disconnected and the folder (all pools), burst attachment and number pool are destroyed. Decides nothing. |
| `StarterPlayerScripts/StatueBar.client.luau` | A `BillboardGui` (in PlayerGui, `AlwaysOnTop`, pixel-sized `Config.StatueBarSize`, `MaxDistance = Config.StatueBarMaxDistance`) above Caleb's head that every player sees: a yellow rounded panel with "Caleb: 12,345 / 1,000,000 🍪" (or "Caleb is FULL! 1,000,000 🍪") over the same cookie bar as the feed pop-up (`FeedPromptUI.ProgressBar`, fill only, same thin minimum sliver). Reads the statue's replicated `CookiesEaten` attribute at start (late joiners) and on `GetAttributeChangedSignal`, tweens the fill and pops the panel. Adorned to an `Attachment` in `Workspace.Terrain` placed `Config.StatueBarHeight` studs above the top of the `Head` (re-placed whenever the Head streams in or changes), so it stays visible when the statue's parts stream out. No remotes; decides nothing. During the Caleb Full Event it also reads `CalebMaxCookies` (falls back to `CalebEvent.MaxCookies()`) and `CalebState`: the text becomes "Caleb is FULL!" (Full), "🎉 COOKIE PARTY! 🎉" (Celebration), "Caleb is resting... 💤" (TrophyClaim). |
| `StarterPlayerScripts/CalebEventUI.client.luau` + `CalebEventUIBuild.luau` + `CalebEventFX.luau` | The Caleb Full Event's screen UI. `CalebEventUIBuild.Build` makes one `CalebEventUI` ScreenGui (`ResetOnSpawn = false`, `IgnoreGuiInset`, `DisplayOrder` 5) with everything hidden: a white `Flash`, a pool of `Config.CalebConfettiCount` confetti frames, the big `FullText`, the pink `PartyBanner`, the gold `TrophyBanner`, and a purple one-line `Pill`. The client script reads the statue's `CalebState` at start (mid-event join) and on change and switches panels: Full → text slam + confetti (+ flash and a `Humanoid.CameraOffset` shake, restored after, unless just joined); Celebration → "COOKIE PARTY!" + m:ss and party lighting (`CalebPartyColor` ColorCorrection + `CalebPartyBloom` in Lighting, created once, tweened in, tweened out and disabled after); TrophyClaim → trophy banner if the local player's `CalebFed > 0` and not `CalebTrophyClaimed`, "Trophy claimed! 🏆" if claimed, else "CALEB IS RESTING — new round soon" + countdown; TrophyClaim → Normal shows "TROPHY CLAIM CLOSED" for `Config.CalebClosedMessageSeconds`. Countdowns use `CalebEvent.TimeLeft` every `Config.CalebUITickSeconds`. **Cookie Party** (`CookiePartyUIBuild` + `CookiePartyFX` + `CookiePartyCountdown`): during Celebration one `Heartbeat` connection reads `CookieParty.TimeLeft` / `GetPhase` / `Intensity` (server-synced, so every client agrees and late joiners land in the right phase) and pulses the banner on the beat (every 2 beats of `Config.CookiePartyMusicBPM` × `CookiePartyMusicSpeed[phase]`, ≤ ~1.2/s), shifts its color per phase (pink → orange → gold → red) and shakes it a little in Frenzy/Countdown; slams a callout when Hype ("MORE COOKIES! 🍪") and Frenzy ("✨ GOLDEN COOKIE FRENZY! ✨") begin (live only, not on join); ramps the lighting through `CalebEventFX.UpdateParty(intensity, pulse)` (`CookiePartyExtraSaturation` / `CookiePartyExtraBloom` + a soft beat pulse); drops `CookiePartyConfettiPieces` confetti every `CookiePartyConfettiEvery[phase]` s (round-robin from the same pool); and shows the 10…1 countdown: `math.ceil(timeLeft)`, each number once, slammed in center-screen with a color cycle and a `Camera.FieldOfView` punch (`CookiePartyCountdownFOVPunch`, `…Big` at 3-2-1, which are red and bigger with a screen-edge gradient glow). Leaving Celebration hides all of it and puts the banner and FOV back. **Finale**: on Celebration → TrophyClaim seen live (not on join) it plays `CookiePartyFinale`, the white flash, `CalebEventFX.Shake(CookiePartyFinaleShakeStuds, CookiePartyFinaleShakeSeconds)` and a full confetti burst, and shows the trophy UI right away as before. Listens to `CookiePartyFinale(reward)` (display only): "+5,000 🍪 PARTY BONUS!" pops and flies down to the cookie counter, gone in ~1.6 s. No completion screen. Decides nothing. |
| `StarterPlayerScripts/CookiePartyFinale.luau` | The finale explosion, client-local, looks only. `Play(statue)` (ignored while one runs): `Config.CookiePartyFinaleCookies` (≤ 80) cookies (disc + 3 chips, every 6th golden; anchored, no collide/touch/query) burst from Caleb's `Head` (fallback: above `PedestalBase`, or the statue pivot if streamed out) at `CookiePartyFinaleSpeedMin..Max` studs/s in every direction, fall with `CookiePartyFinaleGravity`, spin, bounce on the ground (bottom of `PedestalBase`) and fade in the last 0.6 s; plus a crumb + sparkle `ParticleEmitter:Emit` burst, a quick glowing ball and a 120-stud shockwave ring. One `Heartbeat` + one `BulkMoveTo` per frame. After `CookiePartyFinaleSeconds` (2.5 s) the connection is disconnected, the `Workspace.CookiePartyFinale` folder (ball, ring, emitters) is destroyed and the cookie parts are parked (`Parent = nil`) in a pool reused by the next finale. |
| `StarterPlayerScripts/CalebLeaderboard.client.luau` | Builds one `SurfaceGui` (in PlayerGui, `Face = Front`, 40 px/stud, `LightInfluence = 0`) per `Board` part in the statue's `Podium/Leaderboard<corner>` models, once, and re-adorns it when the board streams back in. Shows "CALEB'S TOP FEEDERS", up to `Config.CalebLeaderboardSize` rows from the statue's `CalebTopFeeders` JSON (decoded in `pcall`; bad data = empty), gold/silver/bronze badges for the top 3, the local player's row highlighted, "Be the first to feed Caleb!" when empty, "FINAL RESULTS" in `TrophyClaim`, and `CookiesEaten / CalebMaxCookies` (fallback `CalebEvent.MaxCookies()`). Refreshes on those attributes and `CalebState`. Names are plain text (`RichText = false`, fixed size, truncated). No remotes; decides nothing. |
| `StarterPlayerScripts/CalebAudio.client.luau` | Caleb Full Event sound effects (no music). Creates one `Sound` per non-empty `Config.CalebSounds` id, once, in a `SoundService.CalebAudio` folder (volumes from `Config.CalebSoundVolumes`), and reuses them. Driven only by attributes: `CalebState` → `Full` plays Full; → `Celebration` plays CelebrationStart and starts the looping CookieRain; leaving `Celebration` fades the loop out (0.8 s, then `Stop`) and plays EventEnd; `CookiesEaten` going up in `Normal` plays Grow (at most every `Config.CalebGrowSoundInterval` s); the local player's `CalebTrophyClaimed` turning true plays TrophyClaim. A late joiner hears no old one-shots; only the loops start if it is mid-Celebration. Empty ids are skipped (one info print in Studio, listing `CalebSounds` and the party sounds below). Touches no other sounds. **Cookie Party** (`CookiePartyAudio`, its `Music` / `CountdownTick` / `FinaleBoom` from `Config.CookiePartySounds`, created once in the same folder): during Celebration the music loops, `PlaybackSpeed` tweens to `CookiePartyMusicSpeed[phase]` at each phase change, and the volume fades in and swells slightly with `CookieParty.Intensity`; the countdown tick plays once per number 10…1 (same `ceil` rule as the screen), pitch rising 5 % per second; leaving Celebration stops the music (0.15 s fade). On Celebration → TrophyClaim (heard live) FinaleBoom plays and EventEnd follows 1.6 s later (at once if there is no boom id). The collect / Caleb laugh / spit sounds are played by the party cookie and Caleb scripts. |
| `StarterPlayerScripts/CalebAnimator.client.luau` + `CalebPoses.luau` + `CalebPartyPoses.luau` + `CalebPartyMoves.luau` + `CalebMouth.luau` | Animates Caleb's body parts (`Shared/CalebBody`; never the pedestal, `FeedPads`, or `Podium`) in `Full` and `Celebration`, driven only by the statue's `CalebState`, `CalebStateEndsAt`, `CalebCycleId`. One `RenderStepped` connection, only in those states. Every frame each part is set locally to `pose offset * base`, where `base` is the CFrame the server last replicated (a part whose CFrame isn't what we wrote last frame was moved by the server or streamed in, so it becomes the new base; server tweens are followed, not undone). The `Belly`'s `Size` is handled the same way (base size × `BellyScale`). Leaving those states puts every unchanged part's CFrame/Size back, stops `CalebMouth`, and disconnects. Pose groups (by part name): whole body (about his feet), Head (about the neck), Mouth (`Mouth*`, `Tooth*`, `Chin`; drops with the head), each Cheek, each arm (out + forward about the shoulder), Belly. `Full` = `CalebPoses.Full` (+ the burp puff). `Celebration` = `CalebPartyPoses.Pose(elapsed, seed)`: the `CalebDance` loop with energy from `Config.CookiePartyDanceEnergy` per phase as a smooth curve (ramps over `EnergyRampSeconds`; Countdown rises to `CountdownEnergy`), the beat being that curve's exact integral (so speed changes never jump the dance and every client is on the same beat); moves from `CalebPartyMoves` on a per-phase grid (`CookiePartyCaleb.MoveEvery`), weighted picks from `hash(seed, slot)` with seed = `CalebPartyPoses.Seed(CalebCycleId)`, never the same twice in a row, built once per party; Frenzy/Countdown shake; Countdown belly swell; the last `WindUpSeconds` the "I'M FULL!" wind-up, peaking at time left 0 and held until the state changes. `CalebMouth` keeps one client-local `CalebMouth` Attachment in `Terrain` (burp puff emitter, crumb spray emitter during Spit, 3D `CalebLaugh`/`CalebSpit` sounds from `Config.CookiePartySounds` when non-empty). No remotes; decides nothing. |
| `StarterPlayerScripts/CalebPartyBubble.client.luau` | Caleb's speech bubbles during `Celebration` only: one `BillboardGui` in PlayerGui (`AlwaysOnTop`, pixel-sized, `MaxDistance = Config.StatueBarMaxDistance`, built once, disabled outside the party) adorned to a `CalebPartyBubbleAnchor` Attachment in `Terrain` at the same spot as StatueBar's anchor (`Config.StatueBarHeight` above the Head, followed every frame). The billboard is twice as tall as needed and the bubble sits in its top half just above the bar's pixel height, so they never overlap. A white rounded bubble with a tail pops in/out (UIScale) with lines from `Config.CookiePartyCalebLines[phase]`, a new one every `CookiePartyCalebLineSeconds[phase]` (shown for 75% of it), in list order (Start/Hype/Frenzy start at an offset from the cycle seed; Countdown always from the first), text color per phase, shaking more later; the last `CookiePartyCalebFinalLineSeconds` show `CookiePartyCalebFinalLine` ("I'M FULL!!!", yellow, bigger). Everything comes from `CalebStateEndsAt`, so all players see the same line. One `Heartbeat` connection only during the party. No remotes; decides nothing. |

| `StarterPlayerScripts/TrophyInventory.client.luau` + `TrophyInventoryUI.luau` + `TrophyInventoryIcon.luau` + `TrophyInventoryData.luau` | The trophy inventory. `TrophyInventoryUI.Build` makes one `TrophyInventory` ScreenGui (`ResetOnSpawn = false`, `DisplayOrder` 4: under the event UI and the feed pop-up) with a yellow "🏆 TROPHIES" button at the left middle (clear of the cookie counter and the phone thumbstick) and a hidden centered panel (scale + `UIAspectRatioConstraint` 1.7 + `UISizeConstraint` 400×235 – 880×518): "MY CALEB TROPHIES", "🏆 COLLECTION N / M" (distinct collectable variants owned / `TrophyVariants.CollectableCount()`, or the count of `Weight > 0` definitions if that function is missing), "ACTIVE TROPHIES: n / Max", an orange "Build your Trophy Case…" note when `CaseBuilt` is false, a scrolling grid (`UIGridLayout`, 3–6 columns sized from the grid width), a details pane, an "Active powers: …" line from `TrophyStats`, and "Saving is off this session" when `Saved` is false. Grid tiles are created on demand and **pooled** (hidden, never destroyed; one `Activated` connection each); the order is equipped first, then rarest, then newest. Each tile: rarity-colored border, frame-drawn icon (`TrophyInventoryIcon`: Base/Figure colors, hat, sparkle), rarity, name, green "EQUIPPED" badge. Details: icon, name, "⭐ RARITY" in the rarity color, `PowerText`, `"Description"`, a message line and EQUIP / UNEQUIP (grey "Case full (n/Max)" when full). The button invokes `Remotes.TrophyEquip` (`"Equip"`/`"Unequip"`, instanceId) in a `pcall`, one request at a time and at most every `Config.TrophyEquipCooldown`, shows the server's reason on failure, and otherwise just waits for the attribute. Reads the `TrophyInventory` / `TrophyStats` attributes at start and on change (JSON decoded in `pcall`; missing/bad = empty inventory, bad records skipped, `Equipped` ids not in `Owned` ignored). Missing definition fields / unknown rarities fall back (name "Mystery Caleb", light grey rarity color, "No power"). Decides nothing. |
| `StarterPlayerScripts/TrophyPrompt.client.luau` | Watches `Workspace.Map` for `CalebClaimTrophy` (and its descendants, for streaming) and sets its `ProximityPrompt.Enabled` **locally** to whether this player is eligible (`CalebFed > 0` and not `CalebTrophyClaimed`), updating on those attributes; the server re-checks every claim. On `CalebTrophyNotice` changes, shows a `StarterGui:SetCore("SendNotification")` with the result: the variant's name + rarity (saved, or "couldn't be saved"), "already have this round's trophy", or "only players who fed Caleb this round". No remotes. |

**Client requires:** LocalScripts in `StarterPlayerScripts` start running
while the folder is still being copied into the player, so a sibling
ModuleScript may not exist yet. Always require siblings with
`require(script.Parent:WaitForChild("Name"))`, never `script.Parent.Name`
(that raced and broke CalebAnimator, CookieRain, and CalebEventUI on join).

UI is created by LocalScripts in `StarterPlayerScripts` (which run once per
session) rather than stored as instances in `StarterGui`. Colors and sizes
that are purely visual stay in the script; gameplay numbers stay in `Config`.

## Shared modules

`ReplicatedStorage/Shared` holds modules both sides can require: `Config`,
`CalebEvent` (event contract), and `TrophyVariants` (trophy looks: data,
`Get(id)` with a fallback for unknown ids, `PickVariant(ownedIds)` weighted
random preferring unowned variants). Never put secrets or server-only logic here: clients can
read everything in ReplicatedStorage.

## Configuration

`Config.luau` holds every tunable value (`StartingCash`, `Droppers`, `Builds`,
`DropInterval`, `NumberOfTycoonPlots`, `ConveyorSpeed`, `DropLifetime`,
`DevUnlimitedCash`, `DevStartingCash`, `StatueName`, `StatueMaxCookies`,
`StatueFeedRange`, `StatueFeedCooldown`, `StatueBarHeight`, `StatueBarSize`,
`StatueBarMaxDistance`, and the `Caleb*` / `CookieRain*` event settings,
including the event UI's `CalebUITickSeconds`, `CalebConfettiCount`,
`CalebShakeStuds`, `CalebShakeSeconds`, `CalebClosedMessageSeconds`,
`CalebPartySaturation`, `CalebPartyBloom`, `CalebPartyFadeSeconds`). It is frozen (including each
`StatueBarMaxDistance`, and the Caleb Full Event settings, including
`CalebSounds`, `CalebSoundVolumes`, `CalebGrowSoundInterval`). It is frozen (including each
`CalebPartySaturation`, `CalebPartyBloom`, `CalebPartyFadeSeconds`, and the
trophy settings `TrophyCaseSlots`, `TrophyCaseScale`, `TrophyPodiumScale`,
`TrophyClaimPromptDistance`, `TrophyClaimHoldSeconds`). It is frozen (including each
`Droppers` and `Builds` entry), so code cannot change it at runtime.

`Droppers` is a list of `{ Id, Cost, DropValue, After, Conveyor }`. Entry N
uses the plot parts `DropperSpotN` and `BuyButtonN`, and drops onto the part
named by `Conveyor` (whose collector is `CollectorFor(Conveyor)`).
`Builds` is a list of `{ Id, Name, Cost, After, Parts }`. Entry N uses the
plot part `BuildButtonN`; `Parts` are the plot parts/models it shows when
built. `After` (both lists) is the purchase id that must be bought first
(`nil` = available as soon as the plot is claimed); ids are unique across
both lists. TycoonService requires every part these entries name. To add a
dropper or build: add an entry and its parts to the map.
`NumberOfTycoonPlots` must match the plot models in the map; TycoonService
warns if it does not.

## Remotes

| Remote | Type | Direction | Handled by | Arguments (all untrusted) | Returns |
| ------ | ---- | --------- | ---------- | ------------------------- | ------- |
| `FeedStatue` | RemoteFunction | client → server (`InvokeServer`) | `StatueService` | `amount`: cookies to feed | `(true, cookiesEaten)` or `(false, reason)` |
| `TrophyEquip` | RemoteFunction | client → server (`InvokeServer`) | `TrophyService` (`TrophyInventory.HandleRequest`) | `action`: `"Equip"`/`"Unequip"`, `instanceId`: string ≤ 64 | `(true)` or `(false, reason)` |
| `CookiePartyCollect` | RemoteEvent | client → server | `CookiePartyService` | `id`: number (a cookie id the server sent) | — (answer is `CookiePartyCollected` to everyone) |
| `CookiePartySpawn` | RemoteEvent | server → all clients | `CookiePartyCookies.client` | `{ CookieParty.Spawn }` batch | — |
| `CookiePartyCollected` | RemoteEvent | server → all clients | `CookiePartyCookies.client` | `(id, userId, value, cookieType)`; `userId` 0 = expired/removed | — |
| `CookiePartyFinale` | RemoteEvent | server → each player | `CalebEventUI.client` (the "+N PARTY BONUS!" pop; the boom is played on the state change) | `(reward)` the final reward just paid | — |

`FeedStatue` exists because typing an amount in a UI is something the server
cannot see. The server re-checks everything (type, whole number, ≥ 1,
player within `StatueFeedRange` of a feed pad, cooldown, can afford it,
room left). It is a client → server RemoteFunction, which is safe: the
server's handler never yields on the client.

- **Use a server-side function call** when server code talks to server code,
  or when the server can observe the action itself (e.g. `Touched` on a
  button, `ProximityPrompt.Triggered`, `Players.PlayerAdded`).
- **Use a RemoteEvent** only when the client must tell the server something
  the server cannot see (e.g. a UI button click), or the server must push
  something the client cannot read from replicated state.
- Avoid RemoteFunctions called from server to client (a client can hang them).
- On the server, a remote handler must validate argument types, that the
  player owns what they are acting on, and use server-side prices/values only.

## Tycoon data model

Server-only, one per player, held by TycoonService:

```lua
type Tycoon = {
	PlotId: number,                  -- from the plot's PlotId attribute
	Plot: Model,                     -- Workspace.Map.Plots.PlotN
	Owner: Player,
	Purchased: { [string]: boolean }, -- e.g. Purchased.Dropper2 = true, Purchased.Walls = true
	Restoring: boolean,               -- true until the saved house is restored; TryPurchase refuses meanwhile
}
```

- **Ownership:** TycoonService keeps `player → Tycoon` and `plot → player`
  tables, and mirrors the owner into the plot's `OwnerUserId` attribute
  (read-only for everyone else).
- **Purchased upgrades:** `Purchased` is a set of purchase ids: the
  `Config.Droppers` ids (`"Dropper1"` … `"Dropper8"`) and `Config.Builds` ids
  (`"Walls"`, `"Stairs"`, `"SecondFloor"`, `"TrophyCase"`).
- **Active systems:** a purchase activates a system by calling its service
  (`DropperService.Start(plot, dropperId)`). Each system service keeps its own runtime
  state keyed by plot and must clean up in its stop/reset function.
- **Lifetime:** the Tycoon lasts for the session. On leave, systems stop, the
  plot is released and reset. Respawning does not touch any of it (cash lives
  on the Player, not the character). The *purchase ids* are also saved by
  `DataService` and restored on the next claim (see Persistence).

## Persistence (DataService)

Approved by the user 2026-10-01: the **house** (purchase ids) and **Caleb
trophies** are saved. **Cookies are not saved** (every session starts at
`StartingCash`).

Saved record, key `"Player_" .. UserId` in DataStore `Config.DataStoreName`:

```lua
{
	Version = 2,                       -- DataSchema.CURRENT_VERSION
	Purchases = { [purchaseId] = true },
	Trophies = { TrophyRecord },       -- oldest first, one per non-empty EventId, unique InstanceId
	Equipped = { InstanceId },         -- display order, owned, unique, <= Config.TrophyActiveSlots
	SessionJobId = "<JobId>" | nil,    -- session lock (DataService only)
	SessionTime = os.time(),           -- last write by the lock holder
}
```

- **Loading** (on join, background): one `UpdateAsync` reads, cleans
  (`DataSchema.FromStored`), and takes the session lock. Unknown purchase
  ids and bad/duplicate trophy records are dropped; older `Version`s are
  migrated step by step.
- **Version 2 (trophy inventory):** 1 → 2 gives every trophy a new
  `InstanceId` (a GUID) and sets `Equipped` to the newest
  `TrophyActiveSlots` trophies, newest first (what the old case showed). The
  load writes the migrated record at once, so the new ids stick. Cleaning
  (every load): a record without a non-empty `Variant` string or with a bad
  `EarnedAt` is dropped; a non-string `EventId` becomes `""`; a second
  record with the same non-empty `EventId` is dropped; a missing, invalid,
  or repeated `InstanceId` gets a new one (the trophy is kept). `Equipped`
  keeps only owned string ids, each once, at most `TrophyActiveSlots`.
  A Version 1 server refuses a Version 2 record (newer version), so during a
  rollout a player who reaches an old server plays unsaved there. A value that is not a table, or has a **newer**
  `Version` than the server knows, is refused (not overwritten).
- **Load failure** (all retries failed, refused data, Studio without API
  access): the player is **not loaded** for the session: `IsLoaded` is
  false, `GetPurchases`/`GetTrophies`/`GetEquipped` return `{}`,
  `SetPurchased` is ignored, `AddTrophy` returns false, `SetEquipped`
  returns `(false, "data not loaded")`, and **nothing is ever written** for
  them. A `warn` says so; gameplay works, unsaved.
- **Retries:** every DataStore call is tried up to 5 times, waiting 1, 2, 4,
  8 s.
- **Session lock (chosen over a plain "last saved" stamp):** the record
  holds the id of the server that has it open (`game.JobId`; a random id in
  Studio). Every save is an `UpdateAsync` that writes only if the record
  still carries this server's id, so a server that lost the lock can never
  overwrite newer data. Leaving clears the id. A joining server that finds
  another server's fresh lock (a fast server hop while the old server is
  still saving) cancels, waits 5 s, and retries; after ~30 s it takes the
  lock over (the old server's later saves are then refused). A lock older
  than 30 min (crashed server) is taken over at once. Autosave rewrites
  unchanged data every 10 min only to keep the lock fresh. A player who
  rejoins the **same** server waits for their previous leave save first.
  Why: a time stamp alone can't tell which server's data is newer when two
  servers' clocks and write times interleave; a lock with a compare on
  every write can.
- **Saving:** `UpdateAsync` on leave (and release the lock), every
  `Config.DataAutosaveSeconds` for players whose data changed, right after
  `AddTrophy`, and in `game:BindToClose` (everyone in parallel; waits for
  all loads/saves, at most 25 s). One write per player at a time.
- **Studio without API access:** DataStore calls error; DataService detects
  it, warns once ("Enable Studio Access to API Services to test saving"),
  and runs everyone unsaved.
- **Restoring the house:** `TycoonService.TryClaimPlot` spawns
  `RestorePurchases(player)`: it waits for `DataService.WaitForData`, then
  walks the unlock chain from the first buttons (`Purchases.UnlockedBy`)
  and applies every saved purchase whose `After` is already applied, the
  same way as a purchase (`PlotStages.ShowAfterPurchase` + `DropperService.Start`)
  but without spending. Saved ids that no longer exist, or whose `After`
  wasn't saved, are skipped. Until it finishes, `TryPurchase` refuses, so a
  player is never charged for something they own.
- **Trophies:** DataService only stores and returns them
  (`GetTrophies`, `AddTrophy`, `TrophiesChanged`, `GetEquipped`,
  `SetEquipped`, `EquippedChanged`, `IsLoading`); TrophyService awards,
  equips, and shows them. `AddTrophy` assigns an `InstanceId` if missing
  and **auto-equips** the new trophy when fewer than `TrophyActiveSlots`
  are equipped (so a first trophy shows up in a built case at once);
  `SetEquipped` validates loaded / owned / no repeats / limit, marks the
  data dirty (saved by autosave or on leave), and fires `EquippedChanged`.
  A trophy claimed while the player's data is **not loaded** is kept only
  in `TrophyInventory`'s session list (by UserId, until the server closes),
  is auto-equipped the same way, can be equipped/unequipped this session,
  and is never written. The Trophy Case itself is a normal build
  (purchase id `TrophyCase`), so it is saved and restored like the walls.

## Economy model

- Players see the currency as **cookies**; code and `Config` call it
  "cash" (`StartingCash`, `GetCash`/`AddCash`/`TrySpend`). The leaderstat is
  named `Cookies`. Keep new code consistent with this: "cash" in identifiers,
  "cookies" in anything a player reads.
- Cash is an integer in `leaderstats.Cookies`, changed only via EconomyService.
- Money enters the game only through collection (`AddCash`).
- Money leaves only through purchases (`TrySpend`, which fails without
  changing anything if the player cannot afford it).
- Claim flow: a player touches a plot's `ClaimPad` (server `Touched`) →
  `TycoonService.TryClaimPlot(player, plot)` checks the player has no plot and
  the plot is free → records the tycoon, sets `OwnerUserId` and the sign, and
  calls `PlotStages.ShowClaimed`.
- Purchase flow: owner touches their plot's `BuyButtonN` or `BuildButtonN`
  (server `Touched`, wired by `BuyButtons`) →
  `TycoonService.TryPurchase(player, purchaseId)` checks the player has a
  plot, the id is a real purchase id, it has not already been bought, the
  purchase named in its `After` **has** been bought, and
  `TrySpend(entry.Cost)` succeeds (skipped when `Cost` is 0) → marks
  `Purchased[purchaseId]`, calls `PlotStages.ShowAfterPurchase` (hide that
  button, show a build's parts, show the next button), and for a dropper
  calls `DropperService.Start(plot, purchaseId)`, then records it with
  `DataService.SetPurchased`. While the saved house is being restored after a
  claim (`Restoring`), `TryPurchase` refuses.
  Touches from non-owners are ignored. On release the plot goes back to
  `ShowUnclaimed`.
- Drop values are set by the server from the dropper's `Config.Droppers`
  `DropValue`, never taken from the client or from a property a client could change.
- Dev cash: `DevUnlimitedCash` only changes the *starting* amount, and only
  in Studio. Purchases still go through `EconomyService.TrySpend`.

## Caleb Full Event (contract)

Approved by the user 2026-10-01. Built by several agents in parallel, so
**this section is the contract**: names here are fixed. Change them only with
the lead's OK, and update this section in the same PR.

### Shared state (server → everyone)

The server publishes everything as attributes; clients read and reconcile to
them (also when joining mid-event). Names and helpers are in
`ReplicatedStorage/Shared/CalebEvent.luau` (`CalebEvent.Attr`,
`CalebEvent.PlayerAttr`, `CalebEvent.State`, `MaxCookies()`, `Duration()`,
`TimeLeft()`, `GetState()`, `Progress()`). Always use those constants, never
string literals.

| Where | Attribute | Type | Meaning |
| ----- | --------- | ---- | ------- |
| `Workspace.Map.Statue` | `CookiesEaten` | number | shared total this cycle |
| `Workspace.Map.Statue` | `CalebMaxCookies` | number | the goal |
| `Workspace.Map.Statue` | `CalebState` | string | `Normal` / `Full` / `Celebration` / `TrophyClaim` |
| `Workspace.Map.Statue` | `CalebCycleId` | string | unique id of this cycle (`HttpService:GenerateGUID(false)`) |
| `Workspace.Map.Statue` | `CalebStateEndsAt` | number | `Workspace:GetServerTimeNow()` when this state ends; 0 in Normal |
| `Workspace.Map.Statue` | `CalebTopFeeders` | string | JSON `[{UserId, Name, Cookies}]`, best first, ≤ `Config.CalebLeaderboardSize`, updated at most every `Config.CalebLeaderboardInterval` s |
| each `Player` | `CalebFed` | number | cookies this player fed Caleb this cycle (restored if they rejoin the same server) |
| each `Player` | `CalebTrophyClaimed` | boolean | claimed this cycle's trophy |
| each `Player` | `CalebTrophyNotice` | string | JSON `{Id, Kind, Variant?}` set by TrophyService after a claim attempt (`Kind`: `Saved` / `Unsaved` / `AlreadyOwned` / `NotEligible`); `Id` changes every time. `TrophyPrompt.client` shows it. |

A player is **eligible** for this cycle's trophy when `CalebFed > 0` and
`CalebTrophyClaimed` is not true, during `TrophyClaim`. Players who join
after the goal is reached have `CalebFed = 0`, so they are not eligible.

### Timeline (`CalebCycle`, server)

`Normal` → (total reaches the goal) → `Full` (`Config.CalebFullSeconds`) →
`Celebration` (`Config.CalebCelebrationSeconds`) → `TrophyClaim`
(`Config.CalebTrophyClaimSeconds`) → reset (total 0, contributions cleared,
Caleb back to his smallest size and visible, new `CalebCycleId`) → `Normal`.
`Config.DevCalebFastCycle` (Studio only) shortens all of it for testing.

Only `CalebCycle` changes the state, once per transition, guarded by the
current state, so it can never fire twice. Feeding is refused outside
`Normal`. Luau runs one server thread at a time and `EconomyService.TrySpend`
does not yield, so two simultaneous feeds are processed one after the other
and the total can never pass the goal.

### Server modules and their APIs

| Module (Services/) | Owner | Public API |
| ------------------ | ----- | ---------- |
| `CalebCycle` | Core | `Start(statue)`, `GetState(): string`, `GetCycleId(): string`, `CanFeed(): boolean`, `AddCookies(player, cookies)` (called by StatueService after a successful spend; records the contribution, updates attributes, starts `Full` at the goal), `GetContribution(userId): number`, `IsEligible(userId): boolean`, `MarkTrophyClaimed(userId)`, `OnPlayerAdded(player)` (restores `CalebFed`/`CalebTrophyClaimed`), `StateChanged: RBXScriptSignal` (fires `(state, cycleId)`) |
| `StatueService` | Core | unchanged `FeedStatue` remote; asks `CalebCycle.CanFeed()` and `CalebCycle.AddCookies` |
| `StatueShape` | Statue look | `Setup(statue)`, `Apply(progress, seconds)` (progress 0..1 = cookies / goal; fatness + overall scale), `SetHidden(hidden)` (hide/show Caleb's body; never the pedestal, `FeedPads`, or `Podium`) |
| `DataService` | Saving | `OnPlayerAdded(player)`, `OnPlayerRemoving(player)`, `IsLoaded(player): boolean`, `WaitForData(player): boolean`, `GetPurchases(player): {[string]: true}`, `SetPurchased(player, id)`, `GetTrophies(player): {TrophyRecord}`, `AddTrophy(player, record): boolean` (false if not loaded or `EventId` already owned), `TrophiesChanged: RBXScriptSignal` (fires `(player)`) |
| `TrophyService` | Trophy (wave 2) | `Start(statue?)`. Podium claim (`Workspace.Map.CalebClaimTrophy` + `ClaimPrompt` ProximityPrompt, only during `TrophyClaim`) + Trophy Case display. Uses `TycoonService.PurchaseApplied` (fires `(player, plot, purchaseId)` on buy and restore). |

```lua
type TrophyRecord = {
	Variant: string, -- key into Shared/TrophyVariants
	EventId: string, -- the CalebCycleId it was earned in
	EarnedAt: number, -- os.time()
}
```

Statue children: Caleb's body parts, `Pedestal*` parts, `FeedPads` (folder),
and `Podium` (folder: the four `Leaderboard<corner>` models, each with a `Board` part that carries the client SurfaceGui, plus other podium decoration).
Scaling, hiding, and client animation touch **only Caleb's body parts**.

### Who does presentation

All presentation is client-side and driven only by the attributes above:
`CalebAnimator.client` (full animation + dance), `CalebEventUI.client` (big
message, countdowns, trophy prompt text, screen VFX), `CookieRain.client`,
`CalebAudio.client`, `CalebLeaderboard.client` (podium board),
`TrophyPrompt.client` (claim prompt visibility + claim messages), and the
existing `StatueBar.client`. The Caleb Full Event itself uses no RemoteEvents (state is
attributes; the trophy claim uses a server `ProximityPrompt`); only the Cookie Party's collectable cookies do (see "Cookie Party (contract)").

## Cookie Party (contract)

Approved by the user 2026-10-01. Built by several agents in parallel: **this
section is the contract**; names are fixed (change only with the lead's OK,
and update this section in the same PR). Names, phases and helpers are in
`ReplicatedStorage/Shared/CookieParty.luau`; numbers in `Config.CookieParty*`.

User rules: the party is **exactly 60 seconds** (`CalebState` =
`Celebration`, `Config.CalebCelebrationSeconds`; also in the fast dev cycle).
It ends with one big finale, then goes straight to the existing 2-minute
`TrophyClaim`. No completion screen, no leaderboard, no mini-events, no
changes to the trophy system or the `CalebCycle` states.

### Phases (seconds left in `Celebration`)

| Phase | Seconds left | What happens |
| ----- | ------------ | ------------ |
| `Start` | 60–40 | Caleb celebrates, rain + collectable cookies begin, music starts |
| `Hype` | 40–20 | more and more valuable cookies, Caleb more energetic, music faster |
| `Frenzy` | 20–10 | heavy rain, lots of Golden, Caleb goes crazy, stronger VFX |
| `Countdown` | 10–0 | big 10…1 countdown, everything peaks, Caleb's "I'M FULL!" wind-up |
| finale | 0 | server pays `CookiePartyFinalReward`; on `Celebration → TrophyClaim` clients play the explosion (Caleb is hidden by StatueService at that moment, so the explosion covers it) |

`CookieParty.GetPhase(timeLeft)`, `CookieParty.Intensity(timeLeft)` (0 → 1),
`CookieParty.TimeLeft(statue)`. Everyone derives the phase from
`CalebStateEndsAt`, so all clients and the server agree and late joiners
land in the right phase.

### Collectable cookies (server-authoritative, no server parts)

* `CookiePartyService` (server) is the only thing that creates collectable
  cookies. During `Celebration` it picks, per phase, how many to spawn
  (`CookiePartySpawnPerSecond` + `CookiePartySpawnPerExtraPlayer`, at most
  `CookiePartyMaxAlive` alive), their type (`CookiePartyTypes[t].Weights`),
  where they land (ground spot found by a server raycast; near players or
  anywhere in `CookiePartySpawnRadius`), whether Caleb throws them
  (`CookiePartyFromCalebShare`), `LandAt = now + CookiePartyFallSeconds`, and
  `ExpiresAt = LandAt + CookiePartyLifetime`. It keeps them in a server table
  only and sends them in batches with `CookiePartySpawn`.
* Clients draw them (pooled, client-local parts) and, when their character
  gets close, fire `CookiePartyCollect(id)`.
* The server accepts a collect only if: state is `Celebration`; the id is
  alive (not collected/expired); `now >= LandAt - 0.3` and
  `now <= ExpiresAt + 0.5`; the player's `HumanoidRootPart` is within the
  type's `CollectRadius` (+2 studs lag slack, horizontal) and 25 studs
  vertically of `Position`; the player is under
  `CookiePartyMaxCollectsPerSecond`. First valid collect wins. Then
  `EconomyService.AddCash(player, value)`, the player's
  `CookiePartyEarned` / `CookiePartyCount` attributes go up, and
  `CookiePartyCollected(id, userId, value, type)` goes to everyone (expired
  cookies: `(id, 0, 0, type)`, so clients can drop them).
* At party start all players' `CookiePartyEarned` / `CookiePartyCount` are
  set to 0. When the party ends (`CalebCycle.StateChanged` → `TrophyClaim`)
  the server clears every alive cookie, pays `CookiePartyFinalReward` to
  every player in the server with `EconomyService.AddCash`, and fires
  `CookiePartyFinale(reward)` to each. A stale timer/cycle can never pay
  twice (guard by cycle id).

### Who owns what

| Part | Owner | Files |
| ---- | ----- | ----- |
| Server cookies + rewards | Party server | `Services/CookiePartyService.luau` (new), `ServerMain` (start it), remotes |
| Collectable cookies on screen, collect feedback (pop, floating "+N", sparkles, collect sounds, party earnings counter), visual rain ramp | Party cookies | `CookiePartyCookies.client.luau` (new), `CookiePartyLook.luau` (new), `CookieRain.client.luau` / `CookieRainLook.luau` |
| Caleb at the center: energy ramp, throws/spits, laughs, speech bubbles, "I'M FULL!" finale pose | Caleb party | `CalebAnimator.client.luau`, `CalebPoses.luau`, `CalebPartyPoses.luau`, `CalebPartyMoves.luau`, `CalebMouth.luau`, `CalebPartyBubble.client.luau` |
| Countdown 10…1, phase callouts, escalating lighting/VFX, finale explosion + flash + shake, final reward pop, music + party SFX | Party FX | `CalebEventUI.client.luau`, `CalebEventUIBuild.luau`, `CalebEventFX.luau`, `CookiePartyUIBuild.luau`, `CookiePartyFX.luau`, `CookiePartyCountdown.luau`, `CookiePartyFinale.luau`, `CalebAudio.client.luau`, `CookiePartyAudio.luau`, `tools/audio/` |

Everything created for the party (client parts, pools, connections, lighting
effects, server tables) is cleaned up when `Celebration` ends (the finale
explosion may finish its ~2 s animation into `TrophyClaim`, then is gone).

## Trophy Collection + Powers (contract)

Approved by the user 2026-10-01. Built by several agents in parallel: **this
section is the contract**; names are fixed (change only with the lead's OK).
User decisions: no Magnet Caleb; Big Brain = Collect pad bonus; trophy claim
stays 2 minutes; the Trophy Case stays a purchase and **a trophy's power only
works while it is displayed in a built Trophy Case**.

### Data (DataService / DataSchema, Version 2)

```lua
type TrophyRecord = {
	InstanceId: string, -- unique per earned trophy (HttpService:GenerateGUID(false)), never reused
	Variant: string,    -- definition id in Shared/TrophyVariants (never renamed)
	EventId: string,    -- the CalebCycleId it was earned in ("" for none)
	EarnedAt: number,   -- os.time()
}
PlayerData.Equipped: { string } -- InstanceIds in display order, unique, owned, at most Config.TrophyActiveSlots
```

Version 1 → 2 migration: every old record gets a new InstanceId; Equipped =
the newest `TrophyActiveSlots` records (what the old case showed).

### Shared modules

| Module | Owner | Contract |
| ------ | ----- | -------- |
| `Shared/TrophyVariants` | Definitions | Every definition: `Id`, `DisplayName`, `Rarity`, `Description`, `Powers: {[TrophyPowers.Stat]: number}`, `PowerText` (short line, e.g. "2x COOKIE PRODUCTION"), `Weight`, and the existing look fields. `Rarities` = Common, Uncommon, Rare, Epic, Legendary, Mythic, each `{ Order, Color, ... }` (the ONLY place rarity presentation lives). `Get(id)` (never nil), `RollReward(ownedVariantIds): string` (rarity by `Config.TrophyRarityChances`, then a definition of that rarity, preferring unowned; server calls it), `CollectableCount(): number` (definitions with Weight > 0). |
| `Shared/TrophyPowers` | Lead (names) / Powers (logic) | `Stat` names and the stacking rule (see the file). Powers agent may add a pure `Compute(variantIds): {[Stat]: number}` here. |

### Server modules

| Module | Owner | API |
| ------ | ----- | --- |
| `DataService` | Inventory | existing API, plus `AddTrophy` assigns `InstanceId` when missing; `GetEquipped(player): {string}`; `SetEquipped(player, ids): (boolean, string?)` (validates: loaded, every id owned, no repeats, ≤ `TrophyActiveSlots`); `EquippedChanged: RBXScriptSignal (player)`; `IsLoading(player): boolean`. `AddTrophy` auto-equips into a free active slot. |
| `TrophyService` | Inventory | claim uses `TrophyVariants.RollReward`; handles the `TrophyEquip` remote; publishes the `TrophyInventory` attribute; decides what is displayed (equipped records, only if the case is built) and calls `TrophyCaseDisplay.Show(plot, case, recordsInSlotOrder)` and `PowerService.SetDisplayed(player, variantIds)` (empty when the case isn't built or the plot is released). Session-only (unsaved) trophies keep working as today. |
| `PowerService` | Powers | `SetDisplayed(player, variantIds)`, `Get(player, stat): number` (the capped total bonus, 0 if none), `OnPlayerAdded/OnPlayerRemoving`. Applies WalkSpeed / JumpHeight to the character (and on respawn), publishes `TrophyStats` + `CanDoubleJump`. Requires only Shared modules (no TycoonService: avoids a require cycle). Event-driven, no loops. |
| `DropperService` / `CollectorService` | Powers | read `PowerService.Get(owner, …)` for the plot owner: drop value × (1 + CookieMultiplier), interval ÷ (1 + DropperSpeed), ExtraCookieChance, LuckyCookieChance, collect × (1 + CollectBonus). |
| `TrophyCaseDisplay` | Case | `Show(plot, case, records)` shows `records` in slot order (slot 1 = first), with a nameplate per trophy (name, rarity color from `TrophyVariants.Rarities`); `Clear(plot)`. |
| `TrophyModel` / `TrophyAccessories` | Definitions | looks for every definition. |

### Remote

| Remote | Type | Args (untrusted) | Returns |
| ------ | ---- | ---------------- | ------- |
| `TrophyEquip` | RemoteFunction | `action: "Equip" \| "Unequip"`, `instanceId: string` | `(true)` or `(false, reason)` |

Server checks: types, rate limit (`Config.TrophyEquipCooldown`), data loaded,
the instance is the caller's, equip limit. Ownership is never taken from the
client.

### Player attributes (server-written, read-only for clients)

| Attribute | Type | Meaning |
| --------- | ---- | ------- |
| `TrophyInventory` | string | JSON `{ Owned = [{InstanceId, Variant, EventId, EarnedAt}], Equipped = [InstanceId], CaseBuilt = bool, Max = TrophyActiveSlots, Saved = bool }` |
| `TrophyStats` | string | JSON `{[Stat] = total}` of active powers |
| `CanDoubleJump` | boolean | Rocket Caleb's double jump is active |

### Client

`TrophyInventory.client` (+ UI builder module): "MY CALEB TROPHIES N / M"
button + panel, trophy details (name, rarity, PowerText, Description),
EQUIP / UNEQUIP via `TrophyEquip`, "ACTIVE TROPHIES: n / 5", and a note when
the Trophy Case isn't built. `DoubleJump.client`: second jump when
`CanDoubleJump` is true.

### Power formulas (PowerService, DropperService, CollectorService)

Every bonus is the **plot owner's** (`OwnerUserId` → `Players:GetPlayerByUserId`;
no owner in the server = no bonus), read when it is used, so equip changes
apply from the next drop / collect. Values stay server-side.

| Stat | Applied | At the cap |
| ---- | ------- | ---------- |
| CookieMultiplier | drop value = round(DropValue × (1 + total)) | 3× |
| LuckyCookieChance | that drop × `TrophyLuckyCookieMultiplier` (5), drawn gold | 25% → average 1 + 0.25 × 4 = 2× |
| ExtraCookieChance | one more drop (same value rules, never another extra) | 50% → average 1.5× drops |
| DropperSpeed | wait = `DropInterval` / (1 + total), read every cycle | 2× drop rate |
| CollectBonus | payout = floor(stored × (1 + total)) | 1.5× |
| WalkSpeed / JumpHeight | base × (1 + total) | 1.5× / 2× |
| DoubleJump | `CanDoubleJump` flag → one air jump (client) | — |

Most cookies a player can earn per second vs. no trophies, everything at its
cap: 3 × 2 × 1.5 × 2 × 1.5 = **27×** on average. Each factor is a capped
(1 + total) of summed bonuses, so it is a fixed product of five numbers, never
exponential in the number of trophies. Movement is client-simulated in Roblox
(character physics is owned by the client), so speed / jump / double jump are
not security-relevant.

## Adding a feature (for future agents)

1. Confirm the feature is approved (in `GAME_DESIGN.md` / `TODO.md`).
2. Put numbers in `Config.luau`.
3. Put logic in the service that owns that responsibility. Create a new
   service only for a genuinely new responsibility, and wire it from
   `ServerMain` or from the service that owns it.
4. New map parts: edit the `.model.json` files and
   update `REQUIRED_PARTS` in TycoonService if code depends on them.
5. Only add a remote if the rules above say you need one.
6. Update this file, `GAME_DESIGN.md`, `QA.md`, and `TODO.md`.
7. Build with Rojo and test in Studio using `QA.md`.
