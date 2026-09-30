# SimpleTycoon Game Design (MVP)

This is the complete scope of the MVP. Anything not listed here is out of
scope until the user approves it (see `TODO.md`).

## Core loop

Player joins → receives $100 → is given a plot → buys the dropper for $100 →
the dropper makes $10 drops every 2 seconds → drops ride a conveyor to the
collector → player steps on the Collect pad → cash increases.

## Player

- Starts each session with **$100** (`Config.StartingCash`).
- Cash is shown in the Roblox player list (`leaderstats`) and in a cartoony
  panel at the bottom-center of the screen (e.g. "$1,250") that bounces when
  the amount changes.
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

Plain parts only, no theme:

| Part               | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `Base`             | Plot floor, in front of the spawn.                   |
| `OwnerSign`        | Shows the owner's name.                              |
| `BuyDropperButton` | Red pad. Buys the dropper.                           |
| `DropperSpot`      | Transparent yellow block where the dropper goes.     |
| `Conveyor`         | Dark strip that carries drops.                       |
| `Collector`        | Green block at the end of the conveyor.              |
| `CollectPad`       | Bright green pad. Pays the owner their stored cash.  |
