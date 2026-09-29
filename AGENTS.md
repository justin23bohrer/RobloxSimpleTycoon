# SimpleTycoon Agent Instructions

Read this whole file before changing anything.

## What this project is

- A small **Roblox** game written in **Luau**.
- Source lives in `src/` and is synced into **Roblox Studio** with **Rojo**
  (`default.project.json` defines the mapping).
- The files in this repository are the source of truth, not a place file.
  Anything edited only inside Studio will be lost the next time Rojo syncs.
- Git + GitHub hold the history. OpenCode and other AI agents edit the files.

## Before you change anything

1. Read `AGENTS.md` (this file).
2. Read `ARCHITECTURE.md` before touching services, remotes, the data model,
   or the Rojo mapping.
3. Read `GAME_DESIGN.md` to know what the game is supposed to do.
4. Check `TODO.md` for the current task list and `QA.md` for test cases.
5. Run `git status`. If there are changes you did not make, another agent or
   the user may be working. Do not overwrite, revert, or reformat their work.
   Ask if unsure.

## Rules

- **Server authority.** The server owns cash, plot ownership, purchases,
  dropper production, drop values, and collection rewards. The client only
  does UI, visual feedback, input, and presentation.
- **Never trust the client.** Treat every remote argument and every client
  claim as untrusted. Validate ownership, currency, purchases, and collection
  on the server.
- **Only EconomyService changes cash.** Only TycoonService changes plot
  ownership.
- **No features without approval.** Implement only what `GAME_DESIGN.md` and
  the current `TODO.md` MVP list describe. Do not add monetization,
  gamepasses, developer products, pets, rebirths, NPCs, quests, inventory,
  trading, combat, themes, custom art, complex UI, DataStore persistence,
  frameworks, or dependencies unless the user approves it.
- **Stay in your lane.** Do not modify another system unless your task needs
  it. If it does, say so in your summary.
- **Keep modules focused.** One service per responsibility. Avoid giant
  scripts; if a file grows past roughly 200 lines, consider splitting it.
- **Tunable numbers go in `src/ReplicatedStorage/Shared/Config.luau`**, not
  hard-coded in services.
- **Do not edit `*.rbxl` / `*.rbxlx` files** unless the user explicitly asks.
- **Update docs** (`ARCHITECTURE.md`, `GAME_DESIGN.md`, `TODO.md`, `QA.md`,
  `README.md`) in the same change when behavior or architecture changes.
- **Keep changes small and testable.**

## Git

- Use a branch for significant feature work, e.g. `git switch -c feature/dropper-purchase`.
- Commit only coherent, working changes with a clear message.
- Never commit secrets, `.env` files, or Studio temp/lock files.
- Do not change the GitHub remote or force-push without asking the user.

## Testing

- At minimum: `mkdir -p build && rojo build default.project.json --output build/SimpleTycoon.rbxlx`
  must succeed, and your Luau must have no syntax errors.
- Gameplay must be tested in Roblox Studio (Play, and Test > Clients and
  Servers with 2 players for multiplayer cases). Use the cases in `QA.md`.
- If you could not run Studio, say so. Never claim runtime testing you did
  not perform.

## When you finish

Report:

1. What you changed (files and why).
2. How you tested it, and what you could not test.
3. Any docs you updated.
4. Anything left unfinished or any risk you noticed.

## Project commands

```bash
rojo serve                                                     # live sync to Studio
mkdir -p build && rojo build default.project.json --output build/SimpleTycoon.rbxlx   # build a place file
```
