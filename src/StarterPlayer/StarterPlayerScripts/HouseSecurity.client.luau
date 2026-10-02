-- HouseSecurity (client only)
-- Lets the local player walk through the red SecurityBars of their OWN house.
--
-- The server's bars (HouseSecurityService) are solid for everyone. Here, on
-- this client only, CanCollide is turned off on the bar parts of the plot
-- whose OwnerUserId attribute is this player. Characters are simulated by
-- their own client, so the owner passes while everyone else is blocked.
-- It is kept off when the server re-sends CanCollide (PlotVisibility shows
-- the Walls build) and when parts stream in; it is put back when the plot
-- stops being ours. Decides nothing: the server owns the bars and the timer.
-- No UI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HouseRaid = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HouseRaid"))

local player = Players.LocalPlayer
local plotsFolder = Workspace:WaitForChild("Map"):WaitForChild("Plots")

local hooked: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local watched: { [Instance]: boolean } = {}

local function isMine(plot: Instance): boolean
	return plot:GetAttribute("OwnerUserId") == player.UserId
end

local function barParts(plot: Instance): { BasePart }
	local parts = {}
	local bars = plot:FindFirstChild(HouseRaid.Part.SecurityBars)
	if bars then
		for _, item in bars:GetDescendants() do
			if item:IsA("BasePart") then
				table.insert(parts, item)
			end
		end
	end
	return parts
end

local function hookPart(plot: Instance, part: BasePart)
	if hooked[part] then
		return
	end
	hooked[part] = true
	part:GetPropertyChangedSignal("CanCollide"):Connect(function()
		if part.CanCollide and isMine(plot) then
			part.CanCollide = false
		end
	end)
	if isMine(plot) then
		part.CanCollide = false
	end
end

local function hookBars(plot: Instance, bars: Instance)
	for _, part in barParts(plot) do
		hookPart(plot, part)
	end
	bars.DescendantAdded:Connect(function(item)
		if item:IsA("BasePart") then
			hookPart(plot, item)
		end
	end)
end

local function watchPlot(plot: Instance)
	if watched[plot] then
		return
	end
	watched[plot] = true

	local wasMine = isMine(plot)
	plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		local mine = isMine(plot)
		if mine == wasMine then
			return
		end
		wasMine = mine
		for _, part in barParts(plot) do
			-- Ours: pass through. No longer ours: solid again while shown
			-- (PlotVisibility hides a part with Transparency 1 + no collide).
			part.CanCollide = not mine and part.Transparency < 1
		end
	end)

	local bars = plot:FindFirstChild(HouseRaid.Part.SecurityBars)
	if bars then
		hookBars(plot, bars)
	end
	plot.ChildAdded:Connect(function(child)
		if child.Name == HouseRaid.Part.SecurityBars then
			hookBars(plot, child) -- streamed in later
		end
	end)
end

for _, plot in plotsFolder:GetChildren() do
	watchPlot(plot)
end
plotsFolder.ChildAdded:Connect(watchPlot)
