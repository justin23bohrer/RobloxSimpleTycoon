-- CantAffordSound (client only)
-- Plays Config.TycoonSounds.CantAfford (a soft "nope") when the server fires
-- Remotes.CantAfford at this player: they stepped on a buy button they can't
-- afford. The server decides that and rate-limits it (TycoonSounds); this only
-- plays the sound, 2D, so only this player hears it. Empty id = silent.
-- Presentation only: never talks back to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CantAfford") :: RemoteEvent

local value = Config.TycoonSounds.CantAfford
if typeof(value) ~= "string" or value == "" then
	return -- no id: skipped silently (the server prints the missing ids in Studio)
end

local sound = Instance.new("Sound")
sound.Name = "TycoonCantAfford"
sound.SoundId = if value:match("^%d+$") then "rbxassetid://" .. value else value
sound.Volume = Config.TycoonSoundVolumes.CantAfford or 0.5
sound.Parent = SoundService

remote.OnClientEvent:Connect(function()
	sound:Play()
end)
