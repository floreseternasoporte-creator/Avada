--[[
	🧙 TIENDA MÁGICA v3 - Constructor procedural para Roblox
	---------------------------------------------------------
	CÓMO USARLO:
	1. En Roblox Studio abre ServerScriptService
	2. Inserta un "Script" (NO LocalScript) y pega todo este código
	3. Dale a Play: la tienda aparece sola en POSITION
	   (el frente mira hacia +Z; si quieres girarla cambia ROTATION_Y)

	Todo está hecho con Parts (sin assets externos).

	NOTA AVADA: archivo 3 de 3 (JUEGO, ISLA, TIENDA). POSITION ajustado
	a (0, 2, -40) para sentarla sobre la isla mirando al circulo, y
	ADJUST_LIGHTING en false porque la isla ya fija la luz del mundo
	(si lo pones en true, este archivo pasa a mandar en la luz).
]]

--// ============ CONFIGURACIÓN ============
local POSITION = Vector3.new(0, 2, -40)
local ROTATION_Y = 0 -- grados
local SHOP_TEXT = "TIENDA"
local ADJUST_LIGHTING = false -- true = ambiente de atardecer suave (ponlo en false si ya tienes tu propia iluminación)

--// ============ BASE DEL SISTEMA ============
local ORIGIN = CFrame.new(POSITION) * CFrame.Angles(0, math.rad(ROTATION_Y), 0)
local rng = Random.new(42)
local M = Enum.Material
local F = 1 -- altura del suelo de la tienda
local SZ = -5.6 -- z donde van los estantes (pegados a la pared de atrás)

local old = workspace:FindFirstChild("TiendaMagica")
if old then old:Destroy() end
local model = Instance.new("Model")
model.Name = "TiendaMagica"

local C = {
	WOOD_DARK = Color3.fromRGB(92, 56, 48),
	WOOD = Color3.fromRGB(140, 84, 50),
	WOOD_LIGHT = Color3.fromRGB(176, 116, 70),
	STAFF = Color3.fromRGB(150, 98, 60),
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
	POTION_PURPLE = Color3.fromRGB(205, 110, 255),
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
-- pos = punto en la superficie donde se apoya. Altura total aprox: 2.65 * s
local function potion(pos, color, s)
	s = s or 1
	local r = 0.8 * s
	ball("PotionBody", 2 * r, CFrame.new(pos + Vector3.new(0, r, 0)), color, M.Glass, { Transparency = 0.1 })
	ball("PotionShine", 0.35 * s, CFrame.new(pos + Vector3.new(-0.35 * r, r * 1.35, r * 0.72)), Color3.new(1, 1, 1), M.Neon, { Transparency = 0.45 })
	cyl("PotionNeck", 0.9 * s, 0.55 * s, CFrame.new(pos + Vector3.new(0, 2 * r + 0.25 * s, 0)), color, M.Glass, { Transparency = 0.2 })
	cyl("PotionCork", 0.4 * s, 0.5 * s, CFrame.new(pos + Vector3.new(0, 2 * r + 0.85 * s, 0)), Color3.fromRGB(200, 140, 85), M.Wood)
end

-- libro de pie (lomo hacia el frente +Z). pos = centro
local function bookStand(pos, size, color)
	P("Book", size, CFrame.new(pos), color, M.SmoothPlastic)
	P("BookPages", Vector3.new(size.X * 0.8, size.Y * 0.94, 0.05), CFrame.new(pos + Vector3.new(0, 0, -size.Z / 2 - 0.02)), C.PAPER)
	P("BookEmblem", Vector3.new(size.X * 0.55, size.X * 0.55, 0.05), CFrame.new(pos + Vector3.new(0, size.Y * 0.1, size.Z / 2 + 0.02)), C.GOLD, M.Neon)
	P("BookBand", Vector3.new(size.X * 1.02, 0.1, size.Z * 1.02), CFrame.new(pos + Vector3.new(0, size.Y * 0.38, 0)), C.GOLD)
	P("BookBand", Vector3.new(size.X * 1.02, 0.1, size.Z * 1.02), CFrame.new(pos + Vector3.new(0, -size.Y * 0.38, 0)), C.GOLD)
end

-- libro de pie apoyado sobre una tabla (base = altura de la tabla)
local function bookOn(x, base, z, size, color)
	bookStand(Vector3.new(x, base + size.Y / 2, z), size, color)
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

-- libro abierto parado sobre una tabla, mirando al frente. base = altura de la tabla
local function openBookOn(x, base, z, s)
	openBook(CFrame.new(x, base + 0.85 * s, z) * CFrame.Angles(math.rad(78), 0, 0), s)
end

local function scroll(cf, len)
	cylX("Scroll", len, 0.55, cf, Color3.fromRGB(236, 220, 172), M.Fabric)
	cylX("ScrollEnd", 0.12, 0.62, cf * CFrame.new(len / 2, 0, 0), Color3.fromRGB(205, 180, 125), M.Wood)
	cylX("ScrollEnd", 0.12, 0.62, cf * CFrame.new(-len / 2, 0, 0), Color3.fromRGB(205, 180, 125), M.Wood)
	cylX("ScrollBand", 0.14, 0.6, cf * CFrame.new(len * 0.15, 0, 0), C.BOOK_RED, M.Fabric)
end

-- cristal facetado: cuerpo + punta que se afina suavemente
local function crystal(cf, h, w, color)
	local glass = { Transparency = 0.2, Reflectance = 0.1 }
	local rot = CFrame.Angles(0, math.rad(45), 0)
	local bodyH = h * 0.6
	P("CrystalBody", Vector3.new(w, bodyH, w), cf * CFrame.new(0, bodyH / 2, 0) * rot, color, M.Glass, glass)
	local tiers = 6
	local step = (h - bodyH) / tiers
	for i = 1, tiers do
		local f = 1 - i / (tiers + 0.6)
		P("CrystalTip", Vector3.new(w * f, step + 0.02, w * f), cf * CFrame.new(0, bodyH + (i - 0.5) * step, 0) * rot, color, M.Glass, glass)
	end
	P("CrystalCore", Vector3.new(w * 0.28, h * 0.8, w * 0.28), cf * CFrame.new(0, h * 0.4, 0) * rot, color, M.Neon, { Transparency = 0.35 })
end

local function cluster(pos, color, count, scale)
	scale = scale or 1
	for i = 1, count do
		local ang = (i / count) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local off = Vector3.new(math.cos(ang), 0, math.sin(ang)) * rng:NextNumber(0.3, 0.9) * scale
		local cf = CFrame.new(pos + off)
			* CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 6), rng:NextNumber(-0.25, 0.25))
		crystal(cf, rng:NextNumber(1.8, 3.6) * scale, rng:NextNumber(0.7, 1.1) * scale, color)
	end
	local glow = P("CrystalGlow", Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos + Vector3.new(0, 1.2 * scale, 0)), color, M.Neon, { Transparency = 1, CanCollide = false })
	addLight(glow, color, 7, 0.45)
	sparkles(glow, color, 3)
end

-- báculo: base de madera, vara de cilindros lisos con nudos, garra y cristal
local function staff(base, height, color, tilt)
	tilt = tilt or 0
	cyl("StaffStand", 0.3, 1.6, CFrame.new(base + Vector3.new(0, 0.15, 0)), C.WOOD_DARK, M.Wood)
	local segs = 6
	local segH = height / segs
	local cur = CFrame.new(base + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, tilt)
	for i = 1, segs do
		local d = 0.4 - i * 0.025
		cyl("StaffWood", segH, d, cur * CFrame.new(0, segH / 2, 0), C.STAFF, M.Wood)
		cur = cur * CFrame.new(0, segH, 0)
		ball("StaffKnot", d * 1.3, cur, C.WOOD_DARK, M.Wood)
		cur = cur * CFrame.Angles(0, 0, ((i % 2 == 0) and 1 or -1) * 0.05)
	end
	-- anillo dorado + garra de 3 puntas
	cyl("StaffRing", 0.18, 0.6, cur * CFrame.new(0, 0.08, 0), C.GOLD, M.Metal)
	for k = 0, 2 do
		local ang = k * math.pi * 2 / 3
		cyl("StaffProng", 1.1, 0.17, cur * CFrame.Angles(0, ang, 0) * CFrame.new(0.17, 0.5, 0) * CFrame.Angles(0, 0, -0.28), C.WOOD_DARK, M.Wood)
	end
	crystal(cur * CFrame.new(0, 0.45, 0), 1.6, 0.62, color)
	local glow = P("StaffGlow", Vector3.new(0.4, 0.4, 0.4), cur * CFrame.new(0, 1.4, 0), color, M.Neon, { Transparency = 1, CanCollide = false })
	addLight(glow, color, 8, 0.55)
	sparkles(glow, color, 4)
end

local function lantern(center)
	local cf = CFrame.new(center)
	local glass = P("LanternGlass", Vector3.new(1.0, 1.5, 1.0), cf, Color3.fromRGB(255, 196, 100), M.Neon, { Transparency = 0.25 })
	addLight(glass, Color3.fromRGB(255, 185, 100), 12, 0.8)
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

-- caldero ABIERTO: panza + cuello + borde en anillo + poción morada brillante con burbujas
local function cauldron(pos, s, withStick)
	local cx, cy, cz = pos.X, pos.Y, pos.Z
	local dark = Color3.fromRGB(38, 38, 44)
	-- patas
	for _, a in ipairs({ 0, 2.094, 4.188 }) do
		cyl("CauldronLeg", 0.8 * s, 0.5 * s, CFrame.new(cx + math.cos(a) * 1.0 * s, cy + 0.4 * s, cz + math.sin(a) * 1.0 * s), dark, M.Metal)
	end
	-- panza y cuello
	ellipsoid("CauldronBelly", Vector3.new(3.6 * s, 2.6 * s, 3.6 * s), CFrame.new(cx, cy + 1.7 * s, cz), dark, M.Metal)
	cyl("CauldronNeck", 0.8 * s, 2.9 * s, CFrame.new(cx, cy + 2.6 * s, cz), dark, M.Metal)
	-- asas
	for _, sx in ipairs({ -1, 1 }) do
		ellipsoid("CauldronHandle", Vector3.new(0.55 * s, 0.6 * s, 0.35 * s), CFrame.new(cx + sx * 1.85 * s, cy + 2.4 * s, cz), dark, M.Metal)
	end
	-- borde en anillo (hueco en el centro)
	local ringN = 18
	for i = 0, ringN - 1 do
		local a = i / ringN * math.pi * 2
		P("CauldronRim", Vector3.new(0.7 * s, 0.3 * s, 0.4 * s), CFrame.new(cx, cy + 3.12 * s, cz) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 1.5 * s), dark, M.Metal)
	end
	-- poción morada
	local liquid = cyl("CauldronLiquid", 0.1 * s, 2.6 * s, CFrame.new(cx, cy + 3.06 * s, cz), C.POTION_PURPLE, M.Neon, { Transparency = 0.1 })
	addLight(liquid, C.POTION_PURPLE, 7, 0.5)
	-- burbujas sobre la superficie
	for i = 1, 6 do
		local a = rng:NextNumber(0, 6.28)
		local r = rng:NextNumber(0.1, 0.95) * s
		ball("Bubble", rng:NextNumber(0.25, 0.5) * s, CFrame.new(cx + math.cos(a) * r, cy + 3.12 * s, cz + math.sin(a) * r), Color3.fromRGB(235, 170, 255), M.Neon, { Transparency = 0.15 })
	end
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(225, 140, 255))
	e.LightEmission = 0.8
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1 * s), NumberSequenceKeypoint.new(0.5, 0.4 * s), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(1, 2.2)
	e.Speed = NumberRange.new(1.5, 3)
	e.Rate = 10
	e.SpreadAngle = Vector2.new(20, 20)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = liquid
	if withStick then
		P("Spoon", Vector3.new(0.3 * s, 4.4 * s, 0.3 * s), CFrame.new(cx - 0.9 * s, cy + 4.2 * s, cz) * CFrame.Angles(0, 0, 0.3), C.WOOD, M.Wood)
	end
end

-- estante: postes hasta topY, tablas en 'boards' (alturas absolutas), travesaño arriba
local function shelf(cx, cz, w, boards, topY)
	local h = topY - F
	for _, sx in ipairs({ -1, 1 }) do
		P("ShelfPost", Vector3.new(0.6, h, 1.2), CFrame.new(cx + sx * w / 2, F + h / 2, cz), C.WOOD, M.Wood)
	end
	for _, y in ipairs(boards) do
		P("ShelfBoard", Vector3.new(w, 0.35, 1.6), CFrame.new(cx, y, cz), C.WOOD_LIGHT, M.Wood)
	end
	P("ShelfTop", Vector3.new(w + 0.8, 0.5, 1.6), CFrame.new(cx, topY + 0.25, cz), C.WOOD, M.Wood)
end

--// ============ SUELO / BASE ============
P("BaseRim", Vector3.new(35, 0.75, 27), CFrame.new(0, 0.375, 0.5), C.WOOD_DARK, M.Wood)
P("Base", Vector3.new(34, 0.5, 26), CFrame.new(0, 0.75, 0.5), C.BASE, M.Grass)
local root = P("Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), C.BASE, M.SmoothPlastic, { Transparency = 1, CanCollide = false })
model.PrimaryPart = root

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

for _, side in ipairs({ -1, 1 }) do
	local cf = CFrame.new(side * 16.2, 11.0, -2) * CFrame.Angles(0, 0, -side * 0.42)
	roofPlane(cf, 5.6, 8, 4, 4)
	for _, z in ipairs({ 1.5, -5.5 }) do
		P("AwningBrace", Vector3.new(4.0, 0.5, 0.5), CFrame.new(side * 14.2, 10.25, z) * CFrame.Angles(0, 0, side * 0.55), C.WOOD_DARK, M.Wood)
	end
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
gui.Face = Enum.NormalId.Back -- la cara que mira hacia +Z (hacia el jugador)
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
P("CounterTop", Vector3.new(13.4, 0.6, 3.6), CFrame.new(0, top - 0.3, 4), C.WOOD, M.Wood)
P("CounterBack", Vector3.new(12.8, 3.4, 0.4), CFrame.new(0, F + 1.7, 2.4), C.WOOD_DARK, M.Wood)
for i = 0, 12 do
	local ph = 3.4 + rng:NextNumber(-0.08, 0.08)
	P("CounterPlank", Vector3.new(0.95, ph, 0.4), CFrame.new(-6 + i, F + ph / 2, 5.6), (i % 2 == 0) and C.WOOD or Color3.fromRGB(125, 74, 45), M.Wood)
end
for _, sx in ipairs({ -1, 1 }) do
	P("CounterEnd", Vector3.new(0.8, 3.8, 3.6), CFrame.new(sx * 6.4, F + 1.9, 4), C.WOOD_DARK, M.Wood)
end

-- objetos sobre el mostrador (cada uno con su espacio, sin encimarse)
potion(Vector3.new(-5.0, top, 3.9), C.RED, 1.0)
potion(Vector3.new(-3.2, top, 3.9), C.BLUE, 1.0)
potion(Vector3.new(-1.4, top, 3.9), C.PURPLE, 1.0)
openBook(CFrame.new(1.3, top + 0.08, 4.0) * CFrame.Angles(0, -0.12, 0), 1.0)
scroll(CFrame.new(3.4, top + 0.3, 2.95) * CFrame.Angles(0, 0.2, 0), 1.5)
bookFlat(CFrame.new(5.0, top + 0.35, 4.4), Vector3.new(2.2, 0.7, 1.6), C.BOOK_RED)
bookFlat(CFrame.new(5.0, top + 1.05, 4.4) * CFrame.Angles(0, 0.1, 0), Vector3.new(2.2, 0.7, 1.6), C.BOOK_BLUE)
cluster(Vector3.new(6.0, top, 2.7), C.TEAL, 3, 0.45)

--// ============ ESTANTES (con altura suficiente para que nada atraviese) ============
-- CENTRO
shelf(0, SZ, 8.4, { F + 4.8, F + 8.0 }, F + 11.5)
local c1, c2 = F + 4.8 + 0.175, F + 8.0 + 0.175
bookOn(-3.3, c1, SZ, Vector3.new(0.5, 2.0, 1.3), C.BOOK_BLUE)
bookOn(-2.7, c1, SZ, Vector3.new(0.6, 2.0, 1.3), C.BOOK_RED)
openBookOn(0.2, c1, SZ - 0.1, 1.0)
potion(Vector3.new(3.1, c1, SZ), C.RED, 0.8)
potion(Vector3.new(-1.9, c2, SZ), C.RED, 0.95)
potion(Vector3.new(0, c2, SZ), C.BLUE, 0.95)
potion(Vector3.new(1.9, c2, SZ), C.PURPLE, 0.95)

-- IZQUIERDA
shelf(-9.4, SZ, 4.4, { F + 2.8, F + 5.9, F + 9.0 }, F + 11.8)
cauldron(Vector3.new(-9.4, F + 2.8 + 0.175, SZ), 0.38, false)
openBookOn(-9.4, F + 5.9 + 0.175, SZ - 0.1, 0.95)
local l3 = F + 9.0 + 0.175
bookOn(-10.5, l3, SZ, Vector3.new(0.5, 1.8, 1.3), C.BOOK_BLUE)
bookOn(-9.8, l3, SZ, Vector3.new(0.6, 1.8, 1.3), C.BOOK_RED)
bookOn(-9.1, l3, SZ, Vector3.new(0.5, 1.6, 1.3), Color3.fromRGB(60, 60, 70))

-- DERECHA
shelf(9.4, SZ, 4.4, { F + 2.8, F + 5.9, F + 9.0 }, F + 11.8)
cluster(Vector3.new(9.4, F + 2.8 + 0.175, SZ), C.TEAL, 3, 0.4)
local r2 = F + 5.9 + 0.175
scroll(CFrame.new(8.8, r2 + 0.28, SZ), 2.4)
scroll(CFrame.new(10.0, r2 + 0.28, SZ) * CFrame.Angles(0, 0.08, 0), 2.2)
scroll(CFrame.new(9.4, r2 + 0.84, SZ) * CFrame.Angles(0, -0.08, 0), 2.4)
local r3 = F + 9.0 + 0.175
bookOn(8.2, r3, SZ, Vector3.new(0.6, 2.0, 1.3), Color3.fromRGB(110, 45, 140))
bookOn(8.95, r3, SZ, Vector3.new(0.7, 2.2, 1.3), C.BOOK_RED)
bookOn(9.7, r3, SZ, Vector3.new(0.5, 1.8, 1.3), C.BOOK_BLUE)

--// ============ CALDERO, BÁCULOS Y CRISTALES ============
cauldron(Vector3.new(-9.8, F, 2.4), 1.0, true)
-- báculos detrás del mostrador, cada uno en su soporte
staff(Vector3.new(-5.4, F, 0.6), 6.8, C.YELLOW, 0.04)
staff(Vector3.new(5.4, F, 0.6), 6.8, C.MAGENTA, -0.04)
-- báculo cian a la derecha, lejos de las linternas
staff(Vector3.new(10.4, F, 2.9), 8.0, C.CYAN, 0.08)
cluster(Vector3.new(-9.2, F, 7.6), C.PURPLE, 4, 0.9)
cluster(Vector3.new(9.0, F, 7.8), C.BLUE, 4, 0.9)

--// ============ ILUMINACIÓN SUAVE ============
if ADJUST_LIGHTING then
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 17.3
	Lighting.Brightness = 1.6
	Lighting.ExposureCompensation = -0.25
	Lighting.Ambient = Color3.fromRGB(60, 60, 75)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 90, 105)
	local bloom = Lighting:FindFirstChild("TiendaBloom") or Instance.new("BloomEffect")
	bloom.Name = "TiendaBloom"
	bloom.Intensity = 0.25
	bloom.Size = 20
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

model.Parent = workspace
print("✨ Tienda mágica construida en " .. tostring(POSITION))

-- FIN TIENDA
