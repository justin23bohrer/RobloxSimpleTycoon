-- PushService (server only)
-- The defender's push (ARCHITECTURE.md "House Raid (contract)", Push).
-- Handles the PushRequest remote (no arguments; nothing from the client is
-- trusted): checks the cooldown and that the pusher is alive, then picks the
-- closest other living player within Config.PushRange in front of the
-- pusher (inside a Config.PushFacingAngle cone around the root's LookVector).
--
-- Every push fires PushFX(pusherUserId, targetUserId?, stoppedThief) to all
-- clients (arm swing, hit burst, sounds). On a hit:
--   * a target carrying a stolen trophy -> TheftService.StopThief(target,
--     pusher) (the trophy goes home) and the full knockback + stagger;
--   * anyone else -> only a small nudge (Config.PushNudgeMultiplier).
-- The knockback is sent to the target with PushKnockback(velocity, stagger):
-- characters are client-owned, so the target's client applies it.
-- No damage, no health, no weapons: pushing never changes cash or ownership.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseRaid = require(ReplicatedStorage.Shared.HouseRaid)
local TheftService = require(script.Parent.TheftService)

local PushService = {}

-- Network jitter: a client that waits exactly Config.PushCooldown can have
-- two presses arrive a little closer together than that.
local COOLDOWN_GRACE = 0.15

local lastPushAt: { [Player]: number } = {}

local function aliveRoot(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return nil, nil
	end
	if not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return root, humanoid
end

-- The closest living player in range and in front of the pusher, or nil.
local function findTarget(pusher: Player, pusherRoot: BasePart): (Player?, BasePart?)
	local origin = pusherRoot.Position
	local look = pusherRoot.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	flatLook = if flatLook.Magnitude > 1e-3 then flatLook.Unit else Vector3.zAxis * -1
	local minDot = math.cos(math.rad(Config.PushFacingAngle))

	local best: Player? = nil
	local bestRoot: BasePart? = nil
	local bestDistance = math.huge
	for _, other in Players:GetPlayers() do
		if other ~= pusher then
			local root = aliveRoot(other)
			if root then
				local offset = root.Position - origin
				local distance = offset.Magnitude
				local flat = Vector3.new(offset.X, 0, offset.Z)
				-- Standing (almost) on top of each other counts as in front.
				local inFront = flat.Magnitude < 0.5 or flat.Unit:Dot(flatLook) >= minDot
				if distance <= Config.PushRange and inFront and distance < bestDistance then
					best, bestRoot, bestDistance = other, root, distance
				end
			end
		end
	end
	return best, bestRoot
end

-- Away from the pusher (horizontal) plus a little up, scaled down for a nudge.
local function knockbackVelocity(pusherRoot: BasePart, targetRoot: BasePart, scale: number): Vector3
	local offset = targetRoot.Position - pusherRoot.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 0.5 then
		local look = pusherRoot.CFrame.LookVector
		flat = Vector3.new(look.X, 0, look.Z)
	end
	local direction = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zAxis * -1
	return (direction * Config.PushKnockbackSpeed + Vector3.yAxis * Config.PushKnockbackUp) * scale
end

local function onPushRequest(pusher: Player)
	local now = os.clock()
	local last = lastPushAt[pusher]
	if last and now - last < Config.PushCooldown - COOLDOWN_GRACE then
		return -- too soon: ignored silently
	end
	local pusherRoot = aliveRoot(pusher)
	if not pusherRoot then
		return
	end
	lastPushAt[pusher] = now

	local target, targetRoot = findTarget(pusher, pusherRoot)
	if not target or not targetRoot then
		HouseRaid.GetRemote(HouseRaid.Remote.PushFX):FireAllClients(pusher.UserId, nil, false)
		return
	end

	local stopped = TheftService.IsCarrying(target) and TheftService.StopThief(target, pusher)
	local scale = if stopped then 1 else Config.PushNudgeMultiplier
	HouseRaid.GetRemote(HouseRaid.Remote.Knockback)
		:FireClient(target, knockbackVelocity(pusherRoot, targetRoot, scale), stopped)
	HouseRaid.GetRemote(HouseRaid.Remote.PushFX):FireAllClients(pusher.UserId, target.UserId, stopped)
end

-- Called once by ServerMain.
function PushService.Start()
	HouseRaid.GetRemote(HouseRaid.Remote.Push).OnServerEvent:Connect(onPushRequest)
end

function PushService.OnPlayerRemoving(player: Player)
	lastPushAt[player] = nil
end

return PushService
