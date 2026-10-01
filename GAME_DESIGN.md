# SimpleTycoon Game Design (MVP)

This is the complete scope of the MVP. Anything not listed here is out of
scope until the user approves it (see `TODO.md`).

## Currency: cookies

The game's currency is **cookies** (🍪), not money. Droppers drop cookies,
everything costs cookies, and the player's total is shown as Cookies. In
code and config the currency is still called "cash" (`StartingCash`,
`EconomyService.AddCash`, ...); only what players see says cookies.

## Core loop

Player joins → receives 100 cookies → steps on the blue **Claim Tycoon** pad →
their collect area and a FREE Dropper 1 button appear → buys Dropper 1 →
it drops a 10-cookie cookie every 2 seconds → cookies ride a conveyor to the
collector → player steps on the Collect pad → their cookies increase → the
next, more expensive dropper's button has appeared, so they save up for it.

## Player

- Starts each session with **100 cookies** (`Config.StartingCash`).
- Cookies are shown in the Roblox player list (`leaderstats.Cookies`) and in
  a cartoony panel at the bottom-center of the screen (a drawn chocolate chip
  cookie and e.g. "1,250") that bounces when the amount changes.
- No saving between sessions yet.

## Tycoon

- There are **4** plots (`Config.NumberOfTycoonPlots`), so up to 4 people
  can each run a tycoon on the same server. They sit around the statue at
  the same distance (each plot's center is 87 studs from the statue's
  center), turned so every house's front doorway and Claim pad face the
  statue. Plot1 is in front of the statue (−Z), Plot2 to its −X side,
  Plot3 behind it (+Z), Plot4 to its +X side.
- Each plot has its own spawn area between it and the statue (44 studs from
  the statue's center). The spawn areas are invisible: players just appear
  on the grass there, with no pad or disc. Players appear at a random one of the four.
- Plots 2–4 and spawns 2–4 are exact turned copies of Plot1 and the first
  spawn, made by `tools/plots/generate_plots.py`. Only Plot1 is edited.
- Players are **not** given a plot on join. A free plot shows only its floor
  and a round blue **Claim Tycoon** pad. The first player to step on it owns
  the plot. A player can own only one plot.
- That player owns the plot. Other players cannot use it. While it is taken
  the Claim pad is gone, so nobody else can claim it.
- The plot builds up step by step (nothing shows before it is needed):

  | When | What appears | What disappears |
  | ---- | ------------ | --------------- |
  | Unclaimed | Floor and the Claim Tycoon pad only. | Everything else. |
  | Claimed | Owner sign ("<name>'s Tycoon"), conveyor, collector, Collect pad with its cookie jar, and the **Dropper 1 / FREE!** button with its yellow spot. | The Claim pad. |
  | Dropper N bought | The dropper at its spot, and the next dropper's button and yellow spot. | Button N and its yellow spot. |
  | Dropper 4 bought | Nothing new (all droppers bought). | Button 4. |

- When the player leaves, the plot is released and reset: everything hides
  again and the Claim pad comes back for the next player.

## Purchase

Everything is unlocked **one step at a time**, in this chain:

**Dropper 1 → 2 → 3 → 4 → Build Walls → Build Stairs → 2nd Floor → Dropper 5 → 6 → 7 → 8**

Each step's button appears only after the step before it is bought, and the
server refuses to sell anything out of order (`After` in `Config`).

| Step | Button | Cost (cookies) | Value per drop (cookies) |
| ---- | ------ | -------------- | ------------------------ |
| Dropper 1 | red `BuyButton1` | FREE | 10 |
| Dropper 2 | red `BuyButton2` | 300 | 25 |
| Dropper 3 | red `BuyButton3` | 1000 | 60 |
| Dropper 4 | red `BuyButton4` | 3000 | 150 |
| Walls | orange `BuildButton1` | 5000 | — |
| Stairs | orange `BuildButton2` | 8000 | — |
| 2nd Floor | orange `BuildButton3` | 15000 | — |
| Dropper 5 (2nd floor) | red `BuyButton5` | 20000 | 300 |
| Dropper 6 (2nd floor) | red `BuyButton6` | 35000 | 450 |
| Dropper 7 (2nd floor) | red `BuyButton7` | 60000 | 700 |
| Dropper 8 (2nd floor) | red `BuyButton8` | 100000 | 1000 |

- The owner buys something by stepping on its button. The label shows the
  name with the price under it in yellow, e.g. "Dropper 2 / 🍪 300",
  "Build Walls / 🍪 5000", or "Dropper 1 / FREE!" (text comes from
  `Config`; a `Cost` of 0 is free).
- The player must have enough cookies (the free dropper needs none).
- The purchase is decided on the server.
- Each step can only be bought once per plot. A bought button disappears
  (pad, ring, label, and a dropper's yellow spot). Everything is hidden again
  when the plot is released.

## Building (walls, stairs, 2nd floor)

The right side of the first floor is the **build area**: three orange build
buttons appear there one at a time after Dropper 4.

- **Walls:** the first floor of a two-story house: off-white brick walls,
  15 studs high, around the edge of the plot, with gray trim (corner posts,
  a base strip, a band along the top) and dark windows with gray frames,
  grilles, and sills. The front has a gray-framed, garage-style doorway
  (16 wide, 11 high) in the middle.
- **Stairs:** 16 cream steps along the right wall, climbing from the front
  (z −20) to the back (z −52), ending level with the top of the walls.
- **2nd Floor:** a floor on top of the walls with a hole where the stairs
  come up (railed), the **second story of the house** (more off-white brick
  walls with gray corner posts and windows: two plain ones, an arched one
  above the doorway, and a wide one on the front), and a **gray shingle
  roof**: a hip roof that slopes down on all four sides to eaves overhanging
  the walls, with a ridge on top, darker ridge and hip caps, a soffit and
  fascia under the eaves, a pointed brick front gable with gray rake trim
  and a round vent above the arched window, and a brick chimney at the back. Under the roof there is a
  **second conveyor** on the **same (left) side** as the first one, directly
  above it, moving the same way (front → back) into a second collector.
  Droppers 5–8 sit above it, with their red buttons just right of it, like
  floor 1.
- Cookies that reach the 2nd-floor collector go into the **same** stored
  cookies and cookie jar as floor 1; the owner collects them all on the
  Collect pad downstairs.
- Built parts are hidden (invisible, can't be touched or walked on) until
  bought.

## Droppers

A bought dropper looks like an **upside-down red party cup** (red with
darker ridges, a rolled lip, and a white inside you can see from below);
cookies fall out of its open end onto the conveyor. Both conveyors and
their collectors have gray metal **guard rails** (2 studs above the belt)
on the sides, a stop at the front end of each conveyor, and a stop behind
each collector, so cookies can't fall off.

- Each bought dropper drops one physical **cookie** worth its value every
  **2 seconds** (`Config.DropInterval`, shared by all droppers). A cookie is
  a flat golden-brown disc with chocolate chips (built from plain parts).
- Droppers 1–4 drop onto the first-floor conveyor, droppers 5–8 onto the
  second-floor one. Each conveyor carries cookies to its own collector, and
  runs while any of its droppers runs.

## Testing: unlimited cookies (Studio only)

- `Config.DevUnlimitedCash = true` makes players start with
  `Config.DevStartingCash` (1,000,000,000 cookies) instead of 100, **only** in
  Roblox Studio. It never applies in a published game. Buying still spends
  cookies normally. Must be `false` in commits.

## Collector

- Cookies that reach the plot's collector add their value to that plot's
  stored cookies.
- The owning player collects the stored cookies by stepping on the green
  **Collect** pad (label "COLLECT!").
- Other players cannot collect it.

### Cookie jar (collect area look)

The stored amount is **not** shown as text. Instead:

- The cookie jar stands on its own in the **middle of the first floor**,
  facing the front (the spawn side). The Collect pad is only on its front;
  behind it is a purple wall with a gold frame, a cartoony "COOKIE JAR" sign, and
  a glass tank on an orange stand (the `CashTank` model). The wall's plain
  back faces the back of the room, so you can only collect from the front.
- Each drop that reaches the collector drops one small cookie into the jar,
  so it fills up as cookies wait (it stops adding at 60, when it looks
  full; the stored cookies keep adding up).
- While cookies are waiting, the pad sparkles gold and glows.
- A gold arrow always bounces above the pad.
- Collecting empties the tank with a burst of gold sparkles.
- All of this is looks only; the server's stored cookies decide the payout.

## Plot layout (prototype)

Plain parts only, no theme. Each plot floor is **66 × 66 studs** (2/3 of the
earlier 100 × 100). The ground is 300 × 300 of green grass (`Material =
Grass`, color `86,166,64`), centered on the statue at (0, 0.5, 44) so all
four plots sit on it. The map and positions below are for **Plot1**; Plots
2–4 are the same, turned 90°, 180°, and 270° around the statue's center
(0, 44). Seen from Plot1's spawn, looking at the plot ("left" is −X, "back"
is −Z):

First floor (walls shown with `█`; they appear once built):

```
   ██████████████████ BACK (z = -76) ████████████████████████████
   █ Collector ■                                                 █
   █         ║                                         stairs    █
   █         ║  ▣ spot 4   ( Buy 4 ) [cookie jar]       top  ▲   █
   █ Conveyor║  ▣ spot 3   ( Buy 3 ) ( Collect ) ( Build 3 ) ▲   █
   █ (moves  ║  ▣ spot 2   ( Buy 2 )             ( Build 2 ) ▲   █
   █ to back)║  ▣ spot 1   ( Buy 1 )             ( Build 1 ) ▲   █
   █         ║                                       bottom ▲   █
   █                ( Claim )                       [ Owner sign ]█
   ███████████████   doorway   ███████████████████████████████████
                 FRONT (z = -10)
                      ( Spawn )
```

Second floor (floor at y = 18, walls up to y = 31, roof ridge at y = 45):
the same left-side layout, directly above floor 1 — `Conveyor2` with
`DropperSpot5`–`8` over it, red `BuyButton5`–`8` just right of it,
`Collector2` at the back-left — plus the railed hole where the stairs arrive
(back-right).

| Part | Position (center) |
| ---- | ----------------- |
| `Base` | (0, 1.5, −43), 66 × 1 × 66 |
| `Conveyor` | (−28, 2.5, −42), 4 × 1 × 48, runs front → back along the left side |
| `DropperSpot1`–`4` | x −28, y 8, z −22 / −30 / −38 / −46 (above the conveyor) |
| `BuyButton1`–`4` | x −20, z matching their spot (just right of the conveyor) |
| `Collector` | (−28, 2.5, −69), back-left corner at the conveyor's end |
| `CollectPad` | (0, 2.2, −41), middle of floor 1, on the front side of the `CashTank` (jar wall's back at z −48.4); free-standing, so the jar's back faces the back of the room |
| `ClaimPad` | (0, 2.2, −15), front center |
| `OwnerSign` | (23, 5, −12), front-right corner |
| `BuildButton1`–`3` | x 16, y 2.2, z −26 / −34 / −42 (right side of floor 1) |
| `Walls` (model) | `WallLeft`/`WallRight` (x ±32.5), `WallBack` (z −75.5), `WallFrontLeft`/`WallFrontRight` (z −10.5, doorway x −8..8) and `DoorHeader` (y 13..17); 1 thick, y 2..17. Plus gray trim (`Corner*`, `Plinth*`, `FloorBand*`, `DoorFrame*`) and a `Windows` model. **Generated** by `tools/house/generate_house.py`. |
| `Stairs` (model) | `Step1`–`Step16`, x 26..32; step k is k studs high (top at y 2 + k), 2 deep, from z −20 back to z −52 |
| `SecondFloor` (model) | Slab y 17..18 in four pieces (`FloorMain`, `FloorBackRight`, `FloorFrontRight`, `FloorRightEdge`) leaving a hole at x 26..32, z −20..−52; `HoleRailSide`/`HoleRailFront` around the hole; second-story walls `Wall2Left`/`Wall2Right`/`Wall2Back`/`Wall2Front` (y 18..31) with `UpperCorner*` posts and a `Windows` model; `Roof` model (hip roof: `RoofFront*`/`RoofBack*`/`RoofLeft*`/`RoofRight*` triangles made of WedgeParts from the eaves at y 31 to the ridge x −10..10 at y 46, 1.5-stud overhang; `RidgeCap`, `Hip*Cap`, `Soffit`, `Fascia*`, the `FrontGable` model, and the `Chimney` model). **Generated** by `tools/house/generate_house.py`. |
| `Conveyor2` | (−28, 18.5, −42), 4 × 1 × 48, above `Conveyor` |
| `Collector2` | (−28, 18.5, −69), above `Collector` |
| `DropperSpot5`–`8` | x −28, y 24, z −22 / −30 / −38 / −46 |
| `BuyButton5`–`8` | x −20, y 18.2, z matching their spot |

Each conveyor pushes drops toward its collector (`Conveyor` → `Collector`,
`Conveyor2` → `Collector2`; DropperService works the direction out from
their positions), so moving those parts is enough to reroute one.

The spots players step on are flat round pads with a darker ring underneath
as an outline:

| Part               | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `Base`             | 66 × 66 plot floor, in front of the spawn. Always visible. |
| `ClaimPad`         | Round blue pad with a dark blue ring at the front of the plot, label "CLAIM TYCOON!". Shown only while the plot is unclaimed. |
| `OwnerSign`        | Gold-framed wall with a purple cartoony panel on both faces showing "<DisplayName>'s Tycoon" (hidden until claimed). |
| `BuyButton1`–`8`   | Round red pads with dark red rings, in a line just right of their floor's conveyor, each next to its dropper spot. Buy droppers 1–8 (5–8 on the 2nd floor). |
| `DropperSpot1`–`8` | Transparent yellow blocks above the conveyor where each dropper goes. |
| `BuildButton1`–`3` | Round orange pads (`255,140,0`, ring `140,70,0`, sign panel orange) on the right side of floor 1. Build the walls, stairs, and 2nd floor. |
| `Walls`, `Stairs`, `SecondFloor` | Models that appear when built. House walls off-white `Brick` `238,235,228`; trim, window frames, and hole railings gray `122,126,130`; window glass `44,50,58`; roof `Slate` `96,100,104`; steps cream `245,225,190`; 2nd floor `200,200,200` like `Base`. Trim and windows are looks only (`CanCollide`/`CanTouch`/`CanQuery` off). |
| `Conveyor`, `Conveyor2` | Dark strips that carry drops (floor 1, floor 2). Each has `RailLeft`/`RailRight`/`RailFront` children: gray `Metal` guard rails, 0.4 thick, from the floor to 2 studs above the belt (`CanTouch`/`CanQuery` off). The collectors have `RailLeft`/`RailRight`/`RailBack`. |
| `Collector`, `Collector2` | Green blocks at the end of each conveyor.     |
| `CollectPad`       | Round green pad with a dark green ring. Pays the owner their stored cookies. |
| `CashTank`         | Model behind the Collect pad: `TankWallBorder`, `TankWall`, `TankSign`, `TankStand`, glass `TankLeft`/`TankRight`/`TankFront`/`TankLid`. The small cookies (`TankCookie` parts) go in a `TankCubes` folder made at runtime. |
| `SpawnLocation`, `SpawnLocation2`–`4` | Invisible 14 × 14 spawn areas (`Block`, `Transparency = 1`, `Anchored`, no ring or decal) sunk into the ground so the top is flush with the grass (center Y = 0.5, top Y = 1), in `Map` (not the plots), one between each plot and the statue. Where players appear (a random one). `SpawnLocation2`–`4` are generated. |
| `Statue`           | In `Map` (not the plot), behind the spawn at z ≈ 44, facing it: turn around after spawning to see it. See below. |

### Statue (Caleb)

A giant cartoony statue (about **43 studs** tall, roughly two stories)
standing on a stone pedestal with a gold trim, behind the spawn. Rick and
Morty-style caricature: huge round head, big white eyes with tiny pupils, a
wide toothy grin, short dark brows. Its look comes from two reference photos
the user provided (`agent-office/assets/IMG_2755.JPEG` for the face, smile,
dark navy long-sleeve shirt, thin gold chain, and hand-on-hip pose;
`IMG_9026.jpeg` for the shaggy, medium-length dark-brown hair with a messy
fringe that covers the ears). Dark-gray pants and white sneakers.

Built only from plain parts (balls, blocks) plus a `Highlight` named
`CartoonOutline` (black outline, no fill). No images, meshes, or scripts.
All parts are anchored and solid (players can climb it); mouth, teeth, and
chain are non-colliding. `CanTouch` is off on every statue part (only the
feed pads can be touched). The JSON is generated by
`tools/statue/generate_statue.py`; edit the script, not the JSON.

### Feeding Caleb

- Four round orange **feed pads** (orange ring, sign "FEED CALEB!") sit on
  the grass around the pedestal: front (facing the spawn), back, left, and
  right, about 18 studs from its center.
- Stepping on one opens a pop-up in the cookie counter's style: **"How many
  cookies do you want to feed Caleb?"**, how many he has eaten so far out of
  1,000,000 (with a progress bar), how many cookies you have, an amount box,
  quick buttons **10 / 100 / 1K / ALL**, and **Cancel** / **FEED!**.
- **10 / 100 / 1K add** to the amount every time you click them (1K, 1K, 10
  → 2,010). **ALL** replaces it with everything you can feed. You can also
  type the amount.
- The **progress bar is exact**: cookies eaten out of 1,000,000 (the full
  bar). A lighter part of the bar shows exactly where it will be after
  feeding the amount you picked (red if you don't have that many cookies).
  The text shows the exact percentage, e.g. "1,250 / 1,000,000  +1,000 =
  0.23%". Anything above 0 is drawn at least a thin sliver wide so you can
  see it. The bar slides when it changes. (Caleb's body still grows on its
  own curve, so small feeds still show on the statue.)
- After a successful feed the pop-up **closes right away** and a small
  Roblox notification says "Caleb ate N cookies!". Step off the pad and back
  on to feed again.
- FEED! spends that many of your cookies (server-checked: you must be at a
  pad and able to afford it). Caleb's total is shared by everyone on the
  server and resets when the server restarts (no saving yet).
- The more he has eaten, the **fatter** he gets: wider and deeper body, a
  big round belly, thicker arms and legs, chubby cheeks, and a double chin.
  His size follows progress = cookies eaten / goal (same as the bar).
- At **1,000,000** cookies (`Config.StatueMaxCookies`) he is as fat as he
  gets and stops eating: the pad signs say "CALEB IS FULL!" and feeds are
  refused. If a feed would go past the max, only the cookies he still has
  room for are spent. Then the **Caleb Full Event** starts (below).

### Caleb Full Event (server rules)

- When the shared total reaches the goal, the event runs once:
  **Full** (5 s) → **Celebration** (115 s) → **Trophy claim** (300 s,
  Caleb is hidden) → **reset**. Feeding is refused the whole time
  ("Caleb is FULL!"), and the pads say "CALEB IS FULL!".
- Every cookie a player feeds counts as their **contribution** this cycle.
  Contributions are remembered by account, so leaving and rejoining the same
  server keeps them. The top 10 feeders are shown on the podium board.
- During the trophy claim, every player who fed Caleb at least 1 cookie this
  cycle can claim one trophy. Players who fed nothing (including anyone who
  joined after the goal) can't.
- On reset everything starts over: total 0, contributions and claims
  cleared, an empty board, Caleb back at his smallest size and visible, and
  a new event id (so each cycle's trophy is unique). Pads say "FEED CALEB!"
  again.
- Testing: `Config.DevCalebFastCycle = true` (Studio only) makes the goal
  1,000 cookies and the states 3 s / 20 s / 30 s.
- Walking away or pressing Cancel closes the pop-up; step off the pad and
  back on to open it again.
- A **progress bar floats above Caleb's head** for everyone on the server,
  readable from anywhere on the map (drawn on top of houses, up to
  `Config.StatueBarMaxDistance` studs away). Same look as the pop-up: yellow
  rounded panel, thick dark outline, FredokaOne, and the same cookie bar.
  It reads **"Caleb: 12,345 / 1,000,000 🍪"**, and **"Caleb is FULL!
  1,000,000 🍪"** with a full bar at the max. When anyone feeds him the bar
  slides and the panel gives a little pop. It sits `Config.StatueBarHeight`
  studs above the top of his head (his head never grows, so the bar stays
  clear of him however fat he gets).

### Pad style (copy this for new pads)

| Piece | Setting |
| ----- | ------- |
| Pad (the part players touch) | `Part`, `Shape = Cylinder`, CFrame rotated 90° around Z (orientation `[[0,-1,0],[1,0,0],[0,0,1]]`) so the round face points up. Plot pads: `Size = [0.4, 6, 6]` (height, diameter, diameter), bottom resting on `Base` (Y = 2.2). SmoothPlastic, bold color. |
| Ring (outline) | A child of the pad named `<PadName>Ring`. Same shape and rotation, half the pad's height, 1.5 studs wider (plot pads: `Size = [0.2, 7.5, 7.5]`, Y = 2.1), darker shade of the pad color. `Anchored`, `CanTouch = false`, `CanQuery = false`. |
| Label | Cartoony sign that matches the cash display. `BillboardGui` named `Label` on the pad (`LightInfluence = 0`, about 3 studs up) → `Frame` `Panel` in the pad's bright color with `UICorner` (0.35 scale) and a 4 px `UIStroke` border in the dark outline color `40,28,20` → `TextLabel` named `TextLabel` (white, `FredokaOne`, `TextScaled`, `RichText`, 88%×80% centered) with a 2.5 px Contextual `UIStroke` in the same dark color. Code finds the text with `FindFirstChild("TextLabel", true)`, so keep exactly one TextLabel per pad. |

Buy button colors: pad `255,0,0` (BuyButtons.luau resets the buttons to this
exact red), ring `110,0,0`. Collect pad: `0,220,70` / ring `0,95,35`.
Claim pad: `0,162,255` / ring `0,70,140`.
Owner sign: the `OwnerSign` wall is gold (`255,200,40`) and acts as the frame.
Each face (`Back` toward the spawn, `Front` into the plot) has a `SurfaceGui`
(`OwnerLabelBack` / `OwnerLabelFront`, `PixelsPerStud` 50, `LightInfluence = 0`)
→ purple (`150,70,230`) `Panel` with `UICorner` and a 12 px dark `UIStroke` →
white `FredokaOne` `TextLabel` with a 7 px dark Contextual `UIStroke`. Same
look as the pad signs, scaled for a surface. `RichText` stays off so a
player's name is always shown as plain text. TycoonService sets every
TextLabel on the sign.
Cookie jar sign: the `TankSign` part (on the jar wall, 10 × 2.2) is gold
(`255,200,40`) and acts as the frame, like the owner sign. Its pad-facing
`Back` face has a `SurfaceGui` `SignGui` (`PixelsPerStud` 50,
`LightInfluence = 0`) → pink (`255,90,160`) `Panel` (94% × 84%) with
`UICorner` (0.35 scale) and a 6 px dark `UIStroke` → white `FredokaOne`
`TextLabel` "COOKIE JAR" (86% × 70%, centered, `TextScaled`) with a 3.5 px
dark Contextual `UIStroke`. No code touches it.
Label panels: Claim `0,162,255` "CLAIM TYCOON!"; Buy `255,60,60` "Dropper N" +
yellow (`#FFE14D`) price; Collect `0,200,80` "COLLECT!".
