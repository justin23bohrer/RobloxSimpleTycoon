# SimpleTycoon Architecture

## Current State

The project is an empty Rojo scaffold. Gameplay has not been implemented yet.

## Service Layout

- `src/ServerScriptService`: server-only game systems and startup scripts.
- `src/ReplicatedStorage`: shared modules and remotes that must be visible to both server and client.
- `src/StarterPlayer/StarterPlayerScripts`: client input and presentation code.
- `src/StarterGui`: client UI.

## Planned MVP

1. Give each player `$100` on join.
2. Create identical plots and assign one plot per player.
3. Allow the plot owner to purchase one `$100` dropper.
4. Spawn `$10` drops every two seconds.
5. Move drops along a visible conveyor.
6. Store generated cash at the owner's collector.
7. Allow only the plot owner to collect that cash.

All economy mutations and plot ownership checks belong on the server.
