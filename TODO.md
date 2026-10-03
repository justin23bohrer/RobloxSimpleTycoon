# SimpleTycoon TODO

Only the **MVP** section is approved for work. Everything below it needs the
user's approval first.

## Foundation (done)

- [x] Rojo mapping for Workspace, ReplicatedStorage, ServerScriptService, StarterPlayer, StarterGui.
- [x] Central `Config` module.
- [x] Service modules and `ServerMain` entry point.
- [x] PlayerDataService: $100 starting cash via `leaderstats`.
- [x] EconomyService: validated `AddCash` / `TrySpend`.
- [x] TycoonService: plot validation, claim on the Claim pad (was: assign on join), release on leave, owner sign.
- [x] Prototype map: spawn, one plot with button, dropper spot, conveyor, collector, collect pad (reduced from 4 plots to 1 on 2026-09-30).
- [x] Project docs (AGENTS, ARCHITECTURE, GAME_DESIGN, QA, README).

## MVP

- [ ] Verify the foundation in Studio (QA: B1–B2, P1–P2, T1–T2, E1, M1, R1, L1, L3).
- [x] Dropper purchase: implement `TycoonService.TryPurchaseDropper` and the Buy button trigger (needs Studio test: QA U1–U3, T3).
- [x] Show a simple dropper at `DropperSpot` once purchased. (code done; Studio test pending)
- [x] DropperService: spawn server-owned `$10` drops every 2 seconds; clean up on stop. (code done; Studio test pending)
- [x] Conveyor movement. (code done; Studio test pending)
- [x] CollectorService: store drop value at the collector; owner-only payout on the Collect pad (code done; Studio test waits on DropperService).
- [x] Show the plot's stored (uncollected) cash at the Collect pad (now shown as cubes in the cash tank, not text).
- [ ] Run the full `QA.md` in Studio, including 2-player tests.
- [x] Round, outlined pads for the Buy button and Collect pad (approved 2026-09-30; Studio visual check pending).
- [x] Spawns are invisible spawn areas flush with the grass (no blue discs or rings); spawns 2–4 regenerated (requested by the user 2026-10-01; Studio check pending: QA SP1–SP2).

## Approved 2026-09-30

- [x] Four droppers with increasing prices (`Config.Droppers`), one buy button each, label shows name and price from `Config`. (code done; Studio test pending: QA U1–U7, D4)
- [x] Studio-only unlimited cash for testing (`Config.DevUnlimitedCash`). (code done; Studio test pending: QA DV1–DV2)
- [x] Restyle the new buy buttons to match the round, outlined pads (done by the lead while merging).
- [x] Bought buy buttons disappear instead of turning gray; they come back on plot reset. (code done; Studio test pending: QA U1, U3, U4, U7, L1)
- [x] Claim pad + step-by-step unlocks: plot shows only a Claim pad until claimed; claiming shows the collect area and a FREE Dropper 1 button; each purchase reveals the next dropper's button; order enforced on the server (approved by the user 2026-09-30). (code done; Studio test pending: QA T1, T4–T6, U0–U7, M1, M3–M4, L1, L3)
- [x] Fun cartoony signs above the Claim, Buy, and Collect pads in the cash display's style (FredokaOne, rounded panel, dark outline); buy price on its own yellow line (approved by the user 2026-09-30). (code done; Studio test pending: QA V3)
- [x] Cartoony cash display at the bottom-center (client only; approved 2026-09-30). (code done; Studio test pending: QA C1–C4)
- [x] Cookie theme: the currency is cookies (leaderstat `Cookies`, cookie drops with chips, "🍪 Cost" prices, cookie icon in the display, "COOKIE JAR" with small cookies). Code identifiers still say "cash" (approved by the user 2026-09-30). (code done; Studio test pending: QA CK1–CK2, C1–C2, P2)
- [x] Owner sign restyle: the name is on the sign wall itself in the cartoony sign style (purple panel, gold frame), both faces (approved by the user 2026-10-01). (code done; Studio test pending: QA V5, T4)
- [x] Grass ground: everything outside the tycoon plot is green grass; the plot itself is unchanged (approved by the user 2026-10-01). (code done; Studio test pending: QA V4)
- [x] Fun collect area: cash tank wall behind the Collect pad that fills with a gold cube per collected drop, pad sparkles/glow/bouncing arrow, no amount text (approved 2026-09-30). (code done; Studio test pending: QA CT1–CT7)
- [x] Bigger plot (100 × 100, ground 280 × 280); conveyor + droppers + buy buttons along the left side, Collect pad + cash tank on the back wall; conveyor direction worked out from the Collector's position (approved by the user 2026-10-01). (code done; Studio test pending: QA LY1–LY4, T2)
- [x] Cookie jar + Collect pad moved from the back wall to the middle of floor 1, collect from the front only (approved by the user 2026-09-30). (code done; Studio test pending: QA LY2, LY4, LY5)
- [x] Plot shrunk to 2/3 (66 × 66), same layout (approved by the user 2026-10-01). (Studio test pending: QA LY1–LY4, T2)
- [x] Build area: after Dropper 4, orange build buttons on the right side unlock Walls → Stairs → 2nd Floor in order; the 2nd floor has its own conveyor and collector on the left side (above the first), and Droppers 5–8 unlock after it. Purchases are now one catalog (`Purchases`) with an `After` unlock field; `TryPurchaseDropper` became `TryPurchase` (approved by the user 2026-10-01). (code done; Studio test pending: QA BF1–BF11)
- [x] House look: the Walls and 2nd Floor builds look like a two-story off-white brick house with gray trim, framed windows, and a gray shingle roof with a front gable; generated by `tools/house/generate_house.py` (approved by the user 2026-09-30). (code done; Studio test pending: QA HS1–HS3, BF4, BF6, BF10)
- [x] Hip roof (all four sides slope, ridge, caps, soffit, fascia, front gable, chimney); droppers look like upside-down red party cups (`DropperCup`); guard rails on both conveyors and collectors so cookies can't fall off (approved by the user 2026-09-30). (code done; Studio test pending: QA HS1, CP1–CP3, U1)
- [x] Four plots around the statue (same distance, doorways facing it), each with its own spawn, for up to 4 players; Plots 2–4 and spawns 2–4 generated from Plot1 by `tools/plots/generate_plots.py`; ground enlarged to 300 × 300 around the statue (approved by the user 2026-09-30; 400 × 400 since 2026-10-02 for the backyards). (code done; Studio test pending: QA T2, M5–M8)
- [x] Giant cartoony statue behind the spawn, based on the user's reference photos (face/outfit from IMG_2755, hair from IMG_9026); generated by `tools/statue/generate_statue.py` (approved by the user 2026-10-01). (built; Studio look check pending: QA ST1–ST4)
- [x] Fix: Caleb's grin showed two rows of teeth (each tooth faced the head at its own height, so the dark mouth face cut through it). Teeth now sit in their mouth segment's frame, just in front of it and just below its top edge, rolled to the smile's curve (`tools/statue/generate_statue.py`). (generated; Studio look check pending: QA ST5)
- [x] Feed Caleb: 4 feed pads around the statue; cartoony "How many cookies do you want to feed Caleb?" pop-up; server-validated feeding via the `FeedStatue` RemoteFunction; Caleb gets fatter up to 1,000,000 cookies, then is full (approved by the user 2026-10-01). (code done; Studio test pending: QA FD1–FD13)
- [x] Feeder upgrade: 10 / 100 / 1K add on every click; progress bar is exact (eaten / 1,000,000, exact % in the text) with a preview of the picked amount; pop-up closes right after a successful feed (approved by the user 2026-10-01). (code done; Studio test pending: QA FD4, FD14–FD17, FD19)
- [x] Cookie jar sign restyle: the "COOKIE JAR" sign on the jar wall uses the cartoony sign style (pink rounded panel, thick dark outline, gold frame, FredokaOne), facing the Collect pad (requested by the user 2026-10-01). (done; Studio test pending: QA V6, CT1)
- [x] Cookie jar shows how many cookies are in it (requested by the user 2026-10-01). (code done; Studio test pending: QA JC1–JC9)
- [x] Brown cookie jar: the `CashTank` wall is chocolate brown, the stand and the counter frame dark chocolate, the sign panel milk chocolate; gold frame/sign/counter panel and clear glass kept (requested by the user 2026-10-03). (done; Studio test pending: QA CT1, CT8, V6, JC1)
- [x] Progress bar above Caleb's head that everyone sees: "Caleb: N / 1,000,000 🍪" in the pop-up's style, "FULL!" at the max; client only, reads `CookiesEaten` (requested by the user 2026-10-01). (code done; Studio test pending: QA SB1–SB8)
- [x] Decide what happens when Caleb reaches 1,000,000 cookies: the Caleb Full Event (approved by the user 2026-10-01; see below).

- [x] Caleb's goal scales with players (350k × players, max 1M); Stairs 5k, 2nd Floor 10k (requested by the user 2026-10-02). (code done; Studio test pending: QA GS1–GS10)
- [x] Second-floor furniture: cartoony Bed, Gaming Desk, Shelves + TV, Mini Fridge, and Ninja Kitchen from the user's photos, laid out like the user's sketch; each bought with its own button, all unlocked with the 2nd Floor alongside Dropper 5 (requested by the user 2026-10-01). Generated by `tools/furniture/generate_furniture.py`. (built; Studio test pending: QA FN1–FN6)

## Caleb Full Event (approved by the user 2026-10-01)

Contract: ARCHITECTURE.md "Caleb Full Event (contract)". Music: the user's own tracks, ids in the MUSIC block at the top of `Config.luau`.

- [x] Contract: `Shared/CalebEvent.luau`, Config settings, architecture section (lead).
- [x] Core: `CalebCycle` state machine, contributions, eligibility, reset, new cycle id. (code done; Studio test pending: QA CE1–CE10)
- [x] Caleb grows (fatness + overall scale), "I'm full" animation, dance, hidden during trophy claim (`StatueShape`, `CalebAnimator.client`). (code done; Studio test pending: QA CG1–CG10; `SetHidden` is called by StatueService on CalebCycle.StateChanged)
- [x] Event UI + screen VFX: "CALEB IS FULLLL!!!", COOKIE PARTY countdown, trophy claim countdown / closed. (code done; Studio test pending: QA EV1–EV14)
- [x] Cookie rain (client, pooled): `CookieRain.client` + `CookieRainLook`. Visual only, not collectable. (code done; Studio test pending: QA CR1–CR10)
- [x] Sound effects: `tools/audio/generate_sfx.py` + `CalebAudio.client` (original, synthesized).
- [ ] Upload `tools/audio/out/*.wav` to Roblox and paste the ids into `Config.CalebSounds` (user; steps in `tools/audio/README.md`).
- [x] Podium leaderboard "CALEB'S TOP FEEDERS": 4 corner boards in the statue's `Podium` folder + `CalebLeaderboard.client.luau`. (code done; needs Core's `CalebTopFeeders`; Studio test pending: QA LB1–LB9)
- [x] Leaderboard boards back to yellow: yellow panel + cookie dough `Board` part, as before PR #94 (requested by the user 2026-10-03); the cookie jar stays brown. (code done; Studio test pending: QA LB1, LB4)
- [x] Saving with DataStore: house purchases and trophies (user approved saving 2026-10-01). `DataService` + house restore on claim. (code done; Studio test pending: QA SV1–SV9)
- [x] Caleb Trophies: unique variants, 2-minute claim on the podium, Trophy Case build (5 slots) in the house that shows them. `TrophyVariants`, `TrophyService` (+ `TrophyModel`, `TrophyAccessories`), `TrophyPrompt.client`, `TrophyCase` build. (code done; Studio test pending: QA TR1–TR15, BF4, BF9, BF11)
- [x] Background music + party music + air horn slots; Caleb spit removed (requested by the user 2026-10-02). (code done; Studio test pending: QA MU1–MU8)
- [x] Music suspense: cut at Caleb FULL, horn, short silence, then party music (requested by the user 2026-10-02). (code done; Studio test pending: QA MU2–MU2d, MU4, MU6)
- [ ] Paste the ids for Tender Static / Air Horn / NO PARTY into Config (user).

## Cookie Party upgrade (approved by the user 2026-10-01)

The 60-second Cookie Party (Celebration) becomes one polished, chaotic,
funny celebration with collectable cookies, then straight into the existing
2-minute trophy claim. Contract: ARCHITECTURE.md "Cookie Party (contract)".
No completion screen (only the short "YOU COLLECTED" total), no leaderboard, no mini-events, no trophy changes.

- [x] Contract: `Shared/CookieParty.luau`, `Config.CookieParty*`, remotes, architecture section; Celebration is 60 s even in the fast dev cycle (lead).
- [x] Party server: `CookiePartyService` (+ `CookiePartySpawner`) spawns collectable cookies (Normal / Chocolate / Golden / Giant), validates collects, pays with EconomyService, final reward. (code done; Studio test pending: QA PS1–PS14)
- [x] Party cookies (client): pooled collectable cookies, collect pop / floating numbers / sparkles / sounds / earnings counter, rain ramps up with the phases. `CookiePartyCookies.client` + `CookiePartyLook` / `Motion` / `Feedback` / `Numbers` / `HUD`; `CookieRain` ramp. (code done; Studio test pending: QA PK1–PK16)
- [x] Caleb party: dance energy ramps per phase, throws cookies, laughs, speech bubbles, big "I'M FULL!" finale pose. `CalebAnimator.client` + `CalebPartyPoses` / `CalebPartyMoves` / `CalebMouth`, `CalebPartyBubble.client`. (code done; Studio test pending: QA CD1–CD12)
- [x] Party FX: 10…1 countdown, phase callouts, escalating lighting/VFX, finale explosion + reward pop, music + party SFX; original party SFX + music loop in `tools/audio/`. (code done; Studio test pending: QA PX1–PX14)
- [x] End-of-party total: "YOU COLLECTED 🍪 N!" (requested by the user 2026-10-01). `CookiePartyTotal` + `CookiePartyTotalBuild`. (code done; Studio test pending: QA PT1–PT9)
- [x] Fix: party cookies not collected with Caleb Trophy powers (bug found by the user 2026-10-02). Lag-aware server reach (`CookiePartyReach`: recent path + speed slack + jump reach), faster client re-asks, higher server rate limit. (code done; Studio test pending: QA CP1–CP7)
- [ ] Upload the new party sounds; paste ids into `Config.CookiePartySounds` (user).

## Post-MVP (needs approval)

- [ ] Teleport players to their plot on join/respawn.
- [ ] Handle a full server more gracefully than a warning.
- [x] DataStore persistence for cash (user approved 2026-10-02): `Cash` in the DataService record (Version 3), applied by `EconomyService` on load. (code done; Studio test pending: QA CS1–CS10)

## Polish (needs approval)

- [x] Purchase/collect feedback (sounds…) (user approved 2026-10-02): buy / build / can't afford / Collect payout / drop-in-jar sounds (`TycoonSounds`, `Config.TycoonSounds`). (code done; Studio test pending: QA TS1–TS8) (The cash display itself is done, see MVP.)
- [ ] Upload purchase/collect sounds and paste ids into Config.TycoonSounds (user). WAVs: `tools/audio/out/purchase.wav`, `purchase_build.wav`, `cant_afford.wav`, `collect_cookies.wav`, `drop_in_jar.wav` (see `tools/audio/README.md`).
- [ ] Cleaner prototype visuals (still no theme until approved).
- [x] Photo Mode for icon / thumbnail screenshots (user approved 2026-10-02): `Config.DevPhotoMode` (Studio only), fully built unsaved plot, sunny lighting, camera keys 1–6 / 0 / H (`DevPhotoMode`, `PhotoCamera`, `Shared/PhotoMode`). (code done; Studio test pending: QA PM1–PM8)

## Future features (needs approval)

- [ ] Upgrades (more droppers beyond the four are just new `Config.Droppers` entries + map parts).
- [ ] Anything else (monetization, rebirths, pets, etc.) only after the MVP is playable and tested.

## Trophy Collection + Powers (approved by the user 2026-10-01)

Contract: ARCHITECTURE.md "Trophy Collection + Powers (contract)".

- [x] Contract: `Shared/TrophyPowers`, `Remotes/TrophyEquip`, Config (`TrophyActiveSlots`, `TrophyRarityChances`, ...; `TrophyStatCaps` removed 2026-10-02) (lead).
- [x] Definitions: 6 rarities, Description/Powers/PowerText, new trophies, `RollReward`, looks (`TrophyVariantList`, `TrophyProps`, `TrophyEffects`). (code done; Studio test pending: QA TD1–TD5, TR14)
- [x] Inventory: saved InstanceIds + Equipped (Version 2), equip remote, reward roll at claim, display rules. `DataSchema`, `DataService`, `TrophyService` (+ `TrophyInventory`). (code done; Studio test pending: QA TE1–TE12, TR13)
- [x] Powers: `PowerService`, drop/collect/movement hooks, double jump. (code done; Studio test pending: QA PW1–PW12)
- [x] Big Trophy Case + nameplates: `tools/trophycase/generate_trophy_case.py` (~25 × 14.6 case, 10 slots, sign, warm lights), `TrophyCaseDisplay` slot order + nameplates, `TrophyCaseSlots = 10`. (code done; Studio test pending: QA TR9, TR16–TR18) (later redesigned to 5 slots, see below)
- [x] Trophy Case redesigned for 5 trophies with names on the bottom panel (requested by the user 2026-10-02). One row of 5 on a velvet podium stage, `NameplateN` plaques on the base (rarity-colored name + power, dim "EMPTY"), `TrophyCaseSlots = 5`, `TrophyCaseScale = 1.6`. (built; Studio test pending: QA TC1–TC9)
- [x] Trophy powers show on the house: fire on droppers, shine on the Collect pad (requested by the user 2026-10-01). (code done; Studio test pending: QA PV1–PV10)
- [x] Inventory UI: `TrophyInventory.client` + `TrophyInventoryUI` / `TrophyInventoryIcon` / `TrophyInventoryData` (needs Studio QA: TI1–TI14).
- [x] Trophy claim pop-up: what it does + EQUIP / CLOSE (requested by the user 2026-10-01). `TrophyClaimPopup` + `TrophyClaimPopupUI`, `InstanceId` in `CalebTrophyNotice`. (code done; Studio test pending: QA TP1–TP10)
- [x] Bigger walk speed trophies (+35%..+75%) and glowing feet (requested by the user 2026-10-01). (code done; Studio test pending: QA SG1–SG10)
- [x] Trophy powers: no stat caps, duplicates stack (requested by the user 2026-10-02). (code done; Studio test pending: QA ST1–ST8)
- [x] Studio test switch DevAllTrophies: every trophy × N, session only (requested by the user 2026-10-02). (code done; Studio test pending: QA DT1–DT7)
- [x] Power-up looks: speed trail + glowing feet, jump and double-jump effects (requested by the user 2026-10-02). (code done; Studio test pending: QA PL1–PL11)

## Garage + Backyard (approved by the user 2026-10-02)

After the house is maxed: a garage (1 Caleb Trophy, `TrophyButton1`) on the
house's right side. With the Walls: a backyard with 3 spots (5 trophies
each, `TrophyButton2`–`4`) behind the house. Decoration only.

Contract: ARCHITECTURE.md "Garage + Backyard (contract)". Three workers in parallel (garage model, backyard model, gameplay logic).

- [x] Gameplay logic: `Config.TrophyBuilds` + `BackyardTrophies` (Walls also shows `BackDoor`), `TrophyBuild` purchase kind (`TrophyButtonN`, unlock when the house is maxed, free for owners who own enough Caleb Trophies, saved/restored), trophy button labels, `BackyardGate` + `BackyardDoor` (locked back door + sign, push-out loop), trophy builds' fires/particles/lights on only while shown (`PlotStages`). (code done; Studio test pending: QA GB1–GB16)
- [x] Garage + car model: `tools/garage/generate_garage.py` (+ `id4_car.py`) adds `Garage` (attached brick garage, rolled-up door, workbench, rack, charger, disabled `GarageLight`s), `GarageCar` (white VW ID.4, nose out) and the gold `TrophyButton1` pad to Plot1; Plots 2–4 regenerated. (built; Studio look check pending: QA GG1–GG8)
- [x] Backyard model: `tools/backyard/generate_backyard.py` builds the pool (brick wall, coping, shallow water), flagstone path with rocks and dirt, stone patio hangout with a fire pit and 5 chairs, white picket fence, invisible `BackyardZone`, gold `TrophyButton2`–`4` pads, and the `BackDoor` (door + "🔒 BACKYARD" sign); back door opening in `tools/house/generate_house.py` (x 17..23, replaces the first floor's right back window); ground 400 × 400. Geometry only: visibility, the door lock and the fire's on/off are the game logic's job. (built; Studio test pending: QA BY1–BY10)
- [x] Drivable car (requested by the user 2026-10-02): `CarService` + `CarBuild` + `CarSeats`. Once the Garage is built, the plot's car is a physics car built at runtime from the `GarageCar` look (welded body, 4 motor wheels, servo-steered front wheels; no map changes). Only the owner drives (VehicleSeat, server ejects others); one passenger seat for anyone (prompts "Drive"/"Ride"). The driver gets network ownership while driving. Off the map edge / below `CarFallY`: the car re-parks in its garage and riders respawn at their plot's spawn; flipped + still re-parks. Removed on plot reset/leave. Knobs in `Config` (`Car*`). (code done; Studio test + physics tuning pending: QA CAR1–CAR14)
- [x] Car exit fix (reported by the user 2026-10-02: jumping out left you under the car): `CarSeats.placeBeside` now waits a frame, raycasts to the ground beside the door clear of the car's measured width, moves the body while the server owns it, and re-checks after `Config.CarExitSettleTime`. Knobs `CarExit*`. (code done; Studio test pending: QA CAR5, CAR5b, CAR5c)
- [x] Walk-in pool (requested by the user 2026-10-02): the pool is a raised basin (coping 3.6 studs above the grass, because the ground is one shared slab) with solid walls and floor, waist-deep walk-through water, and steps up to the coping and back down inside in the front +X corner; Pool pad moved to (−3, −95) to make room for the outside steps. No splash effect (no fitting sound in Config). (built; Studio test pending: QA BY5, WP1–WP6)
- [x] Backyard lock rework (requested by the user 2026-10-02): `BackyardFence` and the backyard pads (`TrophyButton2`–`4`, `After = "Walls"` in `Config.TrophyBuilds`) appear with the Walls build together with the `BackDoor` (garage pad still waits for the maxed house); no push-out, only the back door locks (`BackyardZone` and `BackyardCheckInterval`/`BackyardPushOut*` removed); door sign "🔒 Unlock this door once you have 5 Caleb Trophies" + small "🏆 x/5"; pads say "Must have N Caleb Trophies". (code done; Studio test pending: QA GB1–GB19, BY2, BY3, BY9)
