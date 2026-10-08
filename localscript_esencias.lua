-- LocalScript de las ESENCIAS (pegar en StarterPlayer > StarterPlayerScripts)
-- Contador de la moneda del juego abajo a la izquierda, como los diamantes
-- de la referencia pero con un CRISTAL DE HECHIZO morado disenado con
-- piezas de interfaz (sin imagenes ni assets). El saldo lo manda el
-- servidor (NUCLEO) y se guarda solo; ganar noches en el bosque lo sube.
-- NO toca el LocalScript principal ni el del bosque.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RE = RS:WaitForChild("AvadaEsenciasUI")

local gui = Instance.new("ScreenGui")
gui.Name = "EsenciasHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- pastilla oscura abajo a la izquierda, como la de los diamantes
local pill = Instance.new("Frame")
pill.Name = "Pastilla"
pill.AnchorPoint = Vector2.new(0, 1)
pill.Position = UDim2.new(0, 14, 1, -16)
pill.Size = UDim2.new(0, 132, 0, 44)
pill.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
pill.BackgroundTransparency = 0.28
pill.BorderSizePixel = 0
pill.Parent = gui
Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 22)
local borde = Instance.new("UIStroke")
borde.Color = Color3.fromRGB(150, 92, 246)
borde.Transparency = 0.55
borde.Thickness = 1.2
borde.Parent = pill

-- el cristal de hechizo: rombo morado con brillo y estrella de 4 puntas
local icono = Instance.new("Frame")
icono.Name = "Cristal"
icono.AnchorPoint = Vector2.new(0, 0.5)
icono.Position = UDim2.new(0, 10, 0.5, 0)
icono.Size = UDim2.new(0, 30, 0, 30)
icono.BackgroundTransparency = 1
icono.Parent = pill

local function rombo(tam, color)
  local f = Instance.new("Frame")
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0.5, 0, 0.5, 0)
  f.Size = UDim2.new(0, tam, 0, tam)
  f.Rotation = 45
  f.BackgroundColor3 = color
  f.BorderSizePixel = 0
  f.Parent = icono
  Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
  return f
end
rombo(21, Color3.fromRGB(126, 58, 242))
rombo(12, Color3.fromRGB(196, 150, 255))

local estrellaV = Instance.new("Frame")
estrellaV.AnchorPoint = Vector2.new(0.5, 0.5)
estrellaV.Position = UDim2.new(0.5, 0, 0.5, 0)
estrellaV.Size = UDim2.new(0, 2, 0, 15)
estrellaV.BackgroundColor3 = Color3.new(1, 1, 1)
estrellaV.BackgroundTransparency = 0.25
estrellaV.BorderSizePixel = 0
estrellaV.Parent = icono
local estrellaH = Instance.new("Frame")
estrellaH.AnchorPoint = Vector2.new(0.5, 0.5)
estrellaH.Position = UDim2.new(0.5, 0, 0.5, 0)
estrellaH.Size = UDim2.new(0, 15, 0, 2)
estrellaH.BackgroundColor3 = Color3.new(1, 1, 1)
estrellaH.BackgroundTransparency = 0.25
estrellaH.BorderSizePixel = 0
estrellaH.Parent = icono

-- numero y nombre de la moneda
local numero = Instance.new("TextLabel")
numero.BackgroundTransparency = 1
numero.Position = UDim2.new(0, 46, 0, 5)
numero.Size = UDim2.new(0, 56, 0, 22)
numero.Font = Enum.Font.GothamBlack
numero.Text = "0"
numero.TextSize = 20
numero.TextColor3 = Color3.new(1, 1, 1)
numero.TextXAlignment = Enum.TextXAlignment.Left
numero.Parent = pill
local nombre = Instance.new("TextLabel")
nombre.BackgroundTransparency = 1
nombre.Position = UDim2.new(0, 47, 0, 27)
nombre.Size = UDim2.new(0, 56, 0, 12)
nombre.Font = Enum.Font.GothamBold
nombre.Text = "ESENCIAS"
nombre.TextSize = 8
nombre.TextColor3 = Color3.fromRGB(196, 150, 255)
nombre.TextXAlignment = Enum.TextXAlignment.Left
nombre.Parent = pill

-- boton "+" verde (hoy solo late; servira para abrir la tienda)
local mas = Instance.new("TextButton")
mas.AnchorPoint = Vector2.new(1, 0.5)
mas.Position = UDim2.new(1, -6, 0.5, 0)
mas.Size = UDim2.new(0, 24, 0, 24)
mas.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
mas.BorderSizePixel = 0
mas.Font = Enum.Font.GothamBlack
mas.Text = "+"
mas.TextSize = 16
mas.TextColor3 = Color3.new(1, 1, 1)
mas.Parent = pill
Instance.new("UICorner", mas).CornerRadius = UDim.new(1, 0)

local saldo = 0
local function palpita()
  local crece = TweenService:Create(icono, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 37, 0, 37) })
  local vuelve = TweenService:Create(icono, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 30, 0, 30) })
  crece:Play()
  crece.Completed:Connect(function()
    vuelve:Play()
  end)
end
mas.MouseButton1Click:Connect(palpita)

RE.OnClientEvent:Connect(function(n)
  if type(n) ~= "number" then
    return
  end
  local subio = n > saldo
  saldo = n
  numero.Text = tostring(n)
  if subio then
    palpita()
  end
end)

-- pedir el saldo al entrar (el servidor responde solo)
task.delay(1, function()
  RE:FireServer()
end)

-- FIN LOCAL ESENCIAS
