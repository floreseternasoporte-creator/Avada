-- LocalScript del Bosque Prohibido (pegar en StarterPlayer > StarterPlayerScripts)
-- Interfaz como en 99 Noches: barra de hambre naranja a la izquierda, botones
-- circulares a la derecha (Comer, Desgarrar, Tienda/Desalmacenar, CORRER),
-- el Dia/Noche anclado arriba en el centro y el contador del saco pequeño
-- justo encima del boton del saco. NO toca el LocalScript principal.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local SoundService = game:GetService("SoundService")
local RE_UI = RS:WaitForChild("AvadaBosqueUI")
local RE_ACC = RS:WaitForChild("AvadaBosqueAccion")
local RE_SFX = RS:WaitForChild("AvadaSonidos")

-- Sonidos de Avada (locales: cada jugador escucha los suyos). Bosque y
-- musica como en los juegos de supervivencia: recoger/comer dan un
-- "clic" satisfactorio, al caer la noche aulla el lobo, y hay dos
-- pistas largas: una magica para el lobby y el ambiente del bosque
-- nocturno para la partida.
local function nuevoSonido(nombre, id, volumen, loop, velocidad)
  local sd = Instance.new("Sound")
  sd.Name = "Avada_" .. nombre
  sd.SoundId = "rbxassetid://" .. id
  sd.Volume = volumen
  sd.Looping = loop == true
  sd.PlaybackSpeed = velocidad or 1
  sd.Parent = SoundService
  return sd
end
local SFX = {
  Recoger = nuevoSonido("Recoger", 5068107976, 0.55, false, 1.05),
  Guardar = nuevoSonido("Guardar", 5068107976, 0.45, false, 0.82),
  Comer = nuevoSonido("Comer", 625712280, 0.65, false, 1),
  Lena = nuevoSonido("Lena", 9120828958, 0.55, false, 0.95),
  Depositar = nuevoSonido("Depositar", 9120828958, 0.6, false, 0.72),
  Cofre = nuevoSonido("Cofre", 9015015702, 0.55, false, 1),
  Aullido = nuevoSonido("Aullido", 710612141, 0.8, false, 0.92),
  Amanecer = nuevoSonido("Amanecer", 5068107976, 0.4, false, 1.35),
}
local musicaLobby = nuevoSonido("MusicaLobby", 1848133094, 0.3, true, 1)
local musicaBosque = nuevoSonido("MusicaBosque", 138089070, 0.42, true, 1)
local musicaActual
local function ponMusica(sd)
  if musicaActual == sd then
    if not sd.Playing then
      sd:Play()
    end
    return
  end
  if musicaActual and musicaActual.Playing then
    musicaActual:Stop()
  end
  musicaActual = sd
  sd.TimePosition = 0
  sd:Play()
end
ponMusica(musicaLobby)
RE_SFX.OnClientEvent:Connect(function(nombre)
  if nombre == "MusicaBosque" then
    ponMusica(musicaBosque)
  elseif nombre == "MusicaLobby" then
    ponMusica(musicaLobby)
  else
    local sd = SFX[nombre]
    if sd then
      sd.TimePosition = 0
      sd:Play()
    end
  end
end)

pcall(function()
  StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BosqueHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.IgnoreGuiInset = true -- pegado al borde real de la pantalla
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

-- Dia/Noche como la foto de referencia: texto chico en la letra
-- clasica del juego, en cursiva, arriba en el centro y sin fondo.
-- El numero sube solo: Dia 1, Dia 2... y de noche Noche X de 7.
local diaLbl = etiqueta("Día 1", 19, UDim2.new(0.5, 0, 0, 4), UDim2.new(0, 240, 0, 26), Color3.new(1, 1, 1), raiz)
diaLbl.AnchorPoint = Vector2.new(0.5, 0)
diaLbl.Font = Enum.Font.Merriweather
diaLbl.RichText = true
diaLbl.TextXAlignment = Enum.TextXAlignment.Center

-- Barra de hambre: naranja, a la izquierda
local hambreLbl = etiqueta("HAMBRE", 10, UDim2.new(0, 16, 0.40, -18), UDim2.new(0, 120, 0, 14), Color3.new(1, 1, 1), raiz)
local lenosLbl = etiqueta("Leños: 0", 12, UDim2.new(0, 16, 0.42, 18), UDim2.new(0, 160, 0, 18), Color3.fromRGB(255, 215, 150), raiz)
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

-- Contador del saco (X/5) como la foto de referencia: numero grande
-- y claro flotando a la derecha del personaje mientras el saco va en
-- la mano. Solo se ve con el saco puesto, igual que en la referencia.
local contador = etiqueta("0/5", 34, UDim2.new(0.57, 0, 0.42, 0), UDim2.new(0, 110, 0, 46), Color3.new(1, 1, 1), raiz)
contador.AnchorPoint = Vector2.new(0.5, 0.5)
contador.Font = Enum.Font.GothamBlack
contador.TextScaled = true
contador.ZIndex = 5
contador.Visible = false


-- Botones circulares pegados a la esquina, alrededor del boton de salto
-- (como en 99 Noches: Comer arriba-izquierda, CORRER arriba-derecha,
-- Desgarrar a la izquierda del salto y Tienda encima)
local function boton(texto, textSize)
  local b = Instance.new("TextButton")
  b.AnchorPoint = Vector2.new(0.5, 0.5)
  b.Size = UDim2.new(0, 50, 0, 50)
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
correrBtn.Position = UDim2.new(1, -64, 1, -172) -- arriba del salto, pegado
local tiendaBtn = boton("Tienda", 10)
tiendaBtn.Position = UDim2.new(1, -116, 1, -226) -- encima de Comer, juntito
local desgarrarBtn = boton("Desgarrar", 8)
desgarrarBtn.Position = UDim2.new(1, -128, 1, -98) -- a la izquierda del salto, pegado
local comerBtn = boton("Comer", 12)
comerBtn.Position = UDim2.new(1, -122, 1, -164) -- arriba-izquierda del salto, juntito
local soltarBtn = boton("Soltar", 11)
soltarBtn.Position = UDim2.new(1, -180, 1, -164) -- junto a Comer: echa los hongos al caldero
soltarBtn.BackgroundColor3 = Color3.fromRGB(74, 32, 96)
soltarBtn.Visible = false

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
soltarBtn.MouseButton1Click:Connect(function()
  RE_ACC:FireServer("Caldero")
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

-- Red final del contador: cada instante se mira si el saco va en la
-- mano y el numero se ve si o si, sin depender de avisos
task.spawn(function()
  while true do
    task.wait(0.25)
    if ultimoEstado and raiz.Visible then
      local lleva = sacoEnManoLocal
      if not lleva then
        local ch = player.Character
        if ch then
          for _, c in ipairs(ch:GetChildren()) do
            if c:IsA("Tool") and c.Name == "Saco mágico" then
              lleva = true
            end
          end
        end
      end
      contador.Visible = lleva or ultimoEstado.sacoEnMano == true
      if contador.Visible then
        contador.Text = tostring(ultimoEstado.saco or 0) .. "/" .. tostring(ultimoEstado.sacoMax or 5)
      end
      local cercaCal = false
      local ch2 = player.Character
      local hrp2 = ch2 and ch2:FindFirstChild("HumanoidRootPart")
      if hrp2 then
        for _, mCal in ipairs(workspace:GetChildren()) do
          if mCal.Name == "Cauldron" then
            local anclaCal = mCal:FindFirstChild("CalderoAncla")
            if anclaCal then
              local dxC = hrp2.Position.X - anclaCal.Position.X
              local dzC = hrp2.Position.Z - anclaCal.Position.Z
              if (dxC * dxC + dzC * dzC) <= 15 * 15 then
                cercaCal = true
                break
              end
            end
          end
        end
      end
      soltarBtn.Visible = cercaCal and (ultimoEstado.manoTipo == "Hongo" or (ultimoEstado.hongosSaco or 0) > 0)
    end
  end
end)

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
local calNumTop = etiqueta("0", 30, UDim2.new(0, 70, 0, 66), UDim2.new(0, 100, 0, 36), Color3.new(1, 1, 1), calPanel)
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
local calNum = etiqueta("0", 42, UDim2.new(0, 20, 0, 132), UDim2.new(0, 210, 0, 48), Color3.fromRGB(255, 230, 170), calCard)
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

RE_UI.OnClientEvent:Connect(function(st)
  if type(st) ~= "table" then
    return
  end
  ultimoEstado = st
  calNum.Text = tostring(st.calderoHongos or 0)
  calNumTop.Text = tostring(st.calderoHongos or 0)
  raiz.Visible = st.enPartida == true
  if not raiz.Visible then
    return
  end
  relleno.Size = UDim2.new(math.clamp((st.hambre or 100) / 100, 0, 1), 0, 1, 0)
  lenosLbl.Text = "Leños: " .. tostring(st.lenos or 0)
  diaLbl.Text = (st.fase == "noche") and ("<i>Noche " .. tostring(st.noche or 1) .. " de 7</i>") or ("<i>Día " .. tostring((st.noche or 0) + 1) .. "</i>")
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
  tiendaBtn.Visible = st.mano == true and (st.sacoEnMano == true or sacoEnManoLocal == true) -- Tienda solo con el saco puesto
  revisaContador()
end)

-- FIN LOCAL BOSQUE
