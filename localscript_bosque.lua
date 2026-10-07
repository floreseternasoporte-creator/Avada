-- LocalScript del Bosque Prohibido (pegar en StarterPlayer > StarterPlayerScripts)
-- Interfaz como en 99 Noches: barra de hambre naranja a la izquierda, botones
-- circulares a la derecha (Comer, Desgarrar, Tienda/Desalmacenar, CORRER),
-- contador grande del saco y la noche arriba. NO toca el LocalScript principal.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local RE_UI = RS:WaitForChild("AvadaBosqueUI")
local RE_ACC = RS:WaitForChild("AvadaBosqueAccion")

pcall(function()
  StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BosqueHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local raiz = Instance.new("Frame")
raiz.Name = "Raiz"
raiz.Size = UDim2.new(1, 0, 1, 0)
raiz.BackgroundTransparency = 1
raiz.Visible = false
raiz.Parent = gui

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

-- Noche arriba en el centro (como el "Dia 1" de referencia)
local diaLbl = etiqueta("Día", 17, UDim2.new(0.5, -80, 0, 8), UDim2.new(160, 24), Color3.new(1, 1, 1), raiz)
diaLbl.AnchorPoint = Vector2.new(0, 0)

-- Barra de hambre: naranja, a la izquierda
etiqueta("HAMBRE", 10, UDim2.new(0, 16, 0.40, -18), UDim2.new(120, 14), Color3.new(1, 1, 1), raiz)
local barraFondo = Instance.new("Frame")
barraFondo.AnchorPoint = Vector2.new(0, 0.5)
barraFondo.Position = UDim2.new(0, 14, 0.42, 0)
barraFondo.Size = UDim2.new(0, 190, 0, 17)
barraFondo.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
barraFondo.BackgroundTransparency = 0.3
barraFondo.Parent = raiz
Instance.new("UICorner", barraFondo).CornerRadius = UDim.new(0, 6)
local relleno = Instance.new("Frame")
relleno.Size = UDim2.new(1, 0, 1, 0)
relleno.BackgroundColor3 = Color3.fromRGB(240, 127, 26)
relleno.BorderSizePixel = 0
relleno.Parent = barraFondo
Instance.new("UICorner", relleno).CornerRadius = UDim.new(0, 6)

-- Contador grande del saco (X/5), como en la referencia
local contador = etiqueta("0/5", 36, UDim2.new(0.60, -70, 0.40, 0), UDim2.new(140, 52), Color3.new(1, 1, 1), raiz)
contador.Font = Enum.Font.GothamBlack
contador.Visible = false

-- Botones circulares pegados a la esquina, alrededor del boton de salto
-- (como en 99 Noches: Comer arriba-izquierda, CORRER arriba-derecha,
-- Desgarrar a la izquierda del salto y Tienda encima)
local function boton(texto, textSize)
  local b = Instance.new("TextButton")
  b.AnchorPoint = Vector2.new(0.5, 0.5)
  b.Size = UDim2.new(0, 56, 0, 56)
  b.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
  b.BackgroundTransparency = 0.32
  b.BorderSizePixel = 0
  b.Font = Enum.Font.GothamBold
  b.Text = texto
  b.TextSize = textSize or 14
  b.TextColor3 = Color3.new(1, 1, 1)
  b.AutoButtonColor = true
  b.Parent = raiz
  Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
  local st = Instance.new("UIStroke")
  st.Color = Color3.fromRGB(0, 0, 0)
  st.Transparency = 0.45
  st.Thickness = 1.4
  st.Parent = b
  return b
end

local correrBtn = boton("CORRER", 10)
correrBtn.Position = UDim2.new(1, -60, 1, -186) -- arriba-derecha del salto
local tiendaBtn = boton("Tienda", 10)
tiendaBtn.Position = UDim2.new(1, -128, 1, -244) -- encima de Comer
local desgarrarBtn = boton("Desgarrar", 8)
desgarrarBtn.Position = UDim2.new(1, -146, 1, -104) -- a la izquierda del salto
local comerBtn = boton("Comer", 12)
comerBtn.Position = UDim2.new(1, -136, 1, -176) -- arriba-izquierda del salto

-- Correr / caminar (alternando, como pidio el dueno del juego)
local sprint = false
local function aplicarVelocidad()
  local char = player.Character
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  if hum then
    hum.WalkSpeed = sprint and 25 or 16
  end
  correrBtn.Text = sprint and "CAMINAR" or "CORRER"
  correrBtn.TextColor3 = sprint and Color3.fromRGB(255, 140, 26) or Color3.new(1, 1, 1)
end
correrBtn.MouseButton1Click:Connect(function()
  sprint = not sprint
  aplicarVelocidad()
end)
player.CharacterAdded:Connect(function()
  task.wait(0.3)
  aplicarVelocidad()
end)

local accionComer = "Comer"
comerBtn.MouseButton1Click:Connect(function()
  RE_ACC:FireServer(accionComer)
end)
desgarrarBtn.MouseButton1Click:Connect(function()
  RE_ACC:FireServer("Desgarrar")
end)
tiendaBtn.MouseButton1Click:Connect(function()
  RE_ACC:FireServer("Tienda")
end)

-- Estado que manda el servidor
local ultimoEstado = nil
local sacoEnManoLocal = false
local function revisaContador()
  if not ultimoEstado then
    return
  end
  contador.Visible = ultimoEstado.sacoEnMano == true or sacoEnManoLocal
  contador.Text = tostring(ultimoEstado.saco or 0) .. "/" .. tostring(ultimoEstado.sacoMax or 5)
end
local function vigilaSaco(char)
  if not char then
    return
  end
  local function mira()
    sacoEnManoLocal = false
    for _, c in ipairs(char:GetChildren()) do
      if c:IsA("Tool") and c.Name == "Saco mágico" then
        sacoEnManoLocal = true
      end
    end
    revisaContador()
  end
  char.ChildAdded:Connect(mira)
  char.ChildRemoved:Connect(mira)
  mira()
end
player.CharacterAdded:Connect(vigilaSaco)
if player.Character then
  vigilaSaco(player.Character)
end

RE_UI.OnClientEvent:Connect(function(st)
  if type(st) ~= "table" then
    return
  end
  raiz.Visible = st.enPartida == true
  if not raiz.Visible then
    return
  end
  relleno.Size = UDim2.new(math.clamp((st.hambre or 100) / 100, 0, 1), 0, 1, 0)
  diaLbl.Text = (st.fase == "noche") and ("Noche " .. tostring(st.noche or 1) .. " de 7") or "Día"
  ultimoEstado = st
  if st.mano == true then
    accionComer = "Comer"
    comerBtn.Text = "Comer"
    comerBtn.TextSize = 12
    comerBtn.Visible = true
  elseif st.sacoEnMano == true and (st.saco or 0) > 0 then
    accionComer = "Desalmacenar"
    comerBtn.Text = "Desalmacenar"
    comerBtn.TextSize = 8
    comerBtn.Visible = true
  elseif (st.saco or 0) > 0 then
    accionComer = "Comer"
    comerBtn.Text = "Comer"
    comerBtn.TextSize = 15
    comerBtn.Visible = true
  else
    comerBtn.Visible = false
  end
  desgarrarBtn.Visible = st.mano == true
  tiendaBtn.Visible = st.mano == true
  revisaContador()
end)

-- FIN LOCAL BOSQUE
