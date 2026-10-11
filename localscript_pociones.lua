-- LocalScript POCIONES (pegar en StarterPlayer > StarterPlayerScripts)
-- Sistema de fabricación del caldero. NO toca partida.
-- - Agrega la sección POCIONES al panel del caldero (recetas + Fabricar/Te falta).
-- - Toma el botón Comer: si hay poción la bebe, si no hace lo normal.

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

local RECETAS = {
  Vida  = { hongo = 2, mora = 1, diamante = 0, titulo = "Poción de Vida",
            desc = "Cura 60 de vida", icono = "❤️", color = Color3.fromRGB(255, 90, 90) },
  Vigor = { hongo = 1, mora = 2, diamante = 0, titulo = "Poción de Vigor",
            desc = "+80 de vida (vigor)", icono = "💙", color = Color3.fromRGB(90, 180, 255) },
  Llama = { hongo = 0, mora = 2, diamante = 1, titulo = "Poción de Llama",
            desc = "Erupción en la fogata", icono = "🔥", color = Color3.fromRGB(255, 160, 60) },
}
local ORDEN = { "Vida", "Vigor", "Llama" }

local reserva = { hongo = 0, mora = 0, diamante = 0 }
local miSacoPoc = {}
local ultimoHongos = -1
local accionComer = "Comer" -- lo que haría el Comer de partida

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

local function costoTexto(r)
  local partes = {}
  if r.hongo > 0 then table.insert(partes, r.hongo .. "🍄") end
  if r.mora > 0 then table.insert(partes, r.mora .. "🫐") end
  if r.diamante > 0 then table.insert(partes, r.diamante .. "💎") end
  return table.concat(partes, " + ")
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
local reservaLbl

local function construirSeccion()
  local pg = player:WaitForChild("PlayerGui")
  local hud = pg:WaitForChild("CalderoHUD", 30)
  if not hud then return end
  local panel = hud:WaitForChild("CalderoPanel", 30)
  if not panel then return end
  local yaScroll = panel:FindFirstChild("PocScroll")
  if yaScroll and yaScroll:FindFirstChild("PocionesSec") then return end

  -- El panel es corto y mi sección quedaba cortada: lo hago desplazable.
  -- Muevo el contenido existente a un scroll (el botón X se queda).
  local scroll = panel:FindFirstChild("PocScroll")
  if not scroll then
    scroll = Instance.new("ScrollingFrame")
    scroll.Name = "PocScroll"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(160, 160, 160)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 680)
    scroll.Parent = panel
    for _, ch in ipairs(panel:GetChildren()) do
      if ch ~= scroll and ch.Name ~= "PocionesSec" then
        if ch:IsA("TextButton") or ch:IsA("UICorner") or ch:IsA("UIStroke") then
          -- el botón X y la decoración del panel se quedan
        else
          ch.Parent = scroll
        end
      end
    end
  end

  local sec = Instance.new("Frame")
  sec.Name = "PocionesSec"
  sec.BackgroundTransparency = 1
  sec.Size = UDim2.new(1, 0, 0, 300)
  sec.Position = UDim2.new(0, 0, 0, 344)
  sec.Parent = scroll
  scroll.CanvasSize = UDim2.new(0, 0, 0, 344 + 300)

  local tit = etiqueta("POCIONES", 22, UDim2.new(0, 22, 0, 0), UDim2.new(0.8, 0, 0, 28), AMARILLO, sec)
  tit.TextXAlignment = Enum.TextXAlignment.Left

  reservaLbl = etiqueta("", 17, UDim2.new(0, 22, 0, 28), UDim2.new(0.94, 0, 0, 24), Color3.fromRGB(230, 230, 230), sec)
  reservaLbl.TextXAlignment = Enum.TextXAlignment.Left

  for i, id in ipairs(ORDEN) do
    local r = RECETAS[id]
    local y = 56 + (i - 1) * 58
    local card = Instance.new("Frame")
    card.Position = UDim2.new(0, 22, 0, y)
    card.Size = UDim2.new(1, -44, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    card.BorderSizePixel = 0
    card.Parent = sec
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local bd = Instance.new("UIStroke")
    bd.Color, bd.Transparency, bd.Thickness, bd.Parent = r.color, 0.4, 1.5, card

    etiqueta(r.icono, 26, UDim2.new(0, 8, 0, 4), UDim2.new(0, 40, 0, 44), Color3.new(1,1,1), card)
    local nom = etiqueta(r.titulo, 16, UDim2.new(0, 52, 0, 2), UDim2.new(1, -160, 0, 22), Color3.new(1,1,1), card)
    nom.TextXAlignment = Enum.TextXAlignment.Left
    local det = etiqueta(costoTexto(r) .. "  ·  " .. r.desc, 13, UDim2.new(0, 52, 0, 24), UDim2.new(1, -160, 0, 24), Color3.fromRGB(200, 200, 200), card)
    det.TextXAlignment = Enum.TextXAlignment.Left
    det.TextWrapped = true

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

  -- depositar moras / diamantes
  local depMora = Instance.new("TextButton")
  depMora.Position = UDim2.new(0, 22, 0, 56 + 3 * 58 + 6)
  depMora.Size = UDim2.new(0.45, -28, 0, 34)
  depMora.Font, depMora.TextSize, depMora.TextColor3 = FUENTE, 15, Color3.new(1, 1, 1)
  depMora.Text = "＋ Echar moras 🫐"
  depMora.BackgroundColor3 = Color3.fromRGB(60, 60, 140)
  depMora.BorderSizePixel = 0
  depMora.AutoButtonColor = true
  depMora.Parent = sec
  Instance.new("UICorner", depMora).CornerRadius = UDim.new(0, 8)
  depMora.MouseButton1Click:Connect(function()
    RE_POC:FireServer("Depositar", "Mora")
  end)

  local depDiam = Instance.new("TextButton")
  depDiam.Position = UDim2.new(0.5, 6, 0, 56 + 3 * 58 + 6)
  depDiam.Size = UDim2.new(0.45, -28, 0, 34)
  depDiam.Font, depDiam.TextSize, depDiam.TextColor3 = FUENTE, 15, Color3.new(1, 1, 1)
  depDiam.Text = "＋ Echar diamante 💎"
  depDiam.BackgroundColor3 = Color3.fromRGB(40, 120, 140)
  depDiam.BorderSizePixel = 0
  depDiam.AutoButtonColor = true
  depDiam.Parent = sec
  Instance.new("UICorner", depDiam).CornerRadius = UDim.new(0, 8)
  depDiam.MouseButton1Click:Connect(function()
    RE_POC:FireServer("Depositar", "Diamante")
  end)
end

local function refrescarRecetas()
  if reservaLbl then
    reservaLbl.Text = string.format("Reserva: %d🍄  %d🫐  %d💎", reserva.hongo, reserva.mora, reserva.diamante)
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
  -- busca el botón Comer de partida para copiar posición
  local pos, padre, tam = UDim2.new(1, -122, 1, -164), nil, UDim2.new(0, 50, 0, 50)
  for _, d in ipairs(player.PlayerGui:GetDescendants()) do
    if d:IsA("TextButton") and (d.Text == "Comer" or d.Text == "Desalmacenar") and d.Size == UDim2.new(0, 50, 0, 50) then
      pos, padre = d.Position, d.Parent
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
  miComer.Size = tam
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
      RE_POC:FireServer("Beber") -- la poción, no la comida
    else
      RE_ACC:FireServer(accionComer) -- lo normal de partida
    end
  end)
end

-- ===== estado de partida =====
if RE_UI then
  RE_UI.OnClientEvent:Connect(function(st)
    if type(st) ~= "table" then return end
    -- pasa los hongos del caldero a mi servidor (libro mayor)
    local h = st.calderoHongos or 0
    if h ~= ultimoHongos then
      ultimoHongos = h
      pcall(function()
        RE_POC:FireServer("Hongos", h)
      end)
    end
    -- replica la lógica del botón de partida
    if st.mano == true then
      accionComer = "Comer"
    elseif st.sacoEnMano == true and (st.saco or 0) > 0 then
      accionComer = "Desalmacenar"
    else
      accionComer = "Comer"
    end
    -- mi botón solo aparece si hay poción que beber
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
  -- reintenta por si el panel tarda
  for _ = 1, 10 do
    task.wait(3)
    if player.PlayerGui:FindFirstChild("CalderoHUD") then
      construirSeccion()
    end
    if not miComer then
      construirBoton()
    end
  end
end)
-- el botón solo aparece cuando hay poción que beber (mano o saco virtual)
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
  -- pide la reserva al servidor
  pcall(function()
    RE_POC:FireServer("Hongos", ultimoHongos < 0 and 0 or ultimoHongos)
  end)
end)

print("[Pociones] LocalScript cargado")
-- FIN LOCAL POCIONES
