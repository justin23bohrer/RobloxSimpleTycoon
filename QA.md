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
| T2 | Look at the map. | Exactly one 66 × 66 plot, in front of the spawn. No other plots. | |
| T3 | Player 2 steps on Player 1's Buy button / Collect pad. | Nothing happens to either player's cash or plot; button stays. | |
| T4 | Step on the Claim Tycoon pad. | Claim pad disappears. Sign shows "<DisplayName>'s Tycoon"; `OwnerUserId` = your UserId. Conveyor (not moving), collector, Collect pad ("COLLECT!", bouncing arrow), and the empty cash tank appear. Only **one** buy button appears: "Dropper 1 / FREE!", with yellow spot 1 above the conveyor. | |
| T5 | Stepping on your own Collect pad right after claiming. | Nothing happens (nothing stored). | |
| T6 | Press Play and check Output before anyone claims. | No warnings about a missing `ClaimPad` or other plot parts; no "no free plot" warning on join. | |

## Layout (66 × 66 plot)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| LY1 | Press Play; walk from the spawn to the plot and around its edges. | The plot floor is 66 × 66 (2/3 the width and length of the old 100 × 100 one), starts just in front of the spawn, and the grass ground reaches past it on every side (no falling off the back). | |
| LY2 | Claim; stand at the front looking in. | Conveyor runs along the **left** side from front to back; collector in the back-left corner; cookie jar standing in the **middle** of the floor with the Collect pad on its front (spawn) side; owner sign at the front-right. The right half is empty. | |
| LY3 | Buy Dropper 1, then 2–4 (Server cash 4300). | Each button appears just right of the conveyor next to its yellow spot. Drops land on the conveyor and ride it **toward the back** into the collector (none fall off the sides); stored cash rises. | |
| LY4 | Collect at the cookie jar in the middle of the room. | The jar fills with small cookies as drops arrive at the collector; stepping on the Collect pad in front of it pays out as before. | |
| LY5 | Walk all the way around the cookie jar. | The only Collect pad is on the front (spawn) side. Behind and beside the jar there is nothing to step on that pays; the back is the plain back of the purple wall. Nothing overlaps the buy/build buttons, and you can walk between the jar and them. | |

## Statue

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| ST1 | Press Play; after spawning, turn the camera around (away from the plot). | A giant cartoon statue (~2 stories) on a stone pedestal stands behind the spawn, facing you, on the grass. | |
| ST2 | Look at the statue's face and outfit. | Big round head, shaggy dark-brown hair with fringe over the forehead and ears, big white eyes with tiny pupils, brows, small nose, wide grin with white teeth; dark navy long-sleeve shirt, gold chain, one hand on the hip; gray pants, white sneakers. A black cartoon outline around the whole statue. Nothing is floating or misaligned. | |
| ST3 | Walk into and jump on the statue/pedestal. | It's solid and doesn't move; nothing happens to cash or the plot. No errors in Output. | |
| ST4 | Walk around near the statue and look at it from the plot. | No noticeable lag. | |

## Feeding Caleb

Tip: set `DevUnlimitedCash = true` in Studio for the big-number cases (set it back before committing).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| FD1 | Turn around at the spawn; walk around the statue. | Four round orange pads with "FEED CALEB!" signs: in front of, behind, and on both sides of the pedestal. | |
| FD2 | Step on any feed pad. | The pop-up appears with a little bounce: yellow rounded panel, thick dark outline, FredokaOne text: "How many cookies do you want to feed Caleb?", "Caleb has eaten 0 / 1,000,000", empty bar, "You have N", amount box, 10 / 100 / 1K / ALL, Cancel, FEED!. | |
| FD3 | Type `abc12x3` in the amount box. | Only digits stay: `123`. | |
| FD4 | With 100 cookies, press 10 → FEED!. | Cookies 100 → 90 (counter pops). The pop-up closes right away and a corner notification says "Caleb ate 10 cookies!". Caleb visibly gets a bit fatter (belly, cheeks, chin, wider body) with a bouncy grow. Step off and back on: progress "10 / 1,000,000  (0.00%)" with a thin sliver of bar. | |
| FD5 | Feed more than you have (e.g. type 5000 with 90). | "You don't have that many cookies!"; cookies unchanged; Caleb unchanged. | |
| FD6 | Press Cancel; then walk off and back onto the pad. | Cancel closes it. It doesn't reopen while you stand there, but reopens after stepping off and back on. | |
| FD7 | Open the pop-up, then walk ~15 studs away. | It closes by itself. | |
| FD8 | Press FEED! with the box empty. | "Type how many cookies first!"; nothing sent. | |
| FD9 | With dev cash, feed 10,000 then 1,000,000. | At 10,000 he's about two thirds as fat as the max. The second feed spends only 990,000 (the room left); he's at max size; signs say "CALEB IS FULL!"; the pop-up says "Caleb is FULL!". Further feeds: "Caleb is FULL!", no cookies spent. | |
| FD10 | 2 players: Player 1 feeds while Player 2 has the pop-up open. | Player 2's progress and bar update live; both see Caleb grow. | |
| FD11 | Security (code review / Server view): the client can't feed from far away or feed fractions/negatives. | `StatueService` rejects non-whole, < 1, and players not within `StatueFeedRange` of a pad; only `EconomyService.TrySpend` takes cookies. | |
| FD12 | Phone (Device emulator): open the pop-up. | Fits the screen, text readable, buttons tappable, keyboard opens for the amount box. | |
| FD13 | Reset character with the pop-up open; leave and rejoin the server. | Pop-up closes when you walk/teleport away; nothing breaks. Caleb's size stays for the server session (resets only on a new server). | |
| FD14 | Open the pop-up; click **1K** twice, then **10**. | Amount box reads 2010 (each click adds). Progress text shows "(+2,010)". | |
| FD15 | With Caleb at 0, click **1K** until the box says 100000. | The lighter preview section grows with each click and ends at exactly 1/10 of the bar; text "+100,000 = 10.0%". Clearing the box makes it slide back. | |
| FD16 | Pick more than you have (e.g. 1K with 50 cookies). | The preview section turns red. FEED! still says "You don't have that many cookies!" from the server. | |
| FD17 | Feed 500,000 cookies (dev cash), then reopen. | Bar is exactly half full; text "500,000 / 1,000,000  (50.0%)". The preview before feeding showed the same spot. | |
| FD19 | Feed any amount, then click FEED! twice fast on the next feed. | Each successful feed closes the pop-up immediately; it never stays open after a feed. It doesn't reopen until you step off the pad and back on. | |
| FD20 | Open the pop-up; pick a small amount (10), a medium one (100,000), and feed until the bar is full. Check up close and on a phone (Device emulator). | The cookie-colored fill and the lighter preview always stay inside the white track with a thin white gap; they never touch or cover the dark outline, and the rounded ends stay clean. | |
| FD18 | Join, walk straight from the spawn to Caleb, and step on each of the 4 feed pads (also after walking far away and coming back). | The pop-up opens every time you step on a pad, on all four pads. It doesn't reopen until you step off after closing it. | |

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

## Building and the 2nd floor

Tip: set `DevUnlimitedCash = true` (Studio only) so you can buy everything quickly.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| BF1 | Claim; look at the right side of the plot. Buy Droppers 1–3. | No orange build button, no walls, stairs, or 2nd floor. You can walk straight off the plot on every side. | |
| BF2 | Buy Dropper 4. | One orange "Build Walls / 🍪 5000" button appears on the right side (x ≈ 16). No other new button. | |
| BF3 | Before buying the walls, in **Server** view make `BuildButton2` visible and touchable (`Transparency = 0`, `CanTouch = true`) and step on it with ≥ 8000 cookies. | Nothing is built; no cookies spent (Stairs needs Walls first). | |
| BF4 | Buy the walls. | Cookies −5000. Off-white brick walls with gray trim and dark windows appear around the plot with a gray-framed doorway in the middle of the front; the Build Walls button disappears; "Build Stairs / 🍪 8000" appears. You can walk in and out through the doorway only. The owner sign, conveyor, droppers, collect pad, and cookie jar still work inside. | |
| BF5 | Buy the stairs. | Cookies −8000. 16 cream steps appear along the right wall; "2nd Floor / 🍪 15000" appears. Walk up them: each step is climbable without jumping. The top reaches the top of the walls, and nothing is there yet (no floor). | |
| BF6 | Buy the 2nd floor. | Cookies −15000. A floor appears on top of the walls with a railing around the stair hole, plus the brick second story and the gray roof (see HS1). Walk up the stairs onto it. On the **left** side, directly above the first conveyor, is a second conveyor (not moving yet) and a green collector at its back end. "Dropper 5 / 🍪 20000" and its yellow spot appear next to it. Nothing on floor 1 is blocked or hidden by the new floor. | |
| BF7 | Buy Dropper 5. | A dropper appears at spot 5; cookies fall onto the 2nd-floor conveyor, which moves front → back (same as floor 1) into Collector2. Each arrival adds a small cookie to the cookie jar **downstairs**. Dropper 6's button appears. The floor-1 conveyor keeps running. | |
| BF8 | Go down and step on the Collect pad. | You get the cookies from both floors (e.g. with only Droppers 1 and 5 running: +10 per floor-1 cookie and +300 per floor-2 cookie). | |
| BF9 | Buy Droppers 6, 7, 8. | Each costs its price; each appears above Conveyor2; after Dropper 8 no buy buttons remain. | |
| BF10 | Try to fall: walk along every edge of the 2nd floor and around the stair hole. | The second-story walls and the hole railings stop you everywhere except at the top of the stairs. | |
| HS1 | With everything built, walk out the front doorway and look back at the house (also from each side and the back). | It looks like a two-story off-white brick house: gray corner posts, a gray band along the top of the first floor, dark windows with gray frames, grilles, and sills on every side (an arched one above the doorway and a wide one on the upper front), a gray shingle roof with a pointed front gable and a round vent, gray fascia under the roof edges. No parts flicker or poke through each other. | |
| HS2 | Walk inside both floors and around the stairs. | Windows also show (frame + dark glass) on the inside walls, except beside the stairs. You never snag on window frames, sills, or trim; the stairs still climb without jumping. Neither floor is too dark to play (note it if it is). | |
| HS3 | Before the walls are bought, and after leaving (plot reset). | None of the house shows: no walls, trim, windows, second story, or roof. | |
| BF11 | Leave (or 2-player L1) after building the 2nd floor. | Walls, stairs, 2nd floor, both conveyors' droppers, and all buttons disappear; both conveyors stop; the plot looks like T1 again. The next owner starts from Dropper 1 with nothing built. | |

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
| V5 | Claim the plot; look at the owner sign at the front-right from the spawn side, then from inside the plot, in daylight and at night. | The name is on the wall itself (not floating): a purple rounded panel with a thick dark outline inside a gold frame, white chunky text with a dark outline reading "<DisplayName>'s Tycoon", on both sides. Not darkened at night. In Studio the name is your Studio test name (e.g. "Player1"). After leaving and a new claim, it shows the new owner's name. | |
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
