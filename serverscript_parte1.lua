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
-- Busca el ModuleScript del nucleo SIN importar su nombre exacto
local coreMod
local tCore = os.clock()
repeat
  task.wait(0.25)
  coreMod = ServerScriptService:FindFirstChildOfClass("ModuleScript")
until coreMod or (os.clock() - tCore > 15)
assert(coreMod, "Avada: falta el ModuleScript del nucleo en ServerScriptService")
local S = require(coreMod)

local squares = S.squares
local squareParts = S.squareParts
local padStations = S.padStations
local arenaData = S.arenaData
local playerSquare = S.playerSquare
local playerDuel = S.playerDuel
local pendingCast = S.pendingCast
local LOBBY_SPAWN = S.LOBBY_SPAWN
local ROUND_TIME = S.ROUND_TIME
local TOTAL_ROUNDS = S.TOTAL_ROUNDS
local HOUSES = S.HOUSES
local PAD_DATA = S.PAD_DATA
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
-- La Parte 3 construye el modelo IslandLobby (isla + tabla); aqui solo se espera para colgar los pads
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
-- PAD STATIONS
--===========================================================
local function createPadStation(idx, data)
  local pad = makePart(
    "DuelPad_" .. idx,
    Vector3.new(11, 0.25, 11),
    CFrame.new(data.pos),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    LobbyModel,
    false,
    true
  )
  pad.Color = Color3.fromRGB(28, 24, 38)
  squareParts[idx] = pad

  local borders = {}
  local bOff = 5.22
  for _, bd in ipairs({
    { Vector3.new(11, 0.34, 0.55), Vector3.new(0, 0.08, -bOff) },
    { Vector3.new(11, 0.34, 0.55), Vector3.new(0, 0.08, bOff) },
    { Vector3.new(0.55, 0.34, 11), Vector3.new(-bOff, 0.08, 0) },
    { Vector3.new(0.55, 0.34, 11), Vector3.new(bOff, 0.08, 0) },
  }) do
    local bp = makePart(
      "PadBorder_" .. idx,
      bd[1],
      CFrame.new(data.pos + bd[2]),
      "Bright yellow",
      Enum.Material.Neon,
      LobbyModel,
      false,
      true
    )
    bp.Color = Color3.fromRGB(255, 205, 64)
    table.insert(borders, bp)
  end

  local bb = Instance.new("BillboardGui")
  bb.Name = "PadCounter"
  bb.Size = UDim2.new(7, 0, 2.2, 0)
  bb.StudsOffset = Vector3.new(0, 4.4, 0)
  bb.AlwaysOnTop = true
  bb.LightInfluence = 0
  bb.MaxDistance = 90
  bb.Parent = pad
  local counter = Instance.new("TextLabel")
  counter.Name = "Count"
  counter.Size = UDim2.new(1, 0, 1, 0)
  counter.BackgroundTransparency = 1
  counter.Font = Enum.Font.LuckiestGuy
  counter.TextScaled = true
  counter.TextColor3 = Color3.fromRGB(255, 214, 64)
  counter.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  counter.TextStrokeTransparency = 0
  counter.Text = "0/2"
  counter.Parent = bb

  makePart(
    "PadBase_" .. idx,
    Vector3.new(13, 1.4, 13),
    CFrame.new(data.pos + Vector3.new(0, -0.8, 0)),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    LobbyModel,
    true,
    true
  )

  local sign = makePart(
    "PadSign_" .. idx,
    Vector3.new(9.5, 4.6, 0.2),
    CFrame.new(data.signPos, data.signLook),
    "Dark stone grey",
    Enum.Material.SmoothPlastic,
    LobbyModel,
    false,
    true
  )
  local gui = Instance.new("SurfaceGui")
  gui.Face = Enum.NormalId.Front
  gui.AlwaysOnTop = true
  gui.LightInfluence = 0
  gui.Parent = sign

  local holder = Instance.new("Frame")
  holder.Size = UDim2.new(1, 0, 1, 0)
  holder.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
  holder.BackgroundTransparency = 0.12
  holder.BorderSizePixel = 0
  holder.Parent = gui
  Instance.new("UICorner", holder).CornerRadius = UDim.new(0.08, 0)

  local title = Instance.new("TextLabel")
  title.Name = "Title"
  title.BackgroundTransparency = 1
  title.Size = UDim2.new(1, 0, 0.40, 0)
  title.Position = UDim2.new(0, 0, 0.06, 0)
  title.Font = Enum.Font.LuckiestGuy
  title.TextScaled = true
  title.TextColor3 = data.house.neon
  title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  title.TextStrokeTransparency = 0.35
  title.Text = string.upper(data.house.name)
  title.Parent = holder

  local status = Instance.new("TextLabel")
  status.Name = "Status"
  status.BackgroundTransparency = 1
  status.Size = UDim2.new(1, 0, 0.30, 0)
  status.Position = UDim2.new(0, 0, 0.54, 0)
  status.Font = Enum.Font.FredokaOne
  status.TextScaled = true
  status.TextColor3 = Color3.fromRGB(230, 230, 230)
  status.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  status.TextStrokeTransparency = 0.4
  status.Text = "0/2 · TOCA PARA UNIRTE"
  status.Parent = holder

  padStations[idx] = {
    part = pad,
    sign = sign,
    title = title,
    status = status,
    house = data.house,
    borders = borders,
    counter = counter,
  }
end

for i, data in ipairs(PAD_DATA) do
  createPadStation(i, data)
end
print("✅ [Avada] Pads amarillos construidos: " .. #PAD_DATA)

-- (los pads amarillos van sobre los caminos de la isla; sin plaza ni puerta del salón)

local function updateBoardForPad(idx)
  local sq = squares[idx]
  local st = padStations[idx]
  local pad = squareParts[idx]
  if not sq or not st or not pad then
    return
  end
  local occupied = (#sq.players > 0) or sq.inBattle or sq.countdown
  local borderCol = sq.inBattle and Color3.fromRGB(255, 70, 70)
    or (#sq.players == 1 and not sq.countdown) and Color3.fromRGB(120, 255, 120)
    or Color3.fromRGB(255, 205, 64)
  if st.borders then
    for _, bp in ipairs(st.borders) do
      bp.Color = borderCol
    end
  end
  if st.counter then
    st.counter.Text = tostring(#sq.players) .. "/2"
    st.counter.TextColor3 = borderCol
  end
  pad.Color = occupied and Color3.fromRGB(48, 22, 26) or Color3.fromRGB(28, 24, 38)
  if sq.inBattle then
    st.status.Text = "EN BATALLA"
    st.status.TextColor3 = Color3.fromRGB(255, 100, 100)
  elseif sq.countdown then
    st.status.Text = "PREPARANDO"
    st.status.TextColor3 = Color3.fromRGB(255, 215, 0)
  elseif #sq.players == 0 then
    st.status.Text = "0/2 · TOCA PARA UNIRTE"
    st.status.TextColor3 = Color3.fromRGB(210, 210, 210)
  elseif #sq.players == 1 then
    st.status.Text = "1/2 · ESPERANDO"
    st.status.TextColor3 = Color3.fromRGB(120, 255, 120)
  else
    st.status.Text = "2/2 · LISTOS"
    st.status.TextColor3 = Color3.fromRGB(255, 255, 255)
  end
end

for i = 1, 4 do
  updateBoardForPad(i)
end

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
-- ROUND SYSTEM
--===========================================================
local function removeFromSquare(player)
  local idx = playerSquare[player]
  if not idx then
    return
  end
  local sq = squares[idx]
  for k, p in ipairs(sq.players) do
    if p == player then
      table.remove(sq.players, k)
      break
    end
  end
  playerSquare[player] = nil
  updateBoardForPad(idx)
end

local function endBattle(squareIdx)
  local sq = squares[squareIdx]
  if sq then
    sq.inBattle = false
    sq.countdown = false
    updateBoardForPad(squareIdx)
  end
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

local function startDuel(squareIdx)
  local sq = squares[squareIdx]
  if sq.inBattle or sq.countdown or #sq.players < 2 then
    return
  end

  sq.countdown = true
  updateBoardForPad(squareIdx)
  local p1 = sq.players[1]
  local p2 = sq.players[2]
  freezePlayer(p1, true)
  freezePlayer(p2, true)

  for t = 5, 1, -1 do
    if not playerSquare[p1] or not playerSquare[p2] then
      freezePlayer(p1, false)
      freezePlayer(p2, false)
      sq.countdown = false
      updateBoardForPad(squareIdx)
      return
    end
    RE_Countdown:FireClient(p1, t)
    RE_Countdown:FireClient(p2, t)
    task.wait(1)
  end

  sq.countdown = false
  sq.inBattle = true
  playerSquare[p1] = nil
  playerSquare[p2] = nil
  sq.players = {}
  updateBoardForPad(squareIdx)

  local arena = arenaData[squareIdx]
  if not arena then
    endBattle(squareIdx)
    return
  end

  playerDuel[p1] = { opponent = p2, arenaIdx = squareIdx }
  playerDuel[p2] = { opponent = p1, arenaIdx = squareIdx }

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
    local rWinner = startRound(p1, p2, round, squareIdx, wins)
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
    endBattle(squareIdx)
  end)
end

--===========================================================
-- TOUCH PADS
--===========================================================
for i, sqPart in ipairs(squareParts) do
  sqPart.Touched:Connect(function(hit)
    local char = hit and hit.Parent
    local player = char and Players:GetPlayerFromCharacter(char)
    if not player then
      return
    end
    if playerSquare[player] or playerDuel[player] then
      return
    end
    local sq = squares[i]
    if sq.inBattle or sq.countdown or #sq.players >= 2 then
      return
    end
    for _, p in ipairs(sq.players) do
      if p == player then
        return
      end
    end
    playerSquare[player] = i
    table.insert(sq.players, player)
    updateBoardForPad(i)
    if #sq.players == 2 then
      task.spawn(startDuel, i)
    end
  end)
end

local SQUARE_RADIUS = 6.0
RunService.Heartbeat:Connect(function()
  for i, sqPos in ipairs(PAD_DATA) do
    local sq = squares[i]
    if not sq.inBattle and not sq.countdown then
      for k = #sq.players, 1, -1 do
        local pl = sq.players[k]
        local char = pl and pl.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
          table.remove(sq.players, k)
          playerSquare[pl] = nil
          updateBoardForPad(i)
        else
          local dist = (Vector3.new(hrp.Position.X, sqPos.pos.Y, hrp.Position.Z) - sqPos.pos).Magnitude
          if dist > SQUARE_RADIUS then
            table.remove(sq.players, k)
            playerSquare[pl] = nil
            updateBoardForPad(i)
          end
        end
      end
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
    removeFromSquare(player)
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
  removeFromSquare(player)
  saveKills(player)
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
        local sq = squares[info.arenaIdx]
        if sq then
          sq.inBattle = false
          sq.countdown = false
          updateBoardForPad(info.arenaIdx)
        end
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
