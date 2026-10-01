-- TrophyPrompt (client, LocalScript)
-- Presentation only for the Caleb Trophy claim (TrophyService on the server
-- decides everything):
-- * Hides the "Claim Caleb Trophy" prompt on the podium trophy
--   (Workspace.Map.CalebClaimTrophy) for this player unless they are
--   eligible: CalebFed > 0 and not CalebTrophyClaimed. Only a local
--   visibility change; the server re-checks eligibility on every claim.
-- * Shows a notification when the server reports a claim result through
--   the CalebTrophyNotice player attribute.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CalebEvent"))
local TrophyVariants = require(ReplicatedStorage.Shared:WaitForChild("TrophyVariants"))

local player = Players.LocalPlayer
local PlayerAttr = CalebEvent.PlayerAttr
local CLAIM_NAME = "CalebClaimTrophy"

local prompts: { [ProximityPrompt]: true } = {}

local function isEligible(): boolean
	local fed = player:GetAttribute(PlayerAttr.Fed)
	return typeof(fed) == "number" and fed > 0 and player:GetAttribute(PlayerAttr.TrophyClaimed) ~= true
end

local function updatePrompts()
	local eligible = isEligible()
	for prompt in prompts do
		prompt.Enabled = eligible
	end
end

local function track(item: Instance)
	if item:IsA("ProximityPrompt") then
		prompts[item] = true
		item.Enabled = isEligible()
		item.Destroying:Connect(function()
			prompts[item] = nil
		end)
	end
end

local function watchTrophy(model: Instance)
	if model.Name ~= CLAIM_NAME then
		return
	end
	model.DescendantAdded:Connect(track) -- parts may stream in later
	for _, item in model:GetDescendants() do
		track(item)
	end
end

local function notify(title: string, text: string)
	-- SetCore can fail for a moment while the core scripts load; retry.
	for _ = 1, 5 do
		local ok = pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
			Title = title,
			Text = text,
			Duration = 8,
		})
		if ok then
			return
		end
		task.wait(1)
	end
end

local lastNoticeId = nil
local function onNotice()
	local raw = player:GetAttribute(PlayerAttr.TrophyNotice)
	if typeof(raw) ~= "string" then
		return
	end
	local ok, notice = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or typeof(notice) ~= "table" or notice.Id == lastNoticeId then
		return
	end
	lastNoticeId = notice.Id
	local name = if typeof(notice.Variant) == "string" then TrophyVariants.Get(notice.Variant).DisplayName else "Caleb Trophy"
	local rarity = if typeof(notice.Variant) == "string" then TrophyVariants.Get(notice.Variant).Rarity else ""
	if notice.Kind == "Saved" then
		notify("🏆 Caleb Trophy!", `You got {name} ({rarity})! Equipped trophies in a built Trophy Case give their powers.`)
	elseif notice.Kind == "Unsaved" then
		notify("🏆 Caleb Trophy!", `You got {name} ({rarity})! It couldn't be saved, so you only have it until you leave this server.`)
	elseif notice.Kind == "AlreadyOwned" then
		notify("Caleb Trophy", "You already have this round's trophy.")
	elseif notice.Kind == "NotEligible" then
		notify("Caleb Trophy", "Only players who fed Caleb this round can claim a trophy (one each, before time runs out).")
	end
end

player:GetAttributeChangedSignal(PlayerAttr.Fed):Connect(updatePrompts)
player:GetAttributeChangedSignal(PlayerAttr.TrophyClaimed):Connect(updatePrompts)
player:GetAttributeChangedSignal(PlayerAttr.TrophyNotice):Connect(onNotice)

local map = Workspace:WaitForChild("Map")
map.ChildAdded:Connect(watchTrophy)
for _, child in map:GetChildren() do
	watchTrophy(child)
end
