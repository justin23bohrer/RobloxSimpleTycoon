-- PhotoCamera (client only)
-- TESTING ONLY: Photo Mode camera presets and "hide the UI" for icon /
-- thumbnail screenshots. Does nothing unless Shared/PhotoMode.Enabled
-- (Config.DevPhotoMode is true AND the game runs in Roblox Studio).
--
-- * 1-6: snap the camera (Scriptable) to PhotoMode.Shots, placed relative to
--   the local player's own plot's Base, so they work on every turned plot.
-- * 0 or C: back to the normal camera.
-- * H: hide / show the UI. Hides every enabled ScreenGui (this hint too),
--   every enabled BillboardGui except the pad labels (a "Label" on a part
--   named ...Pad / ...Button...), and Roblox's own UI (chat, player list,
--   backpack); remembers what it hid and shows exactly that again.
-- Presentation only: never talks to the server, changes nothing it owns.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PhotoMode = require(ReplicatedStorage.Shared.PhotoMode)

if not PhotoMode.Enabled then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SHOT_KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
}
local HINT_TEXT = "PHOTO MODE (Studio only)   1-6 shots   0 / C normal camera   H hide UI"

-- The hint, top-left and small. Hidden with everything else by H.
local hint = Instance.new("ScreenGui")
hint.Name = "PhotoModeHint"
hint.ResetOnSpawn = false
local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(560, 26)
label.Position = UDim2.fromOffset(12, 12)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.4
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.Text = HINT_TEXT
label.Parent = hint
hint.Parent = playerGui

local normalFov: number? = nil -- the FieldOfView before the first shot

local function ownBase(): BasePart?
	local plots = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			local base = plot:FindFirstChild("Base")
			return if base and base:IsA("BasePart") then base else nil
		end
	end
	return nil
end

local function showShot(index: number)
	local shot = PhotoMode.Shots[index]
	local base = ownBase()
	if not shot or not base then
		label.Text = "No plot yet - wait a moment and try again"
		return
	end
	local camera = Workspace.CurrentCamera
	normalFov = normalFov or camera.FieldOfView
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = PhotoMode.ShotCFrame(base.CFrame, shot)
	camera.FieldOfView = shot.Fov
	label.Text = `{HINT_TEXT}   [{index}: {shot.Name}]`
end

local function normalCamera()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	if normalFov then
		camera.FieldOfView = normalFov
		normalFov = nil
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	label.Text = HINT_TEXT
end

-- What H hid (to show again), or nil while the UI is shown.
local hidden: { guis: { LayerCollector }, core: { Enum.CoreGuiType } }? = nil

local function isPadLabel(gui: Instance): boolean
	local part = gui.Parent
	return gui.Name == "Label"
		and part ~= nil
		and part:IsA("BasePart")
		and (part.Name:match("Pad$") ~= nil or part.Name:find("Button", 1, true) ~= nil)
end

local function hideUi()
	local record = { guis = {}, core = {} }
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui.Enabled then
			gui.Enabled = false
			table.insert(record.guis, gui)
		end
	end
	for _, root in { Workspace, playerGui } do
		for _, gui in root:GetDescendants() do
			if gui:IsA("BillboardGui") and gui.Enabled and not isPadLabel(gui) then
				gui.Enabled = false
				table.insert(record.guis, gui)
			end
		end
	end
	for _, coreType in Enum.CoreGuiType:GetEnumItems() do
		if coreType ~= Enum.CoreGuiType.All and StarterGui:GetCoreGuiEnabled(coreType) then
			StarterGui:SetCoreGuiEnabled(coreType, false)
			table.insert(record.core, coreType)
		end
	end
	hidden = record
end

local function showUi()
	local record = hidden
	hidden = nil
	if not record then
		return
	end
	for _, gui in record.guis do
		if gui.Parent then
			gui.Enabled = true
		end
	end
	for _, coreType in record.core do
		StarterGui:SetCoreGuiEnabled(coreType, true)
	end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return -- typing in chat, etc.
	end
	local key = input.KeyCode
	if SHOT_KEYS[key] then
		showShot(SHOT_KEYS[key])
	elseif key == Enum.KeyCode.Zero or key == Enum.KeyCode.C then
		normalCamera()
	elseif key == Enum.KeyCode.H then
		if hidden then
			showUi()
		else
			hideUi()
		end
	end
end)
