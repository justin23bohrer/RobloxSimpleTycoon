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
| T2 | Look at the map. | Exactly one plot, in front of the spawn. No other plots. | |
| T3 | Player 2 steps on Player 1's Buy button / Collect pad. | Nothing happens to either player's cash or plot; button stays red. | |
| T4 | Player joins; look at the Collect pads. | Every pad label reads "Collect". Stepping on your own pad with nothing stored does nothing. | |

## Purchase

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| U1 | Player with $100 steps on own Buy Dropper button. | Cash → 0; button turns gray and says "Purchased"; a gray dropper appears at the yellow spot. | |
| U2 | Player with less than $100 steps on the button. (To test now: in **Server** view, set your `leaderstats.Cash` to 50 first.) | Nothing is bought; cash stays 50; button stays red. | |
| U3 | After buying, step on the button again (repeatedly). | No second dropper; no cash removed. | |

## Economy

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| E1 | In the **Client** view, change your `leaderstats.Cash` value. Switch to **Server** view. | Server value is unchanged. Buying still uses the server value. | |
| E2 | Code review: search for writes to `Cash`. | Only `EconomyService` changes cash. | |
| E3 | Collection. | Payout equals (number of drops that reached the collector) × `DropValue`, paid once. | |
| E4 | Let 3 drops reach the collector. | Pad label reads "Collect $30" (increases by `DropValue` per drop); cash unchanged. | |
| E5 | Step on your own Collect pad after E4, then stand/jump on it. | Cash +30 exactly once; label back to "Collect". | |
| E6 | Drop an unrelated part (e.g. from the Explorer in Server view) onto a collector. | Label and stored cash unchanged. | |

## Dropper

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| D1 | After buying, watch the dropper. | One drop about every 2 seconds. | |
| D2 | Watch a drop. | It rides the conveyor into the collector. | |
| D3 | Drops that fall off. | They are removed after `DropLifetime` seconds. | |

## Cash display (client UI)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| C1 | Player joins. | A yellow rounded panel with a thick dark outline, a green "$" coin, and white "$100" appears at the bottom-center. The player list (top right) still shows Cash 100. No errors in Output. | |
| C2 | Buy the dropper, then collect (or in **Server** view set `leaderstats.Cash` to 1250, then 1234567). | Text updates right away and matches the player list: "$0", "$1,250", "$1,234,567". The panel does a quick bounce each time. | |
| C3 | Test → Device emulator: a phone (e.g. iPhone SE, landscape) and a large PC resolution. | Panel stays centered at the bottom, keeps its shape, text is readable and inside the panel, and it does not cover the thumbstick or jump button. | |
| C4 | Reset character (Esc → Reset). | Only one cash panel; it still shows the correct amount and still updates. | |

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
| R2 | Reset after buying the dropper. | Still one dropper; not bought again; no extra cash. | |

## Leaving

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| L1 | In a 2-player test, close Player 1's window. | Player 1's plot sign returns to "Unclaimed"; `OwnerUserId` removed; Buy button back to red "Buy Dropper". | |
| L2 | Leave after buying the dropper. | Dropper stops, drops are removed, stored cash is cleared; pad label back to "Collect". | |
| L3 | A new player joins after L1. | They are given the released plot. (A player who was already in the game without a plot does not get it automatically.) | |
