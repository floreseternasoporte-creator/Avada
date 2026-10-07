--===========================================================
-- AVADA DUELING - SERVER PARTE 1: JUEGO (pads, arenas, rondas)
-- Coloca en: ServerScriptService > Script (nombre: AvadaParte1)
-- Carga el nucleo desde el ModuleScript AvadaCore con require
-- (sin "shared": Studio Lite lo bloquea). Pega tambien la
-- Parte 2 (visual) en otro Script.
-- Si el pegado no llega hasta la ultima linea (-- FIN PARTE 1), se corto.
--===========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")
-- Busca el ModuleScript del nucleo SIN importar su nombre ni la carpeta
-- (espera lo que haga falta y avisa, para que nunca muera el juego en silencio)
local coreMod
local waited = 0
while not coreMod do
  coreMod = ServerScriptService:FindFirstChildOfClass("ModuleScript", true)
  if not coreMod then
    task.wait(0.5)
    waited += 0.5
    if waited % 5 < 0.5 then
      warn("[Avada] Buscando el ModuleScript del nucleo en ServerScriptService...")
    end
  end
end
print("[Avada] Nucleo encontrado: " .. coreMod.Name)
local S = require(coreMod)

local arenaData = S.arenaData
local playerDuel = S.playerDuel
local pendingCast = S.pendingCast
local LOBBY_SPAWN = S.LOBBY_SPAWN
local ROUND_TIME = S.ROUND_TIME
local TOTAL_ROUNDS = S.TOTAL_ROUNDS
local HOUSES = S.HOUSES
local ARENA_CENTERS = S.ARENA_CENTERS
local KillsOrdered = S.KillsOrdered
local RE_BattleStart = S.RE_BattleStart
local RE_BattleEnd = S.RE_BattleEnd
local RE_Countdown = S.RE_Countdown
local RE_RoundUpdate = S.RE_RoundUpdate
local freezePlayer = S.freezePlayer
local teleportTo = S.teleportTo
local returnToLobby = S.returnToLobby
local giveFighterSetup = S.giveFighterSetup
local loadKills = S.loadKills
local saveKills = S.saveKills

--===========================================================
-- HELPERS: WORLD BUILDING
--===========================================================
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

local function addTex(part, face, u, v, id)
  local t = Instance.new("Texture")
  t.Texture = id or "rbxassetid://1536723462"
  t.Face = face or Enum.NormalId.Top
  t.StudsPerTileU = u or 6
  t.StudsPerTileV = v or 6
  t.Parent = part
end

local function addGothicPillar(cx, cy, cz, height, parent)
  makePart(
    "PillarShaft",
    Vector3.new(4, height, 4),
    CFrame.new(cx, cy + height / 2, cz),
    "Medium stone grey",
    Enum.Material.SmoothPlastic,
    parent,
    true,
    true
  )
  makePart(
    "PillarBase",
    Vector3.new(5.5, 2, 5.5),
    CFrame.new(cx, cy + 1, cz),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    parent,
    true,
    true
  )
  makePart(
    "PillarCap",
    Vector3.new(5.5, 2, 5.5),
    CFrame.new(cx, cy + height - 1, cz),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    parent,
    true,
    true
  )
end

local function addGothicArch(cx, cy, cz, w, h, thick, parent, rotY)
  rotY = rotY or 0
  local rot = CFrame.Angles(0, math.rad(rotY), 0)
  makePart(
    "ArchLeft",
    Vector3.new(thick, h * 0.65, w * 0.18),
    CFrame.new(cx, cy + h * 0.325, cz) * rot * CFrame.new(-w * 0.41, 0, 0),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    parent,
    true,
    true
  )
  makePart(
    "ArchRight",
    Vector3.new(thick, h * 0.65, w * 0.18),
    CFrame.new(cx, cy + h * 0.325, cz) * rot * CFrame.new(w * 0.41, 0, 0),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    parent,
    true,
    true
  )
end

local function addStainedGlass(pos, size, colors, parent)
  makePart(
    "SGFrame",
    size + Vector3.new(0.4, 0.4, 0),
    CFrame.new(pos),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    parent,
    false,
    true
  )
  local segH = size.Y / #colors
  for i, c in ipairs(colors) do
    local seg = makePart(
      "SGSeg_" .. i,
      Vector3.new(size.X - 0.3, segH - 0.1, 0.15),
      CFrame.new(pos + Vector3.new(0, (i - 1) * segH - size.Y / 2 + segH / 2, -0.1)),
      "White",
      Enum.Material.Neon,
      parent,
      false,
      true
    )
    seg.Color = c
    seg.Transparency = 0.35
    local gl = Instance.new("PointLight")
    gl.Brightness = 1.5
    gl.Range = 12
    gl.Color = c
    gl.Parent = seg
  end
end

local function addWallTorch(pos, parent)
  local bowl = makePart(
    "TorchBowl",
    Vector3.new(0.9, 0.5, 0.9),
    CFrame.new(pos + Vector3.new(0, 0.8, 0)),
    "Dark orange",
    Enum.Material.SmoothPlastic,
    parent,
    false,
    true
  )
  local fire = Instance.new("Fire")
  fire.Heat = 8
  fire.Size = 3.5
  fire.Color = Color3.fromRGB(255, 120, 10)
  fire.SecondaryColor = Color3.fromRGB(255, 220, 0)
  fire.Parent = bowl
  local light = Instance.new("PointLight")
  light.Brightness = 6
  light.Range = 28
  light.Color = Color3.fromRGB(255, 150, 40)
  light.Parent = bowl
end

local function createFlyingCandle(position, parent)
  local candle = Instance.new("Part")
  candle.Name = "FlyingCandle"
  candle.Size = Vector3.new(0.28, 1.2, 0.28)
  candle.BrickColor = BrickColor.new("White")
  candle.Material = Enum.Material.SmoothPlastic
  candle.Anchored = true
  candle.CanCollide = false
  candle.CastShadow = false
  candle.CFrame = CFrame.new(position)
  candle.Parent = parent

  local wick = Instance.new("Part")
  wick.Name = "Wick"
  wick.Size = Vector3.new(0.06, 0.25, 0.06)
  wick.BrickColor = BrickColor.new("Black")
  wick.Material = Enum.Material.SmoothPlastic
  wick.Anchored = true
  wick.CanCollide = false
  wick.CastShadow = false
  wick.CFrame = CFrame.new(position + Vector3.new(0, 0.72, 0))
  wick.Parent = parent

  local flame = Instance.new("Fire")
  flame.Heat = 3
  flame.Size = 1.8
  flame.Color = Color3.fromRGB(255, 200, 80)
  flame.SecondaryColor = Color3.fromRGB(255, 120, 30)
  flame.Parent = candle

  local light = Instance.new("PointLight")
  light.Brightness = 3
  light.Range = 18
  light.Color = Color3.fromRGB(255, 180, 60)
  light.Parent = candle

  local basePos = position
  local offset = math.random(0, 628) / 100
  local speed = 0.4 + math.random(0, 40) / 100
  local conn
  conn = RunService.Heartbeat:Connect(function(dt)
    if not candle.Parent then
      if conn then
        conn:Disconnect()
      end
      return
    end
    offset += dt * speed
    local ny = basePos.Y + math.sin(offset) * 0.6
    candle.CFrame = CFrame.new(basePos.X, ny, basePos.Z)
    wick.CFrame = CFrame.new(basePos.X, ny + 0.72, basePos.Z)
  end)
  return candle
end

--===========================================================
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
-- CIRCULO CENTRAL: CREAR LA PARTIDA (estilo 99 Nights)
-- Sin pads: te paras dentro del circulo magico y entras a la
-- cola; con 2+ magos arranca el duelo en una arena libre.
--===========================================================
local circleQueue = {}
local lockedPair = {}
local arenaBusy = { false, false, false, false }

local circleAnchor = makePart(
  "CircleBoardAnchor",
  Vector3.new(1, 1, 1),
  CFrame.new(0, 15.5, 0),
  "White",
  Enum.Material.SmoothPlastic,
  LobbyModel,
  false,
  true
)
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
circleTitle.Text = "⚔️ CÍRCULO DE DUELOS ⚔️"
circleTitle.Parent = circleGui

local circleStatus = Instance.new("TextLabel")
circleStatus.Name = "Status"
circleStatus.Size = UDim2.new(1, 0, 0.36, 0)
circleStatus.Position = UDim2.new(0, 0, 0.42, 0)
circleStatus.BackgroundTransparency = 1
circleStatus.Font = Enum.Font.FredokaOne
circleStatus.TextScaled = true
circleStatus.TextColor3 = Color3.fromRGB(235, 235, 235)
circleStatus.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
circleStatus.TextStrokeTransparency = 0.2
circleStatus.Text = "ENTRA AL CÍRCULO PARA PELEAR"
circleStatus.Parent = circleGui

local circleSub = Instance.new("TextLabel")
circleSub.Name = "Sub"
circleSub.Size = UDim2.new(1, 0, 0.22, 0)
circleSub.Position = UDim2.new(0, 0, 0.78, 0)
circleSub.BackgroundTransparency = 1
circleSub.Font = Enum.Font.FredokaOne
circleSub.TextScaled = true
circleSub.TextColor3 = Color3.fromRGB(190, 190, 200)
circleSub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
circleSub.TextStrokeTransparency = 0.3
circleSub.Text = "Sal del círculo para salir de la cola"
circleSub.Parent = circleGui

local function updateCircleBoard()
  if next(lockedPair) ~= nil then
    circleStatus.Text = "⚡ ¡DUELO EN CAMINO! ⚡"
    circleStatus.TextColor3 = Color3.fromRGB(255, 215, 0)
  elseif #circleQueue >= 2 then
    circleStatus.Text = tostring(#circleQueue) .. " MAGOS LISTOS ⚡"
    circleStatus.TextColor3 = Color3.fromRGB(120, 255, 120)
  elseif #circleQueue == 1 then
    circleStatus.Text = "1 MAGO ESPERANDO RIVAL..."
    circleStatus.TextColor3 = Color3.fromRGB(255, 230, 120)
  else
    circleStatus.Text = "ENTRA AL CÍRCULO PARA PELEAR"
    circleStatus.TextColor3 = Color3.fromRGB(235, 235, 235)
  end
end

local function removeFromQueue(player)
  for k, p2 in ipairs(circleQueue) do
    if p2 == player then
      table.remove(circleQueue, k)
      break
    end
  end
  updateCircleBoard()
end

-- Estar dentro del circulo = estar en la cola de duelos
task.spawn(function()
  while true do
    task.wait(0.3)
    for _, pl in ipairs(Players:GetPlayers()) do
      if not playerDuel[pl] and not lockedPair[pl] then
        local char = pl.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local inside = false
        if hrp then
          local d = math.sqrt(hrp.Position.X ^ 2 + hrp.Position.Z ^ 2)
          inside = (d <= 12.5) and hrp.Position.Y > 1 and hrp.Position.Y < 12
        end
        local qi = table.find(circleQueue, pl)
        if inside and not qi then
          table.insert(circleQueue, pl)
          updateCircleBoard()
        elseif not inside and qi then
          table.remove(circleQueue, qi)
          updateCircleBoard()
        end
      end
    end
  end
end)
updateCircleBoard()
print("⭕ [Avada] Circulo central listo: la partida se crea en el circulo magico")

--===========================================================
-- ARENAS
--===========================================================
local function buildArena(idx)
  local center = ARENA_CENTERS[idx]
  local model = Instance.new("Model")
  model.Name = "Arena_" .. idx
  model.Parent = workspace

  local AW, AD, AH = 40, 132, 38
  local house = HOUSES[idx]

  local function ap(name, size, off, color, mat, cc)
    return makePart(name, size, CFrame.new(center + off), color, mat, model, cc ~= false, true)
  end

  local aFloor =
    ap("Floor", Vector3.new(AW, 2, AD), Vector3.new(0, -1, 0), "Dark stone grey", Enum.Material.SmoothPlastic, true)
  addTex(aFloor, Enum.NormalId.Top, 5, 5)

  local function wall(name, size, off)
    local w = ap(name, size, off, "Dark stone grey", Enum.Material.SmoothPlastic, true)
    addTex(w, Enum.NormalId.Front, 7, 7)
    addTex(w, Enum.NormalId.Back, 7, 7)
    return w
  end

  wall("WallBack", Vector3.new(AW + 5, AH, 2.5), Vector3.new(0, AH / 2 - 1, -AD / 2))
  wall("WallFront", Vector3.new(AW + 5, AH, 2.5), Vector3.new(0, AH / 2 - 1, AD / 2))
  wall("WallLeft", Vector3.new(2.5, AH, AD + 5), Vector3.new(-AW / 2, AH / 2 - 1, 0))
  wall("WallRight", Vector3.new(2.5, AH, AD + 5), Vector3.new(AW / 2, AH / 2 - 1, 0))
  ap(
    "Ceiling",
    Vector3.new(AW + 5, 2.5, AD + 5),
    Vector3.new(0, AH - 1, 0),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    true
  )

  for z = -AD / 2 + 10, AD / 2 - 10, 12 do
    ap(
      "VaultZ_" .. z,
      Vector3.new(AW, 2, 2),
      Vector3.new(0, AH - 2.5, z),
      "Dark stone grey",
      Enum.Material.SmoothPlastic,
      false
    )
  end
  for x = -AW / 2 + 8, AW / 2 - 8, 10 do
    ap(
      "VaultX_" .. x,
      Vector3.new(2, 2, AD),
      Vector3.new(x, AH - 2.5, 0),
      "Dark stone grey",
      Enum.Material.SmoothPlastic,
      false
    )
  end

  for _, pOff in ipairs({
    Vector3.new(-AW / 2 + 3, 0, -AD / 2 + 3),
    Vector3.new(-AW / 2 + 3, 0, AD / 2 - 3),
    Vector3.new(AW / 2 - 3, 0, -AD / 2 + 3),
    Vector3.new(AW / 2 - 3, 0, AD / 2 - 3),
  }) do
    addGothicPillar(center.X + pOff.X, center.Y + pOff.Y, center.Z + pOff.Z, AH - 2, model)
  end
  for _, zOff in ipairs({ -22, 22 }) do
    addGothicArch(center.X - AW / 2 + 1, center.Y, center.Z + zOff, 14, 28, 2, model, 90)
    addGothicArch(center.X + AW / 2 - 1, center.Y, center.Z + zOff, 14, 28, 2, model, 90)
  end

  local vColors = { house.neon, Color3.fromRGB(255, 255, 180), house.neon }
  for _, xOff in ipairs({ -10, 0, 10 }) do
    addStainedGlass(center + Vector3.new(xOff, AH - 12, -AD / 2 + 1), Vector3.new(7, 14, 0.4), vColors, model)
  end

  for i = 1, 10 do
    createFlyingCandle(
      Vector3.new(
        center.X + math.random(-AW / 2 + 4, AW / 2 - 4),
        center.Y + AH - math.random(5, 14),
        center.Z + math.random(-AD / 2 + 4, AD / 2 - 4)
      ),
      model
    )
  end

  for _, tp in ipairs({
    Vector3.new(-AW / 2 + 3, 12, -AD / 2 + 9),
    Vector3.new(-AW / 2 + 3, 12, AD / 2 - 9),
    Vector3.new(AW / 2 - 3, 12, -AD / 2 + 9),
    Vector3.new(AW / 2 - 3, 12, AD / 2 - 9),
    Vector3.new(0, 12, -AD / 2 + 9),
    Vector3.new(0, 12, AD / 2 - 9),
  }) do
    addWallTorch(center + tp, model)
  end

  arenaData[idx] = {
    spawnA = center + Vector3.new(-12, 3.8, -36),
    spawnB = center + Vector3.new(12, 3.8, 36),
    centerPos = center + Vector3.new(0, 3.5, 0),
  }
end

for i = 1, 4 do
  buildArena(i)
end

--===========================================================
-- ROUND SYSTEM (la entrada ahora es el circulo central)
--===========================================================
local function freeArena(arenaIdx)
  arenaBusy[arenaIdx] = false
  updateCircleBoard()
end

local function startRound(p1, p2, roundNum, arenaIdx, wins)
  RE_RoundUpdate:FireClient(p1, roundNum, ROUND_TIME, wins[1], wins[2])
  RE_RoundUpdate:FireClient(p2, roundNum, ROUND_TIME, wins[2], wins[1])

  local arena = arenaData[arenaIdx]
  giveFighterSetup(p1, HOUSES[arenaIdx].name)
  giveFighterSetup(p2, HOUSES[arenaIdx].name)
  task.wait(0.25)

  teleportTo(p1, arena.spawnA, arena.spawnB)
  teleportTo(p2, arena.spawnB, arena.spawnA)
  task.wait(0.2)
  freezePlayer(p1, false)
  freezePlayer(p2, false)

  local roundFinished = false
  local roundWinner = nil

  local function onDeath(dead, survivor)
    if roundFinished then
      return
    end
    roundFinished = true
    roundWinner = survivor
  end

  local function watchDeath(player, opp)
    local char = player.Character
    if not char then
      return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
      return
    end
    hum.Died:Connect(function()
      if playerDuel[player] then
        onDeath(player, opp)
      end
    end)
  end

  watchDeath(p1, p2)
  watchDeath(p2, p1)

  local timeLeft = ROUND_TIME
  local timerConn
  timerConn = RunService.Heartbeat:Connect(function(dt)
    if roundFinished then
      if timerConn then
        timerConn:Disconnect()
      end
      return
    end
    timeLeft -= dt
    RE_RoundUpdate:FireClient(p1, roundNum, math.ceil(timeLeft), wins[1], wins[2])
    RE_RoundUpdate:FireClient(p2, roundNum, math.ceil(timeLeft), wins[2], wins[1])
    if timeLeft <= 0 then
      roundFinished = true
      roundWinner = nil
      if timerConn then
        timerConn:Disconnect()
      end
    end
  end)

  while not roundFinished do
    task.wait(0.1)
  end
  if timerConn then
    timerConn:Disconnect()
  end
  return roundWinner
end

local function startDuelPair(p1, p2, arenaIdx)
  freezePlayer(p1, true)
  freezePlayer(p2, true)

  for t = 5, 1, -1 do
    if not lockedPair[p1] or not lockedPair[p2] then
      freezePlayer(p1, false)
      freezePlayer(p2, false)
      arenaBusy[arenaIdx] = false
      updateCircleBoard()
      return
    end
    RE_Countdown:FireClient(p1, t)
    RE_Countdown:FireClient(p2, t)
    task.wait(1)
  end

  lockedPair[p1] = nil
  lockedPair[p2] = nil
  updateCircleBoard()

  local arena = arenaData[arenaIdx]
  if not arena then
    freezePlayer(p1, false)
    freezePlayer(p2, false)
    arenaBusy[arenaIdx] = false
    updateCircleBoard()
    return
  end

  playerDuel[p1] = { opponent = p2, arenaIdx = arenaIdx }
  playerDuel[p2] = { opponent = p1, arenaIdx = arenaIdx }

  RE_BattleStart:FireClient(p1, p2.Name)
  RE_BattleStart:FireClient(p2, p1.Name)
  task.wait(2.0)

  teleportTo(p1, arena.spawnA, arena.spawnB)
  teleportTo(p2, arena.spawnB, arena.spawnA)
  freezePlayer(p1, false)
  freezePlayer(p2, false)

  local wins = { 0, 0 }
  local overallWinner = nil
  local overallLoser = nil

  for round = 1, TOTAL_ROUNDS do
    if not playerDuel[p1] or not playerDuel[p2] then
      break
    end
    local rWinner = startRound(p1, p2, round, arenaIdx, wins)
    if rWinner == p1 then
      wins[1] += 1
    elseif rWinner == p2 then
      wins[2] += 1
    end
    RE_RoundUpdate:FireClient(p1, round, 0, wins[1], wins[2])
    RE_RoundUpdate:FireClient(p2, round, 0, wins[2], wins[1])
    if wins[1] >= 2 then
      overallWinner = p1
      overallLoser = p2
      break
    end
    if wins[2] >= 2 then
      overallWinner = p2
      overallLoser = p1
      break
    end
    if round < TOTAL_ROUNDS then
      freezePlayer(p1, true)
      freezePlayer(p2, true)
      task.wait(2)
    end
  end

  if not overallWinner then
    if wins[1] > wins[2] then
      overallWinner = p1
      overallLoser = p2
    elseif wins[2] > wins[1] then
      overallWinner = p2
      overallLoser = p1
    end
  end

  if overallWinner then
    RE_BattleEnd:FireClient(overallWinner, overallWinner.Name, true)
    if overallLoser then
      RE_BattleEnd:FireClient(overallLoser, overallWinner.Name, false)
    end
  else
    RE_BattleEnd:FireClient(p1, "EMPATE", false)
    RE_BattleEnd:FireClient(p2, "EMPATE", false)
  end

  playerDuel[p1] = nil
  playerDuel[p2] = nil
  pendingCast[p1] = nil
  pendingCast[p2] = nil

  task.delay(4, function()
    if overallWinner and overallWinner.Character then
      returnToLobby(overallWinner)
    end
    if overallLoser then
      if not overallLoser.Character then
        overallLoser:LoadCharacter()
        task.wait(0.8)
      end
      returnToLobby(overallLoser)
    end
    freeArena(arenaIdx)
  end)
end


-- Emparejador: cada 0.5s toma parejas de la cola del circulo
task.spawn(function()
  while true do
    task.wait(0.5)
    for k = #circleQueue, 1, -1 do
      local pl = circleQueue[k]
      if not pl or not pl.Parent then
        table.remove(circleQueue, k)
      end
    end
    while #circleQueue >= 2 do
      local freeIdx
      for i2 = 1, 4 do
        if not arenaBusy[i2] then
          freeIdx = i2
          break
        end
      end
      if not freeIdx then
        break
      end
      local p1 = table.remove(circleQueue, 1)
      local p2 = table.remove(circleQueue, 1)
      if not (p1 and p2 and p1.Parent and p2.Parent) then
        if p1 and p1.Parent then
          table.insert(circleQueue, 1, p1)
        end
        break
      end
      arenaBusy[freeIdx] = true
      lockedPair[p1] = { opponent = p2, arenaIdx = freeIdx }
      lockedPair[p2] = { opponent = p1, arenaIdx = freeIdx }
      updateCircleBoard()
      task.spawn(startDuelPair, p1, p2, freeIdx)
    end
  end
end)

--===========================================================
-- PLAYER EVENTS
--===========================================================
Players.PlayerAdded:Connect(function(player)
  local ls = Instance.new("Folder")
  ls.Name = "leaderstats"
  ls.Parent = player
  local kills = Instance.new("IntValue")
  kills.Name = "Kills"
  kills.Value = 0
  kills.Parent = ls
  loadKills(player)
  player.CharacterAdded:Connect(function(char)
    removeFromQueue(player)
    pendingCast[player] = nil
    local hrp = char:WaitForChild("HumanoidRootPart")
    task.wait(0.15)
    local duelInfo = playerDuel[player]
    if duelInfo then
      local arena = arenaData[duelInfo.arenaIdx]
      if arena then
        freezePlayer(player, false)
        hrp.CFrame = CFrame.new(arena.centerPos + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)))
        return
      end
    end
    playerDuel[player] = nil
    hrp.CFrame = CFrame.new(LOBBY_SPAWN + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
  end)
end)

Players.PlayerRemoving:Connect(function(player)
  removeFromQueue(player)
  saveKills(player)
  if lockedPair[player] then
    local info = lockedPair[player]
    lockedPair[player] = nil
    local opp = info.opponent
    if opp and lockedPair[opp] then
      lockedPair[opp] = nil
      freezePlayer(opp, false)
    end
    arenaBusy[info.arenaIdx] = false
    updateCircleBoard()
  end
  if playerDuel[player] then
    local info = playerDuel[player]
    local opp = info.opponent
    playerDuel[player] = nil
    if opp and playerDuel[opp] then
      playerDuel[opp] = nil
      RE_BattleEnd:FireClient(opp, opp.Name, true)
      task.spawn(function()
        task.wait(2)
        local c = opp.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
          c.HumanoidRootPart.CFrame = CFrame.new(LOBBY_SPAWN)
        end
        arenaBusy[info.arenaIdx] = false
        updateCircleBoard()
      end)
    end
  end
end)

task.spawn(function()
  while true do
    task.wait(60)
    for _, plr in ipairs(Players:GetPlayers()) do
      saveKills(plr)
    end
  end
end)

print("⚡ [DuelGame v11.0] Server Script loaded — 7 spells, epic clash system ⚡")

-- FIN PARTE 1
