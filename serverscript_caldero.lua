-- Archivo CALDERO: el caldero de la base del Bosque Prohibido. Es el
-- builder del dueno del juego, integrado en Avada: solo cambian el
-- punto donde nace (junto a la Fogata Magica) y la escala para que
-- quepa en la base. La animacion vive en el LocalScript del bosque y
-- la reserva de hongos la lleva el archivo PARTIDA.

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

------------------------------------------------------------------ CONFIG
local CONFIG = {
	Position = Vector3.new(-9.5, 2, 4208), -- junto a la fogata, dentro del circulo del campamento
	Scale = 0.32,                       -- ~11 studs de ancho y ~5.5 de alto
	LiquidCanCollide = true,            -- true: el liquido es una superficie solida
	Seed = 7,                           -- cambia para otra variacion de piedra/objetos
}

local spawnPart = Workspace:FindFirstChild("CauldronSpawn")
if spawnPart and spawnPart:IsA("BasePart") then
	CONFIG.Position = spawnPart.Position - Vector3.new(0, spawnPart.Size.Y / 2, 0)
	spawnPart.Transparency = 1
	spawnPart.CanCollide = false
end

------------------------------------------------------------------ BASE
local S = CONFIG.Scale
local ORIGIN = CFrame.new(CONFIG.Position)
local rng = Random.new(CONFIG.Seed)
local SIDES = 12
local LIQUID_Y = 14.4 -- altura del liquido (sin escala)

local root = Instance.new("Model")
root.Name = "Cauldron"

local function folder(name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	return f
end

local bodyF, rimF, handlesF, legsF, liquidF, itemsF =
	folder("Body"), folder("Rim"), folder("Handles"), folder("Legs"), folder("Liquid"), folder("Items")

-- cf se da en coordenadas locales SIN escalar
local function mk(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Size = size * S
	p.CFrame = ORIGIN * (CFrame.new(cf.Position * S) * cf.Rotation)
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Parent = parent
	return p
end

local function stone(y, darker)
	local base = Color3.fromRGB(112, 93, 104)
	local f = 0.8 + rng:NextNumber() * 0.32
	local h = 0.72 + math.clamp(y / 17, 0, 1) * 0.32
	if darker then
		h *= 0.55
	end
	return Color3.new(
		math.clamp(base.R * f * h, 0, 1),
		math.clamp(base.G * f * h, 0, 1),
		math.clamp(base.B * f * h, 0, 1)
	)
end

------------------------------------------------------------------ ANILLOS FACETADOS (12 lados)
-- Une dos "anillos" (altura, apotema) con 12 paneles inclinados
local function ring(parent, name, yA, rA, yB, rB, thick, darker)
	local dy, dr = yB - yA, rB - rA
	local len = math.sqrt(dy * dy + dr * dr)
	local rm = (rA + rB) / 2
	local width = 2 * math.max(rA, rB) * math.tan(math.pi / SIDES) * 1.025
	local tilt = math.atan2(dr, dy)
	for i = 0, SIDES - 1 do
		local a = i * 2 * math.pi / SIDES
		local cf = CFrame.new(math.sin(a) * rm, (yA + yB) / 2, math.cos(a) * rm)
			* CFrame.Angles(0, a, 0)
			* CFrame.Angles(tilt, 0, 0)
			* CFrame.new(0, 0, -thick / 2)
		mk(parent, name .. i, Vector3.new(width, len, thick), cf, stone((yA + yB) / 2, darker))
	end
end

-- Cuerpo (panza que se ensancha y vuelve a cerrarse)
ring(bodyF, "Belly1_", 3.5, 8.4, 6.8, 11.8, 1.6)
ring(bodyF, "Belly2_", 6.8, 11.8, 10.0, 13.5, 1.6)
ring(bodyF, "Belly3_", 10.0, 13.5, 13.2, 12.6, 1.6)
-- Borde grueso que sobresale
ring(rimF, "Rim", 13.0, 14.3, 16.5, 14.9, 3.3)
-- Pared interior oscura (se ve dentro del caldero)
ring(rimF, "Inner", 9.0, 11.3, 16.3, 11.5, 0.8, true)

-- Fondo
mk(bodyF, "Bottom", Vector3.new(1.2, 17, 17), CFrame.new(0, 4.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
	stone(4, true), Enum.Material.Slate, Enum.PartType.Cylinder)

-- Relleno interior (para que no se vea hueco bajo el liquido)
mk(bodyF, "Core", Vector3.new(9.6, 20, 20), CFrame.new(0, 9.6, 0) * CFrame.Angles(0, 0, math.pi / 2),
	stone(8, true), Enum.Material.Slate, Enum.PartType.Cylinder)

------------------------------------------------------------------ PATAS (3)
for _, deg in ipairs({ 90, 210, 330 }) do
	local a = math.rad(deg)
	local base = CFrame.new(math.sin(a) * 8.0, 2.4, math.cos(a) * 8.0) * CFrame.Angles(0, a, 0)
	mk(legsF, "Leg", Vector3.new(3.6, 5.2, 3.6), base * CFrame.Angles(0.16, 0, 0), stone(2))
	mk(legsF, "Foot", Vector3.new(4.0, 0.8, 4.0), base * CFrame.new(0, -2.3, 0.45) * CFrame.Angles(0.16, 0, 0), stone(1, true))
end

------------------------------------------------------------------ ASAS (rectangulares, una a cada lado)
for _, sign in ipairs({ -1, 1 }) do
	local function bar(name, size, pos)
		mk(handlesF, name, size, CFrame.new(Vector3.new(pos.X * sign, pos.Y, pos.Z)), stone(pos.Y))
	end
	bar("HandleTop", Vector3.new(6.2, 1.4, 2.6), Vector3.new(14.9, 13.0, 0))
	bar("HandleBottom", Vector3.new(6.2, 1.4, 2.6), Vector3.new(14.2, 9.6, 0))
	bar("HandleOuter", Vector3.new(1.5, 4.8, 2.6), Vector3.new(17.7, 11.3, 0))
end

------------------------------------------------------------------ LIQUIDO
local colA = Color3.fromRGB(132, 42, 156) -- magenta/morado
local colB = Color3.fromRGB(88, 40, 165) -- indigo

local liquid = mk(liquidF, "Liquid", Vector3.new(0.6, 20.4, 20.4),
	CFrame.new(0, LIQUID_Y, 0) * CFrame.Angles(0, 0, math.pi / 2), colA,
	Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
liquid.CanCollide = CONFIG.LiquidCanCollide
liquid:SetAttribute("Kind", "Liquid")
liquid:SetAttribute("ColorA", colA)
liquid:SetAttribute("ColorB", colB)

-- Luz morada del liquido
local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(160, 80, 255)
light.Range = 45 * S
light.Brightness = 2.2
light.Parent = liquid

-- Capa que se desliza y crea el degradado cambiante del liquido
local overlay = mk(liquidF, "LiquidShimmer", Vector3.new(0.2, 13, 13),
	CFrame.new(0, LIQUID_Y + 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2), colB,
	Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
overlay.Transparency = 0.55
overlay.CanCollide = false
overlay.CastShadow = false
overlay:SetAttribute("Kind", "Overlay")

-- Chispas/burbujas de particulas
local emitterPart = mk(liquidF, "BubbleEmitter", Vector3.new(16, 0.2, 16),
	CFrame.new(0, LIQUID_Y + 0.6, 0), colA, Enum.Material.SmoothPlastic)
emitterPart.Transparency = 1
emitterPart.CanCollide = false
emitterPart.CanQuery = false
emitterPart.CastShadow = false

local pe = Instance.new("ParticleEmitter")
pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
pe.Color = ColorSequence.new(Color3.fromRGB(200, 160, 255), Color3.fromRGB(150, 80, 230))
pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
pe.LightEmission = 0.6
pe.Lifetime = NumberRange.new(2, 4)
pe.Rate = 9
pe.Speed = NumberRange.new(2, 4)
pe.SpreadAngle = Vector2.new(15, 15)
pe.Acceleration = Vector3.new(0, 1.5, 0)
pe.Rotation = NumberRange.new(0, 360)
pe.RotSpeed = NumberRange.new(-60, 60)
pe.Parent = emitterPart

------------------------------------------------------------------ OBJETOS (cubos y esferas)
local PALETTE = {
	Color3.fromRGB(190, 160, 228), -- lavanda claro
	Color3.fromRGB(165, 125, 210),
	Color3.fromRGB(125, 75, 175),
	Color3.fromRGB(95, 55, 150),
	Color3.fromRGB(70, 28, 100),
	Color3.fromRGB(110, 70, 160),
}

local function animated(p, kind, props)
	p:SetAttribute("Kind", kind)
	p:SetAttribute("BaseCFrame", p.CFrame)
	p:SetAttribute("Scale", S)
	for k, v in pairs(props) do
		p:SetAttribute(k, v)
	end
	CollectionService:AddTag(p, "CauldronAnim")
	p.CanCollide = false
	p.CastShadow = false
end

-- Objetos sobre la superficie del liquido (cubos y domos)
local placed = {}
local tries = 0
while #placed < 10 and tries < 300 do
	tries += 1
	local ang, rad = rng:NextNumber() * math.pi * 2, math.sqrt(rng:NextNumber()) * 7.4
	local x, z = math.cos(ang) * rad, math.sin(ang) * rad
	local ok = true
	for _, o in ipairs(placed) do
		if (Vector2.new(x, z) - o).Magnitude < 3.6 then
			ok = false
			break
		end
	end
	if ok then
		table.insert(placed, Vector2.new(x, z))
		local size = 1.5 + rng:NextNumber() * 1.7
		local color = PALETTE[rng:NextInteger(1, #PALETTE)]
		local p
		if rng:NextNumber() < 0.6 then
			p = mk(itemsF, "Cube", Vector3.new(size, size, size),
				CFrame.new(x, LIQUID_Y + size * 0.35, z) * CFrame.Angles(0, rng:NextNumber() * 3, 0), color,
				Enum.Material.SmoothPlastic)
		else
			p = mk(itemsF, "Dome", Vector3.new(size * 1.3, size * 1.3, size * 1.3),
				CFrame.new(x, LIQUID_Y + size * 0.05, z), PALETTE[rng:NextInteger(1, 3)],
				Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
		animated(p, "Float", {
			Phase = rng:NextNumber() * 6.28,
			Speed = 0.8 + rng:NextNumber() * 0.8,
			Amp = (0.25 + rng:NextNumber() * 0.25) * S,
			Spin = (rng:NextNumber() - 0.5) * 0.8,
		})
	end
end

-- Objetos que suben como burbujas y se desvanecen
for i = 1, 12 do
	local ang, rad = rng:NextNumber() * math.pi * 2, math.sqrt(rng:NextNumber()) * 7.8
	local size = 0.7 + rng:NextNumber() * 1.1
	local color = PALETTE[rng:NextInteger(1, 3)]
	local p
	if i % 3 == 0 then
		p = mk(itemsF, "Bubble", Vector3.new(size * 1.4, size * 1.4, size * 1.4),
			CFrame.new(math.cos(ang) * rad, LIQUID_Y + 1, math.sin(ang) * rad), color,
			Enum.Material.Neon, Enum.PartType.Ball)
	else
		p = mk(itemsF, "RisingCube", Vector3.new(size, size, size),
			CFrame.new(math.cos(ang) * rad, LIQUID_Y + 1, math.sin(ang) * rad), color,
			Enum.Material.Neon)
	end
	animated(p, "Rise", {
		Phase = rng:NextNumber(),
		Speed = 0.07 + rng:NextNumber() * 0.08,
		Height = (9 + rng:NextNumber() * 6) * S,
		Spin = (rng:NextNumber() - 0.5) * 3,
	})
end

animated(liquid, "Liquid", { Phase = 0 })
animated(overlay, "Overlay", {})
liquid.CanCollide = CONFIG.LiquidCanCollide

------------------------------------------------------------------ FINAL
root.PrimaryPart = bodyF:FindFirstChild("Bottom")
root.Parent = Workspace

-- Integracion Avada: al acercarte sale el prompt "Ver" del caldero;
-- el panel y la reserva de hongos viven en PARTIDA/LocalScript.
root:SetAttribute("CalderoAvada", true)
local promptAnchor = Instance.new("Part")
promptAnchor.Name = "CalderoAncla"
promptAnchor.Size = Vector3.new(2, 2, 2)
promptAnchor.CFrame = CFrame.new(CONFIG.Position + Vector3.new(0, 3, 0))
promptAnchor.Transparency = 1
promptAnchor.CanCollide = false
promptAnchor.CanTouch = false
promptAnchor.CanQuery = false
promptAnchor.Anchored = true
promptAnchor.Parent = root

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "CalderoPrompt"
prompt.ActionText = "Ver"
prompt.ObjectText = "Caldero"
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 13
prompt.RequiresLineOfSight = false
prompt.Parent = promptAnchor

print("[Avada] Caldero listo en la base del bosque")

-- FIN CALDERO
