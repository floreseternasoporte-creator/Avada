-- LocalScript de los DIAMANTES (pegar en StarterPlayer > StarterPlayerScripts)
-- Contador de la moneda del juego abajo a la izquierda: un DIAMANTE de
-- hielo disenado con piezas de interfaz (sin imagenes ni assets).
-- (Antes la moneda se llamaba ESENCIAS; el dueno pidio en 2026-11-03
-- que sean los diamantes.) El saldo lo manda el servidor (NUCLEO) y se
-- guarda solo; sobrevivir noches en el bosque lo sube.
-- NO toca el LocalScript principal ni el del bosque.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RE = RS:WaitForChild("AvadaDiamantesUI")

local gui = Instance.new("ScreenGui")
gui.Name = "DiamantesHUD"
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
borde.Color = Color3.fromRGB(125, 211, 252)
borde.Transparency = 0.55
borde.Thickness = 1.2
borde.Parent = pill

-- EL DIAMANTE de verdad (v2, queja del dueño: «no cambiaste el icono»):
-- forma de GEMA clásica construida con piezas: tabla ancha arriba con
-- sus dos facetas laterales, pabellón en punta abajo y brillo. Ya no
-- es un rombo girado como el cristal de las viejas Esencias.
local icono = Instance.new("Frame")
icono.Name = "DiamanteIcono"
icono.AnchorPoint = Vector2.new(0, 0.5)
icono.Position = UDim2.new(0, 8, 0.5, 0)
icono.Size = UDim2.new(0, 34, 0, 30)
icono.BackgroundTransparency = 1
icono.Parent = pill

local function pieza(x, y, w, h, rot, color, transp, z)
  local f = Instance.new("Frame")
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0, x, 0, y)
  f.Size = UDim2.new(0, w, 0, h)
  f.Rotation = rot or 0
  f.BackgroundColor3 = color
  f.BackgroundTransparency = transp or 0
  f.BorderSizePixel = 0
  f.ZIndex = z or 1
  f.Parent = icono
  return f
end
local AZUL = Color3.fromRGB(56, 169, 235)
local HIELO = Color3.fromRGB(186, 236, 255)
local CIELO = Color3.fromRGB(125, 211, 252)
-- pabellón: la punta (cuadrado girado; la mitad alta la tapa la tabla)
pieza(17, 19, 19, 19, 45, AZUL, 0, 1)
pieza(17, 21, 11, 11, 45, CIELO, 0, 2)
-- facetas laterales de la corona (inclinadas hacia fuera)
pieza(5, 7, 10, 10, 45, CIELO, 0, 2)
pieza(29, 7, 10, 10, 45, CIELO, 0, 2)
-- tabla: la cara ancha de arriba
local tabla = pieza(17, 7, 27, 10, 0, HIELO, 0, 3)
Instance.new("UICorner", tabla).CornerRadius = UDim.new(0, 3)
-- brillo diagonal sobre la punta
pieza(13, 20, 3, 12, 32, Color3.new(1, 1, 1), 0.45, 4)

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
nombre.Text = "DIAMANTES"
nombre.TextSize = 8
nombre.TextColor3 = Color3.fromRGB(165, 225, 255)
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
  local crece = TweenService:Create(icono, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 41, 0, 36) })
  local vuelve = TweenService:Create(icono, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 34, 0, 30) })
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

-- FIN LOCAL DIAMANTES
