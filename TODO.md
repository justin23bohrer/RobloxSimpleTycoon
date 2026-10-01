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
- [x] Round, outlined pads for the Buy button, Collect pad, and spawn (approved 2026-09-30; Studio visual check pending).

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
- [x] Giant cartoony statue behind the spawn, based on the user's reference photos (face/outfit from IMG_2755, hair from IMG_9026); generated by `tools/statue/generate_statue.py` (approved by the user 2026-10-01). (built; Studio look check pending: QA ST1–ST4)
- [x] Feed Caleb: 4 feed pads around the statue; cartoony "How many cookies do you want to feed Caleb?" pop-up; server-validated feeding via the `FeedStatue` RemoteFunction; Caleb gets fatter up to 1,000,000 cookies, then is full (approved by the user 2026-10-01). (code done; Studio test pending: QA FD1–FD13)
- [x] Feeder upgrade: 10 / 100 / 1K add on every click; progress bar follows the statue's growth curve with a preview of the picked amount (approved by the user 2026-10-01). (code done; Studio test pending: QA FD4, FD14–FD17)
- [ ] Decide what happens when Caleb reaches 1,000,000 cookies (currently: max size, stops eating).

## Post-MVP (needs approval)

- [ ] Teleport players to their plot on join/respawn.
- [ ] Handle a full server more gracefully than a warning.
- [ ] DataStore persistence for cash and purchases.

## Polish (needs approval)

- [ ] Purchase/collect feedback (sounds, effects). (The cash display itself is done, see MVP.)
- [ ] Cleaner prototype visuals (still no theme until approved).

## Future features (needs approval)

- [ ] Upgrades (more droppers beyond the four are just new `Config.Droppers` entries + map parts).
- [ ] Anything else (monetization, rebirths, pets, etc.) only after the MVP is playable and tested.
