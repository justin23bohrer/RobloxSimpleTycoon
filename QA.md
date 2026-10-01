# SimpleTycoon QA

Manual test cases for Roblox Studio. Use **Play** for single-player cases and
**Test → Clients and Servers** (2 players) for multiplayer cases.

To inspect server state, switch the Studio view to **Server** (Test tab →
"Current: Client/Server" toggle) and look at `Players.<name>.leaderstats.Cookies`
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
| P2 | Check the player list (with `DevUnlimitedCash = false`). | The column is named **Cookies** and shows **100**. | |

## Tycoon (claiming and unlocking)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| T1 | Player joins; look at the plot. | Only the floor and a round blue pad with a "CLAIM TYCOON!" sign show. No sign, conveyor, collector, Collect pad, cash tank, buy buttons, or yellow spots. You can walk where they would be. `OwnerUserId` is not set. | |
| T2 | Look at the map. | Exactly one plot, in front of the spawn. No other plots. | |
| T3 | Player 2 steps on Player 1's Buy button / Collect pad. | Nothing happens to either player's cash or plot; button stays. | |
| T4 | Step on the Claim Tycoon pad. | Claim pad disappears. Sign shows "<DisplayName>'s Tycoon"; `OwnerUserId` = your UserId. Conveyor (not moving), collector, Collect pad ("COLLECT!", bouncing arrow), and the empty cash tank appear. Only **one** buy button appears: "Dropper 1 / FREE!", with yellow spot 1 above the conveyor. | |
| T5 | Stepping on your own Collect pad right after claiming. | Nothing happens (nothing stored). | |
| T6 | Press Play and check Output before anyone claims. | No warnings about a missing `ClaimPad` or other plot parts; no "no free plot" warning on join. | |

## Purchase

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| U0 | Claim the plot. | Only "Dropper 1 / FREE!" is showing. | |
| U1 | Step on "Dropper 1 / FREE!" with 100 cookies. | Cookies stay **100**. Button 1 and yellow spot 1 disappear; a gray dropper appears at spot 1; the conveyor starts and drops fall every 2 s. The "Dropper 2 / 🍪 300" button and yellow spot 2 appear. Buttons 3 and 4 are still hidden. | |
| U2 | Can't afford: with 299 cookies (Server view), step on "Dropper 2". | Nothing bought; cash stays 299; button 2 stays. | |
| U3 | After buying, walk over where button 1 was (repeatedly). | No second dropper; no cash removed. | |
| U4 | Buy in order: set Server cash to 4300, buy Dropper 1, 2, 3, 4. | Cash 4300 → 4300 → 4000 → 3000 → 0. Each purchase hides that button and shows the next one; after Dropper 4 no buttons remain. A dropper appears at each spot. | |
| U5 | Order is enforced by the server: before buying Dropper 1, in **Server** view select `BuyButton2` and set `Transparency = 0`, `CanTouch = true`, then step on it with cash ≥ 300. | Nothing is bought; cash unchanged. (Only the next dropper can be bought.) | |
| U6 | Walk across the spots where the hidden buttons 2–4 are, before unlocking them. | Nothing happens; no cash removed. | |
| U7 | Can't buy twice: after buying Dropper 3, walk over where its button was, repeatedly (with cash ≥ 1000). | No cash removed; still one dropper at spot 3; the button stays hidden. | |

## Economy

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| E1 | In the **Client** view, change your `leaderstats.Cookies` value. Switch to **Server** view. | Server value is unchanged. Buying still uses the server value. | |
| E2 | Code review: search for writes to `Cash`. | Only `EconomyService` changes cash. | |
| E3 | Collection. | Payout equals the sum of the values of the drops that reached the collector, paid once. | |
| E4 | With only Dropper 1, let 3 drops reach the collector. | 3 small cookies in the cookie jar; no amount text anywhere; cash unchanged. | |
| E5 | Step on your own Collect pad after E4, then stand/jump on it. | Cash +30 exactly once; tank empties. | |
| E6 | Drop an unrelated part (e.g. from the Explorer in Server view) onto a collector. | No cookie added to the jar; stored cash unchanged. | |

## Dropper

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| D1 | After buying, watch the dropper. | One drop about every 2 seconds. | |
| D2 | Watch a drop. | It rides the conveyor into the collector. | |
| D3 | Drops that fall off. | They are removed after `DropLifetime` seconds. | |
| D4 | Buy all four droppers; watch the collector. | Each dropper drops every 2 s onto the one conveyor; conveyor keeps moving; stored cash rises by 10/25/60/150 per drop from droppers 1/2/3/4. | |

## Cookies

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CK1 | Buy Dropper 1 and watch the drops. | Each drop is a flat golden-brown cookie with dark chocolate chips on top, lying flat. It rides the conveyor into the collector, and each one that arrives adds a small cookie to the jar. | |
| CK2 | Watch cookies arrive at the collector for a while. | No cookie gets stuck on the collector (the chips never block a claim); none pile up there. | |

## Dev cash (Studio only)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| DV1 | Set `DevUnlimitedCash = true` in `Config.luau`, Play in Studio. | Output shows one "[DEV] Unlimited cash is ON ... 1000000000 cookies" line; Cookies shows 1000000000. Buying a dropper subtracts its cost (Dropper 1 is free). | |
| DV2 | Set `DevUnlimitedCash = false`, Play. | No "[DEV]" line; cash shows 100. | |
| DV3 | Code review: dev cash is gated by `RunService:IsStudio()` in `PlayerDataService`, and `DevUnlimitedCash` is `false` in the committed `Config.luau`. | Both true. | |

## Visuals

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| V1 | Look at the spawn and Claim pad; then claim and look at the Buy button and Collect pad. | Each is a flat circle lying on the ground with a darker ring around its edge; labels float readably above the pads. | |
| CT1 | Look behind the Collect pad. | Purple wall with a gold frame, pink "COOKIE JAR" sign readable from the pad side, glass tank on an orange stand. The wall doesn't block walking onto the pad. | |
| CT2 | Look above the pad. | A gold ▼ arrow bounces up and down, always. | |
| CT3 | Buy Dropper 1; watch a drop reach the collector. | One small cookie falls into the jar per drop; pad starts sparkling and glowing. | |
| CT4 | Buy several droppers; let 60+ drops arrive. | Tank fills, stops at about 60 small cookies, nothing spills out; collecting still pays the full stored amount. | |
| CT5 | Step on the pad with small cookies in the tank. | Gold sparkle burst; tank empties; sparkles/glow stop until the next drop. | |
| CT6 | In a 2-player test, Player 2 watches Player 1's tank fill and empty. | Player 2 sees the same small cookies, sparkles, and burst. | |
| CT7 | Try to jump into the tank. | The glass lid and walls keep you out; the small cookies don't pay anything if touched. | |
| V2 | Walk across the rings only (not the pad centers). | Nothing is bought or collected; only touching the pad itself does. | |
| V3 | Look at the signs above the Claim pad, then (after claiming) the buy button and Collect pad. Check from close up and ~40 studs away, in daylight and at night (Lighting `ClockTime = 0`). | Each sign is a bright rounded panel with a thick dark outline and white chunky text (same font as the cash display) with a dark outline: blue "CLAIM TYCOON!", red "Dropper N" with the price in yellow underneath (e.g. "🍪 300"; "FREE!" for Dropper 1; the cookie emoji renders, not a box), green "COLLECT!". Text stays inside the panel; no raw tags like `<font>` show; colors are not darkened at night; the Collect sign doesn't overlap the bouncing arrow. | |
| V4 | Look around the map from the spawn and from the plot. | All ground outside the plot is green grass (grass texture up close). The plot's gray floor, pads, conveyor, and cookie jar look the same as before. | |

## Cookie display (client UI)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| C1 | Player joins. | A yellow rounded panel with a thick dark outline, a round golden-brown cookie with 4 dark chips, and white "100" (no "$") appears at the bottom-center. The player list (top right) still shows Cookies 100. No errors in Output. | |
| C2 | Claim, buy Dropper 1, then collect (or in **Server** view set `leaderstats.Cookies` to 1250, then 1234567). | Text updates right away and matches the player list: e.g. "130", "1,250", "1,234,567". The panel does a quick bounce each time. | |
| C3 | Test → Device emulator: a phone (e.g. iPhone SE, landscape) and a large PC resolution. | Panel stays centered at the bottom, keeps its shape, text is readable and inside the panel, and it does not cover the thumbstick or jump button. | |
| C4 | Reset character (Esc → Reset). | Only one cash panel; it still shows the correct amount and still updates. | |

## Multiplayer (2 players)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| M1 | Two players join; Player 1 steps on the Claim pad, then Player 2 walks to where it was. | Player 1 gets the plot (sign shows their name). The Claim pad is gone, so Player 2 cannot claim; Player 2 has no plot. No warnings in Output. | |
| M2 | Player 2 steps on Player 1's Collect pad. | Player 2 gets nothing; Player 1's jar cookies and stored cash are unchanged. | |
| M3 | Player 2 steps on Player 1's Buy button (the one showing). | Nothing happens; Player 2's cash stays 100; the button stays. |
| M4 | Both players step on the Claim pad at the same moment. | Exactly one of them owns the plot; the other has none. | |

## Respawn

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| R1 | Reset character (Esc → Reset). | Cash unchanged (not reset to 100, not doubled). Same plot. | |
| R2 | Reset after buying a dropper. | Same droppers as before; nothing bought again; no extra cash. | |

## Leaving

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| L1 | In a 2-player test, after Player 1 buys some droppers, close Player 1's window. | The plot goes back to the T1 look: only the floor and the Claim Tycoon pad; droppers, drops, buttons, sign, and collect area are gone; `OwnerUserId` removed. | |
| L2 | Leave after buying some droppers. | All droppers stop, drops are removed, conveyor stops, stored cash is cleared; cash tank empty, pad sparkles/glow off. | |
| L3 | After L1, Player 2 (already in the game) steps on the Claim pad. | Player 2 gets the plot and sees exactly the T4 look: collect area and only "Dropper 1 / FREE!" (nothing left over from Player 1). | |
