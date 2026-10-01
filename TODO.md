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
- [x] Hip roof (all four sides slope, ridge, caps, soffit, fascia, front gable, chimney); droppers look like upside-down red party cups (`DropperCup`); guard rails on both conveyors and collectors so cookies can't fall off (approved by the user 2026-09-30). (code done; Studio test pending: QA HS1, CR1–CR3, U1)
- [x] Four plots around the statue (same distance, doorways facing it), each with its own spawn, for up to 4 players; Plots 2–4 and spawns 2–4 generated from Plot1 by `tools/plots/generate_plots.py`; ground enlarged to 300 × 300 around the statue (approved by the user 2026-09-30). (code done; Studio test pending: QA T2, M5–M8)
- [x] Giant cartoony statue behind the spawn, based on the user's reference photos (face/outfit from IMG_2755, hair from IMG_9026); generated by `tools/statue/generate_statue.py` (approved by the user 2026-10-01). (built; Studio look check pending: QA ST1–ST4)
- [x] Feed Caleb: 4 feed pads around the statue; cartoony "How many cookies do you want to feed Caleb?" pop-up; server-validated feeding via the `FeedStatue` RemoteFunction; Caleb gets fatter up to 1,000,000 cookies, then is full (approved by the user 2026-10-01). (code done; Studio test pending: QA FD1–FD13)
- [x] Feeder upgrade: 10 / 100 / 1K add on every click; progress bar is exact (eaten / 1,000,000, exact % in the text) with a preview of the picked amount; pop-up closes right after a successful feed (approved by the user 2026-10-01). (code done; Studio test pending: QA FD4, FD14–FD17, FD19)
- [x] Cookie jar sign restyle: the "COOKIE JAR" sign on the jar wall uses the cartoony sign style (pink rounded panel, thick dark outline, gold frame, FredokaOne), facing the Collect pad (requested by the user 2026-10-01). (done; Studio test pending: QA V6, CT1)
- [x] Progress bar above Caleb's head that everyone sees: "Caleb: N / 1,000,000 🍪" in the pop-up's style, "FULL!" at the max; client only, reads `CookiesEaten` (requested by the user 2026-10-01). (code done; Studio test pending: QA SB1–SB8)
- [x] Decide what happens when Caleb reaches 1,000,000 cookies: the Caleb Full Event (approved by the user 2026-10-01; see below).

- [x] Second-floor furniture: cartoony Bed, Gaming Desk, Shelves + TV, Mini Fridge, and Ninja Kitchen from the user's photos, laid out like the user's sketch; each bought with its own button, all unlocked with the 2nd Floor alongside Dropper 5 (requested by the user 2026-10-01). Generated by `tools/furniture/generate_furniture.py`. (built; Studio test pending: QA FN1–FN6)

## Caleb Full Event (approved by the user 2026-10-01)

Contract: ARCHITECTURE.md "Caleb Full Event (contract)". Music comes later (user will pick a track); sound effects only for now.

- [x] Contract: `Shared/CalebEvent.luau`, Config settings, architecture section (lead).
- [x] Core: `CalebCycle` state machine, contributions, eligibility, reset, new cycle id. (code done; Studio test pending: QA CE1–CE10)
- [x] Caleb grows (fatness + overall scale), "I'm full" animation, dance, hidden during trophy claim (`StatueShape`, `CalebAnimator.client`). (code done; Studio test pending: QA CG1–CG10; `SetHidden` is called by StatueService on CalebCycle.StateChanged)
- [x] Event UI + screen VFX: "CALEB IS FULLLL!!!", COOKIE PARTY countdown, trophy claim countdown / closed. (code done; Studio test pending: QA EV1–EV14)
- [x] Cookie rain (client, pooled): `CookieRain.client` + `CookieRainLook`. Visual only, not collectable. (code done; Studio test pending: QA CR1–CR10)
- [x] Sound effects: `tools/audio/generate_sfx.py` + `CalebAudio.client` (original, synthesized).
- [ ] Upload `tools/audio/out/*.wav` to Roblox and paste the ids into `Config.CalebSounds` (user; steps in `tools/audio/README.md`).
- [x] Podium leaderboard "CALEB'S TOP FEEDERS": 4 corner boards in the statue's `Podium` folder + `CalebLeaderboard.client.luau`. (code done; needs Core's `CalebTopFeeders`; Studio test pending: QA LB1–LB9)
- [x] Saving with DataStore: house purchases and trophies (user approved saving 2026-10-01). `DataService` + house restore on claim. (code done; Studio test pending: QA SV1–SV9)
- [x] Caleb Trophies: unique variants, 2-minute claim on the podium, Trophy Case build (5 slots) in the house that shows them. `TrophyVariants`, `TrophyService` (+ `TrophyModel`, `TrophyAccessories`), `TrophyPrompt.client`, `TrophyCase` build. (code done; Studio test pending: QA TR1–TR15, BF4, BF9, BF11)
- [ ] Celebration music (ask the user for a track).

## Post-MVP (needs approval)

- [ ] Teleport players to their plot on join/respawn.
- [ ] Handle a full server more gracefully than a warning.
- [ ] DataStore persistence for cash (purchases and trophies: see Caleb Full Event).

## Polish (needs approval)

- [ ] Purchase/collect feedback (sounds, effects). (The cash display itself is done, see MVP.)
- [ ] Cleaner prototype visuals (still no theme until approved).

## Future features (needs approval)

- [ ] Upgrades (more droppers beyond the four are just new `Config.Droppers` entries + map parts).
- [ ] Anything else (monetization, rebirths, pets, etc.) only after the MVP is playable and tested.

## Trophy Collection + Powers (approved by the user 2026-10-01)

Contract: ARCHITECTURE.md "Trophy Collection + Powers (contract)".

- [x] Contract: `Shared/TrophyPowers`, `Remotes/TrophyEquip`, Config (`TrophyActiveSlots`, `TrophyRarityChances`, `TrophyStatCaps`, ...) (lead).
- [ ] Definitions: 6 rarities, Description/Powers/PowerText, new trophies, `RollReward`, looks.
- [ ] Inventory: saved InstanceIds + Equipped (Version 2), equip remote, reward roll at claim, display rules.
- [ ] Powers: `PowerService`, drop/collect/movement hooks, double jump.
- [ ] Inventory UI.
- [ ] Big Trophy Case + nameplates.

