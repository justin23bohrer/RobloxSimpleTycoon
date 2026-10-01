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

- There is **1** plot (`Config.NumberOfTycoonPlots`), directly in front of
  the spawn. We build one tycoon at a time.
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

- **Walls:** gingerbread-brown walls, 15 studs high, around the edge of the
  plot, with a 16-stud doorway in the middle of the front wall.
- **Stairs:** 16 cream steps along the right wall, climbing from the front
  (z −20) to the back (z −52), ending level with the top of the walls.
- **2nd Floor:** a floor on top of the walls (the roof) with a hole where the
  stairs come up, a railing around the edge and around the stair hole, and a
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

- Behind the Collect pad is a purple wall with a gold frame, a pink
  "COOKIE JAR" sign, and a glass tank on an orange stand (the `CashTank` model).
- Each drop that reaches the collector drops one small cookie into the jar,
  so it fills up as cookies wait (it stops adding at 60, when it looks
  full; the stored cookies keep adding up).
- While cookies are waiting, the pad sparkles gold and glows.
- A gold arrow always bounces above the pad.
- Collecting empties the tank with a burst of gold sparkles.
- All of this is looks only; the server's stored cookies decide the payout.

## Plot layout (prototype)

Plain parts only, no theme. The plot floor is **66 × 66 studs** (2/3 of the
earlier 100 × 100) and the ground is 280 × 280 of green grass
(`Material = Grass`, color `86,166,64`). Seen from the spawn, looking at the
plot ("left" is −X, "back" is −Z):

First floor (walls shown with `█`; they appear once built):

```
   ██████████████████ BACK (z = -76)  [ cash tank ] ██████████████
   █ Collector ■                      ( Collect )                █
   █         ║                                         stairs    █
   █         ║  ▣ spot 4   ( Buy 4 )                    top  ▲   █
   █ Conveyor║  ▣ spot 3   ( Buy 3 )   ( Build 3 )          ▲   █
   █ (moves  ║  ▣ spot 2   ( Buy 2 )   ( Build 2 )          ▲   █
   █ to back)║  ▣ spot 1   ( Buy 1 )   ( Build 1 )          ▲   █
   █         ║                                       bottom ▲   █
   █                ( Claim )                       [ Owner sign ]█
   ███████████████   doorway   ███████████████████████████████████
                 FRONT (z = -10)
                      ( Spawn )
```

Second floor (on the roof, top at y = 18): the same left-side layout,
directly above floor 1 — `Conveyor2` with `DropperSpot5`–`8` over it, red
`BuyButton5`–`8` just right of it, `Collector2` at the back-left — plus the
railed hole where the stairs arrive (back-right) and a railing around the
edge.

| Part | Position (center) |
| ---- | ----------------- |
| `Base` | (0, 1.5, −43), 66 × 1 × 66 |
| `Conveyor` | (−28, 2.5, −42), 4 × 1 × 48, runs front → back along the left side |
| `DropperSpot1`–`4` | x −28, y 8, z −22 / −30 / −38 / −46 (above the conveyor) |
| `BuyButton1`–`4` | x −20, z matching their spot (just right of the conveyor) |
| `Collector` | (−28, 2.5, −69), back-left corner at the conveyor's end |
| `CollectPad` | (0, 2.2, −68), centered on the back wall; `CashTank` right behind it |
| `ClaimPad` | (0, 2.2, −15), front center |
| `OwnerSign` | (23, 5, −12), front-right corner |
| `BuildButton1`–`3` | x 16, y 2.2, z −26 / −34 / −42 (right side of floor 1) |
| `Walls` (model) | `WallLeft`/`WallRight` (x ±32.5), `WallBack` (z −75.5), `WallFrontLeft`/`WallFrontRight` (z −10.5, doorway x −8..8); 1 thick, y 2..17 |
| `Stairs` (model) | `Step1`–`Step16`, x 26..32; step k is k studs high (top at y 2 + k), 2 deep, from z −20 back to z −52 |
| `SecondFloor` (model) | Slab y 17..18 in four pieces (`FloorMain`, `FloorBackRight`, `FloorFrontRight`, `FloorRightEdge`) leaving a hole at x 26..32, z −20..−52; `Rail*` 3-high railings on the edge and `HoleRailSide`/`HoleRailFront` around the hole |
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
| `Walls`, `Stairs`, `SecondFloor` | Models that appear when built. Walls and railings gingerbread `196,128,72`, steps cream `245,225,190`, 2nd floor `200,200,200` like `Base`. |
| `Conveyor`, `Conveyor2` | Dark strips that carry drops (floor 1, floor 2). |
| `Collector`, `Collector2` | Green blocks at the end of each conveyor.     |
| `CollectPad`       | Round green pad with a dark green ring. Pays the owner their stored cookies. |
| `CashTank`         | Model behind the Collect pad: `TankWallBorder`, `TankWall`, `TankSign`, `TankStand`, glass `TankLeft`/`TankRight`/`TankFront`/`TankLid`. The small cookies (`TankCookie` parts) go in a `TankCubes` folder made at runtime. |
| `SpawnLocation`    | Round blue pad with a dark blue ring, in `Map` (not the plot). Where players appear. |
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
- FEED! spends that many of your cookies (server-checked: you must be at a
  pad and able to afford it). Caleb's total is shared by everyone on the
  server and resets when the server restarts (no saving yet).
- The more he has eaten, the **fatter** he gets: wider and deeper body, a
  big round belly, thicker arms and legs, chubby cheeks, and a double chin.
  Growth follows log(cookies) so even small feeds show: ~100 cookies is about
  a third of the way, ~10,000 about two thirds.
- At **1,000,000** cookies (`Config.StatueMaxCookies`) he is as fat as he
  gets and stops eating: the pad signs say "CALEB IS FULL!" and feeds are
  refused. If a feed would go past the max, only the cookies he still has
  room for are spent. (What happens at a million is still to be decided.)
- Walking away or pressing Cancel closes the pop-up; step off the pad and
  back on to open it again.

### Pad style (copy this for new pads)

| Piece | Setting |
| ----- | ------- |
| Pad (the part players touch) | `Part`, `Shape = Cylinder`, CFrame rotated 90° around Z (orientation `[[0,-1,0],[1,0,0],[0,0,1]]`) so the round face points up. Plot pads: `Size = [0.4, 6, 6]` (height, diameter, diameter), bottom resting on `Base` (Y = 2.2). SmoothPlastic, bold color. |
| Ring (outline) | A child of the pad named `<PadName>Ring`. Same shape and rotation, half the pad's height, 1.5 studs wider (plot pads: `Size = [0.2, 7.5, 7.5]`, Y = 2.1), darker shade of the pad color. `Anchored`, `CanTouch = false`, `CanQuery = false`. |
| Label | Cartoony sign that matches the cash display. `BillboardGui` named `Label` on the pad (`LightInfluence = 0`, about 3 studs up) → `Frame` `Panel` in the pad's bright color with `UICorner` (0.35 scale) and a 4 px `UIStroke` border in the dark outline color `40,28,20` → `TextLabel` named `TextLabel` (white, `FredokaOne`, `TextScaled`, `RichText`, 88%×80% centered) with a 2.5 px Contextual `UIStroke` in the same dark color. Code finds the text with `FindFirstChild("TextLabel", true)`, so keep exactly one TextLabel per pad. |

Buy button colors: pad `255,0,0` (BuyButtons.luau resets the buttons to this
exact red), ring `110,0,0`. Collect pad: `0,220,70` / ring `0,95,35`.
Spawn (14 studs wide): `70,160,255` / ring `20,60,150`.
Claim pad: `0,162,255` / ring `0,70,140`.
Owner sign: the `OwnerSign` wall is gold (`255,200,40`) and acts as the frame.
Each face (`Back` toward the spawn, `Front` into the plot) has a `SurfaceGui`
(`OwnerLabelBack` / `OwnerLabelFront`, `PixelsPerStud` 50, `LightInfluence = 0`)
→ purple (`150,70,230`) `Panel` with `UICorner` and a 12 px dark `UIStroke` →
white `FredokaOne` `TextLabel` with a 7 px dark Contextual `UIStroke`. Same
look as the pad signs, scaled for a surface. `RichText` stays off so a
player's name is always shown as plain text. TycoonService sets every
TextLabel on the sign.
Label panels: Claim `0,162,255` "CLAIM TYCOON!"; Buy `255,60,60` "Dropper N" +
yellow (`#FFE14D`) price; Collect `0,200,80` "COLLECT!".
