-- LocalScript del CALDERO (pegar en StarterPlayer > StarterPlayerScripts)
-- Estilo de la referencia: panel oscuro, titulos amarillos, tarjetas,
-- X roja. Los iconos usan los MODELOS REALES del juego (sin dibujos).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local RE_UI = RS:FindFirstChild("AvadaBosqueUI")
local RE_ACC = RS:FindFirstChild("AvadaBosqueAccion")

-- ===== CONFIG DE ICONOS =====
-- Si tienes el ID de la imagen original, ponlo aqui: "rbxassetid://123456"
-- Si lo dejas vacio, busca un modelo del juego con alguno de estos nombres.
local IMG = { hongo = "", leno = "", saco = "", diam = "" }
local NOMBRES = {
  hongo = { "hongo", "hongos", "mushroom", "seta", "champinon" },
  leno = { "leno", "leño", "lenos", "log", "logs", "wood", "madera", "tronco" },
  saco = { "saco", "saco magico", "saco mágico", "sack", "bag", "magic sack" },
  diam = { "diamante", "diamantes", "diamond", "diamonds", "gem" },
}
local FUENTE = Enum.Font.Kalam
local AMARILLO = Color3.fromRGB(255, 214, 0)

local gui = Instance.new("ScreenGui")
gui.Name = "CalderoHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 51
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- ===== INDICE DE MODELOS DEL JUEGO =====
local indice = {}
local function indexa(raiz)
  for _, d in ipairs(raiz:GetDescendants()) do
    if d:IsA("Model") or d:IsA("Tool") or d:IsA("MeshPart") then
      local n = d.Name:lower()
      if not indice[n] then indice[n] = d end
    end
  end
end
indexa(RS)
indexa(game:GetService("StarterPack"))
indexa(workspace)
local pb = player:FindFirstChildOfClass("Backpack")
if pb then indexa(pb) end

local function buscaModelo(tipo)
  for _, nombre in ipairs(NOMBRES[tipo]) do
    if indice[nombre] then return indice[nombre] end
  end
end

local function vista(padre, src)
  local vf = Instance.new("ViewportFrame")
  vf.Size, vf.BackgroundTransparency = UDim2.fromScale(1, 1), 1
  vf.Ambient, vf.LightColor = Color3.fromRGB(190, 190, 190), Color3.fromRGB(255, 255, 255)
  vf.Parent = padre
  local c = src:Clone()
  for _, d in ipairs(c:GetDescendants()) do
    if d:IsA("BaseScript") then d:Destroy() end
  end
  local m = c
  if not c:IsA("Model") then
    m = Instance.new("Model")
    if c:IsA("BasePart") then
      c.Parent = m
    else
      for _, k in ipairs(c:GetChildren()) do
        if k:IsA("BasePart") or k:IsA("Model") then k.Parent = m end
      end
    end
  end
  m.Parent = vf
  local ok, cf, size = pcall(function()
    local a, b = m:GetBoundingBox()
    return a, b
  end)
  if not ok then return false end
  local cam = Instance.new("Camera")
  cam.Parent = vf
  vf.CurrentCamera = cam
  local dist = math.max(size.X, size.Y, size.Z, 0.5) * 1.7
  cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(1, 0.7, 1).Unit * dist, cf.Position)
  return true
end

local function icono(padre, tipo)
  local id = IMG[tipo]
  if id and id ~= "" then
    local im = Instance.new("ImageLabel")
    im.Size, im.BackgroundTransparency, im.Image = UDim2.fromScale(1, 1), 1, id
    im.ScaleType, im.Parent = Enum.ScaleType.Fit, padre
    return
  end
  local src = buscaModelo(tipo)
  print("[Caldero] icono", tipo, "->", src and src:GetFullName() or "NO ENCONTRADO")
  if src and vista(padre, src) then return end
  local q = Instance.new("TextLabel")
  q.Size, q.BackgroundTransparency, q.Text = UDim2.fromScale(1, 1), 1, "?"
  q.Font, q.TextSize, q.TextColor3, q.Parent = FUENTE, 28, Color3.new(1, 1, 1), padre
end

-- ===== UTILIDADES DE UI =====
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
local function caja(padre, pos, tam, color, transp, radio)
  local f = Instance.new("Frame")
  f.Position, f.Size = pos, tam
  f.BackgroundColor3, f.BackgroundTransparency = color, transp or 0
  f.BorderSizePixel, f.Parent = 0, padre
  Instance.new("UICorner", f).CornerRadius = UDim.new(0, radio or 10)
  return f
end

-- ===== PANEL =====
local calPanel = Instance.new("Frame")
calPanel.Name = "CalderoPanel"
calPanel.AnchorPoint = Vector2.new(0.5, 0.5)
calPanel.Position = UDim2.new(0.5, 0, 0.55, 0)
calPanel.Size = UDim2.new(0.82, 0, 0.8, 0)
calPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
calPanel.BackgroundTransparency = 0.06
calPanel.BorderSizePixel, calPanel.Visible = 0, false
calPanel.Parent = gui
Instance.new("UICorner", calPanel).CornerRadius = UDim.new(0, 8)
local cb = Instance.new("UIStroke")
cb.Color, cb.Transparency, cb.Thickness, cb.Parent = Color3.fromRGB(255, 255, 255), 0.88, 1, calPanel

local calCerrar = Instance.new("TextButton")
calCerrar.AnchorPoint = Vector2.new(1, 0)
calCerrar.Position = UDim2.new(1, 12, 0, -12)
calCerrar.Size = UDim2.new(0, 50, 0, 50)
calCerrar.BackgroundColor3 = Color3.fromRGB(224, 32, 0)
calCerrar.BorderSizePixel, calCerrar.Font = 0, FUENTE
calCerrar.Text, calCerrar.TextSize, calCerrar.TextColor3 = "X", 30, Color3.new(1, 1, 1)
calCerrar.Parent = calPanel
Instance.new("UICorner", calCerrar).CornerRadius = UDim.new(0, 8)
calCerrar.MouseButton1Click:Connect(function() calPanel.Visible = false end)

-- contadores de arriba (icono + numero, centrados)
local fila = Instance.new("Frame")
fila.AnchorPoint = Vector2.new(0.5, 0)
fila.Position, fila.Size = UDim2.new(0.5, 0, 0, 8), UDim2.new(0, 400, 0, 44)
fila.BackgroundTransparency = 1
fila.Parent = calPanel
local fl = Instance.new("UIListLayout")
fl.FillDirection, fl.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 30)
fl.HorizontalAlignment, fl.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center
fl.Parent = fila

local numsArriba = {}
for i, tipo in ipairs({ "hongo", "leno", "diam" }) do
  local item = Instance.new("Frame")
  item.Size, item.BackgroundTransparency, item.LayoutOrder = UDim2.new(0, 104, 0, 44), 1, i
  item.Parent = fila
  local il = Instance.new("UIListLayout")
  il.FillDirection, il.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 8)
  il.VerticalAlignment, il.Parent = Enum.VerticalAlignment.Center, item
  local hold = Instance.new("Frame")
  hold.Size, hold.BackgroundTransparency, hold.LayoutOrder = UDim2.new(0, 38, 0, 38), 1, 1
  hold.Parent = item
  icono(hold, tipo)
  local n = etiqueta("0", 24, UDim2.new(), UDim2.new(0, 56, 0, 38), Color3.new(1, 1, 1), item)
  n.LayoutOrder, n.TextXAlignment = 2, Enum.TextXAlignment.Left
  numsArriba[tipo] = n
end

local function titulo(texto, y)
  local t = etiqueta(texto, 22, UDim2.new(0, 22, 0, y), UDim2.new(0.8, 0, 0, 28), AMARILLO, calPanel)
  t.TextXAlignment = Enum.TextXAlignment.Left
end
titulo("RESERVA DEL CALDERO", 58)

-- tarjetas
local numsTarjeta = {}
local defs = {
  { "Hongos guardados", "hongo", "reserva", true },
  { "En el saco", "saco", "saco", false },
  { "En tu mano", "hongo", "mano", false },
  { "Tus leños", "leno", "lenos", false },
  { "Diamantes", "diam", "diam", false },
}
for i, d in ipairs(defs) do
  local oro = d[4]
  local card = caja(calPanel, UDim2.new(0.018 + (i - 1) * 0.196, 0, 0, 94), UDim2.new(0.178, 0, 0, 142), oro and Color3.fromRGB(150, 118, 34) or Color3.fromRGB(14, 14, 14), 0, 12)
  local bd = Instance.new("UIStroke")
  bd.Color, bd.Transparency, bd.Thickness, bd.Parent = oro and Color3.fromRGB(255, 214, 92) or Color3.fromRGB(255, 255, 255), oro and 0.5 or 0.85, 1.5, card
  local zona = Instance.new("Frame")
  zona.AnchorPoint = Vector2.new(0.5, 0)
  zona.Position, zona.Size = UDim2.new(0.5, 0, 0, 6), UDim2.new(0, 58, 0, 58)
  zona.BackgroundTransparency, zona.BorderSizePixel, zona.Parent = 1, 0, card
  icono(zona, d[2])
  local nom = etiqueta(d[1], 15, UDim2.new(0, 4, 0, 66), UDim2.new(1, -8, 0, 30), Color3.new(1, 1, 1), card)
  nom.TextWrapped, nom.TextXAlignment = true, Enum.TextXAlignment.Center
  local num = etiqueta("0", 28, UDim2.new(0, 4, 0, 100), UDim2.new(1, -8, 0, 34), Color3.new(1, 1, 1), card)
  num.TextXAlignment = Enum.TextXAlignment.Center
  numsTarjeta[d[3]] = num
end

titulo("COMO SE GUARDA", 252)
local pista = etiqueta("Toca SOLTAR junto al caldero para echar los hongos que llevas en la mano y en el saco. Quedan guardados aqui, para tu equipo.", 17, UDim2.new(0, 22, 0, 284), UDim2.new(0.94, 0, 0, 50), Color3.fromRGB(230, 230, 230), calPanel)
pista.TextWrapped = true
pista.TextXAlignment = Enum.TextXAlignment.Left
pista.TextYAlignment = Enum.TextYAlignment.Top

-- ===== ABRIR CON "VER" =====
print("[Caldero] LocalScript cargado")
local function abrirCaldero()
  calPanel.Visible = true
  if RE_ACC then pcall(function() RE_ACC:FireServer("VerCaldero") end) end
end
local enganchados = {}
local function enganchaPrompt(pr)
  if enganchados[pr] then return end
  enganchados[pr] = true
  print("[Caldero] prompt enganchado:", pr:GetFullName())
  pr.Triggered:Connect(abrirCaldero)
end
local function esCaldero(d)
  return d:IsA("ProximityPrompt") and d:GetFullName():lower():find("caldero") ~= nil
end
local function escaneaCalderos()
  for _, d in ipairs(workspace:GetDescendants()) do
    if esCaldero(d) then enganchaPrompt(d) end
  end
end
escaneaCalderos()
workspace.DescendantAdded:Connect(function(d)
  if esCaldero(d) then enganchaPrompt(d) end
end)
task.spawn(function()
  while true do
    task.wait(2)
    escaneaCalderos()
  end
end)

-- si falta algun modelo, lista nombres de ReplicatedStorage para ajustarlo
task.delay(4, function()
  local falta = false
  for tipo in pairs(NOMBRES) do
    if (not IMG[tipo] or IMG[tipo] == "") and not buscaModelo(tipo) then falta = true end
  end
  if not falta then return end
  local lista = {}
  for _, d in ipairs(RS:GetDescendants()) do
    if d:IsA("Model") or d:IsA("Tool") then table.insert(lista, d.Name) end
    if #lista >= 80 then break end
  end
  print("[Caldero] Modelos en ReplicatedStorage:", table.concat(lista, ", "))
end)

-- ===== DATOS DEL SERVIDOR =====
task.spawn(function()
  RE_UI = RE_UI or RS:WaitForChild("AvadaBosqueUI", 60)
  RE_ACC = RE_ACC or RS:WaitForChild("AvadaBosqueAccion", 60)
  if not RE_UI then warn("[Caldero] No existe AvadaBosqueUI en ReplicatedStorage") return end
  RE_UI.OnClientEvent:Connect(function(st)
    if type(st) ~= "table" then return end
    local diam = tostring(st.diamantes or st.diam or 0)
    numsArriba.hongo.Text = tostring(st.calderoHongos or 0)
    numsArriba.leno.Text = tostring(st.lenos or 0)
    numsArriba.diam.Text = diam
    numsTarjeta.reserva.Text = tostring(st.calderoHongos or 0)
    numsTarjeta.saco.Text = tostring(st.hongosSaco or 0)
    numsTarjeta.mano.Text = (st.manoTipo == "Hongo") and "1" or "0"
    numsTarjeta.lenos.Text = tostring(st.lenos or 0)
    numsTarjeta.diam.Text = diam
  end)
end)

-- FIN LOCAL CALDERO
