# SimpleTycoon TODO

Only the **MVP** section is approved for work. Everything below it needs the
user's approval first.

## Foundation (done)

- [x] Rojo mapping for Workspace, ReplicatedStorage, ServerScriptService, StarterPlayer, StarterGui.
- [x] Central `Config` module.
- [x] Service modules and `ServerMain` entry point.
- [x] PlayerDataService: $100 starting cash via `leaderstats`.
- [x] EconomyService: validated `AddCash` / `TrySpend`.
- [x] TycoonService: plot validation, assign on join, release on leave, owner sign.
- [x] Prototype map: spawn, one plot with button, dropper spot, conveyor, collector, collect pad (reduced from 4 plots to 1 on 2026-09-30).
- [x] Project docs (AGENTS, ARCHITECTURE, GAME_DESIGN, QA, README).

## MVP

- [ ] Verify the foundation in Studio (QA: B1–B2, P1–P2, T1–T2, E1, M1, R1, L1, L3).
- [x] Dropper purchase: implement `TycoonService.TryPurchaseDropper` and the Buy button trigger (needs Studio test: QA U1–U3, T3).
- [x] Show a simple dropper at `DropperSpot` once purchased. (code done; Studio test pending)
- [x] DropperService: spawn server-owned `$10` drops every 2 seconds; clean up on stop. (code done; Studio test pending)
- [x] Conveyor movement. (code done; Studio test pending)
- [x] CollectorService: store drop value at the collector; owner-only payout on the Collect pad (code done; Studio test waits on DropperService).
- [x] Show the plot's stored (uncollected) cash on the Collect pad label (approved with the collector task).
- [ ] Run the full `QA.md` in Studio, including 2-player tests.
- [x] Round, outlined pads for the Buy button, Collect pad, and spawn (approved 2026-09-30; Studio visual check pending).

## Post-MVP (needs approval)

- [ ] Show the price on the Buy button from `Config`.
- [ ] Teleport players to their plot on join/respawn.
- [ ] Handle a full server more gracefully than a warning.
- [ ] DataStore persistence for cash and purchases.

## Polish (needs approval)

- [ ] Simple cash UI and purchase/collect feedback (sounds, effects).
- [ ] Cleaner prototype visuals (still no theme until approved).

## Future features (needs approval)

- [ ] More droppers and upgrades.
- [ ] Anything else (monetization, rebirths, pets, etc.) only after the MVP is playable and tested.
