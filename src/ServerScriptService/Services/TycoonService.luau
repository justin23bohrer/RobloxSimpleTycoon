-- TycoonService (server only)
-- Owns plot ownership and each player's tycoon data.
--
-- * Finds the plots in Workspace.Map.Plots at startup.
-- * A player claims a free plot by stepping on its ClaimPad (one plot each).
-- * Releases the plot (and stops its systems) when the player leaves.
-- * Is the single place that decides purchases for a tycoon. Droppers unlock
--   in Config.Droppers order: only the next one can be bought.
-- * Tells PlotStages what to show: only the ClaimPad while unclaimed, then the
--   collect area and the first buy button, then one more button per purchase.
--
-- Public ownership marker: each plot Model has an "OwnerUserId" attribute set
-- by this service (nil when unclaimed). Other services and the client may read
-- it. Only this service writes it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local BuyButtons = require(script.Parent.BuyButtons)
local CollectorService = require(script.Parent.CollectorService)
local DropperService = require(script.Parent.DropperService)
local EconomyService = require(script.Parent.EconomyService)
local PlotStages = require(script.Parent.PlotStages)

local TycoonService = {}

-- One player's tycoon for this session. Server-only; never sent to clients.
export type Tycoon = {
	PlotId: number,
	Plot: Model,
	Owner: Player,
	-- Purchase id -> true once bought. Ids are Config.Droppers[N].Id
	-- ("Dropper1", "Dropper2", ...).
	-- Add new upgrades as new ids; the service that runs the upgrade keeps its
	-- own runtime state keyed by plot.
	Purchased: { [string]: boolean },
}

-- Parts every plot model must contain (see src/Workspace/Map/Plots), plus a
-- DropperSpotN and BuyButtonN for each entry in Config.Droppers.
local REQUIRED_PARTS = {
	"Base",
	"ClaimPad",
	"OwnerSign",
	"Conveyor",
	"Collector",
	"CollectPad",
}
for index in Config.Droppers do
	table.insert(REQUIRED_PARTS, `DropperSpot{index}`)
	table.insert(REQUIRED_PARTS, BuyButtons.PartName(index))
end

-- Seconds a player must wait between buy-button touches. Touched fires many
-- times per step; this only reduces spam. Double purchases are blocked by
-- tycoon.Purchased, not by this.
local BUY_TOUCH_COOLDOWN = 0.5

local plots: { Model } = {} -- valid plots, sorted by PlotId
local tycoonsByPlayer: { [Player]: Tycoon } = {}
local ownerByPlot: { [Model]: Player } = {}
local lastBuyTouch: { [Player]: number } = {}

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

local function getPlayerFromHit(hit: BasePart): Player?
	local character = hit.Parent
	return character and Players:GetPlayerFromCharacter(character)
end

-- Stops the plot's systems and puts it back to its unclaimed look.
local function resetPlot(plot: Model)
	DropperService.StopAll(plot)
	CollectorService.ResetPlot(plot)
	plot:SetAttribute("OwnerUserId", nil)
	setOwnerSign(plot, "Unclaimed")
	PlotStages.ShowUnclaimed(plot)
end

local function onClaimPadTouched(plot: Model, hit: BasePart)
	local player = getPlayerFromHit(hit)
	if player then
		TycoonService.TryClaimPlot(player, plot)
	end
end

local function onBuyButtonTouched(plot: Model, hit: BasePart, dropperId: string)
	local player = getPlayerFromHit(hit)
	if not player or ownerByPlot[plot] ~= player then
		return -- not a player, or not this plot's owner
	end

	local now = os.clock()
	if lastBuyTouch[player] and now - lastBuyTouch[player] < BUY_TOUCH_COOLDOWN then
		return
	end
	lastBuyTouch[player] = now

	TycoonService.TryPurchaseDropper(player, dropperId)
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
		CollectorService.SetupPlot(plot) -- before resetPlot: it builds the pad's effects
		resetPlot(plot)
		plot.ClaimPad.Touched:Connect(function(hit)
			onClaimPadTouched(plot, hit)
		end)
		BuyButtons.Connect(plot, function(hit, dropperId)
			onBuyButtonTouched(plot, hit, dropperId)
		end)
	end
end

-- Gives the plot to the player if it is free and they have no plot yet.
-- Returns true on success. Called when a player touches a plot's ClaimPad.
function TycoonService.TryClaimPlot(player: Player, plot: Model): boolean
	if tycoonsByPlayer[player] or ownerByPlot[plot] or not table.find(plots, plot) then
		return false -- already owns a plot, plot taken, or not a real plot
	end
	if player.Parent ~= Players then
		return false -- leaving; a late touch must not claim a plot nobody will free
	end

	tycoonsByPlayer[player] = {
		PlotId = plot:GetAttribute("PlotId"),
		Plot = plot,
		Owner = player,
		Purchased = {},
	}
	ownerByPlot[plot] = player
	plot:SetAttribute("OwnerUserId", player.UserId)
	setOwnerSign(plot, `{player.DisplayName}'s Tycoon`)
	PlotStages.ShowClaimed(plot)
	return true
end

-- Called by ServerMain when a player leaves. Stops systems and frees the plot.
function TycoonService.OnPlayerRemoving(player: Player)
	local tycoon = tycoonsByPlayer[player]
	if not tycoon then
		return
	end

	tycoonsByPlayer[player] = nil
	ownerByPlot[tycoon.Plot] = nil
	lastBuyTouch[player] = nil
	resetPlot(tycoon.Plot)
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

-- Buys one dropper (a Config.Droppers Id) for the player's own plot.
-- Returns true on success. Called when the owner touches a BuyButtonN.
-- Droppers must be bought in Config.Droppers order; the price comes only from
-- Config. A Cost of 0 is free (nothing is spent).
function TycoonService.TryPurchaseDropper(player: Player, dropperId: string): boolean
	local tycoon = tycoonsByPlayer[player]
	if not tycoon or typeof(dropperId) ~= "string" then
		return false -- player has no plot, or a bad id
	end
	local dropper, index = DropperService.GetConfig(dropperId)
	if not dropper or not index then
		return false -- not a real dropper id
	end
	if tycoon.Purchased[dropperId] then
		return false -- already bought; never charge twice
	end
	local previous = Config.Droppers[index - 1]
	if previous and not tycoon.Purchased[previous.Id] then
		return false -- not unlocked yet; buy the one before it first
	end
	if dropper.Cost > 0 and not EconomyService.TrySpend(player, dropper.Cost) then
		return false -- cannot afford it; cash unchanged
	end

	tycoon.Purchased[dropperId] = true
	PlotStages.ShowAfterPurchase(tycoon.Plot, index)
	DropperService.Start(tycoon.Plot, dropperId)
	return true
end

return TycoonService
