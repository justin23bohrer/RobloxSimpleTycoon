# SimpleTycoon Architecture

Small on purpose. Plain ModuleScripts, one server entry script, no frameworks.

## Project structure

```
src/
├── ReplicatedStorage/          → ReplicatedStorage (server + client can read)
│   ├── Shared/
│   │   └── Config.luau         → ModuleScript: all tunable numbers
│   └── Remotes/                → Folder: RemoteEvents (none needed yet)
├── ServerScriptService/        → ServerScriptService (server only)
│   ├── ServerMain.server.luau  → Script: entry point, starts services
│   └── Services/
│       ├── PlayerDataService.luau
│       ├── EconomyService.luau
│       ├── TycoonService.luau
│       ├── BuyButtons.luau     → helper for TycoonService (buy button labels/touches)
│       ├── DropperService.luau
│       └── CollectorService.luau
├── StarterPlayer/
│   └── StarterPlayerScripts/   → client LocalScripts (none yet)
├── StarterGui/                 → client UI (none yet)
└── Workspace/
    └── Map/                    → Folder in Workspace
        ├── Ground.model.json
        ├── SpawnLocation.model.json
        └── Plots/
            └── Plot1.model.json      → the one tycoon plot
```

Rojo file naming (important):

| File                 | Becomes in Studio |
| -------------------- | ----------------- |
| `Name.server.luau`   | `Script` (runs on the server) |
| `Name.client.luau`   | `LocalScript` (runs on the client) |
| `Name.luau`          | `ModuleScript` (runs only when required) |
| `Name.model.json`    | Any instance(s) described in JSON |
| folder               | `Folder` |
| `README.md`          | Ignored by Rojo (documentation only) |

`default.project.json` maps each `src/<Service>` folder to that Roblox service.
`Workspace` has `$ignoreUnknownInstances: true` so Rojo does not delete Studio's
own `Camera`/`Terrain`. Every other mapped folder is fully managed by Rojo:
instances added there only in Studio will be removed on sync.

## Server / client responsibilities

| Server owns (authoritative)          | Client may do              |
| ------------------------------------ | -------------------------- |
| Player cash                          | UI                         |
| Plot ownership                       | Visual feedback / effects  |
| Purchases                            | Read input                 |
| Dropper production and drop values   | Presentation               |
| Collection rewards                   |                            |

The client can *read* replicated state (`leaderstats.Cash`, the plot
`OwnerUserId` attribute, `Config`). Changes a client makes to those never
reach the server.

## Services (server only)

`ServerMain.server.luau` is the only server Script. It calls
`TycoonService.Start()`, then routes join/leave in a fixed order:

- Join: `PlayerDataService.OnPlayerAdded` → `TycoonService.OnPlayerAdded`
- Leave: `TycoonService.OnPlayerRemoving` → `PlayerDataService.OnPlayerRemoving`

| Service | Responsibility | Status |
| ------- | -------------- | ------ |
| `PlayerDataService` | Creates `leaderstats.Cash` at `StartingCash` on join (or `DevStartingCash` when `DevUnlimitedCash` is on **and** `RunService:IsStudio()`); forgets it on leave. | Implemented |
| `EconomyService` | **Only** writer of cash: `GetCash`, `AddCash`, `TrySpend` (positive whole numbers, no overspending). | Implemented |
| `TycoonService` | Finds and validates plots, assigns a free plot on join, releases it on leave, holds tycoon data, decides purchases (`TryPurchaseDropper(player, dropperId)`). | Implemented (ownership + dropper purchases) |
| `BuyButtons` (helper) | Used only by `TycoonService`: connects each `BuyButtonN` touch to a callback with the dropper id, sets labels from `Config` ("Dropper N - $Cost"), grays out bought ones. Decides nothing. | Implemented |
| `DropperService` | Runs a plot's droppers: `Start(plot, dropperId)` places a part named after the id at `DropperSpotN`, spawns `Drop` parts worth that dropper's `DropValue` into the plot's `Drops` folder every `DropInterval`; the conveyor moves while any dropper runs; drops are destroyed after `DropLifetime`. Drop value and plot live only in server tables; `ClaimDrop(drop, plot)` returns the value once, only for the drop's own plot. `GetConfig(dropperId)` returns the Config entry and index. | Implemented (`Start`, `Stop`, `StopAll`, `ClaimDrop`, `GetConfig`) |
| `CollectorService` | Stores drop value per plot (server-side table) when `DropperService.ClaimDrop` accepts a drop at the collector; pays the owner on the Collect pad via `EconomyService.AddCash`; shows "Collect $<stored>" on the pad. | Implemented (`SetupPlot`, `ResetPlot`) |

`CollectorService` is deliberately not named `CollectionService`, which is a
built-in Roblox service.

Dependencies (no cycles): `TycoonService` → `BuyButtons`, `DropperService`,
`CollectorService`, `EconomyService`. `BuyButtons` → `DropperService` (`GetConfig`).
`CollectorService` → `DropperService` (`ClaimDrop`) and `EconomyService`. `EconomyService` →
`PlayerDataService`. `DropperService` and `CollectorService` never require
`TycoonService`; they receive the plot and check ownership through the plot's
`OwnerUserId` attribute. `DropperService` never requires `CollectorService`.

## Shared modules

`ReplicatedStorage/Shared` holds modules both sides can require. Right now
that is only `Config`. Never put secrets or server-only logic here: clients can
read everything in ReplicatedStorage.

## Configuration

`Config.luau` holds every tunable value (`StartingCash`, `Droppers`,
`DropInterval`, `NumberOfTycoonPlots`, `ConveyorSpeed`, `DropLifetime`,
`DevUnlimitedCash`, `DevStartingCash`). It is frozen (including each
`Droppers` entry), so code cannot change it at runtime.

`Droppers` is an ordered list of `{ Id, Cost, DropValue }`. Entry N uses the
plot parts `DropperSpotN` and `BuyButtonN`; TycoonService requires one of each
per entry. To add a dropper: add an entry and add the two parts to the map.
`NumberOfTycoonPlots` must match the plot models in the map; TycoonService
warns if it does not.

## Remotes

`ReplicatedStorage/Remotes` exists but is empty: the MVP needs **no** remotes.

- **Use a server-side function call** when server code talks to server code,
  or when the server can observe the action itself (e.g. `Touched` on a
  button, `ProximityPrompt.Triggered`, `Players.PlayerAdded`).
- **Use a RemoteEvent** only when the client must tell the server something
  the server cannot see (e.g. a UI button click), or the server must push
  something the client cannot read from replicated state.
- Avoid RemoteFunctions called from server to client (a client can hang them).
- On the server, a remote handler must validate argument types, that the
  player owns what they are acting on, and use server-side prices/values only.

## Tycoon data model

Server-only, one per player, held by TycoonService:

```lua
type Tycoon = {
	PlotId: number,                  -- from the plot's PlotId attribute
	Plot: Model,                     -- Workspace.Map.Plots.PlotN
	Owner: Player,
	Purchased: { [string]: boolean }, -- e.g. Purchased.Dropper2 = true
}
```

- **Ownership:** TycoonService keeps `player → Tycoon` and `plot → player`
  tables, and mirrors the owner into the plot's `OwnerUserId` attribute
  (read-only for everyone else).
- **Purchased upgrades:** `Purchased` is a set of purchase ids: the
  `Config.Droppers` ids (`"Dropper1"` … `"Dropper4"`).
- **Active systems:** a purchase activates a system by calling its service
  (`DropperService.Start(plot, dropperId)`). Each system service keeps its own runtime
  state keyed by plot and must clean up in its stop/reset function.
- **Lifetime:** data lasts for the session. On leave, systems stop, the plot
  is released and reset. Respawning does not touch any of it (cash lives on
  the Player, not the character).

## Economy model

- Cash is an integer in `leaderstats.Cash`, changed only via EconomyService.
- Money enters the game only through collection (`AddCash`).
- Money leaves only through purchases (`TrySpend`, which fails without
  changing anything if the player cannot afford it).
- Purchase flow: owner touches their plot's `BuyButtonN` (server `Touched`,
  wired by `BuyButtons`) → `TycoonService.TryPurchaseDropper(player, dropperId)`
  checks the player has a plot, the id is a real `Config.Droppers` id, it has
  not already been bought, and `TrySpend(entry.Cost)` succeeds → marks
  `Purchased[dropperId]`, turns that button gray ("Purchased"), and calls
  `DropperService.Start(plot, dropperId)`. Droppers can be bought in any order.
  Touches from non-owners are ignored. On release all buttons reset.
- Drop values are set by the server from the dropper's `Config.Droppers`
  `DropValue`, never taken from the client or from a property a client could change.
- Dev cash: `DevUnlimitedCash` only changes the *starting* amount, and only
  in Studio. Purchases still go through `EconomyService.TrySpend`.

## Adding a feature (for future agents)

1. Confirm the feature is approved (in `GAME_DESIGN.md` / `TODO.md`).
2. Put numbers in `Config.luau`.
3. Put logic in the service that owns that responsibility. Create a new
   service only for a genuinely new responsibility, and wire it from
   `ServerMain` or from the service that owns it.
4. New map parts: edit the `.model.json` files and
   update `REQUIRED_PARTS` in TycoonService if code depends on them.
5. Only add a remote if the rules above say you need one.
6. Update this file, `GAME_DESIGN.md`, `QA.md`, and `TODO.md`.
7. Build with Rojo and test in Studio using `QA.md`.
