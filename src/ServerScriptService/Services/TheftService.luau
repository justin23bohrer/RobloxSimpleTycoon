-- TheftService (server only)
-- Owns trophy thefts (ARCHITECTURE.md "House Raid (contract)" -> Stealing):
-- the StealPrompt on displayed trophies, the carrying state, the escape at
-- the thief's own TrophyStash with the permanent transfer, and every way a
-- theft is stopped. Exactly one owner at all times.
--
-- * Start (a StealPrompt triggered; TrophyCaseDisplay.StealTriggered):
--   TheftRules.Check: the trophy is displayed in its owner's case right now
--   (the model is in the owner's plot, the owner is here and has it
--   equipped, it isn't already carried), the house isn't protected
--   (HouseSecurityService.IsProtected), and the thief isn't the owner, isn't
--   carrying, is alive and within range, has a house with a shown stash, and
--   can receive it (TheftTransfer.CanReceive). Nothing yields between these
--   checks and marking the trophy in transit, so two thieves can't both take
--   it. Then the trophy leaves the owner's case (DisplayChanged -> TrophyService
--   skips IsInTransit ids for display and powers), rides over the thief's head
--   (TheftCarry), the thief's CarryingTrophy attribute is set, and all their
--   trophy powers are off (PowerService.SetSuppressed). Saved data is untouched.
-- * Stopped (StopThief from a push, the thief dies / respawns / leaves, their
--   plot is gone, the owner's trophy record disappears, or the anti-teleport
--   check fails): the trophy goes straight back to its owner's case.
-- * Escaped (the thief stands on their OWN TrophyStash): state flips to
--   "Transferring" first (a push in the same frame can't also return it), then
--   TheftTransfer moves the trophy for good. If that fails the trophy stays
--   the owner's and the thief gets a short TheftNotice.
-- Every theft ends in finish(): carried model, connections and attribute
-- removed, powers back.
--
-- Requires DataService, PowerService, TheftCarry, TheftRules (->
-- HouseSecurityService), TheftTransfer, TrophyCaseDisplay, TrophyInventory,
-- TycoonService. Never TrophyService (it requires this module: a cycle).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseRaid = require(ReplicatedStorage.Shared.HouseRaid)
local DataSchema = require(script.Parent.DataSchema)
local DataService = require(script.Parent.DataService)
local PowerService = require(script.Parent.PowerService)
local TheftCarry = require(script.Parent.TheftCarry)
local TheftRules = require(script.Parent.TheftRules)
local TheftTransfer = require(script.Parent.TheftTransfer)
local TrophyCaseDisplay = require(script.Parent.TrophyCaseDisplay)
local TrophyInventory = require(script.Parent.TrophyInventory)
local TycoonService = require(script.Parent.TycoonService)

local TheftService = {}

type Theft = {
	Thief: Player,
	FromUserId: number,
	Record: DataSchema.TrophyRecord,
	State: string, -- "Carrying", "Transferring" (only the transfer can end it), "Done"
	Stash: Instance?, -- the thief's TrophyStash (nil if the map has none)
	Model: Model?,
	Tracker: TheftCarry.Tracker,
	Connections: { RBXScriptConnection },
}

local byThief: { [Player]: Theft } = {}
local byInstance: { [string]: Theft } = {}
local noticeId = 0

local displayChanged = Instance.new("BindableEvent")
-- Fires (userId) when that player's case or powers may have changed (a
-- trophy left, came back, or changed hands). TrophyService refreshes them.
TheftService.DisplayChanged = displayChanged.Event

local function notify(player: Player, text: string)
	noticeId += 1
	player:SetAttribute(HouseRaid.PlayerAttr.TheftNotice, HttpService:JSONEncode({ Id = noticeId, Text = text }))
end

-- Ends a theft exactly once, whatever happened: the carried trophy goes,
-- the trophy is back in its owner's case unless it was transferred (then it
-- is the thief's), and the thief's powers come back.
local function finish(theft: Theft)
	if theft.State == "Done" then
		return
	end
	theft.State = "Done"
	byThief[theft.Thief] = nil
	byInstance[theft.Record.InstanceId] = nil
	for _, connection in theft.Connections do
		connection:Disconnect()
	end
	table.clear(theft.Connections)
	TheftCarry.Detach(theft.Model)
	theft.Model = nil
	theft.Thief:SetAttribute(HouseRaid.PlayerAttr.Carrying, nil)
	PowerService.SetSuppressed(theft.Thief, false)
	displayChanged:Fire(theft.FromUserId)
	displayChanged:Fire(theft.Thief.UserId)
end

local function stop(theft: Theft)
	if theft.State == "Carrying" then
		finish(theft)
	end
end

-- The thief is on their stash: transfer for good (may yield, offline owner).
local function escape(theft: Theft)
	theft.State = "Transferring" -- first: nothing else can end it now
	local ran, ok, message = pcall(TheftTransfer.Run, theft.Thief, theft.FromUserId, theft.Record)
	if not ran then
		warn(`TheftService: transfer of {theft.Record.InstanceId} failed: {ok}`)
		ok, message = false, "Couldn't take the trophy right now, so it went back to its owner."
	end
	if not ok and message and theft.Thief.Parent == Players then
		notify(theft.Thief, message)
	end
	finish(theft)
end

-- Does the owner still have it? Unknown (true) while their data isn't here:
-- the transfer re-checks their saved key.
local function stillOwned(theft: Theft): boolean
	local instanceId = theft.Record.InstanceId
	if TrophyInventory.FindSessionTrophy(theft.FromUserId, instanceId) then
		return true
	end
	local owner = Players:GetPlayerByUserId(theft.FromUserId)
	if not owner or not DataService.IsLoaded(owner) then
		return true
	end
	for _, record in DataService.GetTrophies(owner) do
		if record.InstanceId == instanceId then
			return true
		end
	end
	return false
end

-- Every frame while carrying: alive, still has a plot, not teleporting, on
-- the stash yet?
local function step(theft: Theft, character: Model, humanoid: Humanoid, root: BasePart)
	if theft.State ~= "Carrying" then
		return
	end
	local thief = theft.Thief
	if thief.Character ~= character or humanoid.Health <= 0 or not root:IsDescendantOf(Workspace) then
		stop(theft)
		return
	end
	if not TycoonService.GetTycoon(thief) then
		stop(theft) -- their own plot is gone: nowhere to bring it
		return
	end
	local maxSpeed = humanoid.WalkSpeed + Config.TheftMoveSlack -- WalkSpeed: the server's carry speed
	if TheftCarry.MovedTooFast(theft.Tracker, root.Position, os.clock(), maxSpeed) then
		stop(theft)
		return
	end
	local stash = theft.Stash
	if stash and stash.Parent and TheftCarry.IsShown(stash) and TheftCarry.IsOnStash(stash, root.Position) then
		task.spawn(escape, theft)
	end
end

local function begin(thief: Player, start: TheftRules.Start)
	local record, fromUserId, humanoid, root = start.Record, start.FromUserId, start.Humanoid, start.Root
	local character = start.Character
	local theft: Theft = {
		Thief = thief,
		FromUserId = fromUserId,
		Record = record,
		State = "Carrying",
		Stash = start.Stash,
		Model = nil,
		Tracker = TheftCarry.NewTracker(root.Position, os.clock()),
		Connections = {},
	}
	byThief[thief] = theft
	byInstance[record.InstanceId] = theft
	PowerService.SetSuppressed(thief, true)
	theft.Model = TheftCarry.Attach(character, record.Variant)
	thief:SetAttribute(HouseRaid.PlayerAttr.Carrying, HttpService:JSONEncode({
		Variant = record.Variant,
		InstanceId = record.InstanceId,
		FromUserId = fromUserId,
	}))
	displayChanged:Fire(fromUserId) -- leaves the owner's case; its power stops

	local connections = theft.Connections
	table.insert(connections, RunService.Heartbeat:Connect(function()
		step(theft, character, humanoid, root)
	end))
	table.insert(connections, humanoid.Died:Connect(function()
		stop(theft)
	end))
	table.insert(connections, thief.CharacterRemoving:Connect(function()
		stop(theft)
	end))
	table.insert(connections, DataService.TrophiesChanged:Connect(function(player: Player)
		if player.UserId == fromUserId and not stillOwned(theft) then
			stop(theft)
		end
	end))
end

-- A StealPrompt was held to the end. TheftRules re-checks everything; nothing
-- yields between its checks and recording the theft.
local function onStealTriggered(thief: Player, trophy: Model)
	local start, message = TheftRules.Check(thief, trophy, TheftService.IsCarrying, TheftService.IsInTransit)
	if start then
		begin(thief, start)
	elseif message then
		notify(thief, message)
	end
end

-- Called once by ServerMain after TrophyService.Start().
function TheftService.Start()
	TrophyCaseDisplay.StealTriggered:Connect(onStealTriggered)
end

-- True while this player carries a stolen trophy (also while it is being
-- transferred at their stash).
function TheftService.IsCarrying(player: Player): boolean
	return byThief[player] ~= nil
end

-- A push hit the thief: cancel the theft and return the trophy to its owner's
-- display. Returns true if a theft was cancelled (false if not carrying, or
-- the theft already finished this frame). Called by PushService.
function TheftService.StopThief(thief: Player, _byPlayer: Player?): boolean
	local theft = byThief[thief]
	if not theft or theft.State ~= "Carrying" then
		return false
	end
	finish(theft)
	return true
end

-- True if this trophy instance is being carried right now (not displayed,
-- gives its owner no power until it is back). Used by TrophyService.
function TheftService.IsInTransit(instanceId: string): boolean
	return byInstance[instanceId] ~= nil
end

-- A thief who leaves: the trophy goes home (unless it is already being
-- transferred at their stash: DataService's leave save waits for that). An
-- owner who leaves: their trophy's theft goes on.
function TheftService.OnPlayerRemoving(player: Player)
	local theft = byThief[player]
	if theft then
		stop(theft)
	end
end

return TheftService
