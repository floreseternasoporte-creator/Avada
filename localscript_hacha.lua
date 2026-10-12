-- LocalScript HACHA (pegar en StarterPlayer > StarterPlayerScripts)
-- Animación de corte del hacha. NO toca partida.
-- - Detecta la Tool "Hacha" y conecta su Activated.
-- - Reproduce el hachazo (brazo arriba → corte rápido → recupera) + estela.
-- - Avisa al servidor para validar el golpe contra árboles de cristal.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local RE = RS:WaitForChild("HachaEvent", 30)

-- aviso flotante simple
local guiAviso = Instance.new("ScreenGui")
guiAviso.Name = "HachaAviso"
guiAviso.ResetOnSpawn = false
guiAviso.DisplayOrder = 90
guiAviso.IgnoreGuiInset = true
guiAviso.Parent = player:WaitForChild("PlayerGui")

local function avisar(texto)
  local f = Instance.new("TextLabel")
  f.AnchorPoint = Vector2.new(0.5, 0)
  f.Position = UDim2.new(0.5, 0, 0, 130)
  f.Size = UDim2.new(0, 380, 0, 40)
  f.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
  f.BackgroundTransparency = 0.15
  f.Font = Enum.Font.Kalam
  f.TextSize = 18
  f.TextColor3 = Color3.fromRGB(160, 230, 255)
  f.Text = texto
  f.Parent = guiAviso
  Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
  task.delay(2, function()
    pcall(function()
      f:Destroy()
    end)
  end)
end

local function obtenerHombro(char)
  -- R15
  local ut = char:FindFirstChild("UpperTorso")
  if ut then
    local s = ut:FindFirstChild("RightShoulder")
    if s and s:IsA("Motor6D") then
      return s
    end
  end
  -- R6
  local torso = char:FindFirstChild("Torso")
  if torso then
    local s = torso:FindFirstChild("Right Shoulder")
    if s and s:IsA("Motor6D") then
      return s
    end
  end
  return nil
end

local animando = false
local enHachazo = false -- ventana en la que el filo puede tocar árboles

local function animarHachazo(char, tool)
  if animando then return end
  animando = true
  enHachazo = true -- se activa aunque la animación falle, para que el toque cuente
  local hombro = obtenerHombro(char)
  local trail = tool:FindFirstChild("Estela", true)

  if hombro then
    local c0 = hombro.C0
    -- 1) cargar: brazo arriba y atrás
    local t1 = TweenService:Create(hombro,
      TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
      { C0 = c0 * CFrame.Angles(math.rad(-135), 0, math.rad(-18)) })
    t1:Play()
    t1.Completed:Wait()
    -- 2) ¡corte! rápido hacia abajo (con estela)
    if trail then
      trail.Enabled = true
    end
    local t2 = TweenService:Create(hombro,
      TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
      { C0 = c0 * CFrame.Angles(math.rad(50), 0, math.rad(12)) })
    t2:Play()
    t2.Completed:Wait()
    if trail then
      trail.Enabled = false
    end
    -- 3) recuperar a la pose normal
    local t3 = TweenService:Create(hombro,
      TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
      { C0 = c0 })
    t3:Play()
    t3.Completed:Wait()
    enHachazo = false
  else
    -- sin hombro detectable: solo la estela
    if trail then
      trail.Enabled = true
      task.wait(0.3)
      trail.Enabled = false
    else
      task.wait(0.3)
    end
    enHachazo = false
  end
  animando = false
end

-- El filo TOCA el árbol (como en 99 Noches): avisa al servidor
local function conectarToque(tool)
  local hitbox = tool:WaitForChild("HitboxHacha", 10)
  if not hitbox then return end
  hitbox.Touched:Connect(function(hit)
    if not enHachazo then return end
    local modelo = hit and hit:FindFirstAncestorOfClass("Model")
    if modelo and modelo.Name:match("^ArbolCristal") then
      pcall(function()
        RE:FireServer("TocoArbol", modelo)
      end)
    end
  end)
end

local function vigilarTool(tool)
  if not tool:IsA("Tool") or tool.Name ~= "Hacha" then return end
  if tool:GetAttribute("HachaLista") then return end
  tool:SetAttribute("HachaLista", true)
  task.spawn(conectarToque, tool)
  tool.Activated:Connect(function()
    local char = player.Character
    if not char then return end
    -- animación inmediata (responsiva)
    task.spawn(animarHachazo, char, tool)
    -- el servidor valida el golpe
    pcall(function()
      RE:FireServer("Golpear")
    end)
  end)
end

local function onCharacter(char)
  char.ChildAdded:Connect(vigilarTool)
  for _, t in ipairs(char:GetChildren()) do
    vigilarTool(t)
  end
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
  onCharacter(player.Character)
end
task.spawn(function()
  local bp = player:WaitForChild("Backpack", 30)
  if bp then
    bp.ChildAdded:Connect(vigilarTool)
    for _, t in ipairs(bp:GetChildren()) do
      vigilarTool(t)
    end
  end
end)

-- Onda de choque en el punto de impacto
local function ondaChoque(pos)
  if not pos then return end
  local p = Instance.new("Part")
  p.Shape = Enum.PartType.Ball
  p.Size = Vector3.new(1.5, 1.5, 1.5)
  p.Color = Color3.fromRGB(160, 230, 255)
  p.Material = Enum.Material.Neon
  p.Transparency = 0.35
  p.Anchored = true
  p.CanCollide = false
  p.CanQuery = false
  p.TopSurface = Enum.SurfaceType.Smooth
  p.BottomSurface = Enum.SurfaceType.Smooth
  p.CFrame = CFrame.new(pos)
  p.Parent = Workspace
  local t = TweenService:Create(p,
    TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    { Size = Vector3.new(7, 7, 7), Transparency = 1 })
  t:Play()
  t.Completed:Connect(function()
    pcall(function()
      p:Destroy()
    end)
  end)
end

-- Animación de IMPACTO: el hacha rebota al golpear el árbol
local function animarImpacto(dato)
  local char = player.Character
  if char then
    task.spawn(function()
      local hombro = obtenerHombro(char)
      if hombro then
        local c0 = hombro.C0
        -- rebote: el hacha se levanta un poco por el impacto y vuelve
        local t1 = TweenService:Create(hombro,
          TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
          { C0 = c0 * CFrame.Angles(math.rad(-28), 0, 0) })
        t1:Play()
        t1.Completed:Wait()
        local t2 = TweenService:Create(hombro,
          TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
          { C0 = c0 })
        t2:Play()
      end
    end)
  end
  -- onda expansiva en el árbol
  if dato and dato.pos then
    ondaChoque(dato.pos)
  end
  -- contador para saber que el golpe contó
  if dato and dato.golpe and dato.total then
    avisar(string.format("¡Golpe %d/%d al árbol!", dato.golpe, dato.total))
  end
end

-- ===== BOTÓN "CORTAR" en el HUD (como CORRER) =====
local guiCortar = Instance.new("ScreenGui")
guiCortar.Name = "HachaCortar"
guiCortar.ResetOnSpawn = false
guiCortar.DisplayOrder = 60
guiCortar.IgnoreGuiInset = true
guiCortar.Parent = player:WaitForChild("PlayerGui")

local btnCortar = Instance.new("TextButton")
btnCortar.Name = "CortarBtn"
btnCortar.AnchorPoint = Vector2.new(1, 0.5)
btnCortar.Position = UDim2.new(1, -28, 0.5, -110)
btnCortar.Size = UDim2.new(0, 68, 0, 68)
btnCortar.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
btnCortar.BackgroundTransparency = 0.25
btnCortar.BorderSizePixel = 0
btnCortar.Font = Enum.Font.GothamBold
btnCortar.Text = "Cortar"
btnCortar.TextSize = 13
btnCortar.TextColor3 = Color3.new(1, 1, 1)
btnCortar.AutoButtonColor = true
btnCortar.Visible = false
btnCortar.Parent = guiCortar
Instance.new("UICorner", btnCortar).CornerRadius = UDim.new(1, 0)
local stCortar = Instance.new("UIStroke")
stCortar.Color = Color3.fromRGB(0, 0, 0)
stCortar.Transparency = 0.45
stCortar.Thickness = 1.4
stCortar.Parent = btnCortar

local function hacerCorte()
  local char = player.Character
  local tool = char and char:FindFirstChild("Hacha")
  if not tool then return end
  task.spawn(animarHachazo, char, tool)
  pcall(function()
    RE:FireServer("Golpear")
  end)
end

btnCortar.MouseButton1Click:Connect(hacerCorte)

-- visible solo con el hacha equipada y un árbol cerca (no derribado)
task.spawn(function()
  while true do
    task.wait(0.4)
    local visible = false
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if char and char:FindFirstChild("Hacha") and hrp then
      local bosque = Workspace:FindFirstChild("BosqueProhibido")
      if bosque then
        for _, obj in ipairs(bosque:GetChildren()) do
          if obj:IsA("Model") and obj.Name:match("^ArbolCristal%d*$")
            and not obj:GetAttribute("HachaCaido") then
            local ok, pp = pcall(function()
              return obj:GetPivot().Position
            end)
            if ok and (pp - hrp.Position).Magnitude < 15 then
              visible = true
              break
            end
          end
        end
      end
    end
    btnCortar.Visible = visible
  end
end)

if RE then
  RE.OnClientEvent:Connect(function(tipo, dato)
    if tipo == "Aviso" then
      avisar(tostring(dato))
    elseif tipo == "Impacto" then
      animarImpacto(dato)
    end
  end)
end

print("[Hacha] LocalScript cargado")
-- FIN LOCAL HACHA
