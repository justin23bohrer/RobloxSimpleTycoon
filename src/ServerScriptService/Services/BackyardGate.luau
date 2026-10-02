-- BackyardGate (server only)
-- Locks each plot's back door until the plot's owner owns enough Caleb
-- Trophies. It reads ownership (TycoonService) and trophies
-- (TrophyInventory); it changes neither.
--
-- * A plot's BackDoor is LOCKED (closed and solid) unless the plot has an
--   owner who owns at least Config.BackyardTrophies trophies (inventory
--   count, equipped or not, session/dev trophies included). Unclaimed plots
--   are locked. Once open, anyone may walk through (like the house).
-- * Only the door is locked. Nothing pushes players out of the yard itself:
--   walking around the outside of the house into it (before the Walls and
--   BackyardFence are built) or jumping the fence is allowed.
-- * The look (door closed/swung open, the "Unlock this door once you have
--   5 Caleb Trophies" sign) is BackyardDoor. Updated on claim/release (the
--   plot's OwnerUserId attribute), DataService.TrophiesChanged, and the
--   owner's TrophyInventory attribute (TrophyService republishes it on data
--   load, dev trophies, and session-only claims).
-- * A plot without the BackDoor parts (map not merged yet) is skipped with
--   one warning.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local BackyardDoor = require(script.Parent.BackyardDoor)
local DataService = require(script.Parent.DataService)
local TrophyInventory = require(script.Parent.TrophyInventory)
local TycoonService = require(script.Parent.TycoonService)

local BackyardGate = {}

type Gate = {
	Plot: Model,
	Door: BackyardDoor.Door,
}

local gates: { [Model]: Gate } = {}
local started = false

-- Re-reads the plot's owner and their trophy count; updates the door.
local function refresh(gate: Gate)
	local owner = TycoonService.GetPlotOwner(gate.Plot)
	local owned = if owner then #TrophyInventory.GetOwned(owner) else nil
	local locked = owned == nil or owned < Config.BackyardTrophies
	BackyardDoor.Show(gate.Door, locked, owned, Config.BackyardTrophies)
end

local function refreshPlayer(player: Player)
	local tycoon = TycoonService.GetTycoon(player)
	local gate = tycoon and gates[tycoon.Plot]
	if gate then
		refresh(gate)
	end
end

local function setupPlot(plot: Model)
	local base = plot:FindFirstChild("Base")
	if not (base and base:IsA("BasePart")) then
		return
	end
	local door, missing = BackyardDoor.Find(plot, base.Position)
	if not door then
		warn(`BackyardGate: {plot.Name} has no {table.concat(missing, ", ")}; it has no back door`)
		return
	end
	local gate: Gate = { Plot = plot, Door = door }
	gates[plot] = gate
	refresh(gate)
	plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		refresh(gate) -- claimed or released
	end)
end

local function onPlayerAdded(player: Player)
	player:GetAttributeChangedSignal(TrophyInventory.ATTRIBUTE):Connect(function()
		refreshPlayer(player)
	end)
end

-- Called once by ServerMain after TycoonService.Start.
function BackyardGate.Start()
	if started then
		return
	end
	started = true
	for _, plot in Workspace:WaitForChild("Map"):WaitForChild("Plots"):GetChildren() do
		if plot:IsA("Model") then
			setupPlot(plot)
		end
	end
	DataService.TrophiesChanged:Connect(refreshPlayer)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return BackyardGate
