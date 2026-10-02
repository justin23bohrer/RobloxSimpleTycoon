-- HouseSecurityService (server only)
-- Owns each house's security (ARCHITECTURE.md "House Raid (contract)").
--
-- * The plot's owner steps on the green SecurityPad: it turns red (and
--   glows), and the red SecurityBars rise out of the floor across the front
--   doorway (tweened, with a mechanical sound) for exactly
--   Config.HouseSecuritySeconds. Then they sink back (sound), the pad turns
--   green, and the owner can step on it again right away. No cooldown.
-- * Non-owners stepping on the pad, and touches while it is red, do nothing.
-- * The bars always collide on the server; while down they sit below the
--   floor. The owner's own client turns their collision off locally
--   (HouseSecurity.client), so only the owner walks through.
-- * The pad, bars and TrophyStash are Parts of the Walls build (Config), so
--   PlotStages shows/hides them; this service only moves and colors them.
--
-- Plot attributes (written only here): SecurityActive, SecurityEndsAt.
-- The owner comes from the plot's OwnerUserId attribute (TycoonService), not
-- from TycoonService itself: TycoonService calls ResetPlot on release, so
-- requiring it here would be a cycle. No UI: the pad and bars are the signal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseRaid = require(ReplicatedStorage.Shared.HouseRaid)

local HouseSecurityService = {}

type PlotState = {
	Plot: Model,
	Pad: BasePart,
	Light: PointLight,
	Bars: { BasePart },
	DownCFrames: { [BasePart]: CFrame },
	Rise: number,
	Tweens: { Tween },
	CloseSound: Sound?,
	OpenSound: Sound?,
	Active: boolean,
	-- Bumped on every activate/deactivate/reset; a pending timer only ends
	-- the protection it started.
	Token: number,
}

local states: { [Model]: PlotState } = {}

local function makeSound(parent: Instance, id: string, name: string): Sound?
	if id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = if string.find(id, "://", 1, true) then id else `rbxassetid://{id}`
	sound.Volume = Config.HouseSecuritySoundVolume
	sound.RollOffMaxDistance = 90
	sound.Parent = parent
	return sound
end

-- Builds the plot's state the first time it is needed (ResetPlot runs for
-- every plot at startup, before Start). Nil if the plot has no security parts.
local function getState(plot: Model): PlotState?
	local state = states[plot]
	if state then
		return state
	end
	local pad = plot:FindFirstChild(HouseRaid.Part.SecurityPad)
	local barsModel = plot:FindFirstChild(HouseRaid.Part.SecurityBars)
	if not (pad and pad:IsA("BasePart") and barsModel) then
		return nil
	end
	local rise = barsModel:GetAttribute("RiseStuds")
	if typeof(rise) ~= "number" then
		warn(`HouseSecurityService: {plot.Name}.SecurityBars has no RiseStuds attribute`)
		return nil
	end

	local bars: { BasePart } = {}
	local downCFrames: { [BasePart]: CFrame } = {}
	for _, item in barsModel:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(bars, item)
			downCFrames[item] = item.CFrame -- the map saves the bars down
		end
	end

	-- Lights are not hidden by PlotVisibility, so this one is only on while red.
	local light = Instance.new("PointLight")
	light.Name = "SecurityLight"
	light.Color = Config.HouseSecurityPadLockedColor
	light.Brightness = 2
	light.Range = 10
	light.Enabled = false
	light.Parent = pad

	local soundParent = barsModel:FindFirstChild("RailMiddle") or bars[1] or pad
	state = {
		Plot = plot,
		Pad = pad,
		Light = light,
		Bars = bars,
		DownCFrames = downCFrames,
		Rise = rise,
		Tweens = {},
		CloseSound = makeSound(soundParent, Config.HouseSecuritySounds.Close, "SecurityClose"),
		OpenSound = makeSound(soundParent, Config.HouseSecuritySounds.Open, "SecurityOpen"),
		Active = false,
		Token = 0,
	}
	states[plot] = state
	return state
end

local function stopTweens(state: PlotState)
	for _, tween in state.Tweens do
		tween:Cancel()
	end
	table.clear(state.Tweens)
end

-- Tweens the bars up (closed) or down (open) from wherever they are now.
local function moveBars(state: PlotState, up: boolean)
	stopTweens(state)
	local info = if up
		then TweenInfo.new(Config.HouseSecurityBarsSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- slams shut
		else TweenInfo.new(Config.HouseSecurityBarsSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local lift = Vector3.new(0, if up then state.Rise else 0, 0)
	for _, part in state.Bars do
		local tween = TweenService:Create(part, info, { CFrame = state.DownCFrames[part] + lift })
		table.insert(state.Tweens, tween)
		tween:Play()
	end
end

local function play(sound: Sound?)
	if sound then
		sound.TimePosition = 0
		sound:Play()
	end
end

local function setActive(state: PlotState, active: boolean)
	state.Token += 1
	state.Active = active
	state.Plot:SetAttribute(HouseRaid.PlotAttr.SecurityActive, active)
	state.Plot:SetAttribute(
		HouseRaid.PlotAttr.SecurityEndsAt,
		if active then Workspace:GetServerTimeNow() + Config.HouseSecuritySeconds else 0
	)
	state.Pad.Color = if active then Config.HouseSecurityPadLockedColor else Config.HouseSecurityPadOpenColor
	state.Light.Enabled = active
end

local function deactivate(state: PlotState)
	setActive(state, false)
	moveBars(state, false)
	play(state.OpenSound)
end

local function activate(state: PlotState)
	setActive(state, true)
	moveBars(state, true)
	play(state.CloseSound)
	local token = state.Token
	task.delay(Config.HouseSecuritySeconds, function()
		if state.Token == token then
			deactivate(state)
		end
	end)
end

local function onPadTouched(state: PlotState, hit: BasePart)
	if state.Active then
		return -- already red: wait for the bars to drop
	end
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or state.Plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return -- only this house's owner
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	activate(state)
end

-- Called once by ServerMain after TycoonService.Start().
function HouseSecurityService.Start()
	local plotsFolder = Workspace:WaitForChild("Map"):WaitForChild("Plots")
	for _, plot in plotsFolder:GetChildren() do
		if plot:IsA("Model") then
			local state = getState(plot)
			if state then
				state.Pad.Touched:Connect(function(hit)
					onPadTouched(state, hit)
				end)
			end
		end
	end
end

-- True while the plot's bars are up (other players can't enter, no theft).
function HouseSecurityService.IsProtected(plot: Model): boolean
	local state = states[plot]
	return state ~= nil and state.Active
end

-- Bars down, pad green, timer cancelled (plot released or reset). Instant
-- and silent; TycoonService calls it before hiding the plot's builds.
function HouseSecurityService.ResetPlot(plot: Model)
	local state = getState(plot)
	if not state then
		return
	end
	setActive(state, false)
	stopTweens(state)
	for _, part in state.Bars do
		part.CFrame = state.DownCFrames[part]
	end
end

return HouseSecurityService
