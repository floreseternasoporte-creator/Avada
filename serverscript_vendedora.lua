--[[
	🧙‍♀️ VENDEDORA MÁGICA - NPC animada para la Tienda Mágica (estilo clásico con studs)
	-----------------------------------------------------------------------------------
	CÓMO USARLO:
	1. Ya debes tener el Script de la tienda (TiendaMagica.server.lua) en ServerScriptService
	2. Crea OTRO Script (NO LocalScript) en ServerScriptService y pega todo este código
	3. Dale a Play. La vendedora aparece detrás del mostrador:
	   - Sin clientes: camina de un lado a otro con las manos atrás.
	   - Cuando un jugador se acerca al frente de la tienda: viene sola al centro del
	     mostrador, saluda, te mira y mueve los brazos y la cabeza.
	   - Cuando te vas: vuelve a su patrulla.

	Se para sobre una tarima de madera detrás del mostrador (PLATFORM_H) para que se vean
	su cinturón y sus pociones por encima del mostrador.

	Todo son Parts (bloques Plastic con studs), con articulaciones Motor6D animadas por código.
	El modelo se llama "VendedoraMagica" en Workspace. El atributo "Customer" (UserId) del
	modelo indica a quién está atendiendo (útil para conectar un menú de compra después).

	[Avada] Archivo del dueno del juego, INTACTO. Espera sola a que el
	Script TIENDA construya el modelo "TiendaMagica" en Workspace y se
	apoya en su PrimaryPart y su suelo (F = 1), tal como viene.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// ============ CONFIGURACIÓN ============
local S = 1.1 -- escala de la vendedora (el sombrero debe quedar bajo el techo)
local FLOOR_Y = 1 -- altura del suelo de la tienda (igual que F en el otro script)
-- El mostrador mide 4 studs de alto y taparía su cinturón y sus pociones. Por eso ella
-- se para en una tarima de madera detrás del mostrador (desde el frente la tarima no se ve).
-- Pon PLATFORM_H = 0 para quitarla y que ella quede a nivel del piso.
local PLATFORM_H = 2.9
local STAND_Y = FLOOR_Y + PLATFORM_H
local PATROL_X = 2.6 -- recorre de -X a +X detrás del mostrador
local PATROL_Z = 0.2
local COUNTER_X, COUNTER_Z = 0, 0.9 -- punto del centro del mostrador donde atiende
local WALK_SPEED = 3.2
local GREET_SPEED = 4.2
local ZONE = { xMin = -15, xMax = 15, zMin = 5.5, zMax = 28 } -- zona frente a la tienda donde detecta clientes
local LEAVE_DELAY = 4 -- segundos sin clientes para volver a patrullar
local CHAR_STUDS_ON_SIDES = false -- true = studs también en los lados (la cara siempre queda lisa)
local SHOW_NAME = true
local NAME_TEXT = "Vendedora Mágica"

--// ============ ESPERAR LA TIENDA ============
local shop = workspace:WaitForChild("TiendaMagica", 30)
if not shop then
	warn("VendedoraMagica: no encontré 'TiendaMagica' en Workspace. Pon primero el script de la tienda.")
	return
end
while not shop.PrimaryPart do
	task.wait()
end
local ORIGIN = shop.PrimaryPart.CFrame * CFrame.new(0, -0.5, 0)

local old = workspace:FindFirstChild("VendedoraMagica")
if old then old:Destroy() end

--// ============ TARIMA DE MADERA (estilo studs) ============
local oldPlat = workspace:FindFirstChild("TarimaVendedora")
if oldPlat then oldPlat:Destroy() end
if PLATFORM_H > 0 then
	local plat = Instance.new("Model")
	plat.Name = "TarimaVendedora"
	local function pp(name, size, x, y, z, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = ORIGIN * CFrame.new(x, y, z)
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Studs
		p.BottomSurface = Enum.SurfaceType.Inlet
		p.Parent = plat
		return p
	end
	-- ocupa el espacio entre el mostrador (z 2.2) y los estantes, sin tocar los báculos (x = ±5.4)
	local W, D, CZ = 9.0, 4.3, -0.05
	local woodDark = Color3.fromRGB(92, 56, 48)
	local wood = Color3.fromRGB(140, 84, 50)
	pp("TarimaBase", Vector3.new(W, PLATFORM_H - 0.4, D), 0, FLOOR_Y + (PLATFORM_H - 0.4) / 2, CZ, woodDark)
	pp("TarimaTop", Vector3.new(W + 0.4, 0.4, D + 0.4), 0, FLOOR_Y + PLATFORM_H - 0.2, CZ, wood)
	plat.Parent = workspace
end

--// ============ COLORES ============
local V = Vector3.new
local C = {
	NAVY = Color3.fromRGB(58, 52, 112),
	BLUE = Color3.fromRGB(52, 78, 142),
	PURPLE_BAND = Color3.fromRGB(96, 72, 150),
	HAT = Color3.fromRGB(46, 52, 112),
	GOLD = Color3.fromRGB(236, 186, 52),
	SKIN = Color3.fromRGB(232, 188, 150),
	SKIN_DARK = Color3.fromRGB(212, 165, 130),
	HAIR = Color3.fromRGB(148, 138, 178),
	DARK = Color3.fromRGB(70, 42, 36),
	GLASS = Color3.fromRGB(190, 190, 200),
	BROWN = Color3.fromRGB(112, 72, 42),
	CORK = Color3.fromRGB(200, 140, 85),
	PANTS = Color3.fromRGB(44, 44, 84),
	SHOE = Color3.fromRGB(72, 52, 42),
	SHOE_TOE = Color3.fromRGB(92, 68, 54),
	POUCH = Color3.fromRGB(132, 82, 52),
	GEM = Color3.fromRGB(190, 92, 232),
	STAR = Color3.fromRGB(156, 106, 204),
	SILVER = Color3.fromRGB(205, 205, 215),
	STAFF = Color3.fromRGB(152, 100, 62),
	STAFF_DARK = Color3.fromRGB(110, 70, 44),
	CYAN = Color3.fromRGB(70, 220, 255),
	RED = Color3.fromRGB(224, 44, 54),
	BLUE_POTION = Color3.fromRGB(44, 94, 236),
	WHITE = Color3.new(1, 1, 1),
}

--// ============ CONSTRUCCIÓN DEL RIG ============
-- Todas las medidas están en "unidades de diseño" (se multiplican por S).
-- El frente de la vendedora es -Z (como los personajes de Roblox).
local BASE = ORIGIN * CFrame.new(-PATROL_X, STAND_Y + 3 * S, PATROL_Z) * CFrame.Angles(0, -math.pi / 2, 0)
local rig = Instance.new("Model")
rig.Name = "VendedoraMagica"

local function mk(name, size, x, y, z, color, rot, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size * S
	p.CFrame = BASE * CFrame.new(x * S, y * S, z * S) * (rot or CFrame.new())
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if transparency then p.Transparency = transparency end
	p.Parent = rig
	return p
end

local function weld(a, b)
	local w = Instance.new("Weld")
	w.Part0 = a
	w.Part1 = b
	w.C0 = a.CFrame:Inverse() * b.CFrame
	w.Parent = b
end

-- accesorio pegado a un miembro
local function acc(limb, name, size, x, y, z, color, rot, transparency)
	local p = mk(name, size, x, y, z, color, rot, transparency)
	weld(limb, p)
	return p
end

local joints = {}
local function motor(name, p0, p1, jx, jy, jz)
	local jw = BASE * CFrame.new(jx * S, jy * S, jz * S)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = p0.CFrame:Inverse() * jw
	m.C1 = p1.CFrame:Inverse() * jw
	m.Parent = p0
	joints[name] = { m = m, c0 = m.C0 }
end

-- ---------- RAÍZ Y TORSO ----------
local root = mk("HumanoidRootPart", V(2, 2, 1), 0, 0, 0, C.NAVY, nil, 1)
root.Anchored = true

local torso = mk("Torso", V(2, 2, 1), 0, 0, 0, C.NAVY)
acc(torso, "Panel", V(0.95, 2, 0.08), 0, 0, -0.54, C.BLUE)
acc(torso, "TrimL", V(0.1, 2, 0.09), -0.52, 0, -0.55, C.GOLD)
acc(torso, "TrimR", V(0.1, 2, 0.09), 0.52, 0, -0.55, C.GOLD)
acc(torso, "Neck", V(0.55, 0.3, 0.55), 0, 1.1, -0.05, C.SKIN)
-- cuello en V con runas
acc(torso, "CollarL", V(0.95, 0.22, 0.1), -0.45, 0.75, -0.56, C.PURPLE_BAND, CFrame.Angles(0, 0, -0.5))
acc(torso, "CollarR", V(0.95, 0.22, 0.1), 0.45, 0.75, -0.56, C.PURPLE_BAND, CFrame.Angles(0, 0, 0.5))
acc(torso, "CollarTrimL", V(0.95, 0.06, 0.11), -0.49, 0.62, -0.565, C.GOLD, CFrame.Angles(0, 0, -0.5))
acc(torso, "CollarTrimR", V(0.95, 0.06, 0.11), 0.49, 0.62, -0.565, C.GOLD, CFrame.Angles(0, 0, 0.5))
for _, sx in ipairs({ -1, 1 }) do
	acc(torso, "CollarRuneA", V(0.06, 0.15, 0.04), sx * 0.75, 0.83, -0.62, C.GOLD)
	acc(torso, "CollarRuneB", V(0.06, 0.12, 0.04), sx * 0.5, 0.7, -0.62, C.GOLD, CFrame.Angles(0, 0, sx * 0.6))
	acc(torso, "CollarRuneC", V(0.06, 0.12, 0.04), sx * 0.27, 0.57, -0.62, C.GOLD)
end
acc(torso, "Gem", V(0.24, 0.24, 0.1), 0, 0.36, -0.6, C.GEM, CFrame.Angles(0, 0, math.pi / 4))
-- cinturón con hebilla
acc(torso, "Belt", V(2.1, 0.32, 1.1), 0, -0.82, 0, C.BROWN)
acc(torso, "BuckleT", V(0.52, 0.09, 0.1), 0, -0.62, -0.58, C.GOLD)
acc(torso, "BuckleB", V(0.52, 0.09, 0.1), 0, -1.02, -0.58, C.GOLD)
acc(torso, "BuckleL", V(0.09, 0.4, 0.1), -0.215, -0.82, -0.58, C.GOLD)
acc(torso, "BuckleR", V(0.09, 0.4, 0.1), 0.215, -0.82, -0.58, C.GOLD)
acc(torso, "BuckleP", V(0.3, 0.07, 0.1), 0.05, -0.82, -0.58, C.GOLD)
-- pociones del cinturón
local function potion(x, color)
	acc(torso, "PotionStrap", V(0.12, 0.22, 0.1), x, -1.05, -0.62, C.BROWN)
	acc(torso, "PotionCork", V(0.2, 0.14, 0.2), x, -1.18, -0.72, C.CORK)
	acc(torso, "PotionNeck", V(0.17, 0.2, 0.17), x, -1.3, -0.72, color, nil, 0.15)
	acc(torso, "PotionBody1", V(0.5, 0.18, 0.5), x, -1.5, -0.72, color, nil, 0.1)
	acc(torso, "PotionBody2", V(0.68, 0.22, 0.68), x, -1.7, -0.72, color, nil, 0.1)
	acc(torso, "PotionBody3", V(0.5, 0.18, 0.5), x, -1.89, -0.72, color, nil, 0.1)
	acc(torso, "FaceShine", V(0.12, 0.12, 0.04), x - 0.15, -1.65, -1.08, C.WHITE, nil, 0.3)
end
potion(0.62, C.RED)
potion(-0.62, C.BLUE_POTION)
-- bolsita del cinturón
acc(torso, "PouchTie", V(0.3, 0.12, 0.3), -1.12, -0.88, -0.05, C.BROWN)
acc(torso, "PouchA", V(0.5, 0.2, 0.45), -1.12, -1.0, -0.05, C.POUCH)
acc(torso, "PouchB", V(0.72, 0.3, 0.6), -1.14, -1.25, -0.05, C.POUCH)
acc(torso, "PouchC", V(0.5, 0.2, 0.45), -1.12, -1.5, -0.05, C.POUCH)
-- pelo largo sobre el torso
acc(torso, "HairBack", V(1.7, 2.0, 0.35), 0, 0.15, 0.68, C.HAIR)
acc(torso, "HairBackLow", V(1.3, 0.8, 0.3), 0, -1.0, 0.68, C.HAIR)
for _, sx in ipairs({ -1, 1 }) do
	acc(torso, "HairLock", V(0.42, 1.5, 0.3), sx * 0.88, 0.3, -0.64, C.HAIR)
	acc(torso, "HairLockLow", V(0.32, 0.6, 0.25), sx * 0.88, -0.75, -0.62, C.HAIR)
end

-- ---------- CABEZA ----------
local hy = 1.9
local head = mk("Head", V(1.5, 1.5, 1.3), 0, hy, 0, C.SKIN)
-- cara (todo lo "Face..." se queda liso, sin studs)
local eyes = {}
for _, sx in ipairs({ -1, 1 }) do
	eyes[#eyes + 1] = acc(head, "FaceEye", V(0.14, 0.2, 0.05), sx * 0.36, hy + 0.12, -0.67, C.DARK)
	acc(head, "FaceBrow", V(0.32, 0.07, 0.05), sx * 0.36, hy + 0.44, -0.67, C.HAIR)
	-- gafas redondas (marcos de bloques)
	acc(head, "FaceGlassT", V(0.52, 0.06, 0.05), sx * 0.36, hy + 0.12 + 0.25, -0.69, C.GLASS)
	acc(head, "FaceGlassB", V(0.52, 0.06, 0.05), sx * 0.36, hy + 0.12 - 0.25, -0.69, C.GLASS)
	acc(head, "FaceGlassL", V(0.06, 0.5, 0.05), sx * 0.36 - 0.26, hy + 0.12, -0.69, C.GLASS)
	acc(head, "FaceGlassR", V(0.06, 0.5, 0.05), sx * 0.36 + 0.26, hy + 0.12, -0.69, C.GLASS)
	acc(head, "FaceGlassArm", V(0.05, 0.06, 0.5), sx * 0.77, hy + 0.12, -0.42, C.GLASS)
	-- arruguitas
	acc(head, "FaceLine", V(0.05, 0.16, 0.04), sx * 0.52, hy - 0.3, -0.67, C.SKIN_DARK)
	acc(head, "FaceLine", V(0.14, 0.04, 0.04), sx * 0.64, hy + 0.12, -0.67, C.SKIN_DARK, CFrame.Angles(0, 0, sx * 0.5))
	acc(head, "FaceLine", V(0.14, 0.04, 0.04), sx * 0.64, hy + 0.04, -0.67, C.SKIN_DARK, CFrame.Angles(0, 0, -sx * 0.5))
end
acc(head, "FaceGlassBridge", V(0.2, 0.06, 0.05), 0, hy + 0.14, -0.69, C.GLASS)
acc(head, "FaceNose", V(0.22, 0.28, 0.18), 0, hy - 0.12, -0.72, C.SKIN_DARK)
do
	local xs = { -0.32, -0.16, 0, 0.16, 0.32 }
	local ys = { 0.04, -0.04, -0.07, -0.04, 0.04 }
	for i = 1, 5 do
		acc(head, "FaceSmile", V(0.15, 0.07, 0.05), xs[i], hy - 0.42 + ys[i], -0.67, C.DARK)
	end
end
-- pelo de la cabeza
acc(head, "HairTop", V(1.62, 0.3, 1.42), 0, hy + 0.8, 0.02, C.HAIR)
acc(head, "HairSideL", V(0.3, 1.4, 1.2), -0.88, hy - 0.05, 0.05, C.HAIR)
acc(head, "HairSideR", V(0.3, 1.4, 1.2), 0.88, hy - 0.05, 0.05, C.HAIR)
acc(head, "HairNape", V(1.6, 1.4, 0.3), 0, hy - 0.05, 0.7, C.HAIR)
acc(head, "HairFringeL", V(0.85, 0.28, 0.12), -0.42, hy + 0.64, -0.68, C.HAIR, CFrame.Angles(0, 0, 0.3))
acc(head, "HairFringeR", V(0.85, 0.28, 0.12), 0.42, hy + 0.64, -0.68, C.HAIR, CFrame.Angles(0, 0, -0.3))

-- ---------- SOMBRERO ----------
local hatY = hy + 0.75
acc(head, "HatBrimA", V(3.9, 0.22, 3.0), 0, hatY + 0.1, 0, C.HAT)
acc(head, "HatBrimB", V(3.0, 0.2, 3.9), 0, hatY + 0.1, 0, C.HAT)
acc(head, "HatBrimC", V(3.3, 0.18, 3.3), 0, hatY + 0.1, 0, C.HAT, CFrame.Angles(0, math.pi / 4, 0))
local tiers, tierH = 8, 0.5
for i = 1, tiers do
	local w = 2.5 - (i - 1) * 0.285
	local d = w * 0.92
	local dx = -0.012 * i * i
	local dz = 0.008 * i * i
	local y = hatY + 0.2 + (i - 0.5) * tierH
	acc(head, "HatTier", V(w, tierH, d), dx, y, dz, C.HAT)
	if i == 3 or i == 4 or i == 5 or i == 6 then
		-- tachuelas plateadas a los lados
		local side = (i % 2 == 0) and 1 or -1
		acc(head, "HatStud", V(0.17, 0.17, 0.17), dx + side * (w / 2 + 0.03), y, dz - 0.2, C.SILVER)
	end
end
-- punta doblada
do
	local dx = -0.012 * 64
	acc(head, "HatTip", V(0.38, 0.42, 0.32), dx - 0.3, hatY + 4.35, 0.008 * 64 + 0.05, C.HAT, CFrame.Angles(0, 0, -0.9))
end
-- banda morada y hebilla dorada
acc(head, "HatBand", V(2.64, 0.4, 2.44), 0, hatY + 0.4, 0, C.PURPLE_BAND)
acc(head, "HatBuckleT", V(0.85, 0.1, 0.1), 0, hatY + 0.4 + 0.25, -1.27, C.GOLD)
acc(head, "HatBuckleB", V(0.85, 0.1, 0.1), 0, hatY + 0.4 - 0.25, -1.27, C.GOLD)
acc(head, "HatBuckleL", V(0.1, 0.6, 0.1), -0.375, hatY + 0.4, -1.27, C.GOLD)
acc(head, "HatBuckleR", V(0.1, 0.6, 0.1), 0.375, hatY + 0.4, -1.27, C.GOLD)
-- estrellas moradas en el cono
do
	local stars = { { 3, 0.3 }, { 4, -0.3 }, { 5, 0.2 }, { 6, -0.12 } }
	for _, s in ipairs(stars) do
		local i = s[1]
		local w = 2.5 - (i - 1) * 0.285
		local d = w * 0.92
		local dx = -0.012 * i * i
		local dz = 0.008 * i * i
		local y = hatY + 0.2 + (i - 0.5) * tierH
		local fz = dz - d / 2 - 0.03
		acc(head, "HatStarA", V(0.26, 0.07, 0.04), dx + s[2], y, fz, C.STAR)
		acc(head, "HatStarB", V(0.07, 0.26, 0.04), dx + s[2], y, fz, C.STAR)
		acc(head, "HatStarC", V(0.2, 0.06, 0.04), dx + s[2], y, fz, C.STAR, CFrame.Angles(0, 0, math.pi / 4))
		acc(head, "HatStarD", V(0.2, 0.06, 0.04), dx + s[2], y, fz, C.STAR, CFrame.Angles(0, 0, -math.pi / 4))
	end
	-- runas moradas
	acc(head, "HatRune", V(0.07, 0.26, 0.04), 0.75, hatY + 0.95, -1.05, C.STAR)
	acc(head, "HatRune", V(0.14, 0.07, 0.04), 0.78, hatY + 1.0, -1.05, C.STAR, CFrame.Angles(0, 0, 0.6))
	acc(head, "HatRune", V(0.07, 0.24, 0.04), -0.8, hatY + 1.25, -1.0, C.STAR)
end
-- tachuelas plateadas en el ala
for _, p in ipairs({ { -1.6, -0.9 }, { 1.6, -0.9 }, { -1.4, 0.9 }, { 1.4, 0.9 }, { 0, -1.35 } }) do
	acc(head, "HatBrimStud", V(0.2, 0.18, 0.2), p[1], hatY + 0.3, p[2], C.SILVER)
end

-- ---------- BRAZOS ----------
local function buildArm(sign, name)
	local sleeve = mk(name, V(1.2, 1.5, 1.2), sign * 1.65, 0.2, 0, C.NAVY)
	acc(sleeve, name .. "Cuff", V(1.32, 0.2, 1.32), sign * 1.65, -0.64, 0, C.GOLD)
	acc(sleeve, name .. "Hand", V(0.95, 0.8, 0.95), sign * 1.65, -1.1, 0, C.SKIN)
	acc(sleeve, name .. "Pad", V(1.3, 0.3, 1.3), sign * 1.65, 0.97, 0, C.PURPLE_BAND)
	acc(sleeve, name .. "PadTrim", V(1.34, 0.07, 0.12), sign * 1.65, 1.0, -0.6, C.GOLD)
	acc(sleeve, name .. "SleeveTrim", V(0.08, 1.4, 0.08), sign * 1.65, 0.2, -0.62, C.GOLD)
	return sleeve
end
local rArm = buildArm(1, "RightArm")
local lArm = buildArm(-1, "LeftArm")

-- ---------- PIERNAS Y ZAPATOS ----------
local function buildLeg(sign, name)
	local leg = mk(name, V(1, 2, 1), sign * 0.5, -2, 0, C.PANTS)
	acc(leg, name .. "Shoe", V(1.05, 0.65, 1.3), sign * 0.5, -2.675, -0.12, C.SHOE)
	acc(leg, name .. "Toe", V(0.9, 0.3, 0.25), sign * 0.5, -2.8, -0.8, C.SHOE_TOE)
	acc(leg, name .. "Heel", V(1.0, 0.25, 0.3), sign * 0.5, -2.85, 0.45, C.DARK)
	return leg
end
local rLeg = buildLeg(1, "RightLeg")
local lLeg = buildLeg(-1, "LeftLeg")

-- ---------- TÚNICA (falda) ----------
local robe = mk("Robe", V(2.2, 0.45, 1.25), 0, -1.225, 0, C.NAVY)
acc(robe, "RobeL2", V(2.5, 0.45, 1.4), 0, -1.675, 0, C.NAVY)
acc(robe, "RobeL3", V(2.8, 0.45, 1.55), 0, -2.125, 0, C.NAVY)
do
	local layers = { { -1.225, 1.25 }, { -1.675, 1.4 }, { -2.125, 1.55 } }
	for idx, l in ipairs(layers) do
		local y, depth = l[1], l[2]
		local z = -(depth / 2) - 0.04
		acc(robe, "RobePanel", V(0.95, 0.45, 0.08), 0, y, z, C.BLUE)
		acc(robe, "RobeTrim", V(0.1, 0.45, 0.09), -0.52, y, z - 0.005, C.GOLD)
		acc(robe, "RobeTrim", V(0.1, 0.45, 0.09), 0.52, y, z - 0.005, C.GOLD)
		if idx >= 2 then
			-- runas doradas a los lados del panel
			for _, sx in ipairs({ -1, 1 }) do
				acc(robe, "RobeRuneA", V(0.07, 0.3, 0.04), sx * 0.92, y, z + 0.0, C.GOLD)
				acc(robe, "RobeRuneB", V(0.07, 0.2, 0.04), sx * 0.98, y + 0.06, z + 0.0, C.GOLD, CFrame.Angles(0, 0, sx * 0.7))
			end
		end
	end
	acc(robe, "RobeHem", V(2.86, 0.1, 1.6), 0, -2.33, 0, C.GOLD)
end

-- ---------- BÁCULO (en la mano derecha) ----------
local staff = mk("Staff", V(0.2, 0.7, 0.2), 1.65, -0.4, -0.1, C.STAFF)
for i = 1, 8 do
	local y = -3.0 + (i - 0.5) * 0.65
	local off = ((i % 2 == 0) and 1 or -1) * 0.05
	local w = 0.27 - i * 0.012
	acc(staff, "StaffSeg", V(w, 0.65, w), 1.65 + off, y, -0.1, C.STAFF)
	if i % 2 == 0 then
		acc(staff, "StaffKnot", V(w + 0.1, 0.12, w + 0.1), 1.65 + off, y + 0.3, -0.1, C.STAFF_DARK)
	end
end
-- garra y cristal cian
for _, sx in ipairs({ -1, 1 }) do
	acc(staff, "StaffProng", V(0.12, 0.7, 0.12), 1.65 + sx * 0.14, 2.5, -0.1, C.STAFF_DARK, CFrame.Angles(0, 0, -sx * 0.3))
	acc(staff, "StaffProng", V(0.12, 0.7, 0.12), 1.65, 2.5, -0.1 + sx * 0.14, C.STAFF_DARK, CFrame.Angles(sx * 0.3, 0, 0))
end
do
	local cx, cz = 1.65, -0.1
	local rot45 = CFrame.Angles(0, math.pi / 4, 0)
	acc(staff, "CrystalBody", V(0.46, 0.8, 0.46), cx, 3.0, cz, C.CYAN, rot45, 0.15)
	local widths = { 0.38, 0.28, 0.18, 0.09 }
	for i, w in ipairs(widths) do
		acc(staff, "CrystalTip", V(w, 0.17, w), cx, 3.4 + (i - 0.5) * 0.17, cz, C.CYAN, rot45, 0.15)
	end
	local core = acc(staff, "CrystalCore", V(0.14, 1.0, 0.14), cx, 3.15, cz, Color3.fromRGB(190, 250, 255), rot45, 0.3)
	local light = Instance.new("PointLight")
	light.Color = C.CYAN
	light.Range = 8
	light.Brightness = 0.6
	light.Shadows = false
	light.Parent = core
end

-- ---------- ARTICULACIONES ----------
motor("RootJoint", root, torso, 0, 0, 0)
motor("Neck", torso, head, 0, 1.1, 0)
motor("RightShoulder", torso, rArm, 1.65, 0.95, 0)
motor("LeftShoulder", torso, lArm, -1.65, 0.95, 0)
motor("RightHip", root, rLeg, 0.5, -1, 0)
motor("LeftHip", root, lLeg, -0.5, -1, 0)
motor("Robe", root, robe, 0, -1, 0)
motor("StaffGrip", rArm, staff, 1.65, -1.1, -0.1)

-- ---------- ESTILO STUDS PARA TODA LA VENDEDORA ----------
for _, p in ipairs(rig:GetDescendants()) do
	if p:IsA("Part") and p ~= root then
		p.Material = Enum.Material.Plastic
		p.Reflectance = 0
		if string.sub(p.Name, 1, 4) ~= "Face" then
			p.TopSurface = Enum.SurfaceType.Studs
			p.BottomSurface = Enum.SurfaceType.Inlet
			if CHAR_STUDS_ON_SIDES then
				p.LeftSurface = Enum.SurfaceType.Studs
				p.RightSurface = Enum.SurfaceType.Studs
				p.FrontSurface = Enum.SurfaceType.Studs
				p.BackSurface = Enum.SurfaceType.Studs
			end
		end
	end
end

-- ---------- ETIQUETA CON EL NOMBRE ----------
if SHOW_NAME then
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Adornee = head
	bb.Size = UDim2.new(0, 170, 0, 34)
	bb.StudsOffset = Vector3.new(0, 5.6 * S, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 60
	bb.Parent = head
	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.Text = NAME_TEXT
	tl.Font = Enum.Font.Fantasy
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(255, 240, 200)
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.fromRGB(40, 20, 60)
	tl.Parent = bb
end

rig.PrimaryPart = root
rig.Parent = workspace

--// ============ ANIMACIÓN Y COMPORTAMIENTO ============
local function damp(cur, target, k, dt)
	return cur + (target - cur) * (1 - math.exp(-k * dt))
end

local function angleDiff(target, cur)
	return (target - cur + math.pi) % (2 * math.pi) - math.pi
end

local function findCustomer()
	local best, bestD
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local lp = ORIGIN:PointToObjectSpace(hrp.Position)
			if lp.X > ZONE.xMin and lp.X < ZONE.xMax and lp.Z > ZONE.zMin and lp.Z < ZONE.zMax and math.abs(lp.Y) < 20 then
				local d = (Vector3.new(lp.X, 0, lp.Z) - Vector3.new(0, 0, 12)).Magnitude
				if not bestD or d < bestD then
					best, bestD = plr, d
				end
			end
		end
	end
	return best
end

local px, pz = -PATROL_X, PATROL_Z
local yaw, targetYaw = -math.pi / 2, -math.pi / 2
local dir = 1 -- 1 = hacia +X, -1 = hacia -X
local pauseT = 0
local state = "patrol" -- patrol | toCounter | serving | returning
local phase, speedNow = 0, 0
local t = 0
local scanT = 0
local customer = nil
local sinceCustomer = 99
local nodT = 0
local blinkNext, blinkT = 2.5, 0
local gestureNext, gestureT = 3, 0
local amp = 0
local pose = { rsx = -0.62, rsz = -0.5, lsx = -0.62, lsz = 0.5, hy = 0, hp = 0 }

local eyeOpen = eyes[1].Size
local eyeClosed = Vector3.new(eyeOpen.X, 0.05, eyeOpen.Z)

local function stepToward(tx, tz, speed, dt)
	local dx, dz = tx - px, tz - pz
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 0.05 then
		return true, 0
	end
	local step = math.min(speed * dt, dist)
	px = px + dx / dist * step
	pz = pz + dz / dist * step
	targetYaw = math.atan2(-dx, -dz)
	return step >= dist - 1e-4, step / dt
end

RunService.Heartbeat:Connect(function(dt)
	if not rig.Parent then return end
	dt = math.min(dt, 0.1)
	t = t + dt

	-- detectar clientes
	scanT = scanT + dt
	if scanT > 0.2 then
		scanT = 0
		customer = findCustomer()
		if customer then sinceCustomer = 0 end
	end
	sinceCustomer = sinceCustomer + dt

	-- máquina de estados
	local moved = 0
	if state == "patrol" then
		if customer then
			state = "toCounter"
		elseif pauseT > 0 then
			pauseT = pauseT - dt
			targetYaw = (dir > 0) and (-math.pi / 2) or (math.pi / 2)
		else
			local tx = (dir > 0) and PATROL_X or -PATROL_X
			local arrived, v = stepToward(tx, PATROL_Z, WALK_SPEED, dt)
			moved = v
			if arrived then
				pauseT = 1.2 + math.random() * 1.3
				dir = -dir
			end
		end
	elseif state == "toCounter" then
		local arrived, v = stepToward(COUNTER_X, COUNTER_Z, GREET_SPEED, dt)
		moved = v
		if arrived then
			state = "serving"
			targetYaw = math.pi
			nodT = 0.001
			gestureNext = 1.2
		end
	elseif state == "serving" then
		targetYaw = math.pi
		if not customer and sinceCustomer > LEAVE_DELAY then
			state = "returning"
		end
	elseif state == "returning" then
		local tx = math.clamp(px, -PATROL_X, PATROL_X)
		local arrived, v = stepToward(tx, PATROL_Z, WALK_SPEED, dt)
		moved = v
		if customer then
			state = "toCounter"
		elseif arrived then
			state = "patrol"
			pauseT = 0.5
			dir = (px >= 0) and -1 or 1
		end
	end
	shop:SetAttribute("VendedoraState", state)
	rig:SetAttribute("State", state)
	rig:SetAttribute("Customer", customer and customer.UserId or 0)

	-- giro suave del cuerpo
	yaw = yaw + angleDiff(targetYaw, yaw) * (1 - math.exp(-dt * 6))
	speedNow = damp(speedNow, moved, 10, dt)
	local walking = speedNow > 0.15
	local walkF = math.clamp(speedNow / WALK_SPEED, 0, 1.3)
	phase = phase + speedNow * dt * 2.3
	amp = damp(amp, walkF * 0.6, 8, dt)

	local rootCF = ORIGIN * CFrame.new(px, STAND_Y + 3 * S, pz) * CFrame.Angles(0, yaw, 0)
	root.CFrame = rootCF

	-- ---------- objetivos de pose ----------
	local handsBehind = state ~= "serving"
	local trsx, trsz, tlsx, tlsz
	if handsBehind then
		-- manos atrás (agarradas a la espalda)
		trsx = -0.62 + math.sin(phase) * 0.05 * walkF
		trsz = -0.5
		tlsx = -0.62 - math.sin(phase) * 0.05 * walkF
		tlsz = 0.5
	else
		-- atendiendo: brazo derecho relajado con el báculo, izquierdo con gestos
		trsx = 0.15 + math.sin(t * 1.8) * 0.015
		trsz = 0.12
		tlsx = 0.15 + math.sin(t * 1.8 + 1) * 0.015
		tlsz = -0.12
		gestureNext = gestureNext - dt
		if gestureNext <= 0 and gestureT <= 0 then
			gestureT = 1.9
			gestureNext = 4 + math.random() * 3
		end
		if gestureT > 0 then
			gestureT = gestureT - dt
			-- brazo izquierdo abierto hacia el cliente con un pequeño saludo
			tlsx = 0.25
			tlsz = -0.95 + math.sin(t * 7) * 0.06
		end
	end
	pose.rsx = damp(pose.rsx, trsx, 6, dt)
	pose.rsz = damp(pose.rsz, trsz, 6, dt)
	pose.lsx = damp(pose.lsx, tlsx, 6, dt)
	pose.lsz = damp(pose.lsz, tlsz, 6, dt)

	-- cabeza
	local thy, thp
	if state == "serving" and customer and customer.Character and customer.Character:FindFirstChild("Head") then
		local rel = rootCF:PointToObjectSpace(customer.Character.Head.Position)
		local flat = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
		thy = math.clamp(math.atan2(-rel.X, -rel.Z), -1.0, 1.0)
		thp = math.clamp(math.atan2(rel.Y - 1.9 * S, math.max(flat, 0.1)), -0.35, 0.4)
	elseif state == "serving" then
		thy = math.sin(t * 0.5) * 0.15
		thp = 0
	else
		-- mirando a los lados mientras camina
		thy = math.sin(t * 0.7) * 0.35 + math.sin(t * 0.31) * 0.12
		thp = math.sin(t * 0.5) * 0.05
	end
	if nodT > 0 then
		nodT = nodT + dt
		if nodT < 0.8 then
			thp = thp - math.sin(nodT / 0.8 * math.pi) * 0.2
		else
			nodT = 0
		end
	end
	pose.hy = damp(pose.hy, thy, 6, dt)
	pose.hp = damp(pose.hp, thp, 6, dt)

	-- ---------- aplicar a las articulaciones ----------
	local bob = math.abs(math.sin(phase)) * 0.06 * S * math.min(walkF, 1) + math.sin(t * 1.8) * 0.012 * S
	local twist = math.sin(phase) * 0.07 * math.min(walkF, 1)
	joints.RootJoint.m.C0 = joints.RootJoint.c0 * CFrame.new(0, bob, 0) * CFrame.Angles(0, twist, 0)
	joints.Neck.m.C0 = joints.Neck.c0 * CFrame.Angles(pose.hp, pose.hy, 0)

	local rR = CFrame.Angles(pose.rsx, 0, pose.rsz)
	joints.RightShoulder.m.C0 = joints.RightShoulder.c0 * rR
	joints.LeftShoulder.m.C0 = joints.LeftShoulder.c0 * CFrame.Angles(pose.lsx, 0, pose.lsz)
	-- el báculo se contrarresta para quedar siempre vertical en su mano
	joints.StaffGrip.m.C0 = joints.StaffGrip.c0 * rR:Inverse()

	joints.RightHip.m.C0 = joints.RightHip.c0 * CFrame.Angles(math.sin(phase) * amp, 0, 0)
	joints.LeftHip.m.C0 = joints.LeftHip.c0 * CFrame.Angles(-math.sin(phase) * amp, 0, 0)

	joints.Robe.m.C0 = joints.Robe.c0
		* CFrame.Angles(math.sin(phase) * 0.04 * math.min(walkF, 1) + math.sin(t * 1.6) * 0.01, 0, math.cos(phase) * 0.03 * math.min(walkF, 1))

	-- parpadeo
	blinkNext = blinkNext - dt
	if blinkNext <= 0 and blinkT <= 0 then
		blinkT = 0.14
		blinkNext = 2.5 + math.random() * 3
		for _, e in ipairs(eyes) do e.Size = eyeClosed end
	end
	if blinkT > 0 then
		blinkT = blinkT - dt
		if blinkT <= 0 then
			for _, e in ipairs(eyes) do e.Size = eyeOpen end
		end
	end
end)

print("🧙‍♀️ Vendedora mágica lista")
-- FIN VENDEDORA
