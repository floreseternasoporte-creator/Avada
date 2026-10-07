--===========================================================
-- AVADA DUELING - SERVER PARTE 2 DE 2: MUNDO (LOBBY, ARENAS, RONDAS)
-- Coloca en: ServerScriptService > Script (nombre sugerido: AvadaParte2)
-- Necesita la Parte 1 en otro Script de ServerScriptService.
-- Esta parte ESPERA sola a que la Parte 1 este lista (shared.AvadaDuel).
-- Si en Roblox el pegado no llega hasta la ultima linea (-- FIN PARTE 2),
-- el texto se corto: avisame y lo divido en 3 partes.
--===========================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Espera a que la Parte 1 publique el estado compartido
local S
repeat
    task.wait(0.1)
    S = shared.AvadaDuel
until S

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
                                                local spawnLoc = workspace:FindFirstChild("LobbySpawn")
                                                if not spawnLoc then
                                                    spawnLoc = Instance.new("SpawnLocation"); spawnLoc.Name="LobbySpawn"
                                                    spawnLoc.Size=Vector3.new(6,1,6); spawnLoc.CFrame=CFrame.new(0,3,0)
                                                    spawnLoc.Transparency=1; spawnLoc.CanCollide=true; spawnLoc.Anchored=true
                                                    spawnLoc.Neutral=true; spawnLoc.Parent=workspace
                                                end
 
                                                local LobbyModel = workspace:FindFirstChild("IslandLobby")
                                                if LobbyModel then LobbyModel:Destroy() end
                                                LobbyModel = Instance.new("Model"); LobbyModel.Name="IslandLobby"; LobbyModel.Parent=workspace
 

                                                local LW, LD, LH = 78, 62, 40 -- compatibilidad: el leaderboard usa LD

                                                -- Iluminación diurna tipo diorama (y fuera el tinte dorado sobre la tabla)
                                                local Lighting = game:GetService("Lighting")
                                                Lighting.ClockTime = 13.2
                                                Lighting.Brightness = 2
                                                Lighting.Ambient = Color3.fromRGB(150,150,168)
                                                Lighting.OutdoorAmbient = Color3.fromRGB(170,175,190)

                                                local function islCyl(name, h, d, cf, col, collide)
                                                    local part = Instance.new("Part"); part.Name=name; part.Shape=Enum.PartType.Cylinder
                                                    part.Size=Vector3.new(h,d,d); part.CFrame=cf*CFrame.Angles(0,0,math.rad(90))
                                                    part.BrickColor=BrickColor.new("White"); part.Color=col; part.Material=Enum.Material.SmoothPlastic
                                                    part.Anchored=true; part.CanCollide=(collide~=false); part.CastShadow=false; part.Parent=LobbyModel
                                                    return part
                                                end

                                                -- Isla flotante por capas, como el corte de la imagen: césped, tierra y piedra
                                                islCyl("IslandGrass", 1.2, 78, CFrame.new(0,1.4,0), Color3.fromRGB(84,158,66), true)
                                                islCyl("IslandDirt", 2.0, 75.5, CFrame.new(0,0.05,0), Color3.fromRGB(112,76,45), false)
                                                islCyl("IslandStone", 2.0, 71, CFrame.new(0,-1.7,0), Color3.fromRGB(74,74,86), false)
                                                islCyl("IslandTip", 3.0, 42, CFrame.new(0,-4.0,0), Color3.fromRGB(62,62,74), false)
                                                islCyl("IslandTip2", 2.6, 22, CFrame.new(0,-6.4,0), Color3.fromRGB(54,54,66), false)

                                                -- Borde de piedras alrededor de la isla
                                                for i=0,37 do
                                                    local a = (i/38)*math.pi*2
                                                    local rim = makePart("IslandRim", Vector3.new(4.6,0.8,1.3), CFrame.new(math.cos(a)*37.8, 2.15, math.sin(a)*37.8)*CFrame.Angles(0,-a-math.pi/2,0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    rim.Color = (i%2==0) and Color3.fromRGB(66,66,78) or Color3.fromRGB(76,76,90)
                                                end

                                                -- 4 caminos de losas en X hacia el centro (los pads amarillos van encima)
                                                for _,pd in ipairs({{1,-1},{-1,-1},{-1,1},{1,1}}) do
                                                    local dx, dz = pd[1]*0.7071, pd[2]*0.7071
                                                    local yaw = -math.atan2(dz, dx)
                                                    local px, pz = -dz, dx
                                                    for r=13.2, 35, 3.35 do
                                                        local cx, cz = dx*r, dz*r
                                                        local slab = makePart("PathSlab", Vector3.new(3.15,0.35,6.9), CFrame.new(cx,2.16,cz)*CFrame.Angles(0,yaw,0), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                        slab.Color = ((r*10)%2 < 1) and Color3.fromRGB(126,126,138) or Color3.fromRGB(110,110,124)
                                                        for _,sd2 in ipairs({-1,1}) do
                                                            local curb = makePart("PathCurb", Vector3.new(3.15,0.52,0.55), CFrame.new(cx+px*3.45*sd2, 2.24, cz+pz*3.45*sd2)*CFrame.Angles(0,yaw,0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                            curb.Color = Color3.fromRGB(82,82,96)
                                                        end
                                                    end
                                                end

                                                -- Círculo mágico central: anillos neón cian->magenta que giran, estrella y runas
                                                local spinParts = {}
                                                local function spinAdd(part, radius, y, baseAng, dir)
                                                    table.insert(spinParts, {part=part, r=radius, y=y, a=baseAng, dir=dir})
                                                end
                                                islCyl("MagicRim", 0.6, 25.8, CFrame.new(0,2.2,0), Color3.fromRGB(52,50,66), false)
                                                islCyl("MagicDisc", 0.5, 24.5, CFrame.new(0,2.28,0), Color3.fromRGB(22,20,34), true)
                                                islCyl("MagicCore", 0.56, 7, CFrame.new(0,2.3,0), Color3.fromRGB(15,13,25), false)
                                                local function neonRing(radius, y, segCount, segLen, thick, dir)
                                                    for i=0, segCount-1 do
                                                        local a = (i/segCount)*math.pi*2
                                                        local col = Color3.fromRGB(80,220,255):Lerp(Color3.fromRGB(255,90,220), i/segCount)
                                                        local seg = makePart("MagicRingSeg", Vector3.new(segLen,0.32,thick), CFrame.new(math.cos(a)*radius, y, math.sin(a)*radius)*CFrame.Angles(0,-a-math.pi/2,0), "White", Enum.Material.Neon, LobbyModel, false, true)
                                                        seg.Color = col
                                                        spinAdd(seg, radius, y, a, dir)
                                                    end
                                                end
                                                neonRing(10.6, 2.62, 28, 2.35, 1.05, 1)
                                                neonRing(7.6, 2.62, 22, 2.1, 0.7, -1)
                                                for _,rot in ipairs({0, math.pi/3}) do
                                                    for k=0,2 do
                                                        local a1 = rot + k*(math.pi*2/3)
                                                        local a2 = rot + (k+1)*(math.pi*2/3)
                                                        local x1,z1 = math.cos(a1)*6.2, math.sin(a1)*6.2
                                                        local x2,z2 = math.cos(a2)*6.2, math.sin(a2)*6.2
                                                        local dx,dz = x2-x1, z2-z1
                                                        local bar = makePart("MagicStar", Vector3.new(math.sqrt(dx*dx+dz*dz),0.3,0.55), CFrame.new((x1+x2)/2,2.62,(z1+z2)/2)*CFrame.Angles(0,-math.atan2(dz,dx),0), "White", Enum.Material.Neon, LobbyModel, false, true)
                                                        bar.Color = Color3.fromRGB(170,240,255)
                                                    end
                                                end
                                                for i=0,7 do
                                                    local a = i*(math.pi/4) + math.pi/8
                                                    local rc = (i%2==0) and Color3.fromRGB(110,220,255) or Color3.fromRGB(255,120,220)
                                                    for b=0,2 do
                                                        local off = (b-1)*0.45
                                                        local rb = makePart("MagicRune", Vector3.new(0.8,0.34,0.2), CFrame.new(math.cos(a)*9.0 - math.sin(a)*off, 2.62, math.sin(a)*9.0 + math.cos(a)*off)*CFrame.Angles(0,-a,0), "White", Enum.Material.Neon, LobbyModel, false, true)
                                                        rb.Color = rc
                                                    end
                                                end
                                                local glowPart = makePart("MagicGlow", Vector3.new(1,1,1), CFrame.new(0,4.4,0), "White", Enum.Material.Neon, LobbyModel, false, true)
                                                glowPart.Transparency = 1
                                                local gl = Instance.new("PointLight"); gl.Brightness=2.2; gl.Range=22; gl.Color=Color3.fromRGB(150,130,255); gl.Parent=glowPart
                                                local em = Instance.new("ParticleEmitter")
                                                em.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(120,230,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(255,120,230))}
                                                em.LightEmission=1
                                                em.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.35), NumberSequenceKeypoint.new(1,0)}
                                                em.Speed=NumberRange.new(1.5,3.5); em.Lifetime=NumberRange.new(1.2,2.4); em.Rate=26; em.SpreadAngle=Vector2.new(55,55); em.Parent=glowPart
                                                local spinAngle = 0
                                                RunService.Heartbeat:Connect(function(dt)
                                                    spinAngle += dt*0.35
                                                    for _,sp in ipairs(spinParts) do
                                                        local a = sp.a + spinAngle*sp.dir
                                                        sp.part.CFrame = CFrame.new(math.cos(a)*sp.r, sp.y, math.sin(a)*sp.r)*CFrame.Angles(0,-a-math.pi/2,0)
                                                    end
                                                end)

                                                -- Arbustos cúbicos de seto, plantas, rocas, cristales y losas con runas (como la imagen)
                                                local function islWedge(name, size, cf, col, neon)
                                                    local part = Instance.new("WedgePart"); part.Name=name; part.Size=size; part.CFrame=cf
                                                    part.BrickColor=BrickColor.new("White"); part.Color=col
                                                    part.Material=neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
                                                    part.Anchored=true; part.CanCollide=false; part.CastShadow=false; part.Parent=LobbyModel
                                                    return part
                                                end
                                                for _,bp in ipairs({{-26,-13,3.4},{-13,-26,2.7},{26,-13,3.4},{13,-26,2.7},{-27,10,2.7},{27,10,3.4}}) do
                                                    local bush = makePart("TopiaryBush", Vector3.new(bp[3],bp[3]*0.9,bp[3]), CFrame.new(bp[1],2+bp[3]*0.45,bp[2]), "Dark green", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    bush.Color = Color3.fromRGB(30,86,36)
                                                    local top = makePart("TopiaryTop", Vector3.new(bp[3]*0.8,bp[3]*0.45,bp[3]*0.8), CFrame.new(bp[1],2+bp[3]*1.1,bp[2]), "Bright green", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    top.Color = Color3.fromRGB(48,118,52)
                                                end
                                                for _,pp in ipairs({{7,-25},{-7,-25},{25,7},{-25,7},{7,22},{-7,22},{24,-7},{-24,-7}}) do
                                                    makePart("PlantRock", Vector3.new(0.8,0.5,0.8), CFrame.new(pp[1],2.25,pp[2]), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    for li=0,2 do
                                                        local leaf = makePart("PlantLeaf", Vector3.new(0.3,1.15,0.55), CFrame.new(pp[1]+math.sin(li*2.1)*0.4, 2.8, pp[2]+math.cos(li*2.1)*0.4)*CFrame.Angles(math.rad(18), li*2.1, math.rad(-14)), "Bright green", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                        leaf.Color = Color3.fromRGB(42,112,46)
                                                    end
                                                end
                                                for _,rp in ipairs({{24,-14},{-24,-14},{26,4},{-26,4},{4,-28},{-4,-28}}) do
                                                    islWedge("IslandRock", Vector3.new(1.6+(rp[1]%3)*0.3, 1.3, 1.5), CFrame.new(rp[1],2.6,rp[2])*CFrame.Angles(0,math.rad(rp[1]*7),0), Color3.fromRGB(112,112,122), false)
                                                end
                                                for _,cp in ipairs({{30,-6,Color3.fromRGB(190,110,255)},{-30,-6,Color3.fromRGB(110,220,255)},{30,16,Color3.fromRGB(110,220,255)},{-30,16,Color3.fromRGB(255,120,220)}}) do
                                                    islWedge("IslandCrystalRock", Vector3.new(2.2,0.7,1.9), CFrame.new(cp[1],2.3,cp[2]), Color3.fromRGB(40,38,54), false)
                                                    for ci,ch in ipairs({1.5,2.4,1.8}) do
                                                        local shard = islWedge("IslandCrystal", Vector3.new(0.85,ch,0.85), CFrame.new(cp[1]+(ci-2)*0.8, 2.5+ch/2, cp[2]+((ci%2)*0.6-0.3))*CFrame.Angles(math.rad((ci%2)*8-4), math.rad(45), math.rad((ci%3)*5-5)), cp[3], true)
                                                        if ci == 2 then local cl = Instance.new("PointLight"); cl.Brightness=1.3; cl.Range=8; cl.Color=cp[3]; cl.Parent=shard end
                                                    end
                                                end
                                                for ri,rp in ipairs({{10,-21},{-10,-21},{21,10},{-21,10},{0,-32}}) do
                                                    local slab = makePart("RuneSlab", Vector3.new(2.3,0.35,2.3), CFrame.new(rp[1],2.18,rp[2])*CFrame.Angles(0,math.rad(ri*24),0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    slab.Color = Color3.fromRGB(70,70,84)
                                                    local rc = (ri%2==0) and Color3.fromRGB(255,120,220) or Color3.fromRGB(110,220,255)
                                                    for b=0,1 do
                                                        local rb = makePart("RuneSlabMark", Vector3.new(0.9,0.14,0.22), CFrame.new(rp[1]+(b-0.5)*0.5, 2.42, rp[2]+(b-0.5)*0.3)*CFrame.Angles(0,math.rad(ri*24 + b*50),0), "White", Enum.Material.Neon, LobbyModel, false, true)
                                                        rb.Color = rc
                                                    end
                                                end
                                                for i=1,42 do
                                                    local a = i*2.39996
                                                    local r = 13 + (i%19)
                                                    local x, z = math.cos(a)*r, math.sin(a)*r
                                                    local nearPad = false
                                                    for _,pd2 in ipairs(PAD_DATA) do
                                                        if math.abs(x-pd2.pos.X) < 8.5 and math.abs(z-pd2.pos.Z) < 8.5 then nearPad = true end
                                                    end
                                                    if math.abs(z-x) > 6.5 and math.abs(z+x) > 6.5 and not nearPad and not (z > 20 and math.abs(x) < 27) then
                                                        local tuft = makePart("GrassTuft", Vector3.new(0.55,0.75,0.55), CFrame.new(x,2.35,z), "Bright green", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                        tuft.Color = Color3.fromRGB(58,138,52)
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
                                                            -- LEADERBOARD WALL
                                                            --===========================================================
                                                            local boardPart = makePart("LeaderboardBoard", Vector3.new(30,18,0.4), CFrame.new(0,16,LD/2-1.35), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                            local boardGui = Instance.new("SurfaceGui"); boardGui.Face=Enum.NormalId.Front; boardGui.AlwaysOnTop=false; boardGui.LightInfluence=0; boardGui.Parent=boardPart

                                                            local boardRoot = Instance.new("Frame"); boardRoot.Size=UDim2.new(1,0,1,0)
                                                            boardRoot.BackgroundColor3=Color3.fromRGB(8,6,18); boardRoot.BackgroundTransparency=0.05
                                                            boardRoot.BorderSizePixel=0; boardRoot.Parent=boardGui
                                                            Instance.new("UICorner", boardRoot).CornerRadius=UDim.new(0.03,0)
                                                            local bStroke=Instance.new("UIStroke"); bStroke.Color=Color3.fromRGB(255,215,0); bStroke.Thickness=2; bStroke.Parent=boardRoot

                                                            local bTitle=Instance.new("TextLabel"); bTitle.Size=UDim2.new(1,0,0.12,0); bTitle.Position=UDim2.new(0,0,0.015,0)
                                                            bTitle.BackgroundTransparency=1; bTitle.Font=Enum.Font.LuckiestGuy; bTitle.TextScaled=true
                                                            bTitle.TextColor3=Color3.fromRGB(255,255,255); bTitle.TextStrokeColor3=Color3.fromRGB(0,0,0); bTitle.TextStrokeTransparency=0.35
                                                            bTitle.Text="SOBREVIVIENTES"; bTitle.Parent=boardRoot

                                                            local rowsFrame=Instance.new("ScrollingFrame"); rowsFrame.Size=UDim2.new(0.96,0,0.835,0); rowsFrame.Position=UDim2.new(0.02,0,0.145,0)
                                                            rowsFrame.BackgroundTransparency=1; rowsFrame.Parent=boardRoot
                                                            rowsFrame.ScrollBarThickness = 10
                                                            rowsFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
                                                            rowsFrame.CanvasSize = UDim2.new(0,0,0,0)
                                                            rowsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
                                                            local rl=Instance.new("UIListLayout"); rl.Padding=UDim.new(0,5); rl.FillDirection=Enum.FillDirection.Vertical
                                                            rl.HorizontalAlignment=Enum.HorizontalAlignment.Center; rl.Parent=rowsFrame

                                                            local rankIcons={"👑","🧙","🧪","📖","🔮"}
                                                            local leaderboardRows={}
                                                            for i=1,12 do
                                                                local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0.18,0)
                                                                row.BackgroundColor3=Color3.fromRGB(16,12,28); row.BackgroundTransparency=0.15
                                                                row.BorderSizePixel=0; row.Parent=rowsFrame
                                                                Instance.new("UICorner",row).CornerRadius=UDim.new(0.08,0)

                                                                local rank=Instance.new("TextLabel"); rank.Name="Rank"; rank.Size=UDim2.new(0.10,0,1,0)
                                                                rank.BackgroundTransparency=1; rank.Font=Enum.Font.LuckiestGuy; rank.TextScaled=true
                                                                rank.TextColor3=Color3.fromRGB(255,215,0); rank.Text=i.."."; rank.Parent=row

                                                                local ic=Instance.new("TextLabel"); ic.Name="Icon"; ic.Size=UDim2.new(0.09,0,1,0); ic.Position=UDim2.new(0.10,0,0,0)
                                                                ic.BackgroundTransparency=1; ic.Font=Enum.Font.GothamBold; ic.TextScaled=true
                                                                ic.TextColor3=Color3.fromRGB(255,255,255); ic.Text=rankIcons[i] or "⚡"; ic.Parent=row

                                                                local av=Instance.new("ImageLabel"); av.Name="Avatar"; av.Size=UDim2.new(0.13,0,0.78,0)
                                                                av.Position=UDim2.new(0.20,0,0.11,0); av.BackgroundTransparency=1; av.Image=""; av.Parent=row
                                                                Instance.new("UICorner",av).CornerRadius=UDim.new(1,0)

                                                                local nm=Instance.new("TextLabel"); nm.Name="Name"; nm.Size=UDim2.new(0.42,0,1,0)
                                                                nm.Position=UDim2.new(0.34,0,0,0); nm.BackgroundTransparency=1; nm.Font=Enum.Font.LuckiestGuy
                                                                nm.TextScaled=true; nm.TextXAlignment=Enum.TextXAlignment.Left
                                                                nm.TextColor3=(i==1) and Color3.fromRGB(255,215,0) or Color3.fromRGB(255,255,255); nm.Text="—"; nm.Parent=row

                                                                local kl=Instance.new("TextLabel"); kl.Name="Kills"; kl.Size=UDim2.new(0.20,0,1,0)
                                                                kl.Position=UDim2.new(0.78,0,0,0); kl.BackgroundTransparency=1; kl.Font=Enum.Font.LuckiestGuy
                                                                kl.TextScaled=true; kl.TextXAlignment=Enum.TextXAlignment.Right
                                                                kl.TextColor3=Color3.fromRGB(255,215,0); kl.Text="0"; kl.Parent=row

                                                                leaderboardRows[i]={row=row,rank=rank,icon=ic,avatar=av,name=nm,kills=kl}
                                                            end

                                                            local function refreshLeaderboard()
                                                                local ok,pages=pcall(function() return KillsOrdered:GetSortedAsync(false,12) end)
                                                                    if not ok or not pages then for i=1,12 do leaderboardRows[i].name.Text="—"; leaderboardRows[i].kills.Text="0"; leaderboardRows[i].avatar.Image="" end return end
                                                                    local page=pages:GetCurrentPage()
                                                                    for i=1,12 do
                                                                        local row=leaderboardRows[i]; local entry=page[i]
                                                                        if entry then
                                                                            local uid=tonumber(entry.key); local score=tonumber(entry.value) or 0
                                                                            row.kills.Text=tostring(score)
                                                                            local dName="Mago"; local thumb=""
                                                                            if uid then
                                                                                local okN,nR=pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
                                                                                    if okN and nR then dName=nR else dName="ID "..tostring(uid) end
                                                                                    local okT,tR=pcall(function() return Players:GetUserThumbnailAsync(uid,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
                                                                                        if okT and tR then thumb=tR end
                                                                                    end
                                                                                    row.name.Text=dName; row.avatar.Image=thumb
                                                                                else row.name.Text="—"; row.kills.Text="0"; row.avatar.Image="" end
                                                                                end
                                                                                end
 
                                                                                    task.spawn(function() while true do refreshLeaderboard(); task.wait(12) end end)

                                                                                                                        --===========================================================
                                                                                                                        -- ESTRUCTURA EPICA V2 DE LA CLASIFICACION (arco alto, gargolas, sombrero)
                                                                                                                        -- Reconstruida tras la captura del usuario: fondo oscuro propio para aislarla
                                                                                                                        -- de la luz dorada del lobby, piedra casi negra, luces suaves y arco de verdad.
                                                                                                                        -- Solo Parts decorativas; no toca datos ni el refresco de la tabla.
                                                                                                                        --===========================================================
                                                                                                                        do
                                                                                                                            local BZ = 29.65
                                                                                                                            local PZ = 29.3
                                                                                                                            local STONE_A = Color3.fromRGB(16,15,24)
                                                                                                                            local STONE_B = Color3.fromRGB(24,22,34)
                                                                                                                            local STONE_CAP = Color3.fromRGB(12,11,19)
                                                                                                                            local function MP(n, s, cf, bc, mat, cc)
                                                                                                                                local part = makePart(n, s, cf, bc, mat or Enum.Material.SmoothPlastic, LobbyModel, cc, true)
                                                                                                                                return part
                                                                                                                            end
                                                                                                                            local function cyl(n, size, cf, col)
                                                                                                                                local part = Instance.new("Part")
                                                                                                                                part.Name = n; part.Shape = Enum.PartType.Cylinder; part.Size = size
                                                                                                                                part.CFrame = cf; part.BrickColor = BrickColor.new("White"); part.Color = col
                                                                                                                                part.Material = Enum.Material.SmoothPlastic; part.Anchored = true
                                                                                                                                part.CanCollide = false; part.CastShadow = false; part.Parent = LobbyModel
                                                                                                                                return part
                                                                                                                            end
                                                                                                                            local function wedge(n, size, cf, col, neon)
                                                                                                                                local part = Instance.new("WedgePart")
                                                                                                                                part.Name = n; part.Size = size; part.CFrame = cf
                                                                                                                                part.BrickColor = BrickColor.new("White"); part.Color = col
                                                                                                                                part.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
                                                                                                                                part.Anchored = true; part.CanCollide = false; part.CastShadow = false; part.Parent = LobbyModel
                                                                                                                                return part
                                                                                                                            end

                                                                                                                            -- Fondo oscuro propio + escenario (aisla el monumento de la luz dorada)
                                                                                                                            local back = MP("ClassBackdrop", Vector3.new(62,42,0.6), CFrame.new(0,21.5,30.6), "Dark stone grey", nil, false)
                                                                                                                            back.Color = Color3.fromRGB(17,16,27)
                                                                                                                            local stage = MP("ClassStage", Vector3.new(52,0.9,7.5), CFrame.new(0,2.2,28.0), "Dark stone grey", nil, true)
                                                                                                                            stage.Color = Color3.fromRGB(29,27,43)
                                                                                                                            local step = MP("ClassStageStep", Vector3.new(42,0.55,2.4), CFrame.new(0,2.0,24.9), "Medium stone grey", nil, true)
                                                                                                                            step.Color = Color3.fromRGB(38,35,52)

                                                                                                                            -- Marco de madera de la pizarra
                                                                                                                            local frameCol = Color3.fromRGB(92,56,28)
                                                                                                                            for _,fd in ipairs({
                                                                                                                                {"BoardFrameT", Vector3.new(33,1.4,0.6), CFrame.new(0,25.3,BZ-0.6)},
                                                                                                                                {"BoardFrameB", Vector3.new(33,1.4,0.6), CFrame.new(0,6.7,BZ-0.6)},
                                                                                                                                {"BoardFrameL", Vector3.new(1.4,20,0.6), CFrame.new(-16.1,16,BZ-0.6)},
                                                                                                                                {"BoardFrameR", Vector3.new(1.4,20,0.6), CFrame.new(16.1,16,BZ-0.6)},
                                                                                                                            }) do
                                                                                                                                local fp = MP(fd[1], fd[2], fd[3], "Reddish brown", Enum.Material.Wood, false)
                                                                                                                                fp.Color = frameCol
                                                                                                                            end

                                                                                                                            for _,sd in ipairs({-1,1}) do
                                                                                                                                local PX = sd*20
                                                                                                                                local flameCol = (sd < 0) and Color3.fromRGB(168,92,255) or Color3.fromRGB(74,140,255)

                                                                                                                                -- Pilar de piedra casi negra, bloques alternados
                                                                                                                                local pb = MP("ClassPillarBase", Vector3.new(9.6,0.9,6.2), CFrame.new(PX,3.1,PZ), "Dark stone grey", nil, true); pb.Color = STONE_CAP
                                                                                                                                local pp = MP("ClassPillarPlinth", Vector3.new(8.2,1.3,5.2), CFrame.new(PX,4.2,PZ), "Medium stone grey", nil, true); pp.Color = STONE_B
                                                                                                                                for k=0,8 do
                                                                                                                                    local wide = (k%2==0)
                                                                                                                                    local blk = MP("ClassPillarBlock", wide and Vector3.new(6.4,2.35,4.3) or Vector3.new(5.7,2.35,3.8), CFrame.new(PX+((k%3)-1)*0.15, 5.9+k*2.35, PZ+((k%2)*0.14)-0.07), "Dark stone grey", nil, true)
                                                                                                                                    blk.Color = wide and STONE_A or STONE_B
                                                                                                                                end
                                                                                                                                local cap = MP("ClassPillarCap", Vector3.new(8.0,1.4,5.4), CFrame.new(PX,26.6,PZ), "Dark stone grey", nil, true); cap.Color = STONE_CAP
                                                                                                                                local trim = MP("ClassPillarTrim", Vector3.new(8.8,0.7,5.9), CFrame.new(PX,27.65,PZ), "Medium stone grey", nil, true); trim.Color = Color3.fromRGB(30,28,42)

                                                                                                                                -- Enredaderas densas pegadas a la piedra (masas de hojas, no cubitos sueltos)
                                                                                                                                local greens = {Color3.fromRGB(18,60,28), Color3.fromRGB(24,76,33), Color3.fromRGB(13,44,21)}
                                                                                                                                for k=0,19 do
                                                                                                                                    local vy = 25.4 - k*1.12
                                                                                                                                    local vx = PX - sd*2.55 + math.sin(k*2.1 + sd*3)*0.85
                                                                                                                                    local vs = 0.62 + (k%4)*0.15
                                                                                                                                    local leaf = MP("ClassVine", Vector3.new(vs,vs,0.7), CFrame.new(vx, vy, PZ-2.2), "Dark green", nil, false)
                                                                                                                                    leaf.Color = greens[(k%3)+1]
                                                                                                                                    if k%3 == 0 then
                                                                                                                                        local plate = MP("ClassVineLeaf", Vector3.new(1.6,0.3,1.05), CFrame.new(vx+0.4, vy-0.5, PZ-2.45)*CFrame.Angles(0, math.rad(k*37), math.rad(14)), "Bright green", nil, false)
                                                                                                                                        plate.Color = greens[((k+1)%3)+1]
                                                                                                                                    end
                                                                                                                                end
                                                                                                                                for k=0,6 do
                                                                                                                                    local bush = MP("ClassVineBush", Vector3.new(1.3+(k%3)*0.35, 1.1+(k%2)*0.4, 1.0), CFrame.new(PX - sd*2.2 + (k%3-1)*1.15, 3.4 + (k%2)*0.55, PZ-2.5), "Dark green", nil, false)
                                                                                                                                    bush.Color = greens[(k%3)+1]
                                                                                                                                end

                                                                                                                                -- Llama magica sobre cristal, al frente interior del pilar (acento, sin bañar la piedra)
                                                                                                                                local FX = PX - sd*3.15
                                                                                                                                MP("FlameBase", Vector3.new(1.6,0.6,1.6), CFrame.new(FX,12.8,PZ-2.35), "Really black", nil, false)
                                                                                                                                local fcry = wedge("FlameCrystal", Vector3.new(1.0,1.7,1.0), CFrame.new(FX,13.9,PZ-2.35), flameCol, true)
                                                                                                                                local ff = Instance.new("Fire"); ff.Heat=6; ff.Size=2.4; ff.Color=flameCol; ff.SecondaryColor=Color3.fromRGB(255,255,255); ff.Parent=fcry
                                                                                                                                local fs = Instance.new("ParticleEmitter"); fs.Color=ColorSequence.new(flameCol, Color3.fromRGB(255,255,255)); fs.LightEmission=1
                                                                                                                                fs.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,0)}
                                                                                                                                fs.Speed=NumberRange.new(3,7); fs.Lifetime=NumberRange.new(0.35,0.75); fs.Rate=22; fs.SpreadAngle=Vector2.new(35,35); fs.Parent=fcry
                                                                                                                                local fl = Instance.new("PointLight"); fl.Brightness=2.6; fl.Range=11; fl.Color=flameCol; fl.Parent=fcry

                                                                                                                                -- Farol colgante con luz suave
                                                                                                                                local arm = MP("LanternArm", Vector3.new(0.55,0.55,4.4), CFrame.new(PX,21.6,PZ-3.7), "Reddish brown", Enum.Material.Wood, false); arm.Color = frameCol
                                                                                                                                for li=0,2 do
                                                                                                                                    MP("LanternChain", Vector3.new(0.26,0.5,0.26), CFrame.new(PX, 21.1-li*0.48, PZ-5.7), "Really black", nil, false)
                                                                                                                                end
                                                                                                                                MP("LanternTop", Vector3.new(1.5,0.3,1.5), CFrame.new(PX,19.9,PZ-5.7), "Really black", nil, false)
                                                                                                                                MP("LanternBase", Vector3.new(1.5,0.3,1.5), CFrame.new(PX,18.1,PZ-5.7), "Really black", nil, false)
                                                                                                                                local core = MP("LanternCore", Vector3.new(1.0,1.5,1.0), CFrame.new(PX,19.0,PZ-5.7), "Bright yellow", Enum.Material.Neon, false)
                                                                                                                                core.Color = Color3.fromRGB(255,190,80)
                                                                                                                                local ll = Instance.new("PointLight"); ll.Brightness=2.0; ll.Range=11; ll.Color=Color3.fromRGB(255,170,70); ll.Parent=core

                                                                                                                                -- Gárgola grande y oscura coronando el pilar (mirando al lobby, -Z)
                                                                                                                                local GY = 28.0
                                                                                                                                local function GP(n, s, cf, col)
                                                                                                                                    local gp = MP(n, s, cf, "Dark stone grey", nil, false); gp.Color = col; return gp
                                                                                                                                end
                                                                                                                                GP("GargSeat", Vector3.new(4.4,1.0,3.8), CFrame.new(PX,GY+0.5,PZ), STONE_CAP)
                                                                                                                                GP("GargBody", Vector3.new(3.0,3.2,2.5), CFrame.new(PX,GY+2.6,PZ+0.1), Color3.fromRGB(15,14,22))
                                                                                                                                GP("GargChest", Vector3.new(2.2,2.4,0.6), CFrame.new(PX,GY+2.5,PZ-1.2), Color3.fromRGB(20,19,29))
                                                                                                                                GP("GargHead", Vector3.new(2.45,1.85,2.15), CFrame.new(PX,GY+4.9,PZ-0.3), Color3.fromRGB(30,28,44))
                                                                                                                                GP("GargSnout", Vector3.new(1.25,0.8,1.2), CFrame.new(PX,GY+4.4,PZ-1.65), Color3.fromRGB(23,22,33))
                                                                                                                                GP("GargBrow", Vector3.new(2.3,0.5,0.7), CFrame.new(PX,GY+5.6,PZ-1.15), STONE_CAP)
                                                                                                                                local eyeCol = (sd < 0) and Color3.fromRGB(255,64,64) or Color3.fromRGB(90,225,255)
                                                                                                                                for _,eo in ipairs({-0.55,0.55}) do
                                                                                                                                    local eye = MP("GargEye", Vector3.new(0.34,0.3,0.14), CFrame.new(PX+eo,GY+5.05,PZ-1.42), "White", Enum.Material.Neon, false)
                                                                                                                                    eye.Color = eyeCol
                                                                                                                                end
for _,fo in ipairs({-0.35,0.35}) do
                                                                                                                                    local fang = MP("GargFang", Vector3.new(0.16,0.34,0.1), CFrame.new(PX+fo,GY+3.92,PZ-2.18), "White", Enum.Material.Neon, false)
                                                                                                                                    fang.Color = Color3.fromRGB(240,240,230)
                                                                                                                                    end
                                                                                                                                                                                                                                                                    for _,eo in ipairs({-1.2,1.2}) do
                                                                                                                                    wedge("GargEar", Vector3.new(0.5,0.95,0.42), CFrame.new(PX+eo*0.72,GY+6.05,PZ-0.3)*CFrame.Angles(0,0,math.rad(-eo*26)), Color3.fromRGB(13,12,20), false)
                                                                                                                                end
                                                                                                                                for _,ao in ipairs({-1.85,1.85}) do
                                                                                                                                    GP("GargArm", Vector3.new(0.85,3.0,0.85), CFrame.new(PX+ao,GY+1.9,PZ-0.85)*CFrame.Angles(math.rad(14),0,0), Color3.fromRGB(15,14,22))
                                                                                                                                    GP("GargPaw", Vector3.new(1.15,0.6,1.9), CFrame.new(PX+ao,GY+0.55,PZ-1.55), Color3.fromRGB(20,19,29))
                                                                                                                                    GP("GargHaunch", Vector3.new(1.1,1.9,1.7), CFrame.new(PX+ao,GY+1.35,PZ+0.65), Color3.fromRGB(15,14,22))
                                                                                                                                end
                                                                                                                                GP("GargTail", Vector3.new(0.55,0.55,3.2), CFrame.new(PX,GY+1.1,PZ+2.1)*CFrame.Angles(math.rad(-20),0,0), STONE_CAP)
                                                                                                                                wedge("GargWingA", Vector3.new(5.0,3.6,0.5), CFrame.new(PX+sd*3.1,GY+5.3,PZ+0.75)*CFrame.Angles(0,math.rad(sd*-18),math.rad(sd*14)), Color3.fromRGB(11,10,18), false)
                                                                                                                                wedge("GargWingB", Vector3.new(3.4,2.4,0.45), CFrame.new(PX+sd*5.6,GY+6.1,PZ+0.9)*CFrame.Angles(0,math.rad(sd*-24),math.rad(sd*22)), Color3.fromRGB(11,10,18), false)

                                                                                                                                -- Varita apoyada junto al pilar
                                                                                                                                local wandCol = flameCol
                                                                                                                                local stick = MP("ClassWandStick", Vector3.new(0.18,5.4,0.18), CFrame.new(PX-sd*4.1,5.3,PZ-2.6)*CFrame.Angles(0,0,math.rad(sd*16)), "Reddish brown", Enum.Material.Wood, false)
                                                                                                                                stick.Color = Color3.fromRGB(96,58,30)
                                                                                                                                local wtip = wedge("ClassWandTip", Vector3.new(0.42,0.9,0.42), CFrame.new(PX-sd*4.85,7.85,PZ-2.6), wandCol, true)
                                                                                                                                local wl = Instance.new("PointLight"); wl.Brightness=1.0; wl.Range=7; wl.Color=wandCol; wl.Parent=wtip
                                                                                                                            end

                                                                                                                            -- Arco escalonado alto que une los pilares
                                                                                                                            for _,sd in ipairs({-1,1}) do
                                                                                                                                local a1 = MP("ClassArchBlock1", Vector3.new(6.2,2.2,3.9), CFrame.new(sd*15.2,28.9,PZ), "Dark stone grey", nil, false); a1.Color = STONE_B
                                                                                                                                local a2 = MP("ClassArchBlock2", Vector3.new(5.4,2.1,3.9), CFrame.new(sd*10.6,30.6,PZ), "Dark stone grey", nil, false); a2.Color = STONE_A
                                                                                                                            end
                                                                                                                            local beam = MP("ClassArchBeam", Vector3.new(15.5,2.2,4.1), CFrame.new(0,31.9,PZ), "Dark stone grey", nil, false); beam.Color = STONE_B
                                                                                                                            local key = MP("ClassArchKey", Vector3.new(2.7,3.1,4.3), CFrame.new(0,31.3,PZ), "Medium stone grey", nil, false); key.Color = Color3.fromRGB(34,32,46)

                                                                                                                            -- Runas luminosas en la cara del arco (barritas neon, cian/morado alternadas)
                                                                                                                            local runeCols = {Color3.fromRGB(110,220,255), Color3.fromRGB(190,140,255)}
                                                                                                                            local runePos = {{-15.2,28.9},{-10.6,30.6},{10.6,30.6},{15.2,28.9}}
                                                                                                                            for ri,rp in ipairs(runePos) do
                                                                                                                                local rc = runeCols[(ri%2)+1]
                                                                                                                                local flip = (ri%2==0) and 1 or -1
                                                                                                                                local function RB(s, cf)
                                                                                                                                    local rb = MP("ClassRune", s, cf, "White", Enum.Material.Neon, false); rb.Color = rc
                                                                                                                                end
                                                                                                                                RB(Vector3.new(0.28,2.0,0.18), CFrame.new(rp[1], rp[2], PZ-2.0))
                                                                                                                                RB(Vector3.new(0.28,1.1,0.18), CFrame.new(rp[1]+0.4*flip, rp[2]+0.45, PZ-2.0)*CFrame.Angles(0,0,math.rad(48*flip)))
                                                                                                                                RB(Vector3.new(0.28,1.0,0.18), CFrame.new(rp[1]+0.38*flip, rp[2]-0.15, PZ-2.0)*CFrame.Angles(0,0,math.rad(-48*flip)))
                                                                                                                            end

                                                                                                                            -- Letrero de madera oscura TOP SORCERERS (legible: letras amarillas con borde negro)
                                                                                                                            for _,px2 in ipairs({-6.5,6.5}) do
                                                                                                                                local post = MP("SignPost", Vector3.new(0.9,4.4,0.9), CFrame.new(px2,30.4,28.6), "Reddish brown", Enum.Material.Wood, false)
                                                                                                                                post.Color = Color3.fromRGB(80,48,24)
                                                                                                                            end
                                                                                                                            local signPart = MP("TopSorcerersSign", Vector3.new(23,5.8,0.8), CFrame.new(0,32.95,27.9), "Reddish brown", Enum.Material.Wood, false)
                                                                                                                            signPart.Color = Color3.fromRGB(72,43,21)
                                                                                                                            for _,sy in ipairs({32.05,33.75}) do
                                                                                                                                local seam = MP("SignSeam", Vector3.new(21,0.16,0.12), CFrame.new(0,sy,27.45), "Really black", nil, false)
                                                                                                                                seam.Color = Color3.fromRGB(58,34,16)
                                                                                                                            end
                                                                                                                            local signGui = Instance.new("SurfaceGui"); signGui.Face=Enum.NormalId.Front; signGui.AlwaysOnTop=true; signGui.LightInfluence=0; signGui.Parent=signPart
                                                                                                                            local signLbl = Instance.new("TextLabel"); signLbl.Size=UDim2.new(1,0,0.48,0); signLbl.Position=UDim2.new(0,0,0.02,0); signLbl.BackgroundTransparency=1
signLbl.Font=Enum.Font.LuckiestGuy; signLbl.TextScaled=true
signLbl.TextColor3=Color3.fromRGB(255,206,64); signLbl.TextStrokeColor3=Color3.fromRGB(0,0,0); signLbl.TextStrokeTransparency=0
signLbl.Text="TOP"; signLbl.Parent=signGui
local signLbl2 = Instance.new("TextLabel"); signLbl2.Size=UDim2.new(1,0,0.5,0); signLbl2.Position=UDim2.new(0,0,0.5,0); signLbl2.BackgroundTransparency=1
signLbl2.Font=Enum.Font.LuckiestGuy; signLbl2.TextScaled=true
signLbl2.TextColor3=Color3.fromRGB(255,206,64); signLbl2.TextStrokeColor3=Color3.fromRGB(0,0,0); signLbl2.TextStrokeTransparency=0
signLbl2.Text="SORCERERS"; signLbl2.Parent=signGui

                                                                                                                            -- Sombrero de mago sobre el letrero (ala + cono inclinado + banda + hebilla)
                                                                                                                            local hatCol = Color3.fromRGB(64,27,106)
                                                                                                                            cyl("WitchHatBrim", Vector3.new(0.6,7.8,7.8), CFrame.new(0,36.15,27.9)*CFrame.Angles(0,0,math.rad(90)), Color3.fromRGB(56,23,94))
                                                                                                                            cyl("WitchHatBand", Vector3.new(0.9,5.5,5.5), CFrame.new(0,36.85,27.9)*CFrame.Angles(0,0,math.rad(90)), Color3.fromRGB(40,22,66))
                                                                                                                            cyl("WitchHatCone1", Vector3.new(1.2,5.2,5.2), CFrame.new(0,37.4,27.9)*CFrame.Angles(0,0,math.rad(90)), hatCol)
                                                                                                                            cyl("WitchHatCone2", Vector3.new(1.15,4.1,4.1), CFrame.new(0.35,38.45,27.9)*CFrame.Angles(0,0,math.rad(84)), hatCol)
                                                                                                                            cyl("WitchHatCone3", Vector3.new(1.1,3.1,3.1), CFrame.new(0.75,39.35,27.9)*CFrame.Angles(0,0,math.rad(78)), hatCol)
                                                                                                                            cyl("WitchHatTip", Vector3.new(1.0,2.0,2.0), CFrame.new(1.2,40.05,27.9)*CFrame.Angles(0,0,math.rad(68)), hatCol)
                                                                                                                            local buckle = MP("HatBuckle", Vector3.new(1.35,1.0,0.28), CFrame.new(0.1,36.8,25.45), "Bright yellow", Enum.Material.Neon, false)
                                                                                                                            buckle.Color = Color3.fromRGB(255,190,60)

                                                                                                                            -- Cristales brillantes en la base (cian a la izquierda, rosa a la derecha)
                                                                                                                            for _,sd in ipairs({-1,1}) do
                                                                                                                                local cc = (sd < 0) and Color3.fromRGB(130,235,255) or Color3.fromRGB(255,150,215)
                                                                                                                                local CX = sd*24.0
                                                                                                                                local rock = MP("CrystalRock", Vector3.new(3.6,0.8,2.6), CFrame.new(CX,2.9,26.2), "Dark stone grey", nil, false); rock.Color = STONE_CAP
                                                                                                                                local heights = {2.4, 4.6, 3.2, 5.2}
                                                                                                                                for ci,ch in ipairs(heights) do
                                                                                                                                    local cx2 = CX + (ci-2.5)*0.95
                                                                                                                                    local shard = wedge("ClassCrystal", Vector3.new(1.25,ch,1.25), CFrame.new(cx2, 3.2+ch/2, 26.2+((ci%2)*0.5-0.25))*CFrame.Angles(math.rad((ci%2)*10-5), math.rad(45), math.rad((ci%3)*6-6)), cc, true)
                                                                                                                                    if ci == 4 then
                                                                                                                                        local cl = Instance.new("PointLight"); cl.Brightness=1.6; cl.Range=9; cl.Color=cc; cl.Parent=shard
                                                                                                                                    end
                                                                                                                                end
                                                                                                                            end

                                                                                                                            -- Libros de hechizos a la izquierda de la base
                                                                                                                            local b1 = MP("SpellBook1", Vector3.new(3.4,0.5,2.6), CFrame.new(-18.6,2.95,25.7), "Really red", nil, true); b1.Color = Color3.fromRGB(128,34,34)
                                                                                                                            MP("SpellBook1Pages", Vector3.new(3.1,0.32,2.3), CFrame.new(-18.6,3.32,25.7), "Institutional white", nil, false)
                                                                                                                            local b2cf = CFrame.new(-18.4,3.75,25.7)*CFrame.Angles(0,math.rad(18),0)
                                                                                                                            local b2 = MP("SpellBook2", Vector3.new(2.8,0.45,2.1), b2cf, "Navy blue", nil, true)
                                                                                                                            b2.Color = Color3.fromRGB(40,60,120)
                                                                                                                            local gem = MP("SpellBookGem", Vector3.new(0.55,0.16,0.55), CFrame.new(-18.4,4.05,25.7), "Bright yellow", Enum.Material.Neon, false)
                                                                                                                            gem.Color = Color3.fromRGB(255,190,60)
                                                                                                                            local lean = MP("SpellBookLean", Vector3.new(2.4,3.4,0.5), CFrame.new(-17.6,4.4,26.9)*CFrame.Angles(0,0,math.rad(16)), "Plum", nil, true)
                                                                                                                            lean.Color = Color3.fromRGB(110,40,90)

                                                                                                                            -- Pociones a la derecha de la base
                                                                                                                            local potionCols = {Color3.fromRGB(80,255,120), Color3.fromRGB(190,110,255), Color3.fromRGB(255,90,90)}
                                                                                                                            for pi,pc in ipairs(potionCols) do
                                                                                                                                local px2 = 18.3 + (pi-1)*1.7
                                                                                                                                local glass = MP("PotionBottle", Vector3.new(1.0,1.35,1.0), CFrame.new(px2,3.35,25.7), "Institutional white", Enum.Material.Glass, false)
                                                                                                                                glass.Transparency = 0.35
                                                                                                                                local liq = MP("PotionLiquid", Vector3.new(0.8,0.85,0.8), CFrame.new(px2,3.15,25.7), "White", Enum.Material.Neon, false)
                                                                                                                                liq.Color = pc
                                                                                                                                MP("PotionNeck", Vector3.new(0.4,0.5,0.4), CFrame.new(px2,4.25,25.7), "Institutional white", Enum.Material.Glass, false)
                                                                                                                                MP("PotionCork", Vector3.new(0.34,0.36,0.34), CFrame.new(px2,4.62,25.7), "Brown", Enum.Material.Wood, false)
                                                                                                                                if pi == 2 then
                                                                                                                                    local pl2 = Instance.new("PointLight"); pl2.Brightness=1.1; pl2.Range=7; pl2.Color=pc; pl2.Parent=liq
                                                                                                                                end
                                                                                                                            end
                                                                                                                        end

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


-- FIN PARTE 2
