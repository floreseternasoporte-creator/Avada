--===========================================================
-- AVADA DUELING - SERVER PARTE 2 DE 2: LOBBY VISUAL (ISLA + TABLA)
-- Coloca en: ServerScriptService > Script (nombre sugerido: AvadaParte2)
-- SOLO construye el mundo visual: la isla flotante con el circulo magico,
-- el spawn y la tabla TOP SORCERERS con su monumento. Es INDEPENDIENTE:
-- no usa "shared" ni espera a ningun otro script (Studio Lite bloquea shared).
-- Si el pegado no llega hasta la ultima linea (-- FIN PARTE 2), se corto.
--===========================================================
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Datos propios minimos (copia de la Parte 1; solo posiciones de pads y el
-- DataStore de kills para la tabla). Si cambian alla, actualizar aqui.
local PAD_DATA = {
  { pos = Vector3.new(-21.2, 3.6, -21.2) },
  { pos = Vector3.new(21.2, 3.6, -21.2) },
  { pos = Vector3.new(-21.2, 3.6, 21.2) },
  { pos = Vector3.new(21.2, 3.6, 21.2) },
}
local KillsOrdered
do
  local okDS, resDS = pcall(function()
    return game:GetService("DataStoreService"):GetOrderedDataStore("DuelKillsRank_v11")
  end)
  KillsOrdered = (okDS and resDS)
    or {
      GetSortedAsync = function()
        return {
          GetCurrentPage = function()
            return {}
          end,
        }
      end,
    }
end

local function makePart(name, size, cf, color, material, parent, canCollide, anchored)
  local p = Instance.new("Part")
  p.Name = name
  p.Size = size
  p.CFrame = cf
  p.BrickColor = BrickColor.new(color)
  p.Material = material or Enum.Material.SmoothPlastic
  p.Anchored = (anchored ~= false)
  p.CanCollide = (canCollide ~= false)
  p.CastShadow = true
  for _, s in ipairs({ "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface" }) do
    p[s] = Enum.SurfaceType.Studs
  end
  p.Massless = true
  p.Parent = parent
  return p
end

local spawnLoc = workspace:FindFirstChild("LobbySpawn")
if not spawnLoc then
  spawnLoc = Instance.new("SpawnLocation")
  spawnLoc.Name = "LobbySpawn"
  spawnLoc.Size = Vector3.new(6, 1, 6)
  spawnLoc.CFrame = CFrame.new(0, 3, 0)
  spawnLoc.Transparency = 1
  spawnLoc.CanCollide = true
  spawnLoc.Anchored = true
  spawnLoc.Neutral = true
  spawnLoc.Parent = workspace
end

local LobbyModel = workspace:FindFirstChild("IslandLobby")
if LobbyModel then
  LobbyModel:Destroy()
end
LobbyModel = Instance.new("Model")
LobbyModel.Name = "IslandLobby"
LobbyModel.Parent = workspace

local LW, LD, LH = 112, 94, 40 -- compatibilidad: el leaderboard usa LD

-- Iluminación diurna tipo diorama (y fuera el tinte dorado sobre la tabla)
local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 13.2
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(150, 150, 168)
Lighting.OutdoorAmbient = Color3.fromRGB(170, 175, 190)
-- (El mundo base de Studio queda intacto: el usuario lo quita a mano si quiere)

local function islCyl(name, h, d, cf, col, collide)
  local part = Instance.new("Part")
  part.Name = name
  part.Shape = Enum.PartType.Cylinder
  part.Size = Vector3.new(h, d, d)
  part.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
  part.BrickColor = BrickColor.new("White")
  part.Color = col
  part.Material = Enum.Material.SmoothPlastic
  part.Anchored = true
  part.CanCollide = (collide ~= false)
  part.CastShadow = false
  part.Parent = LobbyModel
  return part
end

-- Isla flotante por capas, como el corte de la imagen: césped, tierra y piedra
islCyl("IslandGrass", 1.2, 112, CFrame.new(0, 1.4, 0), Color3.fromRGB(84, 158, 66), true)
islCyl("IslandDirt", 2.0, 109, CFrame.new(0, 0.05, 0), Color3.fromRGB(112, 76, 45), false)
islCyl("IslandStone", 2.0, 103, CFrame.new(0, -1.7, 0), Color3.fromRGB(74, 74, 86), false)
islCyl("IslandTip", 3.0, 60, CFrame.new(0, -4.0, 0), Color3.fromRGB(62, 62, 74), false)
islCyl("IslandTip2", 2.6, 32, CFrame.new(0, -6.4, 0), Color3.fromRGB(54, 54, 66), false)

-- Borde de piedras alrededor de la isla
for i = 0, 51 do
  local a = (i / 52) * math.pi * 2
  local rim = makePart(
    "IslandRim",
    Vector3.new(6.6, 0.8, 1.3),
    CFrame.new(math.cos(a) * 54.8, 2.15, math.sin(a) * 54.8) * CFrame.Angles(0, -a - math.pi / 2, 0),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    LobbyModel,
    true,
    true
  )
  rim.Color = (i % 2 == 0) and Color3.fromRGB(66, 66, 78) or Color3.fromRGB(76, 76, 90)
end

-- 4 caminos de losas en X hacia el centro (los pads amarillos van encima)
for _, pd in ipairs({ { 1, -1 }, { -1, -1 }, { -1, 1 }, { 1, 1 } }) do
  local dx, dz = pd[1] * 0.7071, pd[2] * 0.7071
  local yaw = -math.atan2(dz, dx)
  local px, pz = -dz, dx
  for r = 14.5, 50, 3.35 do
    local cx, cz = dx * r, dz * r
    local slab = makePart(
      "PathSlab",
      Vector3.new(3.15, 0.35, 6.9),
      CFrame.new(cx, 2.16, cz) * CFrame.Angles(0, yaw, 0),
      "Medium stone grey",
      Enum.Material.SmoothPlastic,
      LobbyModel,
      true,
      true
    )
    slab.Color = ((r * 10) % 2 < 1) and Color3.fromRGB(126, 126, 138) or Color3.fromRGB(110, 110, 124)
    for _, sd2 in ipairs({ -1, 1 }) do
      local curb = makePart(
        "PathCurb",
        Vector3.new(3.15, 0.52, 0.55),
        CFrame.new(cx + px * 3.45 * sd2, 2.24, cz + pz * 3.45 * sd2) * CFrame.Angles(0, yaw, 0),
        "Dark stone grey",
        Enum.Material.SmoothPlastic,
        LobbyModel,
        true,
        true
      )
      curb.Color = Color3.fromRGB(82, 82, 96)
    end
  end
end

-- Círculo mágico central: anillos neón cian->magenta que giran, estrella y runas
local spinParts = {}
local function spinAdd(part, radius, y, baseAng, dir)
  table.insert(spinParts, { part = part, r = radius, y = y, a = baseAng, dir = dir })
end
islCyl("MagicRim", 0.6, 29.2, CFrame.new(0, 2.2, 0), Color3.fromRGB(52, 50, 66), false)
islCyl("MagicDisc", 0.5, 27.6, CFrame.new(0, 2.28, 0), Color3.fromRGB(22, 20, 34), true)
islCyl("MagicCore", 0.56, 7.8, CFrame.new(0, 2.3, 0), Color3.fromRGB(15, 13, 25), false)
local function neonRing(radius, y, segCount, segLen, thick, dir)
  for i = 0, segCount - 1 do
    local a = (i / segCount) * math.pi * 2
    local col = Color3.fromRGB(80, 220, 255):Lerp(Color3.fromRGB(255, 90, 220), i / segCount)
    local seg = makePart(
      "MagicRingSeg",
      Vector3.new(segLen, 0.32, thick),
      CFrame.new(math.cos(a) * radius, y, math.sin(a) * radius) * CFrame.Angles(0, -a - math.pi / 2, 0),
      "White",
      Enum.Material.Neon,
      LobbyModel,
      false,
      true
    )
    seg.Color = col
    spinAdd(seg, radius, y, a, dir)
  end
end
neonRing(11.8, 2.62, 28, 2.6, 1.05, 1)
neonRing(8.4, 2.62, 22, 2.35, 0.75, -1)
for _, rot in ipairs({ 0, math.pi / 3 }) do
  for k = 0, 2 do
    local a1 = rot + k * (math.pi * 2 / 3)
    local a2 = rot + (k + 1) * (math.pi * 2 / 3)
    local x1, z1 = math.cos(a1) * 6.9, math.sin(a1) * 6.9
    local x2, z2 = math.cos(a2) * 6.9, math.sin(a2) * 6.9
    local dx, dz = x2 - x1, z2 - z1
    local bar = makePart(
      "MagicStar",
      Vector3.new(math.sqrt(dx * dx + dz * dz), 0.3, 0.55),
      CFrame.new((x1 + x2) / 2, 2.62, (z1 + z2) / 2) * CFrame.Angles(0, -math.atan2(dz, dx), 0),
      "White",
      Enum.Material.Neon,
      LobbyModel,
      false,
      true
    )
    bar.Color = Color3.fromRGB(170, 240, 255)
  end
end
for i = 0, 7 do
  local a = i * (math.pi / 4) + math.pi / 8
  local rc = (i % 2 == 0) and Color3.fromRGB(110, 220, 255) or Color3.fromRGB(255, 120, 220)
  for b = 0, 2 do
    local off = (b - 1) * 0.45
    local rb = makePart(
      "MagicRune",
      Vector3.new(0.8, 0.34, 0.2),
      CFrame.new(math.cos(a) * 10.0 - math.sin(a) * off, 2.62, math.sin(a) * 10.0 + math.cos(a) * off)
        * CFrame.Angles(0, -a, 0),
      "White",
      Enum.Material.Neon,
      LobbyModel,
      false,
      true
    )
    rb.Color = rc
  end
end
local glowPart = makePart(
  "MagicGlow",
  Vector3.new(1, 1, 1),
  CFrame.new(0, 4.4, 0),
  "White",
  Enum.Material.Neon,
  LobbyModel,
  false,
  true
)
glowPart.Transparency = 1
local gl = Instance.new("PointLight")
gl.Brightness = 2.2
gl.Range = 22
gl.Color = Color3.fromRGB(150, 130, 255)
gl.Parent = glowPart
local em = Instance.new("ParticleEmitter")
em.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 230, 255)),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 230)),
})
em.LightEmission = 1
em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
em.Speed = NumberRange.new(1.5, 3.5)
em.Lifetime = NumberRange.new(1.2, 2.4)
em.Rate = 26
em.SpreadAngle = Vector2.new(55, 55)
em.Parent = glowPart
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt)
  spinAngle += dt * 0.35
  for _, sp in ipairs(spinParts) do
    local a = sp.a + spinAngle * sp.dir
    sp.part.CFrame = CFrame.new(math.cos(a) * sp.r, sp.y, math.sin(a) * sp.r) * CFrame.Angles(0, -a - math.pi / 2, 0)
  end
end)

-- Arbustos cúbicos de seto, plantas, rocas, cristales y losas con runas (como la imagen)
local function islWedge(name, size, cf, col, neon)
  local part = Instance.new("WedgePart")
  part.Name = name
  part.Size = size
  part.CFrame = cf
  part.BrickColor = BrickColor.new("White")
  part.Color = col
  part.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
  part.Anchored = true
  part.CanCollide = false
  part.CastShadow = false
  part.Parent = LobbyModel
  return part
end
local function islCrys(size, cf, col)
  local part = makePart("IslandCrystal", Vector3.new(1, 1, 1), cf, "White", Enum.Material.Neon, LobbyModel, false, true)
  part.Color = col
  local mesh = Instance.new("SpecialMesh")
  mesh.MeshType = Enum.MeshType.Pyramid
  mesh.Scale = size
  mesh.Parent = part
  return part
end
local function islBall(name, size, cf, col)
  local part = makePart(name, size, cf, "White", Enum.Material.SmoothPlastic, LobbyModel, true, true)
  part.Shape = Enum.PartType.Ball
  part.Color = col
  return part
end
local treeGreens = { Color3.fromRGB(34, 110, 44), Color3.fromRGB(52, 138, 58), Color3.fromRGB(74, 168, 74) }
local function islTree(x, z, s, tone)
  local tilt = math.sin(x * 1.7 + z) * 4
  -- Tronco en dos tramos con una leve inclinación, sobre una base de tierra
  local trunk = makePart(
    "TreeTrunk",
    Vector3.new(1.05 * s, 2.3 * s, 1.05 * s),
    CFrame.new(x, 2 + 1.15 * s, z) * CFrame.Angles(0, 0, math.rad(tilt)),
    "Reddish brown",
    Enum.Material.Wood,
    LobbyModel,
    true,
    true
  )
  trunk.Color = Color3.fromRGB(94, 58, 32)
  local trunk2 = makePart(
    "TreeTrunkTop",
    Vector3.new(0.72 * s, 1.9 * s, 0.72 * s),
    CFrame.new(x + 0.18 * s, 2 + 3.1 * s, z) * CFrame.Angles(0, 0, math.rad(tilt - 3)),
    "Reddish brown",
    Enum.Material.Wood,
    LobbyModel,
    true,
    true
  )
  trunk2.Color = Color3.fromRGB(104, 66, 36)
  -- Copa frondosa: tres esferas que se abrazan (como los árboles de la referencia)
  local g1 = treeGreens[((tone - 1) % 3) + 1]
  local g2 = treeGreens[(tone % 3) + 1]
  local g3 = treeGreens[((tone + 1) % 3) + 1]
  islBall("TreeCanopy", Vector3.new(4.6 * s, 4.2 * s, 4.6 * s), CFrame.new(x, 2 + 5.1 * s, z), g1)
  islBall("TreeCanopy", Vector3.new(3.3 * s, 3.0 * s, 3.3 * s), CFrame.new(x + 1.35 * s, 2 + 4.3 * s, z + 0.6 * s), g2)
  islBall("TreeCanopy", Vector3.new(2.7 * s, 2.5 * s, 2.7 * s), CFrame.new(x - 1.15 * s, 2 + 5.9 * s, z - 0.5 * s), g3)
  -- Lucecitas mágicas entre las hojas (guiño al círculo del centro)
  for fi = 1, 3 do
    local fa = fi * 2.1 + x
    local dot = islBall(
      "TreeLight",
      Vector3.new(0.34, 0.34, 0.34),
      CFrame.new(x + math.cos(fa) * 1.9 * s, 2 + (4.4 + (fi % 2) * 0.9) * s, z + math.sin(fa) * 1.9 * s),
      (fi % 2 == 0) and Color3.fromRGB(255, 110, 235) or Color3.fromRGB(90, 240, 255)
    )
    dot.Material = Enum.Material.Neon
  end
end
islTree(-38, -19, 1.08, 1)
islTree(-19, -38, 0.9, 2)
islTree(38, -19, 1.08, 3)
islTree(19, -38, 0.9, 1)
islTree(-39, 15, 0.95, 2)
islTree(39, 15, 1.08, 3)
for _, pp in ipairs({ { 10, -36 }, { -10, -36 }, { 36, 10 }, { -36, 10 }, { 10, 32 }, { -10, 32 }, { 35, -10 }, {
  -35,
  -10,
} }) do
  makePart(
    "PlantRock",
    Vector3.new(0.8, 0.5, 0.8),
    CFrame.new(pp[1], 2.25, pp[2]),
    "Medium stone grey",
    Enum.Material.SmoothPlastic,
    LobbyModel,
    true,
    true
  )
  for li = 0, 2 do
    local leaf = makePart(
      "PlantLeaf",
      Vector3.new(0.3, 1.15, 0.55),
      CFrame.new(pp[1] + math.sin(li * 2.1) * 0.4, 2.8, pp[2] + math.cos(li * 2.1) * 0.4)
        * CFrame.Angles(math.rad(18), li * 2.1, math.rad(-14)),
      "Bright green",
      Enum.Material.SmoothPlastic,
      LobbyModel,
      false,
      true
    )
    leaf.Color = Color3.fromRGB(42, 112, 46)
  end
end
for _, rp in ipairs({ { 35, -20 }, { -35, -20 }, { 38, 6 }, { -38, 6 }, { 6, -41 }, { -6, -41 } }) do
  islWedge(
    "IslandRock",
    Vector3.new(1.6 + (rp[1] % 3) * 0.3, 1.3, 1.5),
    CFrame.new(rp[1], 2.6, rp[2]) * CFrame.Angles(0, math.rad(rp[1] * 7), 0),
    Color3.fromRGB(112, 112, 122),
    false
  )
end
for _, cp in ipairs({
  { 44, -9, Color3.fromRGB(190, 110, 255) },
  { -44, -9, Color3.fromRGB(110, 220, 255) },
  { 44, 23, Color3.fromRGB(110, 220, 255) },
  { -44, 23, Color3.fromRGB(255, 120, 220) },
}) do
  islWedge(
    "IslandCrystalRock",
    Vector3.new(2.2, 0.7, 1.9),
    CFrame.new(cp[1], 2.3, cp[2]),
    Color3.fromRGB(40, 38, 54),
    false
  )
  for ci, ch in ipairs({ 1.5, 2.4, 1.8 }) do
    local shard = islCrys(
      Vector3.new(0.8, ch, 0.8),
      CFrame.new(cp[1] + (ci - 2) * 0.75, 2.55 + ch / 2, cp[2] + ((ci % 2) * 0.6 - 0.3))
        * CFrame.Angles(math.rad((ci % 2) * 7 - 3), math.rad(ci * 40), math.rad((ci % 3) * 5 - 5)),
      cp[3]:Lerp(Color3.fromRGB(255, 255, 255), (ci == 2) and 0.35 or 0.1)
    )
    if ci == 2 then
      local cl = Instance.new("PointLight")
      cl.Brightness = 1.3
      cl.Range = 8
      cl.Color = cp[3]
      cl.Parent = shard
    end
  end
end
for ri, rp in ipairs({ { 15, -30 }, { -15, -30 }, { 30, 15 }, { -30, 15 }, { 0, -46 } }) do
  local slab = makePart(
    "RuneSlab",
    Vector3.new(2.3, 0.35, 2.3),
    CFrame.new(rp[1], 2.18, rp[2]) * CFrame.Angles(0, math.rad(ri * 24), 0),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    LobbyModel,
    true,
    true
  )
  slab.Color = Color3.fromRGB(70, 70, 84)
  local rc = (ri % 2 == 0) and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(110, 220, 255)
  for b = 0, 1 do
    local rb = makePart(
      "RuneSlabMark",
      Vector3.new(0.9, 0.14, 0.22),
      CFrame.new(rp[1] + (b - 0.5) * 0.5, 2.42, rp[2] + (b - 0.5) * 0.3) * CFrame.Angles(
          0,
          math.rad(ri * 24 + b * 50),
          0
        ),
      "White",
      Enum.Material.Neon,
      LobbyModel,
      false,
      true
    )
    rb.Color = rc
  end
end
for i = 1, 42 do
  local a = i * 2.39996
  local r = 15 + (i % 33)
  local x, z = math.cos(a) * r, math.sin(a) * r
  local nearPad = false
  for _, pd2 in ipairs(PAD_DATA) do
    if math.abs(x - pd2.pos.X) < 9.5 and math.abs(z - pd2.pos.Z) < 9.5 then
      nearPad = true
    end
  end
  if math.abs(z - x) > 7.5 and math.abs(z + x) > 7.5 and not nearPad and not (z > 36 and math.abs(x) < 28) then
    local tuft = makePart(
      "GrassTuft",
      Vector3.new(0.55, 0.75, 0.55),
      CFrame.new(x, 2.35, z),
      "Bright green",
      Enum.Material.SmoothPlastic,
      LobbyModel,
      false,
      true
    )
    tuft.Color = Color3.fromRGB(58, 138, 52)
  end
end

--===========================================================
-- LEADERBOARD WALL
--===========================================================
local boardPart = makePart(
  "LeaderboardBoard",
  Vector3.new(30, 18, 0.4),
  CFrame.new(0, 16, LD / 2 - 1.35),
  "Dark stone grey",
  Enum.Material.SmoothPlastic,
  LobbyModel,
  false,
  true
)
local boardGui = Instance.new("SurfaceGui")
boardGui.Face = Enum.NormalId.Front
boardGui.AlwaysOnTop = false
boardGui.LightInfluence = 0
boardGui.Parent = boardPart

local boardRoot = Instance.new("Frame")
boardRoot.Size = UDim2.new(1, 0, 1, 0)
boardRoot.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
boardRoot.BackgroundTransparency = 0.05
boardRoot.BorderSizePixel = 0
boardRoot.Parent = boardGui
Instance.new("UICorner", boardRoot).CornerRadius = UDim.new(0.03, 0)
local bStroke = Instance.new("UIStroke")
bStroke.Color = Color3.fromRGB(255, 215, 0)
bStroke.Thickness = 2
bStroke.Parent = boardRoot

local bTitle = Instance.new("TextLabel")
bTitle.Size = UDim2.new(1, 0, 0.12, 0)
bTitle.Position = UDim2.new(0, 0, 0.015, 0)
bTitle.BackgroundTransparency = 1
bTitle.Font = Enum.Font.LuckiestGuy
bTitle.TextScaled = true
bTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
bTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
bTitle.TextStrokeTransparency = 0.35
bTitle.Text = "SOBREVIVIENTES"
bTitle.Parent = boardRoot

local rowsFrame = Instance.new("ScrollingFrame")
rowsFrame.Size = UDim2.new(0.96, 0, 0.835, 0)
rowsFrame.Position = UDim2.new(0.02, 0, 0.145, 0)
rowsFrame.BackgroundTransparency = 1
rowsFrame.Parent = boardRoot
rowsFrame.ScrollBarThickness = 10
rowsFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
rowsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
rowsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local rl = Instance.new("UIListLayout")
rl.Padding = UDim.new(0, 5)
rl.FillDirection = Enum.FillDirection.Vertical
rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
rl.Parent = rowsFrame

local rankIcons = { "👑", "🧙", "🧪", "📖", "🔮" }
local leaderboardRows = {}
for i = 1, 12 do
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, 0, 0.18, 0)
  row.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
  row.BackgroundTransparency = 0.15
  row.BorderSizePixel = 0
  row.Parent = rowsFrame
  Instance.new("UICorner", row).CornerRadius = UDim.new(0.08, 0)

  local rank = Instance.new("TextLabel")
  rank.Name = "Rank"
  rank.Size = UDim2.new(0.10, 0, 1, 0)
  rank.BackgroundTransparency = 1
  rank.Font = Enum.Font.LuckiestGuy
  rank.TextScaled = true
  rank.TextColor3 = Color3.fromRGB(255, 215, 0)
  rank.Text = i .. "."
  rank.Parent = row

  local ic = Instance.new("TextLabel")
  ic.Name = "Icon"
  ic.Size = UDim2.new(0.09, 0, 1, 0)
  ic.Position = UDim2.new(0.10, 0, 0, 0)
  ic.BackgroundTransparency = 1
  ic.Font = Enum.Font.GothamBold
  ic.TextScaled = true
  ic.TextColor3 = Color3.fromRGB(255, 255, 255)
  ic.Text = rankIcons[i] or "⚡"
  ic.Parent = row

  local av = Instance.new("ImageLabel")
  av.Name = "Avatar"
  av.Size = UDim2.new(0.13, 0, 0.78, 0)
  av.Position = UDim2.new(0.20, 0, 0.11, 0)
  av.BackgroundTransparency = 1
  av.Image = ""
  av.Parent = row
  Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

  local nm = Instance.new("TextLabel")
  nm.Name = "Name"
  nm.Size = UDim2.new(0.42, 0, 1, 0)
  nm.Position = UDim2.new(0.34, 0, 0, 0)
  nm.BackgroundTransparency = 1
  nm.Font = Enum.Font.LuckiestGuy
  nm.TextScaled = true
  nm.TextXAlignment = Enum.TextXAlignment.Left
  nm.TextColor3 = (i == 1) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
  nm.Text = "—"
  nm.Parent = row

  local kl = Instance.new("TextLabel")
  kl.Name = "Kills"
  kl.Size = UDim2.new(0.20, 0, 1, 0)
  kl.Position = UDim2.new(0.78, 0, 0, 0)
  kl.BackgroundTransparency = 1
  kl.Font = Enum.Font.LuckiestGuy
  kl.TextScaled = true
  kl.TextXAlignment = Enum.TextXAlignment.Right
  kl.TextColor3 = Color3.fromRGB(255, 215, 0)
  kl.Text = "0"
  kl.Parent = row

  leaderboardRows[i] = { row = row, rank = rank, icon = ic, avatar = av, name = nm, kills = kl }
end

local function refreshLeaderboard()
  local ok, pages = pcall(function()
    return KillsOrdered:GetSortedAsync(false, 12)
  end)
  if not ok or not pages then
    for i = 1, 12 do
      leaderboardRows[i].name.Text = "—"
      leaderboardRows[i].kills.Text = "0"
      leaderboardRows[i].avatar.Image = ""
    end
    return
  end
  local page = pages:GetCurrentPage()
  for i = 1, 12 do
    local row = leaderboardRows[i]
    local entry = page[i]
    if entry then
      local uid = tonumber(entry.key)
      local score = tonumber(entry.value) or 0
      row.kills.Text = tostring(score)
      local dName = "Mago"
      local thumb = ""
      if uid then
        local okN, nR = pcall(function()
          return Players:GetNameByUserIdAsync(uid)
        end)
        if okN and nR then
          dName = nR
        else
          dName = "ID " .. tostring(uid)
        end
        local okT, tR = pcall(function()
          return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if okT and tR then
          thumb = tR
        end
        if thumb == "" then
          thumb = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(uid) .. "&w=100&h=100"
        end
      end
      row.name.Text = dName
      row.avatar.Image = thumb
    else
      row.name.Text = "—"
      row.kills.Text = "0"
      row.avatar.Image = ""
    end
  end
end

task.spawn(function()
  while true do
    refreshLeaderboard()
    task.wait(12)
  end
end)

--===========================================================
-- ESTRUCTURA EPICA V2 DE LA CLASIFICACION (arco alto, gargolas, sombrero)
-- Reconstruida tras la captura del usuario: fondo oscuro propio para aislarla
-- de la luz dorada del lobby, piedra casi negra, luces suaves y arco de verdad.
-- Solo Parts decorativas; no toca datos ni el refresco de la tabla.
--===========================================================
do
  local BZ = 45.65
  local PZ = 45.3
  local STONE_A = Color3.fromRGB(16, 15, 24)
  local STONE_B = Color3.fromRGB(24, 22, 34)
  local STONE_CAP = Color3.fromRGB(12, 11, 19)
  local function MP(n, s, cf, bc, mat, cc)
    local part = makePart(n, s, cf, bc, mat or Enum.Material.SmoothPlastic, LobbyModel, cc, true)
    return part
  end
  local function cyl(n, size, cf, col)
    local part = Instance.new("Part")
    part.Name = n
    part.Shape = Enum.PartType.Cylinder
    part.Size = size
    part.CFrame = cf
    part.BrickColor = BrickColor.new("White")
    part.Color = col
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Parent = LobbyModel
    return part
  end
  local function wedge(n, size, cf, col, neon)
    local part = Instance.new("WedgePart")
    part.Name = n
    part.Size = size
    part.CFrame = cf
    part.BrickColor = BrickColor.new("White")
    part.Color = col
    part.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Parent = LobbyModel
    return part
  end

  -- Fondo oscuro propio + escenario (aisla el monumento de la luz dorada)
  -- Cristal de verdad: pirámide alta y fina con la punta arriba (nada de cuñas-tabla)
  local function crysShard(size, cf, col)
    local part = MP("CrystalShard", Vector3.new(1, 1, 1), cf, "White", Enum.Material.Neon, false)
    part.Color = col
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Pyramid
    mesh.Scale = size
    mesh.Parent = part
    return part
  end
  -- (Sin pared trasera ni escenario en el suelo: el monumento va directo sobre el césped)

  -- Marco de madera de la pizarra
  local frameCol = Color3.fromRGB(92, 56, 28)
  for _, fd in ipairs({
    { "BoardFrameT", Vector3.new(33, 1.4, 0.6), CFrame.new(0, 25.3, BZ - 0.6) },
    { "BoardFrameB", Vector3.new(33, 1.4, 0.6), CFrame.new(0, 6.7, BZ - 0.6) },
    { "BoardFrameL", Vector3.new(1.4, 20, 0.6), CFrame.new(-16.1, 16, BZ - 0.6) },
    { "BoardFrameR", Vector3.new(1.4, 20, 0.6), CFrame.new(16.1, 16, BZ - 0.6) },
  }) do
    local fp = MP(fd[1], fd[2], fd[3], "Reddish brown", Enum.Material.Wood, false)
    fp.Color = frameCol
  end

  for _, sd in ipairs({ -1, 1 }) do
    local PX = sd * 20
    local flameCol = (sd < 0) and Color3.fromRGB(168, 92, 255) or Color3.fromRGB(74, 140, 255)

    -- Pilar de piedra casi negra, bloques alternados
    local pb = MP("ClassPillarBase", Vector3.new(9.6, 0.9, 6.2), CFrame.new(PX, 3.1, PZ), "Dark stone grey", nil, true)
    pb.Color = STONE_CAP
    local pp =
      MP("ClassPillarPlinth", Vector3.new(8.2, 1.3, 5.2), CFrame.new(PX, 4.2, PZ), "Medium stone grey", nil, true)
    pp.Color = STONE_B
    for k = 0, 8 do
      local wide = (k % 2 == 0)
      local blk = MP(
        "ClassPillarBlock",
        wide and Vector3.new(6.4, 2.35, 4.3) or Vector3.new(5.7, 2.35, 3.8),
        CFrame.new(PX + ((k % 3) - 1) * 0.15, 5.9 + k * 2.35, PZ + ((k % 2) * 0.14) - 0.07),
        "Dark stone grey",
        nil,
        true
      )
      blk.Color = wide and STONE_A or STONE_B
    end
    local cap = MP("ClassPillarCap", Vector3.new(8.0, 1.4, 5.4), CFrame.new(PX, 26.6, PZ), "Dark stone grey", nil, true)
    cap.Color = STONE_CAP
    local trim =
      MP("ClassPillarTrim", Vector3.new(8.8, 0.7, 5.9), CFrame.new(PX, 27.65, PZ), "Medium stone grey", nil, true)
    trim.Color = Color3.fromRGB(30, 28, 42)

    -- Enredaderas densas pegadas a la piedra (masas de hojas, no cubitos sueltos)
    local greens = { Color3.fromRGB(18, 60, 28), Color3.fromRGB(24, 76, 33), Color3.fromRGB(13, 44, 21) }
    for k = 0, 19 do
      local vy = 25.4 - k * 1.12
      local vx = PX - sd * 2.55 + math.sin(k * 2.1 + sd * 3) * 0.85
      local vs = 0.62 + (k % 4) * 0.15
      local leaf = MP("ClassVine", Vector3.new(vs, vs, 0.7), CFrame.new(vx, vy, PZ - 2.2), "Dark green", nil, false)
      leaf.Color = greens[(k % 3) + 1]
      if k % 3 == 0 then
        local plate = MP(
          "ClassVineLeaf",
          Vector3.new(1.6, 0.3, 1.05),
          CFrame.new(vx + 0.4, vy - 0.5, PZ - 2.45) * CFrame.Angles(0, math.rad(k * 37), math.rad(14)),
          "Bright green",
          nil,
          false
        )
        plate.Color = greens[((k + 1) % 3) + 1]
      end
    end
    for k = 0, 6 do
      local bush = MP(
        "ClassVineBush",
        Vector3.new(1.3 + (k % 3) * 0.35, 1.1 + (k % 2) * 0.4, 1.0),
        CFrame.new(PX - sd * 2.2 + (k % 3 - 1) * 1.15, 3.4 + (k % 2) * 0.55, PZ - 2.5),
        "Dark green",
        nil,
        false
      )
      bush.Shape = Enum.PartType.Ball
      bush.Color = greens[(k % 3) + 1]
    end

    -- (fuegos eliminados por peticion del usuario)

    -- Farol colgante con luz suave
    local arm = MP(
      "LanternArm",
      Vector3.new(0.55, 0.55, 4.4),
      CFrame.new(PX, 21.6, PZ - 3.7),
      "Reddish brown",
      Enum.Material.Wood,
      false
    )
    arm.Color = frameCol
    for li = 0, 2 do
      MP(
        "LanternChain",
        Vector3.new(0.26, 0.5, 0.26),
        CFrame.new(PX, 21.1 - li * 0.48, PZ - 5.7),
        "Really black",
        nil,
        false
      )
    end
    MP("LanternTop", Vector3.new(1.5, 0.3, 1.5), CFrame.new(PX, 19.9, PZ - 5.7), "Really black", nil, false)
    MP("LanternBase", Vector3.new(1.5, 0.3, 1.5), CFrame.new(PX, 18.1, PZ - 5.7), "Really black", nil, false)
    local core = MP(
      "LanternCore",
      Vector3.new(1.0, 1.5, 1.0),
      CFrame.new(PX, 19.0, PZ - 5.7),
      "Bright yellow",
      Enum.Material.Neon,
      false
    )
    core.Color = Color3.fromRGB(255, 190, 80)
    local ll = Instance.new("PointLight")
    ll.Brightness = 2.0
    ll.Range = 11
    ll.Color = Color3.fromRGB(255, 170, 70)
    ll.Parent = core

    -- Gárgola grande y oscura coronando el pilar (mirando al lobby, -Z)
    local GY = 28.0
    local function GP(n, s, cf, col)
      local gp = MP(n, s, cf, "Dark stone grey", nil, false)
      gp.Color = col
      return gp
    end
    GP("GargSeat", Vector3.new(4.4, 1.0, 3.8), CFrame.new(PX, GY + 0.5, PZ), STONE_CAP)
    GP("GargBody", Vector3.new(3.0, 3.2, 2.5), CFrame.new(PX, GY + 2.6, PZ + 0.1), Color3.fromRGB(15, 14, 22))
    GP("GargChest", Vector3.new(2.2, 2.4, 0.6), CFrame.new(PX, GY + 2.5, PZ - 1.2), Color3.fromRGB(20, 19, 29))
    GP("GargHead", Vector3.new(2.45, 1.85, 2.15), CFrame.new(PX, GY + 4.9, PZ - 0.3), Color3.fromRGB(30, 28, 44))
    GP("GargSnout", Vector3.new(1.25, 0.8, 1.2), CFrame.new(PX, GY + 4.4, PZ - 1.65), Color3.fromRGB(23, 22, 33))
    GP("GargBrow", Vector3.new(2.3, 0.5, 0.7), CFrame.new(PX, GY + 5.6, PZ - 1.15), STONE_CAP)
    local eyeCol = (sd < 0) and Color3.fromRGB(255, 64, 64) or Color3.fromRGB(90, 225, 255)
    for _, eo in ipairs({ -0.55, 0.55 }) do
      local eye = MP(
        "GargEye",
        Vector3.new(0.34, 0.3, 0.14),
        CFrame.new(PX + eo, GY + 5.05, PZ - 1.42),
        "White",
        Enum.Material.Neon,
        false
      )
      eye.Color = eyeCol
    end
    for _, fo in ipairs({ -0.35, 0.35 }) do
      local fang = MP(
        "GargFang",
        Vector3.new(0.16, 0.34, 0.1),
        CFrame.new(PX + fo, GY + 3.92, PZ - 2.18),
        "White",
        Enum.Material.Neon,
        false
      )
      fang.Color = Color3.fromRGB(240, 240, 230)
    end
    for _, eo in ipairs({ -1.2, 1.2 }) do
      wedge(
        "GargEar",
        Vector3.new(0.5, 0.95, 0.42),
        CFrame.new(PX + eo * 0.72, GY + 6.05, PZ - 0.3) * CFrame.Angles(0, 0, math.rad(-eo * 26)),
        Color3.fromRGB(13, 12, 20),
        false
      )
    end
    for _, ao in ipairs({ -1.85, 1.85 }) do
      GP(
        "GargArm",
        Vector3.new(0.85, 3.0, 0.85),
        CFrame.new(PX + ao, GY + 1.9, PZ - 0.85) * CFrame.Angles(math.rad(14), 0, 0),
        Color3.fromRGB(15, 14, 22)
      )
      GP("GargPaw", Vector3.new(1.15, 0.6, 1.9), CFrame.new(PX + ao, GY + 0.55, PZ - 1.55), Color3.fromRGB(20, 19, 29))
      GP(
        "GargHaunch",
        Vector3.new(1.1, 1.9, 1.7),
        CFrame.new(PX + ao, GY + 1.35, PZ + 0.65),
        Color3.fromRGB(15, 14, 22)
      )
    end
    GP(
      "GargTail",
      Vector3.new(0.55, 0.55, 3.2),
      CFrame.new(PX, GY + 1.1, PZ + 2.1) * CFrame.Angles(math.rad(-20), 0, 0),
      STONE_CAP
    )
    wedge(
      "GargWingA",
      Vector3.new(3.0, 2.6, 0.45),
      CFrame.new(PX + sd * 2.3, GY + 5.5, PZ + 0.55) * CFrame.Angles(0, math.rad(sd * -12), math.rad(sd * 32)),
      Color3.fromRGB(11, 10, 18),
      false
    )
    wedge(
      "GargWingB",
      Vector3.new(2.2, 1.7, 0.4),
      CFrame.new(PX + sd * 4.0, GY + 6.35, PZ + 0.65) * CFrame.Angles(0, math.rad(sd * -18), math.rad(sd * 40)),
      Color3.fromRGB(11, 10, 18),
      false
    )

    -- Varita apoyada junto al pilar
    local wandCol = flameCol
    local stick = MP(
      "ClassWandStick",
      Vector3.new(0.18, 5.4, 0.18),
      CFrame.new(PX - sd * 4.1, 5.3, PZ - 2.6) * CFrame.Angles(0, 0, math.rad(sd * 16)),
      "Reddish brown",
      Enum.Material.Wood,
      false
    )
    stick.Color = Color3.fromRGB(96, 58, 30)
    local wtip =
      wedge("ClassWandTip", Vector3.new(0.42, 0.9, 0.42), CFrame.new(PX - sd * 4.85, 7.85, PZ - 2.6), wandCol, true)
    local wl = Instance.new("PointLight")
    wl.Brightness = 1.0
    wl.Range = 7
    wl.Color = wandCol
    wl.Parent = wtip
  end

  -- Arco escalonado alto que une los pilares
  for _, sd in ipairs({ -1, 1 }) do
    local a1 =
      MP("ClassArchBlock1", Vector3.new(6.2, 2.2, 3.9), CFrame.new(sd * 15.2, 28.9, PZ), "Dark stone grey", nil, false)
    a1.Color = STONE_B
    local a2 =
      MP("ClassArchBlock2", Vector3.new(5.4, 2.1, 3.9), CFrame.new(sd * 10.6, 30.6, PZ), "Dark stone grey", nil, false)
    a2.Color = STONE_A
  end
  local beam = MP("ClassArchBeam", Vector3.new(15.5, 2.2, 4.1), CFrame.new(0, 31.9, PZ), "Dark stone grey", nil, false)
  beam.Color = STONE_B
  local key = MP("ClassArchKey", Vector3.new(2.7, 3.1, 4.3), CFrame.new(0, 31.3, PZ), "Medium stone grey", nil, false)
  key.Color = Color3.fromRGB(34, 32, 46)

  -- Runas luminosas en la cara del arco (barritas neon, cian/morado alternadas)
  local runeCols = { Color3.fromRGB(110, 220, 255), Color3.fromRGB(190, 140, 255) }
  local runePos = { { -15.2, 28.9 }, { -10.6, 30.6 }, { 10.6, 30.6 }, { 15.2, 28.9 } }
  for ri, rp in ipairs(runePos) do
    local rc = runeCols[(ri % 2) + 1]
    local flip = (ri % 2 == 0) and 1 or -1
    local function RB(s, cf)
      local rb = MP("ClassRune", s, cf, "White", Enum.Material.Neon, false)
      rb.Color = rc
    end
    RB(Vector3.new(0.28, 2.0, 0.18), CFrame.new(rp[1], rp[2], PZ - 2.0))
    RB(
      Vector3.new(0.28, 1.1, 0.18),
      CFrame.new(rp[1] + 0.4 * flip, rp[2] + 0.45, PZ - 2.0) * CFrame.Angles(0, 0, math.rad(48 * flip))
    )
    RB(
      Vector3.new(0.28, 1.0, 0.18),
      CFrame.new(rp[1] + 0.38 * flip, rp[2] - 0.15, PZ - 2.0) * CFrame.Angles(0, 0, math.rad(-48 * flip))
    )
  end

  -- Letrero de madera oscura TOP SORCERERS (legible: letras amarillas con borde negro)
  for _, px2 in ipairs({ -6.5, 6.5 }) do
    local post = MP(
      "SignPost",
      Vector3.new(0.9, 4.4, 0.9),
      CFrame.new(px2, 30.4, 44.6),
      "Reddish brown",
      Enum.Material.Wood,
      false
    )
    post.Color = Color3.fromRGB(80, 48, 24)
  end
  local signPart = MP(
    "TopSorcerersSign",
    Vector3.new(23, 5.8, 0.8),
    CFrame.new(0, 32.95, 43.9),
    "Reddish brown",
    Enum.Material.Wood,
    false
  )
  signPart.Color = Color3.fromRGB(72, 43, 21)
  for _, sy in ipairs({ 32.05, 33.75 }) do
    local seam = MP("SignSeam", Vector3.new(23, 0.16, 0.12), CFrame.new(0, sy, 43.45), "Really black", nil, false)
    seam.Color = Color3.fromRGB(58, 34, 16)
  end
  local signGui = Instance.new("SurfaceGui")
  signGui.Face = Enum.NormalId.Front
  signGui.AlwaysOnTop = true
  signGui.LightInfluence = 0
  signGui.Parent = signPart
  local signLbl = Instance.new("TextLabel")
  signLbl.Size = UDim2.new(1, 0, 0.48, 0)
  signLbl.Position = UDim2.new(0, 0, 0.02, 0)
  signLbl.BackgroundTransparency = 1
  signLbl.Font = Enum.Font.LuckiestGuy
  signLbl.TextScaled = true
  signLbl.TextColor3 = Color3.fromRGB(255, 206, 64)
  signLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  signLbl.TextStrokeTransparency = 0
  signLbl.Text = "TOP"
  signLbl.Parent = signGui
  local signLbl2 = Instance.new("TextLabel")
  signLbl2.Size = UDim2.new(1, 0, 0.5, 0)
  signLbl2.Position = UDim2.new(0, 0, 0.5, 0)
  signLbl2.BackgroundTransparency = 1
  signLbl2.Font = Enum.Font.LuckiestGuy
  signLbl2.TextScaled = true
  signLbl2.TextColor3 = Color3.fromRGB(255, 206, 64)
  signLbl2.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  signLbl2.TextStrokeTransparency = 0
  signLbl2.Text = "SORCERERS"
  signLbl2.Parent = signGui

  -- Sombrero de mago sobre el letrero (ala + cono inclinado + banda + hebilla)
  local hatCol = Color3.fromRGB(64, 27, 106)
  cyl(
    "WitchHatBrim",
    Vector3.new(0.6, 7.8, 7.8),
    CFrame.new(0, 36.15, 43.9) * CFrame.Angles(0, 0, math.rad(90)),
    Color3.fromRGB(56, 23, 94)
  )
  cyl(
    "WitchHatBand",
    Vector3.new(0.9, 5.5, 5.5),
    CFrame.new(0, 36.85, 43.9) * CFrame.Angles(0, 0, math.rad(90)),
    Color3.fromRGB(40, 22, 66)
  )
  cyl(
    "WitchHatCone1",
    Vector3.new(1.2, 5.2, 5.2),
    CFrame.new(0, 37.4, 43.9) * CFrame.Angles(0, 0, math.rad(90)),
    hatCol
  )
  cyl(
    "WitchHatCone2",
    Vector3.new(1.15, 4.1, 4.1),
    CFrame.new(0.35, 38.45, 43.9) * CFrame.Angles(0, 0, math.rad(84)),
    hatCol
  )
  cyl(
    "WitchHatCone3",
    Vector3.new(1.1, 3.1, 3.1),
    CFrame.new(0.75, 39.35, 43.9) * CFrame.Angles(0, 0, math.rad(78)),
    hatCol
  )
  cyl(
    "WitchHatTip",
    Vector3.new(1.0, 2.0, 2.0),
    CFrame.new(1.2, 40.05, 43.9) * CFrame.Angles(0, 0, math.rad(68)),
    hatCol
  )
  local buckle = MP(
    "HatBuckle",
    Vector3.new(1.35, 1.0, 0.28),
    CFrame.new(0.1, 36.8, 25.45),
    "Bright yellow",
    Enum.Material.Neon,
    false
  )
  buckle.Color = Color3.fromRGB(255, 190, 60)

  -- Cristales brillantes en la base (cian a la izquierda, rosa a la derecha)
  for _, sd in ipairs({ -1, 1 }) do
    local cc = (sd < 0) and Color3.fromRGB(130, 235, 255) or Color3.fromRGB(255, 150, 215)
    local CX = sd * 24.0
    local rock = MP("CrystalRock", Vector3.new(3.6, 0.8, 2.6), CFrame.new(CX, 2.9, 42.2), "Dark stone grey", nil, false)
    rock.Color = STONE_CAP
    local heights = { 1.7, 2.9, 2.2, 3.5, 1.4 }
    for ci, ch in ipairs(heights) do
      local cx2 = CX + (ci - 3) * 0.8
      local cc2 = cc:Lerp(Color3.fromRGB(255, 255, 255), (ci == 4) and 0.5 or 0.12)
      local shard = crysShard(
        Vector3.new(0.85, ch, 0.85),
        CFrame.new(cx2, 3.25 + ch / 2, 42.2 + ((ci % 2) * 0.5 - 0.25))
          * CFrame.Angles(math.rad((ci % 2) * 7 - 3), math.rad(ci * 40), math.rad((ci % 3) * 5 - 5)),
        cc2
      )
      if ci == 4 then
        local cl = Instance.new("PointLight")
        cl.Brightness = 1.3
        cl.Range = 8
        cl.Color = cc
        cl.Parent = shard
      end
    end
  end

  -- Libros de hechizos a la izquierda de la base
  local b1 = MP("SpellBook1", Vector3.new(3.4, 0.5, 2.6), CFrame.new(-18.6, 2.95, 41.7), "Really red", nil, true)
  b1.Color = Color3.fromRGB(128, 34, 34)
  MP("SpellBook1Pages", Vector3.new(3.1, 0.32, 2.3), CFrame.new(-18.6, 3.32, 41.7), "Institutional white", nil, false)
  local b2cf = CFrame.new(-18.4, 3.75, 41.7) * CFrame.Angles(0, math.rad(18), 0)
  local b2 = MP("SpellBook2", Vector3.new(2.8, 0.45, 2.1), b2cf, "Navy blue", nil, true)
  b2.Color = Color3.fromRGB(40, 60, 120)
  local gem = MP(
    "SpellBookGem",
    Vector3.new(0.55, 0.16, 0.55),
    CFrame.new(-18.4, 4.05, 41.7),
    "Bright yellow",
    Enum.Material.Neon,
    false
  )
  gem.Color = Color3.fromRGB(255, 190, 60)
  local lean = MP(
    "SpellBookLean",
    Vector3.new(2.4, 3.4, 0.5),
    CFrame.new(-17.6, 4.4, 42.9) * CFrame.Angles(0, 0, math.rad(16)),
    "Plum",
    nil,
    true
  )
  lean.Color = Color3.fromRGB(110, 40, 90)

  -- Pociones a la derecha de la base
  local potionCols = { Color3.fromRGB(80, 255, 120), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 90, 90) }
  for pi, pc in ipairs(potionCols) do
    local px2 = 18.3 + (pi - 1) * 1.7
    local glass = MP(
      "PotionBottle",
      Vector3.new(1.0, 1.35, 1.0),
      CFrame.new(px2, 3.35, 41.7),
      "Institutional white",
      Enum.Material.Glass,
      false
    )
    glass.Transparency = 0.35
    local liq =
      MP("PotionLiquid", Vector3.new(0.8, 0.85, 0.8), CFrame.new(px2, 3.15, 41.7), "White", Enum.Material.Neon, false)
    liq.Color = pc
    MP(
      "PotionNeck",
      Vector3.new(0.4, 0.5, 0.4),
      CFrame.new(px2, 4.25, 41.7),
      "Institutional white",
      Enum.Material.Glass,
      false
    )
    MP("PotionCork", Vector3.new(0.34, 0.36, 0.34), CFrame.new(px2, 4.62, 41.7), "Brown", Enum.Material.Wood, false)
    if pi == 2 then
      local pl2 = Instance.new("PointLight")
      pl2.Brightness = 1.1
      pl2.Range = 7
      pl2.Color = pc
      pl2.Parent = liq
    end
  end
end

-- FIN PARTE 2 (lobby visual: isla flotante + tabla TOP SORCERERS)
