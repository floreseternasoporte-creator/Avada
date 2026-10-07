--===========================================================
-- AVADA DUELING - ARCHIVO 1 de 2: JUEGO
-- Pega TODO este archivo en UN Script de ServerScriptService
-- (el nombre da igual). El otro Script lleva el archivo de la ISLA.
-- Incluye: nucleo de combate + circulo central + arenas + rondas.
-- Si el pegado no llega hasta la ultima linea (-- FIN JUEGO), se corto.
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
local survivalCastHook = nil

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
  if survivalCastHook and survivalCastHook(caster, spellName) then
    return
  end
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
print("[DuelGame] Nucleo listo (archivo de juego)")
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

-- Verificacion: cada pieza del nucleo debe existir (si falta, el Output la nombra)
do
  local faltan = {}
  for nombre, valor in pairs({
    arenaData = arenaData,
    playerDuel = playerDuel,
    pendingCast = pendingCast,
    freezePlayer = freezePlayer,
    teleportTo = teleportTo,
    returnToLobby = returnToLobby,
    giveFighterSetup = giveFighterSetup,
    loadKills = loadKills,
    saveKills = saveKills,
    RE_BattleStart = RE_BattleStart,
    RE_BattleEnd = RE_BattleEnd,
    RE_Countdown = RE_Countdown,
    RE_RoundUpdate = RE_RoundUpdate,
  }) do
    if valor == nil then
      table.insert(faltan, nombre)
    end
  end
  if #faltan > 0 then
    warn("[Avada] FALTAN piezas del nucleo: " .. table.concat(faltan, ", "))
  else
    print("[Avada] Nucleo verificado: todas las piezas presentes")
  end
end

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
      p.Material = Enum.Material.Plastic
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
    end
  end
end

-- Cartel sobre el circulo del lobby
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
-- ESTADO DE LA PARTIDA
--===========================================================
local NOCHES_META = 7
local NOCHE_LEN = 140
local DIA_LEN = 50
local FC = Vector3.new(0, 0, 4200) -- centro del bosque (lejos del lobby)

local SE = {
  on = false,
  cuentaAtras = 0,
  enCirculo = {},
  players = {}, -- [player] = {vivo, lenos, hambre}
  sombras = {}, -- lista de criaturas vivas
  noche = 0,
  fase = "dia",
  llama = 100,
  aprendices = 0,
}
local castCd = {}

local function jugadorEnPartida(player)
  return SE.on and SE.players[player] ~= nil
end

local function vivosEnPartida()
  local n = 0
  for _, d in pairs(SE.players) do
    if d.vivo then
      n += 1
    end
  end
  return n
end

--===========================================================
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
bcyl("BosqueGrass", 2.0, 470, CFrame.new(FC.X, 1.0, FC.Z), Color3.fromRGB(74, 148, 60), true)
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
  table.insert(anilloSeguro, { part = seg, ang = a })
end
-- Zona de deposito de lenos (toca aqui con lenos en la mano)
local deposito = bp("FireDeposit", Vector3.new(4.5, 0.4, 4.5), CFrame.new(fuegoPos.X, fuegoPos.Y + 0.2, fuegoPos.Z + 8.5), Color3.fromRGB(140, 92, 50), false)

-- Cartel del campamento
local fireAnchor = bp("FireBoardAnchor", Vector3.new(1, 1, 1), CFrame.new(fuegoPos.X, fuegoPos.Y + 11, fuegoPos.Z), Color3.fromRGB(255, 255, 255), false)
fireAnchor.Transparency = 1
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
for i = 1, 130 do
  local a = rngBosque:NextNumber(0, math.pi * 2)
  local r = rngBosque:NextNumber(30, 214)
  local x, z = FC.X + math.cos(a) * r, FC.Z + math.sin(a) * r
  if lejosDeJaulas(x, z) then
    local th = rngBosque:NextNumber(4.5, 7.5)
    bcyl("TreeTrunk", th, 1.3, CFrame.new(x, 2.0 + th / 2, z), Color3.fromRGB(106, 70, 40), true)
    local verdes = { Color3.fromRGB(52, 128, 48), Color3.fromRGB(64, 148, 56), Color3.fromRGB(44, 110, 42) }
    local lw = rngBosque:NextNumber(4.6, 6.2)
    bp("TreeLeaf", Vector3.new(lw, lw * 0.55, lw), CFrame.new(x, 2.0 + th + lw * 0.25, z), verdes[(i % 3) + 1], false)
    bp("TreeLeaf", Vector3.new(lw * 0.66, lw * 0.5, lw * 0.66), CFrame.new(x, 2.0 + th + lw * 0.72, z), verdes[((i + 1) % 3) + 1], false)
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
  table.insert(cofres, { pos = cp, listo = 0, base = chestBase })
end

-- Nodos de lena (troncos caidos que se recogen tocandolos)
local lenaNodos = {}
for i = 1, 16 do
  local a = (i / 16) * math.pi * 2 + 0.3
  local r = 40 + (i % 4) * 45
  local np = Vector3.new(FC.X + math.cos(a) * r, 2.0, FC.Z + math.sin(a) * r)
  local log = bcyl("FallenLog", 5.2, 1.1, CFrame.new(np.X, np.Y + 0.6, np.Z) * CFrame.Angles(math.rad(90), a, 0), Color3.fromRGB(128, 84, 46), false)
  table.insert(lenaNodos, { part = log, pos = np, listoEn = 0 })
end

-- Arbustos de bayas (tocar: comida)
local bayas = {}
for i = 1, 10 do
  local a = (i / 10) * math.pi * 2 + 0.9
  local r = 55 + (i % 3) * 50
  local np = Vector3.new(FC.X + math.cos(a) * r, 2.0, FC.Z + math.sin(a) * r)
  bball("BerryBush", 3.0, CFrame.new(np.X, np.Y + 1.4, np.Z), Color3.fromRGB(46, 116, 44), false)
  local frutos = {}
  for j = 1, 5 do
    local fb = bp(
      "Berry",
      Vector3.new(0.55, 0.55, 0.55),
      CFrame.new(np.X + math.cos(j * 2.2) * 1.3, np.Y + 2.2 + math.sin(j * 3.1) * 0.5, np.Z + math.sin(j * 2.2) * 1.3),
      Color3.fromRGB(235, 60, 80),
      false
    )
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
    table.insert(barrotes, bar)
    local bar2 = bcyl("CageBar", 6.4, 0.42, CFrame.new(jp.X + 4.55, jp.Y + 4.0, jp.Z - 4.55 + b * 1.3), Color3.fromRGB(52, 52, 62), false)
    table.insert(barrotes, bar2)
  end
  bp("CageRoof", Vector3.new(11, 0.7, 11), CFrame.new(jp.X, jp.Y + 7.5, jp.Z), Color3.fromRGB(70, 66, 80), false)
  local fig = figuraAprendiz(ROPAS[ci])
  for _, pp in ipairs(fig:GetChildren()) do
    local offp = pp.CFrame.Position
    pp.CFrame = CFrame.new(jp.X + offp.X, jp.Y + 0.8 + offp.Y, jp.Z + offp.Z)
  end
  local jAnchor = bp("CageAnchor", Vector3.new(1, 1, 1), CFrame.new(jp.X, jp.Y + 10, jp.Z), Color3.fromRGB(255, 255, 255), false)
  jAnchor.Transparency = 1
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

--===========================================================
-- CARTELES
--===========================================================
local function updateCircleBoard()
  if SE.on then
    circleTitle.Text = "PARTIDA EN CURSO"
    circleStatus.Text = "Noche " .. math.max(SE.noche, 1) .. " de " .. NOCHES_META .. " - Llama al " .. math.floor(SE.llama) .. "%"
    circleSub.Text = "La siguiente partida empieza al terminar esta"
  elseif SE.cuentaAtras > 0 then
    circleTitle.Text = "BOSQUE PROHIBIDO"
    circleStatus.Text = "La partida empieza en " .. math.ceil(SE.cuentaAtras) .. "..."
    local n = 0
    for _ in pairs(SE.enCirculo) do
      n += 1
    end
    circleSub.Text = n .. " mago(s) entrando - entra tu tambien"
  else
    circleTitle.Text = "BOSQUE PROHIBIDO"
    circleStatus.Text = "Párate en el círculo para entrar"
    circleSub.Text = "Sobrevive 7 noches - Rescata a los 4 aprendices"
  end
end

local function updateFireBoard()
  fireStatus.Text = "Llama "
    .. math.floor(SE.llama)
    .. "% - Noche "
    .. math.max(SE.noche, 1)
    .. "/"
    .. NOCHES_META
    .. " - Aprendices "
    .. SE.aprendices
    .. "/4"
  -- la llama crece y el anillo seguro respira con ella
  local f = 0.35 + (SE.llama / 100) * 0.85
  for i, fp in ipairs(llamaParts) do
    local b = llamaBase[i]
    fp.Size = Vector3.new(b.X * f, b.Y * f, b.Z * f)
    fp.CFrame = CFrame.new(fuegoPos.X, fuegoPos.Y + 0.7 + (i - 1) * 1.4 * f, fuegoPos.Z)
  end
  llamaLight.Range = 16 + SE.llama * 0.2
  local radio = 9 + SE.llama * 0.11
  for _, sd in ipairs(anilloSeguro) do
    sd.part.CFrame = CFrame.new(fuegoPos.X, fuegoPos.Y + 0.12, fuegoPos.Z) * CFrame.Angles(0, -sd.ang, 0) * CFrame.new(0, 0, radio)
  end
end

local function radioSeguro()
  return 9 + SE.llama * 0.11
end

--===========================================================
-- SOMBRAS (las criaturas de la noche)
--===========================================================
local function crearSombra(pos, esGuardian, jaulaIdx)
  local model = Instance.new("Model")
  model.Name = "Sombra"
  local root = Instance.new("Part")
  root.Name = "Root"
  root.Size = Vector3.new(2.1, 3.2, 1.1)
  root.BrickColor = BrickColor.new("White")
  root.Color = Color3.fromRGB(18, 16, 28)
  root.Material = Enum.Material.SmoothPlastic
  root.Anchored = true
  root.CanCollide = false
  root.CastShadow = false
  root.CFrame = CFrame.new(pos)
  root.Parent = model
  local head = Instance.new("Part")
  head.Name = "Head"
  head.Size = Vector3.new(1.5, 1.3, 1.3)
  head.BrickColor = BrickColor.new("White")
  head.Color = Color3.fromRGB(13, 12, 22)
  head.Material = Enum.Material.SmoothPlastic
  head.Anchored = true
  head.CanCollide = false
  head.CastShadow = false
  head.CFrame = CFrame.new(pos + Vector3.new(0, 2.25, 0))
  head.Parent = model
  local ojos = {}
  for _, sd in ipairs({ -0.35, 0.35 }) do
    local eye = Instance.new("Part")
    eye.Name = "Eye"
    eye.Size = Vector3.new(0.28, 0.2, 0.1)
    eye.BrickColor = BrickColor.new("White")
    eye.Color = Color3.fromRGB(255, 64, 84)
    eye.Material = Enum.Material.Neon
    eye.Anchored = true
    eye.CanCollide = false
    eye.CastShadow = false
    eye.CFrame = CFrame.new(pos + Vector3.new(sd, 2.35, 0.68))
    eye.Parent = model
    table.insert(ojos, { part = eye, off = Vector3.new(sd, 2.35, 0.68) })
  end
  local gl = Instance.new("BillboardGui")
  gl.Size = UDim2.new(5, 0, 1, 0)
  gl.StudsOffset = Vector3.new(0, 3.4, 0)
  gl.AlwaysOnTop = true
  gl.LightInfluence = 0
  gl.MaxDistance = 90
  gl.Parent = root
  local glLbl = Instance.new("TextLabel")
  glLbl.Size = UDim2.new(1, 0, 1, 0)
  glLbl.BackgroundTransparency = 1
  glLbl.Font = Enum.Font.GothamBold
  glLbl.TextScaled = true
  glLbl.TextColor3 = Color3.fromRGB(255, 120, 130)
  glLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  glLbl.TextStrokeTransparency = 0.3
  glLbl.Text = "Sombra"
  glLbl.Parent = gl
  model.Parent = workspace
  clasicoEn(model)
  local hp = esGuardian and 220 or (90 + SE.noche * 25)
  local som = {
    model = model,
    root = root,
    head = head,
    ojos = ojos,
    label = glLbl,
    hp = hp,
    hpMax = hp,
    guardian = esGuardian,
    jaula = jaulaIdx,
    golpeEn = 0,
  }
  table.insert(SE.sombras, som)
  return som
end

local function matarSombra(som, killer)
  for i, s2 in ipairs(SE.sombras) do
    if s2 == som then
      table.remove(SE.sombras, i)
      break
    end
  end
  if killer then
    registerKill(killer)
  end
  if som.guardian and som.jaula then
    local quedan = false
    for _, s2 in ipairs(SE.sombras) do
      if s2.guardian and s2.jaula == som.jaula then
        quedan = true
        break
      end
    end
    if not quedan then
      local j = jaulas[som.jaula]
      if j and not j.libre then
        j.libre = true
        for _, bar in ipairs(j.barrotes) do
          bar.Transparency = 0.75
          bar.CanCollide = false
        end
        j.label.Text = "Jaula abierta: toca al aprendiz"
      end
    end
  end
  if som.model then
    som.model:Destroy()
  end
end

local function danarSombra(som, dmg, de, player)
  som.hp -= dmg
  if som.label then
    som.label.Text = "Sombra " .. math.max(math.floor(som.hp), 0) .. "/" .. som.hpMax
  end
  if som.root and som.root.Parent then
    local dir = (som.root.Position - de).Unit
    dir = Vector3.new(dir.X, 0, dir.Z)
    som.root.CFrame = som.root.CFrame + dir * 1.6
    if som.head then
      som.head.CFrame = som.head.CFrame + dir * 1.6
    end
    if som.ojos then
      for _, oj in ipairs(som.ojos) do
        oj.part.CFrame = oj.part.CFrame + dir * 1.6
      end
    end
    local old = som.root.Color
    som.root.Color = Color3.fromRGB(255, 240, 240)
    task.delay(0.08, function()
      if som.root and som.root.Parent then
        som.root.Color = old
      end
    end)
  end
  if som.hp <= 0 then
    matarSombra(som, player)
  end
end

-- Hechizos contra las Sombras (sin duelo: golpea la mas cercana)
survivalCastHook = function(caster, spellName)
  if not jugadorEnPartida(caster) then
    return false
  end
  if not SE.players[caster].vivo then
    return true
  end
  if not SPELL_DATA[spellName] then
    return true
  end
  local char = caster.Character
  if not char then
    return true
  end
  local wand = char:FindFirstChild("Varita Magica")
  if wand then
    wand:SetAttribute("CastSpell", spellName)
    wand:SetAttribute("Casting", true)
    task.delay(0.5, function()
      if wand and wand.Parent then
        wand:SetAttribute("Casting", false)
      end
    end)
  end
  local now = os.clock()
  if castCd[caster] and now - castCd[caster] < 0.5 then
    return true
  end
  castCd[caster] = now
  local hrp = char:FindFirstChild("HumanoidRootPart")
  if not hrp then
    return true
  end
  local best, bestD
  for _, som in ipairs(SE.sombras) do
    if som.root and som.root.Parent then
      local d = (som.root.Position - hrp.Position).Magnitude
      if d <= 34 and (not bestD or d < bestD) then
        best, bestD = som, d
      end
    end
  end
  if best then
    local dmg = SPELL_DATA[spellName].damage or 40
    if spellName ~= "AvadaKedavra" then
      dmg = math.floor(dmg * 1.4)
    end
    danarSombra(best, dmg, hrp.Position, caster)
  end
  return true
end

--===========================================================
-- FLUJO DE LA PARTIDA
--===========================================================
local LightingSvc = game:GetService("Lighting")

local function volverAlLobby(player)
  local char = player and player.Character
  if char then
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
      hum.Health = hum.MaxHealth
    end
    if hrp then
      hrp.CFrame = CFrame.new(LOBBY_SPAWN + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
    end
  end
end

local function finPartida(victoria)
  if not SE.on then
    return
  end
  SE.on = false
  for i = #SE.sombras, 1, -1 do
    local som = SE.sombras[i]
    if som.model then
      som.model:Destroy()
    end
    table.remove(SE.sombras, i)
  end
  LightingSvc.ClockTime = 13.2
  LightingSvc.FogEnd = 100000
  if victoria then
    circleTitle.Text = "BOSQUE SUPERADO"
    circleStatus.Text = "Los magos vencieron las " .. NOCHES_META .. " noches"
  else
    circleTitle.Text = "BOSQUE PROHIBIDO"
    circleStatus.Text = "La partida termino en la noche " .. math.max(SE.noche, 1)
  end
  circleSub.Text = "Párate en el círculo para jugar otra vez"
  for player, _ in pairs(SE.players) do
    volverAlLobby(player)
  end
  SE.players = {}
  SE.cuentaAtras = 0
  SE.enCirculo = {}
  task.delay(6, function()
    if not SE.on then
      updateCircleBoard()
    end
  end)
end

local function marcarMuerto(player)
  local d = SE.players[player]
  if not d or not d.vivo then
    return
  end
  d.vivo = false
  volverAlLobby(player)
  if vivosEnPartida() <= 0 then
    finPartida(false)
  end
end

local function nocheSombras()
  local total = math.min(2 + SE.noche, 10)
  for i = 1, total do
    local a = math.random() * math.pi * 2
    local pos = Vector3.new(FC.X + math.cos(a) * 205, 5.5, FC.Z + math.sin(a) * 205)
    crearSombra(pos, false, nil)
  end
end

local function cicloPartida()
  while SE.on do
    -- DIA
    SE.fase = "dia"
    LightingSvc.ClockTime = 13.2
    LightingSvc.FogEnd = 100000
    updateFireBoard()
    local tDia = 0
    while SE.on and tDia < DIA_LEN do
      task.wait(1)
      tDia += 1
      for player, d in pairs(SE.players) do
        if d.vivo then
          d.hambre = math.max(0, d.hambre - 0.5)
          if d.hambre <= 0 then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
              hum:TakeDamage(1.5)
            end
          end
        end
      end
    end
    if not SE.on then
      break
    end
    -- NOCHE
    SE.noche += 1
    SE.fase = "noche"
    LightingSvc.ClockTime = 0.4
    LightingSvc.FogColor = Color3.fromRGB(16, 18, 34)
    LightingSvc.FogStart = 20
    LightingSvc.FogEnd = 110
    nocheSombras()
    updateFireBoard()
    updateCircleBoard()
    local tNoche = 0
    local nocheDur = math.max(NOCHE_LEN - SE.aprendices * 12, 70)
    while SE.on and tNoche < nocheDur do
      task.wait(1)
      tNoche += 1
      -- la llama se consume mas rapido de noche
      SE.llama = math.max(0, SE.llama - (100 / (NOCHE_LEN * 1.25)))
      for player, d in pairs(SE.players) do
        if d.vivo then
          d.hambre = math.max(0, d.hambre - 0.8)
          if d.hambre <= 0 then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
              hum:TakeDamage(2)
            end
          end
        end
      end
      if SE.llama <= 0 then
        circleStatus.Text = "LA LLAMA SE APAGO - fin de la partida"
        task.wait(2)
        finPartida(false)
        return
      end
      updateFireBoard()
    end
    if not SE.on then
      break
    end
    -- amanecer: las sombras de la noche se queman
    for i = #SE.sombras, 1, -1 do
      local som = SE.sombras[i]
      if not som.guardian then
        if som.model then
          som.model:Destroy()
        end
        table.remove(SE.sombras, i)
      end
    end
    if SE.noche >= NOCHES_META then
      finPartida(true)
      return
    end
    updateCircleBoard()
  end
end

local function bucleSombras()
  while true do
    task.wait(0.25)
    if SE.on then
      for _, som in ipairs(SE.sombras) do
        if som.root and som.root.Parent then
          -- objetivo: el mago vivo mas cercano
          local bestP, bestD, bestPos
          for player, d in pairs(SE.players) do
            if d.vivo and player.Character then
              local hrp = player.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                local dist = (hrp.Position - som.root.Position).Magnitude
                if not bestD or dist < bestD then
                  bestP, bestD, bestPos = player, dist, hrp.Position
                end
              end
            end
          end
          -- los guardianes no se alejan de su jaula
          if som.guardian and som.jaula then
            local jp = jaulas[som.jaula].pos
            if (som.root.Position - jp).Magnitude > 60 then
              bestPos = Vector3.new(jp.X, som.root.Position.Y, jp.Z)
              bestD = (bestPos - som.root.Position).Magnitude
            end
          end
          if bestPos then
            local rp = som.root.Position
            local dfx, dfz = rp.X - fuegoPos.X, rp.Z - fuegoPos.Z
            local toFire = math.sqrt(dfx * dfx + dfz * dfz)
            local destino = bestPos
            -- la llama protege: no entran al anillo mientras arda
            if SE.llama > 0 then
              local pfx, pfz = bestPos.X - fuegoPos.X, bestPos.Z - fuegoPos.Z
              local pf = math.sqrt(pfx * pfx + pfz * pfz)
              if pf < radioSeguro() + 1 then
                local dx, dz = dfx, dfz
                local dm = math.sqrt(dx * dx + dz * dz)
                if dm < 1 then
                  dx, dz, dm = 1, 0, 1
                end
                local rr = radioSeguro() + 2.5
                destino = Vector3.new(fuegoPos.X + (dx / dm) * rr, rp.Y, fuegoPos.Z + (dz / dm) * rr)
              end
            end
            local dir = destino - rp
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude > 0.15 then
              local paso = dir.Unit * math.min(dir.Magnitude, (11 + SE.noche * 0.5) * 0.25)
              local nuevo = rp + paso
              local cf = CFrame.new(nuevo, nuevo + dir.Unit)
              som.root.CFrame = cf
              if som.head then
                som.head.CFrame = cf * CFrame.new(0, 2.25, 0)
              end
              if som.ojos then
                for _, oj in ipairs(som.ojos) do
                  oj.part.CFrame = cf * CFrame.new(oj.off)
                end
              end
              rp = nuevo
            end
            -- golpe al mago
            if bestP and bestD and bestD <= 3.4 and SE.players[bestP] and SE.players[bestP].vivo then
              local now = os.clock()
              if now - (som.golpeEn or 0) >= 0.9 then
                som.golpeEn = now
                local hum = bestP.Character and bestP.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                  hum:TakeDamage(8)
                end
              end
            end
            -- el fuego las quema si entran al campamento
            if SE.llama > 25 and toFire < 6 then
              danarSombra(som, 30, fuegoPos, nil)
            end
          end
        end
      end
    end
  end
end
task.spawn(bucleSombras)

-- Recursos: recoger con el toque
local function conectarToques()
  local function jugadorDe(hit)
    local char = hit and hit.Parent
    local player = char and Players:GetPlayerFromCharacter(char)
    return player
  end
  for _, nodo in ipairs(lenaNodos) do
    nodo.part.Touched:Connect(function(hit)
      if not SE.on or os.clock() < nodo.listoEn then
        return
      end
      local player = jugadorDe(hit)
      if player and jugadorEnPartida(player) and SE.players[player].vivo then
        SE.players[player].lenos += 1
        nodo.listoEn = os.clock() + 25
        nodo.part.Transparency = 1
        nodo.part.CanCollide = false
        task.delay(25, function()
          nodo.part.Transparency = 0
          nodo.part.CanCollide = false
        end)
      end
    end)
  end
  for _, b in ipairs(bayas) do
    for _, fb in ipairs(b.frutos) do
      fb.Touched:Connect(function(hit)
        if not SE.on or os.clock() < b.listoEn then
          return
        end
        local player = jugadorDe(hit)
        if player and jugadorEnPartida(player) and SE.players[player].vivo then
          SE.players[player].hambre = math.min(100, SE.players[player].hambre + 30)
          b.listoEn = os.clock() + 15
          for _, f2 in ipairs(b.frutos) do
            f2.Transparency = 1
          end
          task.delay(15, function()
            for _, f2 in ipairs(b.frutos) do
              f2.Transparency = 0
            end
          end)
        end
      end)
    end
  end
  deposito.Touched:Connect(function(hit)
    if not SE.on then
      return
    end
    local player = jugadorDe(hit)
    if player and jugadorEnPartida(player) and SE.players[player].vivo then
      local d = SE.players[player]
      if d.lenos > 0 then
        SE.llama = math.min(100, SE.llama + d.lenos * 18)
        d.lenos = 0
        updateFireBoard()
      end
    end
  end)
  -- jaulas: tocar al aprendiz cuando la jaula esta abierta
  for ci, j in ipairs(jaulas) do
    for _, pp in ipairs(j.fig:GetChildren()) do
      if pp:IsA("BasePart") then
        pp.Touched:Connect(function(hit)
          if not SE.on or not j.libre or j.rescatado then
            return
          end
          local player = jugadorDe(hit)
          if player and jugadorEnPartida(player) and SE.players[player].vivo then
            j.rescatado = true
            SE.aprendices += 1
            j.label.Text = "Aprendiz rescatado"
            -- el aprendiz se muda junto a la fogata
            local ang = ci * (math.pi / 2) + 0.4
            local dest = Vector3.new(fuegoPos.X + math.cos(ang) * 11, fuegoPos.Y, fuegoPos.Z + math.sin(ang) * 11)
            for _, f2 in ipairs(j.fig:GetChildren()) do
              local off = f2.CFrame.Position - j.pos
              f2.CFrame = CFrame.new(dest + Vector3.new(off.X, off.Y - 0.8, off.Z)) * CFrame.Angles(0, -ang - math.pi / 2, 0)
            end
            updateFireBoard()
            updateCircleBoard()
          end
        end)
      end
    end
  end
end
conectarToques()

-- Cofres: toque en la base (hambre o lenos, cada 30 s)
for _, cof in ipairs(cofres) do
  if cof.base then
    cof.base.Touched:Connect(function(hit)
      if not SE.on or os.clock() < cof.listo then
        return
      end
      local char = hit and hit.Parent
      local player = char and Players:GetPlayerFromCharacter(char)
      if player and jugadorEnPartida(player) and SE.players[player].vivo then
        cof.listo = os.clock() + 30
        if math.random() < 0.5 then
          SE.players[player].lenos += 2
        else
          SE.players[player].hambre = math.min(100, SE.players[player].hambre + 40)
        end
      end
    end)
  end
end

local function prepararMundo()
  SE.llama = 100
  SE.noche = 0
  SE.aprendices = 0
  for i = #SE.sombras, 1, -1 do
    if SE.sombras[i].model then
      SE.sombras[i].model:Destroy()
    end
    table.remove(SE.sombras, i)
  end
  for ci, j in ipairs(jaulas) do
    j.libre = false
    j.rescatado = false
    for _, bar in ipairs(j.barrotes) do
      bar.Transparency = 0
      bar.CanCollide = false
    end
    j.label.Text = "Aprendiz atrapado: vence a sus guardianes"
    -- figura de vuelta en la jaula
    for _, pp in ipairs(j.fig:GetChildren()) do
      local offY = ({ Piernas = 0.55, Tunica = 1.95, Cabeza = 3.3, Sombrero = 4.05 })[pp.Name] or 1
      pp.CFrame = CFrame.new(j.pos.X, j.pos.Y + 0.8 + offY, j.pos.Z)
    end
    -- guardianes de la jaula
    crearSombra(j.pos + Vector3.new(-7, 3.5, -7), true, ci)
    crearSombra(j.pos + Vector3.new(7, 3.5, -7), true, ci)
  end
  updateFireBoard()
end

local function iniciarPartida(lista)
  SE.on = true
  SE.players = {}
  prepararMundo()
  local k = 0
  for _, player in ipairs(lista) do
    if player and player.Parent then
      k += 1
      SE.players[player] = { vivo = true, lenos = 0, hambre = 100 }
      local char = player.Character
      if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
          hum.Health = hum.MaxHealth
          hum.Died:Connect(function()
            marcarMuerto(player)
          end)
        end
        if hrp then
          local ang = (k / math.max(#lista, 1)) * math.pi * 2
          hrp.CFrame = CFrame.new(fuegoPos + Vector3.new(math.cos(ang) * 9, 1.5, math.sin(ang) * 9))
        end
      end
    end
  end
  updateCircleBoard()
  task.spawn(cicloPartida)
end

-- Circulo del lobby: quien este dentro cuando la cuenta llega a 0, entra
task.spawn(function()
  while true do
    task.wait(0.3)
    if not SE.on then
      local dentro = {}
      for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
          local flat = Vector2.new(hrp.Position.X, hrp.Position.Z)
          if flat.Magnitude <= 12.5 and hrp.Position.Y > 1 and hrp.Position.Y < 14 then
            dentro[player] = true
          end
        end
      end
      SE.enCirculo = dentro
      local n = 0
      for _ in pairs(dentro) do
        n += 1
      end
      if n >= 1 and SE.cuentaAtras <= 0 then
        SE.cuentaAtras = 12
      end
      if SE.cuentaAtras > 0 then
        SE.cuentaAtras -= 0.3
        if SE.cuentaAtras <= 0 then
          local lista = {}
          for player, _ in pairs(dentro) do
            table.insert(lista, player)
          end
          if #lista >= 1 then
            iniciarPartida(lista)
          end
        end
      end
      updateCircleBoard()
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
    castCd[player] = nil
    local hrp = char:WaitForChild("HumanoidRootPart")
    task.wait(0.15)
    if jugadorEnPartida(player) and SE.players[player].vivo then
      -- reaparecio estando vivo en el bosque: cuenta como caido
      marcarMuerto(player)
      return
    end
    hrp.CFrame = CFrame.new(LOBBY_SPAWN + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
  end)
end)

Players.PlayerRemoving:Connect(function(player)
  saveKills(player)
  if SE.players[player] then
    SE.players[player] = nil
    if SE.on and vivosEnPartida() <= 0 then
      finPartida(false)
    end
  end
  SE.enCirculo[player] = nil
end)

task.spawn(function()
  while true do
    task.wait(60)
    for _, plr in ipairs(Players:GetPlayers()) do
      saveKills(plr)
    end
  end
end)

print("[Avada] Bosque Prohibido listo: supervivencia de magos en 7 noches")

-- FIN PARTE 1
end

-- FIN JUEGO
