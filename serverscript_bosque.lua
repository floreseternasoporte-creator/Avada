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
    if p:IsA("BasePart") and p.Transparency < 1 then
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

-- LA LLAMA MAGICA (el campamento)
local fuegoPos = FC + Vector3.new(0, 2.0, 0)
for i = 0, 11 do
  local a = (i / 12) * math.pi * 2
  bp(
    "FireStone",
    Vector3.new(1.8, 1.1, 1.2),
    CFrame.new(fuegoPos.X + math.cos(a) * 5.6, fuegoPos.Y + 0.4, fuegoPos.Z + math.sin(a) * 5.6)
      * CFrame.Angles(0, -a, 0),
    Color3.fromRGB(88, 84, 96),
    true
  )
end
local lenosFuego = {}
for i = 1, 5 do
  local a = (i / 5) * math.pi
  local lg = bcyl(
    "FireLog",
    4.6,
    0.85,
    CFrame.new(fuegoPos.X, fuegoPos.Y + 0.55, fuegoPos.Z) * CFrame.Angles(0, a, math.rad(90)),
    Color3.fromRGB(120, 78, 44),
    false
  )
  table.insert(lenosFuego, lg)
end
local llamaParts = {}
local llamaBase = { Vector3.new(2.6, 2.2, 2.6), Vector3.new(1.9, 2.0, 1.9), Vector3.new(1.2, 1.8, 1.2) }
local llamaCols = { Color3.fromRGB(255, 122, 26), Color3.fromRGB(255, 176, 32), Color3.fromRGB(255, 224, 92) }
for i = 1, 3 do
  local fp = bp(
    "MagicFlame",
    llamaBase[i],
    CFrame.new(fuegoPos.X, fuegoPos.Y + 0.9 + (i - 1) * 1.5, fuegoPos.Z),
    llamaCols[i],
    false
  )
  fp:SetAttribute("Grupo", "Llama")
  fp:SetAttribute("Idx", i)
  llamaParts[i] = fp
end
local llamaLight = Instance.new("PointLight")
llamaLight.Color = Color3.fromRGB(255, 160, 60)
llamaLight.Range = 30
llamaLight.Brightness = 2.2
llamaLight.Parent = llamaParts[1]
local fuegoFire = Instance.new("Fire")
fuegoFire.Heat = 6
fuegoFire.Size = 5
fuegoFire.Parent = llamaParts[1]
-- chispas vivas subiendo de la llama (se mueven solas, sin codigo)
local chispas = Instance.new("ParticleEmitter")
chispas.Name = "FireSparks"
chispas.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 214, 110)),
  ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 130, 40)),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 40, 16)),
})
chispas.LightEmission = 1
chispas.Rate = 16
chispas.Lifetime = NumberRange.new(0.9, 2.0)
chispas.Speed = NumberRange.new(2.6, 5.0)
chispas.SpreadAngle = Vector2.new(24, 24)
chispas.Acceleration = Vector3.new(0, 2.5, 0)
chispas.Size = NumberSequence.new({
  NumberSequenceKeypoint.new(0, 0.42),
  NumberSequenceKeypoint.new(0.7, 0.26),
  NumberSequenceKeypoint.new(1, 0.02),
})
chispas.Parent = llamaParts[1]
-- Anillo del radio seguro (se ve en el suelo, marca hasta donde llegan las Sombras)
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
local function arbolProhibido(x, z, i)
  local esc = rngBosque:NextNumber(0.85, 1.3)
  local marron = Color3.fromRGB(106, 70, 40)
  local marron2 = Color3.fromRGB(92, 58, 32)
  -- raiz y tronco en tramos (cada tramo mas fino y un poco ladeado)
  bcyl("TreeRoot", 0.9, 2.1 * esc, CFrame.new(x, 2.45, z), marron2, true)
  local px, pz = x, z
  local y = 2.0
  local diams = { 1.45, 1.12, 0.8 }
  for t = 1, 3 do
    local h = 2.7 * esc
    bcyl("TreeTrunk", h, diams[t] * esc, CFrame.new(px, y + h / 2, pz), (t % 2 == 0) and marron2 or marron, true)
    y += h - 0.25
    px += rngBosque:NextNumber(-0.28, 0.28)
    pz += rngBosque:NextNumber(-0.28, 0.28)
  end
  local copaY = y + 0.4
  -- 2 ramas inclinadas hacia lados opuestos
  for r = 1, 2 do
    local yaw = rngBosque:NextNumber(0, math.pi * 2)
    local by = 2.0 + (3.4 + r * 1.9) * esc
    local rama = bp(
      "TreeBranch",
      Vector3.new(0.5 * esc, 3.0 * esc, 0.5 * esc),
      CFrame.new(x + math.cos(yaw) * 0.9 * esc, by, z + math.sin(yaw) * 0.9 * esc)
        * CFrame.Angles(math.rad(52), yaw, 0),
      marron2,
      false
    )
    rama.Shape = Enum.PartType.Cylinder
  end
  -- copa en 4 capas cuadradas, cada una menor y girada: se ve frondosa
  local anchos = { 8.6, 7.0, 5.2, 3.4 }
  local cy = copaY
  for l = 1, 4 do
    local w = anchos[l] * esc
    local giro = rngBosque:NextNumber(-0.3, 0.3) + (l % 2) * 0.35
    bp(
      "TreeLeaf",
      Vector3.new(w, 1.7 * esc, w),
      CFrame.new(px + rngBosque:NextNumber(-0.4, 0.4), cy + 0.85 * esc, pz + rngBosque:NextNumber(-0.4, 0.4))
        * CFrame.Angles(0, giro, 0),
      verdesCopa[((i + l - 2) % 4) + 1],
      false
    )
    cy += 1.45 * esc
  end
  -- punta
  bp("TreeLeaf", Vector3.new(1.8 * esc, 1.5 * esc, 1.8 * esc), CFrame.new(px, cy + 0.7 * esc, pz), verdesCopa[4], false)
end
for i = 1, 130 do
  local a = rngBosque:NextNumber(0, math.pi * 2)
  local r = rngBosque:NextNumber(30, 214)
  local x, z = FC.X + math.cos(a) * r, FC.Z + math.sin(a) * r
  if lejosDeJaulas(x, z) then
    arbolProhibido(x, z, i)
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

-- Arbustos de bayas (tocar: comida)
local bayas = {}
for i = 1, 10 do
  local a = (i / 10) * math.pi * 2 + 0.9
  local r = 55 + (i % 3) * 50
  local np = Vector3.new(FC.X + math.cos(a) * r, 2.0, FC.Z + math.sin(a) * r)
  -- arbusto de fresas como el de referencia: copa redonda de hojas en dos
  -- verdes y fresas rojas colgando por el borde (tallo + fresa + coronita)
  bcyl("BerryStub", 0.9, 0.55, CFrame.new(np.X, np.Y + 0.45, np.Z), Color3.fromRGB(92, 58, 32), false)
  local hojas = {
    { 0, 2.5, 0, 3.1 },
    { 1.15, 2.15, 0.4, 2.3 },
    { -1.1, 2.2, -0.35, 2.35 },
    { 0.35, 2.2, 1.1, 2.25 },
    { -0.4, 2.15, -1.15, 2.2 },
    { 0.1, 3.25, -0.1, 2.3 },
  }
  for hi, h in ipairs(hojas) do
    local hoja = bball(
      "BerryLeaf",
      h[4],
      CFrame.new(np.X + h[1], np.Y + h[2], np.Z + h[3]),
      (hi % 2 == 0) and Color3.fromRGB(56, 142, 54) or Color3.fromRGB(44, 118, 46),
      false
    )
    hoja.Size = Vector3.new(h[4], h[4] * 0.78, h[4])
  end
  local frutos = {}
  for j = 1, 5 do
    local ang = j * 2.25 + i
    local fx, fz = np.X + math.cos(ang) * 1.55, np.Z + math.sin(ang) * 1.55
    local fy = np.Y + 1.62 + math.sin(j * 2.7) * 0.22
    local tallo = bp("BerryStem", Vector3.new(0.16, 0.85, 0.16), CFrame.new(fx, fy + 0.55, fz) * CFrame.Angles(math.rad(14), 0, math.rad(9)), Color3.fromRGB(38, 102, 40), false)
    tallo:SetAttribute("Tipo", "Tallo")
    tallo:SetAttribute("Arbusto", i)
    tallo:SetAttribute("Fresa", j)
    local fb = bp("Berry", Vector3.new(0.6, 0.74, 0.6), CFrame.new(fx, fy, fz), Color3.fromRGB(232, 42, 52), false)
    fb.Shape = Enum.PartType.Ball
    fb.Material = Enum.Material.SmoothPlastic
    fb:SetAttribute("Tipo", "Baya")
    fb:SetAttribute("Arbusto", i)
    fb:SetAttribute("Fresa", j)
    local tapa = bp("BerryCap", Vector3.new(0.44, 0.18, 0.44), CFrame.new(fx, fy + 0.38, fz), Color3.fromRGB(40, 120, 44), false)
    tapa.Shape = Enum.PartType.Ball
    tapa:SetAttribute("Tipo", "Tapa")
    tapa:SetAttribute("Arbusto", i)
    tapa:SetAttribute("Fresa", j)
    table.insert(frutos, fb)
  end
  table.insert(bayas, { frutos = frutos, listoEn = 0 })
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
