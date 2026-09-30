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
│       ├── PlotStages.luau     → helper for TycoonService (what a plot shows at each stage)
│       ├── PlotVisibility.luau → helper: hide/show a part or model and restore it
│       ├── BuyButtons.luau     → helper for TycoonService (buy button labels/touches/visibility)
│       ├── DropperService.luau
│       ├── CollectorService.luau
│       └── CollectorDisplay.luau → helper for CollectorService (cash tank + pad effects)
├── StarterPlayer/
│   └── StarterPlayerScripts/   → client LocalScripts
│       └── CashDisplay.client.luau → LocalScript: bottom-center cash panel
├── StarterGui/                 → client UI (empty; UI is built by LocalScripts)
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

- Join: `PlayerDataService.OnPlayerAdded` (no plot yet; plots are claimed on
  the `ClaimPad`, see TycoonService)
- Leave: `TycoonService.OnPlayerRemoving` → `PlayerDataService.OnPlayerRemoving`

| Service | Responsibility | Status |
| ------- | -------------- | ------ |
| `PlayerDataService` | Creates `leaderstats.Cash` at `StartingCash` on join (or `DevStartingCash` when `DevUnlimitedCash` is on **and** `RunService:IsStudio()`); forgets it on leave. | Implemented |
| `EconomyService` | **Only** writer of cash: `GetCash`, `AddCash`, `TrySpend` (positive whole numbers, no overspending). | Implemented |
| `TycoonService` | Finds and validates plots, gives a free plot to a player who touches its `ClaimPad` (`TryClaimPlot(player, plot)`; one plot per player), releases and resets it on leave, holds tycoon data, decides purchases (`TryPurchaseDropper(player, dropperId)`; in `Config.Droppers` order only; `Cost = 0` spends nothing). Tells `PlotStages` what to show. | Implemented (claiming + ordered dropper purchases) |
| `PlotStages` (helper) | Used only by `TycoonService`: `ShowUnclaimed(plot)` (only `Base` + `ClaimPad`), `ShowClaimed(plot)` (hides `ClaimPad`; shows `OwnerSign`, `Conveyor`, `Collector`, `CollectPad`, `CashTank`, and buy button 1), `ShowAfterPurchase(plot, index)` (hides button N, shows button N+1). Decides nothing. | Implemented |
| `PlotVisibility` (helper) | `Hide(root)` / `Show(root)` for a part or model and all its descendants: hidden parts get `Transparency = 1` and no collide/touch/query; Billboard/Surface GUIs are disabled. Original values are saved and restored exactly. A hidden part cannot fire `Touched`. | Implemented |
| `BuyButtons` (helper) | Used only by `TycoonService`/`PlotStages`: connects each `BuyButtonN` touch to a callback with the dropper id, sets labels from `Config` ("Dropper N - $Cost" / "FREE"), and hides/shows each button together with its `DropperSpotN` (`HideAll`, `Show`, `SetPurchased`). Decides nothing. | Implemented |
| `DropperService` | Runs a plot's droppers: `Start(plot, dropperId)` places a part named after the id at `DropperSpotN`, spawns `Drop` parts worth that dropper's `DropValue` into the plot's `Drops` folder every `DropInterval`; the conveyor moves while any dropper runs; drops are destroyed after `DropLifetime`. Drop value and plot live only in server tables; `ClaimDrop(drop, plot)` returns the value once, only for the drop's own plot. `GetConfig(dropperId)` returns the Config entry and index. | Implemented (`Start`, `Stop`, `StopAll`, `ClaimDrop`, `GetConfig`) |
| `CollectorService` | Stores drop value per plot (server-side table) when `DropperService.ClaimDrop` accepts a drop at the collector; pays the owner on the Collect pad via `EconomyService.AddCash`. Never shows the amount as text. | Implemented (`SetupPlot`, `ResetPlot`) |
| `CollectorDisplay` (helper) | Used only by `CollectorService`: presentation only, never reads or changes cash. `Setup(plot)` adds the pad's sparkles, glow, and bouncing arrow; `AddCube(plot)` drops a gold cube into the plot's `CashTank` (max 60) and turns sparkles/glow on; `Clear(plot, celebrate)` empties the tank and, on payout, bursts sparkles. Built on the server so all players see it. | Implemented |

`CollectorService` is deliberately not named `CollectionService`, which is a
built-in Roblox service.

Dependencies (no cycles): `TycoonService` → `PlotStages`, `BuyButtons`, `DropperService`,
`CollectorService`, `EconomyService`. `PlotStages` → `BuyButtons`, `PlotVisibility`.
`BuyButtons` → `PlotVisibility`.
`CollectorService` → `CollectorDisplay`, `DropperService` (`ClaimDrop`) and `EconomyService`. `EconomyService` →
`PlayerDataService`. `DropperService` and `CollectorService` never require
`TycoonService`; they receive the plot and check ownership through the plot's
`OwnerUserId` attribute. `DropperService` never requires `CollectorService`.

## Client

Client code is presentation only. It reads replicated state and never
changes cash, ownership, or purchases, and never talks to the server.

| Script | What it does |
| ------ | ------------ |
| `StarterPlayerScripts/CashDisplay.client.luau` | Builds a `CashDisplay` ScreenGui (`ResetOnSpawn = false`) with a cartoony panel at the bottom-center. Waits for `leaderstats.Cash`, shows it as `$1,250` (comma separators), and on `.Changed` updates the text and plays a short `UIScale` "pop" tween. Built-in UI only (UICorner, UIStroke, FredokaOne, a text "$" coin). Scale sizing + `UIAspectRatioConstraint` + `UISizeConstraint` keep it readable on phone and PC. The built-in player list still shows cash too. |

UI is created by LocalScripts in `StarterPlayerScripts` (which run once per
session) rather than stored as instances in `StarterGui`. Colors and sizes
that are purely visual stay in the script; gameplay numbers stay in `Config`.

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
- Claim flow: a player touches a plot's `ClaimPad` (server `Touched`) →
  `TycoonService.TryClaimPlot(player, plot)` checks the player has no plot and
  the plot is free → records the tycoon, sets `OwnerUserId` and the sign, and
  calls `PlotStages.ShowClaimed`.
- Purchase flow: owner touches their plot's `BuyButtonN` (server `Touched`,
  wired by `BuyButtons`) → `TycoonService.TryPurchaseDropper(player, dropperId)`
  checks the player has a plot, the id is a real `Config.Droppers` id, it has
  not already been bought, the previous dropper (N-1) **has** been bought, and
  `TrySpend(entry.Cost)` succeeds (skipped when `Cost` is 0) → marks
  `Purchased[dropperId]`, calls `PlotStages.ShowAfterPurchase` (hide button N,
  show button N+1), and calls `DropperService.Start(plot, dropperId)`.
  Touches from non-owners are ignored. On release the plot goes back to
  `ShowUnclaimed`.
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
