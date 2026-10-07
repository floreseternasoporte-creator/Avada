--===========================================================
-- AVADA DUELING - SERVER PARTE 1 DE 2: NUCLEO Y COMBATE
-- Coloca en: ServerScriptService > Script (nombre sugerido: AvadaParte1)
-- Pega TAMBIEN la Parte 2 en OTRO Script de ServerScriptService.
-- El orden de carga no importa: la Parte 2 espera sola a esta Parte 1.
-- Si en Roblox el pegado no llega hasta la ultima linea (-- FIN PARTE 1),
-- el texto se corto: avisame y lo divido en 3 partes.
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
-- Isla circular: los 4 pads amarillos van sobre los 4 caminos diagonales (r=19),
-- letreros al final de cada camino (r=27.5) mirando al centro, spawn en el círculo mágico.
local PAD_DATA = {
{ pos = Vector3.new(-13.4,3.6,-13.4), house=HOUSES[1], signPos=Vector3.new(-19.4,8.5,-19.4), signLook=Vector3.new(-13.4,8.5,-13.4) },
{ pos = Vector3.new( 13.4,3.6,-13.4), house=HOUSES[2], signPos=Vector3.new( 19.4,8.5,-19.4), signLook=Vector3.new( 13.4,8.5,-13.4) },
{ pos = Vector3.new(-13.4,3.6, 13.4), house=HOUSES[3], signPos=Vector3.new(-19.4,8.5, 19.4), signLook=Vector3.new(-13.4,8.5, 13.4) },
{ pos = Vector3.new( 13.4,3.6, 13.4), house=HOUSES[4], signPos=Vector3.new( 19.4,8.5, 19.4), signLook=Vector3.new( 13.4,8.5, 13.4) },
}
 
local ARENA_CENTERS = {
Vector3.new(0,5,320), Vector3.new(0,5,460),
Vector3.new(0,5,600), Vector3.new(0,5,740),
}
 
--===========================================================
-- DATA STORES
--===========================================================
local KillsStore   = DataStoreService:GetDataStore("DuelKills_v11")
local KillsOrdered = DataStoreService:GetOrderedDataStore("DuelKillsRank_v11")
 
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
-- ESTADO COMPARTIDO CON LA PARTE 2 (no borrar esta seccion)
-- Las tablas se comparten por referencia: la Parte 2 escribe en las
-- mismas tablas que esta Parte 1 lee durante el combate.
--===========================================================
shared.AvadaDuel = {
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
-- FIN PARTE 1
