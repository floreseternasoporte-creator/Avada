-- Archivo BOSQUE: construye el mundo del Bosque Prohibido y el cartel del circulo (solo visual).
-- LOBBY WORLD BUILD
--===========================================================
-- La Parte 2 construye el modelo IslandLobby (isla + tabla); aqui se espera para montar el circulo
local LobbyModel
do
  local t0 = os.clock()
  repeat
    task.wait(0.25)
    LobbyModel = workspace:FindFirstChild("IslandLobby")
  until LobbyModel or (os.clock() - t0 > 30)
  if not LobbyModel then
    LobbyModel = Instance.new("Model")
    LobbyModel.Name = "IslandLobby"
    LobbyModel.Parent = workspace
  end
end

--===========================================================

-- BOSQUE PROHIBIDO: supervivencia de magos (estilo 99 Noches)
-- Te paras en el circulo del lobby con quien quieras (1, 2 o
-- todos) y arranca la partida: 7 noches en el bosque, la Llama
-- Magica no debe apagarse, hay que rescatar a los 4 aprendices
-- perdidos y las Sombras caen con tus hechizos (cuentan bajas).
--===========================================================
-- ESTILO CLÁSICO ROBLOX (igual que la tienda): todo Plastic con studs,
-- bien hecho cara por cara; las formas curvas quedan lisas.
local CLASSIC_STUDS = true
local function clasicoEn(modelo)
  if not CLASSIC_STUDS or not modelo then
    return
  end
  local ST = Enum.SurfaceType.Studs
  local SM = Enum.SurfaceType.Smooth
  local INL = Enum.SurfaceType.Inlet
  for _, p in ipairs(modelo:GetDescendants()) do
    if p:IsA("BasePart") and p.Transparency < 1 and not p:GetAttribute("SinClasico") then
      -- el suelo del bosque NO va clasico: hierba oscura con textura,
      -- como en 99 Noches (la referencia del dueno)
      if p.Name == "BosqueGrass" then
        p.Material = Enum.Material.Grass
      else
        p.Material = Enum.Material.Plastic
      end
      p.Reflectance = 0
      -- una Texture en una cara tapa los studs de esa cara: se apaga
      for _, t in ipairs(p:GetChildren()) do
        if t:IsA("Texture") then
          t.Transparency = 1
        end
      end
      local cn = p.ClassName
      local sx, sy, sz = p.Size.X, p.Size.Y, p.Size.Z
      if cn == "WedgePart" or cn == "CornerWedgePart" then
        p.TopSurface = ST
        p.FrontSurface = ST
        p.BackSurface = ST
        p.BottomSurface = INL
        p.LeftSurface, p.RightSurface = SM, SM
      elseif cn == "Part" and p.Shape == Enum.PartType.Cylinder then
        -- en un cilindro las caras redondas son Left/Right: ahi van los studs
        -- (la isla entera es un cilindro: ese es el suelo)
        p.LeftSurface = ST
        p.RightSurface = ST
        p.TopSurface, p.BottomSurface, p.FrontSurface, p.BackSurface = SM, SM, SM, SM
      elseif cn == "Part" and p.Shape == Enum.PartType.Block then
        p.TopSurface = (sx >= 0.9 and sz >= 0.9) and ST or SM
        p.BottomSurface = (sx >= 0.9 and sz >= 0.9) and INL or SM
        p.FrontSurface = (sx >= 0.9 and sy >= 0.9) and ST or SM
        p.BackSurface = p.FrontSurface
        p.LeftSurface = (sz >= 0.9 and sy >= 0.9) and ST or SM
        p.RightSurface = p.LeftSurface
      else
        -- esferas y mallas: lisas (en el Roblox clasico eran mallas, sin studs)
        p.TopSurface, p.BottomSurface = SM, SM
        p.LeftSurface, p.RightSurface, p.FrontSurface, p.BackSurface = SM, SM, SM, SM
      end
      if p.Name == "BosqueGrass" then
        p.TopSurface, p.BottomSurface = SM, SM
        p.LeftSurface, p.RightSurface, p.FrontSurface, p.BackSurface = SM, SM, SM, SM
      end
    end
  end
end

-- Cartel sobre el circulo del lobby
local circleAnchor = Instance.new("Part")
circleAnchor.Name = "CircleBoardAnchor"
circleAnchor.Size = Vector3.new(1, 1, 1)
circleAnchor.CFrame = CFrame.new(0, 15.5, 0)
circleAnchor.BrickColor = BrickColor.new("White")
circleAnchor.Material = Enum.Material.SmoothPlastic
circleAnchor.Anchored = true
circleAnchor.CanCollide = false
circleAnchor.CastShadow = false
circleAnchor.Parent = LobbyModel
circleAnchor.Transparency = 1

local circleGui = Instance.new("BillboardGui")
circleGui.Name = "CircleBoard"
circleGui.Size = UDim2.new(13, 0, 3.6, 0)
circleGui.StudsOffset = Vector3.new(0, 2, 0)
circleGui.AlwaysOnTop = true
circleGui.LightInfluence = 0
circleGui.MaxDistance = 140
circleGui.Parent = circleAnchor

local circleTitle = Instance.new("TextLabel")
circleTitle.Name = "Title"
circleTitle.Size = UDim2.new(1, 0, 0.42, 0)
circleTitle.BackgroundTransparency = 1
circleTitle.Font = Enum.Font.LuckiestGuy
circleTitle.TextScaled = true
circleTitle.TextColor3 = Color3.fromRGB(255, 214, 64)
circleTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
circleTitle.TextStrokeTransparency = 0
circleTitle.Text = "BOSQUE PROHIBIDO"
circleTitle.Parent = circleGui

local circleStatus = Instance.new("TextLabel")
circleStatus.Name = "Status"
circleStatus.Size = UDim2.new(1, 0, 0.36, 0)
circleStatus.Position = UDim2.new(0, 0, 0.42, 0)
circleStatus.BackgroundTransparency = 1
circleStatus.Font = Enum.Font.GothamBold
circleStatus.TextScaled = true
circleStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
circleStatus.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
circleStatus.TextStrokeTransparency = 0.25
circleStatus.Text = "Párate en el círculo para entrar"
circleStatus.Parent = circleGui

local circleSub = Instance.new("TextLabel")
circleSub.Name = "Sub"
circleSub.Size = UDim2.new(1, 0, 0.22, 0)
circleSub.Position = UDim2.new(0, 0, 0.78, 0)
circleSub.BackgroundTransparency = 1
circleSub.Font = Enum.Font.Gotham
circleSub.TextScaled = true
circleSub.TextColor3 = Color3.fromRGB(170, 230, 255)
circleSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
circleSub.TextStrokeTransparency = 0.4
circleSub.Text = "Sobrevive 7 noches · Rescata a los 4 aprendices"
circleSub.Parent = circleGui

--===========================================================

local FC = Vector3.new(0, 0, 4200) -- centro del bosque (lejos del lobby)

-- MUNDO: EL BOSQUE (todo con moldeados clasicos, como la tienda)
--===========================================================
local Bosque = Instance.new("Model")
Bosque.Name = "BosqueProhibido"
Bosque.Parent = workspace

local function bp(name, size, cf, col, collide)
  local part = Instance.new("Part")
  part.Name = name
  part.Size = size
  part.CFrame = cf
  part.BrickColor = BrickColor.new("White")
  part.Color = col
  part.Material = Enum.Material.SmoothPlastic
  part.Anchored = true
  part.CanCollide = collide ~= false
  part.CastShadow = false
  part.Parent = Bosque
  return part
end
local function bcyl(name, h, d, cf, col, collide)
  local part = bp(name, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), col, collide)
  part.Shape = Enum.PartType.Cylinder
  return part
end
local function bwedge(name, size, cf, col)
  local part = Instance.new("WedgePart")
  part.Name = name
  part.Size = size
  part.CFrame = cf
  part.BrickColor = BrickColor.new("White")
  part.Color = col
  part.Material = Enum.Material.SmoothPlastic
  part.Anchored = true
  part.CanCollide = false
  part.CastShadow = false
  part.Parent = Bosque
  return part
end
local function bball(name, d, cf, col, collide)
  local part = bp(name, Vector3.new(d, d, d), cf, col, collide)
  part.Shape = Enum.PartType.Ball
  return part
end

-- Suelo por capas (igual que la isla: cesped, tierra, piedra, punta)
bcyl("BosqueGrass", 2.0, 470, CFrame.new(FC.X, 1.0, FC.Z), Color3.fromRGB(56, 120, 42), true)
bcyl("BosqueDirt", 2.2, 458, CFrame.new(FC.X, -0.6, FC.Z), Color3.fromRGB(112, 76, 45), false)
bcyl("BosqueStone", 2.4, 440, CFrame.new(FC.X, -2.4, FC.Z), Color3.fromRGB(74, 74, 86), false)
bcyl("BosqueTip", 5.0, 240, CFrame.new(FC.X, -6.0, FC.Z), Color3.fromRGB(62, 62, 74), false)
bcyl("BosqueTip2", 4.0, 130, CFrame.new(FC.X, -9.5, FC.Z), Color3.fromRGB(54, 54, 66), false)

-- Borde de piedras del bosque
for i = 0, 71 do
  local a = (i / 72) * math.pi * 2
  local rim = bp(
    "BosqueRim",
    Vector3.new(9, 1.1, 1.6),
    CFrame.new(FC.X + math.cos(a) * 229, 2.35, FC.Z + math.sin(a) * 229) * CFrame.Angles(0, -a - math.pi / 2, 0),
    (i % 2 == 0) and Color3.fromRGB(66, 66, 78) or Color3.fromRGB(76, 76, 90),
    true
  )
end

-- LA FOGATA MAGICA (el campamento): la fogata NUEVA del dueno del
-- juego, su codigo tal cual, solo cambia POSITION (al centro FC).
-- El anillo seguro, el deposito de lenos y el cartel quedan abajo.
do
--[[
	🔥 FOGATA MÁGICA - Constructor + animación para Roblox
	-------------------------------------------------------
	CÓMO USARLO:
	1. En Roblox Studio abre ServerScriptService
	2. Inserta un "Script" (NO LocalScript) y pega todo este código
	3. Dale a Play: la fogata aparece en POSITION (por defecto a unos pasos de la tienda)

	QUÉ INCLUYE:
	- Anillo de 14 piedras oscuras con tapa café y astillas
	- Troncos: base en estrella, travesaños y troncos inclinados tipo tipi
	- Brasas brillantes entre los troncos
	- Llama de bloques: 15 lenguas (violeta/azul por fuera, naranja y rosado por dentro)
	  que se mecen, crecen y se encogen, y cambian un poco de color
	- Chispas cuadradas moradas y naranjas que suben y se apagan
	- Luz naranja + luz morada que parpadean
	- 5 grupos de cristales morados y azules alrededor del anillo
	- Se pausa sola cuando no hay jugadores cerca (ACTIVE_DIST)

	APAGAR / ENCENDER desde otro script:
	    workspace.FogataMagica:SetAttribute("Lit", false)  -- apagar
	    workspace.FogataMagica:SetAttribute("Lit", true)   -- encender

	Todo son Parts, sin assets externos. La llama es Neon (no muestra studs porque Neon
	no los dibuja); el resto (piedras, troncos, cristales, ceniza) sí lleva studs.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// ============ CONFIGURACIÓN ============
local POSITION = Vector3.new(FC.X, 2, FC.Z) -- centro del Bosque Prohibido (el 0,0,-12 del codigo original, aqui)
local ROTATION_Y = 0 -- grados
local CLASSIC_STUDS = true -- true = piedras, troncos y cristales en Plastic con studs (estilo clásico)
local STUDS_ON_SIDES = true -- true = studs en las 6 caras; false = solo arriba y abajo
local RING_RADIUS = 9 -- radio del anillo de piedras
local STONE_COUNT = 14
local FLAME_FPS = 24 -- cuántas veces por segundo se anima la llama
local ACTIVE_DIST = 160 -- si ningún jugador está a menos de esta distancia, la llama se pausa
local MAX_EMBERS = 14 -- chispas cuadradas

--// ============ BASE ============
local ORIGIN = CFrame.new(POSITION) * CFrame.Angles(0, math.rad(ROTATION_Y), 0)
local rng = Random.new(7)
local M = Enum.Material
local SU = Enum.SurfaceType
local TAU = math.pi * 2

local old = workspace:FindFirstChild("FogataMagica")
if old then old:Destroy() end
local model = Instance.new("Model")
model.Name = "FogataMagica"

local function rnd(a, b)
	return rng:NextNumber(a, b)
end

-- gira el sistema para que el eje +X apunte hacia afuera en el ángulo a
local function radial(a)
	return CFrame.Angles(0, -a, 0)
end

local function newPart(name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = SU.Smooth
	p.BottomSurface = SU.Smooth
	p.Parent = model
	return p
end

-- pieza sólida: en modo clásico es Plastic con studs; si no, usa su material natural
local function solid(name, size, cf, color, natural)
	local p = newPart(name, size, ORIGIN * cf, color, CLASSIC_STUDS and M.Plastic or natural)
	if CLASSIC_STUDS then
		p.TopSurface = SU.Studs
		p.BottomSurface = SU.Inlet
		if STUDS_ON_SIDES then
			p.LeftSurface = SU.Studs
			p.RightSurface = SU.Studs
			p.FrontSurface = SU.Studs
			p.BackSurface = SU.Studs
		end
	end
	return p
end

-- pieza luminosa (llama, brasas, chispas): siempre Neon, sin colisión
local function glowPart(name, size, cf, color, transparency)
	local p = newPart(name, size, ORIGIN * cf, color, M.Neon)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = transparency or 0
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

local root = newPart("Root", Vector3.new(1, 0.2, 1), ORIGIN * CFrame.new(0, 0.1, 0), Color3.new(0, 0, 0), M.SmoothPlastic)
root.Transparency = 1
root.CanCollide = false
root.CanTouch = false
root.CanQuery = false
model.PrimaryPart = root

--// ============ CENIZA (suelo oscuro dentro del anillo) ============
solid("Ceniza", Vector3.new(9.4, 0.2, 9.4), CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(15), 0), Color3.fromRGB(46, 38, 42), M.Slate)

--// ============ ANILLO DE PIEDRAS ============
local STONE_SIDE = {
	Color3.fromRGB(60, 54, 62), Color3.fromRGB(74, 60, 62),
	Color3.fromRGB(54, 50, 60), Color3.fromRGB(82, 64, 62),
}
local STONE_TOP = {
	Color3.fromRGB(112, 86, 78), Color3.fromRGB(98, 78, 74), Color3.fromRGB(120, 92, 82),
}
for i = 1, STONE_COUNT do
	local a = (i - 1) / STONE_COUNT * TAU + rnd(-0.05, 0.05)
	local w = rnd(3.1, 4.2) -- ancho (tangente)
	local d = rnd(2.5, 3.1) -- fondo (radial)
	local h = rnd(1.9, 2.9) -- alto total
	local r = RING_RADIUS + rnd(-0.35, 0.35)
	local base = radial(a) * CFrame.new(r, 0, 0)
		* CFrame.Angles(rnd(-0.025, 0.025), rnd(-0.1, 0.1), rnd(-0.025, 0.025))
	local side = STONE_SIDE[rng:NextInteger(1, #STONE_SIDE)]
	local top = STONE_TOP[rng:NextInteger(1, #STONE_TOP)]
	local bh = h - 0.3
	solid("Stone", Vector3.new(d, bh, w), base * CFrame.new(0, bh / 2, 0), side, M.Slate)
	solid("StoneTop", Vector3.new(d * 0.9, 0.3, w * 0.94), base * CFrame.new(0, bh + 0.15, 0), top, M.Slate)
	if rng:NextNumber() < 0.55 then
		solid("StoneChip", Vector3.new(0.8, 0.5, 0.8),
			base * CFrame.new(rnd(-d * 0.25, d * 0.25), h + 0.25, rnd(-w * 0.3, w * 0.3)) * CFrame.Angles(0, rnd(0, TAU), 0),
			side:Lerp(top, 0.5), M.Slate)
	end
end

--// ============ TRONCOS ============
local LOG_BODY = { Color3.fromRGB(94, 58, 42), Color3.fromRGB(84, 52, 40), Color3.fromRGB(106, 66, 46) }
local LOG_END = Color3.fromRGB(150, 100, 66)

-- tronco con sección octagonal (dos bloques cruzados a 45°) y tapas claras en las puntas
local function log(cf, length, thick, body)
	solid("Log", Vector3.new(length, thick, thick), cf, body, M.Wood)
	solid("Log", Vector3.new(length, thick, thick), cf * CFrame.Angles(math.pi / 4, 0, 0), body, M.Wood)
	for _, s in ipairs({ -1, 1 }) do
		solid("LogEnd", Vector3.new(0.14, thick * 0.8, thick * 0.8), cf * CFrame.new(s * (length / 2 + 0.05), 0, 0) * CFrame.Angles(math.pi / 8, 0, 0), LOG_END, M.Wood)
	end
end

-- tronco inclinado hacia el centro (base en el suelo)
local function leanLog(a, baseR, tilt, length, thick, body)
	local B = Vector3.new(math.cos(a) * baseR, thick * 0.45 + 0.2, math.sin(a) * baseR)
	local inward = Vector3.new(-math.cos(a), 0, -math.sin(a))
	local dir = (inward * math.sin(tilt) + Vector3.new(0, math.cos(tilt), 0)).Unit
	local pos = B + dir * (length / 2)
	local zV = dir:Cross(Vector3.new(0, 1, 0)).Unit
	local yV = zV:Cross(dir)
	log(CFrame.fromMatrix(pos, dir, yV, zV), length, thick, body)
end

-- capa de abajo: 6 troncos en estrella
for k = 0, 5 do
	local a = k / 6 * TAU + rnd(-0.1, 0.1)
	log(radial(a) * CFrame.new(2.1, 0.7, 0) * CFrame.Angles(0, 0, rnd(-0.05, 0.05)), 4.8, 1.0, LOG_BODY[rng:NextInteger(1, 3)])
end
-- capa del medio: 3 troncos cruzados
for k = 0, 2 do
	local a = k / 3 * TAU + 0.5
	log(radial(a) * CFrame.new(1.4, 1.75, 0) * CFrame.Angles(0, math.pi / 2, rnd(-0.04, 0.04)), 4.0, 0.95, LOG_BODY[rng:NextInteger(1, 3)])
end
-- capa de arriba: 5 troncos inclinados (tipi)
for k = 0, 4 do
	local a = k / 5 * TAU + 0.3
	local big = (k % 2 == 0)
	leanLog(a, big and 2.9 or 2.6, big and 0.5 or 0.42, big and 6.0 or 5.4, big and 1.2 or 1.05, LOG_BODY[(k % 3) + 1])
end

--// ============ BRASAS EN EL SUELO ============
local coals = {}
for i = 1, 6 do
	local a = (i - 1) / 6 * TAU + rnd(-0.3, 0.3)
	local s = rnd(0.5, 0.8)
	local c = glowPart("Coal", Vector3.new(s, s * 0.8, s),
		radial(a) * CFrame.new(rnd(1.2, 2.5), rnd(0.5, 0.85), 0) * CFrame.Angles(rnd(0, TAU), rnd(0, TAU), rnd(0, TAU)),
		Color3.fromRGB(255, 140, 40), 0.1)
	coals[#coals + 1] = c
end

--// ============ CRISTALES ============
local CRYSTAL_COLORS = {
	purple = Color3.fromRGB(150, 70, 230),
	violet = Color3.fromRGB(110, 70, 225),
	blue = Color3.fromRGB(60, 85, 235),
}

local function crystal(cf, h, w, color)
	local rot = CFrame.Angles(0, math.rad(45), 0)
	local bodyH = h * 0.58
	solid("Crystal", Vector3.new(w, bodyH, w), cf * CFrame.new(0, bodyH / 2, 0) * rot, color, M.Glass)
	local tiers = 5
	local step = (h - bodyH) / tiers
	for i = 1, tiers do
		local f = 1 - i / (tiers + 0.7)
		solid("CrystalTip", Vector3.new(w * f, step + 0.02, w * f), cf * CFrame.new(0, bodyH + (i - 0.5) * step, 0) * rot, color, M.Glass)
	end
	-- núcleo brillante suave
	local core = glowPart("CrystalCore", Vector3.new(w * 0.3, h * 0.75, w * 0.3), cf * CFrame.new(0, h * 0.4, 0) * rot, color, 0.45)
	core.CanCollide = false
end

-- ángulo (grados), color, cantidad
local clusters = {
	{ 200, "purple", 3 }, { 158, "violet", 3 }, { 338, "violet", 2 }, { 18, "blue", 3 }, { 244, "purple", 2 },
}
for _, c in ipairs(clusters) do
	local a = math.rad(c[1])
	local color = CRYSTAL_COLORS[c[2]]
	local n = c[3]
	for j = 1, n do
		local oz = (j - (n + 1) / 2) * 0.9 + rnd(-0.2, 0.2)
		local ox = rnd(-0.3, 0.4)
		local cf = radial(a) * CFrame.new(RING_RADIUS + 1.7 + ox, 0, oz)
			* CFrame.Angles(rnd(-0.15, 0.15), 0, -rnd(0.25, 0.6))
			* CFrame.Angles(0, rnd(0, TAU), 0)
		crystal(cf, rnd(2.2, 4.4), rnd(0.7, 1.0), color)
	end
	local lp = glowPart("CrystalLight", Vector3.new(0.5, 0.5, 0.5), radial(a) * CFrame.new(RING_RADIUS + 1.7, 1.5, 0), color, 1)
	addLight(lp, color, 8, 0.4)
end

--// ============ LLAMA ============
local FLAME_BASE_Y = 0.9
local TIERS = 4
local KINDS = {
	outer = { cols = { Color3.fromRGB(88, 70, 235), Color3.fromRGB(150, 84, 226), Color3.fromRGB(220, 104, 190) }, transp = 0.12 },
	mid = { cols = { Color3.fromRGB(140, 82, 228), Color3.fromRGB(250, 128, 110), Color3.fromRGB(255, 160, 80) }, transp = 0.05 },
	core = { cols = { Color3.fromRGB(255, 206, 96), Color3.fromRGB(255, 150, 60), Color3.fromRGB(238, 112, 128) }, transp = 0 },
	base = { cols = { Color3.fromRGB(255, 196, 84), Color3.fromRGB(255, 142, 52), Color3.fromRGB(255, 110, 60) }, transp = 0 },
}
local HOT = Color3.fromRGB(255, 150, 70)

local function kindColor(kind, t)
	local c = KINDS[kind].cols
	if t < 0.5 then
		return c[1]:Lerp(c[2], t * 2)
	end
	return c[2]:Lerp(c[3], (t - 0.5) * 2)
end

local tongues = {}
local function addTongue(kind, a, r0, H, W, lean, speed)
	local tg = {
		kind = kind, a = a, r0 = r0, H = H, W = W, lean = lean, speed = speed,
		phase = rnd(0, TAU), parts = {}, transp = KINDS[kind].transp,
	}
	for i = 1, TIERS do
		tg.parts[i] = glowPart("Flame_" .. kind, Vector3.new(W, H / TIERS, W), CFrame.new(0, 1, 0), kindColor(kind, (i - 0.5) / TIERS), tg.transp)
	end
	tongues[#tongues + 1] = tg
end

for i = 1, 7 do
	addTongue("outer", (i - 1) / 7 * TAU + rnd(-0.2, 0.2), rnd(1.2, 1.7), rnd(3.4, 5.0), rnd(1.5, 1.9), 0.55, rnd(2.0, 3.2))
end
for i = 1, 4 do
	addTongue("mid", (i - 1) / 4 * TAU + 0.4, rnd(0.5, 0.9), rnd(5.0, 6.8), rnd(1.3, 1.6), 0.3, rnd(2.2, 3.4))
end
addTongue("core", 0, 0.0, 8.6, 1.7, 0.0, 2.4)
addTongue("core", 2.2, 0.35, 7.2, 1.5, 0.1, 2.8)
addTongue("base", 1.0, 0.7, 2.8, 1.3, 0.2, 3.6)
addTongue("base", 4.1, 0.9, 2.4, 1.2, 0.2, 4.0)

local function offsets(tg, tm, t)
	local ox = -tg.lean * t * t * tg.H * 0.45 + math.sin(tm * tg.speed + tg.phase + t * 2.2) * 0.16 * tg.H * t
	local oz = math.cos(tm * tg.speed * 0.8 + tg.phase * 1.3 + t * 2.0) * 0.13 * tg.H * t
	return ox, oz
end

local function updateTongue(tg, tm, doColor)
	local pulse = 1 + 0.16 * math.sin(tm * tg.speed * 1.7 + tg.phase) + 0.09 * math.sin(tm * tg.speed * 3.1 + tg.phase * 2)
	local H = tg.H * pulse
	local F = ORIGIN * radial(tg.a) * CFrame.new(tg.r0, FLAME_BASE_Y, 0)
	for i = 1, TIERS do
		local t0, t1 = (i - 1) / TIERS, i / TIERS
		local tmid = (t0 + t1) / 2
		local y0, y1 = H * t0, H * t1
		local ox0, oz0 = offsets(tg, tm, t0)
		local ox1, oz1 = offsets(tg, tm, t1)
		local w = tg.W * (1 - tmid) ^ 0.85 + 0.14
		local part = tg.parts[i]
		part.Size = Vector3.new(w, (y1 - y0) * 1.12, w)
		local tiltZ = -math.atan2(ox1 - ox0, y1 - y0)
		local tiltX = math.atan2(oz1 - oz0, y1 - y0)
		part.CFrame = F * CFrame.new((ox0 + ox1) / 2, (y0 + y1) / 2, (oz0 + oz1) / 2)
			* CFrame.Angles(tiltX, 0, tiltZ)
			* CFrame.Angles(0, (i % 2) * math.pi / 4 + tg.phase, 0)
		if doColor then
			local flick = 0.5 + 0.5 * math.sin(tm * tg.speed * 2.3 + tg.phase + i)
			part.Color = kindColor(tg.kind, (i - 0.5) / TIERS):Lerp(HOT, 0.12 * flick)
		end
	end
end

--// ============ LUCES Y PARTÍCULAS ============
local lightPart = glowPart("FireLight", Vector3.new(1, 1, 1), CFrame.new(0, 3.2, 0), Color3.fromRGB(255, 150, 70), 1)
local fireLight = addLight(lightPart, Color3.fromRGB(255, 150, 70), 28, 1.15)
local purpleLight = addLight(lightPart, Color3.fromRGB(150, 90, 255), 20, 0.5)

local motes = Instance.new("ParticleEmitter")
motes.Color = ColorSequence.new(Color3.fromRGB(255, 170, 80), Color3.fromRGB(170, 100, 255))
motes.LightEmission = 1
motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
motes.Lifetime = NumberRange.new(1.2, 2.4)
motes.Speed = NumberRange.new(2, 4)
motes.Rate = 6
motes.SpreadAngle = Vector2.new(25, 25)
motes.EmissionDirection = Enum.NormalId.Top
motes.Parent = lightPart

--// ============ CHISPAS CUADRADAS ============
local embers = {}
local EMBER_ORANGE = Color3.fromRGB(255, 150, 60)
local EMBER_PURPLE = Color3.fromRGB(176, 96, 255)

local function respawn(e, initial)
	local a = rnd(0, TAU)
	local r = rnd(0, 1.6)
	e.x, e.y, e.z = math.cos(a) * r, rnd(2.5, 5.5), math.sin(a) * r
	e.vx, e.vy, e.vz = rnd(-0.9, 0.9), rnd(2.4, 5.2), rnd(-0.9, 0.9)
	e.max = rnd(1.6, 3.4)
	e.life = initial and rnd(0.2, e.max) or e.max
	e.size = rnd(0.22, 0.5)
	e.rot = rnd(0, TAU)
	e.spin = rnd(-3, 3)
	e.part.Color = (rng:NextNumber() < 0.5) and EMBER_PURPLE or EMBER_ORANGE
end

for i = 1, MAX_EMBERS do
	local e = { part = glowPart("Ember", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 3, 0), EMBER_ORANGE, 0) }
	respawn(e, true)
	embers[i] = e
end

--// ============ BUCLE DE ANIMACIÓN ============
model:SetAttribute("Lit", true)
model.Parent = workspace

local function setLit(on)
	for _, tg in ipairs(tongues) do
		for _, p in ipairs(tg.parts) do
			p.Transparency = on and tg.transp or 1
		end
	end
	for _, c in ipairs(coals) do
		c.Transparency = on and 0.1 or 0.85
	end
	for _, e in ipairs(embers) do
		e.part.Transparency = 1
	end
	fireLight.Enabled = on
	purpleLight.Enabled = on
	motes.Enabled = on
end

local function anyPlayerNear()
	local center = ORIGIN.Position
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - center).Magnitude < ACTIVE_DIST then
			return true
		end
	end
	return false
end

local acc, tm, scanT, frame = 0, 0, 1, 0
local active = true
local wasLit = true
local interval = 1 / FLAME_FPS

RunService.Heartbeat:Connect(function(dt)
	if not model.Parent then
		return
	end
	local lit = model:GetAttribute("Lit") ~= false
	if lit ~= wasLit then
		wasLit = lit
		if lit then
			setLit(true)
		else
			setLit(false)
		end
	end
	if not lit then
		return
	end

	scanT = scanT + dt
	if scanT > 0.5 then
		scanT = 0
		active = anyPlayerNear()
	end
	if not active then
		acc = 0
		return
	end

	acc = acc + dt
	if acc < interval then
		return
	end
	local step = math.min(acc, 0.1)
	acc = 0
	tm = tm + step
	frame = frame + 1

	local doColor = (frame % 4 == 0)
	for _, tg in ipairs(tongues) do
		updateTongue(tg, tm, doColor)
	end

	-- luces que parpadean
	fireLight.Brightness = 1.15 + 0.25 * math.sin(tm * 9) + 0.15 * math.sin(tm * 17.3)
	purpleLight.Brightness = 0.5 + 0.15 * math.sin(tm * 6 + 1)

	-- brasas del suelo
	for i, c in ipairs(coals) do
		c.Transparency = 0.1 + 0.2 * (0.5 + 0.5 * math.sin(tm * 3 + i * 1.7))
	end

	-- chispas cuadradas
	for _, e in ipairs(embers) do
		e.life = e.life - step
		if e.life <= 0 then
			respawn(e, false)
		end
		local p = 1 - e.life / e.max
		e.x = e.x + e.vx * step + math.sin(tm * 3 + e.rot) * 0.4 * step
		e.y = e.y + e.vy * step
		e.z = e.z + e.vz * step
		e.rot = e.rot + e.spin * step
		local s = e.size * (1 - p * 0.6)
		e.part.Size = Vector3.new(s, s, s)
		e.part.CFrame = ORIGIN * CFrame.new(e.x, e.y, e.z) * CFrame.Angles(e.rot, e.rot * 0.7, 0)
		e.part.Transparency = (p < 0.65) and 0 or (p - 0.65) / 0.35
	end
end)

print("🔥 Fogata mágica encendida en " .. tostring(POSITION))

end

-- Pared gris que CIERRA el circulo del bosque (como el borde rocoso
-- de 99 Noches): nadie sale del mapa hasta que la fogata crezca.
for i = 1, 48 do
  local a = (i / 48) * math.pi * 2
  local px, pz = FC.X + math.cos(a) * 228, FC.Z + math.sin(a) * 228
  local pared = bp("ParedBorde", Vector3.new(30.5, 18, 2), CFrame.new(Vector3.new(px, 11, pz), Vector3.new(FC.X, 11, FC.Z)), Color3.fromRGB(112, 112, 118), true)
  pared.Material = Enum.Material.Slate
  pared:SetAttribute("Grupo", "Pared")
  pared:SetAttribute("Ang", a)
  pared:SetAttribute("Tapa", false)
  local tapaP = bp("ParedTapa", Vector3.new(31.5, 1.6, 3.4), CFrame.new(Vector3.new(px, 20.4, pz), Vector3.new(FC.X, 20.4, FC.Z)), Color3.fromRGB(88, 88, 94), true)
  tapaP.Material = Enum.Material.Slate
  tapaP:SetAttribute("Grupo", "Pared")
  tapaP:SetAttribute("Ang", a)
  tapaP:SetAttribute("Tapa", true)
end

-- Anillo del radio seguro (se ve en el suelo, marca hasta donde llegan las Sombras)
local fuegoPos = FC + Vector3.new(0, 2.0, 0)
local anilloSeguro = {}
for i = 0, 23 do
  local a = (i / 24) * math.pi * 2
  local seg = bp(
    "SafeRing",
    Vector3.new(3.4, 0.25, 0.8),
    CFrame.new(fuegoPos.X, fuegoPos.Y + 0.12, fuegoPos.Z) * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, 17),
    Color3.fromRGB(255, 190, 70),
    false
  )
  seg.Transparency = 0.35
  seg:SetAttribute("Grupo", "Anillo")
  seg:SetAttribute("Ang", a)
  table.insert(anilloSeguro, { part = seg, ang = a })
end
-- Zona de deposito de lenos (toca aqui con lenos en la mano)
local deposito = bp("FireDeposit", Vector3.new(4.5, 0.4, 4.5), CFrame.new(fuegoPos.X, fuegoPos.Y + 0.2, fuegoPos.Z + 8.5), Color3.fromRGB(140, 92, 50), false)
deposito:SetAttribute("Rol", "Deposito")

-- Cartel del campamento
local fireAnchor = bp("FireBoardAnchor", Vector3.new(1, 1, 1), CFrame.new(fuegoPos.X, fuegoPos.Y + 11, fuegoPos.Z), Color3.fromRGB(255, 255, 255), false)
fireAnchor.Transparency = 1
fireAnchor:SetAttribute("Rol", "FireAnchor")
local fireGui = Instance.new("BillboardGui")
fireGui.Name = "FireBoard"
fireGui.Size = UDim2.new(14, 0, 3.4, 0)
fireGui.AlwaysOnTop = true
fireGui.LightInfluence = 0
fireGui.MaxDistance = 200
fireGui.Parent = fireAnchor
local fireTitle = Instance.new("TextLabel")
fireTitle.Size = UDim2.new(1, 0, 0.45, 0)
fireTitle.BackgroundTransparency = 1
fireTitle.Font = Enum.Font.LuckiestGuy
fireTitle.TextScaled = true
fireTitle.TextColor3 = Color3.fromRGB(255, 190, 60)
fireTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
fireTitle.TextStrokeTransparency = 0
fireTitle.Text = "LA LLAMA MAGICA"
fireTitle.Parent = fireGui
local fireStatus = Instance.new("TextLabel")
fireStatus.Name = "FireStatus"
fireStatus.Size = UDim2.new(1, 0, 0.4, 0)
fireStatus.Position = UDim2.new(0, 0, 0.45, 0)
fireStatus.BackgroundTransparency = 1
fireStatus.Font = Enum.Font.GothamBold
fireStatus.TextScaled = true
fireStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
fireStatus.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
fireStatus.TextStrokeTransparency = 0.2
fireStatus.Text = "Llama 100% - Noche 0/7 - Aprendices 0/4"
fireStatus.Parent = fireGui

-- Arboles clasicos por todo el bosque (deterministas)
local rngBosque = Random.new(99)
local jaulasPos = {}
for ci, off in ipairs({ { 106, 106 }, { -106, 106 }, { -106, -106 }, { 106, -106 } }) do
  jaulasPos[ci] = FC + Vector3.new(off[1], 2.0, off[2])
end
local function lejosDeJaulas(x, z)
  for _, jp in ipairs(jaulasPos) do
    local dxj, dzj = x - jp.X, z - jp.Z
    if dxj * dxj + dzj * dzj < 16 * 16 then
      return false
    end
  end
  return true
end
-- Arboles del Bosque Prohibido: tronco en 3 tramos que se afina, 2 ramas
-- y copa de 4 capas giradas (silueta llena, estilo clasico de bloques)
local verdesCopa = {
  Color3.fromRGB(46, 116, 44),
  Color3.fromRGB(56, 134, 50),
  Color3.fromRGB(66, 152, 58),
  Color3.fromRGB(80, 170, 66),
}
-- Arboles de CRISTALES del dueno del juego (sustituyen a los arboles
-- anteriores): su constructor tal cual, envuelto en una funcion para
-- plantar varios por el bosque; solo cambian posicion, giro, semilla
-- y el padre (el modelo Bosque) de cada arbol.
local function crearArbolCristal(xArbol, zArbol, rotArbol, semillaArbol, numArbol)
--[[
	💎 ÁRBOL DE CRISTALES - Constructor para Roblox
	------------------------------------------------
	CÓMO USARLO:
	1. En Roblox Studio abre ServerScriptService
	2. Inserta un "Script" (NO LocalScript) y pega todo este código
	3. Dale a Play: el árbol aparece en POSITION (el frente mira hacia +Z)

	QUÉ INCLUYE (según la imagen):
	- Tronco oscuro que se afina hacia arriba, con una curva suave y base ensanchada
	- 3 ramas: una corta arriba a la izquierda, una principal a la izquierda y una larga a la derecha
	- Racimo grande de cristales en la punta del tronco
	- Racimos de cristales en la punta de cada rama
	- Dos tipos de cristal: "prisma" (alargado con punta) y "gema" (facetado y redondeado)
	- Colores cuarzo: blanco cálido, crema, gris y gris azulado

	"BIEN SOLDADO":
	- Cada rama nace dentro del tronco y cada cristal nace dentro de su rama (se solapan),
	  así no queda ninguna rendija ni pieza flotando.
	- Con WELD_ALL = true todas las piezas se sueldan a una pieza raíz invisible
	  (WeldConstraint), así el árbol se mueve y se mantiene como un solo bloque.

	Todo son Parts, sin assets externos.
]]

--// ============ CONFIGURACIÓN ============
local POSITION = Vector3.new(xArbol, 2, zArbol) -- el suelo del bosque esta en Y = 2
local ROTATION_Y = math.deg(rotArbol) -- grados
local CLASSIC_STUDS = true -- true = Plastic con studs (estilo clásico); false = madera y mármol lisos
local STUDS_ON_SIDES = true -- true = studs en las 6 caras; false = solo arriba y abajo
local WELD_ALL = true -- true = suelda todas las piezas a una raíz invisible

--// ============ BASE ============
local ORIGIN = CFrame.new(POSITION) * CFrame.Angles(0, math.rad(ROTATION_Y), 0)
local rng = Random.new(semillaArbol)
local M = Enum.Material
local SU = Enum.SurfaceType
local TAU = math.pi * 2
local UP = Vector3.new(0, 1, 0)

local model = Instance.new("Model")
model.Name = "ArbolCristal" .. numArbol

local function rnd(a, b)
	return rng:NextNumber(a, b)
end

local function newPart(name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = SU.Smooth
	p.BottomSurface = SU.Smooth
	p.Parent = model
	return p
end

-- pieza sólida: en modo clásico es Plastic con studs; si no, usa su material natural
local function solid(name, size, cf, color, natural)
	local p = newPart(name, size, ORIGIN * cf, color, CLASSIC_STUDS and M.Plastic or natural)
	if CLASSIC_STUDS then
		p.TopSurface = SU.Studs
		p.BottomSurface = SU.Inlet
		if STUDS_ON_SIDES then
			p.LeftSurface = SU.Studs
			p.RightSurface = SU.Studs
			p.FrontSurface = SU.Studs
			p.BackSurface = SU.Studs
		end
	end
	return p
end

-- CFrame cuyo eje local +Y apunta hacia yDir (para ramas y cristales inclinados)
local function frameAlong(pos, yDir)
	local xV = yDir:Cross(UP)
	if xV.Magnitude < 1e-3 then
		xV = Vector3.new(1, 0, 0)
	else
		xV = xV.Unit
	end
	local zV = xV:Cross(yDir).Unit
	return CFrame.fromMatrix(pos, xV, yDir, zV)
end

-- bloque con sección casi octagonal: un bloque + otro girado 45° y un poco más bajo
-- (más bajo para que sus caras de arriba no se pisen y no parpadeen los studs)
local function octBlock(name, cf, w, h, color, natural)
	solid(name, Vector3.new(w, h, w), cf, color, natural)
	solid(name, Vector3.new(w * 0.9, h - 0.1, w * 0.9), cf * CFrame.Angles(0, math.pi / 4, 0), color, natural)
end

local root = newPart("Root", Vector3.new(1, 0.2, 1), ORIGIN * CFrame.new(0, 0.1, 0), Color3.new(0, 0, 0), M.SmoothPlastic)
root.Transparency = 1
root.CanCollide = false
root.CanTouch = false
root.CanQuery = false
model.PrimaryPart = root

--// ============ COLORES ============
local TRUNK_A = Color3.fromRGB(84, 62, 50)
local TRUNK_B = Color3.fromRGB(94, 70, 56)
local BRANCH_C = Color3.fromRGB(88, 64, 50)

local WARM = Color3.fromRGB(230, 222, 204) -- blanco cálido
local CREAM = Color3.fromRGB(232, 220, 190) -- crema
local GREY = Color3.fromRGB(208, 206, 210) -- gris claro
local COOL = Color3.fromRGB(192, 194, 202) -- gris azulado
local PEARL = Color3.fromRGB(222, 220, 218) -- perla

--// ============ TRONCO ============
local TRUNK_H = 18
local TRUNK_SEGS = 10

-- línea central del tronco (curva suave, empieza en 0,0,0)
local function curve(t)
	return Vector3.new(
		0.5 * (math.sin(t * 2.6 + 0.3) - math.sin(0.3)),
		t * TRUNK_H,
		0.25 * (math.sin(t * 1.9 + 1.0) - math.sin(1.0))
	)
end

-- ancho del tronco: 2.2 abajo, 1.35 arriba
local function trunkW(t)
	return 2.2 - 0.85 * t ^ 0.9
end

-- base ensanchada
octBlock("TrunkBase", CFrame.new(0, 0.35, 0), 2.5, 0.7, TRUNK_A, M.Wood)

for i = 1, TRUNK_SEGS do
	local t0, t1 = (i - 1) / TRUNK_SEGS, i / TRUNK_SEGS
	local p0, p1 = curve(t0), curve(t1)
	local mid = (p0 + p1) / 2
	local dy = p1.Y - p0.Y
	local tiltZ = -math.atan2(p1.X - p0.X, dy)
	local tiltX = math.atan2(p1.Z - p0.Z, dy)
	local w = trunkW((t0 + t1) / 2)
	-- 15% más largo que su tramo para que cada segmento se meta en el siguiente
	local segH = (p1 - p0).Magnitude * 1.15
	octBlock("Trunk", CFrame.new(mid) * CFrame.Angles(tiltX, 0, tiltZ), w, segH, (i % 2 == 0) and TRUNK_A or TRUNK_B, M.Wood)
end

--// ============ RAMAS ============
-- t = altura en el tronco (0 a 1), az = dirección horizontal (0 = +X, π = -X),
-- pitchDeg = inclinación hacia arriba, L = largo desde el centro del tronco
local function branch(t, az, pitchDeg, L, w0, w1, bendDeg, segs)
	local pos = curve(t) -- nace en el centro del tronco: queda metida dentro
	local segLen = L / segs
	local pitch = math.rad(pitchDeg)
	local bend = math.rad(bendDeg)
	local dir = Vector3.new(1, 0, 0)
	for i = 1, segs do
		local f = (i - 0.5) / segs
		local p = pitch + bend * f
		dir = Vector3.new(math.cos(az) * math.cos(p), math.sin(p), math.sin(az) * math.cos(p))
		local w = w0 + (w1 - w0) * f
		octBlock("Branch", frameAlong(pos + dir * (segLen / 2), dir), w, segLen * 1.15, BRANCH_C, M.Wood)
		pos = pos + dir * segLen
	end
	return pos, dir
end

local EB1, DB1 = branch(0.86, math.pi + 0.12, 16, 3.2, 0.62, 0.34, 6, 3) -- corta, arriba izquierda
local EB2, DB2 = branch(0.50, math.pi + 0.05, 26, 7.4, 1.0, 0.55, 6, 5) -- principal izquierda
local EB3, DB3 = branch(0.63, -0.05, 28, 8.4, 1.05, 0.55, 8, 5) -- larga derecha

--// ============ CRISTALES ============
-- cf: origen en la base del cristal, eje +Y hacia la punta.
-- kind "prism": alargado con base achaflanada, cuerpo octagonal y punta escalonada
-- kind "gem": gema facetada tipo bipirámide
local function shade(color, i)
	return color:Lerp(Color3.new(1, 1, 1), (i % 2) * 0.07)
end

local function crystal(cf, h, w, color, kind, spin)
	local rot = CFrame.Angles(0, spin, 0)
	if kind == "gem" then
		local prof = { 0.42, 0.78, 1.0, 0.86, 0.55, 0.22 }
		local n = #prof
		local step = h / n
		for i = 1, n do
			local s = w * prof[i]
			solid("Gem", Vector3.new(s, step + 0.03, s),
				cf * CFrame.new(0, (i - 0.5) * step, 0) * rot * CFrame.Angles(0, (i % 2) * math.pi / 4, 0),
				shade(color, i), M.Marble)
		end
	else
		local baseH = 0.07 * h
		local bodyH = 0.5 * h
		solid("CrystalBase", Vector3.new(w * 0.78, baseH + 0.03, w * 0.78), cf * CFrame.new(0, baseH / 2, 0) * rot, shade(color, 1), M.Marble)
		-- cuerpo octagonal (dos bloques; el girado es un poco más bajo)
		local bodyCF = cf * CFrame.new(0, baseH + bodyH / 2, 0) * rot
		solid("Crystal", Vector3.new(w, bodyH + 0.03, w), bodyCF, color, M.Marble)
		solid("Crystal", Vector3.new(w * 0.9, bodyH - 0.07, w * 0.9), bodyCF * CFrame.Angles(0, math.pi / 4, 0), shade(color, 1), M.Marble)
		-- punta escalonada
		local tipStart = baseH + bodyH
		local tiers = 5
		local step = (h - tipStart) / tiers
		for i = 1, tiers do
			local s = w * (1 - i / (tiers + 0.8))
			solid("CrystalTip", Vector3.new(s, step + 0.03, s),
				cf * CFrame.new(0, tipStart + (i - 0.5) * step, 0) * rot * CFrame.Angles(0, (i % 2) * math.pi / 4, 0),
				shade(color, i), M.Marble)
		end
	end
end

-- coloca un cristal en el extremo E de una rama que apunta hacia d.
-- az/el = hacia dónde crece el cristal (el = 90 es vertical), s = cuánto se retrasa hacia el tronco,
-- lu/lv = desplazamiento lateral/vertical (siempre pequeño para que nazca dentro de la rama).
-- La base se mete 0.3 dentro de la rama para que quede soldado.
local function place(E, d, spec)
	local u = d:Cross(UP)
	if u.Magnitude < 1e-3 then
		u = Vector3.new(1, 0, 0)
	else
		u = u.Unit
	end
	local v = u:Cross(d)
	local base = E - d * (spec.s or 0) + u * (spec.lu or 0) + v * (spec.lv or 0)
	local el = math.rad(spec.el)
	local c = Vector3.new(math.cos(spec.az) * math.cos(el), math.sin(el), math.sin(spec.az) * math.cos(el))
	crystal(frameAlong(base - c * 0.3, c), spec.h, spec.w, spec.color, spec.kind, rnd(0, TAU))
end

local PI = math.pi

-- cima del tronco: dos cristales grandes, uno chico en medio, uno acostado a la izquierda y gemas abajo
local TOP = curve(1)
local topSpecs = {
	{ az = 0, el = 80, h = 7.2, w = 2.8, kind = "prism", color = WARM, lu = 0.15, lv = 0.1 },
	{ az = PI, el = 76, h = 6.4, w = 1.7, kind = "prism", color = PEARL, lu = -0.25 },
	{ az = PI + 0.5, el = 84, h = 3.6, w = 1.0, kind = "prism", color = CREAM, lv = 0.2 },
	{ az = PI, el = 22, h = 4.8, w = 1.9, kind = "prism", color = GREY, lu = -0.3, s = 0.4 },
	{ az = 0.5, el = -30, h = 3.0, w = 2.1, kind = "gem", color = GREY, lu = 0.3, s = 0.5 },
	{ az = 0, el = -8, h = 2.0, w = 1.2, kind = "gem", color = CREAM, lu = 0.3, s = 0.7 },
	{ az = PI / 2, el = -28, h = 2.4, w = 1.8, kind = "gem", color = GREY, lv = 0.3, s = 0.5 },
}
for _, sp in ipairs(topSpecs) do
	place(TOP, UP, sp)
end

-- rama corta (arriba izquierda)
place(EB1, DB1, { az = 0.2, el = 70, h = 2.6, w = 1.1, kind = "prism", color = CREAM, s = 0.5, lv = 0.1 })
place(EB1, DB1, { az = PI, el = -40, h = 1.5, w = 1.4, kind = "gem", color = GREY, s = 0.1, lv = -0.1 })

-- rama principal izquierda
place(EB2, DB2, { az = 0.3, el = 75, h = 3.4, w = 2.8, kind = "gem", color = GREY, s = 1.0 })
place(EB2, DB2, { az = PI, el = 62, h = 4.3, w = 1.2, kind = "prism", color = PEARL, s = 0.2, lu = -0.1 })
place(EB2, DB2, { az = PI, el = -12, h = 3.2, w = 0.95, kind = "prism", color = CREAM, s = 0.0, lv = -0.1 })
place(EB2, DB2, { az = PI / 2, el = -62, h = 3.2, w = 2.5, kind = "gem", color = COOL, s = 0.6, lv = -0.15 })
place(EB2, DB2, { az = 0.4, el = -50, h = 2.2, w = 1.5, kind = "gem", color = CREAM, s = 1.6 })
place(EB2, DB2, { az = PI, el = 14, h = 3.4, w = 1.5, kind = "prism", color = GREY, s = 0.0, lu = 0.2 })

-- rama larga derecha
place(EB3, DB3, { az = 0, el = 62, h = 5.2, w = 2.9, kind = "prism", color = WARM, s = 0.5 })
place(EB3, DB3, { az = PI, el = 68, h = 3.8, w = 2.6, kind = "gem", color = GREY, s = 1.4, lv = 0.1 })
place(EB3, DB3, { az = PI / 2, el = 80, h = 2.4, w = 1.4, kind = "gem", color = CREAM, s = 1.0 })
place(EB3, DB3, { az = 0, el = 18, h = 4.6, w = 1.8, kind = "prism", color = CREAM, s = 0.0 })
place(EB3, DB3, { az = PI / 2, el = -68, h = 3.6, w = 2.6, kind = "gem", color = GREY, s = 0.8 })

--// ============ SOLDAR TODO ============
model.Parent = Bosque

if WELD_ALL then
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
			p.Anchored = false
		end
	end
end



end
for i = 1, 26 do
	local a = rngBosque:NextNumber(0, math.pi * 2)
	local r = rngBosque:NextNumber(34, 212)
	local x, z = FC.X + math.cos(a) * r, FC.Z + math.sin(a) * r
	if lejosDeJaulas(x, z) then
		crearArbolCristal(x, z, rngBosque:NextNumber(0, math.pi * 2), 1100 + i * 17, i)
	end
end


-- Hongos comestibles: el Boletus del dueno del juego, en su version
-- corregida (derecho, pegado al piso, escala de jugador 0.3). Se integra
-- al bosque con semilla distinta por hongo y las piezas etiquetadas para
-- que PARTIDA los haga recogibles y comestibles.
local ALTURA_TALLO_H = 9
local RADIO_SOMBRERO_H = 7.6
local ALTURA_SOMBRERO_H = 4.6
local PERFIL_TALLO_H = {
  { 0.00, 1.90 }, { 0.03, 2.55 }, { 0.08, 3.05 },
  { 0.16, 2.80 }, { 0.40, 2.70 }, { 0.70, 2.55 }, { 1.00, 2.15 },
}
local COLOR_TALLO_ARRIBA = Color3.fromRGB(226, 202, 148)
local COLOR_TALLO_ABAJO = Color3.fromRGB(188, 150, 98)
local COLOR_SOMBRERO_TOPE = Color3.fromRGB(140, 82, 52)
local COLOR_SOMBRERO_BORDE = Color3.fromRGB(190, 135, 92)
local COLOR_MANCHA_H = Color3.fromRGB(222, 188, 148)
local COLOR_POROS_H = Color3.fromRGB(228, 208, 152)

local function leerPerfilH(perfil, t)
  for i = 1, #perfil - 1 do
    local p0, p1 = perfil[i], perfil[i + 1]
    if t <= p1[1] then
      local k = (t - p0[1]) / (p1[1] - p0[1])
      k = math.clamp(k, 0, 1)
      return p0[2] + (p1[2] - p0[2]) * (k * k * (3 - 2 * k))
    end
  end
  return perfil[#perfil][2]
end

-- Origen del hongo que se esta construyendo (posicion + giro)
local RAIZ_HONGO = CFrame.new()

local function discoHongo(padre, nombre, y, altura, radio, color, material, escala)
  local pt = Instance.new("Part")
  pt.Name = nombre
  pt.Shape = Enum.PartType.Cylinder
  pt.Size = Vector3.new(altura, radio * 2, radio * 2) * escala
  -- El giro de 90 grados solo pone el cilindro vertical; el giro del hongo va en RAIZ_HONGO
  pt.CFrame = RAIZ_HONGO * CFrame.new(0, y * escala, 0) * CFrame.Angles(0, 0, math.rad(90))
  pt.Color = color
  pt.Material = material
  pt.Anchored = true
  pt.CanCollide = true
  pt.TopSurface = Enum.SurfaceType.Smooth
  pt.BottomSurface = Enum.SurfaceType.Smooth
  pt.Parent = padre
  return pt
end

local function crearHongoDelBosque(posicion, escala, semilla, id)
  local azar = Random.new(semilla)
  local rotacion = math.rad(azar:NextNumber(0, 360))
  RAIZ_HONGO = CFrame.new(posicion) * CFrame.Angles(0, rotacion, 0) -- siempre derecho, pegado al piso
  local modelo = Instance.new("Model")
  modelo.Name = "Hongo" .. id
  local tallo = Instance.new("Folder")
  tallo.Name = "Tallo"
  tallo.Parent = modelo
  local sombrero = Instance.new("Folder")
  sombrero.Name = "Sombrero"
  sombrero.Parent = modelo
  -- el tallo, en segmentos suaves segun el perfil
  local n = 28
  local primeraParte
  for i = 1, n do
    local t0, t1 = (i - 1) / n, i / n
    local tm = (t0 + t1) / 2
    local radio = leerPerfilH(PERFIL_TALLO_H, tm)
    local alturaSeg = ALTURA_TALLO_H / n + 0.05 -- pequeno solape, sin huecos
    local color = COLOR_TALLO_ABAJO:Lerp(COLOR_TALLO_ARRIBA, math.clamp(tm * 1.4, 0, 1))
    local v = azar:NextNumber(-0.02, 0.02)
    color = Color3.new(
      math.clamp(color.R + v, 0, 1),
      math.clamp(color.G + v, 0, 1),
      math.clamp(color.B + v, 0, 1)
    )
    local parte = discoHongo(tallo, "TalloSeg" .. i, tm * ALTURA_TALLO_H, alturaSeg, radio, color, Enum.Material.Fabric, escala)
    primeraParte = primeraParte or parte
  end
  -- el sombrero: labio, poros y cupula de anillos
  local baseSombrero = ALTURA_TALLO_H * 0.88
  discoHongo(sombrero, "Labio", baseSombrero + 0.25, 0.5, RADIO_SOMBRERO_H, COLOR_SOMBRERO_BORDE, Enum.Material.Fabric, escala)
  discoHongo(sombrero, "Poros", baseSombrero + 0.05, 0.3, RADIO_SOMBRERO_H * 0.95, COLOR_POROS_H, Enum.Material.Sand, escala)
  discoHongo(sombrero, "PorosCentro", baseSombrero + 0.5, 0.4, RADIO_SOMBRERO_H * 0.45, COLOR_POROS_H:Lerp(COLOR_TALLO_ARRIBA, 0.5), Enum.Material.Sand, escala)
  local anillos = 18
  local anguloMax = math.rad(86)
  for i = 1, anillos do
    local a0 = (i - 1) / anillos * anguloMax
    local a1 = i / anillos * anguloMax
    local y0 = ALTURA_SOMBRERO_H * math.sin(a0)
    local y1 = ALTURA_SOMBRERO_H * math.sin(a1)
    local alturaAnillo = math.max(y1 - y0, 0.2) + 0.08
    local radio = RADIO_SOMBRERO_H * math.cos((a0 + a1) / 2) ^ 0.85
    local k = (i - 1) / (anillos - 1)
    local color = COLOR_SOMBRERO_BORDE:Lerp(COLOR_SOMBRERO_TOPE, k ^ 0.6)
    if i <= 4 and azar:NextNumber() < 0.4 then
      color = color:Lerp(COLOR_MANCHA_H, azar:NextNumber(0.3, 0.6))
    else
      local v = azar:NextNumber(-0.04, 0.04)
      color = Color3.new(
        math.clamp(color.R + v, 0, 1),
        math.clamp(color.G + v * 0.8, 0, 1),
        math.clamp(color.B + v * 0.6, 0, 1)
      )
    end
    discoHongo(sombrero, "Cupula" .. i, baseSombrero + 0.5 + (y0 + y1) / 2, alturaAnillo, radio, color, Enum.Material.Fabric, escala)
  end
  modelo.PrimaryPart = primeraParte
  -- etiquetas para PARTIDA: todas las piezas llevan HongoId y la base
  -- (PrimaryPart) lleva Tipo=Hongo, ahi se ancla el letrero "Recoger"
  for _, d in ipairs(modelo:GetDescendants()) do
    if d:IsA("BasePart") then
      d:SetAttribute("HongoId", id)
    end
  end
  if primeraParte then
    primeraParte:SetAttribute("Tipo", "Hongo")
  end
  modelo.Parent = Bosque
  return modelo
end
for hi = 1, 14 do
  local a = rngBosque:NextNumber(0, math.pi * 2)
  local r = rngBosque:NextNumber(36, 208)
  local x, z = FC.X + math.cos(a) * r, FC.Z + math.sin(a) * r
  if lejosDeJaulas(x, z) then
    crearHongoDelBosque(Vector3.new(x, 1.84, z), 0.17, 7665 + hi * 131, hi) -- pequeno, enterrado un poco
  end
end

-- Cabanas (decoracion)
local function cabana(cx, cz, yaw)
  local base = CFrame.new(cx, 2.0, cz) * CFrame.Angles(0, yaw, 0)
  bp("HutFloor", Vector3.new(12, 0.7, 10), base * CFrame.new(0, 0.35, 0), Color3.fromRGB(126, 88, 54), true)
  bp("HutWall", Vector3.new(12, 5, 0.7), base * CFrame.new(0, 3.1, -4.65), Color3.fromRGB(140, 96, 58), true)
  bp("HutWall", Vector3.new(0.7, 5, 10), base * CFrame.new(-5.65, 3.1, 0), Color3.fromRGB(140, 96, 58), true)
  bp("HutWall", Vector3.new(0.7, 5, 10), base * CFrame.new(5.65, 3.1, 0), Color3.fromRGB(140, 96, 58), true)
  bwedge("HutRoof", Vector3.new(13.5, 4.5, 11), base * CFrame.new(0, 7.6, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(94, 58, 42))
  local lamp = bp("HutLamp", Vector3.new(0.7, 0.7, 0.7), base * CFrame.new(0, 4.2, 3.5), Color3.fromRGB(255, 200, 90), false)
  local pl = Instance.new("PointLight")
  pl.Color = Color3.fromRGB(255, 190, 100)
  pl.Range = 12
  pl.Brightness = 1
  pl.Parent = lamp
end
cabana(FC.X - 40, FC.Z + 30, math.rad(30))
cabana(FC.X + 48, FC.Z - 36, math.rad(-120))

-- Cofres (tocar: lenos o comida, con espera)
local cofres = {}
for _, off in ipairs({ { -70, -20 }, { 30, 90 }, { 90, 40 } }) do
  local cp = FC + Vector3.new(off[1], 2.0, off[2])
  local chestBase = bp("ChestBase", Vector3.new(3.2, 1.8, 2.2), CFrame.new(cp.X, cp.Y + 0.9, cp.Z), Color3.fromRGB(120, 76, 40), true)
  bp("ChestLid", Vector3.new(3.4, 0.7, 2.4), CFrame.new(cp.X, cp.Y + 2.1, cp.Z), Color3.fromRGB(94, 58, 36), false)
  bp("ChestGlow", Vector3.new(2.6, 0.3, 0.3), CFrame.new(cp.X, cp.Y + 1.6, cp.Z + 1.12), Color3.fromRGB(255, 205, 70), false)
  chestBase:SetAttribute("Tipo", "Cofre")
  table.insert(cofres, { pos = cp, listo = 0, base = chestBase })
end

-- Nodos de lena (troncos caidos que se recogen tocandolos)
local lenaNodos = {}
for i = 1, 16 do
  local a = (i / 16) * math.pi * 2 + 0.3
  local r = 40 + (i % 4) * 45
  local np = Vector3.new(FC.X + math.cos(a) * r, 2.0, FC.Z + math.sin(a) * r)
  local log = bcyl("FallenLog", 5.2, 1.1, CFrame.new(np.X, np.Y + 0.6, np.Z) * CFrame.Angles(math.rad(90), a, 0), Color3.fromRGB(128, 84, 46), false)
  log:SetAttribute("Tipo", "Lena")
  table.insert(lenaNodos, { part = log, pos = np, listoEn = 0 })
end

-- Arbusto de MORAS del dueno: cupula de hojas puntiagudas en capas como
-- tejas, collar de hojas paradas y racimos de moras azules y moradas con
-- corona oscura y rabito. Sustituye por completo al arbusto de fresas.
-- Las moras llevan Tipo/Arbusto/MoraId: PARTIDA las hace comestibles.
local MB_RADIO = 4.6
local MB_ALTO = 3.4
local MB_BASE_Y = 0.9
local MB_OSCURO = Color3.fromRGB(36, 60, 35)
local MB_CLARO = Color3.fromRGB(94, 132, 82)
local MB_BRILLO = Color3.fromRGB(108, 148, 94)
local MB_NERVIO = Color3.fromRGB(120, 156, 100)
local MB_NUCLEO = Color3.fromRGB(30, 50, 30)
local MB_RAMA = Color3.fromRGB(66, 88, 46)
local MB_CORONA = Color3.fromRGB(22, 18, 38)
local MB_MORAS = {
  Color3.fromRGB(38, 44, 92),
  Color3.fromRGB(52, 60, 118),
  Color3.fromRGB(84, 58, 108),
  Color3.fromRGB(70, 48, 96),
}
local MB_RAIZ = CFrame.new()
local MB_ESC = 1

local function mbVariar(color, v)
  return Color3.new(
    math.clamp(color.R + v, 0, 1),
    math.clamp(color.G + v * 1.1, 0, 1),
    math.clamp(color.B + v * 0.8, 0, 1)
  )
end

local function mbParte(padre, nombre, forma, tamano, cf, color, material)
  local pt = Instance.new("Part")
  pt.Name = nombre
  pt.Shape = forma
  pt.Size = tamano * MB_ESC
  local pos = cf.Position
  pt.CFrame = MB_RAIZ * (CFrame.new(pos * MB_ESC) * (cf - pos))
  pt.Color = color
  pt.Material = material or Enum.Material.SmoothPlastic
  pt.Anchored = true
  pt.CanCollide = false
  pt.TopSurface = Enum.SurfaceType.Smooth
  pt.BottomSurface = Enum.SurfaceType.Smooth
  pt.Parent = padre
  pt:SetAttribute("SinClasico", true)
  return pt
end

local function mbTramo(padre, nombre, a, b, grosor, color)
  local largo = (b - a).Magnitude
  local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
  return mbParte(padre, nombre, Enum.PartType.Cylinder, Vector3.new(largo + 0.04, grosor * 2, grosor * 2), cf, color)
end

local function mbSuperficie(phi, theta)
  local sp, cp = math.sin(phi), math.cos(phi)
  local ct, st = math.cos(theta), math.sin(theta)
  local pos = Vector3.new(MB_RADIO * sp * ct, MB_BASE_Y + MB_ALTO * cp, MB_RADIO * sp * st)
  local normal = Vector3.new(sp * ct / MB_RADIO, cp / MB_ALTO, sp * st / MB_RADIO).Unit
  local tangente = Vector3.new(MB_RADIO * cp * ct, -MB_ALTO * sp, MB_RADIO * cp * st).Unit
  return pos, normal, tangente
end

local function mbHoja(padre, base, dir, arriba, largo, color, azar)
  local giroHoja = math.rad(azar:NextNumber(-18, 18))
  local cf = CFrame.lookAt(base, base + dir, arriba) * CFrame.Angles(0, 0, giroHoja)
  local ancho = largo * 0.55
  local grosor = 0.07
  local vertical = CFrame.Angles(0, 0, math.rad(90))
  mbParte(padre, "Hoja", Enum.PartType.Cylinder,
    Vector3.new(grosor, ancho, largo * 0.72),
    cf * CFrame.new(0, 0, -largo * 0.36) * vertical, color)
  mbParte(padre, "PuntaHoja", Enum.PartType.Cylinder,
    Vector3.new(grosor * 1.02, ancho * 0.45, largo * 0.5),
    cf * CFrame.new(0, 0, -largo * 0.74) * vertical, color)
  mbParte(padre, "Nervio", Enum.PartType.Block,
    Vector3.new(0.05, 0.03, largo * 0.92),
    cf * CFrame.new(0, grosor / 2 + 0.01, -largo * 0.48),
    color:Lerp(MB_NERVIO, 0.45))
end

local function mbColorHoja(alturaNorm, azar)
  local color = MB_OSCURO:Lerp(MB_CLARO, math.clamp(alturaNorm, 0, 1) ^ 0.8)
  if azar:NextNumber() < 0.15 then
    color = color:Lerp(MB_BRILLO, azar:NextNumber(0.3, 0.55))
  end
  return mbVariar(color, azar:NextNumber(-0.035, 0.035))
end

local function mbMora(padre, centro, normal, radio, color, base, arbId, moraId)
  local mora = mbParte(padre, "Mora", Enum.PartType.Ball,
    Vector3.new(radio * 2, radio * 1.9, radio * 2),
    CFrame.new(centro), color, Enum.Material.SmoothPlastic)
  mora:SetAttribute("Tipo", "Mora")
  mora:SetAttribute("Arbusto", arbId)
  mora:SetAttribute("MoraId", moraId)
  local posCorona = centro + normal * radio * 0.88
  local corona = mbParte(padre, "Corona", Enum.PartType.Cylinder,
    Vector3.new(0.07, radio * 0.75, radio * 0.75),
    CFrame.lookAt(posCorona, posCorona + normal) * CFrame.Angles(0, math.rad(90), 0),
    MB_CORONA)
  corona:SetAttribute("Tipo", "MoraCorona")
  corona:SetAttribute("Arbusto", arbId)
  corona:SetAttribute("MoraId", moraId)
  local rabito = mbTramo(padre, "Rabito", base, centro - normal * radio * 0.6, 0.05, MB_RAMA)
  rabito:SetAttribute("Tipo", "MoraRabito")
  rabito:SetAttribute("Arbusto", arbId)
  rabito:SetAttribute("MoraId", moraId)
end

local function crearArbustoMoras(posicion, escala, semilla, arbId)
  local azar = Random.new(semilla)
  MB_ESC = escala
  MB_RAIZ = CFrame.new(posicion) * CFrame.Angles(0, math.rad(azar:NextNumber(0, 360)), 0)
  local modelo = Instance.new("Model")
  modelo.Name = "ArbustoMoras" .. arbId
  local function carpeta(nombre)
    local f = Instance.new("Folder")
    f.Name = nombre
    f.Parent = modelo
    return f
  end
  local nucleo = carpeta("Nucleo")
  local ramas = carpeta("Ramas")
  local hojas = carpeta("Hojas")
  local frutos = carpeta("Moras")
  local primeraParte
  local discos = 9
  for i = 1, discos do
    local y = 0.15 + (i - 0.5) / discos * (MB_BASE_Y + MB_ALTO - 0.55)
    local k = math.clamp((y - MB_BASE_Y) / MB_ALTO, 0, 1)
    local radio = (y <= MB_BASE_Y) and MB_RADIO * 0.93 or MB_RADIO * math.sqrt(1 - k * k) * 0.93
    local parte = mbParte(nucleo, "Nucleo" .. i, Enum.PartType.Cylinder,
      Vector3.new((MB_BASE_Y + MB_ALTO - 0.55) / discos + 0.08, radio * 2, radio * 2),
      CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
      mbVariar(MB_NUCLEO, azar:NextNumber(-0.01, 0.01)))
    primeraParte = primeraParte or parte
  end
  for i = 1, 8 do
    local theta = i / 8 * math.pi * 2 + azar:NextNumber(-0.2, 0.2)
    local punto = mbSuperficie(math.rad(azar:NextNumber(40, 62)), theta) * 0.8
    mbTramo(ramas, "Rama" .. i, Vector3.new(0, 0.3, 0), punto, 0.11, MB_RAMA)
  end
  local capas = {
    { angulos = { 4, 20, 36, 52, 68, 82, 94 }, separacion = 1.8, inclinacion = { 8, 28 }, largo = { 2.0, 2.9 } },
    { angulos = { 12, 28, 44, 60, 76, 90 },    separacion = 2.2, inclinacion = { 20, 42 }, largo = { 1.8, 2.5 } },
  }
  for numCapa, capa in ipairs(capas) do
    for _, gradosPhi in ipairs(capa.angulos) do
      local circunferencia = 2 * math.pi * MB_RADIO * math.sin(math.rad(gradosPhi))
      local cantidad = math.max(3, math.round(circunferencia / capa.separacion))
      local desfase = azar:NextNumber(0, 1)
      for k = 1, cantidad do
        local theta = (k + desfase) / cantidad * math.pi * 2 + azar:NextNumber(-0.12, 0.12)
        local phi = math.rad(gradosPhi + azar:NextNumber(-4, 4))
        local pos, normal, tangente = mbSuperficie(phi, theta)
        local lado = normal:Cross(tangente)
        local yaw = (gradosPhi < 10) and azar:NextNumber(-math.pi, math.pi) or math.rad(azar:NextNumber(-55, 55))
        local dir = tangente * math.cos(yaw) + lado * math.sin(yaw)
        local inclinacion = math.rad(azar:NextNumber(capa.inclinacion[1], capa.inclinacion[2]))
        dir = (dir * math.cos(inclinacion) + normal * math.sin(inclinacion)).Unit
        local largo = azar:NextNumber(capa.largo[1], capa.largo[2])
        if gradosPhi < 10 then
          largo = largo * 0.85
        end
        local base = pos - normal * 0.1
        if base.Y + dir.Y * largo < 0.08 then
          dir = Vector3.new(dir.X, (0.08 - base.Y) / largo, dir.Z).Unit
        end
        local alturaNorm = (base.Y + 0.5 * dir.Y * largo) / (MB_BASE_Y + MB_ALTO)
        mbHoja(hojas, base, dir, normal, largo, mbColorHoja(alturaNorm - 0.1 * (numCapa - 1), azar), azar)
      end
    end
  end
  for i = 1, 16 do
    local theta = i / 16 * math.pi * 2 + azar:NextNumber(-0.1, 0.1)
    local radial = Vector3.new(math.cos(theta), 0, math.sin(theta))
    local base = radial * (MB_RADIO * azar:NextNumber(0.97, 1.05)) + Vector3.new(0, 0.05, 0)
    local dir = (radial * azar:NextNumber(0.25, 0.5) + Vector3.yAxis * 0.9).Unit
    local color = mbVariar(MB_OSCURO:Lerp(MB_CLARO, azar:NextNumber(0.1, 0.4)), azar:NextNumber(-0.03, 0.03))
    mbHoja(hojas, base, dir, radial, azar:NextNumber(1.9, 2.5), color, azar)
  end
  local moraId = 0
  for c = 1, 6 do
    local thetaCentro = c / 6 * math.pi * 2 + azar:NextNumber(-0.4, 0.4)
    local phiCentro = math.rad(azar:NextNumber(10, 55))
    local cuantas = azar:NextInteger(2, 3)
    for mm = 1, cuantas do
      moraId = moraId + 1
      local phi = phiCentro + math.rad(azar:NextNumber(-7, 7))
      local theta = thetaCentro + azar:NextNumber(-0.18, 0.18)
      local pos, normal = mbSuperficie(math.max(phi, math.rad(6)), theta)
      local radio = azar:NextNumber(0.38, 0.45)
      local centro = pos + normal * 0.95
      local color = mbVariar(MB_MORAS[azar:NextInteger(1, #MB_MORAS)], azar:NextNumber(-0.02, 0.02))
      mbMora(frutos, centro, normal, radio, color, pos - normal * 0.1, arbId, moraId)
    end
  end
  modelo.PrimaryPart = primeraParte
  modelo.Parent = Bosque
  return modelo
end
for i = 1, 10 do
  local a = (i / 10) * math.pi * 2 + 0.9
  local r = 55 + (i % 3) * 50
  local np = Vector3.new(FC.X + math.cos(a) * r, 2.0, FC.Z + math.sin(a) * r)
  if lejosDeJaulas(np.X, np.Z) then
    crearArbustoMoras(np, 0.5, 7672 + i * 37, i)
  end
end

-- Jaulas de aprendices
local ROPAS = { Color3.fromRGB(122, 62, 186), Color3.fromRGB(52, 102, 196), Color3.fromRGB(198, 70, 60), Color3.fromRGB(60, 168, 96) }
local jaulas = {}
local function figuraAprendiz(colorRopa)
  local fig = Instance.new("Model")
  fig.Name = "Aprendiz"
  local function fp(n, size, off, col)
    local pp = Instance.new("Part")
    pp.Name = n
    pp.Size = size
    pp.BrickColor = BrickColor.new("White")
    pp.Color = col
    pp.Material = Enum.Material.SmoothPlastic
    pp.Anchored = true
    pp.CanCollide = false
    pp.CastShadow = false
    pp.CFrame = CFrame.new(off)
    pp.Parent = fig
    return pp
  end
  fp("Piernas", Vector3.new(1.1, 1.1, 0.7), Vector3.new(0, 0.55, 0), Color3.fromRGB(50, 46, 60))
  fp("Tunica", Vector3.new(1.4, 1.7, 0.85), Vector3.new(0, 1.95, 0), colorRopa)
  fp("Cabeza", Vector3.new(1.0, 1.0, 1.0), Vector3.new(0, 3.3, 0), Color3.fromRGB(240, 200, 150))
  local somb = Instance.new("WedgePart")
  somb.Name = "Sombrero"
  somb.Size = Vector3.new(1.3, 1.0, 1.3)
  somb.BrickColor = BrickColor.new("White")
  somb.Color = Color3.fromRGB(70, 44, 92)
  somb.Material = Enum.Material.SmoothPlastic
  somb.Anchored = true
  somb.CanCollide = false
  somb.CastShadow = false
  somb.CFrame = CFrame.new(0, 4.05, 0)
  somb.Parent = fig
  fig.Parent = Bosque
  return fig
end
for ci = 1, 4 do
  local jp = jaulasPos[ci]
  bp("CageFloor", Vector3.new(13, 0.8, 13), CFrame.new(jp.X, jp.Y + 0.4, jp.Z), Color3.fromRGB(96, 92, 104), true)
  local barrotes = {}
  for b = 0, 7 do
    local bx = jp.X - 4.55 + b * 1.3
    local bar = bcyl("CageBar", 6.4, 0.42, CFrame.new(bx, jp.Y + 4.0, jp.Z - 4.55), Color3.fromRGB(52, 52, 62), false)
    bar:SetAttribute("Jaula", ci)
    table.insert(barrotes, bar)
    local bar2 = bcyl("CageBar", 6.4, 0.42, CFrame.new(jp.X + 4.55, jp.Y + 4.0, jp.Z - 4.55 + b * 1.3), Color3.fromRGB(52, 52, 62), false)
    bar2:SetAttribute("Jaula", ci)
    table.insert(barrotes, bar2)
  end
  bp("CageRoof", Vector3.new(11, 0.7, 11), CFrame.new(jp.X, jp.Y + 7.5, jp.Z), Color3.fromRGB(70, 66, 80), false)
  local fig = figuraAprendiz(ROPAS[ci])
  fig:SetAttribute("Jaula", ci)
  for _, pp in ipairs(fig:GetChildren()) do
    local offp = pp.CFrame.Position
    pp.CFrame = CFrame.new(jp.X + offp.X, jp.Y + 0.8 + offp.Y, jp.Z + offp.Z)
  end
  local jAnchor = bp("CageAnchor", Vector3.new(1, 1, 1), CFrame.new(jp.X, jp.Y + 10, jp.Z), Color3.fromRGB(255, 255, 255), false)
  jAnchor.Transparency = 1
  jAnchor:SetAttribute("Jaula", ci)
  local jGui = Instance.new("BillboardGui")
  jGui.Size = UDim2.new(9, 0, 1.6, 0)
  jGui.AlwaysOnTop = true
  jGui.LightInfluence = 0
  jGui.MaxDistance = 120
  jGui.Parent = jAnchor
  local jLbl = Instance.new("TextLabel")
  jLbl.Size = UDim2.new(1, 0, 1, 0)
  jLbl.BackgroundTransparency = 1
  jLbl.Font = Enum.Font.GothamBold
  jLbl.TextScaled = true
  jLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
  jLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  jLbl.TextStrokeTransparency = 0.2
  jLbl.Text = "Aprendiz atrapado: vence a sus guardianes"
  jLbl.Parent = jGui
  table.insert(jaulas, { pos = jp, fig = fig, barrotes = barrotes, label = jLbl, libre = false, rescatado = false })
end

-- Todo el bosque en estilo clasico (studs), de una pasada
clasicoEn(Bosque)
-- y el lobby tambien, por si el archivo ISLA muere antes de su pasada:
-- asi el estilo clasico nunca depende de un solo archivo
if LobbyModel then
  clasicoEn(LobbyModel)
end

--===========================================================

Bosque:SetAttribute("Listo", true)
print("[Avada] Bosque construido")

-- FIN BOSQUE
