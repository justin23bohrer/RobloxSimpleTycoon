-- PowerLooksRings (client only, helper for PowerLooks.client)
-- Flat rings of light that spring out from a point and fade, with a quick
-- light flash: the jump ring on the ground and the double-jump ring in the
-- air. Play(position, color, radius, seconds).
--
-- Visual only and client-local: each ring is an invisible anchored Part with
-- a hollow CylinderHandleAdornment and a PointLight, in a client-local
-- Workspace folder "PowerLooksFX" (never replicated). At most POOL_SIZE are
-- ever made (lazily, on the first jumps) and reused; when all are busy the
-- oldest is restarted. One Heartbeat connection animates them and exists
-- only while a ring is playing.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PowerLooksRings = {}

-- Looks only; not gameplay tuning.
local POOL_SIZE = 8
local START_RADIUS = 0.6
local HEIGHT = 0.12 -- how thick the ring is up/down
local WIDTH_START = 0.7 -- ring band width (studs) at the start ...
local WIDTH_END = 0.12 -- ... and at the end
local FLASH_BRIGHTNESS = 4
local FLASH_RANGE = 12

type Ring = {
	part: Part,
	ring: CylinderHandleAdornment,
	light: PointLight,
	start: number,
	seconds: number,
	radius: number,
	active: boolean,
}

local pool: { Ring } = {}
local nextReuse = 1
local playing = 0
local heartbeat: RBXScriptConnection? = nil
local folder: Folder? = nil
-- CylinderHandleAdornment.InnerRadius makes it a ring; if this engine has
-- no such property, rings fall back to fading discs.
local hollow = true

local function makeRing(): Ring
	if not folder or folder.Parent == nil then
		local made = Instance.new("Folder")
		made.Name = "PowerLooksFX"
		made.Parent = Workspace
		folder = made
	end
	local part = Instance.new("Part")
	part.Name = "PowerRing"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)

	local ring = Instance.new("CylinderHandleAdornment")
	ring.Adornee = part
	ring.CFrame = CFrame.Angles(math.rad(90), 0, 0) -- height along Y: lies flat
	ring.Height = HEIGHT
	ring.Visible = false
	if hollow then
		local band: any = ring
		hollow = pcall(function()
			band.InnerRadius = 0
		end)
	end
	ring.Parent = part

	local light = Instance.new("PointLight")
	light.Brightness = 0
	light.Range = FLASH_RANGE
	light.Shadows = false
	light.Parent = part

	part.Parent = folder
	return {
		part = part,
		ring = ring,
		light = light,
		start = 0,
		seconds = 1,
		radius = 1,
		active = false,
	}
end

local function stop(r: Ring)
	r.active = false
	r.ring.Visible = false
	r.light.Brightness = 0
	playing -= 1
end

local function step()
	local now = os.clock()
	for _, r in pool do
		if not r.active then
			continue
		end
		local a = (now - r.start) / r.seconds
		if a >= 1 then
			stop(r)
			continue
		end
		local eased = 1 - (1 - a) ^ 3 -- fast out, gentle settle
		local radius = START_RADIUS + (r.radius - START_RADIUS) * eased
		r.ring.Radius = radius
		if hollow then
			local width = WIDTH_START + (WIDTH_END - WIDTH_START) * a
			local band: any = r.ring
			band.InnerRadius = math.max(0, radius - width)
			r.ring.Transparency = a ^ 1.5
		else
			r.ring.Transparency = 0.5 + 0.5 * a
		end
		r.light.Brightness = FLASH_BRIGHTNESS * (1 - a) ^ 2
	end
	if playing <= 0 and heartbeat then
		playing = 0
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

-- A ring of `color` springing out to `radius` studs around `position`
-- (lying flat), fading over `seconds`.
function PowerLooksRings.Play(position: Vector3, color: Color3, radius: number, seconds: number)
	if folder and folder.Parent == nil then
		-- Our folder was removed from Workspace: start a fresh pool.
		table.clear(pool)
		playing = 0
		nextReuse = 1
		folder = nil
	end
	local r: Ring? = nil
	for _, candidate in pool do
		if not candidate.active then
			r = candidate
			break
		end
	end
	if not r and #pool < POOL_SIZE then
		r = makeRing()
		table.insert(pool, r :: Ring)
	end
	if not r then
		r = pool[nextReuse] -- all busy: restart the oldest
		nextReuse = nextReuse % #pool + 1
	end
	local ring = r :: Ring
	if not ring.active then
		playing += 1
	end
	ring.active = true
	ring.start = os.clock()
	ring.seconds = math.max(seconds, 0.05)
	ring.radius = radius
	ring.part.CFrame = CFrame.new(position)
	ring.ring.Color3 = color
	ring.ring.Radius = START_RADIUS
	ring.ring.Transparency = 0
	ring.ring.Visible = true
	ring.light.Color = color
	ring.light.Brightness = FLASH_BRIGHTNESS
	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(step)
	end
end

return PowerLooksRings
