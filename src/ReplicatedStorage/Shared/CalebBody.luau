-- CalebBody (shared: server and client)
-- Which parts of Workspace.Map.Statue are Caleb's body.
--
-- The statue's children are Caleb's body parts, the Pedestal* parts, and
-- folders (FeedPads, Podium). Only body parts are scaled (StatueShape),
-- hidden (StatueShape.SetHidden), and animated (CalebAnimator.client).
-- A body part is any BasePart whose top-level ancestor under the statue is a
-- BasePart not named "Pedestal...". Anything inside a folder is never body.
-- Pure lookup: it decides nothing and changes nothing.

local CalebBody = {}

function CalebBody.IsBodyPart(statue: Instance, item: Instance): boolean
	if not item:IsA("BasePart") or not item:IsDescendantOf(statue) then
		return false
	end
	local top: Instance = item
	while top.Parent ~= statue do
		top = top.Parent :: Instance
	end
	return top:IsA("BasePart") and not top.Name:match("^Pedestal")
end

-- Every body part currently in the statue (with streaming, only the loaded ones).
function CalebBody.GetParts(statue: Instance): { BasePart }
	local parts = {}
	for _, item in statue:GetDescendants() do
		if CalebBody.IsBodyPart(statue, item) then
			table.insert(parts, item :: BasePart)
		end
	end
	return parts
end

return table.freeze(CalebBody)
