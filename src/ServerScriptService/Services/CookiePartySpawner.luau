-- CookiePartySpawner (server helper)
-- Used only by CookiePartyService. Picks a collectable cookie's type and
-- where it lands (a ground spot found by a downward raycast). Creates no
-- parts and changes nothing; it only answers questions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CalebBody = require(ReplicatedStorage.Shared.CalebBody)
local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)

-- Rays start this many studs above the statue's base (above every roof).
local RAY_HEIGHT = 200
-- Parts at least this transparent (spawn areas, barriers) are skipped.
local INVISIBLE = 0.95
-- Tries to find a spot that is not on Caleb before giving up for this cookie.
local SPOT_TRIES = 4

local CookiePartySpawner = {}

local statue: Instance? = nil
local center = Vector3.zero
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

-- Statue center at ground level (bottom of PedestalBase), like CookieRain.
function CookiePartySpawner.Setup(statueModel: Instance)
	statue = statueModel
	local base = statueModel:FindFirstChild("PedestalBase")
	if base and base:IsA("BasePart") then
		center = base.Position - Vector3.new(0, base.Size.Y / 2, 0)
	elseif statueModel:IsA("Model") then
		center = statueModel:GetPivot().Position
	end
end

-- Call once per spawn tick: rays ignore players' characters.
function CookiePartySpawner.BeginTick()
	local characters = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	rayParams.FilterDescendantsInstances = characters
end

-- A weighted random type for this phase (stable order: CookieParty.Types).
function CookiePartySpawner.PickType(phase: string): string
	local total = 0
	for _, name in CookieParty.Types do
		total += Config.CookiePartyTypes[name].Weights[phase] or 0
	end
	local roll = math.random() * total
	for _, name in CookieParty.Types do
		local weight = Config.CookiePartyTypes[name].Weights[phase] or 0
		if weight > 0 and roll < weight then
			return name
		end
		roll -= weight
	end
	return CookieParty.Types[1]
end

-- Random root part of a player who has a character, or nil.
local function randomRoot(): BasePart?
	local roots = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			table.insert(roots, root)
		end
	end
	return if #roots > 0 then roots[math.random(#roots)] else nil
end

-- A random (X, Z) in the party circle, often near a random player.
local function pickXZ(): (number, number)
	local radius = Config.CookiePartySpawnRadius
	local root = math.random() < Config.CookiePartyNearPlayerShare and randomRoot()
	if root then
		local angle = math.random() * 2 * math.pi
		local dist = Config.CookiePartyNearPlayerRadius * math.sqrt(math.random())
		local x = root.Position.X + math.cos(angle) * dist
		local z = root.Position.Z + math.sin(angle) * dist
		if (Vector2.new(x, z) - Vector2.new(center.X, center.Z)).Magnitude <= radius then
			return x, z
		end
	end
	local angle = math.random() * 2 * math.pi
	local dist = radius * math.sqrt(math.random()) -- uniform over the disc
	return center.X + math.cos(angle) * dist, center.Z + math.sin(angle) * dist
end

-- Ground height under (x, z): the first visible surface. nil if that
-- surface is Caleb himself (cookies would sit on his head).
local function landingY(x: number, z: number): number?
	local origin = Vector3.new(x, center.Y + RAY_HEIGHT, z)
	for _ = 1, 3 do
		local hit = Workspace:Raycast(origin, Vector3.new(0, center.Y - RAY_HEIGHT - origin.Y, 0), rayParams)
		if not hit then
			break
		end
		if statue and CalebBody.IsBodyPart(statue, hit.Instance) then
			return nil
		end
		if hit.Instance.Transparency < INVISIBLE then
			return hit.Position.Y
		end
		origin = hit.Position - Vector3.new(0, 0.05, 0)
	end
	return center.Y -- nothing visible: ground level
end

-- Where a new cookie lands, or nil if no good spot was found this time.
function CookiePartySpawner.PickSpot(): Vector3?
	for _ = 1, SPOT_TRIES do
		local x, z = pickXZ()
		local y = landingY(x, z)
		if y then
			return Vector3.new(x, y, z)
		end
	end
	return nil
end

return CookiePartySpawner
