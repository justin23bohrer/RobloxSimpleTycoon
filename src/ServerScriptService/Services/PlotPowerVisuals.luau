-- PlotPowerVisuals (server only)
-- Helper for PowerService and DropperService: shows the plot owner's active
-- Caleb Trophy powers ON the thing they boost. Presentation only; it decides
-- nothing and never changes cash or powers.
--
-- * CookieMultiplier and/or DropperSpeed > 0: every bought dropper cup burns
--   (a Fire + warm PointLight on top of the cup). Bigger bonus = bigger flames,
--   full size at FULL_FIRE_BONUS. Both active = sparks too.
-- * ExtraCookieChance / LuckyCookieChance > 0: a few green and gold luck
--   sparkles float off each dropper cup.
-- * CollectBonus > 0: the CollectPad gets a golden glow ring ("PowerPadFX",
--   a child of the plot) with gold shine particles and a light, separate
--   from CollectorDisplay's own pad "Sparkles"/"Glow".
-- * Player-body powers (WalkSpeed, JumpHeight, DoubleJump) are not shown here.
--
-- PowerService calls Apply(player, totals) whenever the totals change.
-- DropperService calls AddDropper(plot, cup) for every cup it builds, so a
-- dropper bought later burns too. A plot's owner is read from its
-- OwnerUserId attribute; when that changes (claim, release, leave) the plot
-- is redrawn for its new owner (or cleared). Everything is built on the
-- server so every player sees it. Event-driven, no loops: one emitter set per
-- cup, nothing per drop.
--
-- Requires only Shared modules (never TycoonService, DropperService or
-- PowerService), so nothing can make a require cycle through it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local TrophyPowers = require(ReplicatedStorage.Shared.TrophyPowers)

local PlotPowerVisuals = {}

-- Looks only; not gameplay tuning.
local FULL_FIRE_BONUS = 1 -- CookieMultiplier + DropperSpeed that gives the biggest flames
local FIRE_SIZE = NumberRange.new(2, 6) -- Fire.Size at the smallest / biggest bonus
local FIRE_HEAT = NumberRange.new(5, 14)
local FIRE_COLOR = Color3.fromRGB(255, 120, 20)
local FIRE_SECONDARY = Color3.fromRGB(255, 220, 60)
local LIGHT_RANGE = NumberRange.new(6, 14)
local LIGHT_BRIGHTNESS = NumberRange.new(1, 3)
local GOLD = Color3.fromRGB(255, 215, 60)
local LUCK_GREEN = Color3.fromRGB(80, 230, 110)
local FX_NAME = "PowerFX" -- the invisible part on top of a cup holding its effects
local PAD_FX_NAME = "PowerPadFX" -- the CollectPad's glow ring, a child of the plot
local FX_KEY_ATTR = "PowerKey" -- what the effects were built for; skip rebuilding if unchanged

local Stat = TrophyPowers.Stat
local totalsByPlayer: { [Player]: { [string]: number } } = setmetatable({}, { __mode = "k" }) :: any
local droppersByPlot: { [Model]: { [Model]: boolean } } = {}
local watchedPlots: { [Model]: boolean } = {}

local function lerp(range: NumberRange, t: number): number
	return range.Min + (range.Max - range.Min) * t
end

local function ownerTotals(plot: Model): { [string]: number }
	local ownerUserId = plot:GetAttribute("OwnerUserId")
	local owner = type(ownerUserId) == "number" and Players:GetPlayerByUserId(ownerUserId)
	return owner and totalsByPlayer[owner] or {}
end

local function emitter(name: string, colors: ColorSequence, rate: number, speed: number, size: number): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Name = name
	particles.Color = colors
	particles.LightEmission = 0.8
	particles.Rate = rate
	particles.Speed = NumberRange.new(speed, speed * 2)
	particles.Lifetime = NumberRange.new(0.6, 1.2)
	particles.SpreadAngle = Vector2.new(30, 30)
	particles.Size = NumberSequence.new(size, 0)
	particles.EmissionDirection = Enum.NormalId.Top
	return particles
end

local function fxPart(name: string, cframe: CFrame, size: Vector3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
	return part
end

-- Fire / sparks / luck on one dropper cup, or none.
local function drawDropper(cup: Model, totals: { [string]: number })
	local multiplier = totals[Stat.CookieMultiplier] or 0
	local speed = totals[Stat.DropperSpeed] or 0
	local luck = (totals[Stat.ExtraCookieChance] or 0) + (totals[Stat.LuckyCookieChance] or 0)
	local key = if multiplier > 0 or speed > 0 or luck > 0 then `{multiplier}|{speed}|{luck}` else nil

	local old = cup:FindFirstChild(FX_NAME)
	if old and old:GetAttribute(FX_KEY_ATTR) == key then
		return -- already shows these powers
	end
	if old then
		old:Destroy()
	end
	if not key then
		return
	end

	-- The cup is upside down: its base (top of the bounding box) faces up.
	local box, size = cup:GetBoundingBox()
	local top = box.Position + Vector3.new(0, size.Y / 2, 0)
	local fx = fxPart(FX_NAME, CFrame.new(top), Vector3.new(0.4, 0.4, 0.4), cup)
	fx:SetAttribute(FX_KEY_ATTR, key)

	if multiplier > 0 or speed > 0 then
		local t = math.clamp((multiplier + speed) / FULL_FIRE_BONUS, 0, 1)
		local fire = Instance.new("Fire")
		fire.Name = "PowerFire"
		fire.Size = lerp(FIRE_SIZE, t)
		fire.Heat = lerp(FIRE_HEAT, t)
		fire.Color = FIRE_COLOR
		fire.SecondaryColor = FIRE_SECONDARY
		fire.Parent = fx

		local light = Instance.new("PointLight")
		light.Name = "PowerLight"
		light.Color = FIRE_COLOR
		light.Range = lerp(LIGHT_RANGE, t)
		light.Brightness = lerp(LIGHT_BRIGHTNESS, t)
		light.Parent = fx

		if multiplier > 0 and speed > 0 then
			local sparks = emitter("PowerSparks", ColorSequence.new(FIRE_SECONDARY, FIRE_COLOR), 6 + 10 * t, 6, 0.25)
			sparks.Acceleration = Vector3.new(0, -8, 0)
			sparks.Parent = fx
		end
	end
	if luck > 0 then
		local sparkle = emitter("PowerLuck", ColorSequence.new(LUCK_GREEN, GOLD), math.min(1 + luck * 10, 4), 1, 0.35)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = fx
	end
end

-- Golden glow ring + shine on the CollectPad, or none.
local function drawPad(plot: Model, totals: { [string]: number })
	local pad = plot:FindFirstChild("CollectPad")
	if not pad or not pad:IsA("BasePart") then
		return
	end
	local bonus = totals[Stat.CollectBonus] or 0
	local key = if bonus > 0 then tostring(bonus) else nil
	-- On the plot, not inside the pad: PlotStages hides the pad (and its
	-- children) through PlotVisibility, which must not keep track of this.
	local old = plot:FindFirstChild(PAD_FX_NAME)
	if old and old:GetAttribute(FX_KEY_ATTR) == key then
		return
	end
	if old then
		old:Destroy()
	end
	if not key then
		return
	end

	local t = math.clamp(bonus / (Config.TrophyStatCaps[Stat.CollectBonus] or 1), 0, 1)
	-- The pad is a Cylinder turned so its X axis points up; a slightly wider,
	-- slightly thinner neon disc shows as a glowing ring around its edge.
	local ring = fxPart(PAD_FX_NAME, pad.CFrame, pad.Size + Vector3.new(-0.05, 0.8, 0.8), plot)
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = GOLD
	ring.Transparency = 0.6 - 0.3 * t
	ring:SetAttribute(FX_KEY_ATTR, key)

	-- The ring is turned like the pad (X up), so "Right" emits upward.
	local shine = emitter("PowerShine", ColorSequence.new(GOLD), 4 + 12 * t, 1.5, 0.35)
	shine.EmissionDirection = Enum.NormalId.Right
	shine.Parent = ring

	local light = Instance.new("PointLight")
	light.Name = "PowerLight"
	light.Color = GOLD
	light.Range = lerp(LIGHT_RANGE, t)
	light.Brightness = lerp(LIGHT_BRIGHTNESS, t)
	light.Parent = ring
end

local function redraw(plot: Model)
	local totals = ownerTotals(plot)
	for cup in droppersByPlot[plot] or {} do
		drawDropper(cup, totals)
	end
	drawPad(plot, totals)
end

-- Redraws a plot whenever its owner changes (claim, release, leave).
local function watch(plot: Model)
	if watchedPlots[plot] then
		return
	end
	watchedPlots[plot] = true
	plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		redraw(plot)
	end)
end

-- Called by PowerService whenever a player's power totals change (empty =
-- no powers). Redraws the plot(s) they own.
function PlotPowerVisuals.Apply(player: Player, totals: { [string]: number })
	totalsByPlayer[player] = if next(totals) then totals else nil
	local map = Workspace:FindFirstChild("Map")
	local plots = map and map:FindFirstChild("Plots")
	if not plots then
		return
	end
	for _, plot in plots:GetChildren() do
		if plot:IsA("Model") then
			watch(plot)
			if plot:GetAttribute("OwnerUserId") == player.UserId then
				redraw(plot)
			end
		end
	end
end

-- Called by DropperService for every dropper cup it places on a plot (after
-- parenting it). The cup shows the owner's powers now and on every change
-- until it is destroyed.
function PlotPowerVisuals.AddDropper(plot: Model, cup: Model)
	watch(plot)
	local cups = droppersByPlot[plot]
	if not cups then
		cups = {}
		droppersByPlot[plot] = cups
	end
	cups[cup] = true
	cup.Destroying:Connect(function()
		cups[cup] = nil
	end)
	drawDropper(cup, ownerTotals(plot))
end

return PlotPowerVisuals
