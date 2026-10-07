--===========================================================
-- AVADA DUELING - TODO EN UNO (un solo Script)
-- YA NO HAY MODULO NI PARTE 1 NI PARTE 2:
-- * Borra de ServerScriptService: AvadaCore, AvadaParte1, AvadaParte2
--   (y cualquier Script viejo de Avada que veas alli).
-- * Deja UN SOLO Script (el nombre da igual) con TODO este archivo.
-- La partida se crea en el CIRCULO MAGICO del centro de la isla:
-- te paras dentro, entra otro mago, y arranca el duelo.
-- Si el pegado no llega hasta la ultima linea (-- FIN TODO EN UNO), se corto.
--===========================================================
local S
do
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")

--===========================================================
-- CONFIG
--===========================================================
local LOBBY_SPAWN = Vector3.new(0, 6, 0)
local PLAYER_HEALTH = 100
local ROUND_TIME = 60
local TOTAL_ROUNDS = 3

local CLASH_WINDOW = 0.30
local WINDUP = 0.16

-- SFX IDs
local SFX_CAST = "rbxassetid://109707041985625"
local SFX_DEATH = "rbxassetid://120717906835357"
local SFX_HIT = "rbxassetid://5982271945"
local SFX_CLASH = "rbxassetid://6518811702"
local SFX_AVADA = "rbxassetid://6026980735"
local SFX_EXPELL = "rbxassetid://6026982406"

--===========================================================
-- SPELLS (nuevos hechizos auténticos de Harry Potter)
--===========================================================
local SPELL_DATA = {
  Expelliarmus = {
    damage = 30,
    power = 30,
    speed = 70,
    cdKey = "Expelliarmus",
    color = Color3.fromRGB(255, 50, 50),
    light = Color3.fromRGB(255, 90, 90),
    trailA = Color3.fromRGB(255, 110, 110),
    trailB = Color3.fromRGB(180, 0, 0),
    sparkCol = Color3.fromRGB(255, 150, 150),
    projSize = Vector3.new(0.35, 0.35, 1.8),
    kb = 35,
    kbUp = 15,
    kbDur = 1.1,
    sfx = SFX_EXPELL,
  },
  Stupefy = {
    damage = 45,
    power = 45,
    speed = 62,
    cdKey = "Stupefy",
    color = Color3.fromRGB(255, 70, 20),
    light = Color3.fromRGB(255, 110, 40),
    trailA = Color3.fromRGB(255, 140, 60),
    trailB = Color3.fromRGB(200, 60, 0),
    sparkCol = Color3.fromRGB(255, 180, 100),
    projSize = Vector3.new(0.55, 0.55, 0.55),
    kb = 42,
    kbUp = 22,
    kbDur = 1.3,
    sfx = SFX_CAST,
  },
  Reducto = {
    damage = 60,
    power = 60,
    speed = 56,
    cdKey = "Reducto",
    color = Color3.fromRGB(150, 15, 255),
    light = Color3.fromRGB(180, 40, 255),
    trailA = Color3.fromRGB(200, 80, 255),
    trailB = Color3.fromRGB(90, 0, 180),
    sparkCol = Color3.fromRGB(210, 120, 255),
    projSize = Vector3.new(0.70, 0.70, 0.70),
    kb = 50,
    kbUp = 26,
    kbDur = 1.4,
    sfx = SFX_CAST,
  },
  Sectumsempra = {
    damage = 75,
    power = 75,
    speed = 78,
    cdKey = "Sectumsempra",
    color = Color3.fromRGB(210, 0, 25),
    light = Color3.fromRGB(230, 10, 40),
    trailA = Color3.fromRGB(255, 20, 55),
    trailB = Color3.fromRGB(60, 0, 15),
    sparkCol = Color3.fromRGB(240, 50, 60),
    projSize = Vector3.new(0.18, 0.7, 2.6),
    kb = 56,
    kbUp = 18,
    kbDur = 1.6,
    sfx = SFX_CAST,
  },
  Crucio = {
    damage = 45,
    power = 45,
    speed = 50,
    cdKey = "Crucio",
    color = Color3.fromRGB(230, 215, 0),
    light = Color3.fromRGB(255, 240, 20),
    trailA = Color3.fromRGB(255, 240, 60),
    trailB = Color3.fromRGB(175, 145, 0),
    sparkCol = Color3.fromRGB(255, 250, 120),
    projSize = Vector3.new(0.48, 0.48, 0.48),
    kb = 25,
    kbUp = 38,
    kbDur = 2.5,
    sfx = SFX_CAST,
  },
  Incendio = {
    damage = 55,
    power = 55,
    speed = 45,
    cdKey = "Incendio",
    color = Color3.fromRGB(255, 100, 0),
    light = Color3.fromRGB(255, 140, 30),
    trailA = Color3.fromRGB(255, 160, 50),
    trailB = Color3.fromRGB(180, 40, 0),
    sparkCol = Color3.fromRGB(255, 200, 80),
    projSize = Vector3.new(0.9, 0.9, 0.9),
    kb = 38,
    kbUp = 28,
    kbDur = 1.5,
    sfx = SFX_CAST,
  },
  AvadaKedavra = {
    damage = 999,
    power = 999,
    speed = 100,
    cdKey = "AvadaKedavra",
    color = Color3.fromRGB(0, 210, 20),
    light = Color3.fromRGB(0, 255, 40),
    trailA = Color3.fromRGB(0, 255, 30),
    trailB = Color3.fromRGB(0, 70, 0),
    sparkCol = Color3.fromRGB(120, 255, 120),
    projSize = Vector3.new(0.30, 0.30, 2.8),
    kb = 70,
    kbUp = 30,
    kbDur = 0.2,
    sfx = SFX_AVADA,
  },
}

--===========================================================
-- HOUSES & LAYOUT
--===========================================================
local HOUSES = {
  { name = "Gryffindor", primary = "Crimson", neon = Color3.fromRGB(180, 20, 20) },
  { name = "Slytherin", primary = "Bright green", neon = Color3.fromRGB(0, 160, 60) },
  { name = "Ravenclaw", primary = "Bright blue", neon = Color3.fromRGB(30, 60, 200) },
  { name = "Hufflepuff", primary = "Bright yellow", neon = Color3.fromRGB(210, 180, 0) },
}

-- Lobby estilo 99 Noches: los 4 pads en UNA fila central pegada (13 studs entre centros,
-- bases tocándose), letreros bajos justo detrás y spawn al sur mirando a la plaza.
-- Isla circular GRANDE (Ø112) flotante: los 4 pads amarillos van sobre los 4 caminos
-- diagonales (r=30), letreros al final de cada camino (r=44), spawn en el círculo mágico.
local PAD_DATA = {
  {
    pos = Vector3.new(-21.2, 3.6, -21.2),
    house = HOUSES[1],
    signPos = Vector3.new(-31.1, 8.5, -31.1),
    signLook = Vector3.new(-21.2, 8.5, -21.2),
  },
  {
    pos = Vector3.new(21.2, 3.6, -21.2),
    house = HOUSES[2],
    signPos = Vector3.new(31.1, 8.5, -31.1),
    signLook = Vector3.new(21.2, 8.5, -21.2),
  },
  {
    pos = Vector3.new(-21.2, 3.6, 21.2),
    house = HOUSES[3],
    signPos = Vector3.new(-31.1, 8.5, 31.1),
    signLook = Vector3.new(-21.2, 8.5, 21.2),
  },
  {
    pos = Vector3.new(21.2, 3.6, 21.2),
    house = HOUSES[4],
    signPos = Vector3.new(31.1, 8.5, 31.1),
    signLook = Vector3.new(21.2, 8.5, 21.2),
  },
}

local ARENA_CENTERS = {
  Vector3.new(0, 5, 320),
  Vector3.new(0, 5, 460),
  Vector3.new(0, 5, 600),
  Vector3.new(0, 5, 740),
}

--===========================================================
-- DATA STORES
--===========================================================
-- DataStore blindado: en el Play de Studio Lite no hay DataStores; con pcall
-- el juego corre igual en Play (solo no guarda kills ahi) y en el juego real si.
local KillsStore, KillsOrdered
do
  local dummyStore = {
    GetAsync = function()
      return nil
    end,
    SetAsync = function() end,
    UpdateAsync = function()
      return nil
    end,
    GetSortedAsync = function()
      return {
        GetCurrentPage = function()
          return {}
        end,
      }
    end,
  }
  local okA, resA = pcall(function()
    return DataStoreService:GetDataStore("DuelKills_v11")
  end)
  local okB, resB = pcall(function()
    return DataStoreService:GetOrderedDataStore("DuelKillsRank_v11")
  end)
  KillsStore = (okA and resA) or dummyStore
  KillsOrdered = (okB and resB) or dummyStore
end

--===========================================================
-- REMOTES
--===========================================================
local Remotes = ReplicatedStorage:FindFirstChild("DuelRemotes")
if not Remotes then
  Remotes = Instance.new("Folder")
  Remotes.Name = "DuelRemotes"
  Remotes.Parent = ReplicatedStorage
end

local function makeRemote(name, isFunc)
  local r = Remotes:FindFirstChild(name)
  if not r then
    r = Instance.new(isFunc and "RemoteFunction" or "RemoteEvent")
    r.Name = name
    r.Parent = Remotes
  end
  return r
end

local RE_BattleStart = makeRemote("BattleStart")
local RE_BattleEnd = makeRemote("BattleEnd")
local RE_CastSpell = makeRemote("CastSpell")
local RE_Countdown = makeRemote("Countdown")
local RE_RoundUpdate = makeRemote("RoundUpdate")
local RE_SpellEffect = makeRemote("SpellEffect")
local RE_ClashUpdate = makeRemote("ClashUpdate")

--===========================================================
-- STATE
--===========================================================
local squares = {}
local squareParts = {}
local padStations = {}
local arenaData = {}

local playerSquare = {}
local playerDuel = {}
local pendingCast = {}
local clashActive = {}

local playerKills = {}
local loadingKills = {}

for i = 1, 4 do
  squares[i] = { players = {}, inBattle = false, countdown = false }
end

--===========================================================
-- GAMEPLAY HELPERS
--===========================================================
local function playSoundAt(char, id, vol)
  if not char then
    return
  end
  local p = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
  if not p then
    return
  end
  local s = Instance.new("Sound")
  s.SoundId = id
  s.Volume = vol or 1
  s.RollOffMode = Enum.RollOffMode.InverseTapered
  s.RollOffMaxDistance = 80
  s.Parent = p
  s:Play()
  Debris:AddItem(s, 5)
end

local function getCastPart(char)
  if not char then
    return nil
  end
  local wand = char:FindFirstChild("Varita Magica")
  if wand then
    local tip = wand:FindFirstChild("WandTip")
    if tip then
      return tip
    end
  end
  return char:FindFirstChild("RightHand")
    or char:FindFirstChild("Right Lower Arm")
    or char:FindFirstChild("Right Arm")
    or char:FindFirstChild("RightUpperArm")
end

local function freezePlayer(player, frozen)
  local char = player.Character
  if not char then
    return
  end
  local hum = char:FindFirstChildOfClass("Humanoid")
  if not hum then
    return
  end
  hum.WalkSpeed = frozen and 0 or 16
  hum.JumpPower = frozen and 0 or 50
end

local function teleportTo(player, pos, lookAt)
  local char = player.Character
  if char and char:FindFirstChild("HumanoidRootPart") then
    char.HumanoidRootPart.CFrame = CFrame.new(pos, lookAt)
  end
end

local function clearWand(player)
  local function kill(p)
    for _, i in ipairs(p:GetChildren()) do
      if i.Name == "Varita Magica" then
        i:Destroy()
      end
    end
  end
  if player:FindFirstChild("Backpack") then
    kill(player.Backpack)
  end
  if player.Character then
    kill(player.Character)
  end
end

local function returnToLobby(player)
  local char = player.Character
  if char and char:FindFirstChild("HumanoidRootPart") then
    char.HumanoidRootPart.CFrame = CFrame.new(LOBBY_SPAWN + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
  end
  clearWand(player)
end

local function registerKill(killer)
  if not killer or not killer:IsA("Player") then
    return
  end
  playerKills[killer] = (playerKills[killer] or 0) + 1
  local ls = killer:FindFirstChild("leaderstats")
  local kv = ls and ls:FindFirstChild("Kills")
  if kv then
    kv.Value = playerKills[killer]
  end
  task.spawn(function()
    local uid = tostring(killer.UserId)
    pcall(function()
      KillsStore:SetAsync(uid, playerKills[killer])
    end)
    pcall(function()
      KillsOrdered:SetAsync(uid, playerKills[killer])
    end)
  end)
end

local function loadKills(player)
  if loadingKills[player] then
    return
  end
  loadingKills[player] = true
  local uid = tostring(player.UserId)
  local kills = 0
  local ok, result = pcall(function()
    return KillsStore:GetAsync(uid)
  end)
  if ok and typeof(result) == "number" then
    kills = result
  end
  playerKills[player] = kills
  local ls = player:FindFirstChild("leaderstats")
  local kv = ls and ls:FindFirstChild("Kills")
  if kv then
    kv.Value = kills
  end
  loadingKills[player] = nil
end

local function saveKills(player)
  if not playerKills[player] then
    return
  end
  local uid = tostring(player.UserId)
  local kills = playerKills[player]
  pcall(function()
    KillsStore:SetAsync(uid, kills)
  end)
  pcall(function()
    KillsOrdered:SetAsync(uid, kills)
  end)
end

--===========================================================
-- WAND CREATION
--===========================================================
local function createWand(houseName)
  local house = HOUSES[1]
  for _, h in ipairs(HOUSES) do
    if h.name == houseName then
      house = h
      break
    end
  end

  local wand = Instance.new("Tool")
  wand.Name = "Varita Magica"
  wand.RequiresHandle = true
  wand.CanBeDropped = false
  wand.GripPos = Vector3.new(0, -0.52, 0)
  wand.GripForward = Vector3.new(0, 0, 1)
  wand.GripRight = Vector3.new(1, 0, 0)
  wand.GripUp = Vector3.new(0, 1, 0)
  wand:SetAttribute("HouseName", houseName or "Gryffindor")

  local function wp(name, size, col, mat)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.BrickColor = BrickColor.new(col)
    p.Material = mat or Enum.Material.SmoothPlastic
    p.CanCollide = false
    p.Massless = true
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = wand
    return p
  end

  local function weld(p0, p1)
    local w = Instance.new("WeldConstraint")
    w.Part0 = p0
    w.Part1 = p1
    w.Parent = p0
  end

  local function addCylinder(part, scaleX, scaleY, scaleZ)
    local m = Instance.new("SpecialMesh")
    m.MeshType = Enum.MeshType.Cylinder
    m.Scale = Vector3.new(scaleX or 1, scaleY or 1, scaleZ or 1)
    m.Parent = part
    return m
  end

  -- Varita de madera estilizada (más simple y natural)
  local handle = wp("Handle", Vector3.new(0.20, 1.0, 0.20), "Reddish brown", Enum.Material.Wood)
  handle.Color = Color3.fromRGB(86, 46, 30)
  addCylinder(handle, 1, 1, 1)

  local woodRingA = wp("WoodRingA", Vector3.new(0.24, 0.16, 0.24), "Reddish brown", Enum.Material.Wood)
  woodRingA.Color = Color3.fromRGB(97, 55, 35)
  addCylinder(woodRingA, 1.04, 1, 1.04)

  local woodRingB = wp("WoodRingB", Vector3.new(0.22, 0.14, 0.22), "Reddish brown", Enum.Material.Wood)
  woodRingB.Color = Color3.fromRGB(104, 61, 39)
  addCylinder(woodRingB, 1.03, 1, 1.03)

  local shaftLow = wp("ShaftLow", Vector3.new(0.15, 0.80, 0.15), "Reddish brown", Enum.Material.Wood)
  shaftLow.Color = Color3.fromRGB(112, 66, 45)
  addCylinder(shaftLow, 1, 1, 1)

  local shaftMid = wp("WandBody", Vector3.new(0.12, 0.88, 0.12), "Reddish brown", Enum.Material.Wood)
  shaftMid.Color = Color3.fromRGB(124, 74, 52)
  addCylinder(shaftMid, 0.95, 1, 0.95)

  local shaftHigh = wp("ShaftHigh", Vector3.new(0.1, 0.72, 0.1), "Reddish brown", Enum.Material.Wood)
  shaftHigh.Color = Color3.fromRGB(138, 84, 59)
  addCylinder(shaftHigh, 0.9, 1, 0.9)

  local tip = wp("WandTip", Vector3.new(0.06, 0.34, 0.06), "Institutional white", Enum.Material.Neon)
  tip.Color = house.neon
  addCylinder(tip, 0.78, 1, 0.78)

  local pommel = wp("Pommel", Vector3.new(0.24, 0.22, 0.24), "Reddish brown", Enum.Material.Wood)
  pommel.Color = Color3.fromRGB(79, 44, 29)
  addCylinder(pommel, 1.02, 1, 1.02)

  woodRingA.CFrame = handle.CFrame * CFrame.new(0, -0.30, 0)
  woodRingB.CFrame = handle.CFrame * CFrame.new(0, -0.08, 0)
  shaftLow.CFrame = handle.CFrame * CFrame.new(0, 0.9, 0)
  shaftMid.CFrame = shaftLow.CFrame * CFrame.new(0, 0.82, 0)
  shaftHigh.CFrame = shaftMid.CFrame * CFrame.new(0, 0.78, 0)
  tip.CFrame = shaftHigh.CFrame * CFrame.new(0, 0.5, 0)
  pommel.CFrame = handle.CFrame * CFrame.new(0, -0.60, 0)

  for _, part in ipairs({ woodRingA, woodRingB, shaftLow, shaftMid, shaftHigh, tip, pommel }) do
    weld(handle, part)
  end

  -- TipAttachment for particles/effects
  local att = Instance.new("Attachment")
  att.Name = "TipAttachment"
  att.Position = Vector3.new(0, 0.15, 0)
  att.Parent = tip

  -- Ambient magical aura
  local aura = Instance.new("ParticleEmitter")
  aura.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 180)),
    ColorSequenceKeypoint.new(0.45, house.neon),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 255, 255)),
  })
  aura.LightEmission = 1
  aura.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.16),
    NumberSequenceKeypoint.new(0.55, 0.08),
    NumberSequenceKeypoint.new(1, 0),
  })
  aura.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.05),
    NumberSequenceKeypoint.new(1, 1),
  })
  aura.Speed = NumberRange.new(0.4, 2.2)
  aura.SpreadAngle = Vector2.new(28, 28)
  aura.Lifetime = NumberRange.new(0.3, 0.8)
  aura.Rate = 22
  aura.Parent = att

  -- Arc sparks for high detail look
  local sparks = Instance.new("ParticleEmitter")
  sparks.Color = ColorSequence.new(house.neon, Color3.fromRGB(255, 255, 255))
  sparks.LightEmission = 1
  sparks.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.08),
    NumberSequenceKeypoint.new(1, 0),
  })
  sparks.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(1, 1),
  })
  sparks.Speed = NumberRange.new(5, 14)
  sparks.Acceleration = Vector3.new(0, 2, 0)
  sparks.Drag = 3
  sparks.SpreadAngle = Vector2.new(360, 360)
  sparks.Lifetime = NumberRange.new(0.08, 0.2)
  sparks.Rate = 8
  sparks.Parent = att

  -- Glow
  local glow = Instance.new("PointLight")
  glow.Brightness = 4.6
  glow.Color = house.neon
  glow.Range = 10
  glow.Shadows = true
  glow.Parent = tip

  -- Cast burst emitter (enabled on cast)
  local burst = Instance.new("ParticleEmitter")
  burst.Name = "CastBurst"
  burst.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, house.neon),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 255, 180)),
  })
  burst.LightEmission = 1
  burst.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.75),
    NumberSequenceKeypoint.new(0.5, 0.28),
    NumberSequenceKeypoint.new(1, 0),
  })
  burst.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1),
  })
  burst.Speed = NumberRange.new(9, 24)
  burst.SpreadAngle = Vector2.new(360, 360)
  burst.Lifetime = NumberRange.new(0.12, 0.45)
  burst.Rate = 0
  burst.Parent = att

  -- Trail on tip
  local a0 = Instance.new("Attachment")
  a0.Position = Vector3.new(0, 0.16, 0)
  a0.Parent = tip
  local a1 = Instance.new("Attachment")
  a1.Position = Vector3.new(0, -0.16, 0)
  a1.Parent = tip
  local tr = Instance.new("Trail")
  tr.Attachment0 = a0
  tr.Attachment1 = a1
  tr.Lifetime = 0.2
  tr.LightEmission = 1
  tr.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, house.neon),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 255, 170)),
  })
  tr.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.05),
    NumberSequenceKeypoint.new(1, 1),
  })
  tr.WidthScale = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.95),
    NumberSequenceKeypoint.new(0.5, 0.62),
    NumberSequenceKeypoint.new(1, 0),
  })
  tr.Parent = tip

  return wand
end

local function giveFighterSetup(player, houseName)
  local char = player.Character
  if not char then
    return
  end
  local hum = char:FindFirstChildOfClass("Humanoid")
  if hum then
    hum.MaxHealth = PLAYER_HEALTH
    hum.Health = PLAYER_HEALTH
  end
  clearWand(player)
end

--===========================================================
-- PHYSICS: WALL SLAM
--===========================================================
local function wallSlam(char, dir, force, duration)
  if not char then
    return
  end
  local hum = char:FindFirstChildOfClass("Humanoid")
  local hrp = char:FindFirstChild("HumanoidRootPart")
  if not hum or not hrp or hum.Health <= 0 then
    return
  end

  local d = (dir and dir.Magnitude > 0) and dir.Unit or hrp.CFrame.LookVector

  hum:ChangeState(Enum.HumanoidStateType.FallingDown)
  hum.PlatformStand = true
  hrp.AssemblyLinearVelocity = d * force + Vector3.new(0, force * 0.22, 0)

  task.delay(duration or 1.0, function()
    if hum and hum.Parent and hum.Health > 0 then
      hum.PlatformStand = false
      hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
  end)
end

local function damageAndSlam(victimChar, hum, damage, killer, dir, force, duration)
  if not hum or hum.Health <= 0 then
    return false
  end
  hum:TakeDamage(damage)
  if hum.Health <= 0 then
    playSoundAt(victimChar, SFX_DEATH, 1.2)
    registerKill(killer)
    return true
  end
  wallSlam(victimChar, dir, force, duration)
  playSoundAt(victimChar, SFX_HIT, 0.9)
  return false
end

--===========================================================
-- HIT FX PART (client-side burst fx launched from server)
--===========================================================
local function spawnImpactFX(position, spData)
  local fx = Instance.new("Part")
  fx.Size = Vector3.new(1, 1, 1)
  fx.CFrame = CFrame.new(position)
  fx.Anchored = true
  fx.CanCollide = false
  fx.Transparency = 1
  fx.Parent = workspace

  local pe = Instance.new("ParticleEmitter")
  pe.Color = ColorSequence.new(spData.sparkCol)
  pe.LightEmission = 1
  pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
  pe.Speed = NumberRange.new(20, 55)
  pe.Lifetime = NumberRange.new(0.3, 0.9)
  pe.SpreadAngle = Vector2.new(360, 360)
  pe.Parent = fx
  pe:Emit(100)

  local pe2 = pe:Clone()
  pe2.Color = ColorSequence.new(spData.color, Color3.fromRGB(255, 255, 255))
  pe2:Emit(60)
  pe2.Parent = fx

  local pl = Instance.new("PointLight")
  pl.Brightness = 25
  pl.Range = 55
  pl.Color = spData.light
  pl.Parent = fx
  TweenService:Create(pl, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 })
    :Play()

  Debris:AddItem(fx, 2)
end

--===========================================================
-- GENERIC SPELL LAUNCHER
--===========================================================
local function launchSpell(caster, duelInfo, spellName)
  local spData = SPELL_DATA[spellName]
  if not spData then
    return
  end
  local opponent = duelInfo.opponent
  local cChar = caster.Character
  local oChar = opponent and opponent.Character
  if not cChar or not oChar then
    return
  end

  local tipPart = getCastPart(cChar)
  local startPos = tipPart and tipPart.Position or (cChar.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))
  local targetPos = oChar.HumanoidRootPart.Position + Vector3.new(0, 1.0, 0)
  local dir = (targetPos - startPos)
  if dir.Magnitude <= 0 then
    return
  end
  dir = dir.Unit

  -- Trigger wand burst
  if tipPart then
    local burst = tipPart:FindFirstChild("TipAttachment")
      and tipPart:FindFirstChild("TipAttachment"):FindFirstChild("CastBurst")
    if burst then
      burst:Emit(35)
    end
  end
  playSoundAt(cChar, spData.sfx or SFX_CAST, 1)

  -- Create projectile
  local proj = Instance.new("Part")
  proj.Name = spellName .. "Proj"
  proj.Size = spData.projSize
  proj.Color = spData.color
  proj.Material = Enum.Material.Neon
  proj.CanCollide = false
  proj.CanTouch = true
  proj.Anchored = false
  proj.CastShadow = false
  proj.CFrame = CFrame.new(startPos, startPos + dir)
  proj.Parent = workspace

  -- Sphere mesh for round spells
  if spellName == "Stupefy" or spellName == "Reducto" or spellName == "Crucio" or spellName == "Incendio" then
    local m = Instance.new("SpecialMesh")
    m.MeshType = Enum.MeshType.Sphere
    m.Parent = proj
  end

  -- Point light
  local pl = Instance.new("PointLight")
  pl.Brightness = 9
  pl.Range = 22
  pl.Color = spData.light
  pl.Parent = proj

  -- Trail
  local at0 = Instance.new("Attachment")
  at0.Position = Vector3.new(0, 0.1, 0)
  at0.Parent = proj
  local at1 = Instance.new("Attachment")
  at1.Position = Vector3.new(0, -0.1, 0)
  at1.Parent = proj
  local trail = Instance.new("Trail")
  trail.Attachment0 = at0
  trail.Attachment1 = at1
  trail.Lifetime = (spellName == "AvadaKedavra") and 0.65 or 0.28
  trail.LightEmission = 1
  trail.Color =
    ColorSequence.new({ ColorSequenceKeypoint.new(0, spData.trailA), ColorSequenceKeypoint.new(1, spData.trailB) })
  trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
  trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
  trail.Parent = proj

  -- Sparks / particles
  local pe = Instance.new("ParticleEmitter")
  pe.Color =
    ColorSequence.new({ ColorSequenceKeypoint.new(0, spData.sparkCol), ColorSequenceKeypoint.new(1, spData.color) })
  pe.LightEmission = 1
  pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) })
  pe.Speed = NumberRange.new(3, 9)
  pe.Lifetime = NumberRange.new(0.08, 0.28)
  pe.Rate = (spellName == "AvadaKedavra") and 140 or 30
  pe.SpreadAngle = Vector2.new(180, 180)
  pe.Parent = proj

  -- Special: Incendio has Fire
  if spellName == "Incendio" then
    local fire = Instance.new("Fire")
    fire.Heat = 15
    fire.Size = 4
    fire.Color = spData.color
    fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
    fire.Parent = proj
  end
  -- Special: Crucio has extra energy balls effect
  if spellName == "Crucio" then
    local pe2 = Instance.new("ParticleEmitter")
    pe2.Color = ColorSequence.new(Color3.fromRGB(255, 255, 180))
    pe2.LightEmission = 1
    pe2.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
    pe2.Speed = NumberRange.new(8, 20)
    pe2.Lifetime = NumberRange.new(0.15, 0.45)
    pe2.Rate = 25
    pe2.SpreadAngle = Vector2.new(360, 360)
    pe2.Parent = proj
  end
  if spellName == "AvadaKedavra" then
    local smoke = Instance.new("ParticleEmitter")
    smoke.Color = ColorSequence.new(Color3.fromRGB(20, 120, 30), Color3.fromRGB(180, 255, 190))
    smoke.LightEmission = 0.8
    smoke.Size = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 0.5),
      NumberSequenceKeypoint.new(0.6, 0.9),
      NumberSequenceKeypoint.new(1, 0),
    })
    smoke.Transparency = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 0.2),
      NumberSequenceKeypoint.new(1, 1),
    })
    smoke.Speed = NumberRange.new(2, 6)
    smoke.Drag = 4
    smoke.Rate = 70
    smoke.Lifetime = NumberRange.new(0.2, 0.5)
    smoke.Parent = proj

    local ring = Instance.new("ParticleEmitter")
    ring.Color = ColorSequence.new(Color3.fromRGB(140, 255, 140), Color3.fromRGB(0, 255, 30))
    ring.LightEmission = 1
    ring.Texture = "rbxassetid://243660364"
    ring.Size = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 1.4),
      NumberSequenceKeypoint.new(1, 0),
    })
    ring.Transparency = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 0.12),
      NumberSequenceKeypoint.new(1, 1),
    })
    ring.Speed = NumberRange.new(0.5, 1.2)
    ring.RotSpeed = NumberRange.new(-120, 120)
    ring.Rate = 20
    ring.Lifetime = NumberRange.new(0.1, 0.22)
    ring.Parent = proj

    local hum = Instance.new("Sound")
    hum.SoundId = "rbxassetid://9113420771"
    hum.Volume = 0.6
    hum.RollOffMaxDistance = 80
    hum.Parent = proj
    hum:Play()
    Debris:AddItem(hum, 2)
  end

  -- BodyVelocity
  local bv = Instance.new("BodyVelocity")
  bv.Velocity = dir * spData.speed
  bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
  bv.Parent = proj

  -- Hit detection
  local hitDone = false
  proj.Touched:Connect(function(hit)
    if hitDone then
      return
    end
    if not hit or not hit.Parent then
      return
    end
    if hit.Parent == cChar then
      return
    end
    local hp = Players:GetPlayerFromCharacter(hit.Parent)
    if hp ~= opponent then
      return
    end
    hitDone = true

    local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
    local died = damageAndSlam(hit.Parent, hum, spData.damage, caster, dir, spData.kb, spData.kbDur)

    spawnImpactFX(proj.Position, spData)

    RE_SpellEffect:FireClient(caster, spellName .. "_hit", false)
    RE_SpellEffect:FireClient(opponent, spellName .. "_hit", true)

    -- Avada Kedavra: epic extra death FX
    if spellName == "AvadaKedavra" then
      RE_SpellEffect:FireClient(caster, "AvadaKill_cast")
      RE_SpellEffect:FireClient(opponent, "AvadaKill_victim")
    end

    proj:Destroy()
  end)

  Debris:AddItem(proj, 8)
end

--===========================================================
-- CLASH SYSTEM — Priori Incantatem
--===========================================================
local function destroyClashBeam(beam)
  if not beam then
    return
  end
  if beam.Parent then
    beam:Destroy()
  end
end

local function makeClashBeam(p1, p2, col)
  local c1 = p1.Character
  local c2 = p2.Character
  if not c1 or not c2 then
    return nil
  end
  local t1 = getCastPart(c1)
  local t2 = getCastPart(c2)
  if not t1 or not t2 then
    return nil
  end

  local function ensureAtt(tip)
    local a = tip:FindFirstChild("TipAttachment")
      or (function()
        local aa = Instance.new("Attachment")
        aa.Name = "TipAttachment"
        aa.Position = Vector3.new(0, 0.14, 0)
        aa.Parent = tip
        return aa
      end)()
    return a
  end

  local a0 = ensureAtt(t1)
  local a1 = ensureAtt(t2)

  -- Main beam
  local beam = Instance.new("Beam")
  beam.Attachment0 = a0
  beam.Attachment1 = a1
  beam.FaceCamera = true
  beam.Width0 = 0.6
  beam.Width1 = 0.6
  beam.LightEmission = 1
  beam.Segments = 30
  beam.Color = ColorSequence.new(col or Color3.fromRGB(120, 255, 120), Color3.fromRGB(255, 255, 255))
  beam.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.5, 0.1),
    NumberSequenceKeypoint.new(1, 0),
  })
  beam.Parent = t1

  -- Secondary wavy beam
  local beam2 = beam:Clone()
  beam2.Width0 = 0.25
  beam2.Width1 = 0.25
  beam2.CurveSize0 = math.random(2, 6)
  beam2.CurveSize1 = math.random(2, 6)
  beam2.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), col or Color3.fromRGB(120, 255, 120))
  beam2.Parent = t1

  -- Sparks at tips
  local function tipSpark(att, c)
    local sp = Instance.new("ParticleEmitter")
    sp.Color = ColorSequence.new(c)
    sp.LightEmission = 1
    sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
    sp.Speed = NumberRange.new(8, 22)
    sp.Lifetime = NumberRange.new(0.1, 0.3)
    sp.Rate = 120
    sp.SpreadAngle = Vector2.new(360, 360)
    sp.Parent = att
    return sp
  end
  local sp1 = tipSpark(a0, col or Color3.fromRGB(120, 255, 120))
  local sp2 = tipSpark(a1, col or Color3.fromRGB(120, 255, 120))

  -- Midpoint orb
  local mid = Instance.new("Part")
  mid.Anchored = true
  mid.CanCollide = false
  mid.Size = Vector3.new(1.4, 1.4, 1.4)
  mid.Material = Enum.Material.Neon
  mid.Color = col or Color3.fromRGB(120, 255, 120)
  mid.CastShadow = false
  mid.CFrame = CFrame.new((t1.Position + t2.Position) / 2)
  mid.Parent = workspace
  local mesh = Instance.new("SpecialMesh")
  mesh.MeshType = Enum.MeshType.Sphere
  mesh.Parent = mid

  local midLight = Instance.new("PointLight")
  midLight.Brightness = 25
  midLight.Range = 40
  midLight.Color = col or Color3.fromRGB(0, 255, 40)
  midLight.Parent = mid

  local midSp = Instance.new("ParticleEmitter")
  midSp.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
  midSp.LightEmission = 1
  midSp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
  midSp.Speed = NumberRange.new(12, 30)
  midSp.Lifetime = NumberRange.new(0.12, 0.35)
  midSp.Rate = 200
  midSp.SpreadAngle = Vector2.new(360, 360)
  midSp.Parent = mid

  return { beam = beam, beam2 = beam2, sp1 = sp1, sp2 = sp2, mid = mid, t1 = t1, t2 = t2 }
end

local function blendSpellColors(s1, s2)
  local d1 = SPELL_DATA[s1]
  local d2 = SPELL_DATA[s2]
  if not d1 or not d2 then
    return Color3.fromRGB(120, 255, 120)
  end
  local c1 = d1.color
  local c2 = d2.color
  return Color3.fromRGB(
    math.floor((c1.R * 255 + c2.R * 255) / 2),
    math.floor((c1.G * 255 + c2.G * 255) / 2),
    math.floor((c1.B * 255 + c2.B * 255) / 2)
  )
end

local function startClash(p1, spell1, p2, spell2, arenaIdx)
  if clashActive[arenaIdx] then
    return
  end
  clashActive[arenaIdx] = true

  pendingCast[p1] = nil
  pendingCast[p2] = nil

  local beamCol = blendSpellColors(spell1, spell2)
  local vis = makeClashBeam(p1, p2, beamCol)

  freezePlayer(p1, true)
  freezePlayer(p2, true)
  playSoundAt(p1.Character, SFX_CLASH, 1.2)
  playSoundAt(p2.Character, SFX_CLASH, 1.2)

  RE_SpellEffect:FireClient(p1, "ClashStart", spell1, spell2)
  RE_SpellEffect:FireClient(p2, "ClashStart", spell2, spell1)

  -- Determine winner
  local pow1 = (SPELL_DATA[spell1] and SPELL_DATA[spell1].power) or 0
  local pow2 = (SPELL_DATA[spell2] and SPELL_DATA[spell2].power) or 0
  local winnerIdx = (pow1 > pow2) and 1 or (pow2 > pow1) and 2 or math.random(1, 2)

  -- Animate orb moving toward loser over 4 seconds
  local DURATION = 4.0
  local startT = os.clock()

  local conn
  conn = RunService.Heartbeat:Connect(function()
    if not vis then
      if conn then
        conn:Disconnect()
      end
      return
    end
    local t1p = vis.t1 and vis.t1.Parent and vis.t1.Position
    local t2p = vis.t2 and vis.t2.Parent and vis.t2.Position
    if not t1p or not t2p then
      if conn then
        conn:Disconnect()
      end
      return
    end

    local elapsed = os.clock() - startT
    local progress = math.clamp(elapsed / DURATION, 0, 1)
    local orbT = (winnerIdx == 1) and progress or (1 - progress) -- moves toward loser
    orbT = 0.5 + (orbT - 0.5) * 0.9 -- clamp so it doesn't go past tips

    vis.mid.CFrame = CFrame.new(t1p:Lerp(t2p, orbT))

    -- Pulse orb
    local scale = 1.4 + math.sin(elapsed * 8) * 0.3
    vis.mid.Size = Vector3.new(scale, scale, scale)
    vis.mid.CFrame = CFrame.new(t1p:Lerp(t2p, orbT))

    -- Send progress to clients for camera shake intensity
    RE_ClashUpdate:FireClient(p1, progress, winnerIdx == 1)
    RE_ClashUpdate:FireClient(p2, progress, winnerIdx == 2)
  end)

  task.wait(DURATION)
  if conn then
    conn:Disconnect()
  end

  -- Resolve clash
  local winner = (winnerIdx == 1) and p1 or p2
  local loser = (winnerIdx == 1) and p2 or p1
  local wSpell = (winnerIdx == 1) and spell1 or spell2

  -- Big explosion at orb position then cleanup
  if vis and vis.mid and vis.mid.Parent then
    spawnImpactFX(vis.mid.Position, SPELL_DATA[wSpell] or SPELL_DATA.AvadaKedavra)
    vis.sp1:Emit(80)
    vis.sp2:Emit(80)
    task.delay(0.1, function()
      if vis.beam and vis.beam.Parent then
        vis.beam:Destroy()
      end
      if vis.beam2 and vis.beam2.Parent then
        vis.beam2:Destroy()
      end
      if vis.sp1 and vis.sp1.Parent then
        vis.sp1:Destroy()
      end
      if vis.sp2 and vis.sp2.Parent then
        vis.sp2:Destroy()
      end
      if vis.mid and vis.mid.Parent then
        vis.mid:Destroy()
      end
    end)
  end

  RE_SpellEffect:FireClient(p1, "ClashEnd", winnerIdx == 1)
  RE_SpellEffect:FireClient(p2, "ClashEnd", winnerIdx == 2)

  freezePlayer(p1, false)
  freezePlayer(p2, false)
  clashActive[arenaIdx] = false

  task.wait(0.3)

  -- Apply damage to loser
  if playerDuel[winner] and playerDuel[loser] then
    local lchar = loser.Character
    if lchar then
      local hum = lchar:FindFirstChildOfClass("Humanoid")
      if hum then
        local sp = SPELL_DATA[wSpell]
        local dir = loser.Character
            and winner.Character
            and (loser.Character.HumanoidRootPart.Position - winner.Character.HumanoidRootPart.Position).Unit
          or Vector3.new(0, 0, 1)
        damageAndSlam(
          lchar,
          hum,
          sp and sp.damage or 50,
          winner,
          dir,
          (sp and sp.kb or 45) * 1.5,
          (sp and sp.kbDur or 1.5)
        )
        if wSpell == "AvadaKedavra" then
          RE_SpellEffect:FireClient(winner, "AvadaKill_cast")
          RE_SpellEffect:FireClient(loser, "AvadaKill_victim")
        else
          RE_SpellEffect:FireClient(winner, wSpell .. "_hit", false)
          RE_SpellEffect:FireClient(loser, wSpell .. "_hit", true)
        end
      end
    end
  end
end

--===========================================================
-- CAST HANDLER
--===========================================================
RE_CastSpell.OnServerEvent:Connect(function(caster, spellName)
  local duelInfo = playerDuel[caster]
  if not duelInfo then
    return
  end
  if not SPELL_DATA[spellName] then
    return
  end

  local arenaIdx = duelInfo.arenaIdx
  local opponent = duelInfo.opponent
  if not opponent or not playerDuel[opponent] then
    return
  end

  -- Wand cast burst FX on server
  local char = caster.Character
  if char then
    local wand = char:FindFirstChild("Varita Magica")
    if wand then
      wand:SetAttribute("CastSpell", spellName)
      wand:SetAttribute("Casting", true)
      task.delay(0.5, function()
        if wand then
          wand:SetAttribute("Casting", false)
        end
      end)
    end
  end

  local now = os.clock()
  local oppPending = pendingCast[opponent]

  -- Clash check: both cast within CLASH_WINDOW
  if oppPending and (now - oppPending.time) <= CLASH_WINDOW and not clashActive[arenaIdx] then
    pendingCast[caster] = nil
    task.spawn(startClash, opponent, oppPending.spell, caster, spellName, arenaIdx)
    return
  end

  local token = {}
  pendingCast[caster] = { spell = spellName, time = now, token = token }

  task.delay(WINDUP, function()
    local pc = pendingCast[caster]
    if not pc or pc.token ~= token then
      return
    end
    if not playerDuel[caster] or not playerDuel[opponent] then
      pendingCast[caster] = nil
      return
    end
    if clashActive[arenaIdx] then
      pendingCast[caster] = nil
      return
    end
    pendingCast[caster] = nil
    launchSpell(caster, duelInfo, spellName)
  end)
end)

--===========================================================
-- ESTADO PARA LA SEGUNDA MITAD DE ESTE SCRIPT (mundo y rondas)
-- Las tablas van por referencia: la segunda mitad escribe en las mismas
-- tablas que el nucleo lee durante el combate.
--===========================================================
S = { -- antes shared.AvadaDuel; ahora local (Studio Lite bloquea shared)
  squares = squares,
  squareParts = squareParts,
  padStations = padStations,
  arenaData = arenaData,
  playerSquare = playerSquare,
  playerDuel = playerDuel,
  pendingCast = pendingCast,
  clashActive = clashActive,
  playerKills = playerKills,
  LOBBY_SPAWN = LOBBY_SPAWN,
  ROUND_TIME = ROUND_TIME,
  TOTAL_ROUNDS = TOTAL_ROUNDS,
  HOUSES = HOUSES,
  PAD_DATA = PAD_DATA,
  ARENA_CENTERS = ARENA_CENTERS,
  KillsStore = KillsStore,
  KillsOrdered = KillsOrdered,
  RE_BattleStart = RE_BattleStart,
  RE_BattleEnd = RE_BattleEnd,
  RE_CastSpell = RE_CastSpell,
  RE_Countdown = RE_Countdown,
  RE_RoundUpdate = RE_RoundUpdate,
  RE_SpellEffect = RE_SpellEffect,
  RE_ClashUpdate = RE_ClashUpdate,
  freezePlayer = freezePlayer,
  teleportTo = teleportTo,
  returnToLobby = returnToLobby,
  giveFighterSetup = giveFighterSetup,
  loadKills = loadKills,
  saveKills = saveKills,
  registerKill = registerKill,
}
print("⚡ [DuelGame] Nucleo listo (todo en uno) ⚡")
end
do
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
end
do
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

-- Solo necesita el DataStore de kills para la tabla (con respaldo si
-- Studio Lite no deja usarlo en Play).
-- (pads eliminados: la partida se crea en el circulo central)
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
if not LobbyModel then
  LobbyModel = Instance.new("Model")
  LobbyModel.Name = "IslandLobby"
  LobbyModel.Parent = workspace
end

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
  if math.abs(z - x) > 7.5 and math.abs(z + x) > 7.5 and not (z > 36 and math.abs(x) < 28) then
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

local nameCache = {}
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
        if nameCache[uid] then
          dName = nameCache[uid]
        else
          local plrNow = Players:GetPlayerByUserId(uid)
          if plrNow then
            dName = plrNow.Name
            nameCache[uid] = dName
          else
            local okN, nR = pcall(function()
              return Players:GetNameByUserIdAsync(uid)
            end)
            if okN and nR and nR ~= "" then
              dName = nR
              nameCache[uid] = nR
            end
          end
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
      Vector3.new(4.0, 2.9, 0.35),
      CFrame.new(PX + sd * 2.5, GY + 5.2, PZ + 1.05) * CFrame.Angles(0, 0, math.rad(sd * 26)),
      Color3.fromRGB(11, 10, 18),
      false
    )
    wedge(
      "GargWingB",
      Vector3.new(2.8, 2.0, 0.3),
      CFrame.new(PX + sd * 4.6, GY + 6.1, PZ + 1.05) * CFrame.Angles(0, 0, math.rad(sd * 50)),
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
    -- (Sin postes: el letrero va montado directo sobre el arco)
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
end
print("✅ [Avada] TODO EN UNO activo: nucleo + circulo + isla + tabla")

-- FIN TODO EN UNO
