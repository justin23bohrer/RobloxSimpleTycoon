-- TycoonService (server only)
-- Owns plot ownership and each player's tycoon data.
--
-- * Finds the plots in Workspace.Map.Plots at startup.
-- * A player claims a free plot by stepping on its ClaimPad (one plot each).
-- * Releases the plot (and stops its systems) when the player leaves.
-- * Is the single place that decides purchases for a tycoon (droppers and
--   builds, see Purchases). Each one unlocks only after the purchase named in
--   its Config After field: Dropper1-4 -> Walls -> Stairs -> SecondFloor ->
--   Dropper5-8 (and Walls -> TrophyCase). PurchaseApplied fires for every
--   purchase applied to a plot (bought or restored).
-- * Restores a player's saved purchases (DataService) when they claim a plot,
--   in unlock order, without charging cookies, and records new purchases.
-- * Tells PlotStages what to show: only the ClaimPad while unclaimed, then the
--   collect area and the first buy button, then the next button(s) and any
--   built parts after each purchase.
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
local DataService = require(script.Parent.DataService)
local DropperService = require(script.Parent.DropperService)
local EconomyService = require(script.Parent.EconomyService)
local PlotStages = require(script.Parent.PlotStages)
local Purchases = require(script.Parent.Purchases)
local TycoonSounds = require(script.Parent.TycoonSounds)

local TycoonService = {}

-- One player's tycoon for this session. Server-only; never sent to clients.
export type Tycoon = {
	PlotId: number,
	Plot: Model,
	Owner: Player,
	-- Purchase id -> true once bought. Ids are Config.Droppers[N].Id
	-- ("Dropper1", ...) and Config.Builds[N].Id ("Walls", "Stairs", ...).
	-- Add new upgrades as new ids; the service that runs the upgrade keeps its
	-- own runtime state keyed by plot.
	Purchased: { [string]: boolean },
	-- True while saved purchases are being restored; buying waits for it.
	Restoring: boolean,
}

-- Parts every plot model must contain (see src/Workspace/Map/Plots), plus
-- every purchase's button, each dropper's DropperSpotN, conveyor, and
-- collector, and each build's Parts.
local REQUIRED_PARTS = {
	"Base",
	"ClaimPad",
	"OwnerSign",
	"Conveyor",
	"Collector",
	"CollectPad",
}
for _, purchase in Purchases.All() do
	table.insert(REQUIRED_PARTS, purchase.ButtonName)
	if purchase.Kind == "Dropper" then
		table.insert(REQUIRED_PARTS, `DropperSpot{purchase.Index}`)
		table.insert(REQUIRED_PARTS, purchase.Entry.Conveyor)
		table.insert(REQUIRED_PARTS, DropperService.CollectorFor(purchase.Entry.Conveyor))
	else
		for _, name in purchase.Entry.Parts do
			table.insert(REQUIRED_PARTS, name)
		end
	end
end

-- Seconds a player must wait between buy-button touches. Touched fires many
-- times per step; this only reduces spam. Double purchases are blocked by
-- tycoon.Purchased, not by this.
local BUY_TOUCH_COOLDOWN = 0.5

local plots: { Model } = {} -- valid plots, sorted by PlotId
local tycoonsByPlayer: { [Player]: Tycoon } = {}
local ownerByPlot: { [Model]: Player } = {}
local lastBuyTouch: { [Player]: number } = {}

local purchaseApplied = Instance.new("BindableEvent")
-- Fires (player, plot, purchaseId) each time a purchase is applied to a plot:
-- when it is bought and when a saved one is restored after a claim.
TycoonService.PurchaseApplied = purchaseApplied.Event

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

-- The sign has the same text on both faces (toward the spawn and into the
-- plot), so update every TextLabel on it.
local function setOwnerSign(plot: Model, text: string)
	for _, label in plot.OwnerSign:GetDescendants() do
		if label:IsA("TextLabel") then
			label.Text = text
		end
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
	setOwnerSign(plot, "UNCLAIMED")
	PlotStages.ShowUnclaimed(plot)
end

local function onClaimPadTouched(plot: Model, hit: BasePart)
	local player = getPlayerFromHit(hit)
	if player then
		TycoonService.TryClaimPlot(player, plot)
	end
end

local function onBuyButtonTouched(plot: Model, hit: BasePart, purchaseId: string)
	local player = getPlayerFromHit(hit)
	if not player or ownerByPlot[plot] ~= player then
		return -- not a player, or not this plot's owner
	end

	local now = os.clock()
	if lastBuyTouch[player] and now - lastBuyTouch[player] < BUY_TOUCH_COOLDOWN then
		return
	end
	lastBuyTouch[player] = now

	TycoonService.TryPurchase(player, purchaseId)
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
		TycoonSounds.Setup(plot)
		resetPlot(plot)
		plot.ClaimPad.Touched:Connect(function(hit)
			onClaimPadTouched(plot, hit)
		end)
		BuyButtons.Connect(plot, function(hit, purchaseId)
			onBuyButtonTouched(plot, hit, purchaseId)
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
		Restoring = true,
	}
	ownerByPlot[plot] = player
	plot:SetAttribute("OwnerUserId", player.UserId)
	setOwnerSign(plot, `{player.DisplayName}'s Tycoon`)
	PlotStages.ShowClaimed(plot)
	task.spawn(TycoonService.RestorePurchases, player)
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
	TycoonSounds.OnPlayerRemoving(player)
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

-- Marks a purchase as bought on the tycoon's plot: shows what it builds and
-- unlocks, and starts a dropper. Charges nothing; callers decide that.
local function applyPurchase(tycoon: Tycoon, purchase: Purchases.Purchase)
	tycoon.Purchased[purchase.Id] = true
	PlotStages.ShowAfterPurchase(tycoon.Plot, purchase.Id)
	if purchase.Kind == "Dropper" then
		DropperService.Start(tycoon.Plot, purchase.Id)
	end
	purchaseApplied:Fire(tycoon.Owner, tycoon.Plot, purchase.Id)
end

-- Rebuilds the player's saved house on the plot they just claimed (called by
-- TryClaimPlot). Waits for DataService to load, then applies each saved
-- purchase in unlock order (walking the After chain from the first buttons),
-- so every purchase's After is in place before it. Free: no cookies spent.
-- Saved ids that are no longer purchases, or whose After was not saved, are
-- skipped. If the data did not load, the plot just starts fresh.
function TycoonService.RestorePurchases(player: Player)
	local tycoon = tycoonsByPlayer[player]
	if not tycoon or not tycoon.Restoring then
		return
	end
	local loaded = DataService.WaitForData(player)
	if tycoonsByPlayer[player] ~= tycoon then
		return -- left (plot already reset) while loading
	end

	if loaded then
		local saved = DataService.GetPurchases(player)
		local queue = table.clone(Purchases.UnlockedBy(nil))
		local i = 1
		while i <= #queue do
			local purchase = queue[i]
			i += 1
			if saved[purchase.Id] and not tycoon.Purchased[purchase.Id] then
				applyPurchase(tycoon, purchase)
				for _, unlocked in Purchases.UnlockedBy(purchase.Id) do
					table.insert(queue, unlocked)
				end
			end
		end
	end
	tycoon.Restoring = false
end

-- Buys one purchase (a Config.Droppers or Config.Builds Id) for the player's
-- own plot. Returns true on success. Called when the owner touches its button.
-- A purchase can only be bought after the one named in its After field; the
-- price comes only from Config. A Cost of 0 is free (nothing is spent).
-- Buying a dropper starts it; buying a build shows its parts (PlotStages).
-- Plays the purchase sound (or the player's "can't afford" sound) after the
-- result is decided; restoring a saved house never comes through here.
function TycoonService.TryPurchase(player: Player, purchaseId: string): boolean
	local tycoon = tycoonsByPlayer[player]
	if not tycoon or typeof(purchaseId) ~= "string" then
		return false -- player has no plot, or a bad id
	end
	if tycoon.Restoring then
		return false -- saved house not restored yet; never charge for owned items
	end
	local purchase = Purchases.Get(purchaseId)
	if not purchase then
		return false -- not a real purchase id
	end
	if tycoon.Purchased[purchaseId] then
		return false -- already bought; never charge twice
	end
	local after = purchase.Entry.After
	if after ~= nil and not tycoon.Purchased[after] then
		return false -- not unlocked yet; buy the one before it first
	end
	local cost = purchase.Entry.Cost
	if cost > 0 and not EconomyService.TrySpend(player, cost) then
		TycoonSounds.CantAfford(player, purchaseId)
		return false -- cannot afford it; cash unchanged
	end

	applyPurchase(tycoon, purchase)
	DataService.SetPurchased(player, purchaseId)
	TycoonSounds.Purchased(tycoon.Plot, purchaseId)
	return true
end

return TycoonService
