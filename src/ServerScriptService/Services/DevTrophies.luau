-- DevTrophies (server only)
-- TESTING ONLY: Config.DevAllTrophies gives every player
-- Config.DevAllTrophiesCopies session-only copies of every collectable
-- trophy variant (Weight > 0), so all trophies and power stacking can be
-- tested without claiming them one by one.
--
-- * Studio only (RunService:IsStudio()), like DevUnlimitedCash: a published
--   game never gives these.
-- * Session-only (TrophyInventory.AddSessionTrophy): never written to the
--   DataStore, so the real save stays clean. Gone when the server closes.
-- * Not auto-equipped: the player picks which ones to display.
-- * Also on in Photo Mode (Shared/PhotoMode, Studio only), so the showcase
--   plot's back door opens (it needs Config.BackyardTrophies trophies).
-- * EventId DEV_EVENT_ID, so they never match a real Caleb cycle id.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local PhotoMode = require(ReplicatedStorage.Shared.PhotoMode)
local TrophyVariants = require(ReplicatedStorage.Shared.TrophyVariants)
local TrophyInventory = require(script.Parent.TrophyInventory)

local DevTrophies = {}

local DEV_EVENT_ID = "dev"

local enabled = (Config.DevAllTrophies and RunService:IsStudio()) or PhotoMode.Enabled
local given: { [number]: true } = {} -- session trophies outlive a rejoin, so give once per UserId
local announced = false

-- Gives the dev trophies if the switch is on (Studio only). Call after the
-- player's data load attempt finished. Returns true if any were given.
function DevTrophies.Give(player: Player): boolean
	if not enabled or given[player.UserId] then
		return false
	end
	given[player.UserId] = true
	local copies = math.max(0, math.floor(Config.DevAllTrophiesCopies))
	local count = 0
	for _, variant in TrophyVariants.List do
		if variant.Weight > 0 and TrophyVariants.Exists(variant.Id) then
			for _ = 1, copies do
				TrophyInventory.AddSessionTrophy(player, TrophyInventory.NewRecord(variant.Id, DEV_EVENT_ID), false)
				count += 1
			end
		end
	end
	if not announced then
		announced = true
		print(`[DevAllTrophies] gave {count} trophies (session only, not saved). Set Config.DevAllTrophies = false to turn it off.`)
	end
	return count > 0
end

return DevTrophies
