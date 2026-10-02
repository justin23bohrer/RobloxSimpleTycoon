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
| P1 | Player joins. | Player spawns on the grass at one of the four spawn areas; no errors in Output. | |
| P2 | Check the player list (with `DevUnlimitedCash = false`) as a new player (no save, or API access off). | The column is named **Cookies** and shows **100** (a returning player shows their saved cookies, see CS1). | |

## Tycoon (claiming and unlocking)

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| T1 | Player joins; look at the plot. | Only the floor and a round blue pad with a "CLAIM TYCOON!" sign show. No sign, conveyor, collector, Collect pad, cash tank, buy buttons, or yellow spots. You can walk where they would be. `OwnerUserId` is not set. | |
| T2 | Look at the map (fly around in Studio). | Four 66 × 66 plots around the statue, all the same distance from it, each with its Claim pad and front doorway facing the statue, and an (invisible) spawn area between each plot and the statue; no blue spawn discs anywhere. All on grass; nothing overlaps. Output shows no `NumberOfTycoonPlots` warning. | |
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
| FD2 | Step on any feed pad. | The pop-up appears with a little bounce: yellow rounded panel, thick dark outline, FredokaOne text: "How many cookies do you want to feed Caleb?", "Caleb has eaten 0 / 350,000" (solo; the goal is 350,000 per player, see GS1), empty bar, "You have N", amount box, 10 / 100 / 1K / ALL, Cancel, FEED!. | |
| FD3 | Type `abc12x3` in the amount box. | Only digits stay: `123`. | |
| FD4 | With 100 cookies, press 10 → FEED!. | Cookies 100 → 90 (counter pops). The pop-up closes right away and a corner notification says "Caleb ate 10 cookies!". Caleb visibly gets a bit fatter (belly, cheeks, chin, wider body) with a bouncy grow. Step off and back on: progress "10 / 350,000  (0.00%)" (solo) with a thin sliver of bar. | |
| FD5 | Feed more than you have (e.g. type 5000 with 90). | "You don't have that many cookies!"; cookies unchanged; Caleb unchanged. | |
| FD6 | Press Cancel; then walk off and back onto the pad. | Cancel closes it. It doesn't reopen while you stand there, but reopens after stepping off and back on. | |
| FD7 | Open the pop-up, then walk ~15 studs away. | It closes by itself. | |
| FD8 | Press FEED! with the box empty. | "Type how many cookies first!"; nothing sent. | |
| FD9 | Solo, with dev cash, feed 10,000 then 1,000,000. | At 10,000 he's about two thirds as fat as the max. The second feed spends only 340,000 (the room left under the 350,000 goal); he's at max size; signs say "CALEB IS FULL!"; the pop-up says "Caleb is FULL!". Further feeds: "Caleb is FULL!", no cookies spent. | |
| FD10 | 2 players: Player 1 feeds while Player 2 has the pop-up open. | Player 2's progress and bar update live; both see Caleb grow. | |
| FD11 | Security (code review / Server view): the client can't feed from far away or feed fractions/negatives. | `StatueService` rejects non-whole, < 1, and players not within `StatueFeedRange` of a pad; only `EconomyService.TrySpend` takes cookies. | |
| FD12 | Phone (Device emulator): open the pop-up. | Fits the screen, text readable, buttons tappable, keyboard opens for the amount box. | |
| FD13 | Reset character with the pop-up open; leave and rejoin the server. | Pop-up closes when you walk/teleport away; nothing breaks. Caleb's size stays for the server session (resets only on a new server). | |
| FD14 | Open the pop-up; click **1K** twice, then **10**. | Amount box reads 2010 (each click adds). Progress text shows "(+2,010)". | |
| FD15 | Solo, with Caleb at 0, click **1K** until the box says 35000. | The lighter preview section grows with each click and ends at exactly 1/10 of the bar; text "+35,000 = 10.0%". Clearing the box makes it slide back. | |
| FD16 | Pick more than you have (e.g. 1K with 50 cookies). | The preview section turns red. FEED! still says "You don't have that many cookies!" from the server. | |
| FD17 | Solo, feed 175,000 cookies (dev cash), then reopen. | Bar is exactly half full; text "175,000 / 350,000  (50.0%)". The preview before feeding showed the same spot. | |
| FD19 | Feed any amount, then click FEED! twice fast on the next feed. | Each successful feed closes the pop-up immediately; it never stays open after a feed. It doesn't reopen until you step off the pad and back on. | |
| FD20 | Open the pop-up; pick a small amount (10), a medium one (100,000), and feed until the bar is full. Check up close and on a phone (Device emulator). | The cookie-colored fill and the lighter preview always stay inside the white track with a thin white gap; they never touch or cover the dark outline, and the rounded ends stay clean. | |
| FD18 | Join, walk straight from the spawn to Caleb, and step on each of the 4 feed pads (also after walking far away and coming back). | The pop-up opens every time you step on a pad, on all four pads. It doesn't reopen until you step off after closing it. | |

## Caleb growth and animations

Tip: set `DevCalebFastCycle = true` in Studio (goal 1,000 cookies; Full 3 s,
Celebration 60 s, TrophyClaim 30 s) and `DevUnlimitedCash = true`. Set both
back before committing. Feed amounts below are for the 1,000 goal.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CG1 | Press Play; look at Caleb (0 fed). | Normal size, thin, feet on the pedestal; nothing floating or sunk into the pedestal. | |
| CG2 | Feed up to 250, 500, 750, 900, 990 total, looking at him from the same spot after each. | Every step is visibly bigger than the last (fatter first, then clearly taller/wider); feet always stay on the pedestal top; belly, cheeks, chin, chain, arms, and hair stay attached at every size. Each change is a bouncy grow. | |
| CG3 | Feed the last 10 (to 1,000). | A visible final jump to max size (1.6×). Then the Full animation starts. | |
| CG4 | Watch the Full state. | He waddles, leans back with arms out, belly bounces, puffs a white cloud from his mouth with a head jolt, settles. Looks funny, nothing detaches or flies off. | |
| CG5 | Watch Celebration. | He dances the whole time: sway + hop per beat, arms alternate waving, head bobs, belly jiggles, with party moves mixed in (see "Cookie Party: Caleb"). Only Caleb moves: pedestal, feed pads, podium stay put. No errors in Output. | |
| CG6 | Wait for TrophyClaim. | Caleb's body is gone (invisible, can walk through where he was); the pedestal, the 4 feed pads, and the podium are still there. The cartoon outline doesn't draw a ghost of him. | |
| CG7 | Wait for the reset (back to Normal). | Caleb is back, at his smallest, thin, in his normal pose, feet on the pedestal; not stuck in a dance pose. | |
| CG8 | 2 players: Player 2 joins in the middle of Celebration. | Player 2 sees him dancing right away, at the same moment of the dance as Player 1 (moves line up). When it ends both see him stop in the normal pose. | |
| CG9 | During Celebration, walk far away (until the statue streams out) and come back; also reset your character mid-dance. | He is dancing again when you come back; no part stays offset or frozen; one dance only (no double speed). | |
| CG10 | Performance: in Normal and TrophyClaim, check the MicroProfiler / Script Performance for `CalebAnimator`. | No per-frame work outside Full/Celebration. | |

## Statue progress bar

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| SB1 | Press Play; look at Caleb from the spawn. | A yellow rounded panel with a thick dark outline floats above his head (clear of the hair): "Caleb: 0 / 350,000 🍪" (solo) in FredokaOne over an empty white bar. It looks like the feed pop-up's bar. | |
| SB2 | Walk to each plot (and inside a house) and look toward the statue. | The bar is visible and readable from every plot, drawn over roofs; it stays the same size on screen. | |
| SB3 | Feed 10 cookies (solo). | Text "Caleb: 10 / 350,000 🍪"; a thin sliver of fill slides in; the panel pops. | |
| SB4 | Solo, feed 175,000 (dev cash). | Text "Caleb: 175,010 / 350,000 🍪" (commas); bar just over half full. | |
| SB5 | Solo, feed until 350,000. | Text "Caleb is FULL! 350,000 🍪"; bar completely full, fill stays inside the outline. As Caleb reaches max size the bar is still clear of his head. | |
| SB6 | 2 players: Player 1 feeds. | Player 2's bar updates at the same time, wherever Player 2 is. | |
| SB7 | 2 players: Player 1 feeds some cookies, then Player 2 joins (late joiner). | Player 2's bar shows the current total right away, not 0. | |
| SB8 | Reset character; phone (Device emulator). | The bar stays (no duplicate bars after respawn); readable on a phone. No errors in Output. | |

## Caleb Full Event (core)

Tip: set `DevCalebFastCycle = true` (and `DevUnlimitedCash = true`) in Studio for these; set both back to false before committing. With fast cycle the goal is 1,000 and the states last 3 s / 20 s / 30 s. Watch the statue's attributes (`CookiesEaten`, `CalebState`, `CalebCycleId`, `CalebStateEndsAt`, `CalebTopFeeders`) and each player's `CalebFed` / `CalebTrophyClaimed` in the Properties panel (server view).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CE1 | Fast cycle on. Press Play. | Statue: `CalebState = Normal`, `CalebMaxCookies = 1000`, `CookiesEaten = 0`, a GUID `CalebCycleId`, `CalebStateEndsAt = 0`, `CalebTopFeeders = []`. Player: `CalebFed = 0`, `CalebTrophyClaimed = false`. | |
| CE2 | Feed 100, then 50. | `CookiesEaten = 150`, your `CalebFed = 150`. Within ~1 s `CalebTopFeeders` lists you with 150 (one update for quick feeds in a row, never more than once a second, and the last value always shows up). | |
| CE3 | 2 players (Clients and Servers), both at 900 total: both feed 500 at the same moment. | The total ends at exactly 1,000. The first feed spends 100 (room left), the second is refused "Caleb is FULL!" with no cookies spent. Each player's `CalebFed` matches what they actually spent. | |
| CE4 | Reach the goal. | `CalebState` goes Full → (3 s) Celebration → (20 s) TrophyClaim → (30 s) Normal, each exactly once (no double jumps). `CalebStateEndsAt` is about now + the state's length. Pad signs say "CALEB IS FULL!" until reset. Caleb is hidden during TrophyClaim. | |
| CE5 | Try to feed during Full, Celebration, and TrophyClaim. | Refused "Caleb is FULL!"; no cookies spent; total stays at the goal. | |
| CE6 | Reach the goal only once; wait the whole event. | Only one event runs; nothing starts a second Full while one is running. | |
| CE7 | Player A feeds this cycle, leaves before TrophyClaim, rejoins the same server. | After rejoining, `CalebFed` is restored (same number) and `CalebTrophyClaimed` is unchanged; during TrophyClaim A is still eligible (`CalebCycle.IsEligible(A.UserId)`). | |
| CE8 | Player B joins after the goal is reached (during Full/Celebration/TrophyClaim). | B's `CalebFed = 0`; B is not eligible. | |
| CE9 | After the reset (back to Normal). | New `CalebCycleId`; `CookiesEaten = 0`; `CalebTopFeeders = []` right away; everyone's `CalebFed = 0` and `CalebTrophyClaimed = false`; Caleb visible at his smallest size; pads say "FEED CALEB!"; feeding works again and the next goal starts a new event. | |
| CE10 | Fast cycle off (normal). | Goal 350,000 per player, at most 1,000,000 (see GS1–GS10); Full 5 s, Celebration 60 s, TrophyClaim 120 s. `DevCalebFastCycle` has no effect in a published game. | |

## Caleb goal per player

The goal is `Config.CalebGoalPerPlayer` (350,000) × players in the server,
at most `Config.StatueMaxCookies` (1,000,000) (requested by the user
2026-10-02). Use `DevUnlimitedCash = true` and Test > Clients and Servers
(set it back before committing). Watch the statue's `CalebMaxCookies`,
`CookiesEaten`, `CalebState` in the Server view.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| GS1 | Solo Play (fast cycle off). | `CalebMaxCookies = 350000`. Bar above Caleb "Caleb: 0 / 350,000 🍪"; pop-up "0 / 350,000"; board "🍪 0 / 350,000". | |
| GS2 | Solo: feed 100,000. Then a 2nd player joins (Clients and Servers, 2 players). | `CalebMaxCookies = 700000` right away. On both clients the bar reads "100,000 / 700,000" and shrinks to about 1/7; an open pop-up's text, bar, and preview update; the board footer updates. Caleb gets a bit smaller (same cookies, bigger goal). | |
| GS3 | 3 players, then 4. | 3 players: 1,000,000. 4 players: still 1,000,000 (cap). | |
| GS4 | 2 players: feed 500,000 total (goal 700,000). Player 2 leaves. | Goal drops to 350,000 ≤ 500,000: `CalebState` goes to Full right away, exactly once (one "CALEB IS FULL" screen message, one burp), then the normal Celebration → TrophyClaim → reset. Both feeders' `CalebFed` are kept; Player 1 can claim a trophy. | |
| GS5 | 2 players: feed 200,000 total (goal 700,000). Player 2 leaves. | Goal 350,000; still Normal; bar "200,000 / 350,000"; Caleb grows to the new progress. | |
| GS6 | Reach the goal; during Full, Celebration, and TrophyClaim have a player join and another leave. | `CalebMaxCookies` does not change during the event; nothing restarts or fires twice. | |
| GS7 | After GS6, wait for the reset. | The new cycle's goal is 350,000 × the players in the server right now (max 1,000,000). | |
| GS8 | Solo (goal 350,000): type 1,000,000 and FEED! (dev cash). Also press ALL. | Only 350,000 is spent; total exactly 350,000; Caleb is full. ALL fills in at most the room left under the current goal. The server never goes past the goal. | |
| GS9 | `DevCalebFastCycle = true`, 1 and 2 players. | Goal stays 1,000 regardless of player count; joining/leaving doesn't change it. (Set it back to false.) | |
| GS10 | Plot: buy Walls, then look at the next buttons. | "Build Stairs / 🍪 5000"; after buying the stairs, "2nd Floor / 🍪 10000". The right amounts are spent. | |

## Feed pads while Caleb is full, and glare

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| FP1 | Reach the goal, then walk onto any feed pad during Full, Celebration, and TrophyClaim. | No feed pop-up opens. The pads, rings, and their signs are gray and say "CALEB IS FULL!". | |
| FP2 | Stand on a pad with the pop-up open while someone else feeds the last cookies. | The pop-up closes by itself. | |
| FP3 | After the reset (Normal). | Pads are back to their orange colors, sign says "FEED CALEB!", the pop-up opens again. | |
| GL1 | Look at the podium, leaderboards, and Caleb's chain, in Normal and during COOKIE PARTY (day and night). | Gold trim is plain gold, not glowing; nothing is blinding. The party glow is soft. | |

## Cookie rain (Caleb Full Event)

Needs the Caleb cycle (`CalebCycle`) merged. Set `Config.DevCalebFastCycle = true`
(Studio only; Celebration always lasts 60 s) and dev cash, then feed Caleb to the goal.
Without CalebCycle you can fake it: in the **Server** view, set the attribute
`CalebState` on `Workspace.Map.Statue` to `Celebration`, then back to `Normal`.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CR1 | Before the goal (state `Normal`), and during `Full`. | No cookies fall. No `CookieRain` folder in Workspace (client view). | |
| CR2 | Reach the goal; wait for `Celebration`. | Cookies start falling from the sky all around the statue and the plots: round golden-brown cookies with dark chips (like the dropper cookies, a bit bigger). They spin and wobble while falling; on landing (ground, roofs, pads) they hop a little, give a small dusty puff, and fade out. Plenty land around you wherever you stand inside the map. | |
| CR3 | Walk into a house and to the far edge of the map during Celebration. | Cookies keep falling near you, landing on roofs/floors (not under the ground, not floating in mid-air nearby). Nothing falls farther than `CookieRainRadius` (150) from the statue. | |
| CR4 | Walk/jump into falling and landed cookies; click them. | You pass straight through; nothing to pick up; cookies counter unchanged (visual only). | |
| CR5 | Wait for `Celebration` to end (`TrophyClaim`). | No new cookies; the ones in the air land and fade. A few seconds later the client's `Workspace.CookieRain` folder and the `CookieRainPuff` attachment in `Workspace.Terrain` are gone. Nothing left over. | |
| CR6 | Count during the rain: in the client view, the number of `Cookie` parts in `Workspace.CookieRain`. | Never more than `CookieRainMaxCookies` (120) cookies (each cookie = 1 `Cookie` + 5 `Chip` parts, so at most 720 parts). The count stops growing after a few seconds (parts are reused, not created per cookie). | |
| CR7 | Server view during the rain. | No `CookieRain` folder and no rain cookies on the server (client-only). | |
| CR8 | 2 players: Player 2 joins in the middle of `Celebration`. | Player 2 sees the rain start right away and stop when it ends, same as Player 1. | |
| CR9 | Two cycles in a row (fast cycle). | The rain works again in the second Celebration; no duplicate folders. | |
| CR10 | 4 players (Test > Clients and Servers), all near the statue during the rain; check FPS (Shift+F5 / MicroProfiler). | FPS stays smooth on every client; no errors or warnings in Output. | |

## Caleb event UI

Set `DevCalebFastCycle = true` (Studio only) to run the event quickly
(goal 1,000; Full 3 s, Celebration 60 s, TrophyClaim 30 s). Needs the Core
`CalebCycle` to be merged to drive the states.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| EV1 | Play; stay in Normal. | No event UI on screen; only the bar above Caleb ("Caleb: N / goal 🍪", goal from `CalebMaxCookies`). | |
| EV2 | Feed Caleb to the goal. | "🍪 CALEB IS FULLLL!!! 🍪" slams in (huge and tilted → normal, then a short wobble), quick white flash, small camera shake that ends with the camera back where it was, confetti falls and disappears. Bar above Caleb: "Caleb is FULL!". | |
| EV3 | Full ends → Celebration. | Big text fades out. Pink "🎉 COOKIE PARTY! 🎉" banner pops in at the top (below the Roblox top bar) with m:ss counting down a few times per second. The world gets a light warm tint + glow. Bar above Caleb: "🎉 COOKIE PARTY! 🎉". | |
| EV4 | Celebration → TrophyClaim, as a player who fed. | Party banner gone; lighting fades back to normal. Gold banner: "🏆 CALEB TROPHY AVAILABLE!", "You helped feed Caleb!", "Claim your trophy on Caleb's podium before time runs out!", "TROPHY CLAIM: m:ss" counting down. Bar: "Caleb is resting... 💤". | |
| EV5 | Claim the trophy on the podium (needs TrophyService). | Gold banner replaced by a small "Trophy claimed! 🏆". | |
| EV6 | 2 players: only Player 1 fed. During TrophyClaim, look at Player 2. | Player 2 sees the small "CALEB IS RESTING — new round soon  m:ss", not the trophy banner. | |
| EV7 | TrophyClaim ends (new round). | "TROPHY CLAIM CLOSED" for about 4 s (`CalebClosedMessageSeconds`), then nothing. Bar back to "Caleb: 0 / goal 🍪". | |
| EV8 | After the event: check Lighting in the Explorer (client view). | `CalebPartyColor` and `CalebPartyBloom` are disabled (neutral); colors look exactly as before the party. Only one of each exists after several rounds. | |
| EV9 | 2 players: Player 2 joins during Celebration. | Party banner with the correct time left (matches Player 1 within a second) and party lighting, right away. | |
| EV10 | Player 2 joins during TrophyClaim (did not feed). | "CALEB IS RESTING — new round soon" with the correct countdown. | |
| EV11 | Player who fed leaves during Celebration and rejoins during TrophyClaim. | Trophy banner (their `CalebFed` is restored). | |
| EV12 | Join during Full. | The big text and confetti show; no flash or camera shake. | |
| EV13 | Reset your character during Celebration / TrophyClaim. | Banners stay (no duplicates); no errors. | |
| EV14 | Phone (Device emulator) during each state. | Banners readable, inside the screen, not covering the cookie counter. No errors in Output. | |

## Cookie Party: server cookies and rewards

Set `Config.DevCalebFastCycle = true` (Studio only; the party is still 60 s)
and dev cash, then feed Caleb to the goal. Set both back to false before
committing. Until the client cookies exist, watch spawns from a client's
command bar: `game.ReplicatedStorage.Remotes.CookiePartySpawn.OnClientEvent:Connect(function(b) for _, c in b do print(c.Id, c.Type, c.Position, c.LandAt, c.FromCaleb) end end)`
(and the same for `CookiePartyCollected`). Fire collects with
`game.ReplicatedStorage.Remotes.CookiePartyCollect:FireServer(id)`.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PS1 | Watch the server through Celebration (Output, Script Performance, Workspace). | `CookiePartySpawn` batches arrive about 4×/s from the start of the party; ids go up 1, 2, 3…; more per second as the phases go Start → Hype → Frenzy → Countdown; no Golden/Giant in the first 20 s. Never more than 80 (`CookiePartyMaxAlive`) alive. No new parts in Workspace from the server; no errors. | |
| PS2 | Look at spawn positions, also while standing inside a house on the 1st and on the 2nd floor. | Every `Position` is within 140 studs of the statue, on visible ground/floors/roofs/pads (not under the map, not on Caleb's head, not in mid-air). Many land near players, and near-player cookies land on the floor the player is on, also inside houses (not on the roof above them). `LandAt` ≈ now + 1.6, `ExpiresAt` = `LandAt` + 8. About 15–40 % `FromCaleb = true` (more later). | |
| PS3 | Walk onto a landed cookie of each type and fire a collect for its id. | Cookies go up by exactly its value (Normal 50, Chocolate 150, Golden 1,000, Giant 5,000; Giant also accepted from up to ~12 studs away). `CookiePartyEarned` rises by the value and `CookiePartyCount` by 1. Everyone receives `CookiePartyCollected(id, yourUserId, value, type)`. | |
| PS4 | 2 players stand on the same cookie; both fire a collect for its id (and fire it twice yourself). | Only one player is paid, once; one `CookiePartyCollected` for that id. | |
| PS5 | Fake ids: `FireServer(999999)`, `FireServer(1.5)`, `FireServer("5")`, `FireServer(0/0)`, `FireServer(math.huge)`, `FireServer(nil)`, `FireServer({})`. | Nothing paid, no errors in server Output, no kick. | |
| PS6 | Fire a collect for a real cookie that landed far (> 12 studs) from you, and one under/over you by more than 25 studs (e.g. you on a roof, cookie on the ground far below). | Not paid; the cookie stays collectable for someone else. | |
| PS7 | Fire a collect for a cookie right after it appears (before `LandAt` − 0.3) while standing on its spot. | Not paid. Once it has landed, the same request pays. | |
| PS8 | Wait until a cookie's `ExpiresAt` passes, then try to collect it. | `CookiePartyCollected(id, 0, 0, type)` arrives within ~0.75 s after `ExpiresAt`; collecting it after that pays nothing. | |
| PS9 | Spam: fire a collect 100 times in one frame for ids you stand near, plus random ids. | At most 12 requests per second are looked at; only real, valid cookies pay; server stays smooth; no errors. | |
| PS10 | While dead (reset and fire before respawn), or before Celebration / during TrophyClaim, fire collects with old ids. | Nothing paid. | |
| PS11 | Let the party end (2 players). | At the switch to `TrophyClaim` each player gets exactly +5,000 (`CookiePartyFinalReward`) once and one `CookiePartyFinale(5000)`. Every still-alive cookie gets `CookiePartyCollected(id, 0, 0, type)`. No spawns in the last 1.6 s or after the party. | |
| PS12 | Two cycles in a row. | Second party starts at id > the first party's last id, earnings reset to 0 at its start, final reward paid once per party (never twice, never for a stale cycle). No leftover loop (spawns stop between parties). | |
| PS13 | Player 2 joins mid-party. | Player 2 gets one `CookiePartySpawn` with all currently alive cookies right away (then the normal batches), has `CookiePartyEarned = 0`, can collect, and receives the final reward if still in the server at the end. A player who left before the end gets no final reward. | |
| PS14 | Player leaves mid-party and rejoins the same server. | No errors; their party earnings start again at 0; they get the alive cookies and the final reward (if present at the end). Cookie total (`leaderstats`) behaves like any rejoin. | |

## Cookie Party: collectable cookies (client)

Needs the party server (`CookiePartyService`). Set `Config.DevCalebFastCycle = true`
(Studio only; the party is still 60 s) and dev cash, then feed Caleb to the goal.
Sounds need ids in `Config.CookiePartySounds` (empty = silent, no errors).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PK1 | Before the goal and during `Full`. | No collectable cookies, no `CookiePartyCookies` folder in Workspace (client view), no "🍪 +0" counter. | |
| PK2 | Party starts (`Celebration`). | The "🍪 +0" counter appears at the right side, upper-middle (not over the top banner, the bottom cookie counter, or the trophies button). Collectable cookies start falling from the sky with spin/wobble; a faint glowing disc appears where each will land and gets stronger as it falls. | |
| PK3 | Watch cookies land. | Each touches down right on its glowing disc (not floating, not under the ground), puffs, bounces once, then bobs and spins standing up like a coin. Giants hop. | |
| PK4 | Look at the four types. | Normal: golden-brown with dark chips. Chocolate: dark brown with white chips. Golden: bright gold, glowing, sparkling, slow spin, light pillar. Giant: about 2.7× bigger, chunky, pink beacon + pillar. | |
| PK5 | Watch Caleb during the party. | Some cookies arc out of Caleb's mouth and land around the map at the same moment they would from the sky. | |
| PK6 | Run into a Normal cookie. | Right away: it leans toward you, then pops (grows, shrinks into you), a sparkle + confetti burst, a yellow "+50" rises and fades, the collect sound plays; the counter shows "🍪 +50" with a pop and the bottom cash counter goes up 50. | |
| PK7 | Collect a Golden and a Giant. | Bigger gold "GOLDEN! +1,000" / pink "GIANT!! +5,000", bigger burst, their own sounds (if ids are set). | |
| PK8 | Collect 3+ cookies quickly. | "x3 COMBO!", "x4 COMBO!"… under the counter; the collect sound pitch rises a little each time; after ~1.4 s without collecting the combo text hides. | |
| PK9 | Stand still and let a cookie sit. | It blinks for its last ~1.5 s, then fades out. | |
| PK10 | 2 players: both run to the same cookie. | Only one gets it (the server decides). The winner sees the pop and "+N"; the other sees a small puff and the cookie vanishes (no "+N", their counter unchanged). | |
| PK11 | Lag test: Studio network settings with incoming replication lag ~0.5 s; collect cookies, including standing right at the edge of a cookie and sweeping fast through a pile. | No double rewards. A cookie the server refuses comes back within ~1 s and is asked for again while you stay on it (it still picks up; never more than one request in flight per cookie), at most 3 requests per cookie in all. No errors. | |
| PK12 | Player 2 joins in the middle of the party. | Counter shows right away; the cookies already on the ground appear (no fall), new ones fall normally. | |
| PK13 | Party ends (`TrophyClaim`). | The counter hides (no summary screen); all collectable cookies vanish (a pop already playing finishes); within a second the client's `Workspace.CookiePartyCookies` folder, the `CookiePartyBurst` attachment and the `CookiePartyNumber` attachments in `Terrain`, and the `CookiePartyNumber` guis in PlayerGui are gone. | |
| PK14 | Rain ramp: watch the visual rain from Start to Countdown. | Light rain at the start, clearly heavier in Hype, heavy in Frenzy/Countdown; golden-looking rain cookies appear from Hype and are common at the end. They still can't be picked up (no "+N"). Client view: never more than 170 rain `Cookie` parts in `Workspace.CookieRain`. | |
| PK15 | Two parties in a row (fast cycle). | Everything works again in the second party; no duplicate folders/guis; the counter starts at 0. | |
| PK16 | 4 players during Frenzy/Countdown; check FPS (Shift+F5 / MicroProfiler) and Output. | Smooth on every client; no errors or warnings. | |

## Cookie Party: Caleb

Feed Caleb to the goal (fast dev cycle is fine; the party is still 60 s).
Phases by seconds left: Start 60–40, Hype 40–20, Frenzy 20–10, Countdown 10–0.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CD1 | Watch the first seconds of the party (Start). | He eases into the dance and opens with a big laugh (head back and shaking, belly jiggling, bouncing, hands on his belly). Then roughly every 3.5 s a move, with plain dancing in between. Bubble: a Start line ("I'M SO FULL!!", "COOKIE PARTYYY!", ...) pops in above the progress bar. | |
| CD2 | Watch the phase changes at 40 s and 20 s left (Hype, Frenzy). | The dance gets faster and bigger each time **without a jump or snap** (it blends in over about a second; the beat never skips). Moves come more often and are bigger (Frenzy: back to back, spins are double spins, jumps higher). | |
| CD3 | Watch each move a few times. | THROW: one arm winds back and flings forward, body twists. There is no SPIT move any more (no crumb spray ever). LAUGH (as CD1). SPIN: hopping spin with arms out. JUMP: dip, big jump with arms up, squashy landing. DRUM: hands take turns slapping his belly, belly jiggles. Nothing detaches or stays offset; mouth, teeth, chin and cheeks go back into place after. | |
| CD4 | Frenzy (20–10 s left). | He goes crazy: fast alternating moves with a wobble/shake on top of everything. | |
| CD5 | Countdown (10–2.5 s left). | Bounces faster and faster; belly gets bigger and jiggles more; a few moves still. Bubbles: "SOMETHING'S HAPPENING...", "TOO... MANY... COOKIES...", "UH OH...". | |
| CD6 | Last 2.5 s. | No more moves: he crouches a little, arms pulled in hugging his belly, trembling harder and harder, belly puffing faster, cheeks puffed. In the last ~0.3 s he pops: arms flung wide, head thrown back, body pops up, belly pops big, mouth wide open, landing right at 0 together with the bubble "I'M FULL!!!" (yellow, big, shaking, shown for the last second) and the finale explosion. | |
| CD7 | The moment the party ends (TrophyClaim). | Caleb is hidden at once (the explosion is CookiePartyFinale's); no bubble or sound is left behind. Client view: `PlayerGui.CalebPartyBubble.Enabled` is false; the `Terrain.CalebMouth` puff emitter (if any) is `Enabled = false` with no particles. After the reset he is back in his normal pose and normal belly size (not swollen). | |
| CD8 | 2 players (Test → Clients and Servers): watch both windows side by side. | Same move, same bubble line at the same moment on both (within network lag). | |
| CD9 | Player 2 joins mid-party (e.g. in Hype, and again in the last 3 s). | Player 2 sees the right phase right away: same dance speed, same move and line as Player 1; joining during the wind-up shows the wind-up (not the start of the dance). | |
| CD10 | Look at the bubble from right next to the statue, from mid-map, and from a plot. | The bubble is always above the progress bar, never overlapping it, and clear of the center-screen countdown and top banner (it is in world space); disappears beyond the bar's max distance like the bar. | |
| CD11 | Sounds: with `Config.CookiePartySounds.CalebLaugh` empty, then with a real id. | Empty: no errors, nothing plays. With an id: a laugh at each LAUGH start, heard from Caleb's position (quieter far away). Nothing keeps playing after the party. | |
| CD12 | Performance + cleanup: MicroProfiler / Script Performance in Normal and TrophyClaim. | No per-frame work from `CalebAnimator` or `CalebPartyBubble` outside Full/Celebration. No new instances per party after the first (one `CalebMouth` attachment, one bubble billboard, reused). | |

## Cookie Party: countdown, VFX, finale, audio

Set `Config.DevCalebFastCycle = true` (Studio only; the party is still 60 s)
and dev cash, then feed Caleb to the goal. Sound cases need the
`tools/audio/` WAVs uploaded and their ids in `Config.CookiePartySounds`
(except PX12). Set the dev flags back before committing.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PX1 | Watch the whole 60 s party. | Banner "🎉 COOKIE PARTY! 🎉" + m:ss at the top. 60–40: pink, gentle pulse. At 40: banner turns orange, "MORE COOKIES! 🍪" slams in mid-upper screen, holds ~1.5 s, fades. At 20: gold banner, "✨ GOLDEN COOKIE FRENZY! ✨", the banner wobbles/shakes a little. At 10: red banner, stronger shake. Confetti bursts get more frequent (about every 8 → 5 → 3 → 2 s). | |
| PX2 | Watch the lighting through the party. | Warm tint + glow fades in at the start and gets more saturated/glowy toward the end, with a soft pulse about once per second in later phases. Nothing flashes full-screen more than ~2 times per second; it stays comfortable to play. | |
| PX3 | Last 10 seconds. | Huge numbers 10, 9, … 1 in the middle of the screen, each exactly once, slamming in (big + tilted → normal) in changing colors, with a small camera zoom punch. 3, 2, 1 are red, bigger, with a gold glow on the screen edges and a stronger punch. No "0". | |
| PX4 | 2 players (Test > Clients and Servers), both watching the countdown. | Both show the same number at the same time (within a frame or two of each other); neither skips or repeats a number. | |
| PX5 | Moment the party ends (Celebration → TrophyClaim), standing near the statue. | ~48 cookies (some golden) burst out of Caleb's head in every direction, arc, spin, bounce on the ground and fade; a crumb/sparkle burst, a quick glowing ball, an expanding ring on the ground, a white flash, a strong short camera shake, full confetti. | |
| PX6 | Same moment, as a player who fed. | The gold "🏆 CALEB TROPHY AVAILABLE!" banner with "TROPHY CLAIM: m:ss" shows immediately (during the explosion), exactly as before. Only the short "YOU COLLECTED" card (no results screen, no party leaderboard). The trophy claim works as before. | |
| PX7 | Same moment: watch the middle of the screen. | The "YOU COLLECTED" card with "+5,000 PARTY BONUS!" plays (see "Cookie Party: end total"). The counter goes up by 5,000 (the server paid it). | |
| PX8 | ~3 s after the finale: check Workspace (client view) and the camera. | No `CookiePartyFinale` folder and no finale cookies/ring/ball left. Countdown, callout, edge glow are hidden; the party banner is gone; `Camera.FieldOfView` is back to its normal value (70 by default). Run 2 cycles: still nothing left over, no errors in Output. | |
| PX9 | Player 2 joins during TrophyClaim. | No explosion, flash, shake, boom or total card for Player 2; just the TrophyClaim UI. | |
| PX10 | Player 2 joins mid-party (e.g. during Frenzy, or during the countdown). | Banner in the right phase color, lighting at the right level, no callout for the phase already running; if in the last 10 s, the countdown starts from the current number. At the end Player 2 sees the full finale (PX5–PX7). | |
| PX11 | Spend the party and finale far from the statue (at your plot). | Everything still runs; the finale still flashes/shakes and the trophy UI appears; no errors if Caleb's head is streamed out (explosion comes from above the pedestal instead). | |
| PX12 | All `CookiePartySounds` ids empty; run a full cycle. | Silent party (other sounds as configured). Output has at most one `[CalebAudio] no sound id ...` line (listing the missing ones) and no errors or warnings. | |
| PX13 | With ids: listen through the party. | The party music (`Config.CookiePartyMusic`) starts with the party, loops, plays at normal speed (no pitch change at 40 / 20 / 10 s left) and gets a little louder toward the end. A tick each second from 10 to 1, higher each time. At the finale the music stops at once and a big boom plays; the old descending end chime follows ~1.6 s later. | |
| PX14 | Run `python3 tools/audio/generate_sfx.py` twice. | 14 WAVs in `tools/audio/out/` (16-bit, 44.1 kHz, mono); effects under 300 KB, the music ~700 KB; re-running gives identical files. | |

## Cookie Party: end total

The "YOU COLLECTED 🍪 N" card at the finale (`CookiePartyTotal`). Same setup
as above (`Config.DevCalebFastCycle = true` in Studio only; set it back).
Sound ticks need `Config.CookiePartySounds.TotalTick` / `TotalLand` ids;
with empty ids it must be silent with no errors.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PT1 | Collect some party cookies, note the HUD "🍪 +N" just before the end. | At the finale the card says "YOU COLLECTED" and the big number ends exactly at that N (commas, e.g. "🍪 12,450"); the sub-line shows how many cookies you grabbed ("1 cookie grabbed" for one). | |
| PT2 | Collect nothing during the party. | "🍪 0" (no count-up) and "Next time grab some cookies!", then "+5,000 PARTY BONUS!". Shorter, no ring burst. | |
| PT3 | Watch the number. | Counts up fast from 0 (~1 s, slowing at the end), with ticks rising in pitch if a TotalTick id is set; lands with a punchy scale bump, a white shine sweeping across the gold number, a gold ring bursting out and a little confetti. | |
| PT4 | Watch under the number. | "+5,000 PARTY BONUS!" (green) slams in just after the number lands; the amount matches `Config.CookiePartyFinalReward`, and the cash counter goes up by it. | |
| PT5 | Time it from the finale. | The card flies down toward the cookie counter, shrinking and fading; it is completely gone within ~4 s. Nothing left on screen; no errors in Output. | |
| PT6 | As a player who fed (trophy banner) and as one who didn't (resting pill). | The trophy banner / pill at the top is visible the whole time and the card never overlaps it; the card never covers the cash display at the bottom center. | |
| PT7 | Player 2 joins during TrophyClaim. | Player 2 sees no total card at all. | |
| PT8 | Phone layout: Studio device emulator (e.g. iPhone landscape) and a small PC window. | The card fits between the trophy banner and the cash display, text readable, nothing overlaps (at worst a couple of pixels on the smallest screens). | |
| PT9 | 2 players with different totals (Test > Clients and Servers); run 2 cycles. | Each sees only their own total. The second party's card shows the second party's numbers (earned resets at the next party start); no leftovers between parties. | |
## Caleb leaderboard (podium)

Needs the Core agent's `CalebCycle` publishing `CalebTopFeeders`. Tip: `DevCalebFastCycle = true` + `DevUnlimitedCash = true` in Studio for the end-of-cycle cases (set back before committing).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| LB1 | Press Play; walk all the way around the statue, and look from each spawn. | Four boards at the pedestal's corners, each facing out diagonally, with gold trim, chocolate posts, and a chip cookie on top. From any side at least one board is readable from ~40 studs. They don't block any of the 4 feed pads (all 4 still open the pop-up). Text is not darkened by lighting/night. | |
| LB2 | Before anyone feeds. | Title "CALEB'S TOP FEEDERS", subtitle "Cookies fed this round", "Be the first to feed Caleb!", total "🍪 0 / 350,000" (solo). | |
| LB3 | Feed 10 cookies. | Within ~1 s your row appears: badge 1 (gold), your name, "10 🍪"; your row is green with a thick green outline; total "🍪 10 / 350,000" (solo). | |
| LB4 | 2–3 players feed different amounts (e.g. Test > 3 Clients). | Rows are best first with commas (e.g. "248,321 🍪"); badges 1/2/3 are gold/silver/bronze, 4+ brown. Each client sees only its OWN row highlighted. | |
| LB5 | Late joiner: feed, then a second player joins. | The new player's boards show the current list and total right away. | |
| LB6 | Player with a long display name (or temporarily make the server send a 40-character name / one containing `<b>` tags). | The name ends in "…" inside its row; it never overlaps the cookie count or leaves the board; tags show as plain text. | |
| LB7 | Feed until Caleb is full (fast cycle) and wait for TrophyClaim. Also check Caleb at max size. | At max size Caleb never touches a board. During TrophyClaim the subtitle says "FINAL RESULTS" (red) and the list stays. | |
| LB8 | Wait for the reset to Normal. | List cleared ("Be the first to feed Caleb!"), total "🍪 0 / …", subtitle back to "Cookies fed this round". | |
| LB9 | Walk far away (to a plot) and back; reset character. | Boards still show the list (re-attach after streaming); no duplicate boards; no errors in Output. | |

## Caleb sounds

Needs the WAVs uploaded and their ids in `Config.CalebSounds` (see
`tools/audio/README.md`), except CS1. Use `Config.DevCalebFastCycle = true`
(Studio only) to get through the event quickly.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CS0 | Run `python3 tools/audio/generate_sfx.py`. | Six WAVs in `tools/audio/out/` (16-bit, 44.1 kHz, mono), all under 300 KB. Re-running gives identical files. | |
| CS1 | All `CalebSounds` ids empty; Play; run a full fast cycle. | Silent. Output has at most one `[CalebAudio] no sound id ...` line and no errors or warnings. | |
| CS2 | Feed Caleb a few times quickly. | A quiet rising "bloop" per feed, never more than about 3 per second; the other game sounds are unchanged. | |
| CS3 | Feed until the goal. | The "boing/burp/fanfare" plays once when he is Full. | |
| CS4 | Wait for the Celebration. | The air horn (`Config.CookiePartyStartSound`) once, then a quiet sparkle loop with no audible click at the loop point. | |
| CS5 | Wait for the Celebration to end (TrophyClaim starts). | The loop fades out and stops; the descending chime plays once. Nothing keeps playing. In Explorer, `SoundService.CalebAudio.CookieRain.IsPlaying` is false. | |
| CS6 | Claim your trophy (2 players: only Player 1 claims). | Player 1 hears the "ta-da"; Player 2 does not. | |
| CS7 | 2 players: Player 2 joins mid-Celebration. | Player 2 hears only the loops (no Full, no air horn); it stops at the end like CS5. | |
| CS8 | Player 2 joins during TrophyClaim, or after already claiming (rejoin). | No sounds play on join. | |
| CS9 | Reset character during the Celebration; let the cycle run twice. | Still exactly one `SoundService.CalebAudio` folder; sounds play again in the next cycle; no duplicates. | |


## Music

Paste real ids into the MUSIC block at the top of `Config.luau` first
(`BackgroundMusic`, `CookiePartyStartSound`, `CookiePartyMusic`), except for MU8.
`DevCalebFastCycle = true` makes the party come quickly (set it back after).

| ID | Steps | Expected | Pass |
| -- | ----- | -------- | ---- |
| MU1 | Play (not during a party). | "Tender Static" fades in over ~1.5 s and loops with no gap problems. Explorer: one `SoundService.CalebAudio.BackgroundMusic`, `Looped` true. | |
| MU2 | Feed Caleb until "CALEB IS FULLLL!!!" appears. | The background cuts out almost at once (~0.3 s, then `IsPlaying` false, paused); the Full sound effect still plays. | |
| MU2a | Stay through the Full state. | No music at all until the party (suspense). | |
| MU2b | The Cookie Party starts. | The Air Horn plays at once, then ~1 s of silence (no music), then "NO PARTY" starts at normal volume (no slow fade-in) and loops. Never two music tracks together; one Air Horn only. | |
| MU2c | `DevCalebFastCycle` (do not commit it) or a very short party: make the party end within ~1 s of the horn. | "NO PARTY" never starts; the background fades back in as usual. | |
| MU2d | 2 players: Player 2 joins while Caleb is Full. | Player 2 hears no music until the party; then horn, gap, "NO PARTY" like Player 1. | |
| MU3 | Listen through the party. | Only "NO PARTY" (+ effects): normal speed and pitch the whole time, a little louder toward the end. | |
| MU4 | Party ends (finale). | "NO PARTY" stops at once, the finale boom plays, the background fades back in **continuing where it paused** (not from the start). | |
| MU5 | Let two full cycles run. | Same as MU2–MU4 each time; still exactly one of each music Sound in `SoundService.CalebAudio`. | |
| MU6 | 2 players: Player 2 joins mid-party. | Player 2 hears "NO PARTY" right away (no Air Horn, no 1 s gap, no background); when the party ends the background fades in for them too. | |
| MU7 | Reset your character during the party and during normal play. | Music keeps going correctly (no restart, no duplicate). | |
| MU8 | All three music ids empty; Play; run a full cycle. | Silent music, no errors. Output in Studio: one `[CalebAudio] no sound id in Config for: ...` line listing `BackgroundMusic`, `CookiePartyStartSound`, `CookiePartyMusic` (plus any other empty ids). | |

## Purchase

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| U0 | Claim the plot. | Only "Dropper 1 / FREE!" is showing. | |
| U1 | Step on "Dropper 1 / FREE!" with 100 cookies. | Cookies stay **100**. Button 1 and yellow spot 1 disappear; an upside-down red cup appears at spot 1; the conveyor starts and drops fall every 2 s. The "Dropper 2 / 🍪 300" button and yellow spot 2 appear. Buttons 3 and 4 are still hidden. | |
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
| BF3 | Before buying the walls, in **Server** view make `BuildButton2` visible and touchable (`Transparency = 0`, `CanTouch = true`) and step on it with ≥ 5000 cookies. | Nothing is built; no cookies spent (Stairs needs Walls first). | |
| BF4 | Buy the walls. | Cookies −5000. Off-white brick walls with gray trim and dark windows appear around the plot with a gray-framed doorway in the middle of the front; the Build Walls button disappears; "Build Stairs / 🍪 5000" and, further back, "Trophy Case / 🍪 7500" appear. You can walk in and out through the doorway only. The owner sign, conveyor, droppers, collect pad, and cookie jar still work inside. | |
| BF5 | Buy the stairs. | Cookies −5000. 16 cream steps appear along the right wall; "2nd Floor / 🍪 10000" appears. Walk up them: each step is climbable without jumping. The top reaches the top of the walls, and nothing is there yet (no floor). | |
| BF6 | Buy the 2nd floor. | Cookies −10000. A floor appears on top of the walls with a railing around the stair hole, plus the brick second story and the gray roof (see HS1). Walk up the stairs onto it. On the **left** side, directly above the first conveyor, is a second conveyor (not moving yet) and a green collector at its back end. "Dropper 5 / 🍪 20000" and its yellow spot appear next to it. Nothing on floor 1 is blocked or hidden by the new floor. | |
| BF7 | Buy Dropper 5. | A dropper appears at spot 5; cookies fall onto the 2nd-floor conveyor, which moves front → back (same as floor 1) into Collector2. Each arrival adds a small cookie to the cookie jar **downstairs**. Dropper 6's button appears. The floor-1 conveyor keeps running. | |
| BF8 | Go down and step on the Collect pad. | You get the cookies from both floors (e.g. with only Droppers 1 and 5 running: +10 per floor-1 cookie and +300 per floor-2 cookie). | |
| BF9 | Buy Droppers 6, 7, 8. | Each costs its price; each appears above Conveyor2; after Dropper 8 no buy buttons remain (except "Trophy Case" and any furniture you haven't bought). | |
| BF10 | Try to fall: walk along every edge of the 2nd floor and around the stair hole. | The second-story walls and the hole railings stop you everywhere except at the top of the stairs. | |
| HS1 | With everything built, walk out the front doorway and look back at the house (also from each side and the back). | It looks like a two-story off-white brick house: gray corner posts, a gray band along the top of the first floor, dark windows with gray frames, grilles, and sills on every side (an arched one above the doorway and a wide one on the upper front), a gray shingle **hip roof** that slopes down on all four sides with a ridge on top and darker caps on the ridge and the four hips, eaves overhanging every wall with a light soffit and gray fascia underneath, a pointed brick front gable with gray trim and a round vent, and a brick chimney with a gray cap at the back. No roof face is missing, upside down, or has a gap. No parts flicker or poke through each other. | |
| HS2 | Walk inside both floors and around the stairs. | Windows also show (frame + dark glass) on the inside walls, except beside the stairs. You never snag on window frames, sills, or trim; the stairs still climb without jumping. Neither floor is too dark to play (note it if it is). | |
| HS3 | Before the walls are bought, and after leaving (plot reset). | None of the house shows: no walls, trim, windows, second story, or roof. | |
| CP1 | Buy Dropper 1; look at it closely, from the side and from below. | It's an upside-down red party cup (narrower at the top, darker ridges, rolled lip) with a white inside at the bottom opening. Cookies come out of the opening every 2 s and land on the belt. | |
| CP2 | Buy all 8 droppers (unlimited money). Watch both conveyors for a few minutes. | Gray guard rails line both sides of each conveyor and collector, with a stop at each conveyor's front end and behind each collector. No cookie falls off a conveyor; every cookie reaches its collector and adds a small cookie to the jar. Rails don't block the buy buttons or the stairs. | |
| CP3 | Leave (plot reset), or look before claiming / before buying the 2nd floor. | No cups remain; the rails show and hide together with their conveyor (floor-1 rails after claiming, floor-2 rails only after the 2nd floor is built). | |
| FN1 | Build the 2nd floor; go upstairs. | Five orange buttons appear at the same time as "Dropper 5": "Bed / 🍪 12000", "Gaming Desk / 🍪 25000", "Shelves + TV / 🍪 18000", "Mini Fridge / 🍪 8000", "Ninja Kitchen / 🍪 10000". No furniture shows yet. | |
| FN2 | Buy the furniture and Droppers 5–8 in a mixed order (e.g. Bed, Dropper 5, Kitchen, Dropper 6, ...). | Every purchase works in any order; buying furniture never hides or blocks a dropper button and vice versa. Each costs its price once; its button disappears and the item appears. | |
| FN3 | Look at each item up close and from across the room. | Cartoony versions of the photos: Shelves + TV (books, Barad-dûr with the glowing Eye, drill, TV, PS5, lamp, games, bins); Ninja Kitchen (granite counter, tile backsplash, skillet, ice cream maker, blender); Gaming Desk (one straight desk on the back wall, no side piece; 3 monitors incl. one standing up, webcam, keyboard, mouse, controller, headphones, cup, chair, backpack); Bed (black headboard, gray sheets, pillows, blanket); Mini Fridge (black fridge, orange LEGO rocket on its tower, foam roller). Nothing floats, pokes through walls/windows/the roof, or overlaps another item. | |
| FN4 | Walk around everything upstairs, up and down the stairs, and along Conveyor2. | Furniture never blocks the stairs, the stair hole railing, the dropper buttons, or Conveyor2. You can jump on the bed. Small items (books, keyboard, etc.) don't trip you. | |
| FN5 | Buy some furniture, leave, and rejoin (saving on, see SV cases). | The bought furniture comes back after claiming; the rest still has its buttons. | |
| FN6 | Check Plots 2–4 (2 players or Server view). | Each plot has the same furniture layout, turned with its house. | |
| BF11 | Leave (or 2-player L1) after building the 2nd floor. | Walls, stairs, 2nd floor, Trophy Case (and its trophies), all furniture, both conveyors' droppers, and all buttons disappear; both conveyors stop; the plot looks like T1 again. The next owner starts from Dropper 1 with nothing built. | |

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

## Dev: all trophies

Set `Config.DevAllTrophies = true` (Studio only; `DevUnlimitedCash = true`
helps to buy the Trophy Case). Set both back to false before committing.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| DT1 | `DevAllTrophies = true`, Play (API access on or off). | Output shows one "[DevAllTrophies] gave N trophies (session only, not saved)" line (N = 5 × collectable variants). 🏆 TROPHIES shows every variant 5 times; COLLECTION is full (M / M); no Mystery Caleb. Nothing is auto-equipped (ACTIVE 0 / 5, or only your saved equipped ones). | |
| DT2 | Buy the Trophy Case, equip 5 copies of one trophy (e.g. SpeedCaleb). | All 5 show in the case; the power stacks (5×, no cap), "Active powers" in the panel matches. A 6th equip says the slots are full. | |
| DT3 | With a saved trophy already equipped (API access on), equip dev trophies into the free slots, then unequip / re-equip the saved one. | Saved and dev trophies mix freely up to 5; no errors; the saved one's state saves as usual. | |
| DT4 | With dev trophies equipped, Stop. Set `DevAllTrophies = false`, Play (API access on). | No dev trophies; only your real saved trophies and their saved equipped list (no missing/unknown ids, no warnings). | |
| DT5 | `DevAllTrophies = false`, Play. | No "[DevAllTrophies]" line; inventory is normal. | |
| DT6 | Claim a Caleb trophy with dev trophies on (`DevCalebFastCycle = true`). | Claim works as usual (one per cycle); it is saved (API on) and auto-equips only if a slot is free. | |
| DT7 | Code review: `DevTrophies` is gated by `RunService:IsStudio()`, and `DevAllTrophies` is `false` in the committed `Config.luau`. | Both true (a published game ignores it). | |

## Visuals

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| V1 | Look at the Claim pad; then claim and look at the Buy button and Collect pad. | Each is a flat circle lying on the ground with a darker ring around its edge; labels float readably above the pads. | |
| CT1 | Look behind the Collect pad. | Purple wall with a gold frame, cartoony "COOKIE JAR" sign (see V6) readable from the pad side, glass tank on an orange stand. The wall doesn't block walking onto the pad. | |
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
| V6 | Claim the plot; stand on the Collect pad and look up at the "COOKIE JAR" sign, then from ~30 studs away, in daylight and at night (Lighting `ClockTime = 0`). Repeat on Plots 2–4. | The sign matches the other cartoony signs: a pink rounded panel with a thick dark outline inside a thin gold frame, white chunky "COOKIE JAR" text with a dark outline, centered with space around it (not touching the edges, not squashed or stretched). It faces the Collect pad (front); the back of the jar wall shows no text. Not darkened at night. The glass lid doesn't cover it. | |

## Cookie jar counter

The "🍪 N" plaque on top of the cookie jar (`CashTank.JarCounter`). It shows
the plot's stored (uncollected) cookies; the owner's Collect Bonus is added
only when they collect.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| JC1 | Claim the plot; stand on the Collect pad and look at the jar. Then from ~40 studs away, at night (`ClockTime = 0`), and in the Device emulator on a phone (e.g. iPhone SE landscape). Repeat on Plots 2–4. | A pink-framed gold plaque sitting directly on top of the "COOKIE JAR" sign reads "🍪 0" in white chunky text with a dark outline (emoji renders). It faces the pad, the whole number is visible from the pad (the sign doesn't hide its lower half), no flicker where it meets the sign, doesn't overlap the sign or the glass, isn't cut by the 2nd floor (build it to check), isn't darkened at night, and is readable on the phone from the pad. Gone past ~120 studs. | |
| JC2 | Buy Dropper 1 and watch drops reach the collector. | Each drop adds its value (e.g. 🍪 0 → 🍪 10 → 🍪 20 with Dropper 1's DropValue of 10, no trophies); the plaque pops a little each time. Matches the cookies you then get from collecting (without Collect Bonus). | |
| JC3 | Let it pass 1,000 (or use droppers with bigger values). | Commas: "🍪 1,250", "🍪 12,345". Text stays inside the panel. | |
| JC4 | Step on the Collect pad. | Counter goes back to "🍪 0" at the same time as the tank empties and the burst plays; your cookies go up by the shown number (plus Collect Bonus if equipped). | |
| JC5 | Trophy powers: equip a CookieMultiplier trophy, then a CollectBonus trophy (Trophy Case built). | With CookieMultiplier each drop adds its boosted value to the counter. With CollectBonus the counter still shows the stored number; the payout is floor(shown × (1 + bonus)). | |
| JC6 | Build the 2nd floor and buy a 2nd-floor dropper as well as floor-1 droppers. | Drops reaching `Collector` and `Collector2` both add to the same counter; one collect pays and resets it. | |
| JC7 | 2 players: Player 2 watches Player 1's jar fill and get collected; Player 2 steps on Player 1's Collect pad. | Player 2 sees the same number and pop; stepping on Player 1's pad changes nothing. | |
| JC8 | Unclaimed / released: look at an unclaimed plot; then claim, let cookies build up, and leave (watch from Player 2). | Unclaimed plot: no plaque and no text anywhere. After leaving: the plaque hides with the jar; the next claim shows "🍪 0" (not the old number). | |
| JC9 | Rejoin: with cookies in the jar, leave and rejoin (claim again). | Counter starts at "🍪 0" (stored cookies are not saved, as before) and counts up normally. No errors in Output. | |

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
| M5 | Four players (Test > Clients and Servers, 4 players). Each claims a different plot. | Each player owns exactly one plot; each sign shows its owner's name. A player who already owns a plot can't claim a second one. | |
| M6 | With 4 players, each buys Dropper 1 and collects. | Each plot's cup drops cookies onto its own conveyor, into its own collector and cookie jar; collecting pays only that plot's owner. Cookies on the turned plots (2–4) ride toward their own back-left collector and land inside their jar (not stuck in the glass). | |
| M7 | Join several times. | You appear at one of the four spawn areas (it varies). | |
| M8 | Player on Plot3 leaves. | Only Plot3 resets to its Claim pad; the other three keep running. | |

## Spawns

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| SP1 | Test > Clients and Servers with 4 players (rejoin a few times if needed so all four spawns get used). | Every player appears standing on the grass between a plot and the statue, in front of that plot's doorway: at Plot1 (0, 0), Plot2 (−44, 44), Plot3 (0, 88), Plot4 (44, 44). Nobody falls through the ground, sinks into it, or gets stuck. | |
| SP2 | Fly around each of the four spawn spots in Studio (Play and Run mode). | Nothing blue and no disc, ring, decal, or outline is visible at any spawn; it's just grass. In Explorer, `Map` has `SpawnLocation`–`SpawnLocation4` and none has a `SpawnLocationRing` child. | |

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

## Saving (DataService)

Needs a published place with **Game Settings → Security → Enable Studio
Access to API Services** ON, except SV2. Watch Output (Server view).
Cookies are saved too: see "Cookie saving" below.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| SV1 | API access ON. Claim, buy Dropper 1–4, Walls, Stairs (Dev cash on). Stop. Play again, claim any plot. | Within a moment the plot shows exactly what you had: walls + stairs built, 4 cups dropping on the conveyor, and the **2nd Floor** button showing (not Dropper 1–4, Walls, Stairs). Cookies are back at the dev amount (dev cash is never saved); nothing was charged for the restore. No warnings. | |
| SV2 | API access OFF. Press Play, claim, buy Dropper 1. | Exactly **one** warning: "DataService: saving is OFF … Enable Studio Access to API Services to test saving …". No errors; the game plays normally. Stop/Play again: plot starts fresh. | |
| SV3 | After SV1, buy SecondFloor and Dropper 5, then Stop right away (within 2 s). | Next Play + claim shows the 2nd floor and Dropper 5 (BindToClose saved them). Stop does not hang longer than ~25 s. | |
| SV4 | Test > Clients and Servers, 2 players, API ON. Player 1 restores (SV1) on Plot2, leaves, rejoins, claims **Plot4**. | Plot2 resets to its Claim pad on leave; after rejoin Plot4 shows Player 1's full house. Player 2's plot is unaffected; Player 2's house is their own. | |
| SV5 | Load failure never overwrites. After SV1, temporarily make the first line of `DataSchema.FromStored` `return nil, "test"`. Play, claim, buy Dropper 1, Stop. Undo the edit, Play again, claim. | Failing session: one warning "could not load … They play UNSAVED …", plot starts fresh, gameplay works. Next normal session: the SV1 house comes back (the failing session wrote nothing). |  |
| SV6 | Claim the plot and step on the Dropper 1 button immediately while data is still loading (e.g. with a slow first load). | You are never charged for something you already own; once loaded the house appears and buttons work normally. | |
| SV7 | Unknown saved id. After SV1, temporarily remove the `Stairs` entry from `Config.Builds` (and its `After` users) in a local copy, Play, claim. Undo afterwards. | `Stairs` is ignored (and anything that needed it is skipped); everything else restores; no errors. | |
| SV8 | Autosave. Buy something, wait > `DataAutosaveSeconds` (120 s), then Stop. | No DataStore errors in Output; the purchase is restored next time. | |
| SV9 | Respawn (Esc → Reset) after a restore. | House unchanged; nothing restored twice; cookies unchanged. | |

## Cookie saving

Needs a published place with **Game Settings → Security → Enable Studio
Access to API Services** ON (except CS5), and `DevUnlimitedCash = false`
(except CS6). Watch Output (Server view). Rule: until the save loads,
spending is blocked and earned cookies are counted; then cookies = saved +
earned while loading.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CS1 | Earn: claim, buy Dropper 1, collect until you have e.g. 250 cookies. Wait 2 s, Stop. Play again. | Right after the load the player list **Cookies** and the bottom cookie panel both show **250** (the panel pops once when it changes from 100). | |
| CS2 | Spend: after CS1, buy something (or feed Caleb) so cookies drop, Stop, Play again. | Cookies show the lower amount: what you spent stays spent; nothing was refunded. | |
| CS3 | Load window: with a slow load (e.g. temporarily add `task.wait(5)` at the start of `load` in `DataService`), join, claim, and collect cookies from the jar during those 5 s; also try to feed Caleb. Undo the edit. | Feeding says "Your cookies are still loading..." and spends nothing. Once loaded, cookies = saved amount + what you collected during the wait (not lost, not doubled). | |
| CS4 | Old save: with a Version 2 record (saved before this change, or write `Version = 2` without `Cash` in a test key), Play. | Cookies show **100** (`StartingCash`); house and trophies still load. After the next save the record has `Version = 3` and `Cash`. | |
| CS5 | DataStore off: API access OFF, Play, earn some cookies, Stop, Play again. | Starts at 100 each time; one "saving is OFF" warning; nothing saved; gameplay normal. | |
| CS6 | Dev cash: after CS1 (real save has e.g. 250), set `DevUnlimitedCash = true`, Play, spend some, Stop. Set it back to `false`, Play. | Dev session: one "[DEV] ... cookies are NOT loaded or saved" line, 1,000,000,000 cookies. Next normal session: cookies show the CS1 amount again (dev cash never reached the save). | |
| CS7 | Bad saved values: temporarily make `DataSchema.CleanCash` see NaN / -5 / "abc" / 1e20 / 12.7 (e.g. write them as `Cash` in a test key). | NaN, "abc" → 100; -5 → 0; 1e20 → 1e15; 12.7 → 12. No errors. | |
| CS8 | Two servers (session lock): with a published place, join server A, earn cookies, then quickly join server B (server hop) while A is still saving. | B waits for A's leave save (or takes the lock after ~30 s) and shows A's latest cookies; A never writes over B afterwards ("another server took over" if it tries). | |
| CS9 | Server shutdown: earn cookies, then Stop within 2 s (no autosave yet). | Next Play shows the new amount (BindToClose saved it). | |
| CS10 | Autosave: earn cookies, wait > `DataAutosaveSeconds` (120 s), check there are no DataStore errors, Stop. | Next Play shows the amount; no warnings. Collecting many drops does not cause a DataStore write per drop. | |

## Caleb Trophies

Set `DevCalebFastCycle = true` and `DevUnlimitedCash = true` in Studio (set
both back to false before committing): goal 1,000; Full 3 s, Celebration
20 s, TrophyClaim 30 s. Saving needs **Enable Studio Access to API
Services** ON (published place) except TR8. Watch Output (Server view).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| TR1 | Feed Caleb to the goal (1 player). Wait for TrophyClaim. | Caleb is hidden; a big golden Caleb trophy ("CALEB TROPHY / Claim yours!") stands on top of the pedestal where he stood, facing Plot1. Walking up to the pedestal shows the "Claim Caleb Trophy" prompt (hold ~0.5 s). | |
| TR2 | Claim it (TR1). | The "🏆 NEW TROPHY!" pop-up with <Name> and ⭐ <RARITY> (see TP1). The prompt disappears for you; `CalebTrophyClaimed = true`; the event UI shows "Trophy claimed! 🏆". No errors. | |
| TR3 | 2 players (Clients and Servers): only Player 1 fed. During TrophyClaim, Player 2 walks to the pedestal. | Player 2 sees no prompt. (Optional exploit check: in Player 2's client set the prompt's `Enabled = true` and trigger it → notification "Only players who fed Caleb this round…"; no trophy; `CalebTrophyClaimed` stays false.) | |
| TR4 | Double claim: hold the prompt again right after claiming / trigger it twice quickly (Player 1, or set `Enabled = true` on the client after claiming). | Only one trophy: the saved list (and the case) gains exactly one; a repeat says "You already have this round's trophy." | |
| TR5 | Player A feeds, leaves during Celebration, rejoins the same server during TrophyClaim. | A sees the prompt (their `CalebFed` is restored) and can claim (one trophy). | |
| TR6 | Player B joins after the goal (during Full/Celebration/TrophyClaim). | B never sees the prompt; claiming is refused. | |
| TR7 | Let TrophyClaim end without claiming. | The podium trophy and prompt disappear at the reset; Caleb is back. Nothing can be claimed afterwards (a held prompt finishing exactly at the end is refused: no trophy). | |
| TR8 | API access **OFF** (unsaved). Feed, claim. Build the Trophy Case. | The "NEW TROPHY!" pop-up shows <Name> and says it couldn't be saved this session. The trophy stands in your Trophy Case this session. Stop/Play: it's gone (it was never saved). One "saving is OFF" warning only. | |
| TR9 | Trophy Case: claim a plot with Walls built, buy "Trophy Case / 🍪 7500" (button behind the Build 3 spot on the right side). | Cookies −7500. A big dark-wood cabinet (about 25 wide, nearly up to the ceiling) with gold trim, a red velvet back, one row of 5 risers on a velvet stage behind glass, 5 nameplates on its base, and a red "MY CALEB TROPHIES" sign on top appears against the middle of the back wall (covering the middle back window from inside); it doesn't block the conveyor, collector, cookie jar/Collect pad, stairs, `BuildButton4` area, or doorway, and you can walk all around in front of it. Trophies stand on the risers (slot 1 in the middle, then left, right, far left, far right), facing into the room, inside the glass, none poking through the top. Without trophies: empty risers (no visible slot pads) and every nameplate says a dim "EMPTY" (see TC1–TC9). Before buying and after leaving: no case and no light glow on the back wall. | |
| TR10 | Restore after rejoin (API ON): with the case built and 1+ saved trophies, Stop, Play, claim any plot. | The house comes back with the Trophy Case and the same trophies in it (no charge). Same on Plot2–4 (case against that house's back wall, facing in). | |
| TR11 | New trophy updates the case: with the case built, claim a trophy. | The new trophy appears in the middle slot right away; older ones move outward. | |
| TR12 | Second cycle: after claiming, let the cycle reset, feed to the goal again, claim again. | New `CalebCycleId`; you get another trophy with a **different** variant from the ones you own (until you own all 12). Both are saved. | |
| TR13 | 6 trophies (repeat TR12, or temporarily set the fast goal low). | The first 5 were equipped automatically and stand in the case; the 6th is owned (in `TrophyInventory` `Owned`) but **not** equipped or shown until you unequip one (TI3). | |
| TR14 | Variant look check: run several cycles (or in the command bar: `require(game.ServerScriptService.Services.TrophyModel).Build("GoldenCaleb", 3).Parent = workspace`, for each Id in `TrophyVariants.List` and an unknown Id like `"Nope"`). | Each looks like a mini cartoony Caleb (big round head, hair cap, big eyes, grin, belly) in its color, pose, accessories (crown, party hat, chef hat, sunglasses, cookie in hand, bow tie), and effect (sparkles/glow). The unknown Id shows a gray "Mystery Caleb". Nothing collides or can be clicked. | |
| TR15 | Server shutdown right after claiming (API ON): claim, then Stop within 2 s. | Next session the trophy is there (saved right after the claim, and in BindToClose). | |
| TR16 | Trophy Case nameplates: case built, 1+ trophies shown. Walk up close, then back to the Collect pad, then 60+ studs away. | Each trophy's name is on the gold-framed plaque on the case's base right below it (no floating plaques inside the case any more), in its rarity color (Common white, Rare blue, ...) and, if the trophy has a power, the power line (e.g. "2x COOKIE PRODUCTION") in smaller white text; readable at night (not dimmed). Text disappears beyond ~60 studs. Details: TC2–TC4. | |
| TR17 | Trophy Case lighting: case built, with and without trophies; day and night (`Lighting.ClockTime`). | With trophies shown: a soft warm light inside the case, no glare, no bright Neon. Before the case is bought, and after the plot is released: no light on the back wall. | |
| TR18 | Slot order: with equipping (Inventory), equip 1, then 2, ... 5 trophies; unequip one. | Slot 1 (middle, highest riser) = first equipped, then left, right, far left, far right; unequipping rebuilds the row in the new order. (Before the Inventory change: TrophyService passes oldest first, so slot 1 = oldest.) Plot2–4: same, case against each house's back wall facing in. | |

## Trophy powers

Needs the Trophy Case built and trophies equipped (Inventory UI). For quick
checks, in the Server command bar:
`require(game.ServerScriptService.Services.PowerService).SetDisplayed(game.Players.<Name>, { "<VariantId>", ... })`
(TrophyService resets it on the next equip change). Read `TrophyStats` /
`CanDoubleJump` on the player in the Properties window.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PW1 | No trophies displayed. | `TrophyStats` = `[]` or `{}`, `CanDoubleJump` = false; drops worth exactly `DropValue`, one drop per `DropInterval`, payout = stored; normal WalkSpeed (16) / JumpHeight (7.2). | |
| PW2 | CookieMultiplier: display a +1.0 cookie trophy. | Collected cookies per drop double (Dropper1: 20 instead of 10) from the next drop. | |
| PW3 | DropperSpeed: display a DropperSpeed trophy. | Drops come out faster (+1.0 → one per 1 s instead of 2 s) from the next drop. | |
| PW4 | ExtraCookieChance: display one (or set a high value temporarily in a test definition). | Sometimes two cookies fall at once (one just below the other); both are counted. Never three. | |
| PW5 | LuckyCookieChance: display one. | Sometimes a **gold** cookie; it adds 5× the normal value. | |
| PW6 | CollectBonus: display +0.5, collect 100 stored. | Cookies +150 (rounded down for odd amounts). | |
| PW7 | WalkSpeed / JumpHeight: display them. | Visibly faster / higher right away; Humanoid `UseJumpPower` = false. Unequip → back to normal right away. | |
| PW8 | DoubleJump: display Rocket Caleb. | `CanDoubleJump` = true; press jump, then again in the air → a second jump; only one per air time; landing resets. Holding jump does not fire both at once. Unequip → no air jump. | |
| PW9 | No caps: display several trophies of one stat. | `TrophyStats` shows the full sum (no cap). Two copies of the same definition both count. See "Trophy stacking" (ST1–ST7). | |
| PW10 | Respawn (reset character) with speed/jump trophies. | Same boosted WalkSpeed / JumpHeight after respawn; not compounded (reset twice → same values). | |
| PW11 | 2 players (Clients and Servers): only Player 1 has trophies. | Player 2's drops, payouts, speed, jump and `TrophyStats` are unaffected; Player 1's bonuses apply only on Player 1's plot. | |
| PW12 | Unequip every trophy (or release the plot / leave). | All bonuses gone from the next drop; `TrophyStats` empty; movement normal. | |

## Speed trophies + glowing feet

Same setup as Trophy powers (built Trophy Case, or the `PowerService.SetDisplayed`
command bar shortcut). Base WalkSpeed is 16. Read the Humanoid's `WalkSpeed`
in the Properties window (Server view). No cap; the glow is full at `TrophySpeedGlowFullAt` = 1.5.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| SG1 | Display each speed trophy alone, then put it in the inventory without a built case. | Party 21.6, Speed 28, Cool 24, Midnight 22.4, Rainbow 20.8, King 24 (all = 16 × (1 + bonus)). Equipped but case not built → 16, no glow. | |
| SG2 | Inventory details and Trophy Case nameplates for those six. | "+35% WALK SPEED", "+75% WALK SPEED", "+50% WALK SPEED", "+40% JUMP, +40% SPEED", "+10% COOKIES/JUMP/DROPPERS, +30% SPEED", "+50% COOKIES, +50% WALK SPEED"; the Rainbow text fits its plate. | |
| SG3 | Stacking: display Speed + Cool (+1.25). | WalkSpeed 36; `TrophyStats` WalkSpeed = 1.25. | |
| SG4 | No cap: display Speed + Cool + King + Midnight (+2.15). | WalkSpeed 50.4 (3.15×), `TrophyStats` WalkSpeed = 2.15. | |
| SG5 | Any speed trophy displayed. Look at your feet (day and night). | Each foot has a soft light-blue glow and leaves a few sparkles when running; subtle, not blinding. One `SpeedGlow` Attachment per foot in Explorer. | |
| SG6 | Compare Party (+35%) with the big stack (SG4). | Big stack is brighter / more sparkles (full glow); both look tasteful. | |
| SG7 | Unequip the trophy; then re-equip and release the plot; then re-equip and display a JumpHeight-only trophy (Jump Caleb). | Glow disappears right away each time (no `SpeedGlow` left). Jump Caleb alone: no feet glow. | |
| SG8 | 2 players (Clients and Servers): Player 1 has a speed trophy. | Player 2 sees Player 1's glowing feet; Player 2's own feet do not glow. A 3rd player joining later also sees it. | |
| SG9 | Respawn (Esc → Reset) with a speed trophy, twice. | Same WalkSpeed after each respawn (not compounded) and the glow is back, still exactly one `SpeedGlow` per foot. | |
| SG10 | R6: set Game Settings → Avatar → R6, play with a speed trophy. (R15 is covered by SG5.) | Glow on `Left Leg` / `Right Leg` bottoms; same WalkSpeed numbers. | |

## Trophy stacking

No stat caps and duplicates stack (requested by the user 2026-10-02). Needs
several copies of a trophy: in Studio, the command bar shortcut
`require(game.ServerScriptService.Services.PowerService).SetDisplayed(game.Players:GetPlayers()[1], {"SpeedCaleb", "SpeedCaleb"})`
sets displayed ids directly; for the real equip path, give yourself
duplicate saved trophies (different InstanceIds) and equip them in the
inventory. Base WalkSpeed 16. Read `TrophyStats` on the Player and the
Humanoid's `WalkSpeed` (Server view).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| ST1 | Display two different speed trophies: Speed + Cool. | `TrophyStats` WalkSpeed = 1.25, WalkSpeed 36. | |
| ST2 | Display two copies of the same trophy: 2 × Speed Caleb (equip both in the inventory). | Both equip (ACTIVE TROPHIES 2 / 5), both show in the case; `TrophyStats` WalkSpeed = 1.5, WalkSpeed 40. Two Golden Calebs → CookieMultiplier 2, Dropper1 drops worth 30. | |
| ST3 | Display 5 × Speed Caleb. | `TrophyStats` WalkSpeed = 3.75, WalkSpeed 76 (4.75×). Inventory "Active powers" says +375% speed. A 6th can't be equipped (slots full). | |
| ST4 | A chance stat never goes over 100%: command bar `SetDisplayed(player, {"CloneCaleb","CloneCaleb","CloneCaleb","CloneCaleb","CloneCaleb","CloneCaleb","CloneCaleb"})` (7 × 15% = 105%). | `TrophyStats` ExtraCookieChance = 1 (not 1.05); every drop has exactly one extra (never more); UI says 100%. With 5 real Clone Calebs: 0.75. | |
| ST5 | Display 2 × Rocket Caleb. | `CanDoubleJump` = true, exactly one air jump; JumpHeight +40% (7.2 → 10.08). | |
| ST6 | From ST3, unequip trophies one by one. | WalkSpeed drops by 12 each time (76 → 64 → 52 → 40 → 28 → 16); `TrophyStats` follows; no glow at 0. | |
| ST7 | At 5 × Speed Caleb (+375%), look at the feet glow and run around. | Glow looks the same as at +150% (full glow, not blinding, not bigger); one `SpeedGlow` per foot. | |
| ST8 | 5 × Golden + check droppers; 5 × Neon. | Golden: Dropper1 drops worth 60 (6×), dropper fire no bigger than at +100%. Neon: one drop every 0.8 s per dropper; no errors in Output. | |

## Power visuals on the plot

Built Trophy Case and a few droppers bought. Use the inventory UI (or the
PowerService command-bar line above) to change what is displayed.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PV1 | Equip a CookieMultiplier trophy (e.g. +5%, then Golden +100%). | Every dropper cup has fire on top and a warm light; small flames at +5%, big flames at +100% (no bigger past that). No sparks. Unequip → fire and light gone right away. | |
| PV2 | Equip a DropperSpeed trophy only. | Same fire on every cup. Equip a CookieMultiplier one as well → orange sparks also fly off the cups. Unequip one → sparks stop, fire stays. | |
| PV3 | Equip a CollectBonus trophy (e.g. Big Brain). | A golden glowing ring around the Collect pad with rising gold sparkles and a light; brighter at a bigger bonus. Stepping on the pad still collects. Unequip → ring gone. Pad's own "cash waiting" sparkles still work as before. | |
| PV4 | Equip an ExtraCookieChance or LuckyCookieChance trophy. | A few green/gold sparkles float off each cup (no fire unless a production power is also active). | |
| PV5 | Equip WalkSpeed / JumpHeight / Double Jump trophies only. | Nothing new on the cups or the pad (those powers show on the player, not the house). | |
| PV6 | With fire showing, buy another dropper. | The new cup burns too, the same size as the others. | |
| PV7 | Equip a production trophy with the Trophy Case **not** built (fresh plot). | No fire anywhere. Build the case → fire appears. | |
| PV8 | With fire + ring showing, leave the game (or release the plot). | Cups, fire and ring all gone; the free plot looks normal. Another player who claims it sees no fire unless they have their own powers. | |
| PV9 | 2 players (Clients and Servers): Player 1 has fire + ring. | Player 2 sees Player 1's burning cups and gold ring; Player 2's own plot has none. | |
| PV10 | Rejoin (saved data) with a production + collect trophy equipped. | Once the house is restored, the cups burn and the pad ring is back. | |

## Power-up looks

Speed trail + glowing feet, jump and double-jump effects (requested by the
user 2026-10-02). Built Trophy Case. Quickest setup: in Studio set
`Config.DevAllTrophies = true` (5 copies of every trophy; **commit it as
false**) and equip from the inventory, or use the PowerService command-bar
line in "Trophy stacking". Base WalkSpeed 16; the trail shows above 19
studs/s (`TrophySpeedTrailMinSpeed`). Check day and night, and keep an eye on
Output for errors.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PL1 | Display one speed trophy (e.g. Speed Caleb +75%). Stand still, then walk with a light thumbstick touch (phone emulator) or tap a key, then run. | Feet glow light blue with bright sparkles and crackling sparks at all times. **No trail while standing still or moving slowly**; while running, a glowing cyan → blue ribbon streams behind your waist/legs and fades out; stop → it fades away within half a second. A few speed lines whoosh out behind you when you start running (not every frame). | |
| PL2 | Your own view while running in third person, zoomed in close, and in first person; run in circles and up/down stairs. | The trail never covers the screen or reaches the camera; nothing flickers on/off while running at a steady speed. | |
| PL3 | Stacked speed: compare Party Caleb (+35%) with 2 × Speed (+150%) and 5 × Speed (+375%). | Bigger bonus → longer, more solid trail, brighter feet, more sparks. +150% and +375% look the same (full look); nothing is blinding. | |
| PL4 | Display a JumpHeight trophy (Jump Caleb +50%), jump several times on flat ground and on a slope; then 5 × Jump Caleb. | Each takeoff: a mint-green double ring springs out flat on the ground (not floating, not hidden under it) with a sparkle burst; soft green sparkles trail your feet while in the air and stop when you land. 5 × Jump: bigger rings, more sparkles. Jumping without a jump trophy: nothing. | |
| PL5 | Display Rocket Caleb; jump, then press jump again in the air (also walk off a ledge and jump in the air). | Takeoff: the jump ring (Rocket has +20% jump). The air jump: an orange ring of light + a puff appears right under you in mid-air, exactly once per air jump. Holding jump does not fire it twice. A normal jump never shows the orange ring. | |
| PL6 | 2 players (Test → Clients and Servers): Player 1 has speed + jump + Rocket. Watch from Player 2; then start a 3rd player late. | Player 2 (and the late 3rd player) see Player 1's glowing feet, the trail only while Player 1 runs, the jump rings/bursts and the orange air-jump burst. Player 2's own body shows nothing. | |
| PL7 | Unequip each power one by one (and release the plot / unbuilt case). | Each look disappears right away: no `SpeedGlow`, `SpeedTrailTop`/`SpeedTrailBottom`, `JumpFX` left in the character (Explorer, Server and Client views); jumps stop making rings. With only speed left: no `JumpFX`; with only Rocket: `JumpFX` has only `AirBurst`. | |
| PL8 | Respawn (Esc → Reset) twice with every look on. | All looks come back; still exactly one `SpeedGlow` per foot, one `SpeedTrailTop` + `SpeedTrailBottom` + `SpeedTrail`, one `JumpFX` on the `HumanoidRootPart`. | |
| PL9 | No duplicates: equip/unequip a speed trophy 10 times fast, and swap between speed trophies. | Still exactly one trail (no doubled ribbon), one `SpeedGlow` per foot; no errors. On the client, `Workspace.PowerLooksFX` never has more than 8 `PowerRing` parts however much you jump. | |
| PL10 | No powers: a player without trophies runs and jumps; check the MicroProfiler / Script Performance. | No looks, no rings; `PowerLooks` uses ~0 while nobody has a speed trail; no `PowerLooksFX` folder until someone with a jump power jumps. | |
| PL11 | R6 (Game Settings → Avatar → R6) with speed + jump trophies. | Feet glow on the leg bottoms, trail behind the torso, jump ring at the feet (on the ground). | |

## Trophy inventory UI

Needs the Inventory + Powers server work merged (the `TrophyInventory` and
`TrophyStats` attributes and the `TrophyEquip` handler). To get trophies
quickly use `DevCalebFastCycle = true` (see Caleb Trophies), or in the Server
command bar set a test attribute, e.g.
`game.Players.Player1:SetAttribute("TrophyInventory", '{"Owned":[{"InstanceId":"a","Variant":"GoldenCaleb","EventId":"1","EarnedAt":1}],"Equipped":[],"CaseBuilt":false,"Max":5,"Saved":true}')`
(the server overwrites it on its next publish). Check on PC and with the
Device emulator (a phone in landscape).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| TI1 | Join with no trophies. Look at the screen; click "🏆 TROPHIES". | A yellow "🏆 TROPHIES" button at the left middle, not over the cookie counter, chat, or the phone thumbstick. The panel opens with a small pop: "MY CALEB TROPHIES", "🏆 COLLECTION 0 / M" (M = collectable trophies), "ACTIVE TROPHIES: 0 / 5", "No trophies yet! Feed Caleb to earn one 🏆", "Tap a trophy to see its power!", "Active powers: none". | |
| TI2 | Click the button again; open again and click the red X. | Each closes the panel; the button reopens it. Respawning (Esc → Reset) keeps the button (no duplicate GUI). | |
| TI3 | Claim a trophy (TR2) with the panel open. | A tile appears right away (no reopening needed): icon in the trophy's colors (hat for crown/party/chef, ✨ for effects), rarity in its color, name, border in the rarity color. Collection goes to 1 / M. | |
| TI4 | Tap the tile. | It turns yellow and pops. Details: icon, name, "⭐ RARITY" in the rarity color, the power in big text, the description in quotes, green EQUIP. | |
| TI5 | EQUIP it. | The button shows "..." briefly, then "Equipped!" and red UNEQUIP; the tile gets a green "EQUIPPED" badge and moves to the front; "ACTIVE TROPHIES: 1 / 5". With the case built, the trophy appears in the Trophy Case and "Active powers" lists its power. | |
| TI6 | UNEQUIP it. | "Unequipped.", EQUIP again, badge gone, active count back down, trophy leaves the case, its power leaves the list. | |
| TI7 | Equip 5 trophies, select a 6th. | Grey "Case full (5/5)"; clicking it does nothing (no request). Unequip one → the 6th can be equipped. | |
| TI8 | Spam-click EQUIP / UNEQUIP very fast. | Only one request at a time (button "..."); no errors; the final state matches the server (badge, count, case). If the server refuses (rate limit), its reason shows in red under the description. | |
| TI9 | Trophy Case not built (or plot released). | Orange note "Build your Trophy Case at home to activate trophy powers!"; EQUIP still works; "Active powers: none". Build the case → the note disappears and powers appear without reopening the panel. | |
| TI10 | API access OFF (unsaved, TR8). | "Saving is off this session" at the bottom right; everything else works. | |
| TI11 | Many trophies: in the Server command bar publish a test `TrophyInventory` with 120 records (any variants). | The grid scrolls smoothly; every tile shows; no lag spike when it updates again; equipped first, then rarest, then newest. | |
| TI12 | Bad data: set `TrophyInventory` to `"oops"`, then to `'{"Owned":[{"InstanceId":5}],"Equipped":["zzz"]}'`, and a record with Variant `"Nope"`. | No errors. Bad JSON / bad records = empty or skipped; unknown Equipped ids ignored; "Nope" shows as a grey "Mystery Caleb". | |
| TI13 | Selected trophy disappears (publish a `TrophyInventory` without it). | Details go back to "Tap a trophy to see its power!"; no errors. | |
| TI14 | Phone (Device emulator, e.g. iPhone landscape) and a big PC window. Open the panel while the feed pop-up is open, and during the Caleb event banners. | Panel fits the screen and stays readable (text scales, clamps); tiles are 3+ per row. The feed pop-up and event banners draw over the panel, not under it. | |

## Trophy claim pop-up

Claim trophies quickly with `DevCalebFastCycle = true` (don't commit it).
Check on PC and with the Device emulator (a phone in landscape).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| TP1 | Saved: API access ON, Trophy Case built, fewer than 5 equipped. Feed, claim. | A big yellow pop-up pops in at the center with confetti and a spinning shine in the rarity color: "🏆 NEW TROPHY!" banner (rarity color), the trophy icon, its name, "⭐ RARITY" in the rarity color, its power in big text (e.g. "+75% WALK SPEED"), the description in quotes. It was auto-equipped, so it shows green "EQUIPPED ✓" (no EQUIP button) and "Its power is on!". No small notification. | |
| TP2 | Unsaved: API access OFF. Feed, claim. | Same pop-up, plus "This trophy couldn't be saved this session (you keep it until you leave)." | |
| TP3 | Case not built (plot without the Trophy Case). Claim. | Orange "Build your Trophy Case to use powers". Still shows EQUIPPED ✓ if a slot was free (it is equipped; powers start once the case is built). | |
| TP4 | Case full: 5 trophies equipped, case built. Claim. | Green EQUIP button and "Equip it in your Trophy Case to get this power". Tap EQUIP → "..." briefly, then the server's reason in red ("All 5 active slots are full. Unequip a trophy first."); nothing changes; the pop-up stays open. | |
| TP5 | Equip works: from TP4, unequip one trophy in 🏆 TROPHIES (or claim with a slot freed some other way), then tap EQUIP in the pop-up. If the pop-up already closed, claim again next round with 5 equipped, unequip one, then EQUIP. | "EQUIPPED ✓", then the pop-up closes about a second later. The trophy appears in the Trophy Case, the inventory panel shows its EQUIPPED badge and "ACTIVE TROPHIES" goes up, its power is listed. | |
| TP6 | Close: tap CLOSE. Claim again another round and just wait. | CLOSE closes it at once. Untouched, it closes by itself after `TrophyPopupSeconds` (20 s). | |
| TP7 | Spam EQUIP (case full so it fails). | One request at a time (button "..."), at most every `TrophyEquipCooldown`; no errors; any "Slow down a little!" shows in red. | |
| TP8 | Phone (Device emulator, landscape) and a big PC window. | The pop-up fits the screen and is readable; EQUIP and CLOSE are big enough to tap (about 45 px tall or more). It draws over the trophy inventory and the event banners, under the feed pop-up. | |
| TP9 | Already owned / not eligible: trigger the prompt again after claiming (or as a player who didn't feed, TR3). | Only the small notification ("already have this round's trophy" / "Only players who fed Caleb…"); no big pop-up. | |
| TP10 | Respawn (Esc → Reset) with the pop-up open, then claim next round. | No duplicate GUI; the pop-up still works after respawn. | |

### Trophy definitions (rarities, powers, looks)

| # | Steps | Expected | Pass? |
| - | ----- | -------- | ----- |
| TD1 | Command bar: `local T = require(game.ReplicatedStorage.Shared.TrophyVariants) print(T.CollectableCount()) for _, v in T.List do print(v.Id, v.Rarity, v.PowerText) end` | 21; every trophy prints a rarity and a power line. No warnings in Output. `T.Get("Nope").DisplayName` = "Mystery Caleb", and its `Powers` is empty. | |
| TD2 | Build each new look (see TR14) at scale 3: CookieCaleb, SpeedCaleb, JumpCaleb, FireCaleb, CloneCaleb, BigBrainCaleb, RocketCaleb, RainbowCaleb, KingCaleb. | Cookie: giant cookie behind him, arms up. Speed: blue, running pose, yellow bolt on the belly, white speed lines behind. Jump: green, standing on two coil springs (raised off the plinth). Fire: orange-red, cartoon flame hair with a few small rising flame particles. Clone: two mini Calebs (same color) on the front plinth corners. Big Brain: big pink brain on his head, hand on his cheek. Rocket: two rockets on his back with small exhaust flames. Rainbow: a 5-color rainbow arching over him from behind with a cloud at each end. King: purple, crown, red cape with white fur collar, sparkles, soft pink glow. Nothing floats apart or pokes through the front of the face; nothing collides or can be clicked; no big glaring Neon. | |
| TD3 | Rarity band: build one trophy of each rarity (e.g. BronzeCaleb, SpeedCaleb, FireCaleb, RocketCaleb, GoldenCaleb, KingCaleb). | The band around the top of the plinth is gray / green / blue / purple / gold / pink, and the nameplate name is in the same rarity color. Only King Caleb (Mythic) glows. | |
| TD4 | Roll check: command bar `local T = require(game.ReplicatedStorage.Shared.TrophyVariants) local c = {} for i = 1, 100000 do local r = T.Get(T.RollReward({})).Rarity c[r] = (c[r] or 0) + 1 end for k, n in c do print(k, n / 1000) end` | About 60 / 20 / 10 / 6 / 3 / 1 % (Common .. Mythic), each within about half a percent. | |
| TD5 | Prefer unowned: `local T = require(game.ReplicatedStorage.Shared.TrophyVariants) for i = 1, 20 do print(T.RollReward({"PartyCaleb", "CookieCaleb"})) end` | Every Common result is BronzeCaleb (the only Common not owned). | |

## Trophy inventory + equipping

Same setup as Caleb Trophies (fast cycle, API access ON unless noted). Read
the server-written player attribute `TrophyInventory` (JSON: `Owned`,
`Equipped`, `CaseBuilt`, `Max`, `Saved`) in the Properties window of your
Player (Client or Server view). Until the Inventory UI exists, equip from the
**client** command bar (Test > Clients and Servers, Player 1 window):
`print(game.ReplicatedStorage.Remotes.TrophyEquip:InvokeServer("Equip", "<InstanceId>"))`
(copy an InstanceId from `Owned`).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| TE1 | Join (no trophies yet). | `TrophyInventory` appears right away with `Owned = []`, `Equipped = []`, `Max = 5`, `CaseBuilt = false`; `Saved` becomes true once your data loads (false with API access off). | |
| TE2 | Claim a trophy with fewer than 5 equipped. | It is in `Owned` and auto-equipped (last in `Equipped`). With the case built it appears in the case at once; without the case it is not shown and gives no power (`TrophyStats` empty). | |
| TE3 | Unequip then equip: `InvokeServer("Unequip", id)`, wait 1 s, `InvokeServer("Equip", id)`. | Each prints `true`. The trophy leaves / returns to the case; `Equipped` updates; repeating an action that is already done also returns `true` and changes nothing. | |
| TE4 | Limit: with 5 equipped, equip a 6th owned trophy. | `false  All 5 active slots are full. Unequip a trophy first.` Nothing changes. | |
| TE5 | Unowned / fake id: `InvokeServer("Equip", "not-a-real-id")`, `InvokeServer("Equip", <Player 2's InstanceId>)`, `InvokeServer("Equip", 123)`, `InvokeServer("Equip", string.rep("a", 500))`, `InvokeServer("Dance", id)`. | Every one returns `false` with a friendly reason ("isn't in your collection" / "Unknown action."); no change to either player; no server errors. | |
| TE6 | Spam: `for i = 1, 20 do print(game.ReplicatedStorage.Remotes.TrophyEquip:InvokeServer("Unequip", id)) end` | Most calls return `false  Slow down a little!` (cooldown `TrophyEquipCooldown` = 0.25 s); no errors, no lag. | |
| TE7 | Rejoin restores equipped: equip a specific set (e.g. unequip slot 1), Stop, Play, claim a plot. | `Equipped` is the same list in the same order; with the case built the same trophies are in the case, same slots. | |
| TE8 | Migration of an old save: in a published test place with a Version 1 save (made before this change, or written via the command bar: `game:GetService("DataStoreService"):GetDataStore("SimpleTycoon_v1"):SetAsync("Player_<UserId>", {Version = 1, Purchases = {}, Trophies = {{Variant = "GoldenCaleb", EventId = "a", EarnedAt = 1}, ...6 more}})` while not in the game), join. | No warnings. Every trophy is kept with a new `InstanceId`; `Equipped` = the newest 5, newest first. Rejoin: the same InstanceIds (written at load). | |
| TE9 | Case not built: own trophies, plot claimed but no Trophy Case. Then buy it. | Before: `CaseBuilt = false`, nothing displayed, no powers. After buying: `CaseBuilt = true`, equipped trophies appear, powers on. | |
| TE10 | Release: leave with the case built (2 players: watch from Player 2). | The case and its trophies are removed with the plot; no errors. Player 1's powers stop (they're gone). | |
| TE11 | Unsaved (API access OFF): claim, then unequip/equip it. | The pop-up says it couldn't be saved this session; `Saved = false`; the trophy is auto-equipped and can be unequipped/equipped this session. Leave + rejoin the same server: still owned and equipped. New server: gone. | |
| TE12 | Exploit: from the client, set your own `TrophyInventory` attribute or call `InvokeServer` with another player's id. | Client-side attribute changes affect only your own view; the server's state, the case, and powers don't change. | |

## Trophy Case (5 slots)

The redesigned case: one row of 5 trophies on a velvet podium stage, each
trophy's name on a plaque in the case's base below it. Quick setup: set
`Config.DevAllTrophies = true` and `DevUnlimitedCash = true` in Studio to
own every trophy and buy the case at once (set both back to **false**
before committing). Equip/unequip with the Inventory UI.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| TC1 | Fill in order: case built, nothing equipped. Equip 5 trophies one at a time, then unequip the 2nd one. | Each new one appears in the next slot: 1 middle (highest riser), 2 left, 3 right, 4 far left, 5 far right (as seen from the room). After unequipping, the row rebuilds in the new order with no gap and the last slot goes back to "EMPTY". Exactly 5 risers and 5 plaques; no 6th slot or extra shelf anywhere. | |
| TC2 | Names on the bottom panel: 5 trophies of different rarities equipped (e.g. BronzeCaleb, SpeedCaleb, FireCaleb, RocketCaleb, KingCaleb). | Each plaque sits right below its own trophy and shows that trophy's name in its rarity color (gray/white, green, blue, purple, gold, pink as in TD3) with a dark outline, and its power (e.g. "+50% COOKIES, +50% WALK SPEED") in smaller white text under it. Long power texts wrap or shrink but stay inside the plaque. A trophy with no power shows just its (bigger) name. | |
| TC3 | Empty slots: equip 0, then 2 trophies. | With 0: all 5 plaques show a dim, faded "EMPTY" (not bright, not missing) and the risers are bare. With 2: plaques 1–2 show names, plaques 3–5 still say "EMPTY". | |
| TC4 | Readable on phone: Device emulator (e.g. iPhone SE landscape), stand on the Collect pad, then walk up to the case; also at night (`Lighting.ClockTime = 0`). | Names readable from the Collect pad on the phone; power text readable from a few studs away. Text is not darkened at night. All text disappears beyond ~60 studs. | |
| TC5 | Only when bought: claim a plot without the case, look at the back wall; then buy "Trophy Case / 🍪 7500"; then leave (watch from Player 2). | Before buying: no case, no plaques, no "EMPTY" text, no light glow. After buying: the whole case with plaques appears. After leaving: it all hides again, and the next owner's case starts with "EMPTY" plaques (no old names). | |
| TC6 | Lights: case built, with trophies; then unequip all; then release the plot. | Light is on while the case is shown (also with 0 trophies: it shows "EMPTY" plaques), off before buying and after release. Soft and warm, no Neon glare. | |
| TC7 | Bigger trophies fit: equip the tallest/widest looks (KingCaleb, RocketCaleb, CookieCaleb, JumpCaleb, CloneCaleb) in all 5 slots. | Trophies are bigger than before (`TrophyCaseScale = 1.6`) but none pokes through the top board/gold valance, the glass, the velvet back, or a neighbor; each stands flush on its riser (not floating). | |
| TC8 | All 4 plots: claim Plot2, Plot3, Plot4 in turn (2 players for two at once). | Each house has the identical case against its own back wall, trophies and plaques facing into the room, names readable the right way round. | |
| TC9 | Nothing overlaps: case built, walk around it; build the 2nd floor and the bed above. | The case stays inside its old footprint (x −12.4..12.4, z −74.7..−69.55, y 2..16.6 in Plot1): the plaques stick out only ~0.2 from the base; it does not touch the conveyor, collector, cookie jar/Collect pad, stairs, `BuildButton4`, the doorway, or the 2nd floor (the sign top stays below y 17). Output has no "missing TrophySlotN/NameplateN" warnings. | |

## Garage + Backyard

Needs the garage and backyard map parts (other workers' PRs). Quick setup in
Studio: `Config.DevUnlimitedCash = true` to max the house fast; trophies
from real claims, or `Config.DevAllTrophies = true` for "many" (set both back
to **false** before committing). For 0 / 1 / 4 / 5 trophies, use a test save
or claim trophies one at a time (`DevCalebFastCycle = true`). Count = owned
trophies (inventory), equipped or not.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| GB1 | Walls reveal: claim a fresh plot, buy Dropper 1–4, watch the back of the house; then buy Build Walls. | Before Walls: no back door, no fence, no trophy buttons (fence hidden and not solid: you can walk where it will be). The moment Walls is bought, the walls, the closed back door, the white picket fence, and the three backyard buttons (Pool, Path, Fire Pit Hangout) all appear together. The door is locked (closed, solid). The Garage button does **not** appear. No Pool/Path/Hangout model shows yet. | |
| GB2 | Labels. | "Garage" over gold "Must have 1 Caleb Trophy"; "Pool", "Path", "Fire Pit Hangout" each over gold "Must have 5 Caleb Trophies". No cookie price, no "🏆 N" that looks like a price. Text fits the sign. | |
| GB3 | 0 trophies, house maxed: step on the Garage button. | "Can't afford" sound (only you hear it, at most every 1.5 s); nothing built; cookies unchanged. | |
| GB4 | 1 trophy (not equipped): step on Garage. | Garage + white VW ID.4 appear, build sound plays, button disappears. Cookies **unchanged**; you still own the trophy. | |
| GB5 | 1–4 trophies, Walls built: jump the fence (jump trophies, or `Humanoid.JumpPower` in Server view) into the backyard and step on the Pool / Path / Hangout buttons. | Getting into the yard this way is allowed: nobody pushes you out. Nothing is built: "can't afford" sound, cookies and trophies unchanged. | |
| GB6 | 5 trophies: buy Pool, Hangout, Path in that (any) order. | Each is free, plays the build sound, its button disappears, its build appears. The fire pit's flames, embers and light show only once Hangout is bought (none while hidden). Trophies still owned. | |
| GB7 | Door + sign, locked: Walls built, owner owns 0, 3, then 5 trophies (claim one while watching). | Back door closed and solid; sign (inside the house) reads "🔒 Unlock this door once you have 5 Caleb Trophies" with a smaller gold "🏆 0/5" under it, then "🏆 3/5". The text fits the sign and is readable from the middle of the room (not tiny, not cut off). At 5 the door swings open into the backyard and the sign says "BACKYARD OPEN!" with no progress line, without rejoining. | |
| GB8 | Unclaimed plot: look at the back of the house. In Server view, check `BackDoor.DoorSign` on a released plot. | No walls, no door, no fence, no buttons on an unclaimed plot (you can walk straight into the yard area). The sign's `TextLabel` reads "🔒 Unlock this door once you have 5 Caleb Trophies" and `ProgressLabel` is empty/hidden. | |
| GB9 | No push-out: owner with < 5 trophies. Before buying Walls, walk around the outside of the house into the backyard area (no fence yet); after Walls, jump over the fence with jump trophies; stand there for 10 s each time. | You stay in the yard: nothing teleports you. The back door stays closed and solid (you can't walk through it from either side). | |
| GB10 | Open backyard: owner with ≥ 5 trophies. Walk through the back door; Player 2 (visitor) does the same. | Both can walk in freely through the open door and stay; nobody is pushed out. | |
| GB11 | Locks again: owner (≥ 5) and Player 2 are in the backyard; owner leaves. | The plot resets: walls, door, fence and buttons hide; Player 2 is not moved. When a new owner with < 5 claims and builds the walls, the door is closed again. | |
| GB12 | Save/restore: buy Walls, then (with 5 trophies) Pool; also on another save buy everything + Garage. Leave and rejoin (saving on), claim a plot. | Walls come back with the back door, the fence, and the Path/Hangout buttons (Pool built, no button). Garage comes back only on the maxed save. No sounds. | |
| GB13 | Locked pads: in Server view make `TrophyButton1` (Garage) visible/touchable on a plot whose house is not maxed, and `TrophyButton2` on a plot without Walls; step on them with trophies. | Nothing is built (the server checks the Walls for the backyard and the maxed house for the garage). | |
| GB14 | Turned plots: repeat GB1, GB7 and GB9 on Plots 2, 3 and 4. | Buttons, door, fence and sign work the same on every plot. | |
| GB15 | 2 players: Player 2 (visitor, 5+ trophies of their own) tries the back door of Player 1's house while Player 1 owns < 5, then jumps the fence into the yard. Player 2 also steps on Player 1's trophy buttons. | The door stays closed for Player 2 (it's the owner's count that matters). Being in the yard is fine (not pushed out). Player 1's buttons do nothing for Player 2. | |
| GB16 | Missing map parts (on a branch without the garage/backyard maps). | The game runs normally; Output has one "TycoonService: … has no …" and one "BackyardGate: … has no BackDoor" warning per plot, no errors. | |
| GB17 | Garage still waits: Walls built, house not maxed, owner has 1+ trophies. | The three backyard buttons are there; the Garage button is not. Buy the last house item: only then the Garage button appears. | |
| GB18 | Fence rejoin: buy Walls, leave, rejoin, claim a plot. | The fence and the back door come back with the walls (solid fence, closed door). A save without Walls shows no fence. | |
| GB19 | Backyard before max: Walls built, house not maxed, owner owns 5 trophies. Walk through the open door, step on Pool. | The door is open; the Pool is built for free (trophies still owned) even though the house is not maxed. | |

## Tycoon sounds

Upload the five WAVs from `tools/audio/out/` and paste the ids into
`Config.TycoonSounds` first (see `tools/audio/README.md`); TS8 is the empty-id
case. Use Test > Clients and Servers with 2 players where it says so. For a
quick setup, `Config.DevUnlimitedCash = true` in Studio (set it back to
**false** before committing), except for TS3.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| TS1 | Buy a dropper (claim a plot, step on "Dropper 1"). 2 players: Player 2 stands next to the plot, then far away (~100 studs). | A "ka-ching!" plays once at the button. Player 2 hears it nearby, not from far away. No sound when the purchase fails for another reason (e.g. Player 2 steps on Player 1's button). | |
| TS2 | Buy a build (Walls, Stairs, 2nd Floor, a furniture piece, Trophy Case). | The bigger build sound (hammer + whoosh + chime) plays at that button, once per purchase. With `PurchaseBuild = ""` the dropper "ka-ching!" plays instead. | |
| TS3 | Can't afford: with too few cookies, stand on a button for ~5 s, step off and on, then walk onto a second unaffordable button. 2 players: Player 2 stands next to Player 1. | A soft "nope" plays at most once every 1.5 s while standing there (about 3–4 times in 5 s, not a spam), a new button can boop right away, and only Player 1 hears it (Player 2 hears nothing). Cookies are unchanged. | |
| TS4 | Collect payout: let a few cookies collect, step on the Collect pad; then let a lot collect (e.g. 10,000+) and collect again. 2 players: Player 2 nearby. | Coin cascade + chime plays once per payout, a little higher-pitched for the big payout. Player 2 hears it nearby. No sound when the jar is empty or when Player 2 steps on Player 1's pad. | |
| TS5 | Jar plink rate limit: buy all 8 droppers (dev cash) and stand near the jar for 20 s. | Quiet plinks as cookies reach the collector, never more than ~6 per second; no "noise soup", no warnings in Output. | |
| TS6 | No sounds on house restore: own several droppers and builds, leave, rejoin (published test place with API access on, or the same server), claim a plot. | The saved house rebuilds silently: no purchase / build sounds for the restored parts. Buying the next item afterwards plays its sound normally. | |
| TS7 | Release: leave with a claimed plot, then a new player claims it and buys. | No errors; the new owner's sounds play at the right buttons. | |
| TS8 | Empty ids: set every `Config.TycoonSounds` id to `""`, Play, buy, step on an unaffordable button, collect. | Everything works silently; no errors; in Studio Output one "[TycoonSounds] no sound id in Config for: …" line (once, not per plot). | |

## Backyard look

Geometry only (`tools/backyard/generate_backyard.py`). Showing/hiding the
pool, path and hangout, the pads, the door lock, the sign's trophy count and
the fire's on/off are the game logic's job (see its own QA cases). To see
everything at once before that logic exists, look in Studio **Edit** mode
(not Play). Check each case on **all 4 plots**.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| BY1 | Fly above the map (Edit mode). | Every house has a fenced backyard behind it (on the side away from the statue). No backyard or fence touches another plot, another plot's garage area (right side of each house), a spawn, or the statue. All of it is on grass; the 400 × 400 ground reaches past every fence. (In Play the fence shows only with the Walls: GB1.) | |
| BY2 | Walls built: walk along the fence inside the yard; try to walk through it; look at the corners. Before the Walls: walk where the fence will be. | White picket fence about 8 studs tall (pickets with pointed tips, posts with caps and balls, rails on the outside) on the left, right and back. It meets the house's back corners with no gap; you can't walk through or squeeze between pickets. Before the Walls it is invisible and you walk right through it. | |
| BY3 | Build the walls, then stand inside the house and look at the back wall's right side; also at night (`Lighting.ClockTime = 0`). | A wooden back door (window with panes, two panels, gold knob) fills a framed opening where the right back window used to be. Above it a gold-framed purple sign reads "🔒 Unlock this door once you have 5 Caleb Trophies" in chunky white text (two lines, fits the sign), readable from inside, not darkened at night. The door doesn't touch the Trophy Case, the stairs, the collector, or `BuildButton4`; no window frame pokes through it. | |
| BY4 | Look at the back door from the yard. Walk from the step onto the grass. | Gray casing around the door, a small gray awning above it, a stone step below; the door has the same window/panels/knob on this side. Stepping from the house floor to the step to the grass is smooth (no getting stuck). | |
| BY5 | Pool: walk around it. | Long raised pool on the left running front to back: stone walls with a sand-colored rim on top, light blue floor and lining with a dark blue lane line, see-through blue water up to just under the rim, steps up to the rim in the front corner nearest the back door, a red brick wall with a stone cap and three piers along its outer side (taller than the rim), a diving board at the far end, two beach balls floating on the water. (Getting in and out: WP1–WP6.) | |
| BY6 | Path: walk from the back step to the patio. | Gray flagstones from the step all the way to the patio, with round gray rocks and brown dirt patches along both sides. Rocks and dirt don't block you. | |
| BY7 | Hangout, in daylight and at night, with the fire turned on (by the game logic, or set `Fire`/`Embers`/`FireLight` `Enabled` in Edit mode). | Square stone patio with a tile grid at the end of the path. Fire pit in the middle: ring of stones, crossed logs, flames, glowing embers rising, warm orange light on the patio at night. Five colorful chairs face the fire with their backs leaning away from it; the path side is open. Nothing floats or sinks into the patio. With the fire off: no flames, embers or glow. | |
| BY8 | Pads, with nothing in the yard built: walk out of the back door to each pad. | Three gold pads with dark purple rings and purple signs on the grass: right of the pool, left of where the path starts, at the patio's front-left corner. Each is reachable on foot from the back door, and none overlaps the pool rim, a rock, dirt, the path, or the patio. | |
| BY9 | Look in the Explorer for `BackyardZone` on every plot. | It is gone (removed: no push-out any more). Nothing in Output mentions it. | |
| BY10 | Run `python3 tools/backyard/generate_backyard.py` twice, then `python3 tools/plots/generate_plots.py`, then `git status`. | The second run changes nothing; the plot files have no other changes. `rojo build` still succeeds. | |

## Walk-in pool

The pool is a raised basin (`tools/backyard/generate_backyard.py`). Build it
first (5 Caleb Trophies; `Config.DevAllTrophies = true` helps, set it back to
**false** before committing), or check the shape in Studio **Edit** mode.
Use **Play** for movement. Check each case on **all 4 plots**.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| WP1 | Walk out of the back door to the pool's front corner nearest the house and walk up the outside steps (no jumping). | Three sand-colored steps take you from the grass onto the rim smoothly; no getting stuck on a step. The Pool pad is a little further back along the pool and doesn't touch the steps. | |
| WP2 | From the rim, hop into the water anywhere. | You drop through the water onto the pool floor and stand there about waist deep, head and shoulders above the surface. No swimming animation, no falling through the floor, no bouncing on the water. | |
| WP3 | Run around inside the pool, all the way to the far end and along every wall. | You run on the floor like on the ground, through the water (it never blocks you). The walls stop you at every side. Under the diving board you bump into it (it is solid); everywhere else is open. Beach balls don't block you. | |
| WP4 | Walk out by the inside steps (front corner, near the house), no jumping. | Three white steps take you from the floor up onto the rim, then the outside steps down to the grass, in one straight line. | |
| WP5 | Walk around the whole pool on the rim, then onto the diving board, and jump off into the water. | The rim is wide enough to walk on all the way round. From the far end's rim you step up onto the board, walk to its end, and land in the water. | |
| WP6 | Before the pool is built (its trophy button still showing): walk where the pool and its steps would be. | Nothing there: no invisible walls, steps or floor block you (the whole Pool model is hidden and non-solid). After building it, WP1–WP5 work. | |

## Garage + car (look)

Look checks for the garage model (`tools/garage/generate_garage.py`); the
unlock itself is tested in GB1–GB16. Setup: max the house with
`Config.DevUnlimitedCash = true` and buy the garage with a Caleb Trophy
(`Config.DevAllTrophies = true` helps; set both back to **false** before
committing).

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| GG1 | Plot1: stand at the spawn and look at the house's right (stairs) side. | An attached one-car garage next to the house, front flush with the house front: off-white brick, gray corner posts/bands, gray shingle gable roof with a round vent, lanterns by the door. It matches the house and touches it with no gap or poking through (roof meets the house wall below the 2nd-floor windows). | |
| GG2 | Walk up the driveway ramp into the garage. | The door is rolled up (roll box above the opening inside, white door edge just under the frame). The ramp is walkable from the grass, the floor is solid concrete level with the plot floor, the walls and roof block you, nothing floats. | |
| GG3 | Look at the car from the front, sides and back. | A white VW ID.4: rounded white body, black roof and pillars, dark windows, black arches/sills/bumpers, slim headlights joined by a white light bar, a VW roundel on the nose and tailgate (V over W, reads right way round from behind), red light bar at the back, 4 side doors + tailgate, silver/black wheels. Parked nose out, wheels on the floor. | |
| GG4 | Walk around the car inside the garage; jump on it. | You can walk around it (bench and rack behind it, charger cable on the floor on its right); the body is solid, small details (mirrors, lights, logos) do not snag you. | |
| GG5 | Inside details. | Workbench with pegboard tools, red toolbox and vise at the back right; metal rack with bins, boxes and paint cans at the back left; white wall charger on the house wall with a green light, cable running to the car's right rear. The house's first-floor window at z −22 is visible on the left wall. | |
| GG6 | Lights: before buying, at night (`Lighting.ClockTime = 0`); then buy the garage. | No glow from the hidden garage before buying (the `GarageLight`s are saved disabled). After buying (or on restore), `PlotStages` turns them on: warm light inside the garage. After the owner leaves, they go off with the garage. | |
| GG7 | The pad: max the house (logic in). | A gold pad with a dark purple ring and a purple sign on the grass in front of the driveway, same style as the other trophy pads. It does not overlap the ramp. | |
| GG8 | All 4 plots: walk to Plot2, Plot3 and Plot4 (or claim each). | Each house has the same garage on its own right side, door facing the statue side. No garage touches a neighbor plot, a spawn, the statue, or another plot's garage/pad. | |

## Drivable car

Setup: max the house (`Config.DevUnlimitedCash = true`) and build the
Garage with a Caleb Trophy (`Config.DevAllTrophies = true` helps; set both
back to **false** before committing). Physics numbers are `Config.Car*`;
note any you change. Use **Test → Clients and Servers** (2 players) for
CAR5–CAR5c (passenger), CAR6–CAR8 and CAR13.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| CAR1 | Build the Garage; look in the Server view under `Workspace.Cars`. | A `Plot1Car` appears parked exactly where the white ID.4 was (nose out, wheels on the floor, no jump or jitter); the anchored `GarageCar` is hidden (only one car visible). Windows are a little see-through. No errors in Output. | |
| CAR2 | Walk to the driver's side (the car's left); press E on "Drive". | You sit in the driver's seat, visible through the window. Default vehicle controls work. | |
| CAR3 | Drive: W/S gas and reverse, A/D steer. Drive out of the garage, down the ramp, around the map, up and down the 1-stud plot edges. | W drives forward (nose first), S backs up, D turns right, A left (if any is reversed, report it: a sign in `CarSeats.drive`). Top speed about 60 studs/s; no wheelies, no flipping in normal turns, tires don't sink into the body. Releasing W slows the car to a stop. | |
| CAR4 | Physics ownership: while driving, in the Server view select the car's `Body` (Studio: show network owner, or check that driving feels lag-free). Get out. | While you drive, your client owns the car (smooth, no input lag). Empty, the server owns it. | |
| CAR5 | Jump to get out (Space) on flat ground: once from the driver seat, once from the passenger seat (2 players, or switch seats). Try it parked in the garage and out on the grass. | Driver stands on the ground beside the driver's door (car's left), passenger beside the passenger door (right), a step clear of the mirrors, facing the way the car points. Never under the car, inside it, or sunk into the ground/garage floor; you can walk normally right away (not frozen or stuck). | |
| CAR5b | Jump out on uneven ground: park with the exit side on the driveway ramp, on a 1-stud plot edge, and beside the pool rim (exit side over the rim / water). Do it as driver and as passenger. | You end up standing on top of whatever is beside the door (ramp, plot edge, pool rim, or the pool floor in the water), feet on the surface, not in it and not under the car. No falling through the map. | |
| CAR5c | Jump out right after driving fast (brake hard, then Space at once). | Same as CAR5: beside your door, standing. At most a quick second snap if the first placement got overruled (it's re-checked after `CarExitSettleTime`). | |
| CAR6 | 2 players: Player 2 walks to Player 1's car and presses E on "Drive". | Nothing happens for Player 2 (prompt shows "<owner>'s car" but they don't get in). | |
| CAR7 | 2 players: Player 2 presses F on "Ride". Player 1 then drives around. | Player 2 sits in the passenger seat and rides along; Player 1 drives. Each prompt hides while its seat is taken. | |
| CAR8 | 2 players: in the Server view, with Player 2's Humanoid, try `DriverSeat:Sit(humanoid)` (simulates a cheat). | Player 2 is thrown out of the driver's seat at once and put beside the door. | |
| CAR9 | Drive off the edge of the map (any side), with and without a passenger. | Within about half a second of going over and falling (or by y −20), the car is back parked in its garage, and the driver (and passenger) respawn at the spawn in front of their own plot (a passenger without a plot: a normal spawn). Nobody falls forever; no errors. | |
| CAR10 | Flip the car (drive up something steep, or in the Server view rotate the `Body` onto its roof) and leave it still. | After about 4 s it is back parked in its garage, upright. | |
| CAR11 | Leave the car anywhere on the map, then (owner) leave the game. | The car disappears with the garage; nothing is left in `Workspace.Cars`. Rejoin and claim a plot: when the Garage is restored the car is back parked in the garage. | |
| CAR12 | Owner leaves while Player 2 rides as passenger. | The car disappears; Player 2 stands where it was and can walk. | |
| CAR13 | Turned plots: claim Plot 2, 3 and 4 (or 4 players), build the Garage on each. | Each car spawns in its own garage, nose out of the door; driving, getting in/out, edge respawn (to that plot's spawn) and flip reset work the same. | |
| CAR14 | Plot without a garage map (branch without `GarageCar`). | No car, no errors (CarService skips the plot). | |


## Photo Mode

Setup: `Config.DevPhotoMode = true` (leave `DevAllTrophies` and
`DevUnlimitedCash` false). Set it back to **false** before committing.

| ID | Test | Expected | Status |
| -- | ---- | -------- | ------ |
| PM1 | `DevPhotoMode = false`: Play. Press 1–6, 0, C, H. | Nothing different from normal: no hint, no auto-claim, keys do nothing new, normal time of day, saving works as before (no `[DevPhotoMode]` lines in Output). | |
| PM2 | `DevPhotoMode = true`: Play. | Output: `[DevPhotoMode] DataStore is OFF` and `[DevPhotoMode] Photo Mode is ON`. You own Plot1 at once, fully built: droppers 1–8 dropping, walls, stairs, 2nd floor, all furniture, Trophy Case, garage with a drivable car, pool, path, hangout; back door open; no buy buttons left. Bright afternoon sun. No errors. | |
| PM3 | After PM2, stop, set `DevPhotoMode = false`, Play again (with API access on). | Your real save is unchanged: same cookies and house as before PM2 (not the showcase plot). | |
| PM4 | Press 1–6 on Plot1. | Each key snaps to its shot: 1 whole tycoon, 2 house front, 3 backyard pool + hangout, 4 garage + car, 5 statue with your plot behind it, 6 droppers + conveyor + cash tank. Note any shot that needs its numbers in `PhotoMode.Shots` changed. | |
| PM5 | Test → Clients and Servers with 4 players (or claim order): players get Plot1–4. On each, press 1–6. | Each player's shots frame their **own** plot the same way as on Plot1 (turned with the plot). | |
| PM6 | Press 0, then C. | The normal camera follows your character again, normal zoom/FOV. | |
| PM7 | Open the 🏆 TROPHIES panel, then press H; press H again. | H hides every ScreenGui (cookie counter, trophies button/panel, hint), the floating labels (statue bar, jar counter) and Roblox's chat / player list; pad labels may stay. Second H shows exactly what was shown before (the panel is still open; nothing that was hidden before comes back). | |
| PM8 | Type "1" or "h" in chat. | Nothing happens to the camera or UI while typing. | |
