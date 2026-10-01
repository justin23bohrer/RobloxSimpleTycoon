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
-- * CalebCycle owns the shared total, contributions, and the Caleb Full
--   Event state. Feeding is refused unless CalebCycle.CanFeed() (Normal, room
--   left). A bigger feed only spends what Caleb still has room for (up to
--   CalebEvent.MaxCookies()); after the spend, CalebCycle.AddCookies records
--   it (and starts the event at the goal).
-- * Caleb's size follows progress = eaten / goal (StatueShape.Apply). He is
--   hidden during TrophyClaim and shrinks back on reset. Pad signs say
--   "FEED CALEB!" in Normal and "CALEB IS FULL!" otherwise.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local CalebCycle = require(script.Parent.CalebCycle)
local EconomyService = require(script.Parent.EconomyService)
local StatueShape = require(script.Parent.StatueShape)

local StatueService = {}

local statue: Model? = nil
local pads: { BasePart } = {}
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

-- CalebCycle keeps CookiesEaten up to date (set synchronously in AddCookies).
local function eatenNow(): number
	local eaten = statue and statue:GetAttribute(CalebEvent.Attr.CookiesEaten)
	return if typeof(eaten) == "number" then eaten else 0
end

local function feedText(): string
	return `FEED {string.upper(Config.StatueName)}!`
end

local function fullText(): string
	return `{string.upper(Config.StatueName)} IS FULL!`
end

local function setPadLabels(text: string)
	for _, pad in pads do
		local label = pad:FindFirstChild("TextLabel", true)
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
end

-- Map colors of each pad's parts (the pad, its ring) and sign panels, saved
-- at Start so a disabled pad goes back exactly as it was built.
local padPartColors: { [BasePart]: Color3 } = {}
local padSignColors: { [Frame]: Color3 } = {}

local function rememberPadColors()
	for _, pad in pads do
		padPartColors[pad] = pad.Color
		for _, item in pad:GetDescendants() do
			if item:IsA("BasePart") then
				padPartColors[item] = item.Color
			elseif item:IsA("Frame") and item.Name == "Panel" then
				padSignColors[item] = item.BackgroundColor3
			end
		end
	end
end

-- Gray pads while Caleb isn't eating; map colors when he is. Looks only:
-- the feed itself is refused by CalebCycle.CanFeed, and the client won't
-- open the pop-up.
local function setPadsEnabled(enabled: boolean)
	for part, color in padPartColors do
		local off = if table.find(pads, part) then Config.StatueFeedPadOffColor else Config.StatueFeedPadOffRingColor
		part.Color = if enabled then color else off
	end
	for panel, color in padSignColors do
		panel.BackgroundColor3 = if enabled then color else Config.StatueFeedPadOffSignColor
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

	-- Nothing below yields, so no other feed can run between the room check,
	-- the spend, and AddCookies: two feeds at once can't pass the goal.
	if not CalebCycle.CanFeed() then
		return false, `{Config.StatueName} is FULL!`
	end
	local max = CalebEvent.MaxCookies()
	local room = max - eatenNow()
	if room <= 0 then
		return false, `{Config.StatueName} is FULL!`
	end
	local cookies = math.min(amount, room)
	if not EconomyService.TrySpend(player, cookies) then
		return false, "You don't have that many cookies!"
	end

	CalebCycle.AddCookies(player, cookies)
	StatueShape.Apply(eatenNow() / max, Config.CalebGrowSeconds)
	return true, cookies
end

local function onStateChanged(state: string)
	local eating = state == CalebEvent.State.Normal
	setPadLabels(if eating then feedText() else fullText())
	setPadsEnabled(eating)
	if state == CalebEvent.State.TrophyClaim then
		if StatueShape.SetHidden then
			StatueShape.SetHidden(true)
		end
	elseif state == CalebEvent.State.Normal then
		-- A new cycle: Caleb comes back at his smallest size.
		if StatueShape.SetHidden then
			StatueShape.SetHidden(false)
		end
		StatueShape.Apply(0, Config.CalebGrowSeconds)
	end
end

-- Called once by ServerMain. Returns the statue (for CalebCycle.Start), or
-- nil if the map has none.
function StatueService.Start(): Model?
	local found = Workspace:WaitForChild("Map"):FindFirstChild("Statue")
	if not found or not found:IsA("Model") then
		warn("StatueService: Workspace.Map.Statue is missing; feeding is off")
		return nil
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
	setPadLabels(feedText())
	rememberPadColors()
	CalebCycle.StateChanged:Connect(onStateChanged)

	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FeedStatue") :: RemoteFunction
	remote.OnServerInvoke = onFeed
	return found
end

-- Called by ServerMain when a player leaves.
function StatueService.OnPlayerRemoving(player: Player)
	lastFeed[player] = nil
end

return StatueService
