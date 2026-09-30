# SimpleTycoon Game Design (MVP)

This is the complete scope of the MVP. Anything not listed here is out of
scope until the user approves it (see `TODO.md`).

## Core loop

Player joins → receives $100 → is given a plot → buys the dropper for $100 →
the dropper makes $10 drops every 2 seconds → drops ride a conveyor to the
collector → player steps on the Collect pad → cash increases.

## Player

- Starts each session with **$100** (`Config.StartingCash`).
- Cash is shown in the Roblox player list (`leaderstats`).
- No saving between sessions yet.

## Tycoon

- There is **1** plot (`Config.NumberOfTycoonPlots`), directly in front of
  the spawn. We build one tycoon at a time.
- The first player to join is automatically given the plot.
- That player owns the plot. Other players cannot use it. Anyone who joins
  while it is taken gets no plot (the server logs a warning).
- The plot's sign shows the owner's name, or "Unclaimed".
- When the player leaves, the plot is released and reset for the next player.

## Purchase

- The dropper costs **$100** (`Config.DropperCost`).
- The owner buys it by stepping on their plot's red **Buy Dropper** button.
- The player must have enough cash.
- The purchase is decided on the server.
- The dropper can only be bought once per plot.

## Dropper

- Produces one physical **$10** object (`Config.DropValue`) every
  **2 seconds** (`Config.DropInterval`).
- Objects travel along the plot's conveyor.

## Collector

- Objects that reach the plot's collector add their value to that plot's
  stored cash.
- The owning player collects the stored cash by stepping on the green
  **Collect** pad.
- Other players cannot collect it.

## Plot layout (prototype)

Plain parts only, no theme. The spots players step on are flat round pads
with a darker ring underneath as an outline:

| Part               | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `Base`             | Plot floor, in front of the spawn.                   |
| `OwnerSign`        | Shows the owner's name.                              |
| `BuyDropperButton` | Round red pad with a dark red ring. Buys the dropper. |
| `DropperSpot`      | Transparent yellow block where the dropper goes.     |
| `Conveyor`         | Dark strip that carries drops.                       |
| `Collector`        | Green block at the end of the conveyor.              |
| `CollectPad`       | Round green pad with a dark green ring. Pays the owner their stored cash. |
| `SpawnLocation`    | Round blue pad with a dark blue ring, in `Map` (not the plot). Where players appear. |

### Pad style (copy this for new pads)

| Piece | Setting |
| ----- | ------- |
| Pad (the part players touch) | `Part`, `Shape = Cylinder`, CFrame rotated 90° around Z (orientation `[[0,-1,0],[1,0,0],[0,0,1]]`) so the round face points up. Plot pads: `Size = [0.4, 6, 6]` (height, diameter, diameter), bottom resting on `Base` (Y = 2.2). SmoothPlastic, bold color. |
| Ring (outline) | A child of the pad named `<PadName>Ring`. Same shape and rotation, half the pad's height, 1.5 studs wider (plot pads: `Size = [0.2, 7.5, 7.5]`, Y = 2.1), darker shade of the pad color. `Anchored`, `CanTouch = false`, `CanQuery = false`. |
| Label | `BillboardGui` named `Label` on the pad, `StudsOffset = [0, 3, 0]`, white `TextScaled` text with a black stroke. |

Buy button colors: pad `255,0,0` (TycoonService resets the button to this
exact red), ring `110,0,0`. Collect pad: `0,220,70` / ring `0,95,35`.
Spawn (14 studs wide): `70,160,255` / ring `20,60,150`.
