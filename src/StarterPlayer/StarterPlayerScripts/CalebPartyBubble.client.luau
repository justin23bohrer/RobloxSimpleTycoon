-- CalebPartyBubble (client only)
-- Caleb's cartoony speech bubbles during the Cookie Party (CalebState
-- "Celebration"): short funny lines (Config.CookiePartyCalebLines, by phase)
-- that pop in and out above his head, faster and shakier later, and
-- Config.CookiePartyCalebFinalLine ("I'M FULL!!!") for the last second.
--
-- Looks only: driven by the statue's CalebState / CalebStateEndsAt /
-- CalebCycleId attributes. Which line shows is worked out from server time
-- (Shared/CookieParty), so every player, including a late joiner, sees the
-- same line at the same moment. Never talks to the server.
--
-- Like StatueBar, the BillboardGui is adorned to an Attachment in
-- Workspace.Terrain at the same spot as the bar (Config.StatueBarHeight above
-- the top of the Head), so it stays up if the statue streams out. The
-- billboard is twice as tall as needed and the bubble sits in its top half,
-- starting just above the bar's pixel height, so the two never overlap at any
-- distance. Hidden (and nothing runs per frame) outside Celebration.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)
local CalebPartyPoses = require(script.Parent:WaitForChild("CalebPartyPoses"))

local player = Players.LocalPlayer
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")

local DURATION = Config.CalebCelebrationSeconds

-- Look (presentation only, same family as StatueBar / CashDisplay)
local BUBBLE_SIZE = Vector2.new(340, 90) -- pixels
local GAP = 8 -- pixels between the top of the bar and the tail's tip
local TAIL = 18 -- pixels the tail sticks out under the bubble
local MARGIN = 30 -- pixels of room for the pop and the shake
local SHOW_SHARE = 0.75 -- a line shows for this share of its slot, then pops out
local PANEL_COLOR = Color3.fromRGB(255, 255, 255)
local FINAL_PANEL_COLOR = Color3.fromRGB(255, 214, 64)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local FONT = Enum.Font.FredokaOne
local TEXT_COLORS = {
	Start = Color3.fromRGB(255, 105, 180),
	Hype = Color3.fromRGB(255, 140, 30),
	Frenzy = Color3.fromRGB(255, 60, 45),
	Countdown = Color3.fromRGB(140, 80, 255),
}
local FINAL_TEXT_COLOR = Color3.fromRGB(235, 40, 40)
local SHAKE_DEGREES = { Start = 0, Hype = 1.5, Frenzy = 4, Countdown = 3 }
local FINAL_SHAKE_DEGREES = 6
local FINAL_SCALE = 1.25
local POP_IN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)

-- Elapsed seconds at which each phase starts.
local phaseStart: { [string]: number } = { Start = 0 }
for i, name in CookieParty.PhaseOrder do
	if i > 1 then
		phaseStart[name] = DURATION - Config.CookiePartyPhases[name]
	end
end

local function addStroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode)
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
end

-- Build the UI (once) ----------------------------------------------------------

local anchor = Instance.new("Attachment")
anchor.Name = "CalebPartyBubbleAnchor"
anchor.Parent = Workspace.Terrain

-- Centered on the bar's center: the top half holds the bubble.
local half = Config.StatueBarSize.Y / 2 + GAP + TAIL + BUBBLE_SIZE.Y + MARGIN
local billboard = Instance.new("BillboardGui")
billboard.Name = "CalebPartyBubble"
billboard.ResetOnSpawn = false
billboard.Adornee = anchor
billboard.Size = UDim2.fromOffset(BUBBLE_SIZE.X + 2 * MARGIN, 2 * half)
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.MaxDistance = Config.StatueBarMaxDistance
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.Enabled = false

-- Everything that pops/shakes, pinned at the tail's tip (bottom center).
local bubble = Instance.new("Frame")
bubble.Name = "Bubble"
bubble.AnchorPoint = Vector2.new(0.5, 1)
bubble.Position = UDim2.new(0.5, 0, 0, half - Config.StatueBarSize.Y / 2 - GAP)
bubble.Size = UDim2.fromOffset(BUBBLE_SIZE.X, BUBBLE_SIZE.Y + TAIL)
bubble.BackgroundTransparency = 1
bubble.Parent = billboard

local scale = Instance.new("UIScale")
scale.Scale = 0
scale.Parent = bubble

-- The tail: a diamond half hidden behind the panel.
local tail = Instance.new("Frame")
tail.Name = "Tail"
tail.AnchorPoint = Vector2.new(0.5, 0.5)
tail.Position = UDim2.new(0.5, 0, 0, BUBBLE_SIZE.Y - 4)
tail.Size = UDim2.fromOffset(TAIL * 1.6, TAIL * 1.6)
tail.Rotation = 45
tail.BackgroundColor3 = PANEL_COLOR
tail.ZIndex = 1
tail.Parent = bubble
addStroke(tail, 4, Enum.ApplyStrokeMode.Border)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(BUBBLE_SIZE.X, BUBBLE_SIZE.Y)
panel.BackgroundColor3 = PANEL_COLOR
panel.ZIndex = 2
panel.Parent = bubble
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.35, 0)
corner.Parent = panel
addStroke(panel, 4, Enum.ApplyStrokeMode.Border)

local label = Instance.new("TextLabel")
label.Name = "Line"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.5)
label.Size = UDim2.fromScale(0.88, 0.66)
label.BackgroundTransparency = 1
label.Font = FONT
label.Text = ""
label.TextScaled = true
label.ZIndex = 3
label.Parent = panel
addStroke(label, 2.5, Enum.ApplyStrokeMode.Contextual)

billboard.Parent = player:WaitForChild("PlayerGui")

-- Which line ----------------------------------------------------------------

-- The line showing `elapsed` seconds into the party: (key, text, phase) or
-- nil between lines. The key changes whenever the line does.
local function lineAt(elapsed: number, timeLeft: number, offset: number): (string?, string, string)
	if timeLeft <= Config.CookiePartyCalebFinalLineSeconds then
		return "Final", Config.CookiePartyCalebFinalLine, "Final"
	end
	local phase = CookieParty.GetPhase(timeLeft)
	local lines = Config.CookiePartyCalebLines[phase]
	local every = Config.CookiePartyCalebLineSeconds[phase]
	if not lines or #lines == 0 or not every or every <= 0 then
		return nil, "", phase
	end
	local into = elapsed - phaseStart[phase]
	local slot = math.floor(into / every)
	if into - slot * every >= every * SHOW_SHARE then
		return nil, "", phase
	end
	-- The Countdown lines tell a story, so they always start at the first one.
	local first = if phase == CookieParty.Phase.Countdown then 0 else offset
	return `{phase}{slot}`, lines[(first + slot) % #lines + 1], phase
end

-- Run during the party ---------------------------------------------------------

local stepConnection: RBXScriptConnection? = nil
local shownKey: string? = nil
local shownPhase = ""
local offset = 0
local placed = false -- the anchor has been put above his head at least once
local scaleTween: Tween? = nil

local function tweenScale(to: number, info: TweenInfo)
	if scaleTween then
		scaleTween:Cancel()
	end
	local tween = TweenService:Create(scale, info, { Scale = to })
	scaleTween = tween
	tween:Play()
end

local function show(key: string?, text: string, phase: string)
	shownKey, shownPhase = key, phase
	if not key then
		tweenScale(0, POP_OUT)
		return
	end
	local final = phase == "Final"
	label.Text = text
	label.TextColor3 = if final then FINAL_TEXT_COLOR else TEXT_COLORS[phase] or FINAL_TEXT_COLOR
	panel.BackgroundColor3 = if final then FINAL_PANEL_COLOR else PANEL_COLOR
	tail.BackgroundColor3 = panel.BackgroundColor3
	scale.Scale = 0
	tweenScale(if final then FINAL_SCALE else 1, POP_IN)
end

local function step()
	local head = statue:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		-- Same spot as StatueBar's anchor (it follows his dancing head too).
		local top = head.Position.Y + head.Size.Y / 2
		anchor.WorldPosition = Vector3.new(head.Position.X, top + Config.StatueBarHeight, head.Position.Z)
		placed = true
	end
	billboard.Enabled = placed -- not until we know where his head is
	local endsAt = statue:GetAttribute(CalebEvent.Attr.StateEndsAt)
	local timeLeft = CookieParty.TimeLeft(statue)
	local key, text, phase = nil, "", ""
	if typeof(endsAt) == "number" and endsAt > 0 then
		key, text, phase = lineAt(DURATION - timeLeft, timeLeft, offset)
	end
	if key ~= shownKey then
		show(key, text, phase)
	end
	local shake = if shownPhase == "Final" then FINAL_SHAKE_DEGREES else SHAKE_DEGREES[shownPhase] or 0
	bubble.Rotation = shake * math.sin(os.clock() * 37)
end

local function stop()
	if stepConnection then
		stepConnection:Disconnect()
		stepConnection = nil
	end
	if scaleTween then
		scaleTween:Cancel()
		scaleTween = nil
	end
	billboard.Enabled = false
	scale.Scale = 0
	shownKey, shownPhase = nil, ""
end

local function refresh()
	if CalebEvent.GetState(statue) ~= CalebEvent.State.Celebration then
		stop()
		return
	end
	if not stepConnection then
		local cycleId = statue:GetAttribute(CalebEvent.Attr.CycleId)
		offset = CalebPartyPoses.Seed(if typeof(cycleId) == "string" then cycleId else nil)
		stepConnection = RunService.Heartbeat:Connect(step)
	end
end

-- A late joiner gets the current state from the replicated attribute here.
statue:GetAttributeChangedSignal(CalebEvent.Attr.State):Connect(refresh)
refresh()
