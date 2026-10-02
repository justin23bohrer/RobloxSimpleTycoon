-- HouseRaid (shared: server and client)
-- The contract for house security, trophy stealing and the push (see
-- ARCHITECTURE.md "House Raid (contract)"). Names only: it decides nothing.
-- The server's HouseSecurityService, TheftService and PushService own the
-- real state; clients read attributes and draw.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HouseRaid = {}

-- Parts/models in every plot (Workspace.Map.Plots.PlotN), made in Plot1's
-- map file and copied to Plot2-4 by tools/plots/generate_plots.py.
HouseRaid.Part = table.freeze({
	SecurityPad = "SecurityPad", -- round floor button inside the house (green/red)
	SecurityBars = "SecurityBars", -- Model: red metal bars across the front doorway
	TrophyStash = "TrophyStash", -- floor pad inside the house: bring a stolen trophy here
})

-- Attributes on each plot Model. Written only by the server.
HouseRaid.PlotAttr = table.freeze({
	SecurityActive = "SecurityActive", -- boolean: bars are up
	SecurityEndsAt = "SecurityEndsAt", -- number: Workspace:GetServerTimeNow() when they drop (0 when down)
})

-- Attributes on each Player. Written only by the server.
HouseRaid.PlayerAttr = table.freeze({
	-- string: JSON { Variant, InstanceId, FromUserId } while this player
	-- carries a stolen trophy; "" (or nil) when not carrying.
	Carrying = "CarryingTrophy",
})

-- On each displayed trophy Model in a plot's CaseTrophies folder (set by
-- TrophyCaseDisplay): who owns it and which instance it is.
HouseRaid.TrophyAttr = table.freeze({
	OwnerUserId = "TrophyOwnerUserId", -- number
	InstanceId = "TrophyInstanceId", -- string
})

-- The server ProximityPrompt on each displayed trophy Model.
HouseRaid.StealPromptName = "StealPrompt"
-- The carried trophy Model welded above a thief's head (inside the character).
HouseRaid.CarriedModelName = "CarriedTrophy"

-- RemoteEvents in ReplicatedStorage.Remotes.
HouseRaid.Remote = table.freeze({
	Push = "PushRequest", -- client -> server: () "I pushed" (untrusted; server finds the target)
	PushFX = "PushFX", -- server -> all: (pusherUserId: number, targetUserId: number?) play the push / hit
	Knockback = "PushKnockback", -- server -> the pushed player: (velocity: Vector3) apply it locally
})

function HouseRaid.GetRemote(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name) :: RemoteEvent
end

return table.freeze(HouseRaid)
