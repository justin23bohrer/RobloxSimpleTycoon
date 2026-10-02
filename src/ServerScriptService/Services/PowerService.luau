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
-- * Glowing feet: whenever movement is applied, PowerVisuals.SetSpeedGlow
--   shows (WalkSpeed bonus > 0) or removes (0) the glow on the character's
--   feet; it is made here on the server so every player sees it.
-- * Character physics is client-owned in Roblox, so movement bonuses (and
--   DoubleJump.client's double jump) are presentation-level: an exploiter
--   could move faster anyway. Cookie values stay fully server-side.
--
-- * Plot visuals: SetDisplayed also calls PlotPowerVisuals.Apply, which shows
--   the production / collect powers on the owner's plot (fire on dropper
--   cups, luck sparkles, a gold ring on the Collect pad).
-- * Suppression (House Raid): while TheftService has SetSuppressed(player,
--   true) (the player carries a stolen trophy), every power is off: Get
--   returns 0 for every stat (so DropperService / CollectorService bonuses
--   stop too), TrophyStats is {} and CanDoubleJump false, WalkSpeed is the
--   base x Config.TheftCarrySpeedMultiplier, JumpHeight the base, no glowing
--   feet, and no plot effects. The displayed totals are kept, so
--   SetSuppressed(player, false) brings back exactly what is displayed.
--
-- Requires only Shared modules and two presentation helpers: PowerVisuals
-- (glowing feet; requires Config only) and PlotPowerVisuals (plot effects;
-- requires Shared only). Never TycoonService: that would be a require cycle.
-- Event-driven: no loops.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TrophyPowers = require(ReplicatedStorage.Shared.TrophyPowers)
local PowerVisuals = require(script.Parent.PowerVisuals)
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
local suppressed: { [Player]: true } = {} -- carrying a stolen trophy: no powers

-- What is active right now: the displayed totals, or nothing while suppressed.
local function activeTotals(player: Player): { [string]: number }
	return if suppressed[player] then {} else totalsByPlayer[player] or {}
end

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
	local walkFactor = if suppressed[player]
		then Config.TheftCarrySpeedMultiplier
		else 1 + PowerService.Get(player, Stat.WalkSpeed)
	humanoid.WalkSpeed = baseWalk * walkFactor
	humanoid.JumpHeight = baseJump * (1 + PowerService.Get(player, Stat.JumpHeight))
	PowerVisuals.SetSpeedGlow(character, PowerService.Get(player, Stat.WalkSpeed))
end

local function watchCharacter(player: Player, character: Model)
	PowerVisuals.Watch(player, character, function()
		return PowerService.Get(player, Stat.WalkSpeed)
	end)
end

local function publish(player: Player)
	local totals = activeTotals(player)
	player:SetAttribute(STATS_ATTR, HttpService:JSONEncode(totals))
	player:SetAttribute(DOUBLE_JUMP_ATTR, (totals[Stat.DoubleJump] or 0) > 0)
end

-- The player's total bonus for one stat (already capped), or 0 (also 0 for
-- every stat while suppressed).
function PowerService.Get(player: Player, stat: string): number
	return activeTotals(player)[stat] or 0
end

-- Republishes the attributes, movement, feet glow and plot effects from the
-- active totals.
local function applyAll(player: Player)
	publish(player)
	applyMovement(player, player.Character)
	PlotPowerVisuals.Apply(player, activeTotals(player)) -- fire on droppers, shine on the Collect pad
end

-- Sets which trophy definitions the player has on display (variant ids, in
-- any order; repeats count once). Called by TrophyService.
function PowerService.SetDisplayed(player: Player, variantIds: { string })
	if player.Parent == nil then
		return -- left the game; nothing to keep
	end
	totalsByPlayer[player] = TrophyPowers.Compute(variantIds)
	applyAll(player)
end

-- Server only (TheftService): true turns every trophy power of the player off
-- (carry speed, no double jump, no production / collect bonus, no effects);
-- false brings back exactly what their case displays. Idempotent.
function PowerService.SetSuppressed(player: Player, on: boolean)
	if (suppressed[player] == true) == on then
		return -- already that way
	end
	suppressed[player] = if on then true else nil
	if player.Parent ~= nil then -- a player who left gets nothing applied
		applyAll(player)
	end
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
			watchCharacter(player, character)
			applyMovement(player, character)
		end
	end)
	if player.Character then
		watchCharacter(player, player.Character)
		applyMovement(player, player.Character)
	end
end

-- Called by ServerMain when a player leaves.
function PowerService.OnPlayerRemoving(player: Player)
	totalsByPlayer[player] = nil
	suppressed[player] = nil
	local connection = characterConnections[player]
	if connection then
		connection:Disconnect()
		characterConnections[player] = nil
	end
	PowerVisuals.Forget(player)
end

return PowerService
