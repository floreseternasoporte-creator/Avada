-- LocalScript del CALDERO (pegar en StarterPlayer > StarterPlayerScripts)
-- El panel de la reserva (estilo 99 Noches), el prompt "Ver" y la
-- animacion del liquido. Vive aparte del HUD para que ningun fallo
-- aqui pueda tocar la interfaz de la partida.

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

local calNum, calNumTop

-- Caldero de la base: prompt "Ver" y panel de reserva estilo 99
-- Noches (panel oscuro translucido, contadores arriba, X roja). Por
-- ahora guarda solo hongos; los diamantes llegaran con los arboles.
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

local calPanel = Instance.new("Frame")
calPanel.Name = "CalderoPanel"
calPanel.AnchorPoint = Vector2.new(0.5, 0.5)
calPanel.Position = UDim2.new(0.5, 0, 0.52, 0)
calPanel.Size = UDim2.new(0.74, 0, 0.64, 0)
calPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
calPanel.BackgroundTransparency = 0.18
calPanel.BorderSizePixel = 0
calPanel.Visible = false
calPanel.ZIndex = 20
calPanel.Parent = gui
Instance.new("UICorner", calPanel).CornerRadius = UDim.new(0, 14)
local calBorde = Instance.new("UIStroke")
calBorde.Color = Color3.fromRGB(0, 0, 0)
calBorde.Transparency = 0.25
calBorde.Thickness = 2
calBorde.Parent = calPanel

etiqueta("CALDERO", 28, UDim2.new(0, 24, 0, 16), UDim2.new(0, 260, 0, 36), Color3.fromRGB(255, 214, 92), calPanel).Font = Enum.Font.GothamBlack
local calCerrar = Instance.new("TextButton")
calCerrar.AnchorPoint = Vector2.new(1, 0)
calCerrar.Position = UDim2.new(1, -14, 0, 14)
calCerrar.Size = UDim2.new(0, 48, 0, 48)
calCerrar.BackgroundColor3 = Color3.fromRGB(218, 42, 42)
calCerrar.BorderSizePixel = 0
calCerrar.Font = Enum.Font.GothamBlack
calCerrar.Text = "X"
calCerrar.TextSize = 26
calCerrar.TextColor3 = Color3.new(1, 1, 1)
calCerrar.ZIndex = 22
calCerrar.Parent = calPanel
Instance.new("UICorner", calCerrar).CornerRadius = UDim.new(0, 9)
calCerrar.MouseButton1Click:Connect(function()
  calPanel.Visible = false
end)

iconoHongo(calPanel, 24, 68, 1)
calNumTop = etiqueta("0", 30, UDim2.new(0, 70, 0, 66), UDim2.new(0, 100, 0, 36), Color3.new(1, 1, 1), calPanel)
calNumTop.Font = Enum.Font.GothamBlack
calNumTop.TextXAlignment = Enum.TextXAlignment.Left
etiqueta("HONGOS", 11, UDim2.new(0, 72, 0, 100), UDim2.new(0, 100, 0, 16), Color3.fromRGB(210, 190, 170), calPanel).TextXAlignment = Enum.TextXAlignment.Left

local calTitulo = etiqueta("RESERVA DEL CALDERO", 15, UDim2.new(0, 24, 0, 128), UDim2.new(0, 360, 0, 22), Color3.fromRGB(255, 214, 92), calPanel)
calTitulo.Font = Enum.Font.GothamBlack
calTitulo.TextXAlignment = Enum.TextXAlignment.Left

local calCard = Instance.new("Frame")
calCard.AnchorPoint = Vector2.new(0.5, 0)
calCard.Position = UDim2.new(0.5, 0, 0, 160)
calCard.Size = UDim2.new(0, 250, 0, 210)
calCard.BackgroundColor3 = Color3.fromRGB(28, 25, 34)
calCard.BackgroundTransparency = 0.12
calCard.BorderSizePixel = 0
calCard.ZIndex = 21
calCard.Parent = calPanel
Instance.new("UICorner", calCard).CornerRadius = UDim.new(0, 12)
local calCardBorde = Instance.new("UIStroke")
calCardBorde.Color = Color3.fromRGB(0, 0, 0)
calCardBorde.Transparency = 0.45
calCardBorde.Thickness = 1.5
calCardBorde.Parent = calCard
iconoHongo(calCard, 91, 22, 1.9)
etiqueta("Hongos guardados", 16, UDim2.new(0, 20, 0, 104), UDim2.new(0, 210, 0, 24), Color3.new(1, 1, 1), calCard).TextXAlignment = Enum.TextXAlignment.Center
calNum = etiqueta("0", 42, UDim2.new(0, 20, 0, 132), UDim2.new(0, 210, 0, 48), Color3.fromRGB(255, 230, 170), calCard)
calNum.Font = Enum.Font.GothamBlack
calNum.TextXAlignment = Enum.TextXAlignment.Center
local calPista = etiqueta("Toca SOLTAR junto al caldero para echar los hongos que llevas.", 12, UDim2.new(0, 24, 1, -48), UDim2.new(1, -48, 0, 36), Color3.fromRGB(215, 205, 195), calPanel)
calPista.TextWrapped = true
calPista.TextXAlignment = Enum.TextXAlignment.Center

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
local function enganchaCaldero(modeloCal)
  local ancla = modeloCal:WaitForChild("CalderoAncla", 20)
  local prompt = ancla and ancla:WaitForChild("CalderoPrompt", 20)
  if prompt then
    prompt.Triggered:Connect(function(pl)
      if pl == player then
        abrirCaldero()
      end
    end)
  end
end
for _, mCal in ipairs(workspace:GetChildren()) do
  if mCal.Name == "Cauldron" then
    task.spawn(enganchaCaldero, mCal)
  end
end
workspace.ChildAdded:Connect(function(mCal)
  if mCal.Name == "Cauldron" then
    enganchaCaldero(mCal)
  end
end)

-- Animacion del caldero (la del dueno): liquido que cambia de color,
-- objetos flotando y burbujas que suben, todo en el cliente.
local ColeccionCal = game:GetService("CollectionService")
local RunCal = game:GetService("RunService")
local calItems = {}
local function registraCaldero(p)
  if not p:IsA("BasePart") then
    return
  end
  local base = p.CFrame -- la base es donde esta la pieza (vale tambien en mundos clonados)
  if not base then
    return
  end
  calItems[p] = {
    kind = p:GetAttribute("Kind"),
    base = base,
    size = p.Size,
    escala = p:GetAttribute("Scale") or 1,
    fase = p:GetAttribute("Phase") or 0,
    velocidad = p:GetAttribute("Speed") or 1,
    amplitud = p:GetAttribute("Amp") or 0.3,
    giro = p:GetAttribute("Spin") or 0,
    altura = p:GetAttribute("Height") or 10,
    colA = p:GetAttribute("ColorA"),
    colB = p:GetAttribute("ColorB"),
  }
end
for _, p in ipairs(ColeccionCal:GetTagged("CauldronAnim")) do
  registraCaldero(p)
end
ColeccionCal:GetInstanceAddedSignal("CauldronAnim"):Connect(function(p)
  task.defer(registraCaldero, p)
end)
ColeccionCal:GetInstanceRemovedSignal("CauldronAnim"):Connect(function(p)
  calItems[p] = nil
end)
RunCal.RenderStepped:Connect(function()
  local t = os.clock()
  for p, dd in pairs(calItems) do
    if not p.Parent then
      calItems[p] = nil
    else
      local kind = dd.kind
      if kind == "Liquid" then
        local a = (math.sin(t * 0.5) + 1) / 2
        if dd.colA and dd.colB then
          p.Color = dd.colA:Lerp(dd.colB, a)
        end
      elseif kind == "Overlay" then
        p.CFrame = dd.base + Vector3.new(math.cos(t * 0.35) * 3.2 * dd.escala, math.sin(t * 1.3) * 0.04 * dd.escala, math.sin(t * 0.5) * 3.2 * dd.escala)
        p.Transparency = 0.5 + math.sin(t * 0.8) * 0.12
      elseif kind == "Float" then
        local w = t * dd.velocidad + dd.fase
        local pos = dd.base.Position + Vector3.new(0, math.sin(w) * dd.amplitud, 0)
        p.CFrame = CFrame.new(pos) * CFrame.Angles(math.sin(w * 0.7) * 0.12, t * dd.giro + dd.fase, math.cos(w * 0.9) * 0.12)
      elseif kind == "Rise" then
        local u = (t * dd.velocidad + dd.fase) % 1
        local pos = dd.base.Position + Vector3.new(math.sin(u * math.pi * 4 + dd.fase * 6) * 0.9 * dd.escala, u * dd.altura, math.cos(u * math.pi * 3 + dd.fase * 6) * 0.9 * dd.escala)
        p.CFrame = CFrame.new(pos) * CFrame.Angles(t * dd.giro * 0.6, t * dd.giro, t * dd.giro * 0.4)
        p.Size = dd.size * (1 - 0.45 * u)
        local fadeIn = (u < 0.08) and (1 - u / 0.08) or 0
        local fadeOut = (u > 0.65) and ((u - 0.65) / 0.35) or 0
        p.Transparency = math.clamp(math.max(fadeIn, fadeOut), 0, 1)
      end
    end
  end
end)

-- El contador se entera por el mismo aviso del servidor
RE_UI.OnClientEvent:Connect(function(st)
  if type(st) ~= "table" then
    return
  end
  if calNum then
    calNum.Text = tostring(st.calderoHongos or 0)
  end
  if calNumTop then
    calNumTop.Text = tostring(st.calderoHongos or 0)
  end
end)

-- FIN LOCAL CALDERO
