-- TheftPrompt (client, LocalScript)
-- Presentation only for trophy stealing (TheftService on the server decides
-- everything and re-checks every steal):
-- * Hides the "Steal Trophy" prompt (HouseRaid.StealPromptName) on trophies
--   whose TrophyOwnerUserId is this player (your own case), and on every
--   trophy while you carry one (CarryingTrophy). Only a local Enabled change.
-- * Shows the server's TheftNotice player attribute (why a steal couldn't
--   start, or why the trophy went back) as a small notification.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local HouseRaid = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HouseRaid"))

local player = Players.LocalPlayer
local prompts: { [ProximityPrompt]: true } = {}

local function isCarrying(): boolean
	local carrying = player:GetAttribute(HouseRaid.PlayerAttr.Carrying)
	return typeof(carrying) == "string" and carrying ~= ""
end

local function update(prompt: ProximityPrompt)
	local trophy = prompt:FindFirstAncestorWhichIsA("Model")
	local mine = trophy ~= nil and trophy:GetAttribute(HouseRaid.TrophyAttr.OwnerUserId) == player.UserId
	prompt.Enabled = not mine and not isCarrying()
end

local function track(item: Instance)
	if item:IsA("ProximityPrompt") and item.Name == HouseRaid.StealPromptName then
		prompts[item] = true
		update(item)
		item.Destroying:Connect(function()
			prompts[item] = nil
		end)
	end
end

local function notify(text: string)
	-- SetCore can fail for a moment while the core scripts load; retry.
	for _ = 1, 5 do
		local ok = pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
			Title = "Trophy",
			Text = text,
			Duration = 5,
		})
		if ok then
			return
		end
		task.wait(1)
	end
end

local lastNoticeId = nil
local function onNotice()
	local raw = player:GetAttribute(HouseRaid.PlayerAttr.TheftNotice)
	if typeof(raw) ~= "string" then
		return
	end
	local ok, notice = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or typeof(notice) ~= "table" or notice.Id == lastNoticeId or typeof(notice.Text) ~= "string" then
		return
	end
	lastNoticeId = notice.Id
	notify(notice.Text)
end

player:GetAttributeChangedSignal(HouseRaid.PlayerAttr.TheftNotice):Connect(onNotice)
player:GetAttributeChangedSignal(HouseRaid.PlayerAttr.Carrying):Connect(function()
	for prompt in prompts do
		update(prompt)
	end
end)

-- Case trophies are rebuilt by the server and stream in and out.
local plots = Workspace:WaitForChild("Map"):WaitForChild("Plots")
plots.DescendantAdded:Connect(track)
for _, item in plots:GetDescendants() do
	track(item)
end
