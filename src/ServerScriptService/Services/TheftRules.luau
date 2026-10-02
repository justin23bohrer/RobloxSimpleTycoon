-- TheftRules (server only)
-- Helper for TheftService: may this player start stealing this displayed
-- trophy? Every check uses server data only (the prompt trigger and the
-- model's attributes are just a hint). Reads, never changes anything, and
-- never yields, so TheftService can record the theft in the same step.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseRaid = require(ReplicatedStorage.Shared.HouseRaid)
local DataSchema = require(script.Parent.DataSchema)
local HouseSecurityService = require(script.Parent.HouseSecurityService)
local TheftCarry = require(script.Parent.TheftCarry)
local TheftTransfer = require(script.Parent.TheftTransfer)
local TrophyInventory = require(script.Parent.TrophyInventory)
local TycoonService = require(script.Parent.TycoonService)

local TheftRules = {}

-- Network delay between the client's prompt and the server's position.
local RANGE_SLACK = 4

export type Start = {
	FromUserId: number,
	Record: DataSchema.TrophyRecord,
	Character: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Stash: Instance?, -- the thief's TrophyStash (nil if the map has none)
}

local warnedNoStash = false

-- Returns what the theft needs, or nil and (maybe) a short message for the
-- thief. `isCarrying` / `isInTransit` are TheftService's own state.
function TheftRules.Check(
	thief: Player,
	trophy: Model,
	isCarrying: (Player) -> boolean,
	isInTransit: (string) -> boolean
): (Start?, string?)
	local fromUserId = trophy:GetAttribute(HouseRaid.TrophyAttr.OwnerUserId)
	local instanceId = trophy:GetAttribute(HouseRaid.TrophyAttr.InstanceId)
	if typeof(fromUserId) ~= "number" or typeof(instanceId) ~= "string" or fromUserId == thief.UserId then
		return nil -- not a case trophy, or your own
	end
	if thief.Parent ~= Players or isInTransit(instanceId) then
		return nil -- leaving, or someone is already carrying it
	end
	if isCarrying(thief) then
		return nil, "You're already carrying a trophy!"
	end

	-- Displayed right now: in the owner's plot, owned and equipped by them.
	local owner = Players:GetPlayerByUserId(fromUserId)
	local ownerTycoon = owner and TycoonService.GetTycoon(owner)
	if not owner or not ownerTycoon or not trophy:IsDescendantOf(ownerTycoon.Plot) then
		return nil
	end
	if not table.find(TrophyInventory.GetEquipped(owner), instanceId) then
		return nil
	end
	local record = nil
	for _, owned in TrophyInventory.GetOwned(owner) do
		if owned.InstanceId == instanceId then
			record = owned
		end
	end
	if not record then
		return nil
	end
	if HouseSecurityService.IsProtected(ownerTycoon.Plot) then
		return nil, "The security bars are up! Wait for them to drop."
	end

	-- The thief: alive, close enough, and has somewhere to bring it.
	local character = thief.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not (root and root:IsA("BasePart")) then
		return nil
	end
	if (root.Position - trophy:GetPivot().Position).Magnitude > Config.TheftPromptDistance + RANGE_SLACK then
		return nil
	end
	local tycoon = TycoonService.GetTycoon(thief)
	if not tycoon then
		return nil, "Claim a house first: stolen trophies go to your Trophy Stash."
	end
	local stash, shown = TheftCarry.FindStash(tycoon.Plot)
	if stash and not shown then
		return nil, "Build your walls first: stolen trophies go to your Trophy Stash."
	elseif not stash and not warnedNoStash then
		warnedNoStash = true
		warn(`TheftService: {tycoon.Plot.Name} has no {HouseRaid.Part.TrophyStash}; stolen trophies can't be delivered`)
	end
	local sessionOnly = TrophyInventory.FindSessionTrophy(fromUserId, instanceId) ~= nil
	local ok, why = TheftTransfer.CanReceive(thief, record, sessionOnly)
	if not ok then
		return nil, why
	end
	return {
		FromUserId = fromUserId,
		Record = record,
		Character = character,
		Humanoid = humanoid,
		Root = root,
		Stash = stash,
	}
end

return TheftRules
