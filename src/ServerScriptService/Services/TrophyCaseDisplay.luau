-- TrophyCaseDisplay (server only)
-- Helper for TrophyService: puts trophy models on a plot's Trophy Case
-- slots (TrophySlot1..N, N = Config.TrophyCaseSlots). Presentation only;
-- TrophyService decides whose trophies are shown and when.
--
-- The trophies go in a runtime "CaseTrophies" folder in the plot (not inside
-- the TrophyCase model, so PlotVisibility never tracks them) and are built
-- by TrophyModel. Each stands on its slot facing the slot's LookVector.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TrophyModel = require(script.Parent.TrophyModel)

local TrophyCaseDisplay = {}

local FOLDER = "CaseTrophies"

-- Removes every trophy shown in the plot's case.
function TrophyCaseDisplay.Clear(plot: Instance)
	local folder = plot:FindFirstChild(FOLDER)
	if folder then
		folder:Destroy()
	end
end

-- Shows the newest Config.TrophyCaseSlots of `records` (oldest first) on the
-- case's slots, slot 1 = newest. Replaces whatever was shown before.
function TrophyCaseDisplay.Show(plot: Instance, case: Instance, records: { { Variant: string } })
	TrophyCaseDisplay.Clear(plot)
	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	for slot = 1, math.min(Config.TrophyCaseSlots, #records) do
		local spot = case:FindFirstChild(`TrophySlot{slot}`)
		if spot and spot:IsA("BasePart") then
			local record = records[#records - slot + 1]
			local trophy = TrophyModel.Build(record.Variant, Config.TrophyCaseScale)
			trophy:PivotTo(spot.CFrame * CFrame.new(0, spot.Size.Y / 2, 0))
			trophy.Parent = folder
		end
	end
	folder.Parent = plot
end

return TrophyCaseDisplay
