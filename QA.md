# SimpleTycoon QA

Manual test cases for Roblox Studio. Use **Play** for single-player cases and
**Test → Clients and Servers** (2 players) for multiplayer cases.

To inspect server state, switch the Studio view to **Server** (Test tab →
"Current: Client/Server" toggle) and look at `Players.<name>.leaderstats.Cash`
and the `OwnerUserId` attribute on `Workspace.Map.Plots.PlotN`.

Status key: ✅ pass · ❌ fail · ⏳ not testable yet (feature is a stub).
Record the date and result when you run a case.

## Build

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| B1 | `mkdir -p build && rojo build default.project.json --output build/SimpleTycoon.rbxlx` | Builds with no errors or warnings. | |
| B2 | Start Play. Check Output. | No errors from ServerMain or services. No "missing" or plot-count warnings. | |

## Player

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| P1 | Player joins. | Player spawns on the center spawn; no errors in Output. | |
| P2 | Check the player list (with `DevUnlimitedCash = false`). | Cash shows **100**. | |

## Tycoon

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| T1 | Player joins. | One plot's sign shows "<DisplayName>'s Tycoon"; that plot's `OwnerUserId` = player's UserId. | |
| T2 | Look at the map. | Exactly one plot, in front of the spawn. No other plots. | |
| T3 | Player 2 steps on Player 1's Buy buttons / Collect pad. | Nothing happens to either player's cash or plot; buttons stay red. | |
| T4 | Player joins; look at the Collect pads. | Every pad label reads "Collect". Stepping on your own pad with nothing stored does nothing. | |

## Purchase

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| U0 | Player joins; look at the four buy buttons. | Red, labeled "Dropper 1 - $100", "Dropper 2 - $300", "Dropper 3 - $1000", "Dropper 4 - $3000". | |
| U1 | Player with $100 steps on own "Dropper 1" button. | Cash → 0; button turns gray and says "Purchased"; a gray dropper appears at yellow spot 1. | |
| U2 | Player with less than $100 steps on "Dropper 1". (In **Server** view, set your `leaderstats.Cash` to 50 first.) | Nothing is bought; cash stays 50; button stays red. | |
| U3 | After buying, step on the same button again (repeatedly). | No second dropper; no cash removed. | |
| U4 | Buy in order: set Server cash to 4400, buy Dropper 1, 2, 3, 4. | Cash 4400 → 4300 → 4000 → 3000 → 0. Each button grays out; a dropper appears at each matching spot. | |
| U5 | Buy out of order: set Server cash to 3000, step on "Dropper 4" first. | Cash → 0; only Dropper 4 is bought (spot 4). Other buttons stay red. | |
| U6 | Can't afford: with $299 (Server view), step on "Dropper 2". | Nothing bought; cash stays 299; button stays red. | |
| U7 | Can't buy twice: after buying Dropper 3, step on it repeatedly (with cash ≥ 1000). | No cash removed; still one dropper at spot 3. | |

## Economy

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| E1 | In the **Client** view, change your `leaderstats.Cash` value. Switch to **Server** view. | Server value is unchanged. Buying still uses the server value. | |
| E2 | Code review: search for writes to `Cash`. | Only `EconomyService` changes cash. | |
| E3 | Collection. | Payout equals the sum of the values of the drops that reached the collector, paid once. | |
| E4 | With only Dropper 1, let 3 drops reach the collector. | Pad label reads "Collect $30" (increases by 10 per drop); cash unchanged. | |
| E5 | Step on your own Collect pad after E4, then stand/jump on it. | Cash +30 exactly once; label back to "Collect". | |
| E6 | Drop an unrelated part (e.g. from the Explorer in Server view) onto a collector. | Label and stored cash unchanged. | |

## Dropper

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| D1 | After buying, watch the dropper. | One drop about every 2 seconds. | |
| D2 | Watch a drop. | It rides the conveyor into the collector. | |
| D3 | Drops that fall off. | They are removed after `DropLifetime` seconds. | |
| D4 | Buy all four droppers; watch the collector. | Each dropper drops every 2 s onto the one conveyor; conveyor keeps moving; stored cash rises by 10/25/60/150 per drop from droppers 1/2/3/4. | |

## Dev cash (Studio only)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| DV1 | Set `DevUnlimitedCash = true` in `Config.luau`, Play in Studio. | Output shows one "[DEV] Unlimited cash is ON" line; cash shows 1000000000. Buying a dropper subtracts its cost. | |
| DV2 | Set `DevUnlimitedCash = false`, Play. | No "[DEV]" line; cash shows 100. | |
| DV3 | Code review: dev cash is gated by `RunService:IsStudio()` in `PlayerDataService`, and `DevUnlimitedCash` is `false` in the committed `Config.luau`. | Both true. | |

## Visuals

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| V1 | Look at the spawn, Buy button, and Collect pad. | Each is a flat circle lying on the ground with a darker ring around its edge; labels float readably above the pads. | |
| V2 | Walk across the rings only (not the pad centers). | Nothing is bought or collected; only touching the pad itself does. | |

## Multiplayer (2 players)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| M1 | Two players join. | Player 1 gets the plot (sign shows their name). Player 2 gets no plot; Output shows a "no free plot" warning. | |
| M2 | Player 2 steps on Player 1's Collect pad. | Player 2 gets nothing; Player 1's pad label and stored cash are unchanged. | |
| M3 | Player 2 steps on Player 1's Buy button. | Nothing happens; Player 2's cash stays 100. | |

## Respawn

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| R1 | Reset character (Esc → Reset). | Cash unchanged (not reset to 100, not doubled). Same plot. | |
| R2 | Reset after buying a dropper. | Same droppers as before; nothing bought again; no extra cash. | |

## Leaving

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| L1 | In a 2-player test, close Player 1's window. | Player 1's plot sign returns to "Unclaimed"; `OwnerUserId` removed; all Buy buttons back to red "Dropper N - $Cost". | |
| L2 | Leave after buying some droppers. | All droppers stop, drops are removed, conveyor stops, stored cash is cleared; pad label back to "Collect". | |
| L3 | A new player joins after L1. | They are given the released plot. (A player who was already in the game without a plot does not get it automatically.) | |
