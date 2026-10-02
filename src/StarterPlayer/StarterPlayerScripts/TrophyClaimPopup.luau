-- TrophyClaimPopup (client only, ModuleScript)
-- The big "NEW TROPHY!" pop-up shown by TrophyPrompt.client after the server
-- reports a Saved / Unsaved claim: icon, name, rarity, power, description,
-- a note about the Trophy Case, and EQUIP / CLOSE.
--
-- Presentation only. Reads the server-written TrophyInventory attribute to
-- know whether the trophy is equipped and whether the case is built, and asks
-- the server to equip it with Remotes.TrophyEquip ("Equip", instanceId); the
-- server checks ownership and the slot limit. Closes on CLOSE, on a newer
-- pop-up, and by itself after Config.TrophyPopupSeconds.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TrophyVariants = require(Shared:WaitForChild("TrophyVariants"))
local TrophyClaimPopupUI = require(script.Parent:WaitForChild("TrophyClaimPopupUI"))
local TrophyInventoryIcon = require(script.Parent:WaitForChild("TrophyInventoryIcon"))
local Data = require(script.Parent:WaitForChild("TrophyInventoryData"))

local TrophyClaimPopup = {}

local player = Players.LocalPlayer
local ui = TrophyClaimPopupUI.Build(player:WaitForChild("PlayerGui"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local colors = TrophyClaimPopupUI.Colors

local DEFAULT_MAX = Config.TrophyActiveSlots or 5
local EQUIP_GAP = Config.TrophyEquipCooldown or 0.25 -- same rule as the inventory panel
local OPEN_SECONDS = Config.TrophyPopupSeconds or 20
local CLOSE_AFTER_EQUIP = 1.2
local POP = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FLY = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local current = {
	Token = 0, -- bumps on every Show / close, so old timers do nothing
	Variant = "",
	InstanceId = nil :: string?, -- from the notice, else resolved from the inventory
	KnownIds = {} :: { [string]: boolean }, -- owned before the claim (fallback only)
	Unsaved = false,
	Busy = false,
	Error = "",
}
local lastRequest = -math.huge
local shineSpin: RBXScriptConnection? = nil

local function textOr(value: any, fallback: string): string
	return if type(value) == "string" and value ~= "" then value else fallback
end

local function readInventory(): Data.Inventory
	local raw = player:GetAttribute("TrophyInventory")
	local decoded = nil
	if type(raw) == "string" then
		local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
		decoded = if ok then value else nil
	end
	return Data.Parse(decoded, DEFAULT_MAX)
end

-- Old servers don't send InstanceId: use the newest trophy of this variant,
-- preferring one that wasn't owned before the pop-up opened.
local function instanceIdFor(inv: Data.Inventory): string?
	if current.InstanceId then
		return current.InstanceId
	end
	local best, bestIsNew = nil, false
	for _, t in inv.Owned do
		if t.Variant == current.Variant then
			local isNew = not current.KnownIds[t.InstanceId]
			if not best or (isNew and not bestIsNew) or (isNew == bestIsNew and t.EarnedAt >= best.EarnedAt) then
				best, bestIsNew = t, isNew
			end
		end
	end
	return best and best.InstanceId
end

local function render()
	local inv = readInventory()
	local id = instanceIdFor(inv)
	local equipped = id ~= nil and inv.EquippedSet[id] == true

	ui.EquipButton.Visible = not equipped
	ui.Equipped.Visible = equipped
	local canClick = not current.Busy and id ~= nil
	ui.EquipButton.Active = canClick
	ui.EquipButton.AutoButtonColor = canClick
	ui.EquipText.Text = if current.Busy then "..." else "EQUIP"
	ui.EquipButton.BackgroundColor3 = if canClick then colors.Equip else colors.Disabled

	if not inv.CaseBuilt then
		ui.Note.Text = "Build your Trophy Case to use powers"
	elseif equipped then
		ui.Note.Text = "Its power is on!"
	else
		ui.Note.Text = "Equip it in your Trophy Case to get this power"
	end
	ui.Note.TextColor3 = if inv.CaseBuilt and equipped then colors.Equip else colors.Note

	if current.Error ~= "" then
		ui.Info.Text = current.Error
		ui.Info.TextColor3 = colors.Error
	elseif current.Unsaved then
		ui.Info.Text = "This trophy couldn't be saved this session (you keep it until you leave)."
		ui.Info.TextColor3 = colors.Info
	else
		ui.Info.Text = ""
	end
end

local function hide()
	current.Token += 1
	ui.Gui.Enabled = false
	if shineSpin then
		shineSpin:Disconnect()
		shineSpin = nil
	end
end

local function burstConfetti()
	for i, piece in ui.Confetti do
		local angle = (i / #ui.Confetti) * math.pi * 2 + math.random() * 0.4
		local distance = 0.35 + math.random() * 0.25
		piece.Position = UDim2.fromScale(0.5, 0.24)
		piece.Rotation = math.random(0, 360)
		piece.BackgroundTransparency = 0
		piece.Visible = true
		local tween = TweenService:Create(piece, FLY, {
			Position = UDim2.fromScale(0.5 + math.cos(angle) * distance, 0.24 + math.sin(angle) * distance * 0.8),
			Rotation = piece.Rotation + math.random(-270, 270),
			BackgroundTransparency = 1,
		})
		tween.Completed:Once(function()
			piece.Visible = false
		end)
		tween:Play()
	end
end

local function playSound()
	local id = Config.TrophyPopupSound
	if type(id) ~= "string" or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Config.TrophyPopupVolume or 0.6
	sound.Parent = ui.Gui
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

-- kind: "Saved" / "Unsaved"; instanceId may be nil (older server).
function TrophyClaimPopup.Show(kind: string, variantId: string, instanceId: string?)
	hide() -- a newer pop-up replaces the old one
	local token = current.Token
	current.Variant = variantId
	current.InstanceId = instanceId
	current.Unsaved = kind == "Unsaved"
	current.Busy = false
	current.Error = ""
	current.KnownIds = {}
	if not instanceId then
		for _, t in readInventory().Owned do
			current.KnownIds[t.InstanceId] = true
		end
	end

	local variant = TrophyVariants.Get(variantId) :: any
	local rarityName = if type(variant.Rarity) == "string" then variant.Rarity else "Common"
	local rarity = (TrophyVariants.Rarities :: any)[rarityName]
	local color = if type(rarity) == "table" and typeof(rarity.Color) == "Color3" then rarity.Color else Color3.fromRGB(235, 235, 235)
	TrophyInventoryIcon.Paint(ui.Icon, variant)
	ui.Header.BackgroundColor3 = color
	ui.Shine.BackgroundColor3 = color
	ui.Name.Text = textOr(variant.DisplayName, "Mystery Caleb")
	ui.Rarity.Text = "⭐ " .. string.upper(rarityName)
	ui.Rarity.TextColor3 = color
	ui.Power.Text = textOr(variant.PowerText, "No power")
	local description = textOr(variant.Description, "")
	ui.Description.Text = if description ~= "" then `"{description}"` else ""
	render()

	ui.Gui.Enabled = true
	ui.Scale.Scale = 0.3
	TweenService:Create(ui.Scale, POP, { Scale = 1 }):Play()
	burstConfetti()
	playSound()
	shineSpin = RunService.RenderStepped:Connect(function(dt)
		ui.ShineGradient.Rotation = (ui.ShineGradient.Rotation + dt * 60) % 360
	end)

	task.delay(OPEN_SECONDS, function()
		if current.Token == token then
			hide()
		end
	end)
end

local function reasonText(reason: any): string
	if type(reason) == "string" and reason ~= "" then
		return string.sub(reason, 1, 80)
	end
	return "Couldn't do that. Try again!"
end

local function onEquipClicked()
	local id = instanceIdFor(readInventory())
	if current.Busy or not id or os.clock() - lastRequest < EQUIP_GAP then
		return
	end
	local remote = remotes:FindFirstChild("TrophyEquip")
	if not (remote and remote:IsA("RemoteFunction")) then
		current.Error = "Trophies aren't ready yet. Try again!"
		render()
		return
	end

	local token = current.Token
	current.Busy = true
	current.Error = ""
	lastRequest = os.clock()
	render()
	local ok, accepted, reason = pcall(remote.InvokeServer, remote, "Equip", id)
	if current.Token ~= token then
		return -- closed or replaced while waiting
	end
	current.Busy = false
	if not ok then
		current.Error = "Couldn't reach the server. Try again!"
	elseif accepted ~= true then
		current.Error = reasonText(reason)
	else
		current.InstanceId = id
		ui.EquipButton.Visible = false
		ui.Equipped.Visible = true -- before the attribute catches up
		task.delay(CLOSE_AFTER_EQUIP, function()
			if current.Token == token then
				hide()
			end
		end)
		return
	end
	render()
end

ui.EquipButton.Activated:Connect(onEquipClicked)
ui.CloseButton.Activated:Connect(hide)
player:GetAttributeChangedSignal("TrophyInventory"):Connect(function()
	if ui.Gui.Enabled and not current.Busy then
		render()
	end
end)

return TrophyClaimPopup
