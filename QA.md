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
| P2 | Check the player list. | Cash shows **100**. | |

## Tycoon

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| T1 | Player joins. | One plot's sign shows "<DisplayName>'s Tycoon"; that plot's `OwnerUserId` = player's UserId. | |
| T2 | Other plots. | Signs show "Unclaimed"; no `OwnerUserId` attribute. | |
| T3 | Player 2 steps on Player 1's Buy button / Collect pad. | Nothing happens to either player's cash or plot. | ⏳ |
| T4 | Player joins; look at the Collect pads. | Every pad label reads "Collect". Stepping on your own pad with nothing stored does nothing. | |

## Purchase

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| U1 | Player with $100 steps on own Buy Dropper button. | Cash → 0; dropper activates. | ⏳ |
| U2 | Player with less than $100 steps on the button. | Nothing is bought; cash unchanged. | ⏳ |
| U3 | After buying, step on the button again (repeatedly). | No second dropper; no cash removed. | ⏳ |

## Economy

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| E1 | In the **Client** view, change your `leaderstats.Cash` value. Switch to **Server** view. | Server value is unchanged. Buying still uses the server value. | |
| E2 | Code review: search for writes to `Cash`. | Only `EconomyService` changes cash. | |
| E3 | Collection. | Payout equals (number of drops that reached the collector) × `DropValue`, paid once. | ⏳ |
| E4 | Let 3 drops reach the collector. | Pad label reads "Collect $30" (increases by `DropValue` per drop); cash unchanged. | ⏳ |
| E5 | Step on your own Collect pad after E4, then stand/jump on it. | Cash +30 exactly once; label back to "Collect". | ⏳ |
| E6 | Drop an unrelated part (e.g. from the Explorer in Server view) onto a collector. | Label and stored cash unchanged. | ⏳ |

## Dropper

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| D1 | After buying, watch the dropper. | One drop about every 2 seconds. | ⏳ |
| D2 | Watch a drop. | It rides the conveyor into the collector. | ⏳ |
| D3 | Drops that fall off. | They are removed after `DropLifetime` seconds. | ⏳ |

## Multiplayer (2 players)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| M1 | Two players join. | Each gets a different plot; both signs show the right names. | |
| M2 | Player 2 steps on Player 1's Collect pad. | Player 2 gets nothing; Player 1's pad label and stored cash are unchanged. | ⏳ |
| M3 | Both buy droppers. | Each dropper only fills its own collector. | ⏳ |

## Respawn

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| R1 | Reset character (Esc → Reset). | Cash unchanged (not reset to 100, not doubled). Same plot. | |
| R2 | Reset after buying the dropper. | Still one dropper; not bought again; no extra cash. | ⏳ |

## Leaving

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| L1 | In a 2-player test, close Player 1's window. | Player 1's plot sign returns to "Unclaimed"; `OwnerUserId` removed. | |
| L2 | Leave after buying the dropper. | Dropper stops, drops are removed, stored cash is cleared; pad label back to "Collect". | ⏳ |
| L3 | A new player joins after L1. | They can be given the released plot. | |
