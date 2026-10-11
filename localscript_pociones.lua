-- LocalScript POCIONES (pegar en StarterPlayer > StarterPlayerScripts)
-- Sistema de fabricación del caldero. NO toca partida.
-- - Agrega la sección POCIONES al panel del caldero (recetas + Fabricar/Te falta).
-- - Toma el botón Comer: si hay poción la bebe, si no hace lo normal.
-- - El botón Soltar también echa moras y diamantes a la reserva.
-- - Íconos 3D procedurales (estilo 99 Noches), sin emojis.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local RE_POC = RS:WaitForChild("PocionesEvent", 60)
local RE_UI = RS:WaitForChild("AvadaBosqueUI", 60)
local RE_ACC = RS:WaitForChild("AvadaBosqueAccion", 60)

local FUENTE = Enum.Font.Kalam
local AMARILLO = Color3.fromRGB(255, 214, 0)
local VERDE = Color3.fromRGB(40, 160, 70)
local GRIS_BOTON = Color3.fromRGB(95, 95, 100)

-- Íconos dibujados estilo 99 Noches (subidos a Roblox).
-- Cuando tengas los IDs reales, reemplázalos aquí. Mientras tanto usa los 3D.
local ICONOS = {
  hongo = "rbxassetid://0",
  mora = "rbxassetid://0",
  diamante = "rbxassetid://0",
  pocionVida = "rbxassetid://0",
  pocionVigor = "rbxassetid://0",
  pocionLlama = "rbxassetid://0",
}

local RECETAS = {
  Vida  = { hongo = 2, mora = 1, diamante = 0, titulo = "Poción de Vida",
            desc = "Cura 60 de vida", color = Color3.fromRGB(255, 90, 90) },
  Vigor = { hongo = 1, mora = 2, diamante = 0, titulo = "Poción de Vigor",
            desc = "+80 de vida (vigor)", color = Color3.fromRGB(90, 180, 255) },
  Llama = { hongo = 0, mora = 2, diamante = 1, titulo = "Poción de Llama",
            desc = "Erupción en la fogata", color = Color3.fromRGB(255, 160, 60) },
}
local ORDEN = { "Vida", "Vigor", "Llama" }

local reserva = { hongo = 0, mora = 0, diamante = 0 }
local miSacoPoc = {}
local ultimoHongos = -1
local accionComer = "Comer"

local function modeloIcono(tipo)
  local m = Instance.new("Model")
  m.Name = "Icono_" .. tipo
  local function parte(shape, size, color, cf, material)
    local p = Instance.new("Part")
    p.Shape = shape
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.CFrame = cf or CFrame.new()
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = m
    return p
  end
  if tipo == "hongo" then
    parte(Enum.PartType.Cylinder, Vector3.new(0.9, 0.45, 0.45),
      Color3.fromRGB(228, 208, 178), CFrame.new(0, 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)))
    parte(Enum.PartType.Ball, Vector3.new(1.5, 0.8, 1.5),
      Color3.fromRGB(188, 66, 55), CFrame.new(0, 1.05, 0))
    parte(Enum.PartType.Ball, Vector3.new(0.28, 0.28, 0.28),
      Color3.fromRGB(245, 235, 225), CFrame.new(0.4, 1.25, 0.3))
    parte(Enum.PartType.Ball, Vector3.new(0.22, 0.22, 0.22),
      Color3.fromRGB(245, 235, 225), CFrame.new(-0.35, 1.2, -0.25))
  elseif tipo == "mora" then
    parte(Enum.PartType.Ball, Vector3.new(1.05, 1.05, 1.05),
      Color3.fromRGB(58, 68, 130), CFrame.new(0, 0.55, 0))
    parte(Enum.PartType.Ball, Vector3.new(0.35, 0.35, 0.35),
      Color3.fromRGB(120, 140, 200), CFrame.new(-0.25, 0.8, 0.25))
    parte(Enum.PartType.Cylinder, Vector3.new(0.35, 0.12, 0.12),
      Color3.fromRGB(35, 95, 45), CFrame.new(0, 1.12, 0) * CFrame.Angles(0, 0, math.rad(90)))
  elseif tipo == "diamante" then
    parte(Enum.PartType.Block, Vector3.new(0.85, 0.85, 0.85),
      Color3.fromRGB(130, 225, 255),
      CFrame.new(0, 0.65, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0),
      Enum.Material.Neon)
  elseif tipo == "pocionVida" or tipo == "pocionVigor" or tipo == "pocionLlama" then
    local col = tipo == "pocionVida" and Color3.fromRGB(255, 90, 90)
      or (tipo == "pocionVigor" and Color3.fromRGB(90, 180, 255) or Color3.fromRGB(255, 160, 60))
    parte(Enum.PartType.Cylinder, Vector3.new(1.0, 0.72, 0.72),
      col, CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon)
    parte(Enum.PartType.Cylinder, Vector3.new(0.4, 0.34, 0.34),
      Color3.fromRGB(72, 48, 26), CFrame.new(0, 1.18, 0) * CFrame.Angles(0, 0, math.rad(90)),
      Enum.Material.Wood)
  end
  return m
end

local function icono3D(padre, tipo, tam, pos)
  local vf = Instance.new("ViewportFrame")
  vf.Size = UDim2.new(0, tam, 0, tam)
  if pos then
    vf.Position = pos
  end
  vf.BackgroundTransparency = 1
  vf.BorderSizePixel = 0
  vf.Ambient = Color3.fromRGB(210, 210, 210)
  vf.LightColor = Color3.fromRGB(255, 255, 255)
  vf.LightDirection = Vector3.new(-1, -1, -1)
  vf.Parent = padre
  local m = modeloIcono(tipo)
  m.Parent = vf
  local ok, cf, size = pcall(function()
    return m:GetBoundingBox()
  end)
  if ok then
    local cam = Instance.new("Camera")
    cam.Parent = vf
    vf.CurrentCamera = cam
    local dist = math.max(size.X, size.Y, size.Z, 0.5) * 2.4
    cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(1, 0.55, 1).Unit * dist, cf.Position)
  end
  return vf
end
-- ===== ÍCONOS (imagen estilo 99 Noches, o 3D procedural de respaldo) =====
local function icono(padre, tipo, tam, pos)
  local id = ICONOS[tipo]
  if id and id ~= "" and id ~= "rbxassetid://0" then
    local im = Instance.new("ImageLabel")
    im.Size = UDim2.new(0, tam, 0, tam)
    if pos then
      im.Position = pos
    end
    im.BackgroundTransparency = 1
    im.BorderSizePixel = 0
    im.Image = id
    im.ScaleType = Enum.ScaleType.Fit
    im.Parent = padre
    return im
  end
  return icono3D(padre, tipo, tam, pos)
end

-- ===== utilidades =====
local function etiqueta(texto, size, pos, tam, color, padre)
  local l = Instance.new("TextLabel")
  l.BackgroundTransparency = 1
  l.Font = FUENTE
  l.Text, l.TextSize, l.TextColor3 = texto, size, color or Color3.new(1, 1, 1)
  l.Position, l.Size, l.Parent = pos, tam, padre
  local st = Instance.new("UIStroke")
  st.Color, st.Thickness, st.Parent = Color3.new(0, 0, 0), 1.2, l
  return l
end

local function tengoPocion()
  local ch = player.Character
  if ch then
    local t = ch:FindFirstChildOfClass("Tool")
    if t and t:GetAttribute("Pocion") then
      return true
    end
  end
  return #miSacoPoc > 0
end

-- ===== aviso flotante =====
local guiAviso = Instance.new("ScreenGui")
guiAviso.Name = "PocionesAviso"
guiAviso.ResetOnSpawn = false
guiAviso.DisplayOrder = 90
guiAviso.IgnoreGuiInset = true
guiAviso.Parent = player:WaitForChild("PlayerGui")

local function avisar(texto)
  local f = Instance.new("TextLabel")
  f.AnchorPoint = Vector2.new(0.5, 0)
  f.Position = UDim2.new(0.5, 0, 0, 90)
  f.Size = UDim2.new(0, 420, 0, 44)
  f.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
  f.BackgroundTransparency = 0.15
  f.Font = FUENTE
  f.TextSize = 19
  f.TextColor3 = Color3.new(1, 1, 1)
  f.Text = texto
  f.TextWrapped = true
  f.Parent = guiAviso
  Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
  task.delay(2.4, function()
    pcall(function()
      f:Destroy()
    end)
  end)
end

-- ===== sección POCIONES en el panel del caldero =====
local recetaUI = {}
local reservaFila

local function miniIcono(padre, tipo, x)
  local f = Instance.new("Frame")
  f.Size = UDim2.new(0, 52, 0, 26)
  f.Position = UDim2.new(0, x, 0, 0)
  f.BackgroundTransparency = 1
  f.Parent = padre
  icono(f, tipo, 24, UDim2.new(0, 0, 0, 1))
  return f
end

local function construirSeccion()
  local pg = player:WaitForChild("PlayerGui")
  local hud = pg:WaitForChild("CalderoHUD", 30)
  if not hud then return end
  local panel = hud:WaitForChild("CalderoPanel", 30)
  if not panel then return end
  local yaScroll = panel:FindFirstChild("PocScroll")
  if yaScroll and yaScroll:FindFirstChild("PocionesSec") then return end

  -- panel desplazable para que la sección no quede cortada
  local scroll = yaScroll
  if not scroll then
    scroll = Instance.new("ScrollingFrame")
    scroll.Name = "PocScroll"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(160, 160, 160)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 700)
    scroll.Parent = panel
    for _, ch in ipairs(panel:GetChildren()) do
      if ch ~= scroll and ch.Name ~= "PocionesSec" then
        if ch:IsA("TextButton") or ch:IsA("UICorner") or ch:IsA("UIStroke") then
          -- el botón X y la decoración se quedan
        else
          ch.Parent = scroll
        end
      end
    end
  end

  local sec = Instance.new("Frame")
  sec.Name = "PocionesSec"
  sec.BackgroundTransparency = 1
  sec.Size = UDim2.new(1, 0, 0, 320)
  sec.Position = UDim2.new(0, 0, 0, 344)
  sec.Parent = scroll
  scroll.CanvasSize = UDim2.new(0, 0, 0, 344 + 320)

  local tit = etiqueta("POCIONES", 22, UDim2.new(0, 22, 0, 0), UDim2.new(0.8, 0, 0, 28), AMARILLO, sec)
  tit.TextXAlignment = Enum.TextXAlignment.Left

  -- reserva con íconos
  reservaFila = Instance.new("Frame")
  reservaFila.Position = UDim2.new(0, 22, 0, 30)
  reservaFila.Size = UDim2.new(1, -44, 0, 30)
  reservaFila.BackgroundTransparency = 1
  reservaFila.Parent = sec
  local rx = 0
  for _, t in ipairs({ "hongo", "mora", "diamante" }) do
    local f = miniIcono(reservaFila, t, rx)
    local n = etiqueta("0", 17, UDim2.new(0, 26, 0, 0), UDim2.new(0, 40, 0, 26), Color3.new(1,1,1), f)
    n.TextXAlignment = Enum.TextXAlignment.Left
    rx += 72
  end
  reservaFila.Name = "ReservaFila"

  for i, id in ipairs(ORDEN) do
    local r = RECETAS[id]
    local y = 64 + (i - 1) * 62
    local card = Instance.new("Frame")
    card.Position = UDim2.new(0, 22, 0, y)
    card.Size = UDim2.new(1, -44, 0, 56)
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    card.BorderSizePixel = 0
    card.Parent = sec
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local bd = Instance.new("UIStroke")
    bd.Color, bd.Transparency, bd.Thickness, bd.Parent = r.color, 0.4, 1.5, card

    icono(card, "pocion" .. id, 44, UDim2.new(0, 6, 0, 6))

    local nom = etiqueta(r.titulo, 16, UDim2.new(0, 56, 0, 2), UDim2.new(1, -170, 0, 20), Color3.new(1,1,1), card)
    nom.TextXAlignment = Enum.TextXAlignment.Left
    -- costo con íconos
    local cx = 56
    local cy = 24
    local function costo(tipo, cant)
      if cant <= 0 then return end
      icono(card, tipo, 20, UDim2.new(0, cx, 0, cy))
      local nn = etiqueta("x" .. cant, 14, UDim2.new(0, cx + 22, 0, cy), UDim2.new(0, 34, 0, 20), Color3.fromRGB(220,220,220), card)
      nn.TextXAlignment = Enum.TextXAlignment.Left
      cx += 58
    end
    costo("hongo", r.hongo)
    costo("mora", r.mora)
    costo("diamante", r.diamante)
    local det = etiqueta(r.desc, 13, UDim2.new(0, 56, 0, 40), UDim2.new(1, -170, 0, 16), Color3.fromRGB(190, 190, 190), card)
    det.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0)
    btn.Size = UDim2.new(0, 92, 0, 36)
    btn.Font = FUENTE
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Te falta"
    btn.BackgroundColor3 = GRIS_BOTON
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function()
      RE_POC:FireServer("Fabricar", id)
    end)
    recetaUI[id] = { boton = btn }
  end

  -- depositar moras / diamantes (con íconos)
  local yDep = 64 + 3 * 62 + 8
  local function botonDep(texto, tipo, xPos, esMora)
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(0, xPos, 0, yDep)
    b.Size = UDim2.new(0, 200, 0, 36)
    b.Font, b.TextSize, b.TextColor3 = FUENTE, 15, Color3.new(1, 1, 1)
    b.Text = texto
    b.BackgroundColor3 = esMora and Color3.fromRGB(60, 60, 140) or Color3.fromRGB(40, 120, 140)
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Parent = sec
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    icono(b, tipo, 26, UDim2.new(1, -32, 0, 5))
    b.MouseButton1Click:Connect(function()
      RE_POC:FireServer("Depositar", esMora and "Mora" or "Diamante")
    end)
  end
  botonDep("＋ Echar moras", "mora", 22, true)
  botonDep("＋ Echar diamante", "diamante", 234, false)
end

local function refrescarRecetas()
  -- actualiza los números de la reserva (busca las etiquetas)
  local sec = nil
  local pg = player.PlayerGui
  local hud = pg:FindFirstChild("CalderoHUD")
  local panel = hud and hud:FindFirstChild("CalderoPanel")
  local scroll = panel and panel:FindFirstChild("PocScroll")
  sec = scroll and scroll:FindFirstChild("PocionesSec")
  if sec then
    local fila = sec:FindFirstChild("ReservaFila")
    if fila then
      local vals = { reserva.hongo, reserva.mora, reserva.diamante }
      local idx = 0
      for _, f in ipairs(fila:GetChildren()) do
        if f:IsA("Frame") then
          idx += 1
          for _, l in ipairs(f:GetChildren()) do
            if l:IsA("TextLabel") then
              l.Text = tostring(vals[idx] or 0)
            end
          end
        end
      end
    end
  end
  for id, ui in pairs(recetaUI) do
    local r = RECETAS[id]
    local alcanza = reserva.hongo >= r.hongo and reserva.mora >= r.mora and reserva.diamante >= r.diamante
    ui.boton.Text = alcanza and "Fabricar" or "Te falta"
    ui.boton.BackgroundColor3 = alcanza and VERDE or GRIS_BOTON
  end
end

-- ===== botón Comer (toma el control del de partida) =====
local miComer

local function construirBoton()
  local pos = UDim2.new(1, -122, 1, -164)
  for _, d in ipairs(player.PlayerGui:GetDescendants()) do
    if d:IsA("TextButton") and (d.Text == "Comer" or d.Text == "Desalmacenar") and d.Size == UDim2.new(0, 50, 0, 50) then
      pos = d.Position
      break
    end
  end
  local g = Instance.new("ScreenGui")
  g.Name = "PocionesComer"
  g.ResetOnSpawn = false
  g.DisplayOrder = 80
  g.IgnoreGuiInset = true
  g.Parent = player.PlayerGui
  miComer = Instance.new("TextButton")
  miComer.AnchorPoint = Vector2.new(0.5, 0.5)
  miComer.Position = pos
  miComer.Size = UDim2.new(0, 50, 0, 50)
  miComer.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
  miComer.BackgroundTransparency = 0.32
  miComer.BorderSizePixel = 0
  miComer.Font = Enum.Font.GothamBold
  miComer.Text = "Comer"
  miComer.TextSize = 12
  miComer.TextColor3 = Color3.new(1, 1, 1)
  miComer.AutoButtonColor = true
  miComer.Visible = false
  miComer.Parent = g
  Instance.new("UICorner", miComer).CornerRadius = UDim.new(1, 0)
  local st = Instance.new("UIStroke")
  st.Color, st.Transparency, st.Thickness, st.Parent = Color3.fromRGB(0, 0, 0), 0.45, 1.4, miComer
  miComer.MouseButton1Click:Connect(function()
    if tengoPocion() then
      RE_POC:FireServer("Beber")
    else
      RE_ACC:FireServer(accionComer)
    end
  end)
end

-- ===== el botón Soltar también echa moras y diamantes =====
local soltarConectado = false
local function conectarSoltar()
  if soltarConectado then return end
  for _, d in ipairs(player.PlayerGui:GetDescendants()) do
    if d:IsA("TextButton") and d.Text == "Soltar" then
      soltarConectado = true
      d.MouseButton1Click:Connect(function()
        -- partida echa los hongos; yo echo moras y diamantes
        RE_POC:FireServer("DepositarTodo")
      end)
      break
    end
  end
end

-- ===== estado de partida =====
if RE_UI then
  RE_UI.OnClientEvent:Connect(function(st)
    if type(st) ~= "table" then return end
    local h = st.calderoHongos or 0
    if h ~= ultimoHongos then
      ultimoHongos = h
      pcall(function()
        RE_POC:FireServer("Hongos", h)
      end)
    end
    if st.mano == true then
      accionComer = "Comer"
    elseif st.sacoEnMano == true and (st.saco or 0) > 0 then
      accionComer = "Desalmacenar"
    else
      accionComer = "Comer"
    end
    if miComer then
      miComer.Visible = tengoPocion()
    end
  end)
end

-- ===== mensajes de mi servidor =====
if RE_POC then
  RE_POC.OnClientEvent:Connect(function(tipo, a)
    if tipo == "Reserva" and type(a) == "table" then
      reserva.hongo = a.hongo or 0
      reserva.mora = a.mora or 0
      reserva.diamante = a.diamante or 0
      refrescarRecetas()
    elseif tipo == "SacoPoc" and type(a) == "table" then
      miSacoPoc = a
      if miComer then
        miComer.Visible = tengoPocion()
      end
    elseif tipo == "Aviso" then
      avisar(tostring(a))
    end
  end)
end

-- ===== arranque =====
task.spawn(function()
  construirSeccion()
  for _ = 1, 10 do
    task.wait(3)
    if player.PlayerGui:FindFirstChild("CalderoHUD") then
      construirSeccion()
    end
    if not miComer then
      construirBoton()
    end
    conectarSoltar()
  end
end)
task.spawn(function()
  while true do
    task.wait(0.5)
    if miComer then
      miComer.Visible = tengoPocion()
    end
  end
end)
task.delay(2, function()
  if not miComer then
    construirBoton()
  end
  conectarSoltar()
  pcall(function()
    RE_POC:FireServer("Hongos", ultimoHongos < 0 and 0 or ultimoHongos)
  end)
end)

print("[Pociones] LocalScript cargado")
-- FIN LOCAL POCIONES
