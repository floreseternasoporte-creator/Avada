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
                                                    spawnLoc.Size=Vector3.new(6,1,6); spawnLoc.CFrame=CFrame.new(0,3,19)
                                                    spawnLoc.Transparency=1; spawnLoc.CanCollide=true; spawnLoc.Anchored=true
                                                    spawnLoc.Neutral=true; spawnLoc.Parent=workspace
                                                end
 
                                                local LobbyModel = workspace:FindFirstChild("HogwartsLobby")
                                                if LobbyModel then LobbyModel:Destroy() end
                                                LobbyModel = Instance.new("Model"); LobbyModel.Name="HogwartsLobby"; LobbyModel.Parent=workspace
 
                                                local LW, LD, LH = 78, 62, 40
 
                                                local floor = makePart("Floor", Vector3.new(LW,2,LD), CFrame.new(0,1,0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                addTex(floor, Enum.NormalId.Top, 9, 9)
 
                                                for _, data in ipairs({
                                                    {"WallBack",  Vector3.new(LW,LH,2.5),    CFrame.new(0,LH/2+1,-LD/2)},
                                                    {"WallFront", Vector3.new(LW,LH,2.5),    CFrame.new(0,LH/2+1, LD/2)},
                                                    {"WallLeft",  Vector3.new(2.5,LH,LD+5),  CFrame.new(-LW/2,LH/2+1,0)},
                                                    {"WallRight", Vector3.new(2.5,LH,LD+5),  CFrame.new( LW/2,LH/2+1,0)},
                                                    {"Ceiling",   Vector3.new(LW,2.5,LD),    CFrame.new(0,LH+2,0)},
                                                    }) do
                                                    local w = makePart(data[1], data[2], data[3], "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    addTex(w, Enum.NormalId.Front, 8, 8); addTex(w, Enum.NormalId.Back, 8, 8)
                                                end
 
                                                for z=-24,24,12 do makePart("VaultZ_"..z, Vector3.new(LW,2,2), CFrame.new(0,LH+1,z), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true) end
                                                for x=-36,36,18 do makePart("VaultX_"..x, Vector3.new(2,2,LD), CFrame.new(x,LH+1,0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true) end
 
                                                for _,px in ipairs({-32,32}) do
                                                    for _,pz in ipairs({-22,-7,7,22}) do addGothicPillar(px,2,pz,LH-4,LobbyModel) end
                                                end
                                                for _,pz in ipairs({-22,-7,7,22}) do
                                                    addGothicArch(-LW/2+1,2,pz,18,30,2,LobbyModel,90)
                                                    addGothicArch( LW/2-1,2,pz,18,30,2,LobbyModel,90)
                                                end
 
                                                local glassColors = {
                                                {Color3.fromRGB(200,30,30),  Color3.fromRGB(255,215,0),  Color3.fromRGB(200,30,30)},
                                                {Color3.fromRGB(0,140,60),   Color3.fromRGB(180,180,180),Color3.fromRGB(0,140,60)},
                                                {Color3.fromRGB(30,60,200),  Color3.fromRGB(180,180,200),Color3.fromRGB(30,60,200)},
                                                {Color3.fromRGB(210,180,0),  Color3.fromRGB(30,30,30),   Color3.fromRGB(210,180,0)},
                                                }
                                                for i,gc in ipairs(glassColors) do
                                                    addStainedGlass(Vector3.new(-27+(i-1)*18, LH-12, -LD/2+1), Vector3.new(10,16,0.4), gc, LobbyModel)
                                                end
 
                                                for _,cp in ipairs({
                                                    Vector3.new(-34,LH-8,-18), Vector3.new(-34,LH-8,18),
                                                    Vector3.new(0,LH-8,-24),   Vector3.new(0,LH-8,0), Vector3.new(0,LH-8,24),
                                                    Vector3.new(34,LH-8,-18),  Vector3.new(34,LH-8,18),
                                                    }) do addWallTorch(cp, LobbyModel) end
 
                                                    for i=1,14 do
                                                        createFlyingCandle(Vector3.new(math.random(-34,34), LH-math.random(5,15), math.random(-26,26)), LobbyModel)
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

                                                    local plaza = makePart("LobbyPlaza", Vector3.new(60,1,20), CFrame.new(0,2.55,-6), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    addTex(plaza, Enum.NormalId.Top, 6, 6)

                                                    makePart("GatePostL", Vector3.new(1.2,14,1.2), CFrame.new(-27,8.5,-19), "Really black", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    makePart("GatePostR", Vector3.new(1.2,14,1.2), CFrame.new( 27,8.5,-19), "Really black", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                    for gi=0,11 do
                                                        local gx = -24.75 + gi*4.5
                                                        local segA = makePart("GateTapeA_"..gi, Vector3.new(4.5,1.1,0.35), CFrame.new(gx,13.8,-19), (gi%2==0) and "Bright yellow" or "Really black", Enum.Material.Neon, LobbyModel, false, true)
                                                        if gi%2==0 then segA.Color = Color3.fromRGB(255,205,64) end
                                                        local segB = makePart("GateTapeB_"..gi, Vector3.new(4.5,1.1,0.35), CFrame.new(gx,12.2,-19), (gi%2==1) and "Bright yellow" or "Really black", Enum.Material.Neon, LobbyModel, false, true)
                                                        if gi%2==1 then segB.Color = Color3.fromRGB(255,205,64) end
                                                    end

                                                    for _,cp2 in ipairs({Vector3.new(30,3.4,-14), Vector3.new(30,3.4,-10.8), Vector3.new(30,6.2,-12.4), Vector3.new(-30,3.4,-12.4)}) do
                                                        makePart("SupplyCrate", Vector3.new(2.8,2.8,2.8), CFrame.new(cp2)*CFrame.Angles(0,math.rad(12),0), "Brown", Enum.Material.Wood, LobbyModel, true, true)
                                                    end
 
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
                                                            local boardGui = Instance.new("SurfaceGui"); boardGui.Face=Enum.NormalId.Front; boardGui.AlwaysOnTop=false; boardGui.LightInfluence=1; boardGui.Parent=boardPart

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
                                                                                                                        -- ESTRUCTURA EPICA DE LA CLASIFICACION (arco, gargolas, sombrero)
                                                                                                                        -- Todo son Parts/SPARK creados aqui; no toca datos ni refresco.
                                                                                                                        --===========================================================
                                                                                                                        do
                                                                                                                            local BZ = 29.65 -- cara del tablon; el lobby queda hacia -Z
                                                                                                                            local PZ = 29.3  -- plano de pilares y arco

                                                                                                                            -- Marco de madera de la pizarra (4 vigas al frente)
                                                                                                                            makePart("BoardFrameT", Vector3.new(32.6,1.3,0.55), CFrame.new(0,25.15,BZ-0.55), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                            makePart("BoardFrameB", Vector3.new(32.6,1.3,0.55), CFrame.new(0,6.85,BZ-0.55), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                            makePart("BoardFrameL", Vector3.new(1.3,19.6,0.55), CFrame.new(-15.65,16,BZ-0.55), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                            makePart("BoardFrameR", Vector3.new(1.3,19.6,0.55), CFrame.new(15.65,16,BZ-0.55), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)

                                                                                                                            -- Escalones de piedra hacia el lobby
                                                                                                                            makePart("BoardStepTop", Vector3.new(34,0.9,3.6), CFrame.new(0,2.45,29.2), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                                                                                            makePart("BoardStepLow", Vector3.new(38,0.6,2.6), CFrame.new(0,2.3,27.3), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)

                                                                                                                            for _,sd in ipairs({-1,1}) do
                                                                                                                                local PX = sd*19

                                                                                                                                -- Pilar voxel: base ancha, fuste de bloques alternados y capitel
                                                                                                                                makePart("ClassPillarBase", Vector3.new(8.8,0.8,5.8), CFrame.new(PX,2.4,PZ), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                                                                                                makePart("ClassPillarPlinth", Vector3.new(7.6,1.2,4.8), CFrame.new(PX,3.3,PZ), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                                                                                                for k=0,8 do
                                                                                                                                    local by = 4.8 + k*2.4
                                                                                                                                    local wide = (k%2==0)
                                                                                                                                    local blk = makePart("ClassPillarBlock", wide and Vector3.new(5.2,2.4,3.8) or Vector3.new(4.6,2.4,3.3), CFrame.new(PX + ((k%3)-1)*0.15, by, PZ + ((k%2)*0.14)-0.07), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                                                                                                    blk.Color = wide and Color3.fromRGB(41,39,54) or Color3.fromRGB(54,51,68)
                                                                                                                                end
                                                                                                                                makePart("ClassPillarCap", Vector3.new(7.4,1.5,5.0), CFrame.new(PX,25.95,PZ), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                                                                                                makePart("ClassPillarCapTrim", Vector3.new(8.2,0.7,5.5), CFrame.new(PX,26.95,PZ), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, true, true)

                                                                                                                                -- Enredaderas: cubitos verdes bajando en diagonal por el frente
                                                                                                                                for k=0,15 do
                                                                                                                                    local vy = 24.6 - k*1.28
                                                                                                                                    local vx = PX + math.sin(k*1.85 + sd*2)*1.7 + (k%3-1)*0.4
                                                                                                                                    local vs = 0.55 + (k%4)*0.17
                                                                                                                                    local vine = makePart("ClassVine", Vector3.new(vs,vs,vs), CFrame.new(vx, vy, PZ-1.95-((k%3)*0.1)), (k%2==0) and "Bright green" or "Dark green", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                    vine.Color = (k%2==0) and Color3.fromRGB(52,148,66) or Color3.fromRGB(30,96,44)
                                                                                                                                    if k%4==1 then
                                                                                                                                        local vine2 = makePart("ClassVineSide", Vector3.new(vs*0.8,vs*0.8,vs*0.8), CFrame.new(PX - sd*2.75, vy-0.5, PZ-0.9), "Dark green", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                        vine2.Color = Color3.fromRGB(38,116,54)
                                                                                                                                    end
                                                                                                                                end

                                                                                                                                -- Farol colgante: brazo de madera, cadena y nucleo calido
                                                                                                                                makePart("LanternArm", Vector3.new(0.45,0.45,3.8), CFrame.new(PX,20.9,27.9), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                                makePart("LanternArmBrace", Vector3.new(0.35,0.35,2.4), CFrame.new(PX,21.8,28.5)*CFrame.Angles(math.rad(32),0,0), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                                for j=0,2 do
                                                                                                                                    makePart("LanternChain", Vector3.new(0.17,0.46,0.17), CFrame.new(PX,20.35-j*0.44,26.3), "Really black", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                end
                                                                                                                                makePart("LanternCap", Vector3.new(1.0,0.28,1.0), CFrame.new(PX,19.15,26.3), "Really black", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                local lampCore = makePart("LanternCore", Vector3.new(0.64,1.15,0.64), CFrame.new(PX,18.45,26.3), "Bright yellow", Enum.Material.Neon, LobbyModel, false, true)
                                                                                                                                lampCore.Color = Color3.fromRGB(255,186,80)
                                                                                                                                makePart("LanternBottom", Vector3.new(0.85,0.22,0.85), CFrame.new(PX,17.78,26.3), "Really black", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                local lampLight = Instance.new("PointLight"); lampLight.Brightness=5; lampLight.Range=21; lampLight.Color=Color3.fromRGB(255,170,60); lampLight.Parent=lampCore

                                                                                                                                -- Llama magica sobre cristal (morada a la izquierda, azul a la derecha)
                                                                                                                                local flameCol = (sd<0) and Color3.fromRGB(178,88,255) or Color3.fromRGB(70,145,255)
                                                                                                                                makePart("FlameBase", Vector3.new(1.5,0.55,1.5), CFrame.new(PX-sd*2.35,13.05,PZ-1.55), "Really black", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                local fcry = Instance.new("WedgePart")
                                                                                                                                fcry.Name="FlameCrystal"; fcry.Size=Vector3.new(1.15,2.8,1.15)
                                                                                                                                fcry.CFrame=CFrame.new(PX-sd*2.35,14.8,PZ-1.55)*CFrame.Angles(0,math.rad(sd*20),math.rad(-sd*9))
                                                                                                                                fcry.BrickColor=BrickColor.new("White"); fcry.Material=Enum.Material.Neon
                                                                                                                                fcry.Color=flameCol; fcry.Anchored=true; fcry.CanCollide=false; fcry.Parent=LobbyModel
                                                                                                                                local ff = Instance.new("Fire"); ff.Heat=7; ff.Size=4.2; ff.Color=flameCol; ff.SecondaryColor=Color3.fromRGB(255,255,255); ff.Parent=fcry
                                                                                                                                local fs = Instance.new("ParticleEmitter"); fs.Color=ColorSequence.new(flameCol, Color3.fromRGB(255,255,255)); fs.LightEmission=1
                                                                                                                                fs.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.34), NumberSequenceKeypoint.new(1,0)}
                                                                                                                                fs.Speed=NumberRange.new(1.2,3.2); fs.Acceleration=Vector3.new(0,6,0); fs.Lifetime=NumberRange.new(0.5,1.1); fs.Rate=42; fs.Parent=fcry
                                                                                                                                local fl = Instance.new("PointLight"); fl.Brightness=6; fl.Range=19; fl.Color=flameCol; fl.Parent=fcry

                                                                                                                                -- Gargola alada sobre el capitel (mirando al lobby, -Z)
                                                                                                                                local GY = 27.3
                                                                                                                                local eyeCol = (sd<0) and Color3.fromRGB(255,60,50) or Color3.fromRGB(0,255,255)
                                                                                                                                makePart("GargSeat", Vector3.new(3.1,1.1,2.7), CFrame.new(PX,GY+0.55,PZ), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargBody", Vector3.new(2.4,2.6,2.0), CFrame.new(PX,GY+2.4,PZ+0.1), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargChest", Vector3.new(1.8,2.0,0.5), CFrame.new(PX,GY+2.3,PZ-0.95), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargHead", Vector3.new(1.7,1.5,1.7), CFrame.new(PX,GY+4.35,PZ-0.25), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargSnout", Vector3.new(1.0,0.65,1.0), CFrame.new(PX,GY+3.95,PZ-1.15), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargBrow", Vector3.new(1.85,0.42,0.6), CFrame.new(PX,GY+4.85,PZ-0.85), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                for _,eo in ipairs({-0.42,0.42}) do
                                                                                                                                    local eye = makePart("GargEye", Vector3.new(0.24,0.24,0.12), CFrame.new(PX+eo,GY+4.45,PZ-1.13), "White", Enum.Material.Neon, LobbyModel, false, true)
                                                                                                                                    eye.Color = eyeCol
                                                                                                                                end
                                                                                                                                makePart("GargArmL", Vector3.new(0.7,2.4,0.7), CFrame.new(PX-1.35,GY+1.7,PZ-0.7)*CFrame.Angles(math.rad(14),0,0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargArmR", Vector3.new(0.7,2.4,0.7), CFrame.new(PX+1.35,GY+1.7,PZ-0.7)*CFrame.Angles(math.rad(14),0,0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargPawL", Vector3.new(0.95,0.5,1.5), CFrame.new(PX-1.35,GY+0.45,PZ-1.15), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargPawR", Vector3.new(0.95,0.5,1.5), CFrame.new(PX+1.35,GY+0.45,PZ-1.15), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                makePart("GargTail", Vector3.new(0.5,0.5,2.6), CFrame.new(PX,GY+1.0,PZ+1.9)*CFrame.Angles(math.rad(-18),0,0), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                for _,w in ipairs({
                                                                                                                                    {Vector3.new(0.5,1.15,0.9), CFrame.new(PX-0.78,GY+5.45,PZ-0.1)*CFrame.Angles(0,0,math.rad(22))},
                                                                                                                                    {Vector3.new(0.5,1.15,0.9), CFrame.new(PX+0.78,GY+5.45,PZ-0.1)*CFrame.Angles(0,0,math.rad(-22))},
                                                                                                                                    {Vector3.new(0.45,0.95,0.7), CFrame.new(PX,GY+5.6,PZ-0.1)*CFrame.Angles(math.rad(-12),0,0)},
                                                                                                                                    {Vector3.new(0.55,3.7,2.7), CFrame.new(PX+sd*2.0,GY+3.9,PZ+1.35)*CFrame.Angles(0,math.rad(sd*16),math.rad(-sd*26))},
                                                                                                                                    {Vector3.new(0.5,2.3,1.9), CFrame.new(PX+sd*3.3,GY+5.35,PZ+1.6)*CFrame.Angles(0,math.rad(sd*22),math.rad(-sd*38))},
                                                                                                                                }) do
                                                                                                                                    local wp = Instance.new("WedgePart")
                                                                                                                                    wp.Name="GargWedge"; wp.Size=w[1]; wp.CFrame=w[2]
                                                                                                                                    wp.BrickColor=BrickColor.new("Dark stone grey"); wp.Material=Enum.Material.SmoothPlastic
                                                                                                                                    wp.Anchored=true; wp.CanCollide=false; wp.Parent=LobbyModel
                                                                                                                                end

                                                                                                                                -- Varita apoyada en el lado interior del pilar, punta de cristal
                                                                                                                                local wandCol = (sd<0) and Color3.fromRGB(190,95,255) or Color3.fromRGB(95,175,255)
                                                                                                                                makePart("ClassWandStick", Vector3.new(0.17,4.9,0.17), CFrame.new(PX-sd*2.55,GY-22.1,PZ-1.85)*CFrame.Angles(0,0,math.rad(sd*15)), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                                local wtip = makePart("ClassWandTip", Vector3.new(0.36,0.75,0.36), CFrame.new(PX-sd*3.3,GY-19.85,PZ-1.85), "White", Enum.Material.Neon, LobbyModel, false, true)
                                                                                                                                wtip.Color = wandCol
                                                                                                                                local wl = Instance.new("PointLight"); wl.Brightness=2.5; wl.Range=10; wl.Color=wandCol; wl.Parent=wtip
                                                                                                                            end

                                                                                                                            -- Arco superior escalonado (voxel) uniendo los pilares
                                                                                                                            for _,sd in ipairs({-1,1}) do
                                                                                                                                local ab1 = makePart("ClassArchBlock", Vector3.new(5.2,2.0,3.4), CFrame.new(sd*14.8,27.7,PZ), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                ab1.Color = Color3.fromRGB(41,39,54)
                                                                                                                                local ab2 = makePart("ClassArchBlock", Vector3.new(4.6,1.9,3.4), CFrame.new(sd*10.8,29.3,PZ), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                                ab2.Color = Color3.fromRGB(54,51,68)
                                                                                                                            end
                                                                                                                            makePart("ClassArchBeam", Vector3.new(13,1.9,3.6), CFrame.new(0,30.3,PZ), "Dark stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)
                                                                                                                            makePart("ClassArchKey", Vector3.new(2.4,2.6,3.8), CFrame.new(0,29.9,PZ), "Medium stone grey", Enum.Material.SmoothPlastic, LobbyModel, false, true)

                                                                                                                            -- Runas luminosas sobre la cara frontal del arco (cian y moradas)
                                                                                                                            local runeCols = {Color3.fromRGB(0,235,255), Color3.fromRGB(190,95,255)}
                                                                                                                            for ri,rx in ipairs({-14.8,-10.8,10.8,14.8}) do
                                                                                                                                local ry = (math.abs(rx) > 12) and 27.7 or 29.3
                                                                                                                                local rc = runeCols[(ri%2)+1]
                                                                                                                                local r1 = makePart("ClassRune", Vector3.new(0.26,1.9,0.16), CFrame.new(rx,ry,PZ-1.82), "White", Enum.Material.Neon, LobbyModel, false, true); r1.Color = rc
                                                                                                                                local r2 = makePart("ClassRune", Vector3.new(0.26,1.05,0.16), CFrame.new(rx+0.38,ry+0.42,PZ-1.82)*CFrame.Angles(0,0,math.rad(48)), "White", Enum.Material.Neon, LobbyModel, false, true); r2.Color = rc
                                                                                                                                local r3 = makePart("ClassRune", Vector3.new(0.26,0.9,0.16), CFrame.new(rx+0.36,ry-0.18,PZ-1.82)*CFrame.Angles(0,0,math.rad(-48)), "White", Enum.Material.Neon, LobbyModel, false, true); r3.Color = rc
                                                                                                                            end

                                                                                                                            -- Letrero de madera TOP SORCERERS en el centro del arco
                                                                                                                            local signPart = makePart("TopSorcerersSign", Vector3.new(17,5,0.7), CFrame.new(0,28.2,27.45), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                            signPart.Color = Color3.fromRGB(122,74,34)
                                                                                                                            makePart("SignPostL", Vector3.new(0.8,3.6,0.8), CFrame.new(-6,26.6,28.5), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                            makePart("SignPostR", Vector3.new(0.8,3.6,0.8), CFrame.new(6,26.6,28.5), "Reddish brown", Enum.Material.Wood, LobbyModel, false, true)
                                                                                                                            local signGui = Instance.new("SurfaceGui"); signGui.Face=Enum.NormalId.Front; signGui.AlwaysOnTop=true; signGui.LightInfluence=0; signGui.Parent=signPart
                                                                                                                            local signLbl = Instance.new("TextLabel"); signLbl.Size=UDim2.new(1,0,1,0); signLbl.BackgroundTransparency=1
                                                                                                                            signLbl.Font=Enum.Font.LuckiestGuy; signLbl.TextScaled=true; signLbl.TextColor3=Color3.fromRGB(255,202,40)
                                                                                                                            signLbl.TextStrokeColor3=Color3.fromRGB(40,18,0); signLbl.TextStrokeTransparency=0.15
                                                                                                                            signLbl.Text="TOP\nSORCERERS"; signLbl.Parent=signGui

                                                                                                                            -- Sombrero de mago morado sobre el letrero (cilindros apilados con inclinacion)
                                                                                                                            for _,c in ipairs({
                                                                                                                                {x=0.6, y=31.0, z=27.5, h=0.45, d=6.4, col=Color3.fromRGB(86,42,140), lean=0},
                                                                                                                                {x=0.62, y=31.65, z=27.5, h=0.85, d=4.7, col=Color3.fromRGB(30,16,44), lean=0},
                                                                                                                                {x=0.7, y=32.35, z=27.5, h=1.25, d=4.35, col=Color3.fromRGB(104,54,168), lean=2},
                                                                                                                                {x=1.0, y=33.55, z=27.5, h=1.25, d=3.3, col=Color3.fromRGB(104,54,168), lean=5},
                                                                                                                                {x=1.4, y=34.65, z=27.5, h=1.15, d=2.3, col=Color3.fromRGB(96,48,156), lean=8},
                                                                                                                                {x=1.85, y=35.6, z=27.5, h=1.05, d=1.35, col=Color3.fromRGB(88,44,146), lean=11},
                                                                                                                            }) do
                                                                                                                                local hp = Instance.new("Part")
                                                                                                                                hp.Name="WitchHat"; hp.Shape=Enum.PartType.Cylinder
                                                                                                                                hp.Size=Vector3.new(c.h, c.d, c.d)
                                                                                                                                hp.CFrame=CFrame.new(c.x, c.y, c.z)*CFrame.Angles(0,0,math.rad(90+c.lean))
                                                                                                                                hp.BrickColor=BrickColor.new("White"); hp.Material=Enum.Material.SmoothPlastic
                                                                                                                                hp.Color=c.col; hp.Anchored=true; hp.CanCollide=false; hp.Parent=LobbyModel
                                                                                                                            end
                                                                                                                            local buckle = makePart("HatBuckle", Vector3.new(1.25,0.95,0.25), CFrame.new(0.72,31.65,25.05), "Bright yellow", Enum.Material.Neon, LobbyModel, false, true)
                                                                                                                            buckle.Color = Color3.fromRGB(255,214,64)

                                                                                                                            -- Racimos de cristales brillantes en la base (cian / rosa)
                                                                                                                            for _,cl in ipairs({{-13.6, Color3.fromRGB(94,234,255)}, {13.6, Color3.fromRGB(255,105,220)}}) do
                                                                                                                                local big = nil
                                                                                                                                for j=1,4 do
                                                                                                                                    local ch = 1.5 + j*0.5
                                                                                                                                    local cw = Instance.new("WedgePart")
                                                                                                                                    cw.Name="BaseCrystal"; cw.Size=Vector3.new(0.9+((j%2)*0.3), ch, 0.9+(((j+1)%2)*0.3))
                                                                                                                                    cw.CFrame=CFrame.new(cl[1] + (j-2.5)*0.95, 2.9+ch/2-0.15, 28.5 + ((j%3)-1)*0.4)*CFrame.Angles(math.rad((j-2)*5), math.rad(j*43), math.rad((j%3-1)*9))
                                                                                                                                    cw.BrickColor=BrickColor.new("White"); cw.Material=Enum.Material.Neon
                                                                                                                                    cw.Color=cl[2]; cw.Anchored=true; cw.CanCollide=false; cw.Parent=LobbyModel
                                                                                                                                    if j==3 then big = cw end
                                                                                                                                end
                                                                                                                                if big then local bl = Instance.new("PointLight"); bl.Brightness=3; bl.Range=13; bl.Color=cl[2]; bl.Parent=big end
                                                                                                                            end

                                                                                                                            -- Libros: pila a la izquierda y uno apoyado en el pilar
                                                                                                                            local bookCf = CFrame.new(-25.6,2.32,28.6)*CFrame.Angles(0,math.rad(14),0)
                                                                                                                            local bk1 = makePart("SpellBookCover", Vector3.new(3.2,0.42,2.4), bookCf, "Really red", Enum.Material.SmoothPlastic, LobbyModel, true, true); bk1.Color=Color3.fromRGB(124,32,32)
                                                                                                                            makePart("SpellBookPages", Vector3.new(2.95,0.3,2.15), bookCf*CFrame.new(0,0.34,0), "Institutional white", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                                                                                            local bk2cf = CFrame.new(-25.4,2.95,28.5)*CFrame.Angles(0,math.rad(-9),0)
                                                                                                                            local bk2 = makePart("SpellBookCover2", Vector3.new(2.6,0.38,2.0), bk2cf, "Brown", Enum.Material.SmoothPlastic, LobbyModel, true, true); bk2.Color=Color3.fromRGB(96,56,26)
                                                                                                                            makePart("SpellBookPages2", Vector3.new(2.35,0.26,1.75), bk2cf*CFrame.new(0,0.3,0), "Institutional white", Enum.Material.SmoothPlastic, LobbyModel, true, true)
                                                                                                                            makePart("SpellBookGem", Vector3.new(0.5,0.14,0.5), bookCf*CFrame.new(0,0.55,0), "Bright yellow", Enum.Material.Neon, LobbyModel, false, true)
                                                                                                                            local leanCf = CFrame.new(-14.7,4.35,27.15)*CFrame.Angles(math.rad(17),0,0)
                                                                                                                            local bk3 = makePart("SpellBookLean", Vector3.new(2.3,3.1,0.42), leanCf, "Navy blue", Enum.Material.SmoothPlastic, LobbyModel, false, true); bk3.Color=Color3.fromRGB(34,52,110)
                                                                                                                            makePart("SpellBookLeanPages", Vector3.new(2.0,2.8,0.25), leanCf*CFrame.new(0,0,-0.32), "Institutional white", Enum.Material.SmoothPlastic, LobbyModel, false, true)

                                                                                                                            -- Pociones a la derecha de la base
                                                                                                                            for pi,pc in ipairs({Color3.fromRGB(64,255,120), Color3.fromRGB(190,95,255), Color3.fromRGB(255,80,80)}) do
                                                                                                                                local px2 = 22.9 + pi*1.65
                                                                                                                                local pz2 = 28.7 - (pi%2)*0.5
                                                                                                                                local body = Instance.new("Part")
                                                                                                                                body.Name="PotionBody"; body.Shape=Enum.PartType.Ball; body.Size=Vector3.new(1.05,1.2,1.05)
                                                                                                                                body.CFrame=CFrame.new(px2,2.6,pz2)
                                                                                                                                body.BrickColor=BrickColor.new("Institutional white"); body.Material=Enum.Material.Glass
                                                                                                                                body.Transparency=0.45; body.Anchored=true; body.CanCollide=false; body.Parent=LobbyModel
                                                                                                                                local liq = Instance.new("Part")
                                                                                                                                liq.Name="PotionLiquid"; liq.Shape=Enum.PartType.Ball; liq.Size=Vector3.new(0.82,0.82,0.82)
                                                                                                                                liq.CFrame=CFrame.new(px2,2.48,pz2)
                                                                                                                                liq.BrickColor=BrickColor.new("White"); liq.Material=Enum.Material.Neon
                                                                                                                                liq.Color=pc; liq.Anchored=true; liq.CanCollide=false; liq.Parent=LobbyModel
                                                                                                                                local pl2 = Instance.new("PointLight"); pl2.Brightness=1.6; pl2.Range=8; pl2.Color=pc; pl2.Parent=liq
                                                                                                                                makePart("PotionNeck", Vector3.new(0.36,0.55,0.36), CFrame.new(px2,3.35,pz2), "Institutional white", Enum.Material.Glass, LobbyModel, false, true)
                                                                                                                                makePart("PotionCork", Vector3.new(0.3,0.34,0.3), CFrame.new(px2,3.72,pz2), "Brown", Enum.Material.Wood, LobbyModel, false, true)
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
