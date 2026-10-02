-- CookiePartyReach (server only, helper for CookiePartyService)
-- Decides whether a player is close enough to a party cookie to collect it,
-- using only what the server sees (never a position sent by the client).
--
-- The server sees a moving character late (replication lag): a player with
-- big WalkSpeed powers is many studs further on, on their own screen, than
-- the server thinks when the collect request arrives, and the request may
-- even arrive after the server already saw them run past. So:
--   * While the party runs, every Heartbeat records each player's
--     HumanoidRootPart position; the last Config.CookiePartyCollectHistorySeconds
--     are kept. The player's path = those samples + the current position.
--   * Horizontal reach = CollectRadius + CookiePartyCollectSlack + lag slack,
--     lag slack = min(current horizontal speed x CookiePartyCollectLagSeconds,
--     CookiePartyCollectLagSlackMax). Only a moving player gets it (the
--     server sees a player who stands still where they really are), so a
--     standing player's reach stays tight; a player who just stopped is
--     covered by the path.
--   * Vertical reach = CookieParty.VerticalReach (jump powers count).
--   * In reach if any point of the path is within both. A step longer than
--     CookiePartyCollectMaxStep (teleport, respawn) is not a path: only its
--     ends count.
-- Start() / Stop() follow the party; Forget(player) on leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)

type Sample = { T: number, P: Vector3 }
type History = { Root: BasePart, Samples: { Sample } }

local CookiePartyReach = {}

local histories: { [Player]: History } = {}
local heartbeat: RBXScriptConnection? = nil

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function record()
	local now = os.clock()
	local oldest = now - Config.CookiePartyCollectHistorySeconds
	for _, player in Players:GetPlayers() do
		local root = getRoot(player)
		local history = histories[player]
		if not root then
			histories[player] = nil
			continue
		end
		if not history or history.Root ~= root then
			history = { Root = root, Samples = {} } -- new character: new path
			histories[player] = history
		end
		local samples = history.Samples
		table.insert(samples, { T = now, P = root.Position })
		while #samples > 1 and samples[1].T < oldest do
			table.remove(samples, 1)
		end
	end
end

-- True if the segment a..b passes within `radius` (horizontal) and `vertical`
-- (at that point) of `target`.
local function segmentInReach(a: Vector3, b: Vector3, target: Vector3, radius: number, vertical: number): boolean
	local abx, abz = b.X - a.X, b.Z - a.Z
	local lengthSq = abx * abx + abz * abz
	local t = 0
	if lengthSq > 1e-6 then
		t = math.clamp(((target.X - a.X) * abx + (target.Z - a.Z) * abz) / lengthSq, 0, 1)
	end
	local point = a:Lerp(b, t)
	local dx, dz = point.X - target.X, point.Z - target.Z
	return dx * dx + dz * dz <= radius * radius and math.abs(point.Y - target.Y) <= vertical
end

-- Starts recording positions (party start). Safe to call twice.
function CookiePartyReach.Start()
	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(record)
	end
end

-- Stops recording and forgets every path (party end).
function CookiePartyReach.Stop()
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	histories = {}
end

function CookiePartyReach.Forget(player: Player)
	histories[player] = nil
end

-- True if the player's character is (or just was) close enough to collect a
-- cookie at `target` with this CollectRadius.
function CookiePartyReach.InReach(
	player: Player,
	root: BasePart,
	humanoid: Humanoid,
	target: Vector3,
	collectRadius: number
): boolean
	local velocity = root.AssemblyLinearVelocity
	local speed = Vector2.new(velocity.X, velocity.Z).Magnitude
	local lagSlack = math.min(speed * Config.CookiePartyCollectLagSeconds, Config.CookiePartyCollectLagSlackMax)
	local radius = collectRadius + Config.CookiePartyCollectSlack + lagSlack
	local vertical = CookieParty.VerticalReach(player, humanoid)

	local current = root.Position
	local history = histories[player]
	local samples = if history and history.Root == root then history.Samples else {}
	local maxStepSq = Config.CookiePartyCollectMaxStep * Config.CookiePartyCollectMaxStep
	local previous: Vector3? = nil
	for i = 1, #samples + 1 do
		local point = if i <= #samples then samples[i].P else current
		local from = previous or point
		if (point - from).Magnitude ^ 2 > maxStepSq then
			from = point -- teleport/respawn: not a path, only the end counts
		end
		if segmentInReach(from, point, target, radius, vertical) then
			return true
		end
		previous = point
	end
	return false
end

return CookiePartyReach
