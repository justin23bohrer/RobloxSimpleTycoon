-- TrophyInventory (client only)
-- The "🏆 TROPHIES" button and the "MY CALEB TROPHIES" panel: the player's
-- Caleb Trophies in a scrolling grid, details of the selected one (name,
-- rarity, power, description), EQUIP / UNEQUIP, how many are active, and the
-- active powers.
--
-- Presentation only. Reads the server-written player attributes
-- TrophyInventory and TrophyStats (JSON; missing or bad = empty) and asks the
-- server to equip/unequip with Remotes.TrophyEquip. The server decides
-- everything; this script only re-renders from the attributes. The UI is
-- built once (TrophyInventoryUI); grid tiles are pooled and reused.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TrophyVariants = require(Shared:WaitForChild("TrophyVariants"))
local TrophyInventoryUI = require(script.Parent:WaitForChild("TrophyInventoryUI"))
local TrophyInventoryIcon = require(script.Parent:WaitForChild("TrophyInventoryIcon"))
local Data = require(script.Parent:WaitForChild("TrophyInventoryData"))

local player = Players.LocalPlayer
local ui = TrophyInventoryUI.Build(player:WaitForChild("PlayerGui"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local colors = TrophyInventoryUI.Colors

local DEFAULT_MAX = Config.TrophyActiveSlots or 5
local EQUIP_GAP = Config.TrophyEquipCooldown or 0.25 -- don't trip the server's rate limit
local POP = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local inventory = Data.Parse(nil, DEFAULT_MAX)
local selectedId: string? = nil
local busy = false
local lastRequest = -math.huge
local message = { Text = "", IsError = false, For = "" }
local tiles: { TrophyInventoryUI.Tile } = {}
local tileIds: { string } = {}

-- Definitions (fall back gracefully while fields/rarities are being added) --

local function rarityOf(variant: any): (string, Color3, number)
	local name = if type(variant.Rarity) == "string" then variant.Rarity else "Common"
	local info = (TrophyVariants.Rarities :: any)[name]
	local color = if type(info) == "table" and typeof(info.Color) == "Color3" then info.Color else colors.UnknownRarity
	local order = if type(info) == "table" and type(info.Order) == "number" then info.Order else 0
	return name, color, order
end

local function isCollectable(variantId: string): boolean
	return TrophyVariants.Exists(variantId) and (TrophyVariants.Get(variantId).Weight or 0) > 0
end

local function collectableCount(): number
	local count = (TrophyVariants :: any).CollectableCount
	if type(count) == "function" then
		local ok, n = pcall(count)
		if ok and type(n) == "number" then
			return n
		end
	end
	local n = 0
	for _, v in TrophyVariants.List do
		if (v.Weight or 0) > 0 then
			n += 1
		end
	end
	return n
end
local COLLECTABLE = collectableCount()

local function decodeAttribute(name: string): any
	local raw = player:GetAttribute(name)
	if type(raw) ~= "string" then
		return nil
	end
	local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok then value else nil
end

local function textOr(value: any, fallback: string): string
	return if type(value) == "string" and value ~= "" then value else fallback
end

-- Rendering ---------------------------------------------------------------

local function renderDetails()
	local trophy = nil
	for _, t in inventory.Owned do
		if t.InstanceId == selectedId then
			trophy = t
			break
		end
	end
	ui.Placeholder.Visible = trophy == nil
	for _, piece in { ui.DetailIcon.Root, ui.DetailName, ui.DetailRarity, ui.DetailPower, ui.DetailDescription, ui.Message, ui.EquipButton } do
		piece.Visible = trophy ~= nil
	end
	if not trophy then
		return
	end

	local variant = TrophyVariants.Get(trophy.Variant) :: any
	local rarity, color = rarityOf(variant)
	TrophyInventoryIcon.Paint(ui.DetailIcon, variant)
	ui.DetailName.Text = textOr(variant.DisplayName, "Mystery Caleb")
	ui.DetailRarity.Text = "⭐ " .. string.upper(rarity)
	ui.DetailRarity.TextColor3 = color
	ui.DetailPower.Text = textOr(variant.PowerText, "No power")
	local description = textOr(variant.Description, "")
	ui.DetailDescription.Text = if description ~= "" then `"{description}"` else ""

	local equipped = inventory.EquippedSet[trophy.InstanceId] == true
	local count, max = #inventory.Equipped, inventory.Max
	local canClick = not busy and (equipped or count < max)
	ui.EquipButton.Active = canClick
	ui.EquipButton.AutoButtonColor = canClick
	if busy then
		ui.EquipText.Text = "..."
		ui.EquipButton.BackgroundColor3 = colors.Disabled
	elseif equipped then
		ui.EquipText.Text = "UNEQUIP"
		ui.EquipButton.BackgroundColor3 = colors.Unequip
	elseif count >= max then
		ui.EquipText.Text = `Case full ({count}/{max})`
		ui.EquipButton.BackgroundColor3 = colors.Disabled
	else
		ui.EquipText.Text = "EQUIP"
		ui.EquipButton.BackgroundColor3 = colors.Equip
	end

	local showMessage = message.For == trophy.InstanceId
	ui.Message.Text = if showMessage then message.Text else ""
	ui.Message.TextColor3 = if message.IsError then colors.Error else colors.Success
end

local function renderPowers()
	local summary = Data.PowerSummary(decodeAttribute("TrophyStats"))
	ui.Powers.Text = "Active powers: " .. (if summary ~= "" then summary else "none")
end

local selectTrophy: (string) -> ()

local function getTile(i: number): TrophyInventoryUI.Tile
	local tile = tiles[i]
	if not tile then
		tile = TrophyInventoryUI.NewTile(ui.Grid)
		tile.Button.LayoutOrder = i
		tile.Button.Activated:Connect(function()
			if tileIds[i] then
				selectTrophy(tileIds[i])
			end
		end)
		tiles[i] = tile
	end
	return tile
end

local function render()
	local count, max = #inventory.Equipped, inventory.Max
	ui.Collection.Text = `🏆 COLLECTION {Data.DistinctOwned(inventory, isCollectable)} / {COLLECTABLE}`
	ui.Active.Text = `ACTIVE TROPHIES: {count} / {max}`
	ui.CaseNote.Visible = not inventory.CaseBuilt
	ui.SavedNote.Visible = not inventory.Saved

	local sorted = Data.Sort(inventory, function(variantId)
		local _, _, order = rarityOf(TrophyVariants.Get(variantId))
		return order
	end)
	local stillOwned = false
	for i, trophy in sorted do
		local tile = getTile(i)
		local variant = TrophyVariants.Get(trophy.Variant) :: any
		local rarity, color = rarityOf(variant)
		tileIds[i] = trophy.InstanceId
		tile.Button.Visible = true
		tile.Button.BackgroundColor3 = color
		tile.Face.BackgroundColor3 = if trophy.InstanceId == selectedId then colors.TileSelected else colors.TileFace
		tile.Name.Text = textOr(variant.DisplayName, "Mystery Caleb")
		tile.Rarity.Text = string.upper(rarity)
		tile.Rarity.TextColor3 = color
		tile.Badge.Visible = inventory.EquippedSet[trophy.InstanceId] == true
		TrophyInventoryIcon.Paint(tile.Icon, variant)
		stillOwned = stillOwned or trophy.InstanceId == selectedId
	end
	for i = #sorted + 1, #tiles do
		tileIds[i] = nil
		tiles[i].Button.Visible = false
	end
	ui.Empty.Visible = #sorted == 0
	if not stillOwned then
		selectedId = nil
	end
	renderDetails()
end

local function refresh()
	inventory = Data.Parse(decodeAttribute("TrophyInventory"), DEFAULT_MAX)
	render()
end

local function pop(scale: UIScale, from: number)
	scale.Scale = from
	TweenService:Create(scale, POP, { Scale = 1 }):Play()
end

selectTrophy = function(instanceId: string)
	if selectedId ~= instanceId then
		selectedId = instanceId
		message.For = ""
		render()
	end
	for i, id in tileIds do
		if id == instanceId then
			pop(tiles[i].Scale, 1.08)
		end
	end
end

-- Grid: 3-6 square-ish columns that fill the scroll area's width.
local function layoutGrid()
	local width = ui.Grid.AbsoluteSize.X - 12 - ui.Grid.ScrollBarThickness
	local gap = ui.GridLayout.CellPadding.X.Offset
	local columns = math.clamp(math.floor(width / 110), 3, 6)
	local cell = math.max(math.floor((width - gap * (columns - 1)) / columns), 40)
	ui.GridLayout.CellSize = UDim2.fromOffset(cell, math.floor(cell * 1.25))
end

-- Input --------------------------------------------------------------------

local function setMessage(forId: string, text: string, isError: boolean)
	message.Text, message.IsError, message.For = text, isError, forId
end

local function reasonText(reason: any): string
	if type(reason) == "string" and reason ~= "" then
		return string.sub(reason, 1, 80)
	end
	return "Couldn't do that. Try again!"
end

local function onEquipClicked()
	local id = selectedId
	if busy or not id or os.clock() - lastRequest < EQUIP_GAP then
		return
	end
	local equipped = inventory.EquippedSet[id] == true
	if not equipped and #inventory.Equipped >= inventory.Max then
		return -- button shows "Case full"
	end
	local remote = remotes:FindFirstChild("TrophyEquip")
	if not (remote and remote:IsA("RemoteFunction")) then
		setMessage(id, "Trophies aren't ready yet. Try again!", true)
		renderDetails()
		return
	end

	busy = true
	lastRequest = os.clock()
	setMessage(id, "", false)
	renderDetails()
	local action = if equipped then "Unequip" else "Equip"
	local ok, accepted, reason = pcall(remote.InvokeServer, remote, action, id)
	busy = false
	if not ok then
		setMessage(id, "Couldn't reach the server. Try again!", true)
	elseif accepted ~= true then
		setMessage(id, reasonText(reason), true)
	else
		setMessage(id, if equipped then "Unequipped." else "Equipped!", false)
	end
	renderDetails() -- the new equipped list arrives via the attribute
end

local function setOpen(open: boolean)
	if ui.Panel.Visible == open then
		return
	end
	ui.Panel.Visible = open
	if open then
		layoutGrid()
		pop(ui.PanelScale, 0.85)
	end
end

ui.ToggleButton.Activated:Connect(function()
	setOpen(not ui.Panel.Visible)
end)
ui.CloseButton.Activated:Connect(function()
	setOpen(false)
end)
ui.EquipButton.Activated:Connect(onEquipClicked)
ui.Grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutGrid)
player:GetAttributeChangedSignal("TrophyInventory"):Connect(refresh)
player:GetAttributeChangedSignal("TrophyStats"):Connect(renderPowers)

layoutGrid()
refresh()
renderPowers()
