--[[
	TIENDA MÁGICA - Constructor procedural para Roblox
	-----------------------------------------------------
	CÓMO USARLO:
	1. En Roblox Studio abre ServerScriptService
	2. Inserta un "Script" (NO LocalScript) y pega todo este código
	3. Dale a Play: la tienda aparece sola en POSITION
	   (el frente mira hacia +Z; si quieres girarla cambia ROTATION_Y)

	Todo está hecho con Parts (sin assets externos), así que funciona en cualquier experiencia.

	NOTA AVADA: archivo 3 de 3 (JUEGO, ISLA, TIENDA). POSITION se movio
	a (0, 2, -40) para que la tienda quede SOBRE la isla flotante,
	mirando al circulo magico del centro. Nada mas se toco.
]]

--// ============ CONFIGURACIÓN ============
local POSITION = Vector3.new(0, 2, -40)
local ROTATION_Y = 0 -- grados
local SHOP_TEXT = "TIENDA"

--// ============ BASE DEL SISTEMA ============
local ORIGIN = CFrame.new(POSITION) * CFrame.Angles(0, math.rad(ROTATION_Y), 0)
local rng = Random.new(42)
local M = Enum.Material
local F = 1 -- altura del suelo de la tienda

local old = workspace:FindFirstChild("TiendaMagica")
if old then old:Destroy() end
local model = Instance.new("Model")
model.Name = "TiendaMagica"

local C = {
	WOOD_DARK = Color3.fromRGB(92, 56, 48),
	WOOD = Color3.fromRGB(140, 84, 50),
	WOOD_LIGHT = Color3.fromRGB(176, 116, 70),
	TILE_A = Color3.fromRGB(222, 134, 84),
	TILE_B = Color3.fromRGB(242, 198, 122),
	WALL = Color3.fromRGB(214, 190, 150),
	BASE = Color3.fromRGB(112, 106, 58),
	STONE = Color3.fromRGB(132, 128, 134),
	IRON = Color3.fromRGB(44, 44, 52),
	GOLD = Color3.fromRGB(235, 180, 60),
	PAPER = Color3.fromRGB(246, 236, 205),
	RED = Color3.fromRGB(230, 40, 50),
	BLUE = Color3.fromRGB(40, 90, 235),
	PURPLE = Color3.fromRGB(150, 50, 230),
	MAGENTA = Color3.fromRGB(235, 70, 200),
	YELLOW = Color3.fromRGB(255, 225, 60),
	CYAN = Color3.fromRGB(60, 220, 255),
	TEAL = Color3.fromRGB(60, 190, 190),
	BOOK_RED = Color3.fromRGB(140, 40, 50),
	BOOK_BLUE = Color3.fromRGB(40, 55, 110),
	RUNE = Color3.fromRGB(110, 50, 150),
}

--// ============ HELPERS ============
local function P(name, size, cf, color, material, extra)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = ORIGIN * cf
	p.Color = color
	p.Material = material or M.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if extra then
		for k, v in pairs(extra) do p[k] = v end
	end
	p.Parent = model
	return p
end

-- cilindro VERTICAL
local function cyl(name, height, diameter, cf, color, material, extra)
	local p = P(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.pi / 2), color, material, extra)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- cilindro HORIZONTAL (eje X)
local function cylX(name, length, diameter, cf, color, material, extra)
	local p = P(name, Vector3.new(length, diameter, diameter), cf, color, material, extra)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ball(name, diameter, cf, color, material, extra)
	local p = P(name, Vector3.new(diameter, diameter, diameter), cf, color, material, extra)
	p.Shape = Enum.PartType.Ball
	return p
end

local function ellipsoid(name, size, cf, color, material, extra)
	local p = P(name, size, cf, color, material, extra)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end

local function addLight(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
	return l
end

local function sparkles(parent, color, rate)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(0.4, 1)
	e.Rate = rate or 2
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = parent
end

local function roofY(z)
	return 17.5 - (5.3 / 9) * math.abs(z)
end

--// ============ TECHO DE TEJAS ============
local function roofPlane(cf, sx, sz, cols, rows)
	P("RoofSlab", Vector3.new(sx, 0.6, sz), cf, C.WOOD_DARK, M.Wood)
	local tw, th = sx / cols, sz / rows
	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			local color = (rng:NextInteger(0, 1) == 0) and C.TILE_A or C.TILE_B
			local jitter = CFrame.new(rng:NextNumber(-0.06, 0.06), rng:NextNumber(0, 0.07), rng:NextNumber(-0.06, 0.06))
				* CFrame.Angles(rng:NextNumber(-0.03, 0.03), rng:NextNumber(-0.04, 0.04), rng:NextNumber(-0.03, 0.03))
			local local_ = CFrame.new(-sx / 2 + (c + 0.5) * tw, 0.45, -sz / 2 + (r + 0.5) * th)
			P("Tile", Vector3.new(tw * 0.93, 0.4, th * 0.93), cf * local_ * jitter, color, M.Slate)
		end
	end
end

--// ============ OBJETOS ============
local function potion(pos, color, s)
	s = s or 1
	local r = 0.8 * s
	ball("PotionBody", 2 * r, CFrame.new(pos + Vector3.new(0, r, 0)), color, M.Glass, { Transparency = 0.1 })
	ball("PotionShine", 0.35 * s, CFrame.new(pos + Vector3.new(-0.35 * r, r * 1.35, r * 0.72)), Color3.new(1, 1, 1), M.Neon, { Transparency = 0.45 })
	cyl("PotionNeck", 0.9 * s, 0.55 * s, CFrame.new(pos + Vector3.new(0, 2 * r + 0.25 * s, 0)), color, M.Glass, { Transparency = 0.2 })
	cyl("PotionCork", 0.4 * s, 0.5 * s, CFrame.new(pos + Vector3.new(0, 2 * r + 0.85 * s, 0)), Color3.fromRGB(200, 140, 85), M.Wood)
end

-- libro de pie (lomo hacia el frente +Z)
local function bookStand(pos, size, color)
	P("Book", size, CFrame.new(pos), color, M.SmoothPlastic)
	P("BookPages", Vector3.new(size.X * 0.8, size.Y * 0.94, 0.05), CFrame.new(pos + Vector3.new(0, 0, -size.Z / 2 - 0.02)), C.PAPER)
	P("BookEmblem", Vector3.new(size.X * 0.55, size.X * 0.55, 0.05), CFrame.new(pos + Vector3.new(0, size.Y * 0.1, size.Z / 2 + 0.02)), C.GOLD, M.Neon)
	P("BookBand", Vector3.new(size.X * 1.02, 0.1, size.Z * 1.02), CFrame.new(pos + Vector3.new(0, size.Y * 0.38, 0)), C.GOLD)
	P("BookBand", Vector3.new(size.X * 1.02, 0.1, size.Z * 1.02), CFrame.new(pos + Vector3.new(0, -size.Y * 0.38, 0)), C.GOLD)
end

-- libro acostado (para pilas)
local function bookFlat(cf, size, color)
	local w, h, d = size.X, size.Y, size.Z
	P("BookBottom", Vector3.new(w, 0.12, d), cf * CFrame.new(0, -h / 2 + 0.06, 0), color)
	P("BookTop", Vector3.new(w, 0.12, d), cf * CFrame.new(0, h / 2 - 0.06, 0), color)
	P("BookPages", Vector3.new(w * 0.95, h - 0.2, d * 0.95), cf * CFrame.new(0.05, 0, 0), C.PAPER)
	P("BookSpine", Vector3.new(0.14, h, d), cf * CFrame.new(-w / 2 + 0.07, 0, 0), color)
	P("BookEmblem", Vector3.new(0.55, 0.03, 0.55), cf * CFrame.new(0, h / 2 + 0.01, 0), C.GOLD, M.Neon)
end

local function runes(pageCF, s)
	for row = 0, 2 do
		for k = 0, 2 do
			local gx = (-0.4 + k * 0.4) * s
			local gz = (-0.4 + row * 0.38) * s
			local g = pageCF * CFrame.new(gx, 0.07, gz)
			P("Rune", Vector3.new(0.07 * s, 0.02, 0.3 * s), g, C.RUNE)
			P("Rune", Vector3.new(0.07 * s, 0.02, 0.22 * s), g * CFrame.new(0.08 * s, 0, -0.04 * s) * CFrame.Angles(0, 0.7, 0), C.RUNE)
		end
	end
end

local function openBook(cf, s)
	s = s or 1
	P("BookCover", Vector3.new(3.3 * s, 0.14, 1.5 * s), cf * CFrame.new(0, 0, 0), Color3.fromRGB(110, 50, 140))
	local left = cf * CFrame.new(-0.78 * s, 0.14, 0) * CFrame.Angles(0, 0, -0.12)
	local right = cf * CFrame.new(0.78 * s, 0.14, 0) * CFrame.Angles(0, 0, 0.12)
	P("PageL", Vector3.new(1.5 * s, 0.1, 1.3 * s), left, C.PAPER)
	P("PageR", Vector3.new(1.5 * s, 0.1, 1.3 * s), right, C.PAPER)
	runes(left, s)
	runes(right, s)
end

local function scroll(cf, len)
	cylX("Scroll", len, 0.55, cf, Color3.fromRGB(236, 220, 172), M.Fabric)
	cylX("ScrollEnd", 0.12, 0.62, cf * CFrame.new(len / 2, 0, 0), Color3.fromRGB(205, 180, 125), M.Wood)
	cylX("ScrollEnd", 0.12, 0.62, cf * CFrame.new(-len / 2, 0, 0), Color3.fromRGB(205, 180, 125), M.Wood)
	cylX("ScrollBand", 0.14, 0.6, cf * CFrame.new(len * 0.15, 0, 0), C.BOOK_RED, M.Fabric)
end

local function crystal(cf, h, w, color)
	local extra = { Transparency = 0.1 }
	P("CrystalBody", Vector3.new(w, h, w), cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.rad(45), 0), color, M.Neon, extra)
	P("CrystalTip", Vector3.new(w * 0.72, w * 0.72, w * 0.72), cf * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(-35.26), 0, math.rad(45)), color, M.Neon, extra)
end

local function cluster(pos, color, count, scale)
	scale = scale or 1
	for i = 1, count do
		local ang = (i / count) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local off = Vector3.new(math.cos(ang), 0, math.sin(ang)) * rng:NextNumber(0.2, 0.9) * scale
		local cf = CFrame.new(pos + off)
			* CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3))
		crystal(cf, rng:NextNumber(1.8, 3.8) * scale, rng:NextNumber(0.8, 1.3) * scale, color)
	end
	local glow = P("CrystalGlow", Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos + Vector3.new(0, 1.2 * scale, 0)), color, M.Neon, { Transparency = 1, CanCollide = false })
	addLight(glow, color, 9, 1.2)
	sparkles(glow, color, 3)
end

local function staff(base, height, color, tilt)
	tilt = tilt or 0
	local segs = 6
	local segH = height / segs
	local root = CFrame.new(base) * CFrame.Angles(0, 0, tilt)
	for i = 1, segs do
		local wob = math.sin(i * 1.4) * 0.16
		P("StaffWood", Vector3.new(0.42 - i * 0.02, segH + 0.1, 0.42 - i * 0.02), root * CFrame.new(wob, (i - 0.5) * segH, math.cos(i * 1.1) * 0.1), C.WOOD_LIGHT, M.Wood)
	end
	local top = root * CFrame.new(0, height, 0)
	for _, sgn in ipairs({ -1, 1 }) do
		P("StaffProng", Vector3.new(0.25, 1.1, 0.25), top * CFrame.new(sgn * 0.28, 0.4, 0) * CFrame.Angles(0, 0, -sgn * 0.3), C.WOOD_LIGHT, M.Wood)
	end
	crystal(top * CFrame.new(0, 0.6, 0), 1.3, 0.65, color)
	local glow = P("StaffGlow", Vector3.new(0.4, 0.4, 0.4), top * CFrame.new(0, 1.5, 0), color, M.Neon, { Transparency = 1, CanCollide = false })
	addLight(glow, color, 12, 1.5)
	sparkles(glow, color, 4)
end

local function lantern(center)
	local cf = CFrame.new(center)
	local glass = P("LanternGlass", Vector3.new(1.0, 1.5, 1.0), cf, Color3.fromRGB(255, 214, 120), M.Neon, { Transparency = 0.05 })
	addLight(glass, Color3.fromRGB(255, 190, 100), 18, 2)
	P("LanternBase", Vector3.new(1.3, 0.25, 1.3), cf * CFrame.new(0, -0.85, 0), C.IRON, M.Metal)
	P("LanternCap", Vector3.new(1.35, 0.3, 1.35), cf * CFrame.new(0, 0.9, 0), C.IRON, M.Metal)
	P("LanternCap2", Vector3.new(0.9, 0.3, 0.9), cf * CFrame.new(0, 1.15, 0), C.IRON, M.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			P("LanternBar", Vector3.new(0.16, 1.55, 0.16), cf * CFrame.new(sx * 0.55, 0, sz * 0.55), C.IRON, M.Metal)
		end
	end
	P("LanternRing", Vector3.new(0.5, 0.5, 0.14), cf * CFrame.new(0, 1.55, 0), C.IRON, M.Metal)
end

local function herb(x, z, color, leafy, leafColor)
	local top = 14.0
	P("HerbString", Vector3.new(0.08, 0.7, 0.08), CFrame.new(x, top - 0.35, z), C.IRON)
	P("HerbBand", Vector3.new(0.55, 0.22, 0.55), CFrame.new(x, top - 0.85, z), Color3.fromRGB(150, 100, 60), M.Fabric)
	for i = 1, 8 do
		local len = rng:NextNumber(2.6, 3.4)
		local pivot = CFrame.new(x, top - 0.8, z) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3))
		P("HerbStem", Vector3.new(0.12, len, 0.12), pivot * CFrame.new(0, -len / 2, 0), color, M.Grass)
		if leafy then
			for j = 1, 3 do
				ellipsoid("HerbLeaf", Vector3.new(0.7, 0.45, 0.7), pivot * CFrame.new(rng:NextNumber(-0.1, 0.1), -len * (0.35 + 0.2 * j), 0), leafColor, M.Grass)
			end
		else
			ellipsoid("HerbHead", Vector3.new(0.22, 0.7, 0.22), pivot * CFrame.new(0, -len, 0), color, M.Grass)
		end
	end
end

local function cauldron(pos, s, withStick)
	local cx, cy, cz = pos.X, pos.Y, pos.Z
	ellipsoid("CauldronBody", Vector3.new(3.5 * s, 3.0 * s, 3.5 * s), CFrame.new(cx, cy + 1.7 * s, cz), Color3.fromRGB(38, 38, 44), M.Metal)
	cyl("CauldronRim", 0.35 * s, 3.1 * s, CFrame.new(cx, cy + 3.05 * s, cz), Color3.fromRGB(30, 30, 36), M.Metal)
	local liquid = cyl("CauldronLiquid", 0.1 * s, 2.7 * s, CFrame.new(cx, cy + 3.15 * s, cz), Color3.fromRGB(205, 110, 255), M.Neon)
	addLight(liquid, Color3.fromRGB(205, 110, 255), 10, 1.3)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(215, 120, 255))
	e.LightEmission = 0.8
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.35 * s), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(1.5, 3)
	e.Rate = 7
	e.SpreadAngle = Vector2.new(25, 25)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = liquid
	for _, a in ipairs({ 0, 2.1, 4.2 }) do
		P("CauldronLeg", Vector3.new(0.5 * s, 0.7 * s, 0.5 * s), CFrame.new(cx + math.cos(a) * 1.2 * s, cy + 0.35 * s, cz + math.sin(a) * 1.2 * s), Color3.fromRGB(30, 30, 36), M.Metal)
	end
	if withStick then
		P("Spoon", Vector3.new(0.3, 4.4, 0.3), CFrame.new(cx - 0.9, cy + 4.2, cz) * CFrame.Angles(0, 0, 0.3), C.WOOD, M.Wood)
	end
end

local function shelf(cx, cz, w, h, boards)
	for _, sx in ipairs({ -1, 1 }) do
		P("ShelfPost", Vector3.new(0.6, h, 0.9), CFrame.new(cx + sx * w / 2, F + h / 2, cz), C.WOOD, M.Wood)
	end
	for _, y in ipairs(boards) do
		P("ShelfBoard", Vector3.new(w, 0.35, 1.2), CFrame.new(cx, y, cz), C.WOOD_LIGHT, M.Wood)
	end
	P("ShelfTop", Vector3.new(w + 0.8, 0.5, 1.2), CFrame.new(cx, F + h + 0.1, cz), C.WOOD, M.Wood)
end

--// ============ SUELO / BASE ============
P("BaseRim", Vector3.new(35, 0.75, 27), CFrame.new(0, 0.375, 0.5), C.WOOD_DARK, M.Wood)
P("Base", Vector3.new(34, 0.5, 26), CFrame.new(0, 0.75, 0.5), C.BASE, M.Grass)
local root = P("Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), C.BASE, M.SmoothPlastic, { Transparency = 1, CanCollide = false })
model.PrimaryPart = root

-- piedras del camino
local pavers = {
	{ -9, 11, 3.2, 1.8, 0.3 }, { -3, 10.6, 4.2, 2.2, -0.1 }, { 4.5, 10.8, 4.4, 2.0, 0.15 },
	{ 11, 10, 3.4, 1.8, -0.3 }, { -12, 6, 2.2, 3, 0.2 }, { 13, 4, 2.6, 2.4, 0.1 }, { 0, 8.6, 2.4, 1.2, 0 },
}
for _, p in ipairs(pavers) do
	P("Paver", Vector3.new(p[3], 0.2, p[4]), CFrame.new(p[1], 1.1, p[2]) * CFrame.Angles(0, p[5], 0), C.STONE, M.Slate)
end

--// ============ POSTES ============
local posts = {
	{ -7.8, 5.4, 1.9 }, { 7.8, 5.4, 1.9 },
	{ -12.2, 1.5, 1.4 }, { 12.2, 1.5, 1.4 },
	{ -12.2, -5.5, 1.4 }, { 12.2, -5.5, 1.4 },
}
for _, p in ipairs(posts) do
	local x, z, w = p[1], p[2], p[3]
	P("Pedestal", Vector3.new(w + 0.8, 1.2, w + 0.8), CFrame.new(x, F + 0.6, z), C.STONE, M.Slate)
	local topY = roofY(z) - 0.45
	local h = topY - (F + 1.2)
	P("Post", Vector3.new(w, h, w), CFrame.new(x, F + 1.2 + h / 2, z), C.WOOD_DARK, M.Wood)
	P("PostCap", Vector3.new(w + 0.4, 0.5, w + 0.4), CFrame.new(x, topY - 0.25, z), C.WOOD, M.Wood)
end

-- vigas
P("BeamFront", Vector3.new(27, 0.9, 1.2), CFrame.new(0, roofY(5.4) - 0.9, 5.4), C.WOOD_DARK, M.Wood)
P("BeamMid", Vector3.new(27, 0.8, 0.9), CFrame.new(0, 14.4, 3.8), C.WOOD_DARK, M.Wood)
P("BeamBack", Vector3.new(27, 0.9, 1.0), CFrame.new(0, roofY(-5.5) - 0.9, -5.5), C.WOOD_DARK, M.Wood)

--// ============ PARED TRASERA ============
P("BackWall", Vector3.new(24.4, 12.6, 0.6), CFrame.new(0, F + 6.3, -6.8), C.WALL, M.SmoothPlastic)
for _, sx in ipairs({ -1, 1 }) do
	P("WallFrame", Vector3.new(0.7, 12.6, 0.9), CFrame.new(sx * 12.2, F + 6.3, -6.7), C.WOOD_DARK, M.Wood)
end

--// ============ TECHO ============
local theta = math.atan2(5.3, 9)
local L = math.sqrt(81 + 5.3 * 5.3)
for _, side in ipairs({ 1, -1 }) do
	local cf = CFrame.new(0, (17.5 + roofY(9)) / 2, side * 4.5) * CFrame.Angles(side * theta, 0, 0)
	roofPlane(cf, 28, L, 10, 5)
end
P("RoofRidge", Vector3.new(28.4, 1.0, 1.4), CFrame.new(0, 17.7, 0), C.WOOD_DARK, M.Wood)
P("RoofTrimFront", Vector3.new(28.4, 0.5, 0.5), CFrame.new(0, roofY(9) - 0.2, 9.1), C.WOOD_DARK, M.Wood)

-- toldos laterales + soportes
for _, side in ipairs({ -1, 1 }) do
	local cf = CFrame.new(side * 16.2, 11.0, -2) * CFrame.Angles(0, 0, -side * 0.42)
	roofPlane(cf, 5.6, 8, 4, 4)
	for _, z in ipairs({ 1.5, -5.5 }) do
		P("AwningBrace", Vector3.new(4.0, 0.5, 0.5), CFrame.new(side * 14.2, 10.25, z) * CFrame.Angles(0, 0, side * 0.55), C.WOOD_DARK, M.Wood)
	end
	-- brazo y linterna exterior
	P("LanternArm", Vector3.new(5, 0.6, 0.6), CFrame.new(side * 14.7, 8.8, 1.5), C.WOOD_DARK, M.Wood)
	P("LanternChain", Vector3.new(0.1, 0.8, 0.1), CFrame.new(side * 16.7, 8.4, 1.5), C.IRON, M.Metal)
	lantern(Vector3.new(side * 16.7, 7.0, 1.5))
end

--// ============ LINTERNAS INTERIORES ============
for _, side in ipairs({ -1, 1 }) do
	P("LanternArm", Vector3.new(1.6, 0.35, 0.35), CFrame.new(side * 9.5, 11.5, 5.4), C.WOOD_DARK, M.Wood)
	P("LanternChain", Vector3.new(0.1, 0.9, 0.1), CFrame.new(side * 10.1, 11.0, 5.4), C.IRON, M.Metal)
	lantern(Vector3.new(side * 10.1, 9.3, 5.4))
end

--// ============ LETRERO ============
for _, sx in ipairs({ -1, 1 }) do
	P("SignChain", Vector3.new(0.1, 1.2, 0.1), CFrame.new(sx * 2.8, 13.4, 3.8), C.IRON, M.Metal)
end
local board = P("SignBoard", Vector3.new(6.6, 2.5, 0.45), CFrame.new(0, 11.8, 3.8), Color3.fromRGB(205, 165, 115), M.Wood)
P("SignBorderT", Vector3.new(6.8, 0.2, 0.55), CFrame.new(0, 13.0, 3.8), C.WOOD_DARK, M.Wood)
P("SignBorderB", Vector3.new(6.8, 0.2, 0.55), CFrame.new(0, 10.6, 3.8), C.WOOD_DARK, M.Wood)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 60
gui.Parent = board
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.new(0.62, 0, 0.8, 0)
label.Position = UDim2.new(0.34, 0, 0.1, 0)
label.Text = SHOP_TEXT
label.TextScaled = true
label.Font = Enum.Font.Fantasy
label.TextColor3 = Color3.fromRGB(78, 44, 60)
label.Parent = gui
-- sombrero de mago
local hatZ = 3.8 + 0.28
local HAT = Color3.fromRGB(92, 48, 62)
cylX("HatBrim", 0.12, 0.5, CFrame.new(-2.35, 11.35, hatZ) * CFrame.Angles(0, math.pi / 2, 0), HAT).Size = Vector3.new(0.12, 0.5, 1.8)
P("HatBase", Vector3.new(0.95, 0.5, 0.12), CFrame.new(-2.4, 11.65, hatZ), HAT)
P("HatMid", Vector3.new(0.7, 0.5, 0.12), CFrame.new(-2.3, 12.1, hatZ), HAT)
P("HatTip", Vector3.new(0.4, 0.45, 0.12), CFrame.new(-2.1, 12.5, hatZ), HAT)

--// ============ HIERBAS COLGANTES ============
herb(-6.8, 3.8, Color3.fromRGB(205, 165, 85), false)
herb(-4.4, 3.8, Color3.fromRGB(110, 100, 70), true, Color3.fromRGB(165, 160, 140))
herb(4.4, 3.8, Color3.fromRGB(55, 140, 65), false)
herb(6.8, 3.8, Color3.fromRGB(50, 135, 60), true, Color3.fromRGB(40, 150, 60))

--// ============ MOSTRADOR ============
local top = F + 4.0
P("CounterTop", Vector3.new(13.8, 0.6, 3.6), CFrame.new(0, top - 0.3, 4), C.WOOD, M.Wood)
P("CounterBack", Vector3.new(13.2, 3.4, 0.4), CFrame.new(0, F + 1.7, 2.4), C.WOOD_DARK, M.Wood)
for i = 0, 12 do
	local ph = 3.4 + rng:NextNumber(-0.08, 0.08)
	P("CounterPlank", Vector3.new(0.95, ph, 0.4), CFrame.new(-6 + i, F + ph / 2, 5.6), (i % 2 == 0) and C.WOOD or Color3.fromRGB(125, 74, 45), M.Wood)
end
for _, sx in ipairs({ -1, 1 }) do
	P("CounterEnd", Vector3.new(1.0, 3.8, 3.6), CFrame.new(sx * 6.7, F + 1.9, 4), C.WOOD_DARK, M.Wood)
end

-- objetos sobre el mostrador
potion(Vector3.new(-4.6, top, 3.9), C.RED, 1.2)
potion(Vector3.new(-2.5, top, 3.9), C.BLUE, 1.2)
potion(Vector3.new(-0.4, top, 3.9), C.PURPLE, 1.2)
openBook(CFrame.new(2.2, top + 0.08, 4.0) * CFrame.Angles(0, -0.12, 0), 1.3)
scroll(CFrame.new(4.6, top + 0.3, 3.4) * CFrame.Angles(0, 0.35, 0), 2.2)
bookFlat(CFrame.new(5.6, top + 0.35, 3.8), Vector3.new(2.6, 0.7, 1.9), C.BOOK_RED)
bookFlat(CFrame.new(5.5, top + 1.05, 3.8) * CFrame.Angles(0, 0.1, 0), Vector3.new(2.6, 0.7, 1.9), C.BOOK_BLUE)
cluster(Vector3.new(6.3, top, 2.7), C.TEAL, 3, 0.5)

--// ============ ESTANTES ============
-- centro
shelf(0, -5.8, 8.4, 10.4, { F + 5.2, F + 8.0 })
local c1, c2 = F + 5.2 + 0.18, F + 8.0 + 0.18
bookStand(Vector3.new(-3.4, c1 + 1.0, -5.8), Vector3.new(0.5, 2.0, 1.4), C.BOOK_BLUE)
bookStand(Vector3.new(-2.8, c1 + 1.0, -5.8), Vector3.new(0.6, 2.0, 1.4), C.BOOK_RED)
openBook(CFrame.new(0.1, c1 + 1.0, -5.9) * CFrame.Angles(math.rad(78), 0, 0), 1.1)
potion(Vector3.new(3.0, c1, -5.8), C.RED, 0.8)
potion(Vector3.new(-1.9, c2, -5.8), C.RED, 1.0)
potion(Vector3.new(0, c2, -5.8), C.BLUE, 1.0)
potion(Vector3.new(1.9, c2, -5.8), C.PURPLE, 1.0)

-- izquierda
shelf(-9.4, -5.8, 4.4, 9.6, { F + 2.8, F + 5.6, F + 8.4 })
cauldron(Vector3.new(-9.4, F + 2.8 + 0.18, -5.8), 0.45, false)
openBook(CFrame.new(-9.4, F + 5.6 + 1.1, -5.9) * CFrame.Angles(math.rad(78), 0, 0), 1.0)
bookStand(Vector3.new(-10.5, F + 8.4 + 1.0, -5.8), Vector3.new(0.5, 1.8, 1.4), C.BOOK_BLUE)
bookStand(Vector3.new(-9.9, F + 8.4 + 1.0, -5.8), Vector3.new(0.6, 1.8, 1.4), C.BOOK_RED)
bookStand(Vector3.new(-8.9, F + 8.4 + 1.0, -5.8) , Vector3.new(0.5, 1.6, 1.4), Color3.fromRGB(60, 60, 70))

-- derecha
shelf(9.4, -5.8, 4.4, 9.6, { F + 2.8, F + 5.6, F + 8.4 })
cluster(Vector3.new(9.4, F + 2.8 + 0.18, -5.8), C.TEAL, 3, 0.45)
scroll(CFrame.new(8.8, F + 5.6 + 0.5, -5.8), 2.6)
scroll(CFrame.new(10.0, F + 5.6 + 0.5, -5.8) * CFrame.Angles(0, 0.1, 0), 2.4)
scroll(CFrame.new(9.4, F + 5.6 + 1.05, -5.8) * CFrame.Angles(0, -0.1, 0), 2.6)
bookStand(Vector3.new(8.3, F + 8.4 + 1.0, -5.8), Vector3.new(0.6, 2.0, 1.4), Color3.fromRGB(110, 45, 140))
bookStand(Vector3.new(9.0, F + 8.4 + 1.0, -5.8), Vector3.new(0.7, 2.2, 1.4), C.BOOK_RED)
bookStand(Vector3.new(9.8, F + 8.4 + 0.9, -5.8), Vector3.new(0.5, 1.8, 1.4), C.BOOK_BLUE)

--// ============ CALDERO, BÁCULOS Y CRISTALES ============
cauldron(Vector3.new(-9.8, F, 2.4), 1.0, true)
staff(Vector3.new(-6.4, F, 1.2), 7.0, C.YELLOW, 0)
staff(Vector3.new(6.4, F, 1.2), 7.0, C.MAGENTA, 0)
staff(Vector3.new(10.4, F, 4.6), 8.6, C.CYAN, -0.05)
cluster(Vector3.new(-9.2, F, 7.4), C.PURPLE, 5, 1.2)
cluster(Vector3.new(9.0, F, 7.6), C.BLUE, 5, 1.2)

--// ============ LUZ AMBIENTE ============
local amb = P("AmbientLight", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 10, 2), Color3.new(1, 1, 1), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
addLight(amb, Color3.fromRGB(255, 205, 140), 28, 0.8)

model.Parent = workspace
print("Tienda magica construida en " .. tostring(POSITION))

-- FIN TIENDA
