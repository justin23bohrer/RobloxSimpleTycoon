-- PowerService (server only)
-- Holds each player's active Caleb Trophy powers (the capped totals from
-- TrophyPowers.Compute) and applies the movement ones.
--
-- * TrophyService calls SetDisplayed(player, variantIds) whenever what the
--   player's built Trophy Case displays changes (empty list = no powers).
--   That recomputes the totals, publishes the player attributes
--   "TrophyStats" (JSON { [Stat] = total }) and "CanDoubleJump" (boolean),
--   and re-applies WalkSpeed / JumpHeight to the current character.
-- * Get(player, stat) is the total bonus for one stat (0 if none). Production
--   (DropperService, CollectorService) reads it for the plot owner.
-- * Movement: Humanoid.WalkSpeed = base * (1 + WalkSpeed bonus) and
--   Humanoid.JumpHeight = base * (1 + JumpHeight bonus). The base is the
--   character's own value when it spawned (saved on the Humanoid as
--   attributes), so re-applying never compounds. The Humanoid is switched to
--   JumpHeight (UseJumpPower = false). CharacterAdded re-applies on respawn.
-- * Character physics is client-owned in Roblox, so movement bonuses (and
--   DoubleJump.client's double jump) are presentation-level: an exploiter
--   could move faster anyway. Cookie values stay fully server-side.
--
-- Requires only Shared modules and PlotPowerVisuals (which shows the powers on
-- the owner's plot; it requires Shared only). Never TycoonService: that would
-- be a require cycle.
-- Event-driven: no loops.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrophyPowers = require(ReplicatedStorage.Shared.TrophyPowers)
local PlotPowerVisuals = require(script.Parent.PlotPowerVisuals)

local PowerService = {}

local Stat = TrophyPowers.Stat
local STATS_ATTR = "TrophyStats"
local DOUBLE_JUMP_ATTR = "CanDoubleJump"
-- Saved on the Humanoid: its own values before any trophy bonus.
local BASE_WALK_ATTR = "BaseWalkSpeed"
local BASE_JUMP_ATTR = "BaseJumpHeight"

local totalsByPlayer: { [Player]: { [string]: number } } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}

local function applyMovement(player: Player, character: Model?)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local baseWalk = humanoid:GetAttribute(BASE_WALK_ATTR)
	if type(baseWalk) ~= "number" then
		baseWalk = humanoid.WalkSpeed
		humanoid:SetAttribute(BASE_WALK_ATTR, baseWalk)
	end
	local baseJump = humanoid:GetAttribute(BASE_JUMP_ATTR)
	if type(baseJump) ~= "number" then
		baseJump = humanoid.JumpHeight
		humanoid:SetAttribute(BASE_JUMP_ATTR, baseJump)
	end
	humanoid.UseJumpPower = false
	humanoid.WalkSpeed = baseWalk * (1 + PowerService.Get(player, Stat.WalkSpeed))
	humanoid.JumpHeight = baseJump * (1 + PowerService.Get(player, Stat.JumpHeight))
end

local function publish(player: Player)
	local totals = totalsByPlayer[player] or {}
	player:SetAttribute(STATS_ATTR, HttpService:JSONEncode(totals))
	player:SetAttribute(DOUBLE_JUMP_ATTR, (totals[Stat.DoubleJump] or 0) > 0)
end

-- The player's total bonus for one stat (already capped), or 0.
function PowerService.Get(player: Player, stat: string): number
	local totals = totalsByPlayer[player]
	return totals and totals[stat] or 0
end

-- Sets which trophy definitions the player has on display (variant ids, in
-- any order; repeats count once). Called by TrophyService.
function PowerService.SetDisplayed(player: Player, variantIds: { string })
	if player.Parent == nil then
		return -- left the game; nothing to keep
	end
	totalsByPlayer[player] = TrophyPowers.Compute(variantIds)
	publish(player)
	applyMovement(player, player.Character)
	PlotPowerVisuals.Apply(player, totalsByPlayer[player]) -- fire on droppers, shine on the Collect pad
end

-- Called by ServerMain when a player joins.
function PowerService.OnPlayerAdded(player: Player)
	if characterConnections[player] then
		return -- already set up
	end
	if not totalsByPlayer[player] then
		totalsByPlayer[player] = {}
	end
	publish(player)
	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		if player.Character == character then
			applyMovement(player, character)
		end
	end)
	if player.Character then
		applyMovement(player, player.Character)
	end
end

-- Called by ServerMain when a player leaves.
function PowerService.OnPlayerRemoving(player: Player)
	totalsByPlayer[player] = nil
	local connection = characterConnections[player]
	if connection then
		connection:Disconnect()
		characterConnections[player] = nil
	end
end

return PowerService
