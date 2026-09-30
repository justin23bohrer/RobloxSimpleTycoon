# SimpleTycoon Game Design (MVP)

This is the complete scope of the MVP. Anything not listed here is out of
scope until the user approves it (see `TODO.md`).

## Core loop

Player joins → receives $100 → is given a plot → buys Dropper 1 for $100 →
it makes $10 drops every 2 seconds → drops ride a conveyor to the
collector → player steps on the Collect pad → cash increases → saves up for
the next, more expensive dropper.

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

There are four droppers (`Config.Droppers`), each with its own buy button:

| Dropper   | Cost   | Value per drop |
| --------- | ------ | -------------- |
| Dropper 1 | $100   | $10            |
| Dropper 2 | $300   | $25            |
| Dropper 3 | $1000  | $60            |
| Dropper 4 | $3000  | $150           |

- The owner buys a dropper by stepping on its red button. The label shows the
  name and price, e.g. "Dropper 2 - $300" (text comes from `Config`).
- Droppers can be bought in any order.
- The player must have enough cash.
- The purchase is decided on the server.
- Each dropper can only be bought once per plot. A bought button turns gray
  and says "Purchased". All buttons reset when the plot is released.

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
  **Collect** pad.
- Other players cannot collect it.

## Plot layout (prototype)

Plain parts only, no theme. The spots players step on are flat round pads
with a darker ring underneath as an outline:

| Part               | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `Base`             | Plot floor, in front of the spawn.                   |
| `OwnerSign`        | Shows the owner's name.                              |
| `BuyButton1`–`4`   | Round red pads with dark red rings, in a row beside the conveyor. Buy droppers 1–4. |
| `DropperSpot1`–`4` | Transparent yellow blocks above the conveyor where each dropper goes. |
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

Buy button colors: pad `255,0,0` (BuyButtons.luau resets the buttons to this
exact red), ring `110,0,0`. Collect pad: `0,220,70` / ring `0,95,35`.
Spawn (14 studs wide): `70,160,255` / ring `20,60,150`.
