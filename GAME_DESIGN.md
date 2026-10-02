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

- A new player starts with **100 cookies** (`Config.StartingCash`); a
  returning player gets their saved cookies back.
- Cookies are shown in the Roblox player list (`leaderstats.Cookies`) and in
  a cartoony panel at the bottom-center of the screen (a drawn chocolate chip
  cookie and e.g. "1,250") that bounces when the amount changes.
- **Saving** (approved by the user 2026-10-01): the player's **house** (every
  dropper and build they bought) and their **Caleb trophies** are saved
  between sessions. **Cookies are saved too** (approved 2026-10-02): leave
  and rejoin and you have the same cookies (saved every couple of minutes,
  on leave, and when the server shuts down). Players who saved before
  cookies were saved get 100 the first time. For the first moment after
  joining (while the save loads) cookies can't be spent; cookies earned in
  that moment are added on top of the saved amount.
  When a returning player claims any free plot, their house comes back
  exactly as they left it (built parts, running droppers, the right next
  buy buttons), for free. If their data can't be loaded (Roblox DataStore
  down, or Studio without API access), they play unsaved that session
  (starting with 100 cookies) and their old save is left untouched.

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
| Stairs | orange `BuildButton2` | 5000 | — |
| 2nd Floor | orange `BuildButton3` | 10000 | — |
| Dropper 5 (2nd floor) | red `BuyButton5` | 20000 | 300 |
| Dropper 6 (2nd floor) | red `BuyButton6` | 35000 | 450 |
| Dropper 7 (2nd floor) | red `BuyButton7` | 60000 | 700 |
| Dropper 8 (2nd floor) | red `BuyButton8` | 100000 | 1000 |
| Bed (2nd floor) | orange `BuildButton5` | 12000 | — |
| Gaming Desk (2nd floor) | orange `BuildButton6` | 25000 | — |
| Shelves + TV (2nd floor) | orange `BuildButton7` | 18000 | — |
| Mini Fridge (2nd floor) | orange `BuildButton8` | 8000 | — |
| Ninja Kitchen (2nd floor) | orange `BuildButton9` | 10000 | — |

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

The right side of the first floor is the **build area**: orange build
buttons appear there one at a time after Dropper 4 (Walls first; after the
walls both Stairs and the Trophy Case are offered).

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
- **Trophy Case** (🍪 7,500, after the walls; button `BuildButton4` at the
  back of the build area): the house's big centerpiece (user, 2026-10-01:
  "significantly larger than a normal shelf"). A tall dark-wood display
  cabinet (about 25 wide × 14.6 tall) with gold trim, a red velvet back, one
  tall glass front, a dim warm light inside (on only while trophies are
  shown; no Neon), and a red cartoony "MY CALEB TROPHIES" sign on top. It
  stands against the middle of the back wall (x −12.4..12.4, in front of the
  middle back window). It has **exactly 5 trophy slots** (one per active
  slot, redesigned 2026-10-02: "make it only want 5"), in one row on a
  raised red velvet stage with gold-topped risers like a podium (slot 1 in
  the middle is highest, then left, right, far left, far right). Below each
  slot, on the case's tall base, is a dark gold-framed nameplate with that
  trophy's name in its rarity color and its power (if it has one) in smaller
  white text; an empty slot's nameplate shows a dim "EMPTY". The owner's
  Caleb Trophies stand on the slots (see "Caleb Trophies" below). It is
  saved and restored like the other builds.
- **Second-floor furniture** (requested by the user 2026-10-01): cartoony
  versions of the user's real stuff (photos in `agent-office/assets`), laid
  out like the user's sketch. All five orange buttons appear **when the 2nd
  Floor is built, at the same time as Dropper 5**, so the player can buy
  furniture and the 2nd-floor droppers in any order. Each is bought once.
  - **Shelves + TV** (🍪 18,000) along the front wall: a dark cube
    bookshelf full of colorful books (and headphones) with the LEGO
    Barad-dûr tower (glowing orange Eye) and a lime-green drill on top; a
    cube TV stand with board games and white bins, a TV, a standing PS5, a
    white mushroom lamp, and a remote.
  - **Ninja Kitchen** (🍪 10,000) along the front wall on the conveyor side:
    a cream cabinet with a granite top and white tile backsplash, a cast
    iron skillet, the Ninja ice cream maker, and the Ninja blender.
  - **Gaming Desk** (🍪 25,000) against the back wall, right of the bed:
    one big straight black desk (about 20 studs long, no side piece) with
    three monitors (two wide ones and one standing up), a webcam, a
    white/blue keyboard, mouse, a cup, the controller, headphones, a black
    leather office chair,
    and a backpack on the floor.
  - **Bed** (🍪 12,000) at the back, next to the desk: a big bed (about
    13 × 18 studs) with a black headboard and frame, gray sheets, a white and a gray pillow, and a rumpled gray
    blanket.
  - **Mini Fridge** (🍪 8,000) against the back wall, left of the bed:
    a black mini fridge with the orange LEGO moon rocket on its launch tower
    on top, and a foam roller on the floor.
  - Generated by `tools/furniture/generate_furniture.py` (edit the script,
    not the JSON). Saved and restored like the other builds.
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
  cookies normally. While it is on, cookies are neither loaded nor saved, so
  the dev cookies never reach a real save. Must be `false` in commits.
- `Config.DevAllTrophies = true` (Studio only) gives each player
  `Config.DevAllTrophiesCopies` (5) copies of every collectable Caleb Trophy
  when they join, to test every trophy and stacking: buy the Trophy Case,
  open 🏆 TROPHIES, equip. They are session only (never saved) and not
  auto-equipped. Must be `false` in commits.

## Collector

- Cookies that reach the plot's collector add their value to that plot's
  stored cookies.
- The owning player collects the stored cookies by stepping on the green
  **Collect** pad (label "COLLECT!").
- Other players cannot collect it.

### Cookie jar (collect area look)

The jar shows the stored amount both as small cookies and as a number:

- The cookie jar stands on its own in the **middle of the first floor**,
  facing the front (the spawn side). The Collect pad is only on its front;
  behind it is a purple wall with a gold frame, a cartoony "COOKIE JAR" sign, and
  a glass tank on an orange stand (the `CashTank` model). The wall's plain
  back faces the back of the room, so you can only collect from the front.
- Each drop that reaches the collector drops one small cookie into the jar,
  so it fills up as cookies wait (it stops adding at 60, when it looks
  full; the stored cookies keep adding up).
- A cartoony counter on top of the jar (a pink-framed gold plaque sitting
  right on top of the "COOKIE JAR" sign, facing the Collect pad) shows how many cookies are
  stored, e.g. "🍪 1,250" (with commas), and "🍪 0" when the jar is empty.
  It pops a little each time the number goes up, goes back to 0 when the
  owner collects or the plot is released, and is hidden with the jar while
  the plot is unclaimed. Both floors' collectors add to the same number.
  Everyone sees the same number. It shows the stored cookies; the owner's
  Collect Bonus trophy power is added on top when they collect.
- While cookies are waiting, the pad sparkles gold and glows.
- A gold arrow always bounces above the pad.
- Collecting empties the tank with a burst of gold sparkles.
- All of this is looks only; the server's stored cookies decide the payout.
  (Requested by the user 2026-10-01; replaces the old "no amount text" rule.)

### Tycoon sounds (approved by the user 2026-10-02)

Original sound effects (synthesized by `tools/audio/generate_sfx.py`), ids in
`Config.TycoonSounds` (empty = silent), volumes in `Config.TycoonSoundVolumes`.
They only react to what the server already decided.

- Buying a dropper: a "ka-ching!" at the button. Building a house part
  (walls, stairs, floor, furniture, Trophy Case): hammer knocks + whoosh +
  chime. Players nearby hear it too (3D).
- Stepping on a button you can't afford: a soft "nope" only you hear, at most
  once every 1.5 s per button.
- Collecting on the Collect pad: a cascade of coin clinks + a happy chime;
  the pitch rises a little for bigger payouts. Nearby players hear it.
- Each cookie reaching the jar: a tiny quiet "plink" (at most 6 per second
  per plot, however many droppers).
- Rebuilding your saved house when you claim a plot plays no sounds.

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
   █ Collector ■            [=TROPHY CASE=]                      █
   █         ║                                         stairs    █
   █         ║  ▣ spot 4   ( Buy 4 ) [cookie jar] ( Build 4 )▲   █
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
| `BuildButton1`–`4` | x 16, y 2.2, z −26 / −34 / −42 / −50 (right side of floor 1) |
| `BuildButton5`–`9` | 2nd floor (y 18.2), in front of each piece of furniture: Bed (−3, −50), Gaming Desk (15.5, −55), Shelves + TV (8, −21), Mini Fridge (−13.5, −63), Ninja Kitchen (−8, −21) |
| `Bed`, `GamingDesk`, `ShelvesTV`, `MiniFridge`, `KitchenCounter` (models) | 2nd-floor furniture (y 18 up to < 31). Shelves + TV along the front wall x 2.5..19.3; kitchen counter x −12.7..−3.3 on the front wall; straight desk against the back wall (x 8.1..28.4, out to z −69.4) and bed x −9.6..3.6, z −74.75..−56.5 against the back wall (both drawn big, `BED_GROW` / `DESK_GROW` in the generator, to fill the room); mini fridge against the back wall left of the bed (x −15.2..−11.8), foam roller next to it. Clear of the stair hole, Conveyor2, the dropper buttons, and the front windows except the wide one behind the bookshelf. **Generated** by `tools/furniture/generate_furniture.py`. |
| `TrophyCase` (model) | Against the middle of the back wall, x −12.4..12.4, z −74.7..−69.55, y 2..16.6 (the 2nd floor starts at y 17): `CaseBase` (y 2..5.6), `CaseSideLeft`/`Right`, velvet `CaseBack`, velvet `CaseStage` (top y 6.2), `CaseTop` (y 14.2..14.8), glass `CaseGlass` (y 5.6..14.2, Transparency 0.65), gold `GoldBase`/`GoldStageLip`/`GoldValance` (y 13.85..14.2)/`GoldEdgeLeft`/`Right`/`GoldTop`, `CaseSign` ("MY CALEB TROPHIES", y 14.8..16.6), warm `SurfaceLight` `CaseLight` on `CaseTop` (starts disabled); per slot N = 1–5 at x 0 / −4.48 / 4.48 / −8.96 / 8.96 (middle outward, as seen from the room): velvet `RiserN` + gold `RiserTrimN` (3.8 × 3.4, tops y 7.1 / 6.7 / 6.7 / 6.35 / 6.35), invisible `TrophySlotN` (z −72.4, top flush with the riser, turned to face into the room), and on the base's front a gold `NameplateFrameN` with a dark `NameplateN` (4 × 2.3, y 2.25..4.55, front at z −69.9) holding the `NameplateGui` SurfaceGui (`TrophyName`, `PowerText`; saved as a dim "EMPTY"). Covers the middle back window from inside; clear of the conveyor, collector, cookie jar/Collect pad (≥ 21 studs), stairs, `BuildButton4`, and doorway. **Generated** by `tools/trophycase/generate_trophy_case.py`. |
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
| `BuildButton1`–`4` | Round orange pads (`255,140,0`, ring `140,70,0`, sign panel orange) on the right side of floor 1. Build the walls, stairs, 2nd floor, and Trophy Case. |
| `Walls`, `Stairs`, `SecondFloor` | Models that appear when built. House walls off-white `Brick` `238,235,228`; trim, window frames, and hole railings gray `122,126,130`; window glass `44,50,58`; roof `Slate` `96,100,104`; steps cream `245,225,190`; 2nd floor `200,200,200` like `Base`. Trim and windows are looks only (`CanCollide`/`CanTouch`/`CanQuery` off). |
| `Conveyor`, `Conveyor2` | Dark strips that carry drops (floor 1, floor 2). Each has `RailLeft`/`RailRight`/`RailFront` children: gray `Metal` guard rails, 0.4 thick, from the floor to 2 studs above the belt (`CanTouch`/`CanQuery` off). The collectors have `RailLeft`/`RailRight`/`RailBack`. |
| `Collector`, `Collector2` | Green blocks at the end of each conveyor.     |
| `CollectPad`       | Round green pad with a dark green ring. Pays the owner their stored cookies. |
| `CashTank`         | Model behind the Collect pad: `TankWallBorder`, `TankWall`, `TankSign`, `TankStand`, glass `TankLeft`/`TankRight`/`TankFront`/`TankLid`. The small cookies (`TankCookie` parts) go in a `TankCubes` folder made at runtime, and the counter plaque (`JarCounter` part, made at runtime) sits directly on top of `TankSign`. |
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
  his goal (with a progress bar), how many cookies you have, an amount box,
  quick buttons **10 / 100 / 1K / ALL**, and **Cancel** / **FEED!**.
- **10 / 100 / 1K add** to the amount every time you click them (1K, 1K, 10
  → 2,010). **ALL** replaces it with everything you can feed. You can also
  type the amount.
- The **progress bar is exact**: cookies eaten out of the goal (the full
  bar). A lighter part of the bar shows exactly where it will be after
  feeding the amount you picked (red if you don't have that many cookies).
  The text shows the exact percentage, e.g. "1,250 / 1,000,000  +1,000 =
  0.23%" (with 3+ players). Anything above 0 is drawn at least a thin sliver wide so you can
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
  Fatness is front-loaded so even small feeds show (~100 cookies is about a
  fifth of the way, 1% of the goal about 60%, 25% about 90%).
- He also gets **bigger overall**: from `Config.CalebMinScale` (1×) to
  `Config.CalebMaxScale` (1.6×), feet staying on the pedestal. Size is
  back-loaded (progress², so the late feeds show), with one last jump when
  he reaches the goal: about 1.03× at 25%, 1.13× at 50%, 1.28× at 75%,
  1.41× at 90%, 1.49× at 99%, and 1.6× at 100%. Each change grows with a
  bouncy tween (`Config.CalebGrowSeconds`).
- **Caleb's goal grows with the server** (requested by the user
  2026-10-02): **350,000 cookies per player** (`Config.CalebGoalPerPlayer`),
  at most **1,000,000** (`Config.StatueMaxCookies`). 1 player: 350,000;
  2 players: 700,000; 3 or more: 1,000,000. That keeps the wait at about
  3–4 minutes at any server size, instead of 12+ minutes alone.
  - While Caleb is eating (Normal), the goal changes right away when
    someone joins or leaves; the bar, the pop-up, and the board update and
    Caleb's size follows the new progress.
  - If someone leaves and the new goal is at or below what Caleb already
    ate, he is full right away and the event starts.
  - During the event (Full, party, trophy claim) the goal stays as it was.
    Each new round computes it fresh from the players in the server.
- At the goal he is as fat as he gets and stops eating: the pad signs say
  "CALEB IS FULL!" and feeds are refused. If a feed would go past the goal,
  only the cookies he still has room for are spent. Then the **Caleb Full
  Event** starts (below).

### Caleb Full Event (server rules)

- When the shared total reaches the goal, the event runs once:
  **Full** (5 s) → **Celebration** (60 s) → **Trophy claim** (120 s,
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
  1,000 cookies (any number of players) and the states 3 s / 20 s / 30 s.
- Walking away or pressing Cancel closes the pop-up; step off the pad and
  back on to open it again.
- A **progress bar floats above Caleb's head** for everyone on the server,
  readable from anywhere on the map (drawn on top of houses, up to
  `Config.StatueBarMaxDistance` studs away). Same look as the pop-up: yellow
  rounded panel, thick dark outline, FredokaOne, and the same cookie bar.
  It reads **"Caleb: 12,345 / 350,000 🍪"** (the current goal), and
  **"Caleb is FULL! 350,000 🍪"** with a full bar at the goal. When anyone feeds him the bar
  slides and the panel gives a little pop. It sits `Config.StatueBarHeight`
  studs above the top of his head (his head never grows, so the bar stays
  clear of him however fat he gets).
- During the Caleb Full Event the bar's text follows the event: **"Caleb is
  FULL!"**, then **"🎉 COOKIE PARTY! 🎉"**, then **"Caleb is resting...
  💤"** while trophies are claimed.

### Caleb Trophies

- During the **trophy claim** (2 minutes), a big golden Caleb trophy stands
  on Caleb's pedestal (where he stood; he is hidden then) with a **"Claim
  Caleb Trophy"** prompt (hold E / tap, from up to
  `Config.TrophyClaimPromptDistance` studs). Only players who fed Caleb this
  round and haven't claimed see the prompt; the server checks again on
  every claim. One trophy per player per round; clicking twice never gives
  two. When the claim period ends, the trophy and prompt disappear and no
  more claims are accepted.
- Each claim gives a **random trophy** (`TrophyVariants.RollReward`; the
  definitions are in `Shared/TrophyVariantList.luau`). First a **rarity**
  is rolled by `Config.TrophyRarityChances` (Common 60%, Uncommon 20%,
  Rare 10%, Epic 6%, Legendary 3%, Mythic 1%), then a trophy of that rarity
  (by its Weight). Within the rolled rarity a player gets one they **don't
  own yet** whenever there is one left. Each trophy has its own colors,
  material, pose, accessories, effect, a fun description, and a **power**
  (only while displayed in a built Trophy Case, see `TrophyPowers`):

  | Trophy | Rarity | Power |
  | ------ | ------ | ----- |
  | Bronze Caleb | Common | +5% cookie production |
  | Party Caleb | Common | +35% walk speed |
  | Cookie Caleb (giant cookie) | Common | +25% cookie production |
  | Chef Caleb | Uncommon | +5% cookies when you collect |
  | Snack Time Caleb | Uncommon | 3% chance for an extra cookie |
  | Speed Caleb (lightning bolt, running) | Uncommon | +75% walk speed |
  | Jump Caleb (on springs) | Uncommon | +50% jump height |
  | Cool Caleb | Rare | +50% walk speed |
  | Stuffed Caleb | Rare | +15% cookie production |
  | Ruby Caleb | Rare | 4% chance for 5x cookies |
  | Fire Caleb (flame hair) | Rare | droppers 25% faster |
  | Clone Caleb (two mini Calebs) | Rare | 15% chance for an extra cookie |
  | Big Brain Caleb (big pink brain) | Rare | +10% cookies when you collect |
  | Diamond Caleb | Epic | 10% chance for 5x cookies |
  | Neon Caleb | Epic | droppers 30% faster |
  | Midnight Caleb | Epic | +40% jump height, +40% walk speed |
  | Rocket Caleb (rocket pack) | Epic | double jump, +20% jump height |
  | Rainbow Caleb (rainbow arch) | Epic | +10% cookies, jump height, dropper speed; +30% walk speed |
  | Golden Caleb | Legendary | 2x cookie production |
  | Cookie King Caleb | Legendary | +60% cookies, +15% when you collect |
  | King Caleb (crown + cape, glows) | Mythic | +50% cookies, +50% walk speed |

  Chef and Snack Time Caleb moved from Common to Uncommon (saved trophies
  keep their Id; only the rarity label changed). Adding a trophy = adding
  one entry to that list.
- A message tells the player what they got ("You got Golden Caleb
  (Legendary)!"). Trophies are **saved** (DataService). If saving isn't
  working for them (DataStore down, or Studio without API access) they still
  get it for this server session (and can equip it) until they leave the
  server, and the message says it couldn't be saved.
- Each trophy is a small statue of Caleb on a plinth with a gold
  "CALEB TROPHY" nameplate showing the variant's name in its rarity color;
  the band around the top of the plinth is the rarity color too (gray,
  green, blue, purple, gold, pink), and Mythic trophies give off a soft
  glow.
- The **Trophy Case** (a house build, see Building) shows the owner's
  **equipped** trophies (up to 5, in equip order). A new trophy is equipped
  automatically when one of the 5 slots is free; otherwise it is kept
  (saved) and the player can swap it in (equip / unequip). Only trophies
  displayed in a built case give their power. The case appears when built,
  when the saved house is restored on claim, and updates right after a new
  trophy or an equip change; it empties when the plot is released.
- Edge cases: leaving during the Celebration and rejoining (same server)
  during the claim keeps your contribution, so you can still claim. Joining
  after the goal: not eligible. Next round: new event id, so you can earn
  another (different) trophy. Server shutdown: trophies were already saved
  right after the claim (and again on close).

### Trophy powers

- A Caleb Trophy's power only works while it is **displayed in your built
  Trophy Case** (equipped, up to 5).
- **Duplicates stack**: every displayed trophy counts, so 2 Speed Calebs give
  +150% walk speed and 5 give +375% (requested by the user 2026-10-02).
- Powers of the same kind **add up with no cap**: more cookies per drop,
  faster droppers, a chance for an extra cookie, a chance for a gold **lucky
  cookie** worth 5×, a bonus when you collect at the Collect pad, faster
  walking, higher jumps, and a **double jump** (jump again once in the air;
  more than one Rocket Caleb still gives one air jump). The only limit: a
  chance can't go past 100%.
- With 5 of the strongest trophy for one power: 5 Golden = 6× cookies,
  5 Neon = 2.5× drop rate, 5 Clone = 75% extra cookie chance, 5 Diamond = 50%
  lucky chance, 5 Cookie King = +75% collect, 5 Speed = 4.75× walk speed,
  5 Jump = 3.5× jump height.
- Cookie powers work on **your own plot** (the owner's trophies), for every
  dropper, and change from the next cookie when you equip or unequip.
- Walk speed and jump height stay after you respawn. Each player's powers are
  their own.
- **Power-up looks** (requested by the user 2026-10-02): your movement
  powers show on your body. Everyone can see them (players who join later
  too). They go away when the power is gone (unequip, case not built, plot
  released), come back after you respawn, and get stronger with bigger
  bonuses up to a "full" look (the power itself keeps growing):
  - **Super speed** (any walk speed bonus): each foot **glows** light blue
    with bright sparkles and crackling electric sparks. While you **run
    fast** (faster than normal walking) a glowing **cyan → electric blue
    trail** streams behind you from your waist to your knees and fades out;
    a few **speed lines** whoosh out behind you when you start sprinting. The
    trail stops when you stop or slow down, and it is short enough never to
    reach your own camera. Full look at +150%.
  - **Jump boost** (any jump height bonus): every jump makes a **springy
    mint-green double ring** on the ground and a burst of sparkles at your
    feet; while you are in the air your feet leave soft glowing sparkles.
    Bigger rings and more sparkles for bigger bonuses (full at +100%).
  - **Double jump** (Rocket Caleb): the air jump fires a **ring of orange
    light and a puff** right under you, in mid-air.
- **Active trophy powers show on what they boost** (everyone sees it, only
  while the trophy is displayed): more cookies or faster droppers → every
  dropper cup **burns** (bigger flames for a bigger bonus, full size at +100%;
  both kinds at once → sparks too); extra/lucky cookie chance → a few green
  and gold luck sparkles off each cup; Collect bonus → the Collect pad gets a
  **golden glow ring** with gold shine. Droppers bought later burn too; it all
  goes away when the power does (unequip, case not built, plot released,
  leave).

### New trophy pop-up

- Right after a claim, a big **"🏆 NEW TROPHY!"** pop-up opens in the middle
  of the screen (pop + confetti + a shine in the rarity color): the trophy's
  icon, name, **⭐ RARITY**, its **power** in big text, and its description.
  It says "Build your Trophy Case to use powers" (no case), "Equip it in your
  Trophy Case to get this power" (not equipped), or "Its power is on!", and
  "couldn't be saved this session" when saving is off.
- **EQUIP** equips that trophy (the server checks; if all 5 slots are full its
  reason shows). A trophy that was auto-equipped shows **EQUIPPED ✓**
  instead. **CLOSE** closes it; it also closes by itself after
  `Config.TrophyPopupSeconds` and when a newer pop-up opens.
- "Already have this round's trophy" and "only players who fed Caleb" stay
  small notifications.

### My Caleb Trophies (inventory screen)

- A yellow **"🏆 TROPHIES"** button on the left side of the screen opens
  (and closes) the **"MY CALEB TROPHIES"** panel; it also has an X button.
- The top shows **"🏆 COLLECTION N / M"** (different trophies owned / how
  many can be collected) and **"ACTIVE TROPHIES: n / 5"**.
- Every trophy the player owns is a tile in a scrolling grid (works with
  100+): its icon, rarity (in the rarity's color, also the tile's border),
  name, and an **EQUIPPED** badge. Equipped ones come first, then the
  rarest, then the newest. No trophies yet: "No trophies yet! Feed Caleb to
  earn one 🏆".
- Tapping a tile shows its details: name, **⭐ RARITY**, its power in big
  text (e.g. "2x COOKIE PRODUCTION"), and its description in quotes, with
  **EQUIP** / **UNEQUIP**. When 5 are already equipped, the button is grey
  "Case full (5/5)": unequip one first. If the server says no, its reason is
  shown under the description.
- Equipped trophies are the ones shown in the Trophy Case, and only they give
  powers. Without a built Trophy Case the panel says **"Build your Trophy
  Case at home to activate trophy powers!"**; you can still equip, and the
  powers start once the case is built.
- The bottom line lists the powers active right now, e.g. "Active powers:
  +125% cookies, +20% speed" (or "none"). "Saving is off this session"
  shows when the player's trophies aren't being saved.

### Caleb Full Event: what players see on screen

- **Full** (5 s): a huge **"🍪 CALEB IS FULLLL!!! 🍪"** slams onto the
  middle of the screen (big and tilted, then snaps into place and wobbles),
  with a quick white flash, a small camera shake, and a burst of confetti.
- **Celebration**: a pink **"🎉 COOKIE PARTY! 🎉"** banner at the top with
  the time left (m:ss). The world gets a little warmer and glowier
  (light color tint + bloom), fading back to normal when the party ends.
- **Cookie Party show** (the 60 s Celebration) gets crazier as it goes:
  60–40 the party starts with an air horn, the background music fades out
  and the party music begins; 40–20 **"MORE
  COOKIES!"** slams onto the screen, the light pulse speeds up and the banner turns
  orange; 20–10 **"GOLDEN COOKIE FRENZY!"**, gold banner that shakes a
  little, stronger glow and more confetti; the **last 10 seconds** are a huge
  **10… 9… 8… … 3… 2… 1…** countdown in the middle of the screen, a tick
  each second (higher each time) and a small camera punch (3-2-1 red and
  bigger, with glowing screen edges). Lighting pulses gently with the music
  (never fast flashing).
- **Finale** (party hits 0): a massive cookie explosion out of Caleb (cookies
  fly everywhere, bounce and vanish), a big boom, white flash, strong camera
  shake and confetti; everyone gets the party bonus. A short **"YOU
  COLLECTED 🍪 12,450"** celebration pops up in the middle of the screen:
  the number counts up fast with ticks, lands with a bump, a shine and a
  little confetti, "37 cookies grabbed" under it (or "🍪 0 — Next time grab
  some cookies!"), then **"+5,000 PARTY BONUS!"** slams in and it all flies
  down to the cookie counter, gone in about 3.5 seconds. It only shows your
  own total (no leaderboard, no buttons), never covers the trophy banner,
  then straight into the trophy claim. Players who join during the trophy
  claim don't see the explosion or the total.
- **Trophy claim**: if you fed Caleb this round and haven't claimed yet, a
  gold banner: **"🏆 CALEB TROPHY AVAILABLE!"**, "You helped feed Caleb!",
  "Claim your trophy on Caleb's podium before time runs out!",
  **"TROPHY CLAIM: 1:52"**. After you claim: a small **"Trophy claimed!
  🏆"**. If you didn't feed this round: a small **"CALEB IS RESTING — new
  round soon"** with the countdown. When it ends: **"TROPHY CLAIM CLOSED"**
  for a few seconds.
- **Normal**: no big messages; just the progress bar above Caleb.
- Joining in the middle of the event shows the current part right away
  (without the flash and shake).

### Cookie rain (Caleb Full Event)

- While Caleb's state is **Celebration**, chocolate chip cookies rain from
  the sky within `Config.CookieRainRadius` studs of the statue (the whole
  map), with more of them (`CookieRainNearPlayerShare`) landing near each
  player so everyone sees plenty around them. They look like the dropper
  cookies (golden-brown disc, dark chips), spin and wobble as they fall, then
  hop, puff a little crumb dust, and fade where they land (ground, roofs,
  pads).
- It starts when the Celebration starts (or right away for a player who
  joins during it) and stops when it ends: no new cookies, the falling ones
  land and fade, then nothing is left.
- **Visual only**: each player's own client draws its own rain, so players
  see different cookies, and they cannot be picked up and give nothing.
  Making them collectable would need a server-authoritative design (the
  server spawning/tracking the cookies and validating every pickup) and the
  user's approval.
- During the Cookie Party it gets heavier each phase and some rain cookies
  look golden (`CookiePartyRainRate`, `CookiePartyRainMaxCookies`,
  `CookiePartyRainGoldenShare`); they are still only visual.
- Tunable in Config: `CookieRainMaxCookies` (most falling at once per
  player), `CookieRainRadius`, `CookieRainPerSecond`, `CookieRainFallSpeed`,
  `CookieRainHeight`, `CookieRainSpinSpeed`, `CookieRainNearPlayerShare`,
  `CookieRainNearPlayerRadius`.
  studs above the top of his head and follows the head as he grows.

While Caleb is not eating (Full, Celebration, TrophyClaim) the four feed pads
turn gray (`Config.StatueFeedPadOff*Color`) with "CALEB IS FULL!", and the feed
pop-up does not open; they go back to orange on reset. The podium's gold trim,
the leaderboard frames, and Caleb's chain are plain gold (not Neon) so they
don't glare, and the party bloom is soft (`Config.CalebPartyBloom` 0.12).

### Cookie Party: collectable cookies and rewards

- During the 60-second party (Celebration) the server drops collectable
  cookies around the statue and near players: **Normal**, **Chocolate**,
  **Golden**, **Giant**. Their values, how often each appears in each phase,
  how many fall per second, and how close you must be are all in Config
  (`CookiePartyTypes`, `CookiePartySpawnPerSecond`, …); more valuable ones
  show up as the party gets crazier, and more fall with more players.
- Walk into a landed cookie to collect it; the first player to reach it gets
  its value in cookies. Uncollected cookies vanish after
  `CookiePartyLifetime` seconds.
- When the party ends, every player in the server gets
  `CookiePartyFinalReward` cookies (once), then the trophy claim starts.
- Party cookies only appear during the party, and the server checks every
  pickup (distance, timing, rate), so they cannot be faked.

### Cookie Party: collectable cookies

During the 60-second Cookie Party the server drops **collectable cookies**
around the map (and Caleb throws some out of his mouth). Run into them to
collect them; the server decides who gets each one and pays it straight into
your cookies.

- **Normal** (golden-brown, dark chips) and **Chocolate** (dark, white chips)
  are the common ones; **Golden** (glowing gold, sparkles, light pillar) and
  **Giant** (huge, bouncy, pink pillar) are rarer and worth much more. They
  get more common as the party goes on (`Config.CookiePartyTypes`).
- A glowing disc on the ground shows where each cookie will land. Landed
  cookies bob and spin; they blink just before they disappear.
- Collecting one: it pops into you with a sparkle + confetti burst, a
  floating "+50" (bigger "GOLDEN!" / "GIANT!!" for the special ones) and a
  sound. Grabbing several in quick succession shows "x5 COMBO!" and raises
  the sound's pitch (just for fun, no extra reward).
- A small counter at the right side shows what you earned this party:
  "🍪 +12,450". It just disappears when the party ends (no summary screen).
- If someone else grabs a cookie first, it vanishes with a little puff.
- The visual (non-collectable) cookie rain gets heavier with each phase and
  more of it looks golden toward the end.

### Caleb's animations (Caleb Full Event)

Client-side only, driven by the statue's `CalebState`; everyone sees the
same moment (timed from `CalebStateEndsAt`), including late joiners.

- **Full** ("I'm completely full", `CalebEvent.Duration("Full")` s): he
  waddles side to side (dying down), leans back with his arms out and his
  belly bouncing, then puffs out a white cloud from his mouth (a burp) and
  his head jolts back, and settles. Numbers: `Config.CalebFullAnim`.
- **Celebration** (the Cookie Party): Caleb is the center of the party. A
  dance loop (sways to a side and hops on every beat, arms take turns
  waving up with a wiggle, head bobs, belly jiggles; `Config.CalebDance`)
  gets faster and bigger every phase (`CookiePartyDanceEnergy`, blended
  smoothly), with funny moves mixed in (`Config.CookiePartyCaleb`):
  **throw** (an arm winds up and flings), **laugh** (head shaking, belly jiggling, bouncing), **spin**, **jump**,
  **belly drum**. Start: he opens with a laugh and celebrates; Hype: more
  energetic, more moves; Frenzy: goes crazy (back-to-back moves, double
  spins, a wobble on top); Countdown: bounces faster and faster and his
  belly swells, then in the last 2.5 s the **"I'M FULL!" wind-up** (crouch,
  arms hugging his belly, trembling, belly puffing) that pops (arms flung
  wide, head back, belly pop) exactly when the party ends, right into the
  finale explosion. Every player sees the same move at the same moment
  (timed from server time; the moves are picked from the cycle id).
  Speech bubbles above the progress bar pop in and out with short lines
  per phase (`Config.CookiePartyCalebLines`: "COOKIE PARTYYY!", "CATCH!",
  "I CAN'T STOP!!", "TOO... MANY... COOKIES..."), faster and shakier
  later, and "I'M FULL!!!" for the last second. Optional laugh sound
  (`CookiePartySounds.CalebLaugh`). Looks only. (He used to spit crumbs
  too; the user had that removed 2026-10-02.)
- **TrophyClaim**: Caleb's body is hidden (the pedestal, feed pads, and
  podium stay). After the reset he is back, small, in his normal pose.
- Only Caleb's body moves; the pedestal, feed pads, and podium never do.

### Podium: "CALEB'S TOP FEEDERS"

- Four leaderboard boards stand on the grass at the pedestal's four
  **corners**, each facing outward along a diagonal (21 studs from the
  statue's center), so one is readable from any direction and none is near
  a feed pad (those are on the sides). Each board is cookie-themed: a gold
  neon trim frame, two chocolate posts, and a big chocolate chip cookie on
  top. They stay clear of Caleb even at his biggest
  (`Config.CalebMaxScale`). Generated in the statue's `Podium` folder
  (`Leaderboard<corner>` models) by `tools/statue/generate_statue.py`.
- Each board shows **"CALEB'S TOP FEEDERS"**, then up to
  `Config.CalebLeaderboardSize` rows like "1  Justin   248,321 🍪" (best
  first, commas), and the shared total "🍪 N / goal" at the bottom.
  The top 3 have gold / silver / bronze rank badges; **your own row** is
  green with a thick green outline. Empty list: "Be the first to feed
  Caleb!". Long names end in "…" instead of overflowing.
- It counts cookies **fed to Caleb** this round (tracked by the server), not
  cookies produced. During the trophy claim it says **"FINAL RESULTS"** above
  the list (the server keeps the list until the reset, which clears it).
- Same look as the rest of the game (yellow rounded panel, thick dark
  outline, FredokaOne, not affected by lighting), readable from ~40 studs.
  Display only (`CalebLeaderboard.client.luau` reads the statue's
  `CalebTopFeeders` attribute). Names are plain text, never markup.

### Caleb Full Event sounds

Original, cartoony sound effects (synthesized by `tools/audio/generate_sfx.py`,
no copyrighted audio). Each player hears them on their own client. The
music is the user's own picks (see "Music" below).

- Caleb is fed: a short, quiet rising "bloop" (at most about 3 per second, however many feeds).
- Caleb is full: a big "boing" + burp + fanfare hit.
- Celebration starts: the "Air Horn" (`Config.CookiePartyStartSound`), then
  a soft sparkle/patter loop plays quietly for the whole Celebration (it
  fades out when the Celebration ends).
- Celebration ends: a gentle descending chime.
- You claim your trophy: a bright "ta-da" (only you hear yours).
- Joining mid-event plays no old sounds; mid-Celebration you just hear the loop.
- A sound whose id in `Config.CalebSounds` is empty is silent. Volumes are
  `Config.CalebSoundVolumes`.

### Music (approved by the user 2026-10-02)

The user's own Roblox audio; the ids go in the MUSIC block at the top of
`Config.luau` (empty = silent).

- **"Tender Static"** (`BackgroundMusic`) loops quietly the whole game,
  starting when you join.
- When the Cookie Party starts the background fades out
  (`MusicFadeSeconds`) and pauses, the **"Air Horn"**
  (`CookiePartyStartSound`) blasts once, and **"NO PARTY"**
  (`CookiePartyMusic`) loops for the 60 s party (normal speed, a little
  louder toward the end). Only one music track plays at a time.
- When the party ends the party music stops (the finale boom still plays)
  and the background fades back in, continuing where it left off.
- Joining mid-party: you hear the party music (no air horn), then the
  background after the party.

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
Cookie jar counter: a runtime `JarCounter` part (7 × 1.8 × 0.6, pink
`255,90,160` frame) directly on top of the `TankSign` (y 14.3..16.1 on
Plot1, front face z −46.4, 0.2 in front of the sign's; below the 2nd floor
at y 17), with a `SurfaceGui` `CounterGui` on the
pad-facing face (`PixelsPerStud` 50, `LightInfluence = 0`, `MaxDistance`
120) → gold (`255,200,40`) `Panel` (94% × 82%) with `UICorner` (0.35), a
6 px dark `UIStroke`, and a `UIScale` for the pop → white `FredokaOne`
`TextLabel` `Amount` ("🍪 1,250", 86% × 72%, `TextScaled`) with a 3.5 px dark
Contextual `UIStroke`. Built by `JarCounter.luau`; no map edits.
Label panels: Claim `0,162,255` "CLAIM TYCOON!"; Buy `255,60,60` "Dropper N" +
yellow (`#FFE14D`) price; Collect `0,200,80` "COLLECT!".
