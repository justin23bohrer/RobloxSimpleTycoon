# SimpleTycoon

A tiny Roblox tycoon, built as a clean starting point:

> join → get $100 → get a plot → buy a dropper → drops ride a conveyor →
> collect the cash

The full design is in [GAME_DESIGN.md](GAME_DESIGN.md). **Current status:** cash, plots,
ownership, the map, and buying the dropper are built. The dropper itself,
drops, and collection are stubs; see [TODO.md](TODO.md).

## How the project works

The game's code and map live as plain text files in `src/`. **Rojo** turns
those files into Roblox objects and syncs them into **Roblox Studio** live.
You (or an AI agent) edit files here, and Studio updates automatically.

- `src/` → the game (Luau scripts and `.model.json` map parts)
- `default.project.json` → tells Rojo which folder goes into which Roblox service
- Docs: [ARCHITECTURE.md](ARCHITECTURE.md), [GAME_DESIGN.md](GAME_DESIGN.md),
  [QA.md](QA.md), [TODO.md](TODO.md), [AGENTS.md](AGENTS.md)

Edits made only inside Studio are **not** saved back to these files and will
be overwritten. Always change the files.

## One-time setup

1. **Roblox Studio** — install from <https://create.roblox.com>.
2. **Rojo** (command-line tool) — already installed on this Mac via Homebrew
   (`rojo --version` → 7.7.0). On another machine: `brew install rojo`, or see
   <https://rojo.space/docs>.
3. **Rojo Studio plugin** — with Studio closed, run:
   ```bash
   rojo plugin install
   ```
   Then open Studio; a **Rojo** button appears in the **Plugins** tab.
   (Alternatively install "Rojo" from the Creator Store. Keep the plugin and
   CLI on the same major version, 7.x.)

## Connect the project to Roblox Studio

From this folder:

```bash
# 1. Build a place file from the source (creates build/SimpleTycoon.rbxlx)
mkdir -p build && rojo build default.project.json --output build/SimpleTycoon.rbxlx

# 2. Start the live-sync server (leave this terminal running)
rojo serve
```

3. In Studio: **File → Open from File…** → `build/SimpleTycoon.rbxlx`.
4. **Plugins → Rojo → Connect** (default `localhost:34872`).
5. Press **Play** to test. Cash appears in the player list at the top right.

When you change a file, Rojo updates Studio within a second. Stop Play mode
first; changes don't apply to a running test. `build/` is ignored by Git, so
you can rebuild it anytime.

> `Place1.rbxl` is the original place file. It has its own Baseplate and
> SpawnLocation, so syncing into it would give you two spawns. Use the built
> place above instead.

## Using OpenCode

```bash
cd /Users/justinbohrer/agent-office/justin23bohrer/RobloxSimpleTycoon
opencode
```

OpenCode reads `AGENTS.md` automatically. Give it one small task at a time,
e.g. "Implement the dropper purchase from TODO.md".

## Development workflow

1. Pick one task from the **MVP** list in `TODO.md`.
2. Create a branch: `git switch -c feature/<short-name>`.
3. Run `rojo serve`, connect Studio, and make the change in `src/`.
4. Test in Studio with the matching cases in `QA.md` (use
   **Test → Clients and Servers** with 2 players for multiplayer).
5. Update the docs if behavior changed.
6. Commit, merge to `main`, push.

## Git basics

```bash
git status                       # what changed?
git switch -c feature/my-task    # new branch for a feature
git add -A && git commit -m "Describe the change"
git switch main && git merge feature/my-task
git push                         # upload to GitHub
```

The repo is connected to GitHub at
`https://github.com/justin23bohrer/RobloxSimpleTycoon`. `.gitignore` keeps
build outputs, Studio lock files, and secrets out of Git.
