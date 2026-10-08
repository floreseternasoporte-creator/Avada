-- LocalScript del CALDERO (pegar en StarterPlayer > StarterPlayerScripts)
-- El panel de la reserva como el menu de la imagen de referencia (panel
-- oscuro translucido, contadores arriba, tarjetas con icono y numero,
-- titulos amarillos en cursiva y la X roja en la esquina), el prompt
-- "Ver". Vive aparte del HUD para que ningun fallo aqui pueda tocar
-- la interfaz de la partida. La animacion del liquido va en su propio
-- LocalScript (CALDERO ANIM), asi este queda corto y no se corta.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local RE_UI = RS:WaitForChild("AvadaBosqueUI")
local RE_ACC = RS:WaitForChild("AvadaBosqueAccion")

local gui = Instance.new("ScreenGui")
gui.Name = "CalderoHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 51
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function etiqueta(texto, size, pos, tam, color, padre)
  local l = Instance.new("TextLabel")
  l.BackgroundTransparency = 1
  l.Font = Enum.Font.GothamBold
  l.Text = texto
  l.TextSize = size
  l.TextColor3 = color or Color3.new(1, 1, 1)
  l.Position = pos
  l.Size = tam
  l.Parent = padre
  local st = Instance.new("UIStroke")
  st.Color = Color3.new(0, 0, 0)
  st.Thickness = 1.6
  st.Parent = l
  return l
end

-- Iconos dibujados con Frames (sin imagenes de catalogo): el hongo,
-- el leno, el saco y el diamante de los contadores y las tarjetas.
local function iconoHongo(padre, x, y, esc)
  local f = Instance.new("Frame")
  f.Position = UDim2.new(0, x, 0, y)
  f.Size = UDim2.new(0, 36 * esc, 0, 32 * esc)
  f.BackgroundTransparency = 1
  f.Parent = padre
  local tallo = Instance.new("Frame")
  tallo.AnchorPoint = Vector2.new(0.5, 0)
  tallo.Position = UDim2.new(0.5, 0, 0.45, 0)
  tallo.Size = UDim2.new(0.36, 0, 0.55, 0)
  tallo.BackgroundColor3 = Color3.fromRGB(238, 218, 178)
  tallo.BorderSizePixel = 0
  tallo.Parent = f
  Instance.new("UICorner", tallo).CornerRadius = UDim.new(0.35, 0)
  local sombrero = Instance.new("Frame")
  sombrero.Size = UDim2.new(1, 0, 0.58, 0)
  sombrero.BackgroundColor3 = Color3.fromRGB(154, 84, 52)
  sombrero.BorderSizePixel = 0
  sombrero.Parent = f
  Instance.new("UICorner", sombrero).CornerRadius = UDim.new(0.55, 0)
  for _, sp in ipairs({ { 0.18, 0.16 }, { 0.48, 0.30 }, { 0.72, 0.14 } }) do
    local mancha = Instance.new("Frame")
    mancha.Position = UDim2.new(sp[1], 0, sp[2], 0)
    mancha.Size = UDim2.new(0.18, 0, 0.18, 0)
    mancha.BackgroundColor3 = Color3.fromRGB(238, 205, 160)
    mancha.BorderSizePixel = 0
    mancha.Parent = sombrero
    Instance.new("UICorner", mancha).CornerRadius = UDim.new(1, 0)
  end
  return f
end
local function iconoLeno(padre, x, y, esc)
  local f = Instance.new("Frame")
  f.Position = UDim2.new(0, x, 0, y)
  f.Size = UDim2.new(0, 38 * esc, 0, 24 * esc)
  f.BackgroundTransparency = 1
  f.Parent = padre
  local cuerpo = Instance.new("Frame")
  cuerpo.Size = UDim2.new(1, 0, 0.72, 0)
  cuerpo.Position = UDim2.new(0, 0, 0.14, 0)
  cuerpo.BackgroundColor3 = Color3.fromRGB(122, 79, 43)
  cuerpo.BorderSizePixel = 0
  cuerpo.Parent = f
  Instance.new("UICorner", cuerpo).CornerRadius = UDim.new(0.4, 0)
  local cara = Instance.new("Frame")
  cara.AnchorPoint = Vector2.new(0.5, 0.5)
  cara.Position = UDim2.new(0.12, 0, 0.5, 0)
  cara.Size = UDim2.new(0, 15 * esc, 0, 15 * esc)
  cara.BackgroundColor3 = Color3.fromRGB(216, 172, 116)
  cara.BorderSizePixel = 0
  cara.Parent = f
  Instance.new("UICorner", cara).CornerRadius = UDim.new(1, 0)
  local anilloIco = Instance.new("Frame")
  anilloIco.AnchorPoint = Vector2.new(0.5, 0.5)
  anilloIco.Position = UDim2.new(0.5, 0, 0.5, 0)
  anilloIco.Size = UDim2.new(0.45, 0, 0.45, 0)
  anilloIco.BackgroundColor3 = Color3.fromRGB(172, 122, 70)
  anilloIco.BorderSizePixel = 0
  anilloIco.Parent = cara
  Instance.new("UICorner", anilloIco).CornerRadius = UDim.new(1, 0)
  return f
end
local function iconoSaco(padre, x, y, esc)
  local f = Instance.new("Frame")
  f.Position = UDim2.new(0, x, 0, y)
  f.Size = UDim2.new(0, 30 * esc, 0, 32 * esc)
  f.BackgroundTransparency = 1
  f.Parent = padre
  local bolso = Instance.new("Frame")
  bolso.AnchorPoint = Vector2.new(0.5, 1)
  bolso.Position = UDim2.new(0.5, 0, 1, 0)
  bolso.Size = UDim2.new(0.92, 0, 0.78, 0)
  bolso.BackgroundColor3 = Color3.fromRGB(158, 120, 74)
  bolso.BorderSizePixel = 0
  bolso.Parent = f
  Instance.new("UICorner", bolso).CornerRadius = UDim.new(0.45, 0)
  local nudo = Instance.new("Frame")
  nudo.AnchorPoint = Vector2.new(0.5, 0)
  nudo.Position = UDim2.new(0.5, 0, 0, 0)
  nudo.Size = UDim2.new(0.5, 0, 0.26, 0)
  nudo.BackgroundColor3 = Color3.fromRGB(112, 82, 46)
  nudo.BorderSizePixel = 0
  nudo.Parent = f
  Instance.new("UICorner", nudo).CornerRadius = UDim.new(0.4, 0)
  return f
end
local function iconoDiamante(padre, x, y, esc)
  local f = Instance.new("Frame")
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0, x, 0, y)
  f.Size = UDim2.new(0, 22 * esc, 0, 22 * esc)
  f.Rotation = 45
  f.BackgroundColor3 = Color3.fromRGB(88, 214, 255)
  f.BorderSizePixel = 0
  f.Parent = padre
  Instance.new("UICorner", f).CornerRadius = UDim.new(0.18, 0)
  local brillo = Instance.new("Frame")
  brillo.Size = UDim2.new(0.45, 0, 0.45, 0)
  brillo.BackgroundColor3 = Color3.fromRGB(205, 244, 255)
  brillo.BackgroundTransparency = 0.25
  brillo.BorderSizePixel = 0
  brillo.Parent = f
  Instance.new("UICorner", brillo).CornerRadius = UDim.new(0.18, 0)
  return f
end

-- Panel como el de la referencia: oscuro y translucido, ocupa casi
-- toda la pantalla, con la X roja montada en la esquina
local calPanel = Instance.new("Frame")
calPanel.Name = "CalderoPanel"
calPanel.AnchorPoint = Vector2.new(0.5, 0.5)
calPanel.Position = UDim2.new(0.5, 0, 0.55, 0)
calPanel.Size = UDim2.new(0.82, 0, 0.8, 0)
calPanel.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
calPanel.BackgroundTransparency = 0.14
calPanel.BorderSizePixel = 0
calPanel.Visible = false
calPanel.ZIndex = 20
calPanel.Parent = gui
Instance.new("UICorner", calPanel).CornerRadius = UDim.new(0, 12)
local calBorde = Instance.new("UIStroke")
calBorde.Color = Color3.fromRGB(255, 255, 255)
calBorde.Transparency = 0.86
calBorde.Thickness = 1
calBorde.Parent = calPanel

local calCerrar = Instance.new("TextButton")
calCerrar.AnchorPoint = Vector2.new(1, 0)
calCerrar.Position = UDim2.new(1, 12, 0, -12)
calCerrar.Size = UDim2.new(0, 50, 0, 50)
calCerrar.BackgroundColor3 = Color3.fromRGB(224, 38, 38)
calCerrar.BorderSizePixel = 0
calCerrar.Font = Enum.Font.GothamBlack
calCerrar.Text = "X"
calCerrar.TextSize = 27
calCerrar.TextColor3 = Color3.new(1, 1, 1)
calCerrar.ZIndex = 23
calCerrar.Parent = calPanel
Instance.new("UICorner", calCerrar).CornerRadius = UDim.new(0, 9)
calCerrar.MouseButton1Click:Connect(function()
  calPanel.Visible = false
end)

-- Contadores arriba en el centro, como en la referencia (icono +
-- numero blanco en negrita): hongos guardados, tus lenos, diamantes
local cntHongo, cntLeno, cntDiam
local function contadorArriba(xOff, tipo)
  local num = etiqueta("0", 19, UDim2.new(0.5, xOff, 0, 15), UDim2.new(0, 56, 0, 26), Color3.new(1, 1, 1), calPanel)
  num.Font = Enum.Font.GothamBlack
  num.TextXAlignment = Enum.TextXAlignment.Left
  if tipo == "hongo" then
    iconoHongo(calPanel, 0, 0, 0.72).Position = UDim2.new(0.5, xOff - 30, 0, 14)
  elseif tipo == "leno" then
    iconoLeno(calPanel, 0, 0, 0.72).Position = UDim2.new(0.5, xOff - 32, 0, 17)
  else
    iconoDiamante(calPanel, 0, 0, 0.82).Position = UDim2.new(0.5, xOff - 16, 0, 27)
  end
  return num
end
cntHongo = contadorArriba(-118, "hongo")
cntLeno = contadorArriba(2, "leno")
cntDiam = contadorArriba(122, "diamante")

-- Titulo de seccion amarillo en cursiva, como el de la referencia
local function tituloSeccion(texto, y)
  local t = etiqueta("", 16, UDim2.new(0, 22, 0, y), UDim2.new(0.8, 0, 0, 24), Color3.fromRGB(255, 214, 92), calPanel)
  t.Font = Enum.Font.GothamBlack
  t.RichText = true
  t.Text = "<i>" .. texto .. "</i>"
  t.TextXAlignment = Enum.TextXAlignment.Left
  return t
end
tituloSeccion("RESERVA DEL CALDERO", 58)

-- Tarjetas como las de la referencia: rectangulo oscuro con borde
-- suave, icono arriba, nombre en blanco y numero grande debajo
local numReserva, numSaco, numMano, numLenos, numDiam
local function tarjeta(i, nombre, tipo, dorada, apagada)
  local card = Instance.new("Frame")
  card.Position = UDim2.new(0.018 + (i - 1) * 0.196, 0, 0, 92)
  card.Size = UDim2.new(0.178, 0, 0, 132)
  card.BackgroundColor3 = dorada and Color3.fromRGB(150, 118, 34) or Color3.fromRGB(22, 22, 30)
  card.BackgroundTransparency = apagada and 0.4 or 0.08
  card.BorderSizePixel = 0
  card.Parent = calPanel
  Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
  local borde = Instance.new("UIStroke")
  borde.Color = Color3.fromRGB(255, 255, 255)
  borde.Transparency = 0.84
  borde.Thickness = 1
  borde.Parent = card
  if tipo == "hongo" then
    iconoHongo(card, 0, 0, 1).Position = UDim2.new(0.5, -18, 0, 12)
  elseif tipo == "leno" then
    iconoLeno(card, 0, 0, 1).Position = UDim2.new(0.5, -19, 0, 18)
  elseif tipo == "saco" then
    iconoSaco(card, 0, 0, 1).Position = UDim2.new(0.5, -15, 0, 12)
  else
    iconoDiamante(card, 0, 0, 1).Position = UDim2.new(0.5, 0, 0, 34)
  end
  local nom = etiqueta(nombre, 12, UDim2.new(0, 4, 0, 62), UDim2.new(1, -8, 0, 30), apagada and Color3.fromRGB(165, 165, 178) or Color3.new(1, 1, 1), card)
  nom.TextWrapped = true
  nom.TextXAlignment = Enum.TextXAlignment.Center
  local num = etiqueta("0", 25, UDim2.new(0, 4, 0, 94), UDim2.new(1, -8, 0, 32), dorada and Color3.fromRGB(255, 240, 200) or Color3.new(1, 1, 1), card)
  num.Font = Enum.Font.GothamBlack
  num.TextXAlignment = Enum.TextXAlignment.Center
  return num
end
numReserva = tarjeta(1, "Hongos guardados", "hongo", true, false)
numSaco = tarjeta(2, "En el saco", "saco", false, false)
numMano = tarjeta(3, "En tu mano", "hongo", false, false)
numLenos = tarjeta(4, "Tus leños", "leno", false, false)
numDiam = tarjeta(5, "Diamantes", "diamante", false, true)

tituloSeccion("COMO SE GUARDA", 248)
local calPista = etiqueta("Toca SOLTAR junto al caldero para echar los hongos que llevas en la mano y en el saco. Quedan guardados aqui, para tu equipo.", 13, UDim2.new(0, 22, 0, 278), UDim2.new(0.94, 0, 0, 44), Color3.fromRGB(216, 208, 198), calPanel)
calPista.TextWrapped = true
calPista.TextXAlignment = Enum.TextXAlignment.Left
calPista.VerticalAlignment = Enum.TextYAlignment.Top

for _, g in ipairs(calPanel:GetDescendants()) do
  if g:IsA("GuiObject") then
    g.ZIndex = 21
  end
end
calCerrar.ZIndex = 23

local function abrirCaldero()
  calPanel.Visible = true
  RE_ACC:FireServer("VerCaldero")
end
local function enganchaPrompt(pr)
  pr.Triggered:Connect(function(pl)
    if pl == player then
      abrirCaldero()
    end
  end)
end
for _, d in ipairs(workspace:GetDescendants()) do
  if d:IsA("ProximityPrompt") and d.Name == "CalderoPrompt" then
    enganchaPrompt(d)
  end
end
workspace.DescendantAdded:Connect(function(d)
  if d:IsA("ProximityPrompt") and d.Name == "CalderoPrompt" then
    enganchaPrompt(d)
  end
end)

-- Los numeros se enteran por el mismo aviso del servidor
RE_UI.OnClientEvent:Connect(function(st)
  if type(st) ~= "table" then
    return
  end
  cntHongo.Text = tostring(st.calderoHongos or 0)
  cntLeno.Text = tostring(st.lenos or 0)
  numReserva.Text = tostring(st.calderoHongos or 0)
  numSaco.Text = tostring(st.hongosSaco or 0)
  numMano.Text = (st.manoTipo == "Hongo") and "1" or "0"
  numLenos.Text = tostring(st.lenos or 0)
end)

-- FIN LOCAL CALDERO
