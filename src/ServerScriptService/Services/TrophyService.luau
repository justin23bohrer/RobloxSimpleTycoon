-- TrophyService (server only)
-- Caleb Trophies: the claim on Caleb's podium, and showing each player's
-- trophies in the Trophy Case build of their house.
--
-- * Claim: while CalebCycle's state is TrophyClaim, a big golden trophy
--   (Workspace.Map.CalebClaimTrophy) stands where Caleb stood, with a server
--   ProximityPrompt "Claim Caleb Trophy". In any other state it is removed.
--   On Triggered the server checks CalebCycle.IsEligible (fed this cycle,
--   not claimed yet, state is TrophyClaim), picks a variant
--   (TrophyVariants.PickVariant, preferring ones the player doesn't own),
--   saves it with DataService.AddTrophy, then CalebCycle.MarkTrophyClaimed.
--   The check, the save, and the mark run without yielding in between, so
--   double triggers can never give two trophies. AddTrophy also refuses a
--   second trophy for the same EventId (cycle id).
-- * If the player's data is not loaded (DataStore down, or Studio without
--   API access), the trophy is kept in a session-only list here instead
--   (by UserId, until this server closes) and still shown in their case.
-- * The player is told the result through the CalebTrophyNotice player
--   attribute (TrophyPrompt.client shows a notification). No remotes.
-- * Trophy Case: when the owner's TrophyCase is built or restored
--   (TycoonService.PurchaseApplied), or they get a trophy
--   (DataService.TrophiesChanged), their newest Config.TrophyCaseSlots
--   trophies are placed on TrophySlot1.. (slot 1 = newest) by
--   TrophyCaseDisplay. Cleared when the plot is released (its OwnerUserId
--   attribute goes away).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local TrophyVariants = require(ReplicatedStorage.Shared.TrophyVariants)
local CalebCycle = require(script.Parent.CalebCycle)
local DataService = require(script.Parent.DataService)
local TrophyCaseDisplay = require(script.Parent.TrophyCaseDisplay)
local TrophyModel = require(script.Parent.TrophyModel)
local TycoonService = require(script.Parent.TycoonService)

local TrophyService = {}

type TrophyRecord = DataService.TrophyRecord

local CASE_ID = "TrophyCase" -- the Config.Builds Id (and plot model name)
local CLAIM_NAME = "CalebClaimTrophy"
local CLAIM_LOOK = "GoldenCaleb"

local statue: Instance? = nil
local claimTrophy: Model? = nil
local sessionTrophies: { [number]: { TrophyRecord } } = {} -- unsaved claims, by UserId
local claiming: { [number]: true } = {} -- waiting for their data to load
local noticeId = 0

local function notify(player: Player, kind: string, variantId: string?)
	noticeId += 1
	local notice = { Id = noticeId, Kind = kind, Variant = variantId }
	player:SetAttribute(CalebEvent.PlayerAttr.TrophyNotice, HttpService:JSONEncode(notice))
end

-- Saved + session-only trophies, oldest first.
local function allTrophies(player: Player): { TrophyRecord }
	local list = DataService.GetTrophies(player)
	for _, record in sessionTrophies[player.UserId] or {} do
		table.insert(list, record)
	end
	table.sort(list, function(a, b)
		if a.EarnedAt ~= b.EarnedAt then
			return a.EarnedAt < b.EarnedAt
		end
		return a.EventId < b.EventId
	end)
	return list
end

-- Rebuilds the trophies in the player's Trophy Case (if it is built).
local function refreshCase(player: Player)
	local tycoon = TycoonService.GetTycoon(player)
	if not tycoon then
		return
	end
	local case = tycoon.Plot:FindFirstChild(CASE_ID)
	if case and TycoonService.HasPurchased(player, CASE_ID) then
		TrophyCaseDisplay.Show(tycoon.Plot, case, allTrophies(player))
	else
		TrophyCaseDisplay.Clear(tycoon.Plot)
	end
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
	for _, record in allTrophies(player) do
		table.insert(owned, record.Variant)
	end
	local record: TrophyRecord = {
		Variant = TrophyVariants.PickVariant(owned),
		EventId = CalebCycle.GetCycleId(),
		EarnedAt = os.time(),
	}
	local kind
	if DataService.IsLoaded(player) then
		-- False only if they already have this cycle's trophy saved.
		kind = if DataService.AddTrophy(player, record) then "Saved" else "AlreadyOwned"
	else
		local list = sessionTrophies[userId] or {}
		sessionTrophies[userId] = list
		table.insert(list, record)
		kind = "Unsaved"
	end
	CalebCycle.MarkTrophyClaimed(userId)
	notify(player, kind, if kind == "AlreadyOwned" then nil else record.Variant)
	if kind == "Unsaved" then
		refreshCase(player) -- saved ones refresh through TrophiesChanged
	end
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

	TycoonService.PurchaseApplied:Connect(function(player: Player, _plot: Model, purchaseId: string)
		if purchaseId == CASE_ID then
			refreshCase(player)
		end
	end)
	DataService.TrophiesChanged:Connect(refreshCase)

	local plots = Workspace:WaitForChild("Map"):WaitForChild("Plots")
	for _, plot in plots:GetChildren() do
		local case = plot:FindFirstChild(CASE_ID)
		for slot = 1, Config.TrophyCaseSlots do
			if case and not case:FindFirstChild(`TrophySlot{slot}`) then
				warn(`TrophyService: {plot.Name}.{CASE_ID} is missing TrophySlot{slot}`)
			end
		end
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			if plot:GetAttribute("OwnerUserId") == nil then
				TrophyCaseDisplay.Clear(plot) -- released
			end
		end)
	end
end

return TrophyService
