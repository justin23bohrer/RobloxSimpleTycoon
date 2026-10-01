-- TrophyModel (server only)
-- Builds a small cartoony Caleb Trophy Model from a variant
-- (Shared/TrophyVariants): a plinth with a gold "CALEB TROPHY" nameplate,
-- a mini Caleb in the statue's style (big round head, shaggy hair cap, big
-- eyes, wide grin, round belly) in the variant's color and pose, its
-- accessories (TrophyAccessories), and its effect (sparkles or a glow).
-- Used by TrophyService for both the big claim trophy on Caleb's podium and
-- the small ones in each house's Trophy Case. Presentation only.
--
-- Every part is anchored with CanCollide/CanTouch/CanQuery off. The model's
-- pivot is the bottom center of the plinth and it faces its pivot's
-- LookVector (-Z), so `model:PivotTo(spot)` stands it on `spot`.
-- At scale 1 it is about 1.8 studs wide and 3 to 4 studs tall.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrophyVariants = require(ReplicatedStorage.Shared.TrophyVariants)
local TrophyAccessories = require(script.Parent.TrophyAccessories)

local TrophyModel = {}

local BALL = Enum.PartType.Ball
local GOLD = Color3.fromRGB(255, 200, 40)
local DARK = Color3.fromRGB(40, 28, 20)
local SHOULDER_Y = 1.76
local HEAD = Vector3.new(0, 2.3, 0)

-- Arm angles in degrees for each pose: X swings the arm forward (toward the
-- front), Z swings it out to the side (positive = away from the body for
-- the right arm, so the left arm uses negative numbers to go out).
local POSES = {
	Down = { Right = { 0, 10 }, Left = { 0, -10 } },
	ArmsUp = { Right = { 0, 155 }, Left = { 0, -155 } },
	Wave = { Right = { 0, 140 }, Left = { 0, -12 } },
	BellyPat = { Right = { 50, -35 }, Left = { 50, 35 } },
	HandOnHip = { Right = { 0, 10 }, Left = { -10, -45 } },
	HoldCookie = { Right = { 80, 8 }, Left = { 0, -12 } },
}

local function addNameplate(plate: BasePart, title: string, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "NameplateGui"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(300, 80)
	gui.LightInfluence = 0
	local function label(name: string, text: string, y: number, height: number, textColor: Color3, stroke: number)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Text = text
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = textColor
		l.TextStrokeColor3 = DARK
		l.TextStrokeTransparency = stroke
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.04, y)
		l.Size = UDim2.fromScale(0.92, height)
		l.Parent = gui
	end
	label("Title", "CALEB TROPHY", 0.04, 0.4, DARK, 1)
	label("VariantName", title, 0.46, 0.5, color, 0)
	gui.Parent = plate
end

local function addEffect(model: Model, variant: TrophyVariants.Variant, scale: number)
	local head = model:FindFirstChild("Head")
	local torso = model:FindFirstChild("Torso")
	if variant.Effect == "Sparkles" and head then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = variant.EffectColor
		sparkles.Parent = head
	elseif variant.Effect == "Glow" and torso then
		local light = Instance.new("PointLight")
		light.Color = variant.EffectColor
		light.Brightness = 2
		light.Range = math.clamp(4 * scale, 4, 40)
		light.Parent = torso
	end
end

-- Builds the trophy for a variant Id (unknown Ids use the fallback look).
-- `label` replaces the variant's name on the nameplate (e.g. on the podium).
function TrophyModel.Build(variantId: string, scale: number?, label: string?): Model
	local variant = TrophyVariants.Get(variantId)
	local model = Instance.new("Model")
	model.Name = "CalebTrophy"
	model:SetAttribute("Variant", variantId)

	local function make(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): BasePart
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		if shape then
			part.Shape = shape
		end
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end

	-- Plinth with a gold trim and nameplate.
	local base = variant.Base
	make("Plinth", Vector3.new(1.7, 0.5, 1.7), CFrame.new(0, 0.25, 0), base.Color, base.Material)
	make("PlinthTrim", Vector3.new(1.78, 0.08, 1.78), CFrame.new(0, 0.5, 0), GOLD, Enum.Material.SmoothPlastic)
	local plate = make("Nameplate", Vector3.new(1.3, 0.34, 0.04), CFrame.new(0, 0.26, -0.87), GOLD)
	local rarity = TrophyVariants.Rarities[variant.Rarity] or TrophyVariants.Rarities.Common
	addNameplate(plate, label or variant.DisplayName, rarity.Color)

	-- Mini Caleb (one color, like a cast statue), standing on the plinth.
	local color, material = variant.Figure.Color, variant.Figure.Material
	local hair = color:Lerp(Color3.new(0, 0, 0), 0.3)
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "Left" else "Right"
		make(`{tag}Shoe`, Vector3.new(0.3, 0.14, 0.42), CFrame.new(side * 0.17, 0.57, -0.05), color, material)
		make(`{tag}Leg`, Vector3.new(0.26, 0.5, 0.28), CFrame.new(side * 0.17, 0.89, 0), color, material)
		make(`{tag}Ear`, Vector3.new(0.2, 0.2, 0.2), CFrame.new(HEAD + Vector3.new(side * 0.5, -0.02, 0.03)), color, material, BALL)
		make(`{tag}Eye`, Vector3.new(0.3, 0.3, 0.3), CFrame.new(HEAD + Vector3.new(side * 0.16, 0.08, -0.4)), Color3.new(1, 1, 1), nil, BALL)
		make(`{tag}Pupil`, Vector3.new(0.09, 0.09, 0.09), CFrame.new(HEAD + Vector3.new(side * 0.15, 0.1, -0.55)), DARK, nil, BALL)
	end
	make("Torso", Vector3.new(0.8, 0.72, 0.5), CFrame.new(0, 1.5, 0), color, material)
	make("Belly", Vector3.new(0.62, 0.62, 0.62), CFrame.new(0, 1.42, -0.12), color, material, BALL)
	make("Belt", Vector3.new(0.82, 0.08, 0.52), CFrame.new(0, 1.18, 0), hair, material)
	make("Head", Vector3.new(1, 1, 1), CFrame.new(HEAD), color, material, BALL)
	make("HairCap", Vector3.new(1, 1, 1), CFrame.new(HEAD + Vector3.new(0, 0.2, 0.1)), hair, material, BALL)
	make("Mouth", Vector3.new(0.4, 0.1, 0.06), CFrame.new(HEAD + Vector3.new(0, -0.2, -0.46)), DARK)
	make("Teeth", Vector3.new(0.32, 0.04, 0.04), CFrame.new(HEAD + Vector3.new(0, -0.17, -0.49)), Color3.new(1, 1, 1))

	-- Arms in the variant's pose; remember where the right hand ends up.
	local pose = POSES[variant.Pose] or POSES.Down
	local rightHand = Vector3.zero
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "Left" else "Right"
		local angles = pose[tag]
		local shoulder = CFrame.new(side * 0.5, SHOULDER_Y, 0)
			* CFrame.Angles(0, 0, math.rad(angles[2]))
			* CFrame.Angles(math.rad(angles[1]), 0, 0)
		make(`{tag}Arm`, Vector3.new(0.22, 0.56, 0.22), shoulder * CFrame.new(0, -0.28, 0), color, material)
		local hand = make(`{tag}Hand`, Vector3.new(0.26, 0.26, 0.26), shoulder * CFrame.new(0, -0.6, 0), color, material, BALL)
		if side > 0 then
			rightHand = hand.Position
		end
	end

	TrophyAccessories.Add(make, variant.Accessories, {
		Head = HEAD,
		Neck = Vector3.new(0, 1.84, -0.27),
		RightHand = rightHand,
	})

	model.WorldPivot = CFrame.new() -- bottom center of the plinth
	local s = scale or 1
	if s ~= 1 then
		model:ScaleTo(s)
	end
	addEffect(model, variant, s)
	return model
end

return TrophyModel
