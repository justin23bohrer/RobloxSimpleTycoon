-- TycoonSounds (server only)
-- Helper for TycoonService and CollectorService: the tycoon's sound effects
-- (Config.TycoonSounds). Presentation only: it is told what already happened
-- (a purchase went through, a payout was paid) and never decides or changes
-- anything.
--
-- * Purchase (droppers) / PurchaseBuild (builds and trophy builds): 3D at
--   the bought button, heard by players nearby. Played only from
--   TycoonService.TryPurchase, never when a saved house is restored.
-- * CantAfford (too few cookies, or too few Caleb Trophies for a trophy
--   build): only for the player who touched the button, through the
--   CantAfford RemoteEvent (CantAffordSound.client plays it), at most once per
--   Config.TycoonCantAffordSoundInterval per player per button.
-- * Collect: 3D at the CollectPad on payout; pitch rises a little for bigger
--   payouts.
-- * DropInJar: quiet 3D plink at the cookie jar (or the Collector if the plot
--   has no jar), at most Config.TycoonDropSoundsPerSecond per plot.
--
-- The 3D Sounds are made once per plot (Setup) and played from the server,
-- which replicates to every client. An empty id = that Sound is never made,
-- so it is skipped silently.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Purchases = require(script.Parent.Purchases)

local TycoonSounds = {}

-- Hearing range, looks only: loud near the plot, gone past MAX studs.
local ROLLOFF_MIN = 12
local ROLLOFF_MAX = 90

type PlotSounds = {
	Spot: Attachment, -- moved to the bought button before Purchase plays
	Purchase: Sound?,
	PurchaseBuild: Sound?,
	Collect: Sound?,
	DropInJar: Sound?,
	LastDrop: number,
}

local soundsByPlot: { [Model]: PlotSounds } = {}
local lastCantAfford: { [Player]: { [string]: number } } = {}
local cantAffordRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CantAfford") :: RemoteEvent
local reportedMissing = false

-- "123" or "rbxassetid://123" -> "rbxassetid://123"; "" or not a string -> nil.
local function assetId(value: any): string?
	if typeof(value) ~= "string" or value == "" then
		return nil
	end
	if value:match("^%d+$") then
		return "rbxassetid://" .. value
	end
	return value
end

local function makeSound(name: string, parent: Instance): Sound?
	local id = assetId(Config.TycoonSounds[name])
	if not id then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = "Tycoon" .. name
	sound.SoundId = id
	sound.Volume = Config.TycoonSoundVolumes[name] or 0.5
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = ROLLOFF_MIN
	sound.RollOffMaxDistance = ROLLOFF_MAX
	sound.Parent = parent
	return sound
end

local function reportMissing()
	if reportedMissing or not RunService:IsStudio() then
		return
	end
	reportedMissing = true
	local missing = {}
	for _, name in { "Purchase", "PurchaseBuild", "CantAfford", "Collect", "DropInJar" } do
		if not assetId(Config.TycoonSounds[name]) then
			table.insert(missing, "TycoonSounds." .. name)
		end
	end
	if #missing > 0 then
		print("[TycoonSounds] no sound id in Config for: " .. table.concat(missing, ", ")
			.. " (skipped; see tools/audio/README.md)")
	end
end

-- Makes the plot's Sounds. Called once per plot at server start.
function TycoonSounds.Setup(plot: Model)
	if soundsByPlot[plot] then
		return
	end
	reportMissing()

	local spot = Instance.new("Attachment")
	spot.Name = "TycoonSoundSpot"
	spot.Parent = plot:FindFirstChild("Base")

	local tank = plot:FindFirstChild("CashTank")
	local jar = (tank and tank:FindFirstChild("TankLid")) or plot:FindFirstChild("Collector")

	soundsByPlot[plot] = {
		Spot = spot,
		Purchase = makeSound("Purchase", spot),
		PurchaseBuild = makeSound("PurchaseBuild", spot),
		Collect = makeSound("Collect", plot:FindFirstChild("CollectPad") :: Instance),
		DropInJar = jar and makeSound("DropInJar", jar),
		LastDrop = 0,
	}
end

-- A purchase was bought (not restored): ka-ching at its button.
function TycoonSounds.Purchased(plot: Model, purchaseId: string)
	local sounds = soundsByPlot[plot]
	local purchase = Purchases.Get(purchaseId)
	if not sounds or not purchase then
		return
	end
	local sound = if purchase.Kind ~= "Dropper" then sounds.PurchaseBuild or sounds.Purchase else sounds.Purchase
	if not sound then
		return
	end
	local button = plot:FindFirstChild(purchase.ButtonName)
	if button and button:IsA("BasePart") then
		sounds.Spot.WorldPosition = button.Position
	end
	sound:Play()
end

-- The player touched a button they can't afford: a soft "nope" only they hear.
function TycoonSounds.CantAfford(player: Player, purchaseId: string)
	if not assetId(Config.TycoonSounds.CantAfford) or player.Parent ~= Players then
		return
	end
	local byButton = lastCantAfford[player]
	if not byButton then
		byButton = {}
		lastCantAfford[player] = byButton
	end
	local now = os.clock()
	local last = byButton[purchaseId]
	if last and now - last < Config.TycoonCantAffordSoundInterval then
		return
	end
	byButton[purchaseId] = now
	cantAffordRemote:FireClient(player)
end

-- The owner was paid `payout` cookies from the CollectPad.
function TycoonSounds.Collected(plot: Model, payout: number)
	local sounds = soundsByPlot[plot]
	local sound = sounds and sounds.Collect
	if not sound then
		return
	end
	local tenfolds = math.max(0, math.log10(math.max(payout, 1)) - 1)
	sound.PlaybackSpeed = math.min(Config.TycoonCollectPitchMax, 1 + Config.TycoonCollectPitchPerTenfold * tenfolds)
	sound:Play()
end

-- A cookie drop reached one of the plot's collectors.
function TycoonSounds.DropInJar(plot: Model)
	local sounds = soundsByPlot[plot]
	local sound = sounds and sounds.DropInJar
	if not sound then
		return
	end
	local now = os.clock()
	if now - sounds.LastDrop < 1 / Config.TycoonDropSoundsPerSecond then
		return
	end
	sounds.LastDrop = now
	sound:Play()
end

-- Forgets a leaving player's CantAfford timers.
function TycoonSounds.OnPlayerRemoving(player: Player)
	lastCantAfford[player] = nil
end

return TycoonSounds
