-- StatueService (server only)
-- Owns feeding the statue (Caleb, Workspace.Map.Statue).
--
-- * Players stand on one of the statue's FeedPads, type an amount in the
--   feed prompt (FeedPrompt.client.luau), and the client invokes the
--   ReplicatedStorage.Remotes.FeedStatue RemoteFunction with that amount.
-- * This service decides everything: the amount must be a whole number >= 1,
--   the player must be standing near a feed pad, must not be spamming, and
--   must be able to afford it. Cookies are spent only through
--   EconomyService.TrySpend.
-- * Total cookies eaten is shared by all players for this server session (no
--   saving yet). It is mirrored into the statue's "CookiesEaten" attribute so
--   clients can show it. Caleb stops eating at CalebEvent.MaxCookies(); a
--   bigger feed only spends what he still has room for.
-- * The more he has eaten, the fatter and bigger he gets: StatueShape.Apply
--   with progress = eaten / CalebEvent.MaxCookies().

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local EconomyService = require(script.Parent.EconomyService)
local StatueShape = require(script.Parent.StatueShape)

local StatueService = {}

local statue: Model? = nil
local pads: { BasePart } = {}
local eaten = 0
local lastFeed: { [Player]: number } = {}

local function isNearPad(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	for _, pad in pads do
		local offset = root.Position - pad.Position
		local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
		if flat <= Config.StatueFeedRange and math.abs(offset.Y) <= 10 then
			return true
		end
	end
	return false
end

local function setPadLabels(text: string)
	for _, pad in pads do
		local label = pad:FindFirstChild("TextLabel", true)
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
end

-- Handles one feed request. Returns (true, cookiesEaten) or (false, reason).
-- Every argument is untrusted.
local function onFeed(player: Player, amount: any): (boolean, number | string)
	if typeof(amount) ~= "number" or amount ~= amount or amount < 1 or amount ~= math.floor(amount) then
		return false, "Type a whole number of cookies."
	end

	local now = os.clock()
	if lastFeed[player] and now - lastFeed[player] < Config.StatueFeedCooldown then
		return false, "Slow down! Caleb is still chewing."
	end
	lastFeed[player] = now

	if not statue or not isNearPad(player) then
		return false, "Stand on a feed pad first."
	end

	local room = CalebEvent.MaxCookies() - eaten
	if room <= 0 then
		return false, `{Config.StatueName} is FULL!`
	end
	local cookies = math.min(amount, room)
	if not EconomyService.TrySpend(player, cookies) then
		return false, "You don't have that many cookies!"
	end

	eaten += cookies
	statue:SetAttribute("CookiesEaten", eaten)
	StatueShape.Apply(eaten / CalebEvent.MaxCookies(), Config.CalebGrowSeconds)
	if eaten >= CalebEvent.MaxCookies() then
		setPadLabels(`{string.upper(Config.StatueName)} IS FULL!`)
	end
	return true, cookies
end

-- Called once by ServerMain.
function StatueService.Start()
	local found = Workspace:WaitForChild("Map"):FindFirstChild("Statue")
	if not found or not found:IsA("Model") then
		warn("StatueService: Workspace.Map.Statue is missing; feeding is off")
		return
	end
	statue = found

	local padFolder = found:FindFirstChild("FeedPads")
	if padFolder then
		for _, pad in padFolder:GetChildren() do
			if pad:IsA("BasePart") then
				table.insert(pads, pad)
			end
		end
	end
	if #pads == 0 then
		warn("StatueService: the statue has no FeedPads; nobody can feed it")
	end

	StatueShape.Setup(found)
	StatueShape.Apply(0, 0)
	found:SetAttribute("CookiesEaten", 0)
	setPadLabels(`FEED {string.upper(Config.StatueName)}!`)

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FeedStatue") :: RemoteFunction
	remote.OnServerInvoke = onFeed
end

-- Called by ServerMain when a player leaves.
function StatueService.OnPlayerRemoving(player: Player)
	lastFeed[player] = nil
end

return StatueService
