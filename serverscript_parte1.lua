--===========================================================
-- AVADA DUELING - SERVER PARTE 1 DE 2: NUCLEO, COMBATE Y JUEGO
-- Coloca en: ServerScriptService > Script (nombre sugerido: AvadaParte1)
-- Pega TAMBIEN la Parte 2 (la visual: isla y tabla) en OTRO Script.
-- Este script es AUTOSUFICIENTE: ya no usa "shared" (Studio Lite lo bloquea),
-- por eso el nucleo y el juego viven juntos aqui como en el original.
-- Si el pegado no llega hasta la ultima linea (-- FIN PARTE 1), se corto.
--===========================================================
 
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")
local RunService        = game:GetService("RunService")
local DataStoreService  = game:GetService("DataStoreService")
local TweenService      = game:GetService("TweenService")
 
--===========================================================
-- CONFIG
--===========================================================
local LOBBY_SPAWN   = Vector3.new(0, 6, 0)
local PLAYER_HEALTH = 100
local ROUND_TIME    = 60
local TOTAL_ROUNDS  = 3
 
local CLASH_WINDOW = 0.30
local WINDUP       = 0.16
 
-- SFX IDs
local SFX_CAST   = "rbxassetid://109707041985625"
local SFX_DEATH  = "rbxassetid://120717906835357"
local SFX_HIT    = "rbxassetid://5982271945"
local SFX_CLASH  = "rbxassetid://6518811702"
local SFX_AVADA  = "rbxassetid://6026980735"
local SFX_EXPELL = "rbxassetid://6026982406"
 
--===========================================================
-- SPELLS (nuevos hechizos auténticos de Harry Potter)
--===========================================================
local SPELL_DATA = {
Expelliarmus = {
damage   = 30,  power  = 30, speed = 70, cdKey = "Expelliarmus",
color    = Color3.fromRGB(255, 50, 50),
light    = Color3.fromRGB(255, 90, 90),
trailA   = Color3.fromRGB(255, 110, 110),
trailB   = Color3.fromRGB(180, 0, 0),
sparkCol = Color3.fromRGB(255, 150, 150),
projSize = Vector3.new(0.35, 0.35, 1.8),
kb = 35, kbUp = 15, kbDur = 1.1,
sfx = SFX_EXPELL,
},
Stupefy = {
damage   = 45,  power  = 45, speed = 62, cdKey = "Stupefy",
color    = Color3.fromRGB(255, 70, 20),
light    = Color3.fromRGB(255, 110, 40),
trailA   = Color3.fromRGB(255, 140, 60),
trailB   = Color3.fromRGB(200, 60, 0),
sparkCol = Color3.fromRGB(255, 180, 100),
projSize = Vector3.new(0.55, 0.55, 0.55),
kb = 42, kbUp = 22, kbDur = 1.3,
sfx = SFX_CAST,
},
Reducto = {
damage   = 60,  power  = 60, speed = 56, cdKey = "Reducto",
color    = Color3.fromRGB(150, 15, 255),
light    = Color3.fromRGB(180, 40, 255),
trailA   = Color3.fromRGB(200, 80, 255),
trailB   = Color3.fromRGB(90, 0, 180),
sparkCol = Color3.fromRGB(210, 120, 255),
projSize = Vector3.new(0.70, 0.70, 0.70),
kb = 50, kbUp = 26, kbDur = 1.4,
sfx = SFX_CAST,
},
Sectumsempra = {
damage   = 75,  power  = 75, speed = 78, cdKey = "Sectumsempra",
color    = Color3.fromRGB(210, 0, 25),
light    = Color3.fromRGB(230, 10, 40),
trailA   = Color3.fromRGB(255, 20, 55),
trailB   = Color3.fromRGB(60, 0, 15),
sparkCol = Color3.fromRGB(240, 50, 60),
projSize = Vector3.new(0.18, 0.7, 2.6),
kb = 56, kbUp = 18, kbDur = 1.6,
sfx = SFX_CAST,
},
Crucio = {
damage   = 45,  power  = 45, speed = 50, cdKey = "Crucio",
color    = Color3.fromRGB(230, 215, 0),
light    = Color3.fromRGB(255, 240, 20),
trailA   = Color3.fromRGB(255, 240, 60),
trailB   = Color3.fromRGB(175, 145, 0),
sparkCol = Color3.fromRGB(255, 250, 120),
projSize = Vector3.new(0.48, 0.48, 0.48),
kb = 25, kbUp = 38, kbDur = 2.5,
sfx = SFX_CAST,
},
Incendio = {
damage   = 55,  power  = 55, speed = 45, cdKey = "Incendio",
color    = Color3.fromRGB(255, 100, 0),
light    = Color3.fromRGB(255, 140, 30),
trailA   = Color3.fromRGB(255, 160, 50),
trailB   = Color3.fromRGB(180, 40, 0),
sparkCol = Color3.fromRGB(255, 200, 80),
projSize = Vector3.new(0.9, 0.9, 0.9),
kb = 38, kbUp = 28, kbDur = 1.5,
sfx = SFX_CAST,
},
AvadaKedavra = {
damage   = 999, power  = 999, speed = 100, cdKey = "AvadaKedavra",
color    = Color3.fromRGB(0, 210, 20),
light    = Color3.fromRGB(0, 255, 40),
trailA   = Color3.fromRGB(0, 255, 30),
trailB   = Color3.fromRGB(0, 70, 0),
sparkCol = Color3.fromRGB(120, 255, 120),
projSize = Vector3.new(0.30, 0.30, 2.8),
kb = 70, kbUp = 30, kbDur = 0.2,
sfx = SFX_AVADA,
},
}
 
--===========================================================
-- HOUSES & LAYOUT
--===========================================================
local HOUSES = {
{ name = "Gryffindor", primary = "Crimson",       neon = Color3.fromRGB(180,20,20)  },
{ name = "Slytherin",  primary = "Bright green",  neon = Color3.fromRGB(0,160,60)   },
{ name = "Ravenclaw",  primary = "Bright blue",   neon = Color3.fromRGB(30,60,200)  },
{ name = "Hufflepuff", primary = "Bright yellow", neon = Color3.fromRGB(210,180,0)  },
}
 
-- Lobby estilo 99 Noches: los 4 pads en UNA fila central pegada (13 studs entre centros,
-- bases tocándose), letreros bajos justo detrás y spawn al sur mirando a la plaza.
-- Isla circular GRANDE (Ø112) flotante: los 4 pads amarillos van sobre los 4 caminos
-- diagonales (r=30), letreros al final de cada camino (r=44), spawn en el círculo mágico.
local PAD_DATA = {
{ pos = Vector3.new(-21.2,3.6,-21.2), house=HOUSES[1], signPos=Vector3.new(-31.1,8.5,-31.1), signLook=Vector3.new(-21.2,8.5,-21.2) },
{ pos = Vector3.new( 21.2,3.6,-21.2), house=HOUSES[2], signPos=Vector3.new( 31.1,8.5,-31.1), signLook=Vector3.new( 21.2,8.5,-21.2) },
{ pos = Vector3.new(-21.2,3.6, 21.2), house=HOUSES[3], signPos=Vector3.new(-31.1,8.5, 31.1), signLook=Vector3.new(-21.2,8.5, 21.2) },
{ pos = Vector3.new( 21.2,3.6, 21.2), house=HOUSES[4], signPos=Vector3.new( 31.1,8.5, 31.1), signLook=Vector3.new( 21.2,8.5, 21.2) },
}
 
local ARENA_CENTERS = {
Vector3.new(0,5,320), Vector3.new(0,5,460),
Vector3.new(0,5,600), Vector3.new(0,5,740),
}
 
--===========================================================
-- DATA STORES
--===========================================================
-- DataStore blindado: en el Play de Studio Lite no hay DataStores; con pcall
-- el juego corre igual en Play (solo no guarda kills ahi) y en el juego real si.
local KillsStore, KillsOrdered
do
    local dummyStore = { GetAsync = function() return nil end, SetAsync = function() end,
        UpdateAsync = function() return nil end,
        GetSortedAsync = function() return { GetCurrentPage = function() return {} end } end }
    local okA, resA = pcall(function() return DataStoreService:GetDataStore("DuelKills_v11") end)
    local okB, resB = pcall(function() return DataStoreService:GetOrderedDataStore("DuelKillsRank_v11") end)
    KillsStore = (okA and resA) or dummyStore
    KillsOrdered = (okB and resB) or dummyStore
end
 
--===========================================================
-- REMOTES
--===========================================================
local Remotes = ReplicatedStorage:FindFirstChild("DuelRemotes")
if not Remotes then
    Remotes = Instance.new("Folder"); Remotes.Name = "DuelRemotes"; Remotes.Parent = ReplicatedStorage
end
 
local function makeRemote(name, isFunc)
    local r = Remotes:FindFirstChild(name)
    if not r then
        r = Instance.new(isFunc and "RemoteFunction" or "RemoteEvent")
        r.Name = name; r.Parent = Remotes
    end
    return r
end
 
local RE_BattleStart  = makeRemote("BattleStart")
local RE_BattleEnd    = makeRemote("BattleEnd")
local RE_CastSpell    = makeRemote("CastSpell")
local RE_Countdown    = makeRemote("Countdown")
local RE_RoundUpdate  = makeRemote("RoundUpdate")
local RE_SpellEffect  = makeRemote("SpellEffect")
local RE_ClashUpdate  = makeRemote("ClashUpdate")
 
--===========================================================
-- STATE
--===========================================================
local squares     = {}
local squareParts = {}
local padStations = {}
local arenaData   = {}
 
local playerSquare = {}
local playerDuel   = {}
local pendingCast  = {}
local clashActive  = {}
 
local playerKills  = {}
local loadingKills = {}
 
for i = 1, 4 do
    squares[i] = { players = {}, inBattle = false, countdown = false }
end
 
--===========================================================
-- GAMEPLAY HELPERS
--===========================================================
local function playSoundAt(char, id, vol)
    if not char then return end
    local p = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not p then return end
    local s = Instance.new("Sound"); s.SoundId=id; s.Volume=vol or 1
    s.RollOffMode=Enum.RollOffMode.InverseTapered; s.RollOffMaxDistance=80
    s.Parent=p; s:Play(); Debris:AddItem(s, 5)
end
 
local function getCastPart(char)
    if not char then return nil end
    local wand = char:FindFirstChild("Varita Magica")
    if wand then
        local tip = wand:FindFirstChild("WandTip")
        if tip then return tip end
    end
    return char:FindFirstChild("RightHand")
    or char:FindFirstChild("Right Lower Arm")
    or char:FindFirstChild("Right Arm")
    or char:FindFirstChild("RightUpperArm")
end
 
local function freezePlayer(player, frozen)
    local char = player.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.WalkSpeed = frozen and 0 or 16; hum.JumpPower = frozen and 0 or 50
end
 
local function teleportTo(player, pos, lookAt)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos, lookAt)
    end
end
 
local function clearWand(player)
    local function kill(p) for _,i in ipairs(p:GetChildren()) do if i.Name=="Varita Magica" then i:Destroy() end end end
    if player:FindFirstChild("Backpack") then kill(player.Backpack) end
    if player.Character then kill(player.Character) end
end
 
local function returnToLobby(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(LOBBY_SPAWN + Vector3.new(math.random(-8,8),0,math.random(-8,8)))
    end
    clearWand(player)
end
 
local function registerKill(killer)
    if not killer or not killer:IsA("Player") then return end
    playerKills[killer] = (playerKills[killer] or 0) + 1
    local ls = killer:FindFirstChild("leaderstats")
    local kv = ls and ls:FindFirstChild("Kills")
    if kv then kv.Value = playerKills[killer] end
    task.spawn(function()
        local uid = tostring(killer.UserId)
        pcall(function() KillsStore:SetAsync(uid, playerKills[killer]) end)
            pcall(function() KillsOrdered:SetAsync(uid, playerKills[killer]) end)
            end)
            end
 
                local function loadKills(player)
                    if loadingKills[player] then return end; loadingKills[player] = true
                        local uid = tostring(player.UserId); local kills = 0
                        local ok, result = pcall(function() return KillsStore:GetAsync(uid) end)
                            if ok and typeof(result) == "number" then kills = result end
                            playerKills[player] = kills
                            local ls = player:FindFirstChild("leaderstats"); local kv = ls and ls:FindFirstChild("Kills")
                            if kv then kv.Value = kills end
                            loadingKills[player] = nil
                        end
 
                        local function saveKills(player)
                            if not playerKills[player] then return end
                            local uid = tostring(player.UserId); local kills = playerKills[player]
                            pcall(function() KillsStore:SetAsync(uid, kills) end)
                                pcall(function() KillsOrdered:SetAsync(uid, kills) end)
                                end
 
                                    --===========================================================
                                    -- WAND CREATION
                                    --===========================================================
                                    local function createWand(houseName)
                                        local house = HOUSES[1]
                                        for _, h in ipairs(HOUSES) do if h.name == houseName then house = h break end end
 
                                        local wand = Instance.new("Tool"); wand.Name = "Varita Magica"
                                        wand.RequiresHandle = true; wand.CanBeDropped = false
                                        wand.GripPos = Vector3.new(0,-0.52,0); wand.GripForward = Vector3.new(0,0,1)
                                        wand.GripRight = Vector3.new(1,0,0); wand.GripUp = Vector3.new(0,1,0)
                                        wand:SetAttribute("HouseName", houseName or "Gryffindor")
 
                                        local function wp(name, size, col, mat)
                                            local p = Instance.new("Part")
                                            p.Name = name; p.Size = size
                                            p.BrickColor = BrickColor.new(col)
                                            p.Material = mat or Enum.Material.SmoothPlastic
                                            p.CanCollide = false; p.Massless = true; p.CastShadow = false
                                            p.TopSurface = Enum.SurfaceType.Smooth
                                            p.BottomSurface = Enum.SurfaceType.Smooth
                                            p.Parent = wand
                                            return p
                                        end
 
                                        local function weld(p0, p1)
                                            local w = Instance.new("WeldConstraint")
                                            w.Part0 = p0; w.Part1 = p1; w.Parent = p0
                                        end
 
                                        local function addCylinder(part, scaleX, scaleY, scaleZ)
                                            local m = Instance.new("SpecialMesh")
                                            m.MeshType = Enum.MeshType.Cylinder
                                            m.Scale = Vector3.new(scaleX or 1, scaleY or 1, scaleZ or 1)
                                            m.Parent = part
                                            return m
                                        end
 
                                        -- Varita de madera estilizada (más simple y natural)
                                        local handle = wp("Handle", Vector3.new(0.20,1.0,0.20), "Reddish brown", Enum.Material.Wood)
                                        handle.Color = Color3.fromRGB(86, 46, 30)
                                        addCylinder(handle, 1, 1, 1)
 
                                        local woodRingA = wp("WoodRingA", Vector3.new(0.24,0.16,0.24), "Reddish brown", Enum.Material.Wood)
                                        woodRingA.Color = Color3.fromRGB(97, 55, 35)
                                        addCylinder(woodRingA, 1.04, 1, 1.04)
 
                                        local woodRingB = wp("WoodRingB", Vector3.new(0.22,0.14,0.22), "Reddish brown", Enum.Material.Wood)
                                        woodRingB.Color = Color3.fromRGB(104, 61, 39)
                                        addCylinder(woodRingB, 1.03, 1, 1.03)
 
                                        local shaftLow = wp("ShaftLow", Vector3.new(0.15,0.80,0.15), "Reddish brown", Enum.Material.Wood)
                                        shaftLow.Color = Color3.fromRGB(112, 66, 45)
                                        addCylinder(shaftLow, 1, 1, 1)
 
                                        local shaftMid = wp("WandBody", Vector3.new(0.12,0.88,0.12), "Reddish brown", Enum.Material.Wood)
                                        shaftMid.Color = Color3.fromRGB(124, 74, 52)
                                        addCylinder(shaftMid, 0.95, 1, 0.95)
 
                                        local shaftHigh = wp("ShaftHigh", Vector3.new(0.1,0.72,0.1), "Reddish brown", Enum.Material.Wood)
                                        shaftHigh.Color = Color3.fromRGB(138, 84, 59)
                                        addCylinder(shaftHigh, 0.9, 1, 0.9)
 
                                        local tip = wp("WandTip", Vector3.new(0.06,0.34,0.06), "Institutional white", Enum.Material.Neon)
                                        tip.Color = house.neon
                                        addCylinder(tip, 0.78, 1, 0.78)
 
                                        local pommel = wp("Pommel", Vector3.new(0.24,0.22,0.24), "Reddish brown", Enum.Material.Wood)
                                        pommel.Color = Color3.fromRGB(79, 44, 29)
                                        addCylinder(pommel, 1.02, 1, 1.02)
 
                                        woodRingA.CFrame = handle.CFrame * CFrame.new(0,-0.30,0)
                                        woodRingB.CFrame = handle.CFrame * CFrame.new(0,-0.08,0)
                                        shaftLow.CFrame = handle.CFrame * CFrame.new(0,0.9,0)
                                        shaftMid.CFrame = shaftLow.CFrame * CFrame.new(0,0.82,0)
                                        shaftHigh.CFrame = shaftMid.CFrame * CFrame.new(0,0.78,0)
                                        tip.CFrame = shaftHigh.CFrame * CFrame.new(0,0.5,0)
                                        pommel.CFrame = handle.CFrame * CFrame.new(0,-0.60,0)
 
                                        for _, part in ipairs({woodRingA, woodRingB, shaftLow, shaftMid, shaftHigh, tip, pommel}) do
                                            weld(handle, part)
                                        end
 
                                        -- TipAttachment for particles/effects
                                        local att = Instance.new("Attachment")
                                        att.Name = "TipAttachment"; att.Position = Vector3.new(0,0.15,0); att.Parent = tip
 
                                        -- Ambient magical aura
                                        local aura = Instance.new("ParticleEmitter")
                                        aura.Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,240,180)),
                                        ColorSequenceKeypoint.new(0.45, house.neon),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(120,255,255)),
                                        }
                                        aura.LightEmission = 1
                                        aura.Size = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0.16),
                                        NumberSequenceKeypoint.new(0.55,0.08),
                                        NumberSequenceKeypoint.new(1,0)
                                        }
                                        aura.Transparency = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0.05),
                                        NumberSequenceKeypoint.new(1,1)
                                        }
                                        aura.Speed = NumberRange.new(0.4,2.2)
                                        aura.SpreadAngle = Vector2.new(28,28)
                                        aura.Lifetime = NumberRange.new(0.3,0.8)
                                        aura.Rate = 22
                                        aura.Parent = att
 
                                        -- Arc sparks for high detail look
                                        local sparks = Instance.new("ParticleEmitter")
                                        sparks.Color = ColorSequence.new(house.neon, Color3.fromRGB(255,255,255))
                                        sparks.LightEmission = 1
                                        sparks.Size = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0.08),
                                        NumberSequenceKeypoint.new(1,0)
                                        }
                                        sparks.Transparency = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0.1),
                                        NumberSequenceKeypoint.new(1,1)
                                        }
                                        sparks.Speed = NumberRange.new(5,14)
                                        sparks.Acceleration = Vector3.new(0,2,0)
                                        sparks.Drag = 3
                                        sparks.SpreadAngle = Vector2.new(360,360)
                                        sparks.Lifetime = NumberRange.new(0.08,0.2)
                                        sparks.Rate = 8
                                        sparks.Parent = att
 
                                        -- Glow
                                        local glow = Instance.new("PointLight")
                                        glow.Brightness = 4.6; glow.Color = house.neon; glow.Range = 10; glow.Shadows = true; glow.Parent = tip
 
                                        -- Cast burst emitter (enabled on cast)
                                        local burst = Instance.new("ParticleEmitter")
                                        burst.Name = "CastBurst"
                                        burst.Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, house.neon),
                                        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255,255,255)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(120,255,180)),
                                        }
                                        burst.LightEmission = 1
                                        burst.Size = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0.75),
                                        NumberSequenceKeypoint.new(0.5,0.28),
                                        NumberSequenceKeypoint.new(1,0)
                                        }
                                        burst.Transparency = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0),
                                        NumberSequenceKeypoint.new(1,1)
                                        }
                                        burst.Speed = NumberRange.new(9,24)
                                        burst.SpreadAngle = Vector2.new(360,360)
                                        burst.Lifetime = NumberRange.new(0.12,0.45)
                                        burst.Rate = 0
                                        burst.Parent = att
 
                                        -- Trail on tip
                                        local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0,0.16,0); a0.Parent = tip
                                        local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0,-0.16,0); a1.Parent = tip
                                        local tr = Instance.new("Trail")
                                        tr.Attachment0 = a0; tr.Attachment1 = a1
                                        tr.Lifetime = 0.2; tr.LightEmission = 1
                                        tr.Color = ColorSequence.new{
                                        ColorSequenceKeypoint.new(0, house.neon),
                                        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255,255,255)),
                                        ColorSequenceKeypoint.new(1, Color3.fromRGB(90,255,170)),
                                        }
                                        tr.Transparency = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0.05),
                                        NumberSequenceKeypoint.new(1,1)
                                        }
                                        tr.WidthScale = NumberSequence.new{
                                        NumberSequenceKeypoint.new(0,0.95),
                                        NumberSequenceKeypoint.new(0.5,0.62),
                                        NumberSequenceKeypoint.new(1,0)
                                        }
                                        tr.Parent = tip
 
                                        return wand
                                    end
 
                                    local function giveFighterSetup(player, houseName)
                                        local char = player.Character; if not char then return end
                                        local hum = char:FindFirstChildOfClass("Humanoid")
                                        if hum then hum.MaxHealth = PLAYER_HEALTH; hum.Health = PLAYER_HEALTH end
                                        clearWand(player)
                                    end
 
                                    --===========================================================
                                    -- PHYSICS: WALL SLAM
                                    --===========================================================
                                    local function wallSlam(char, dir, force, duration)
                                        if not char then return end
                                        local hum = char:FindFirstChildOfClass("Humanoid")
                                        local hrp = char:FindFirstChild("HumanoidRootPart")
                                        if not hum or not hrp or hum.Health <= 0 then return end
 
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
                                        if not hum or hum.Health <= 0 then return false end
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
                                        local fx = Instance.new("Part"); fx.Size=Vector3.new(1,1,1)
                                        fx.CFrame=CFrame.new(position); fx.Anchored=true
                                        fx.CanCollide=false; fx.Transparency=1; fx.Parent=workspace
 
                                        local pe = Instance.new("ParticleEmitter"); pe.Color=ColorSequence.new(spData.sparkCol)
                                        pe.LightEmission=1
                                        pe.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,1.2),NumberSequenceKeypoint.new(1,0)}
                                        pe.Speed=NumberRange.new(20,55); pe.Lifetime=NumberRange.new(0.3,0.9)
                                        pe.SpreadAngle=Vector2.new(360,360); pe.Parent=fx; pe:Emit(100)
 
                                        local pe2 = pe:Clone(); pe2.Color=ColorSequence.new(spData.color,Color3.fromRGB(255,255,255)); pe2:Emit(60); pe2.Parent=fx
 
                                        local pl = Instance.new("PointLight"); pl.Brightness=25; pl.Range=55; pl.Color=spData.light; pl.Parent=fx
                                        TweenService:Create(pl, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness=0}):Play()
 
                                        Debris:AddItem(fx, 2)
                                    end
 
                                    --===========================================================
                                    -- GENERIC SPELL LAUNCHER
                                    --===========================================================
                                    local function launchSpell(caster, duelInfo, spellName)
                                        local spData = SPELL_DATA[spellName]; if not spData then return end
                                        local opponent = duelInfo.opponent
                                        local cChar = caster.Character; local oChar = opponent and opponent.Character
                                        if not cChar or not oChar then return end
 
                                        local tipPart = getCastPart(cChar)
                                        local startPos = tipPart and tipPart.Position or (cChar.HumanoidRootPart.Position + Vector3.new(0,1.5,0))
                                        local targetPos = oChar.HumanoidRootPart.Position + Vector3.new(0,1.0,0)
                                        local dir = (targetPos - startPos)
                                        if dir.Magnitude <= 0 then return end
                                        dir = dir.Unit
 
                                        -- Trigger wand burst
                                        if tipPart then
                                            local burst = tipPart:FindFirstChild("TipAttachment") and tipPart:FindFirstChild("TipAttachment"):FindFirstChild("CastBurst")
                                            if burst then burst:Emit(35) end
                                        end
                                        playSoundAt(cChar, spData.sfx or SFX_CAST, 1)
 
                                        -- Create projectile
                                        local proj = Instance.new("Part")
                                        proj.Name = spellName .. "Proj"
                                        proj.Size = spData.projSize
                                        proj.Color = spData.color
                                        proj.Material = Enum.Material.Neon
                                        proj.CanCollide = false; proj.CanTouch = true
                                        proj.Anchored = false; proj.CastShadow = false
                                        proj.CFrame = CFrame.new(startPos, startPos + dir)
                                        proj.Parent = workspace
 
                                        -- Sphere mesh for round spells
                                        if spellName == "Stupefy" or spellName == "Reducto" or spellName == "Crucio" or spellName == "Incendio" then
                                            local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = proj
                                        end
 
                                        -- Point light
                                        local pl = Instance.new("PointLight"); pl.Brightness=9; pl.Range=22; pl.Color=spData.light; pl.Parent=proj
 
                                        -- Trail
                                        local at0 = Instance.new("Attachment"); at0.Position=Vector3.new(0,0.1,0); at0.Parent=proj
                                        local at1 = Instance.new("Attachment"); at1.Position=Vector3.new(0,-0.1,0); at1.Parent=proj
                                        local trail = Instance.new("Trail"); trail.Attachment0=at0; trail.Attachment1=at1
                                        trail.Lifetime = (spellName == "AvadaKedavra") and 0.65 or 0.28
                                        trail.LightEmission = 1
                                        trail.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,spData.trailA), ColorSequenceKeypoint.new(1,spData.trailB)}
                                        trail.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}
                                        trail.WidthScale = NumberSequence.new{NumberSequenceKeypoint.new(0,1.2),NumberSequenceKeypoint.new(1,0)}
                                        trail.Parent = proj
 
                                        -- Sparks / particles
                                        local pe = Instance.new("ParticleEmitter")
                                        pe.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,spData.sparkCol),ColorSequenceKeypoint.new(1,spData.color)}
                                        pe.LightEmission=1
                                        pe.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.22),NumberSequenceKeypoint.new(1,0)}
                                        pe.Speed=NumberRange.new(3,9); pe.Lifetime=NumberRange.new(0.08,0.28)
                                        pe.Rate = (spellName == "AvadaKedavra") and 140 or 30
                                        pe.SpreadAngle=Vector2.new(180,180); pe.Parent=proj
 
                                        -- Special: Incendio has Fire
                                        if spellName == "Incendio" then
                                            local fire = Instance.new("Fire"); fire.Heat=15; fire.Size=4
                                            fire.Color=spData.color; fire.SecondaryColor=Color3.fromRGB(255,200,0); fire.Parent=proj
                                        end
                                        -- Special: Crucio has extra energy balls effect
                                        if spellName == "Crucio" then
                                            local pe2 = Instance.new("ParticleEmitter")
                                            pe2.Color=ColorSequence.new(Color3.fromRGB(255,255,180)); pe2.LightEmission=1
                                            pe2.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(1,0)}
                                            pe2.Speed=NumberRange.new(8,20); pe2.Lifetime=NumberRange.new(0.15,0.45)
                                            pe2.Rate=25; pe2.SpreadAngle=Vector2.new(360,360); pe2.Parent=proj
                                        end
                                        if spellName == "AvadaKedavra" then
                                            local smoke = Instance.new("ParticleEmitter")
                                            smoke.Color = ColorSequence.new(Color3.fromRGB(20,120,30), Color3.fromRGB(180,255,190))
                                            smoke.LightEmission = 0.8
                                            smoke.Size = NumberSequence.new{
                                            NumberSequenceKeypoint.new(0,0.5),
                                            NumberSequenceKeypoint.new(0.6,0.9),
                                            NumberSequenceKeypoint.new(1,0)
                                            }
                                            smoke.Transparency = NumberSequence.new{
                                            NumberSequenceKeypoint.new(0,0.2),
                                            NumberSequenceKeypoint.new(1,1)
                                            }
                                            smoke.Speed = NumberRange.new(2,6)
                                            smoke.Drag = 4
                                            smoke.Rate = 70
                                            smoke.Lifetime = NumberRange.new(0.2,0.5)
                                            smoke.Parent = proj
 
                                            local ring = Instance.new("ParticleEmitter")
                                            ring.Color = ColorSequence.new(Color3.fromRGB(140,255,140), Color3.fromRGB(0,255,30))
                                            ring.LightEmission = 1
                                            ring.Texture = "rbxassetid://243660364"
                                            ring.Size = NumberSequence.new{
                                            NumberSequenceKeypoint.new(0,1.4),
                                            NumberSequenceKeypoint.new(1,0)
                                            }
                                            ring.Transparency = NumberSequence.new{
                                            NumberSequenceKeypoint.new(0,0.12),
                                            NumberSequenceKeypoint.new(1,1)
                                            }
                                            ring.Speed = NumberRange.new(0.5,1.2)
                                            ring.RotSpeed = NumberRange.new(-120,120)
                                            ring.Rate = 20
                                            ring.Lifetime = NumberRange.new(0.1,0.22)
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
                                        bv.Velocity = dir * spData.speed; bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Parent = proj
 
                                        -- Hit detection
                                        local hitDone = false
                                        proj.Touched:Connect(function(hit)
                                            if hitDone then return end
                                            if not hit or not hit.Parent then return end
                                            if hit.Parent == cChar then return end
                                            local hp = Players:GetPlayerFromCharacter(hit.Parent)
                                            if hp ~= opponent then return end
                                            hitDone = true
 
                                            local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
                                            local died = damageAndSlam(hit.Parent, hum, spData.damage, caster, dir, spData.kb, spData.kbDur)
 
                                            spawnImpactFX(proj.Position, spData)
 
                                            RE_SpellEffect:FireClient(caster,   spellName .. "_hit",   false)
                                            RE_SpellEffect:FireClient(opponent, spellName .. "_hit",   true)
 
                                            -- Avada Kedavra: epic extra death FX
                                            if spellName == "AvadaKedavra" then
                                                RE_SpellEffect:FireClient(caster,   "AvadaKill_cast")
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
                                        if not beam then return end
                                        if beam.Parent then beam:Destroy() end
                                    end
 
                                    local function makeClashBeam(p1, p2, col)
                                        local c1 = p1.Character; local c2 = p2.Character
                                        if not c1 or not c2 then return nil end
                                        local t1 = getCastPart(c1); local t2 = getCastPart(c2)
                                        if not t1 or not t2 then return nil end
 
                                        local function ensureAtt(tip)
                                            local a = tip:FindFirstChild("TipAttachment") or (function()
                                                local aa=Instance.new("Attachment"); aa.Name="TipAttachment"; aa.Position=Vector3.new(0,0.14,0); aa.Parent=tip; return aa
                                            end)()
                                            return a
                                        end
 
                                        local a0 = ensureAtt(t1); local a1 = ensureAtt(t2)
 
                                        -- Main beam
                                        local beam = Instance.new("Beam")
                                        beam.Attachment0=a0; beam.Attachment1=a1; beam.FaceCamera=true
                                        beam.Width0=0.6; beam.Width1=0.6; beam.LightEmission=1; beam.Segments=30
                                        beam.Color = ColorSequence.new(col or Color3.fromRGB(120,255,120), Color3.fromRGB(255,255,255))
                                        beam.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(0.5,0.1), NumberSequenceKeypoint.new(1,0)}
                                        beam.Parent = t1
 
                                        -- Secondary wavy beam
                                        local beam2 = beam:Clone(); beam2.Width0=0.25; beam2.Width1=0.25
                                        beam2.CurveSize0=math.random(2,6); beam2.CurveSize1=math.random(2,6)
                                        beam2.Color = ColorSequence.new(Color3.fromRGB(255,255,255), col or Color3.fromRGB(120,255,120))
                                        beam2.Parent = t1
 
                                        -- Sparks at tips
                                        local function tipSpark(att, c)
                                            local sp = Instance.new("ParticleEmitter"); sp.Color=ColorSequence.new(c)
                                            sp.LightEmission=1; sp.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,0)}
                                            sp.Speed=NumberRange.new(8,22); sp.Lifetime=NumberRange.new(0.1,0.3)
                                            sp.Rate=120; sp.SpreadAngle=Vector2.new(360,360); sp.Parent=att; return sp
                                        end
                                        local sp1 = tipSpark(a0, col or Color3.fromRGB(120,255,120))
                                        local sp2 = tipSpark(a1, col or Color3.fromRGB(120,255,120))
 
                                        -- Midpoint orb
                                        local mid = Instance.new("Part"); mid.Anchored=true; mid.CanCollide=false
                                        mid.Size=Vector3.new(1.4,1.4,1.4); mid.Material=Enum.Material.Neon
                                        mid.Color=col or Color3.fromRGB(120,255,120); mid.CastShadow=false
                                        mid.CFrame=CFrame.new((t1.Position+t2.Position)/2); mid.Parent=workspace
                                        local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=mid
 
                                        local midLight=Instance.new("PointLight"); midLight.Brightness=25; midLight.Range=40; midLight.Color=col or Color3.fromRGB(0,255,40); midLight.Parent=mid
 
                                        local midSp=Instance.new("ParticleEmitter"); midSp.Color=ColorSequence.new(Color3.fromRGB(255,255,255)); midSp.LightEmission=1
                                        midSp.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(1,0)}
                                        midSp.Speed=NumberRange.new(12,30); midSp.Lifetime=NumberRange.new(0.12,0.35)
                                        midSp.Rate=200; midSp.SpreadAngle=Vector2.new(360,360); midSp.Parent=mid
 
                                        return { beam=beam, beam2=beam2, sp1=sp1, sp2=sp2, mid=mid, t1=t1, t2=t2 }
                                    end
 
                                    local function blendSpellColors(s1, s2)
                                        local d1 = SPELL_DATA[s1]; local d2 = SPELL_DATA[s2]
                                        if not d1 or not d2 then return Color3.fromRGB(120,255,120) end
                                        local c1 = d1.color; local c2 = d2.color
                                        return Color3.fromRGB(math.floor((c1.R*255+c2.R*255)/2), math.floor((c1.G*255+c2.G*255)/2), math.floor((c1.B*255+c2.B*255)/2))
                                    end
 
                                    local function startClash(p1, spell1, p2, spell2, arenaIdx)
                                        if clashActive[arenaIdx] then return end
                                        clashActive[arenaIdx] = true
 
                                        pendingCast[p1] = nil; pendingCast[p2] = nil
 
                                        local beamCol = blendSpellColors(spell1, spell2)
                                        local vis = makeClashBeam(p1, p2, beamCol)
 
                                        freezePlayer(p1, true); freezePlayer(p2, true)
                                        playSoundAt(p1.Character, SFX_CLASH, 1.2)
                                        playSoundAt(p2.Character, SFX_CLASH, 1.2)
 
                                        RE_SpellEffect:FireClient(p1, "ClashStart", spell1, spell2)
                                        RE_SpellEffect:FireClient(p2, "ClashStart", spell2, spell1)
 
                                        -- Determine winner
                                        local pow1 = (SPELL_DATA[spell1] and SPELL_DATA[spell1].power) or 0
                                        local pow2 = (SPELL_DATA[spell2] and SPELL_DATA[spell2].power) or 0
                                        local winnerIdx = (pow1 > pow2) and 1 or (pow2 > pow1) and 2 or math.random(1,2)
 
                                        -- Animate orb moving toward loser over 4 seconds
                                        local DURATION = 4.0
                                        local startT = os.clock()
 
                                        local conn
                                        conn = RunService.Heartbeat:Connect(function()
                                            if not vis then if conn then conn:Disconnect() end return end
                                            local t1p = vis.t1 and vis.t1.Parent and vis.t1.Position
                                            local t2p = vis.t2 and vis.t2.Parent and vis.t2.Position
                                            if not t1p or not t2p then if conn then conn:Disconnect() end return end
 
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
                                        if conn then conn:Disconnect() end
 
                                        -- Resolve clash
                                        local winner = (winnerIdx == 1) and p1 or p2
                                        local loser  = (winnerIdx == 1) and p2 or p1
                                        local wSpell = (winnerIdx == 1) and spell1 or spell2
 
                                        -- Big explosion at orb position then cleanup
                                        if vis and vis.mid and vis.mid.Parent then
                                            spawnImpactFX(vis.mid.Position, SPELL_DATA[wSpell] or SPELL_DATA.AvadaKedavra)
                                            vis.sp1:Emit(80); vis.sp2:Emit(80)
                                            task.delay(0.1, function()
                                                if vis.beam and vis.beam.Parent then vis.beam:Destroy() end
                                                if vis.beam2 and vis.beam2.Parent then vis.beam2:Destroy() end
                                                if vis.sp1 and vis.sp1.Parent then vis.sp1:Destroy() end
                                                if vis.sp2 and vis.sp2.Parent then vis.sp2:Destroy() end
                                                if vis.mid and vis.mid.Parent then vis.mid:Destroy() end
                                            end)
                                        end
 
                                        RE_SpellEffect:FireClient(p1, "ClashEnd", winnerIdx == 1)
                                        RE_SpellEffect:FireClient(p2, "ClashEnd", winnerIdx == 2)
 
                                        freezePlayer(p1, false); freezePlayer(p2, false)
                                        clashActive[arenaIdx] = false
 
                                        task.wait(0.3)
 
                                        -- Apply damage to loser
                                        if playerDuel[winner] and playerDuel[loser] then
                                            local lchar = loser.Character
                                            if lchar then
                                                local hum = lchar:FindFirstChildOfClass("Humanoid")
                                                if hum then
                                                    local sp = SPELL_DATA[wSpell]
                                                    local dir = loser.Character and winner.Character and
                                                    (loser.Character.HumanoidRootPart.Position - winner.Character.HumanoidRootPart.Position).Unit or Vector3.new(0,0,1)
                                                    damageAndSlam(lchar, hum, sp and sp.damage or 50, winner, dir, (sp and sp.kb or 45) * 1.5, (sp and sp.kbDur or 1.5))
                                                    if wSpell == "AvadaKedavra" then
                                                        RE_SpellEffect:FireClient(winner, "AvadaKill_cast")
                                                        RE_SpellEffect:FireClient(loser, "AvadaKill_victim")
                                                    else
                                                        RE_SpellEffect:FireClient(winner, wSpell.."_hit", false)
                                                        RE_SpellEffect:FireClient(loser,  wSpell.."_hit", true)
                                                    end
                                                end
                                            end
                                        end
                                    end
 
                                    --===========================================================
                                    -- CAST HANDLER
                                    --===========================================================
                                    RE_CastSpell.OnServerEvent:Connect(function(caster, spellName)
                                        local duelInfo = playerDuel[caster]; if not duelInfo then return end
                                        if not SPELL_DATA[spellName] then return end
 
                                        local arenaIdx = duelInfo.arenaIdx
                                        local opponent = duelInfo.opponent
                                        if not opponent or not playerDuel[opponent] then return end
 
                                        -- Wand cast burst FX on server
                                        local char = caster.Character
                                        if char then
                                            local wand = char:FindFirstChild("Varita Magica")
                                            if wand then
                                                wand:SetAttribute("CastSpell", spellName)
                                                wand:SetAttribute("Casting", true)
                                                task.delay(0.5, function() if wand then wand:SetAttribute("Casting", false) end end)
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
                                                        if not pc or pc.token ~= token then return end
                                                        if not playerDuel[caster] or not playerDuel[opponent] then pendingCast[caster]=nil; return end
                                                        if clashActive[arenaIdx] then pendingCast[caster]=nil; return end
                                                        pendingCast[caster] = nil
                                                        launchSpell(caster, duelInfo, spellName)
                                                    end)
                                                end)
 

--===========================================================
-- ESTADO PARA LA SEGUNDA MITAD DE ESTE SCRIPT (mundo y rondas)
-- Las tablas van por referencia: la segunda mitad escribe en las mismas
-- tablas que el nucleo lee durante el combate.
--===========================================================
local S = { -- antes shared.AvadaDuel; ahora local (Studio Lite bloquea shared)
    squares = squares, squareParts = squareParts, padStations = padStations,
    arenaData = arenaData, playerSquare = playerSquare, playerDuel = playerDuel,
    pendingCast = pendingCast, clashActive = clashActive, playerKills = playerKills,
    LOBBY_SPAWN = LOBBY_SPAWN, ROUND_TIME = ROUND_TIME, TOTAL_ROUNDS = TOTAL_ROUNDS,
    HOUSES = HOUSES, PAD_DATA = PAD_DATA, ARENA_CENTERS = ARENA_CENTERS,
    KillsStore = KillsStore, KillsOrdered = KillsOrdered,
    RE_BattleStart = RE_BattleStart, RE_BattleEnd = RE_BattleEnd,
    RE_CastSpell = RE_CastSpell, RE_Countdown = RE_Countdown,
    RE_RoundUpdate = RE_RoundUpdate, RE_SpellEffect = RE_SpellEffect,
    RE_ClashUpdate = RE_ClashUpdate,
    freezePlayer = freezePlayer, teleportTo = teleportTo,
    returnToLobby = returnToLobby, giveFighterSetup = giveFighterSetup,
    loadKills = loadKills, saveKills = saveKills, registerKill = registerKill,
}
print("⚡ [DuelGame] Parte 1 de 2 lista: nucleo y combate ⚡")


--===========================================================
-- SEGUNDA MITAD: MUNDO Y RONDAS (pads, arenas, rondas, eventos)
-- Vive en este mismo archivo a proposito: sin "shared" entre scripts.
--===========================================================
do
local squares      = S.squares
local squareParts  = S.squareParts
local padStations  = S.padStations
local arenaData    = S.arenaData
local playerSquare = S.playerSquare
local playerDuel   = S.playerDuel
local pendingCast  = S.pendingCast
local LOBBY_SPAWN    = S.LOBBY_SPAWN
local ROUND_TIME     = S.ROUND_TIME
local TOTAL_ROUNDS   = S.TOTAL_ROUNDS
local HOUSES         = S.HOUSES
local PAD_DATA       = S.PAD_DATA
local ARENA_CENTERS  = S.ARENA_CENTERS
local KillsOrdered   = S.KillsOrdered
local RE_BattleStart = S.RE_BattleStart
local RE_BattleEnd   = S.RE_BattleEnd
local RE_Countdown   = S.RE_Countdown
local RE_RoundUpdate = S.RE_RoundUpdate
local freezePlayer     = S.freezePlayer
local teleportTo       = S.teleportTo
local returnToLobby    = S.returnToLobby
local giveFighterSetup = S.giveFighterSetup
local loadKills        = S.loadKills
local saveKills        = S.saveKills

--===========================================================
-- HELPERS: WORLD BUILDING
--===========================================================
local function makePart(name, size, cf, color, material, parent, canCollide, anchored)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.CFrame = cf
    p.BrickColor = BrickColor.new(color)
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = (anchored ~= false); p.CanCollide = (canCollide ~= false)
    p.CastShadow = true
    for _, s in ipairs({"TopSurface","BottomSurface","LeftSurface","RightSurface","FrontSurface","BackSurface"}) do
        p[s] = Enum.SurfaceType.Studs
    end
    p.Massless = true; p.Parent = parent
    return p
end

local function addTex(part, face, u, v, id)
    local t = Instance.new("Texture")
    t.Texture = id or "rbxassetid://1536723462"
    t.Face = face or Enum.NormalId.Top
    t.StudsPerTileU = u or 6; t.StudsPerTileV = v or 6
    t.Parent = part
end

local function addGothicPillar(cx, cy, cz, height, parent)
    makePart("PillarShaft", Vector3.new(4,height,4),    CFrame.new(cx, cy+height/2, cz), "Medium stone grey", Enum.Material.SmoothPlastic, parent, true, true)
    makePart("PillarBase",  Vector3.new(5.5,2,5.5),     CFrame.new(cx, cy+1, cz),       "Dark stone grey",   Enum.Material.SmoothPlastic, parent, true, true)
    makePart("PillarCap",   Vector3.new(5.5,2,5.5),     CFrame.new(cx, cy+height-1, cz),"Dark stone grey",   Enum.Material.SmoothPlastic, parent, true, true)
end

local function addGothicArch(cx, cy, cz, w, h, thick, parent, rotY)
    rotY = rotY or 0
    local rot = CFrame.Angles(0, math.rad(rotY), 0)
    makePart("ArchLeft",  Vector3.new(thick, h*0.65, w*0.18), CFrame.new(cx, cy+h*0.325, cz)*rot*CFrame.new(-w*0.41,0,0), "Dark stone grey", Enum.Material.SmoothPlastic, parent, true, true)
    makePart("ArchRight", Vector3.new(thick, h*0.65, w*0.18), CFrame.new(cx, cy+h*0.325, cz)*rot*CFrame.new( w*0.41,0,0), "Dark stone grey", Enum.Material.SmoothPlastic, parent, true, true)
end

local function addStainedGlass(pos, size, colors, parent)
    makePart("SGFrame", size+Vector3.new(0.4,0.4,0), CFrame.new(pos), "Dark stone grey", Enum.Material.SmoothPlastic, parent, false, true)
    local segH = size.Y / #colors
    for i, c in ipairs(colors) do
        local seg = makePart("SGSeg_"..i, Vector3.new(size.X-0.3, segH-0.1, 0.15),
        CFrame.new(pos+Vector3.new(0,(i-1)*segH-size.Y/2+segH/2,-0.1)), "White", Enum.Material.Neon, parent, false, true)
        seg.Color = c; seg.Transparency = 0.35
        local gl = Instance.new("PointLight"); gl.Brightness=1.5; gl.Range=12; gl.Color=c; gl.Parent=seg
    end
end

local function addWallTorch(pos, parent)
    local bowl = makePart("TorchBowl", Vector3.new(0.9,0.5,0.9), CFrame.new(pos+Vector3.new(0,0.8,0)), "Dark orange", Enum.Material.SmoothPlastic, parent, false, true)
    local fire = Instance.new("Fire"); fire.Heat=8; fire.Size=3.5
    fire.Color=Color3.fromRGB(255,120,10); fire.SecondaryColor=Color3.fromRGB(255,220,0); fire.Parent=bowl
    local light = Instance.new("PointLight"); light.Brightness=6; light.Range=28; light.Color=Color3.fromRGB(255,150,40); light.Parent=bowl
end

local function createFlyingCandle(position, parent)
    local candle = Instance.new("Part")
    candle.Name = "FlyingCandle"; candle.Size = Vector3.new(0.28,1.2,0.28)
    candle.BrickColor = BrickColor.new("White"); candle.Material = Enum.Material.SmoothPlastic
    candle.Anchored = true; candle.CanCollide = false; candle.CastShadow = false
    candle.CFrame = CFrame.new(position); candle.Parent = parent

    local wick = Instance.new("Part")
    wick.Name = "Wick"; wick.Size = Vector3.new(0.06,0.25,0.06)
    wick.BrickColor = BrickColor.new("Black"); wick.Material = Enum.Material.SmoothPlastic
    wick.Anchored = true; wick.CanCollide = false; wick.CastShadow = false
    wick.CFrame = CFrame.new(position+Vector3.new(0,0.72,0)); wick.Parent = parent

    local flame = Instance.new("Fire"); flame.Heat=3; flame.Size=1.8
    flame.Color=Color3.fromRGB(255,200,80); flame.SecondaryColor=Color3.fromRGB(255,120,30); flame.Parent=candle

    local light = Instance.new("PointLight"); light.Brightness=3; light.Range=18; light.Color=Color3.fromRGB(255,180,60); light.Parent=candle

    local basePos = position; local offset = math.random(0,628)/100; local speed = 0.4+math.random(0,40)/100
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not candle.Parent then if conn then conn:Disconnect() end return end
        offset += dt * speed
        local ny = basePos.Y + math.sin(offset)*0.6
        candle.CFrame = CFrame.new(basePos.X, ny, basePos.Z)
        wick.CFrame = CFrame.new(basePos.X, ny+0.72, basePos.Z)
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
                                                        LobbyModel = Instance.new("Model"); LobbyModel.Name = "IslandLobby"; LobbyModel.Parent = workspace
                                                    end
                                                end

                                                    --===========================================================
                                                    -- PAD STATIONS
                                                    --===========================================================
                                                    local function createPadStation(idx, data)
                                                        local pad = makePart("DuelPad_"..idx, Vector3.new(11,0.25,11), CFrame.new(data.pos), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                        pad.Color = Color3.fromRGB(28,24,38)
                                                        squareParts[idx] = pad

                                                        local borders = {}
                                                        local bOff = 5.22
                                                        for _,bd in ipairs({
                                                            {Vector3.new(11,0.34,0.55), Vector3.new(0,0.08,-bOff)},
                                                            {Vector3.new(11,0.34,0.55), Vector3.new(0,0.08, bOff)},
                                                            {Vector3.new(0.55,0.34,11), Vector3.new(-bOff,0.08,0)},
                                                            {Vector3.new(0.55,0.34,11), Vector3.new( bOff,0.08,0)},
                                                        }) do
                                                            local bp = makePart("PadBorder_"..idx, bd[1], CFrame.new(data.pos+bd[2]), "Bright yellow", Enum.Material.Neon, LobbyModel, false, true)
                                                            bp.Color = Color3.fromRGB(255,205,64)
                                                            table.insert(borders, bp)
                                                        end

                                                        local bb = Instance.new("BillboardGui"); bb.Name="PadCounter"
                                                        bb.Size=UDim2.new(7,0,2.2,0); bb.StudsOffset=Vector3.new(0,4.4,0)
                                                        bb.AlwaysOnTop=true; bb.LightInfluence=0; bb.MaxDistance=90; bb.Parent=pad
                                                        local counter = Instance.new("TextLabel"); counter.Name="Count"
                                                        counter.Size=UDim2.new(1,0,1,0); counter.BackgroundTransparency=1
                                                        counter.Font=Enum.Font.LuckiestGuy; counter.TextScaled=true
                                                        counter.TextColor3=Color3.fromRGB(255,214,64)
                                                        counter.TextStrokeColor3=Color3.fromRGB(0,0,0); counter.TextStrokeTransparency=0
                                                        counter.Text="0/2"; counter.Parent=bb

                                                        makePart("PadBase_"..idx, Vector3.new(13,1.4,13), CFrame.new(data.pos+Vector3.new(0,-0.8,0)), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)

                                                        local sign = makePart("PadSign_"..idx, Vector3.new(9.5,4.6,0.2), CFrame.new(data.signPos, data.signLook), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                        local gui = Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.AlwaysOnTop=true; gui.LightInfluence=0; gui.Parent=sign

                                                        local holder = Instance.new("Frame"); holder.Size=UDim2.new(1,0,1,0)
                                                        holder.BackgroundColor3=Color3.fromRGB(12,10,20); holder.BackgroundTransparency=0.12
                                                        holder.BorderSizePixel=0; holder.Parent=gui
                                                        Instance.new("UICorner", holder).CornerRadius=UDim.new(0.08,0)

                                                        local title = Instance.new("TextLabel"); title.Name="Title"
                                                        title.BackgroundTransparency=1; title.Size=UDim2.new(1,0,0.40,0); title.Position=UDim2.new(0,0,0.06,0)
                                                        title.Font=Enum.Font.LuckiestGuy; title.TextScaled=true; title.TextColor3=data.house.neon
                                                        title.TextStrokeColor3=Color3.fromRGB(0,0,0); title.TextStrokeTransparency=0.35
                                                        title.Text=string.upper(data.house.name); title.Parent=holder

                                                        local status = Instance.new("TextLabel"); status.Name="Status"
                                                        status.BackgroundTransparency=1; status.Size=UDim2.new(1,0,0.30,0); status.Position=UDim2.new(0,0,0.54,0)
                                                        status.Font=Enum.Font.FredokaOne; status.TextScaled=true; status.TextColor3=Color3.fromRGB(230,230,230)
                                                        status.TextStrokeColor3=Color3.fromRGB(0,0,0); status.TextStrokeTransparency=0.4
                                                        status.Text="0/2 · TOCA PARA UNIRTE"; status.Parent=holder

                                                        padStations[idx] = { part=pad, sign=sign, title=title, status=status, house=data.house, borders=borders, counter=counter }
                                                    end

                                                    for i,data in ipairs(PAD_DATA) do createPadStation(i, data) end

                                                    -- (los pads amarillos van sobre los caminos de la isla; sin plaza ni puerta del salón)

                                                    local function updateBoardForPad(idx)
                                                        local sq=squares[idx]; local st=padStations[idx]; local pad=squareParts[idx]
                                                        if not sq or not st or not pad then return end
                                                        local occupied = (#sq.players>0) or sq.inBattle or sq.countdown
                                                        local borderCol = sq.inBattle and Color3.fromRGB(255,70,70) or (#sq.players==1 and not sq.countdown) and Color3.fromRGB(120,255,120) or Color3.fromRGB(255,205,64)
                                                        if st.borders then for _,bp in ipairs(st.borders) do bp.Color = borderCol end end
                                                        if st.counter then st.counter.Text = tostring(#sq.players).."/2"; st.counter.TextColor3 = borderCol end
                                                        pad.Color = occupied and Color3.fromRGB(48,22,26) or Color3.fromRGB(28,24,38)
                                                        if sq.inBattle then st.status.Text="EN BATALLA"; st.status.TextColor3=Color3.fromRGB(255,100,100)
                                                        elseif sq.countdown then st.status.Text="PREPARANDO"; st.status.TextColor3=Color3.fromRGB(255,215,0)
                                                        elseif #sq.players==0 then st.status.Text="0/2 · TOCA PARA UNIRTE"; st.status.TextColor3=Color3.fromRGB(210,210,210)
                                                        elseif #sq.players==1 then st.status.Text="1/2 · ESPERANDO"; st.status.TextColor3=Color3.fromRGB(120,255,120)
                                                        else st.status.Text="2/2 · LISTOS"; st.status.TextColor3=Color3.fromRGB(255,255,255)
                                                        end
                                                        end

                                                            for i=1,4 do updateBoardForPad(i) end

                                                                                        --===========================================================
                                                                                        -- ARENAS
                                                                                        --===========================================================
                                                                                        local function buildArena(idx)
                                                                                            local center=ARENA_CENTERS[idx]
                                                                                            local model=Instance.new("Model"); model.Name="Arena_"..idx; model.Parent=workspace

                                                                                            local AW,AD,AH=40,132,38
                                                                                            local house=HOUSES[idx]

                                                                                            local function ap(name,size,off,color,mat,cc)
                                                                                                return makePart(name,size,CFrame.new(center+off),color,mat,model,cc~=false,true)
                                                                                            end

                                                                                            local aFloor=ap("Floor",Vector3.new(AW,2,AD),Vector3.new(0,-1,0),"Dark stone grey",Enum.Material.SmoothPlastic,true)
                                                                                            addTex(aFloor,Enum.NormalId.Top,5,5)

                                                                                            local function wall(name,size,off)
                                                                                                local w=ap(name,size,off,"Dark stone grey",Enum.Material.SmoothPlastic,true)
                                                                                                addTex(w,Enum.NormalId.Front,7,7); addTex(w,Enum.NormalId.Back,7,7); return w
                                                                                            end

                                                                                            wall("WallBack",  Vector3.new(AW+5,AH,2.5),   Vector3.new(0,AH/2-1,-AD/2))
                                                                                            wall("WallFront", Vector3.new(AW+5,AH,2.5),   Vector3.new(0,AH/2-1, AD/2))
                                                                                            wall("WallLeft",  Vector3.new(2.5,AH,AD+5),   Vector3.new(-AW/2,AH/2-1,0))
                                                                                            wall("WallRight", Vector3.new(2.5,AH,AD+5),   Vector3.new( AW/2,AH/2-1,0))
                                                                                            ap("Ceiling",Vector3.new(AW+5,2.5,AD+5),Vector3.new(0,AH-1,0),"Dark stone grey",Enum.Material.SmoothPlastic,true)

                                                                                            for z=-AD/2+10,AD/2-10,12 do ap("VaultZ_"..z,Vector3.new(AW,2,2),Vector3.new(0,AH-2.5,z),"Dark stone grey",Enum.Material.SmoothPlastic,false) end
                                                                                            for x=-AW/2+8,AW/2-8,10 do  ap("VaultX_"..x,Vector3.new(2,2,AD),Vector3.new(x,AH-2.5,0),"Dark stone grey",Enum.Material.SmoothPlastic,false) end

                                                                                            for _,pOff in ipairs({Vector3.new(-AW/2+3,0,-AD/2+3),Vector3.new(-AW/2+3,0,AD/2-3),Vector3.new(AW/2-3,0,-AD/2+3),Vector3.new(AW/2-3,0,AD/2-3)}) do
                                                                                                addGothicPillar(center.X+pOff.X,center.Y+pOff.Y,center.Z+pOff.Z,AH-2,model)
                                                                                            end
                                                                                            for _,zOff in ipairs({-22,22}) do
                                                                                                addGothicArch(center.X-AW/2+1,center.Y,center.Z+zOff,14,28,2,model,90)
                                                                                                addGothicArch(center.X+AW/2-1,center.Y,center.Z+zOff,14,28,2,model,90)
                                                                                            end

                                                                                            local vColors={house.neon,Color3.fromRGB(255,255,180),house.neon}
                                                                                            for _,xOff in ipairs({-10,0,10}) do
                                                                                                addStainedGlass(center+Vector3.new(xOff,AH-12,-AD/2+1),Vector3.new(7,14,0.4),vColors,model)
                                                                                            end

                                                                                            for i=1,10 do
                                                                                                createFlyingCandle(Vector3.new(center.X+math.random(-AW/2+4,AW/2-4), center.Y+AH-math.random(5,14), center.Z+math.random(-AD/2+4,AD/2-4)), model)
                                                                                            end

                                                                                            for _,tp in ipairs({
                                                                                                Vector3.new(-AW/2+3,12,-AD/2+9), Vector3.new(-AW/2+3,12,AD/2-9),
                                                                                                Vector3.new(AW/2-3,12,-AD/2+9),  Vector3.new(AW/2-3,12,AD/2-9),
                                                                                                Vector3.new(0,12,-AD/2+9),        Vector3.new(0,12,AD/2-9),
                                                                                                }) do addWallTorch(center+tp, model) end

                                                                                                arenaData[idx] = {
                                                                                                spawnA   = center+Vector3.new(-12,3.8,-36),
                                                                                                spawnB   = center+Vector3.new( 12,3.8, 36),
                                                                                                centerPos= center+Vector3.new(0,3.5,0),
                                                                                                }
                                                                                            end

                                                                                            for i=1,4 do buildArena(i) end

                                                                                            --===========================================================
                                                                                            -- ROUND SYSTEM
                                                                                            --===========================================================
                                                                                            local function removeFromSquare(player)
                                                                                                local idx=playerSquare[player]; if not idx then return end
                                                                                                local sq=squares[idx]
                                                                                                for k,p in ipairs(sq.players) do if p==player then table.remove(sq.players,k); break end end
                                                                                                playerSquare[player]=nil; updateBoardForPad(idx)
                                                                                            end

                                                                                            local function endBattle(squareIdx)
                                                                                                local sq=squares[squareIdx]
                                                                                                if sq then sq.inBattle=false; sq.countdown=false; updateBoardForPad(squareIdx) end
                                                                                            end

                                                                                            local function startRound(p1, p2, roundNum, arenaIdx, wins)
                                                                                                RE_RoundUpdate:FireClient(p1, roundNum, ROUND_TIME, wins[1], wins[2])
                                                                                                RE_RoundUpdate:FireClient(p2, roundNum, ROUND_TIME, wins[2], wins[1])

                                                                                                local arena=arenaData[arenaIdx]
                                                                                                giveFighterSetup(p1, HOUSES[arenaIdx].name)
                                                                                                giveFighterSetup(p2, HOUSES[arenaIdx].name)
                                                                                                task.wait(0.25)

                                                                                                teleportTo(p1, arena.spawnA, arena.spawnB)
                                                                                                teleportTo(p2, arena.spawnB, arena.spawnA)
                                                                                                task.wait(0.2)
                                                                                                freezePlayer(p1, false); freezePlayer(p2, false)

                                                                                                local roundFinished=false; local roundWinner=nil

                                                                                                local function onDeath(dead, survivor)
                                                                                                    if roundFinished then return end
                                                                                                    roundFinished=true; roundWinner=survivor
                                                                                                end

                                                                                                local function watchDeath(player, opp)
                                                                                                    local char=player.Character; if not char then return end
                                                                                                    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
                                                                                                    hum.Died:Connect(function() if playerDuel[player] then onDeath(player, opp) end end)
                                                                                                    end

                                                                                                        watchDeath(p1, p2); watchDeath(p2, p1)

                                                                                                        local timeLeft=ROUND_TIME
                                                                                                        local timerConn
                                                                                                        timerConn=RunService.Heartbeat:Connect(function(dt)
                                                                                                            if roundFinished then if timerConn then timerConn:Disconnect() end return end
                                                                                                            timeLeft -= dt
                                                                                                            RE_RoundUpdate:FireClient(p1, roundNum, math.ceil(timeLeft), wins[1], wins[2])
                                                                                                            RE_RoundUpdate:FireClient(p2, roundNum, math.ceil(timeLeft), wins[2], wins[1])
                                                                                                            if timeLeft<=0 then roundFinished=true; roundWinner=nil; if timerConn then timerConn:Disconnect() end end
                                                                                                        end)

                                                                                                        while not roundFinished do task.wait(0.1) end
                                                                                                        if timerConn then timerConn:Disconnect() end
                                                                                                        return roundWinner
                                                                                                    end

                                                                                                    local function startDuel(squareIdx)
                                                                                                        local sq=squares[squareIdx]
                                                                                                        if sq.inBattle or sq.countdown or #sq.players<2 then return end

                                                                                                        sq.countdown=true; updateBoardForPad(squareIdx)
                                                                                                        local p1=sq.players[1]; local p2=sq.players[2]
                                                                                                        freezePlayer(p1, true); freezePlayer(p2, true)

                                                                                                        for t=5,1,-1 do
                                                                                                            if not playerSquare[p1] or not playerSquare[p2] then
                                                                                                                freezePlayer(p1,false); freezePlayer(p2,false)
                                                                                                                sq.countdown=false; updateBoardForPad(squareIdx); return
                                                                                                            end
                                                                                                            RE_Countdown:FireClient(p1, t); RE_Countdown:FireClient(p2, t)
                                                                                                            task.wait(1)
                                                                                                        end

                                                                                                        sq.countdown=false; sq.inBattle=true
                                                                                                        playerSquare[p1]=nil; playerSquare[p2]=nil; sq.players={}; updateBoardForPad(squareIdx)

                                                                                                        local arena=arenaData[squareIdx]
                                                                                                        if not arena then endBattle(squareIdx); return end

                                                                                                        playerDuel[p1]={opponent=p2, arenaIdx=squareIdx}
                                                                                                        playerDuel[p2]={opponent=p1, arenaIdx=squareIdx}

                                                                                                        RE_BattleStart:FireClient(p1, p2.Name)
                                                                                                        RE_BattleStart:FireClient(p2, p1.Name)
                                                                                                        task.wait(2.0)

                                                                                                        teleportTo(p1, arena.spawnA, arena.spawnB)
                                                                                                        teleportTo(p2, arena.spawnB, arena.spawnA)
                                                                                                        freezePlayer(p1,false); freezePlayer(p2,false)

                                                                                                        local wins={0,0}; local overallWinner=nil; local overallLoser=nil

                                                                                                        for round=1,TOTAL_ROUNDS do
                                                                                                            if not playerDuel[p1] or not playerDuel[p2] then break end
                                                                                                            local rWinner=startRound(p1, p2, round, squareIdx, wins)
                                                                                                            if rWinner==p1 then wins[1]+=1 elseif rWinner==p2 then wins[2]+=1 end
                                                                                                            RE_RoundUpdate:FireClient(p1, round, 0, wins[1], wins[2])
                                                                                                            RE_RoundUpdate:FireClient(p2, round, 0, wins[2], wins[1])
                                                                                                            if wins[1]>=2 then overallWinner=p1; overallLoser=p2; break end
                                                                                                            if wins[2]>=2 then overallWinner=p2; overallLoser=p1; break end
                                                                                                            if round<TOTAL_ROUNDS then freezePlayer(p1,true); freezePlayer(p2,true); task.wait(2) end
                                                                                                        end

                                                                                                        if not overallWinner then
                                                                                                            if wins[1]>wins[2] then overallWinner=p1; overallLoser=p2
                                                                                                            elseif wins[2]>wins[1] then overallWinner=p2; overallLoser=p1 end
                                                                                                            end

                                                                                                                if overallWinner then
                                                                                                                    RE_BattleEnd:FireClient(overallWinner, overallWinner.Name, true)
                                                                                                                    if overallLoser then RE_BattleEnd:FireClient(overallLoser, overallWinner.Name, false) end
                                                                                                                else
                                                                                                                    RE_BattleEnd:FireClient(p1, "EMPATE", false); RE_BattleEnd:FireClient(p2, "EMPATE", false)
                                                                                                                end

                                                                                                                playerDuel[p1]=nil; playerDuel[p2]=nil; pendingCast[p1]=nil; pendingCast[p2]=nil

                                                                                                                task.delay(4, function()
                                                                                                                    if overallWinner and overallWinner.Character then returnToLobby(overallWinner) end
                                                                                                                    if overallLoser then
                                                                                                                        if not overallLoser.Character then overallLoser:LoadCharacter(); task.wait(0.8) end
                                                                                                                        returnToLobby(overallLoser)
                                                                                                                    end
                                                                                                                endBattle(squareIdx)
                                                                                                            end)
                                                                                                        end

                                                                                                        --===========================================================
                                                                                                        -- TOUCH PADS
                                                                                                        --===========================================================
                                                                                                        for i,sqPart in ipairs(squareParts) do
                                                                                                            sqPart.Touched:Connect(function(hit)
                                                                                                                local char=hit and hit.Parent
                                                                                                                local player=char and Players:GetPlayerFromCharacter(char)
                                                                                                                if not player then return end
                                                                                                                if playerSquare[player] or playerDuel[player] then return end
                                                                                                                local sq=squares[i]
                                                                                                                if sq.inBattle or sq.countdown or #sq.players>=2 then return end
                                                                                                                for _,p in ipairs(sq.players) do if p==player then return end end
                                                                                                                playerSquare[player]=i; table.insert(sq.players, player); updateBoardForPad(i)
                                                                                                                if #sq.players==2 then task.spawn(startDuel, i) end
                                                                                                            end)
                                                                                                        end

                                                                                                        local SQUARE_RADIUS=6.0
                                                                                                        RunService.Heartbeat:Connect(function()
                                                                                                            for i,sqPos in ipairs(PAD_DATA) do
                                                                                                                local sq=squares[i]
                                                                                                                if not sq.inBattle and not sq.countdown then
                                                                                                                    for k=#sq.players,1,-1 do
                                                                                                                        local pl=sq.players[k]; local char=pl and pl.Character
                                                                                                                        local hrp=char and char:FindFirstChild("HumanoidRootPart")
                                                                                                                        if not hrp then table.remove(sq.players,k); playerSquare[pl]=nil; updateBoardForPad(i)
                                                                                                                        else
                                                                                                                            local dist=(Vector3.new(hrp.Position.X,sqPos.pos.Y,hrp.Position.Z)-sqPos.pos).Magnitude
                                                                                                                            if dist>SQUARE_RADIUS then table.remove(sq.players,k); playerSquare[pl]=nil; updateBoardForPad(i) end
                                                                                                                        end
                                                                                                                    end
                                                                                                                end
                                                                                                            end
                                                                                                        end)

                                                                                                        --===========================================================
                                                                                                        -- PLAYER EVENTS
                                                                                                        --===========================================================
                                                                                                        Players.PlayerAdded:Connect(function(player)
                                                                                                            local ls=Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player
                                                                                                            local kills=Instance.new("IntValue"); kills.Name="Kills"; kills.Value=0; kills.Parent=ls
                                                                                                            loadKills(player)
                                                                                                            player.CharacterAdded:Connect(function(char)
                                                                                                                removeFromSquare(player); pendingCast[player]=nil
                                                                                                                local hrp=char:WaitForChild("HumanoidRootPart"); task.wait(0.15)
                                                                                                                local duelInfo = playerDuel[player]
                                                                                                                if duelInfo then
                                                                                                                    local arena = arenaData[duelInfo.arenaIdx]
                                                                                                                    if arena then
                                                                                                                        freezePlayer(player, false)
                                                                                                                        hrp.CFrame = CFrame.new(arena.centerPos + Vector3.new(math.random(-4,4), 0, math.random(-4,4)))
                                                                                                                        return
                                                                                                                    end
                                                                                                                end
                                                                                                                playerDuel[player]=nil
                                                                                                                hrp.CFrame=CFrame.new(LOBBY_SPAWN+Vector3.new(math.random(-8,8),0,math.random(-8,8)))
                                                                                                            end)
                                                                                                        end)

                                                                                                        Players.PlayerRemoving:Connect(function(player)
                                                                                                            removeFromSquare(player); saveKills(player)
                                                                                                            if playerDuel[player] then
                                                                                                                local info=playerDuel[player]; local opp=info.opponent
                                                                                                                playerDuel[player]=nil
                                                                                                                if opp and playerDuel[opp] then
                                                                                                                    playerDuel[opp]=nil; RE_BattleEnd:FireClient(opp, opp.Name, true)
                                                                                                                    task.spawn(function()
                                                                                                                        task.wait(2)
                                                                                                                        local c=opp.Character
                                                                                                                        if c and c:FindFirstChild("HumanoidRootPart") then c.HumanoidRootPart.CFrame=CFrame.new(LOBBY_SPAWN) end
                                                                                                                        local sq=squares[info.arenaIdx]
                                                                                                                        if sq then sq.inBattle=false; sq.countdown=false; updateBoardForPad(info.arenaIdx) end
                                                                                                                    end)
                                                                                                                end
                                                                                                            end
                                                                                                        end)

                                                                                                        task.spawn(function()
                                                                                                            while true do task.wait(60)
                                                                                                                for _,plr in ipairs(Players:GetPlayers()) do saveKills(plr) end
                                                                                                            end
                                                                                                        end)

                                                                                                        print("⚡ [DuelGame v11.0] Server Script loaded — 7 spells, epic clash system ⚡")
end

-- FIN PARTE 1
