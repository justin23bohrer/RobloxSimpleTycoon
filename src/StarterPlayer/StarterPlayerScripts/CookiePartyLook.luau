-- CookiePartyLook (client only, ModuleScript)
-- Builds the collectable Cookie Party cookies for CookiePartyCookies.client:
--   Normal     classic golden-brown cookie with chocolate chips
--   Chocolate  dark chocolate cookie with white chips
--   Golden     shiny gold (Neon) cookie with sparkles and a soft glow
--   Giant      a huge, chunky chip cookie (about 2.7x)
-- Each cookie also has a ground beacon (a soft glowing disc where it lands;
-- Golden and Giant add a tall light pillar) so cookies are easy to spot.
--
-- Looks only, built-in parts and materials. Every part is anchored with
-- CanCollide, CanTouch and CanQuery off. Nothing is welded: the client script
-- moves all parts with one BulkMoveTo, using the frames from AddFrames.

local CookiePartyLook = {}

-- A Cylinder's round faces are on its X axis; this turns that axis to point
-- along the frame's Y (a disc lies flat, a pillar stands up).
local UP = CFrame.Angles(0, 0, math.pi / 2)
local GOLDEN_ANGLE = 2.4 -- radians between chips, spreads them evenly
local PILLAR_HEIGHT = 18

type Style = {
	Diameter: number,
	Thickness: number,
	Dough: Color3,
	DoughMaterial: Enum.Material,
	Chip: Color3,
	ChipMaterial: Enum.Material,
	ChipSize: number,
	Chips: number, -- per face
	Beacon: Color3,
	BeaconDiameter: number,
	Pillar: boolean,
	Glow: boolean, -- PointLight + sparkles
	Spin: number, -- radians/s once landed
	Bounce: number, -- landing hop (studs)
	Bob: number, -- idle bob (studs)
	Hop: boolean, -- idle bob as bouncy hops instead of a smooth float
}

local STYLES: { [string]: Style } = {
	Normal = {
		Diameter = 3, Thickness = 0.6,
		Dough = Color3.fromRGB(214, 160, 90), DoughMaterial = Enum.Material.SmoothPlastic,
		Chip = Color3.fromRGB(70, 40, 20), ChipMaterial = Enum.Material.SmoothPlastic, ChipSize = 0.55, Chips = 5,
		Beacon = Color3.fromRGB(255, 225, 150), BeaconDiameter = 5, Pillar = false, Glow = false,
		Spin = 2.2, Bounce = 1.4, Bob = 0.5, Hop = false,
	},
	Chocolate = {
		Diameter = 3, Thickness = 0.6,
		Dough = Color3.fromRGB(85, 50, 30), DoughMaterial = Enum.Material.SmoothPlastic,
		Chip = Color3.fromRGB(250, 245, 235), ChipMaterial = Enum.Material.SmoothPlastic, ChipSize = 0.5, Chips = 6,
		Beacon = Color3.fromRGB(230, 160, 110), BeaconDiameter = 5, Pillar = false, Glow = false,
		Spin = 2.2, Bounce = 1.4, Bob = 0.5, Hop = false,
	},
	Golden = {
		Diameter = 3.2, Thickness = 0.65,
		Dough = Color3.fromRGB(255, 200, 50), DoughMaterial = Enum.Material.Neon,
		Chip = Color3.fromRGB(190, 120, 20), ChipMaterial = Enum.Material.Foil, ChipSize = 0.55, Chips = 5,
		Beacon = Color3.fromRGB(255, 215, 60), BeaconDiameter = 7, Pillar = true, Glow = true,
		Spin = 1.2, Bounce = 1.8, Bob = 0.7, Hop = false,
	},
	Giant = {
		Diameter = 8, Thickness = 1.6,
		Dough = Color3.fromRGB(225, 165, 85), DoughMaterial = Enum.Material.SmoothPlastic,
		Chip = Color3.fromRGB(70, 40, 20), ChipMaterial = Enum.Material.SmoothPlastic, ChipSize = 1.4, Chips = 8,
		Beacon = Color3.fromRGB(255, 120, 200), BeaconDiameter = 13, Pillar = true, Glow = false,
		Spin = 0.9, Bounce = 3.5, Bob = 1.6, Hop = true,
	},
}

export type Cookie = {
	Type: string, -- the style used (unknown types look Normal)
	Style: Style,
	Hover: number, -- studs from the ground to the cookie's center when landed
	Parts: { BasePart }, -- moved with the cookie frame
	Offsets: { CFrame },
	Sizes: { Vector3 },
	Base: { number }, -- each part's transparency when fully shown
	Ground: { BasePart }, -- the beacon, moved with the ground frame
	GroundOffsets: { CFrame },
	GroundBase: { number },
	Light: PointLight?,
	Sparkle: ParticleEmitter?,
	Alpha: number, -- 0 shown .. 1 hidden
	GroundAlpha: number,
	Scale: number,
}

local function newPart(name: string, shape: Enum.PartType, size: Vector3, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1 -- hidden until used
	return part
end

-- The look a type gets: itself, or "Normal" for an unknown type.
function CookiePartyLook.Kind(cookieType: string): string
	return if STYLES[cookieType] then cookieType else "Normal"
end

-- Builds one hidden cookie of this type under parent.
function CookiePartyLook.Build(cookieType: string, parent: Instance): Cookie
	local kind = CookiePartyLook.Kind(cookieType)
	local style = STYLES[kind]
	local radius = style.Diameter / 2
	local cookie: Cookie = {
		Type = kind,
		Style = style,
		-- Cookies stand tilted (like a coin); this keeps the rim off the ground.
		Hover = radius * 0.95 + style.Thickness * 0.3 + 0.4,
		Parts = {},
		Offsets = {},
		Sizes = {},
		Base = {},
		Ground = {},
		GroundOffsets = {},
		GroundBase = {},
		Alpha = 1,
		GroundAlpha = 1,
		Scale = 1,
	}
	local function add(part: BasePart, offset: CFrame, base: number)
		table.insert(cookie.Parts, part)
		table.insert(cookie.Offsets, offset)
		table.insert(cookie.Sizes, part.Size)
		table.insert(cookie.Base, base)
	end
	local function addGround(part: BasePart, offset: CFrame, base: number)
		table.insert(cookie.Ground, part)
		table.insert(cookie.GroundOffsets, offset)
		table.insert(cookie.GroundBase, base)
	end

	local disc = newPart("Cookie", Enum.PartType.Cylinder, Vector3.new(style.Thickness, style.Diameter, style.Diameter), style.Dough, style.DoughMaterial)
	add(disc, UP, 0)
	for side = -1, 1, 2 do
		for i = 1, style.Chips do
			local angle = i * GOLDEN_ANGLE + (if side < 0 then 1 else 0)
			local dist = radius * (0.2 + 0.55 * (i / style.Chips))
			local chip = newPart("Chip", Enum.PartType.Ball, Vector3.one * style.ChipSize, style.Chip, style.ChipMaterial)
			add(chip, CFrame.new(math.cos(angle) * dist, side * style.Thickness / 2, math.sin(angle) * dist), 0)
		end
	end

	local ring = newPart("Beacon", Enum.PartType.Cylinder, Vector3.new(0.12, style.BeaconDiameter, style.BeaconDiameter), style.Beacon, Enum.Material.Neon)
	addGround(ring, CFrame.new(0, 0.08, 0) * UP, 0.55)
	if style.Pillar then
		local pillar = newPart("Pillar", Enum.PartType.Cylinder, Vector3.new(PILLAR_HEIGHT, 0.7, 0.7), style.Beacon, Enum.Material.Neon)
		addGround(pillar, CFrame.new(0, PILLAR_HEIGHT / 2, 0) * UP, 0.75)
	end

	if style.Glow then
		local light = Instance.new("PointLight")
		light.Color = style.Dough
		light.Brightness = 1.5
		light.Range = 10
		light.Shadows = false
		light.Enabled = false
		light.Parent = disc
		cookie.Light = light

		local attachment = Instance.new("Attachment")
		attachment.Parent = disc
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160))
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Lifetime = NumberRange.new(0.5, 0.9)
		sparkle.Speed = NumberRange.new(1, 2.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Rate = 8
		sparkle.Enabled = false
		sparkle.Parent = attachment
		cookie.Sparkle = sparkle
	end

	for _, part in cookie.Parts do
		part.Parent = parent
	end
	for _, part in cookie.Ground do
		part.Parent = parent
	end
	return cookie
end

-- Fades the cookie (alpha) and its beacon (groundAlpha): 0 shown, 1 hidden.
function CookiePartyLook.SetAlpha(cookie: Cookie, alpha: number, groundAlpha: number)
	if alpha ~= cookie.Alpha then
		cookie.Alpha = alpha
		for i, part in cookie.Parts do
			local base = cookie.Base[i]
			part.Transparency = base + (1 - base) * alpha
		end
	end
	if groundAlpha ~= cookie.GroundAlpha then
		cookie.GroundAlpha = groundAlpha
		for i, part in cookie.Ground do
			local base = cookie.GroundBase[i]
			part.Transparency = base + (1 - base) * groundAlpha
		end
	end
end

-- Grows/shrinks the cookie (not the beacon); 1 = normal size.
function CookiePartyLook.SetScale(cookie: Cookie, scale: number)
	if scale == cookie.Scale then
		return
	end
	cookie.Scale = scale
	for i, part in cookie.Parts do
		part.Size = cookie.Sizes[i] * scale
	end
end

-- Turns a cookie on (taken from the pool) or off (back in the pool: hidden,
-- normal size, no glow).
function CookiePartyLook.SetActive(cookie: Cookie, active: boolean)
	CookiePartyLook.SetScale(cookie, 1)
	CookiePartyLook.SetAlpha(cookie, if active then 0 else 1, 1)
	if cookie.Light then
		cookie.Light.Enabled = active
	end
	if cookie.Sparkle then
		cookie.Sparkle.Enabled = active
	end
end

-- Appends the cookie's parts and their CFrames for this frame. groundFrame
-- nil = leave the beacon where it is (it is hidden).
function CookiePartyLook.AddFrames(cookie: Cookie, frame: CFrame, groundFrame: CFrame?, parts: { BasePart }, frames: { CFrame })
	local scale = cookie.Scale
	for i, part in cookie.Parts do
		local offset = cookie.Offsets[i]
		if scale ~= 1 then
			offset = offset.Rotation + offset.Position * scale
		end
		table.insert(parts, part)
		table.insert(frames, frame * offset)
	end
	if groundFrame then
		for i, part in cookie.Ground do
			table.insert(parts, part)
			table.insert(frames, groundFrame * cookie.GroundOffsets[i])
		end
	end
end

return CookiePartyLook
