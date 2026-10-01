# SimpleTycoon Game Design (MVP)

This is the complete scope of the MVP. Anything not listed here is out of
scope until the user approves it (see `TODO.md`).

## Core loop

Player joins → receives $100 → steps on the blue **Claim Tycoon** pad →
their collect area and a FREE Dropper 1 button appear → buys Dropper 1 →
it makes $10 drops every 2 seconds → drops ride a conveyor to the
collector → player steps on the Collect pad → cash increases → the next,
more expensive dropper's button has appeared, so they save up for it.

## Player

- Starts each session with **$100** (`Config.StartingCash`).
- Cash is shown in the Roblox player list (`leaderstats`) and in a cartoony
  panel at the bottom-center of the screen (e.g. "$1,250") that bounces when
  the amount changes.
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
  | Claimed | Owner sign ("<name>'s Tycoon"), conveyor, collector, Collect pad with its cash tank, and the **Dropper 1 / FREE!** button with its yellow spot. | The Claim pad. |
  | Dropper N bought | The dropper at its spot, and the next dropper's button and yellow spot. | Button N and its yellow spot. |
  | Dropper 4 bought | Nothing new (all droppers bought). | Button 4. |

- When the player leaves, the plot is released and reset: everything hides
  again and the Claim pad comes back for the next player.

## Purchase

There are four droppers (`Config.Droppers`), each with its own buy button:

| Dropper   | Cost   | Value per drop |
| --------- | ------ | -------------- |
| Dropper 1 | FREE   | $10            |
| Dropper 2 | $300   | $25            |
| Dropper 3 | $1000  | $60            |
| Dropper 4 | $3000  | $150           |

- The owner buys a dropper by stepping on its red button. The label shows the
  name with the price under it in yellow, e.g. "Dropper 2 / $300", or
  "Dropper 1 / FREE!" (text comes
  from `Config`; a `Cost` of 0 is free).
- Droppers unlock **in order**: only the next dropper's button is shown, and
  the server refuses to sell a dropper before the one before it is bought.
- The player must have enough cash (the free dropper needs none).
- The purchase is decided on the server.
- Each dropper can only be bought once per plot. A bought button disappears
  (pad, ring, label, and its yellow spot). All buttons are hidden again when
  the plot is released.

## Droppers

- Each bought dropper produces one physical object worth its value every
  **2 seconds** (`Config.DropInterval`, shared by all droppers).
- Objects travel along the plot's one conveyor to the one collector.

## Testing: unlimited cash (Studio only)

- `Config.DevUnlimitedCash = true` makes players start with
  `Config.DevStartingCash` ($1,000,000,000) instead of $100, **only** in
  Roblox Studio. It never applies in a published game. Buying still spends
  cash normally. Must be `false` in commits.

## Collector

- Objects that reach the plot's collector add their value to that plot's
  stored cash.
- The owning player collects the stored cash by stepping on the green
  **Collect** pad (label "COLLECT!").
- Other players cannot collect it.

### Cash tank (collect area look)

The stored amount is **not** shown as text. Instead:

- Behind the Collect pad is a purple wall with a gold frame, a pink
  "CASH TANK" sign, and a glass tank on an orange stand.
- Each drop that reaches the collector drops one gold cube into the tank, so
  the tank fills up as cash waits (it stops adding cubes at 60, when it looks
  full; the cash itself keeps adding up).
- While cash is waiting, the pad sparkles gold and glows.
- A gold arrow always bounces above the pad.
- Collecting empties the tank with a burst of gold sparkles.
- All of this is looks only; the server's stored cash decides the payout.

## Plot layout (prototype)

Plain parts only, no theme. The spots players step on are flat round pads
with a darker ring underneath as an outline:

| Part               | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `Base`             | Plot floor, in front of the spawn. Always visible.   |
| `ClaimPad`         | Round blue pad with a dark blue ring at the front of the plot, label "CLAIM TYCOON!". Shown only while the plot is unclaimed. |
| `OwnerSign`        | Shows the owner's name.                              |
| `BuyButton1`–`4`   | Round red pads with dark red rings, in a row beside the conveyor. Buy droppers 1–4. |
| `DropperSpot1`–`4` | Transparent yellow blocks above the conveyor where each dropper goes. |
| `Conveyor`         | Dark strip that carries drops.                       |
| `Collector`        | Green block at the end of the conveyor.              |
| `CollectPad`       | Round green pad with a dark green ring. Pays the owner their stored cash. |
| `CashTank`         | Model behind the Collect pad: `TankWallBorder`, `TankWall`, `TankSign`, `TankStand`, glass `TankLeft`/`TankRight`/`TankFront`/`TankLid`. Cubes go in a `TankCubes` folder made at runtime. |
| `SpawnLocation`    | Round blue pad with a dark blue ring, in `Map` (not the plot). Where players appear. |

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
Label panels: Claim `0,162,255` "CLAIM TYCOON!"; Buy `255,60,60` "Dropper N" +
yellow (`#FFE14D`) price; Collect `0,200,80` "COLLECT!".
