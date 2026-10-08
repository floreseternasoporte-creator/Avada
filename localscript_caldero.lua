-- LocalScript del CALDERO (pegar en StarterPlayer > StarterPlayerScripts)
-- El panel de la reserva como el menu de la referencia (panel oscuro,
-- contadores arriba, tarjetas con numero, titulos amarillos, X roja) y
-- el aviso "Ver". Corto a proposito: en este Studio los pegados
-- largos se cortan y el script muere sin decir nada.

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
  l.Text, l.TextSize, l.TextColor3 = texto, size, color or Color3.new(1, 1, 1)
  l.Position, l.Size, l.Parent = pos, tam, padre
  local st = Instance.new("UIStroke")
  st.Color, st.Thickness, st.Parent = Color3.new(0, 0, 0), 1.6, l
  return l
end
local function caja(padre, pos, tam, color, transp, radio)
  local f = Instance.new("Frame")
  f.Position, f.Size = pos, tam
  f.BackgroundColor3, f.BackgroundTransparency = color, transp or 0
  f.BorderSizePixel, f.Parent = 0, padre
  Instance.new("UICorner", f).CornerRadius = UDim.new(radio or 0.3, 0)
  return f
end
local function icono(padre, cx, cy, esc, tipo)
  if tipo == "hongo" then
    caja(padre, UDim2.new(0, cx - 6 * esc, 0, cy + 2 * esc), UDim2.new(0, 13 * esc, 0, 15 * esc), Color3.fromRGB(238, 218, 178), 0, 0.35)
    caja(padre, UDim2.new(0, cx - 17 * esc, 0, cy - 12 * esc), UDim2.new(0, 34 * esc, 0, 17 * esc), Color3.fromRGB(154, 84, 52), 0, 0.55)
  elseif tipo == "leno" then
    caja(padre, UDim2.new(0, cx - 18 * esc, 0, cy - 7 * esc), UDim2.new(0, 36 * esc, 0, 16 * esc), Color3.fromRGB(122, 79, 43), 0, 0.4)
    caja(padre, UDim2.new(0, cx - 16 * esc, 0, cy - 5 * esc), UDim2.new(0, 12 * esc, 0, 12 * esc), Color3.fromRGB(216, 172, 116), 0, 1)
  elseif tipo == "saco" then
    caja(padre, UDim2.new(0, cx - 13 * esc, 0, cy - 4 * esc), UDim2.new(0, 26 * esc, 0, 22 * esc), Color3.fromRGB(158, 120, 74), 0, 0.45)
    caja(padre, UDim2.new(0, cx - 7 * esc, 0, cy - 13 * esc), UDim2.new(0, 14 * esc, 0, 9 * esc), Color3.fromRGB(112, 82, 46), 0, 0.4)
  else
    local d = caja(padre, UDim2.new(0, cx - 10 * esc, 0, cy - 10 * esc), UDim2.new(0, 20 * esc, 0, 20 * esc), Color3.fromRGB(88, 214, 255), 0, 0.18)
    d.Rotation = 45
  end
end

local calPanel = Instance.new("Frame")
calPanel.Name = "CalderoPanel"
calPanel.AnchorPoint = Vector2.new(0.5, 0.5)
calPanel.Position = UDim2.new(0.5, 0, 0.55, 0)
calPanel.Size = UDim2.new(0.82, 0, 0.8, 0)
calPanel.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
calPanel.BackgroundTransparency = 0.14
calPanel.BorderSizePixel, calPanel.Visible = 0, false
calPanel.Parent = gui
Instance.new("UICorner", calPanel).CornerRadius = UDim.new(0, 12)
local cb = Instance.new("UIStroke")
cb.Color, cb.Transparency, cb.Thickness, cb.Parent = Color3.fromRGB(255, 255, 255), 0.86, 1, calPanel

local calCerrar = Instance.new("TextButton")
calCerrar.AnchorPoint = Vector2.new(1, 0)
calCerrar.Position = UDim2.new(1, 12, 0, -12)
calCerrar.Size = UDim2.new(0, 50, 0, 50)
calCerrar.BackgroundColor3 = Color3.fromRGB(224, 38, 38)
calCerrar.BorderSizePixel, calCerrar.Font = 0, Enum.Font.GothamBlack
calCerrar.Text, calCerrar.TextSize, calCerrar.TextColor3 = "X", 27, Color3.new(1, 1, 1)
calCerrar.Parent = calPanel
Instance.new("UICorner", calCerrar).CornerRadius = UDim.new(0, 9)
calCerrar.MouseButton1Click:Connect(function() calPanel.Visible = false end)

local numsArriba = {}
for i, def in ipairs({ { "hongo", -148 }, { "leno", -28 }, { "diam", 92 } }) do
  icono(calPanel, def[2] + 10, 28, 0.66, def[1])
  local n = etiqueta("0", 19, UDim2.new(0.5, def[2] + 24, 0, 15), UDim2.new(0, 56, 0, 26), Color3.new(1, 1, 1), calPanel)
  n.Font = Enum.Font.GothamBlack
  n.TextXAlignment = Enum.TextXAlignment.Left
  numsArriba[def[1]] = n
end

local function titulo(texto, y)
  local t = etiqueta("", 16, UDim2.new(0, 22, 0, y), UDim2.new(0.8, 0, 0, 24), Color3.fromRGB(255, 214, 92), calPanel)
  t.Font, t.RichText = Enum.Font.GothamBlack, true
  t.Text = "<i>" .. texto .. "</i>"
  t.TextXAlignment = Enum.TextXAlignment.Left
end
titulo("RESERVA DEL CALDERO", 58)

local numsTarjeta = {}
local defs = {
  { "Hongos guardados", "hongo", "reserva", true, false },
  { "En el saco", "saco", "saco", false, false },
  { "En tu mano", "hongo", "mano", false, false },
  { "Tus leños", "leno", "lenos", false, false },
  { "Diamantes", "diam", "diam", false, true },
}
for i, d in ipairs(defs) do
  local card = caja(calPanel, UDim2.new(0.018 + (i - 1) * 0.196, 0, 0, 92), UDim2.new(0.178, 0, 0, 132), d[4] and Color3.fromRGB(150, 118, 34) or Color3.fromRGB(22, 22, 30), d[5] and 0.4 or 0.08, 0.08)
  local bd = Instance.new("UIStroke")
  bd.Color, bd.Transparency, bd.Thickness, bd.Parent = Color3.fromRGB(255, 255, 255), 0.84, 1, card
  local zona = Instance.new("Frame")
  zona.AnchorPoint = Vector2.new(0.5, 0)
  zona.Position = UDim2.new(0.5, 0, 0, 6)
  zona.Size = UDim2.new(0, 44, 0, 48)
  zona.BackgroundTransparency, zona.BorderSizePixel, zona.Parent = 1, 0, card
  icono(zona, 22, 24, 0.9, d[2])
  local nom = etiqueta(d[1], 12, UDim2.new(0, 4, 0, 62), UDim2.new(1, -8, 0, 30), d[5] and Color3.fromRGB(165, 165, 178) or Color3.new(1, 1, 1), card)
  nom.TextWrapped, nom.TextXAlignment = true, Enum.TextXAlignment.Center
  local num = etiqueta("0", 25, UDim2.new(0, 4, 0, 94), UDim2.new(1, -8, 0, 32), d[4] and Color3.fromRGB(255, 240, 200) or Color3.new(1, 1, 1), card)
  num.Font, num.TextXAlignment = Enum.Font.GothamBlack, Enum.TextXAlignment.Center
  numsTarjeta[d[3]] = num
end

titulo("COMO SE GUARDA", 248)
local pista = etiqueta("Toca SOLTAR junto al caldero para echar los hongos que llevas en la mano y en el saco. Quedan guardados aqui, para tu equipo.", 13, UDim2.new(0, 22, 0, 278), UDim2.new(0.94, 0, 0, 44), Color3.fromRGB(216, 208, 198), calPanel)
pista.TextWrapped = true
pista.TextXAlignment = Enum.TextXAlignment.Left
pista.VerticalAlignment = Enum.TextYAlignment.Top

local function abrirCaldero()
  calPanel.Visible = true
  RE_ACC:FireServer("VerCaldero")
end
local enganchados = {}
local function enganchaPrompt(pr)
  if enganchados[pr] then return end
  enganchados[pr] = true
  pr.Triggered:Connect(function(pl)
    if pl == player then abrirCaldero() end
  end)
end
local function escaneaCalderos()
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("ProximityPrompt") and d.Name == "CalderoPrompt" then enganchaPrompt(d) end
  end
end
escaneaCalderos()
workspace.DescendantAdded:Connect(function(d)
  if d:IsA("ProximityPrompt") and d.Name == "CalderoPrompt" then enganchaPrompt(d) end
end)
task.spawn(function()
  while true do
    task.wait(2)
    escaneaCalderos()
  end
end)

RE_UI.OnClientEvent:Connect(function(st)
  if type(st) ~= "table" then return end
  numsArriba.hongo.Text = tostring(st.calderoHongos or 0)
  numsArriba.leno.Text = tostring(st.lenos or 0)
  numsTarjeta.reserva.Text = tostring(st.calderoHongos or 0)
  numsTarjeta.saco.Text = tostring(st.hongosSaco or 0)
  numsTarjeta.mano.Text = (st.manoTipo == "Hongo") and "1" or "0"
  numsTarjeta.lenos.Text = tostring(st.lenos or 0)
end)

-- FIN LOCAL CALDERO
