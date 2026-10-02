-- TrophyService (server only)
-- Caleb Trophies: the claim on Caleb's podium, equipping, and what each
-- player's Trophy Case shows (and so which trophy powers are active).
--
-- * Claim: while CalebCycle's state is TrophyClaim, a big golden trophy
--   (Workspace.Map.CalebClaimTrophy) stands where Caleb stood, with a server
--   ProximityPrompt "Claim Caleb Trophy". In any other state it is removed.
--   On Triggered the server checks CalebCycle.IsEligible (fed this cycle,
--   not claimed yet, state is TrophyClaim), rolls the reward on the server
--   (TrophyVariants.RollReward: rarity by Config.TrophyRarityChances,
--   preferring trophies the player doesn't own), saves it with
--   DataService.AddTrophy, then CalebCycle.MarkTrophyClaimed. The check, the
--   save, and the mark run without yielding in between, so double triggers
--   can never give two trophies. AddTrophy also refuses a second CLAIMED
--   trophy for the same EventId (cycle id); stolen trophies (StolenFrom)
--   never count, so stealing this round's trophy doesn't block your claim.
-- * If the player's data is not loaded (DataStore down, or Studio without
--   API access), the trophy is kept session-only by TrophyInventory (by
--   UserId, until this server closes) and can still be equipped.
-- * A new trophy is equipped automatically when an active slot is free.
-- * Equipping: the TrophyEquip remote (TrophyInventory.HandleRequest checks
--   type, cooldown, loading, ownership, and the active slot limit).
-- * The player is told the claim result through the CalebTrophyNotice
--   player attribute (Saved/Unsaved carry the new trophy's Variant and
--   InstanceId; TrophyPrompt.client shows the claim pop-up).
-- * Display rule: a trophy's power only works while it is displayed, and
--   only equipped trophies in a BUILT Trophy Case are displayed. On every
--   change (join/load, trophy added, equip change, case built/restored, plot
--   claimed/released) refresh() shows the equipped trophies in slot order
--   (TrophyCaseDisplay.Show) or clears the case, tells PowerService which
--   variants are displayed (none without a built case), and republishes the
--   TrophyInventory player attribute. Refreshes are batched per frame.
-- * House Raid: a trophy a thief is carrying (TheftService.IsInTransit) is
--   neither displayed (its slot stays empty) nor counted for powers, but it
--   stays owned and equipped. TheftService.DisplayChanged asks for a refresh
--   when a theft starts or ends. TheftService never requires this module.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local TrophyVariants = require(ReplicatedStorage.Shared.TrophyVariants)
local CalebCycle = require(script.Parent.CalebCycle)
local DataService = require(script.Parent.DataService)
local PowerService = require(script.Parent.PowerService)
local TheftService = require(script.Parent.TheftService)
local TrophyCaseDisplay = require(script.Parent.TrophyCaseDisplay)
local TrophyInventory = require(script.Parent.TrophyInventory)
local TrophyModel = require(script.Parent.TrophyModel)
local TycoonService = require(script.Parent.TycoonService)

local TrophyService = {}

local CASE_ID = "TrophyCase" -- the Config.Builds Id (and plot model name)
local CLAIM_NAME = "CalebClaimTrophy"
local CLAIM_LOOK = "GoldenCaleb"

local statue: Instance? = nil
local claimTrophy: Model? = nil
local claiming: { [number]: true } = {} -- waiting for their data to load
local pending: { [Player]: true } = {} -- refresh scheduled this frame
local leaving: { [Player]: true } = setmetatable({}, { __mode = "k" }) :: any
local noticeId = 0

local function notify(player: Player, kind: string, variantId: string?, instanceId: string?)
	noticeId += 1
	local notice = { Id = noticeId, Kind = kind, Variant = variantId, InstanceId = instanceId }
	player:SetAttribute(CalebEvent.PlayerAttr.TrophyNotice, HttpService:JSONEncode(notice))
end

-- Shows the player's equipped trophies in their case if it is built (else
-- clears it), sets their active powers to exactly what is displayed, and
-- republishes their TrophyInventory attribute.
local function refresh(player: Player)
	pending[player] = nil -- done now; a scheduled refresh is not needed
	if leaving[player] or player.Parent ~= Players then
		return
	end
	local tycoon = TycoonService.GetTycoon(player)
	local case = tycoon and tycoon.Plot:FindFirstChild(CASE_ID)
	local caseBuilt = tycoon ~= nil and case ~= nil and TycoonService.HasPurchased(player, CASE_ID)
	-- By slot (slot N = the Nth equipped trophy); one being stolen is skipped.
	local shown = {}
	local variantIds = {}
	if caseBuilt then
		for slot, record in TrophyInventory.GetEquippedRecords(player) do
			if not TheftService.IsInTransit(record.InstanceId) then
				shown[slot] = record
				table.insert(variantIds, record.Variant)
			end
		end
	end
	if tycoon and caseBuilt then
		TrophyCaseDisplay.Show(tycoon.Plot, case :: Instance, shown, player.UserId)
	elseif tycoon then
		TrophyCaseDisplay.Clear(tycoon.Plot)
	end
	PowerService.SetDisplayed(player, variantIds)
	TrophyInventory.Publish(player, caseBuilt)
end

-- Several changes in one frame (e.g. a trophy added and auto-equipped)
-- rebuild the case only once.
local function scheduleRefresh(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(function()
		if pending[player] then
			refresh(player)
		end
	end)
end

local function onClaimTriggered(player: Player)
	local userId = player.UserId
	if claiming[userId] then
		return
	end
	if not CalebCycle.IsEligible(userId) then
		local claimed = player:GetAttribute(CalebEvent.PlayerAttr.TrophyClaimed) == true
		notify(player, if claimed then "AlreadyOwned" else "NotEligible")
		return
	end

	-- Returns at once unless their data is still loading (just joined).
	claiming[userId] = true
	DataService.WaitForData(player)
	claiming[userId] = nil
	if player.Parent ~= Players then
		return
	end
	if not CalebCycle.IsEligible(userId) then
		notify(player, "NotEligible") -- the claim period closed while loading
		return
	end

	-- Nothing below yields: check, record, and mark happen together.
	local owned = {}
	for _, record in TrophyInventory.GetOwned(player) do
		table.insert(owned, record.Variant)
	end
	local record = TrophyInventory.NewRecord(TrophyVariants.RollReward(owned), CalebCycle.GetCycleId())
	local kind
	if DataService.IsLoaded(player) then
		-- False only if they already have this cycle's trophy saved.
		kind = if DataService.AddTrophy(player, record) then "Saved" else "AlreadyOwned"
	else
		TrophyInventory.AddSessionTrophy(player, record)
		kind = "Unsaved"
	end
	CalebCycle.MarkTrophyClaimed(userId)
	if kind == "AlreadyOwned" then
		notify(player, kind)
	else
		notify(player, kind, record.Variant, record.InstanceId)
	end
	scheduleRefresh(player)
end

-- Top center of Caleb's pedestal (the highest Pedestal* part).
local function podiumSpot(s: Instance): CFrame
	local best: BasePart? = nil
	local bestTop = -math.huge
	for _, child in s:GetChildren() do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 8) == "Pedestal" then
			local top = child.Position.Y + child.Size.Y / 2
			if top > bestTop then
				best, bestTop = child, top
			end
		end
	end
	if best then
		return best.CFrame * CFrame.new(0, best.Size.Y / 2, 0)
	end
	return if s:IsA("Model") then s:GetPivot() else CFrame.new()
end

local function removeClaimTrophy()
	if claimTrophy then
		claimTrophy:Destroy()
		claimTrophy = nil
	end
end

local function placeClaimTrophy()
	removeClaimTrophy()
	local s = statue
	local map = Workspace:FindFirstChild("Map")
	if not s or not map then
		return
	end
	local trophy = TrophyModel.Build(CLAIM_LOOK, Config.TrophyPodiumScale, "Claim yours!")
	trophy.Name = CLAIM_NAME
	trophy:PivotTo(podiumSpot(s))

	local plinth = trophy:FindFirstChild("Plinth") :: BasePart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimPrompt"
	prompt.ActionText = "Claim Caleb Trophy"
	prompt.ObjectText = "Caleb Trophy"
	prompt.HoldDuration = Config.TrophyClaimHoldSeconds
	prompt.MaxActivationDistance = Config.TrophyClaimPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = plinth
	prompt.Triggered:Connect(onClaimTriggered)

	trophy.Parent = map
	claimTrophy = trophy
end

local function onStateChanged(state: string)
	if state == CalebEvent.State.TrophyClaim then
		placeClaimTrophy()
	else
		removeClaimTrophy()
	end
end

-- Called once by ServerMain after CalebCycle.Start (statue may be nil if the
-- map has none: then only the Trophy Case works).
function TrophyService.Start(statueModel: Instance?)
	statue = statueModel
	CalebCycle.StateChanged:Connect(onStateChanged)
	onStateChanged(CalebCycle.GetState())

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local equipRemote = remotes:WaitForChild("TrophyEquip") :: RemoteFunction
	equipRemote.OnServerInvoke = function(player: Player, action: any, instanceId: any)
		local ok, reason = TrophyInventory.HandleRequest(player, action, instanceId)
		if ok then
			scheduleRefresh(player) -- also batches with EquippedChanged
		end
		return ok, reason
	end

	TycoonService.PurchaseApplied:Connect(function(player: Player, _plot: Model, purchaseId: string)
		if purchaseId == CASE_ID then
			scheduleRefresh(player)
		end
	end)
	DataService.TrophiesChanged:Connect(scheduleRefresh)
	DataService.EquippedChanged:Connect(scheduleRefresh)
	TheftService.DisplayChanged:Connect(function(userId: number)
		local player = Players:GetPlayerByUserId(userId)
		if player then
			scheduleRefresh(player) -- a trophy left the case, came back, or changed hands
		end
	end)

	-- Join: publish at once (nothing owned yet), again once their data loaded.
	local function onPlayerAdded(player: Player)
		scheduleRefresh(player)
		task.spawn(function()
			DataService.WaitForData(player)
			scheduleRefresh(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		leaving[player] = true
		pending[player] = nil
		TrophyInventory.OnPlayerRemoving(player)
		PowerService.SetDisplayed(player, {})
	end)

	local plots = Workspace:WaitForChild("Map"):WaitForChild("Plots")
	for _, plot in plots:GetChildren() do
		local case = plot:FindFirstChild(CASE_ID)
		for slot = 1, Config.TrophyCaseSlots do
			if case and not case:FindFirstChild(`TrophySlot{slot}`) then
				warn(`TrophyService: {plot.Name}.{CASE_ID} is missing TrophySlot{slot}`)
			end
		end
		local ownerUserId = plot:GetAttribute("OwnerUserId")
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			local previous = ownerUserId
			ownerUserId = plot:GetAttribute("OwnerUserId")
			if ownerUserId == nil then
				TrophyCaseDisplay.Clear(plot) -- released
			end
			-- Claimed or released: the owner's case (and powers) changed.
			for _, userId in { previous, ownerUserId } do
				local player = typeof(userId) == "number" and Players:GetPlayerByUserId(userId)
				if player then
					scheduleRefresh(player)
				end
			end
		end)
	end
end

return TrophyService
