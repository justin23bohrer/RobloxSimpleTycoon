-- PlotVisibility (server only)
-- Hides and shows a part or model, and everything inside it, without
-- destroying it, so it comes back exactly as the map built it.
--
-- Hide makes parts invisible and non-solid (Transparency 1, no collide,
-- touch, or query) and turns off Billboard/Surface GUIs. It saves the
-- original values the first time, and Show puts them back. Hiding something
-- already hidden, or showing something never hidden, does nothing.
--
-- A hidden part cannot be touched, so its Touched handlers never fire.
-- Used by PlotStages and BuyButtons. Presentation only; it decides nothing.

local PlotVisibility = {}

type SavedPart = {
	Transparency: number,
	CanCollide: boolean,
	CanTouch: boolean,
	CanQuery: boolean,
}

local savedParts: { [BasePart]: SavedPart } = {}
local savedGuis: { [LayerCollector]: boolean } = {}

local function hideOne(item: Instance)
	if item:IsA("BasePart") then
		if savedParts[item] then
			return
		end
		savedParts[item] = {
			Transparency = item.Transparency,
			CanCollide = item.CanCollide,
			CanTouch = item.CanTouch,
			CanQuery = item.CanQuery,
		}
		item.Transparency = 1
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
	elseif item:IsA("LayerCollector") then
		if savedGuis[item] ~= nil then
			return
		end
		savedGuis[item] = item.Enabled
		item.Enabled = false
	end
end

local function showOne(item: Instance)
	if item:IsA("BasePart") then
		local saved = savedParts[item]
		if not saved then
			return
		end
		savedParts[item] = nil
		item.Transparency = saved.Transparency
		item.CanCollide = saved.CanCollide -- before CanQuery: CanQuery needs it
		item.CanQuery = saved.CanQuery
		item.CanTouch = saved.CanTouch
	elseif item:IsA("LayerCollector") then
		local enabled = savedGuis[item]
		if enabled == nil then
			return
		end
		savedGuis[item] = nil
		item.Enabled = enabled
	end
end

function PlotVisibility.Hide(root: Instance)
	hideOne(root)
	for _, item in root:GetDescendants() do
		hideOne(item)
	end
end

function PlotVisibility.Show(root: Instance)
	showOne(root)
	for _, item in root:GetDescendants() do
		showOne(item)
	end
end

return PlotVisibility
