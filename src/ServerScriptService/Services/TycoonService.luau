-- TycoonService (server only)
-- Owns plot ownership and each player's tycoon data.
--
-- * Finds the plots in Workspace.Map.Plots at startup.
-- * Gives each joining player the first free plot.
-- * Releases the plot (and stops its systems) when the player leaves.
-- * Is the single place that decides purchases for a tycoon.
--
-- Public ownership marker: each plot Model has an "OwnerUserId" attribute set
-- by this service (nil when unclaimed). Other services and the client may read
-- it. Only this service writes it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local CollectorService = require(script.Parent.CollectorService)
local DropperService = require(script.Parent.DropperService)

local TycoonService = {}

-- One player's tycoon for this session. Server-only; never sent to clients.
export type Tycoon = {
	PlotId: number,
	Plot: Model,
	Owner: Player,
	-- Purchase id -> true once bought. The MVP has one id: "Dropper".
	-- Add new upgrades as new ids; the service that runs the upgrade keeps its
	-- own runtime state keyed by plot.
	Purchased: { [string]: boolean },
}

-- Parts every plot model must contain (see src/Workspace/Map/Plots).
local REQUIRED_PARTS = {
	"Base",
	"OwnerSign",
	"DropperSpot",
	"Conveyor",
	"Collector",
	"CollectPad",
	"BuyDropperButton",
}

local plots: { Model } = {} -- valid plots, sorted by PlotId
local tycoonsByPlayer: { [Player]: Tycoon } = {}
local ownerByPlot: { [Model]: Player } = {}

local function isValidPlot(plot: Instance): boolean
	if not plot:IsA("Model") or typeof(plot:GetAttribute("PlotId")) ~= "number" then
		return false
	end
	for _, partName in REQUIRED_PARTS do
		if not plot:FindFirstChild(partName) then
			warn(`TycoonService: {plot.Name} is missing '{partName}' and will not be used`)
			return false
		end
	end
	return true
end

local function setOwnerSign(plot: Model, text: string)
	local label = plot.OwnerSign:FindFirstChild("TextLabel", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- Called once by ServerMain before any players are handled.
function TycoonService.Start()
	local plotsFolder = Workspace:WaitForChild("Map"):WaitForChild("Plots")

	for _, child in plotsFolder:GetChildren() do
		if isValidPlot(child) then
			table.insert(plots, child :: Model)
		end
	end
	table.sort(plots, function(a, b)
		return a:GetAttribute("PlotId") < b:GetAttribute("PlotId")
	end)

	if #plots ~= Config.NumberOfTycoonPlots then
		warn(`TycoonService: found {#plots} valid plots but Config.NumberOfTycoonPlots is {Config.NumberOfTycoonPlots}`)
	end

	for _, plot in plots do
		setOwnerSign(plot, "Unclaimed")
		CollectorService.SetupPlot(plot)
	end
end

-- Called by ServerMain when a player joins. Assigns the first free plot.
function TycoonService.OnPlayerAdded(player: Player)
	if tycoonsByPlayer[player] then
		return -- already has a plot; never assign two
	end

	for _, plot in plots do
		if not ownerByPlot[plot] then
			tycoonsByPlayer[player] = {
				PlotId = plot:GetAttribute("PlotId"),
				Plot = plot,
				Owner = player,
				Purchased = {},
			}
			ownerByPlot[plot] = player
			plot:SetAttribute("OwnerUserId", player.UserId)
			setOwnerSign(plot, `{player.DisplayName}'s Tycoon`)
			return
		end
	end

	warn(`TycoonService: no free plot for {player.Name}. Set the server's max players to {#plots}.`)
end

-- Called by ServerMain when a player leaves. Stops systems and frees the plot.
function TycoonService.OnPlayerRemoving(player: Player)
	local tycoon = tycoonsByPlayer[player]
	if not tycoon then
		return
	end

	DropperService.Stop(tycoon.Plot)
	CollectorService.ResetPlot(tycoon.Plot)

	tycoonsByPlayer[player] = nil
	ownerByPlot[tycoon.Plot] = nil
	tycoon.Plot:SetAttribute("OwnerUserId", nil)
	setOwnerSign(tycoon.Plot, "Unclaimed")
end

-- Returns the player's tycoon, or nil if they have no plot.
function TycoonService.GetTycoon(player: Player): Tycoon?
	return tycoonsByPlayer[player]
end

-- Returns the player who owns a plot, or nil if it is unclaimed.
function TycoonService.GetPlotOwner(plot: Model): Player?
	return ownerByPlot[plot]
end

-- Returns true if the player has bought the given purchase id.
function TycoonService.HasPurchased(player: Player, purchaseId: string): boolean
	local tycoon = tycoonsByPlayer[player]
	return tycoon ~= nil and tycoon.Purchased[purchaseId] == true
end

-- Buys the dropper for the player's own plot. Returns true on success.
--
-- STATUS: stub. Intended server-side steps for the next agent:
--   1. Get the player's tycoon; fail if they have none.
--   2. Fail if tycoon.Purchased.Dropper is already true (no double purchase).
--   3. EconomyService.TrySpend(player, Config.DropperCost); fail if false.
--   4. Set tycoon.Purchased.Dropper = true.
--   5. DropperService.Start(tycoon.Plot).
-- Trigger: in Start(), connect each plot's BuyDropperButton.Touched, find the
-- player with Players:GetPlayerFromCharacter(hit.Parent), and only call this
-- when that player owns the plot.
function TycoonService.TryPurchaseDropper(player: Player): boolean
	warn(`TycoonService.TryPurchaseDropper is not implemented yet ({player.Name})`)
	return false
end

return TycoonService
