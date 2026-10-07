-- Archivo PARTIDA: la supervivencia en el Bosque Prohibido (llama, hambre, Sombras, rescates, 7 noches).
local Players = game:GetService("Players")
local LOBBY_SPAWN = Vector3.new(0, 6, 0)

-- ESTADO DE LA PARTIDA
--===========================================================
local NOCHES_META = 7
local NOCHE_LEN = 140
local DIA_LEN = 50
local FC = Vector3.new(0, 0, 4200) -- centro del bosque (lejos del lobby)

local SE = {
  on = false,
  cuentaAtras = 0,
  enCirculo = {},
  players = {}, -- [player] = {vivo, lenos, hambre}
  sombras = {}, -- lista de criaturas vivas
  noche = 0,
  fase = "dia",
  llama = 100,
  aprendices = 0,
}
local castCd = {}

local function jugadorEnPartida(player)
  return SE.on and SE.players[player] ~= nil
end

local function vivosEnPartida()
  local n = 0
  for _, d in pairs(SE.players) do
    if d.vivo then
      n += 1
    end
  end
  return n
end

--===========================================================

local function clasicoEn(modelo)
  if not CLASSIC_STUDS or not modelo then
    return
  end
  local ST = Enum.SurfaceType.Studs
  local SM = Enum.SurfaceType.Smooth
  local INL = Enum.SurfaceType.Inlet
  for _, p in ipairs(modelo:GetDescendants()) do
    if p:IsA("BasePart") and p.Transparency < 1 then
      p.Material = Enum.Material.Plastic
      p.Reflectance = 0
      -- una Texture en una cara tapa los studs de esa cara: se apaga
      for _, t in ipairs(p:GetChildren()) do
        if t:IsA("Texture") then
          t.Transparency = 1
        end
      end
      local cn = p.ClassName
      local sx, sy, sz = p.Size.X, p.Size.Y, p.Size.Z
      if cn == "WedgePart" or cn == "CornerWedgePart" then
        p.TopSurface = ST
        p.FrontSurface = ST
        p.BackSurface = ST
        p.BottomSurface = INL
        p.LeftSurface, p.RightSurface = SM, SM
      elseif cn == "Part" and p.Shape == Enum.PartType.Cylinder then
        -- en un cilindro las caras redondas son Left/Right: ahi van los studs
        -- (la isla entera es un cilindro: ese es el suelo)
        p.LeftSurface = ST
        p.RightSurface = ST
        p.TopSurface, p.BottomSurface, p.FrontSurface, p.BackSurface = SM, SM, SM, SM
      elseif cn == "Part" and p.Shape == Enum.PartType.Block then
        p.TopSurface = (sx >= 0.9 and sz >= 0.9) and ST or SM
        p.BottomSurface = (sx >= 0.9 and sz >= 0.9) and INL or SM
        p.FrontSurface = (sx >= 0.9 and sy >= 0.9) and ST or SM
        p.BackSurface = p.FrontSurface
        p.LeftSurface = (sz >= 0.9 and sy >= 0.9) and ST or SM
        p.RightSurface = p.LeftSurface
      else
        -- esferas y mallas: lisas (en el Roblox clasico eran mallas, sin studs)
        p.TopSurface, p.BottomSurface = SM, SM
        p.LeftSurface, p.RightSurface, p.FrontSurface, p.BackSurface = SM, SM, SM, SM
      end
    end
  end
end


--===========================================================
-- DESCUBRIR LAS PIEZAS DEL BOSQUE (las construye el archivo BOSQUE)
--===========================================================
local Bosque, fuegoPos, deposito, llamaParts, llamaBase, llamaLight, anilloSeguro, chispasFuego
local jaulas, jaulasPos, lenaNodos, fresas, cofres, fireStatus
local circleTitle, circleStatus, circleSub
local fireBoardAnchor

local function escanearBosque()
  Bosque = workspace:FindFirstChild("BosqueProhibido")
  if not (Bosque and Bosque:GetAttribute("Listo")) then
    return false
  end

  if Bosque then
    -- fuego y deposito
    llamaParts = {}
    llamaBase = { [1] = Vector3.new(2.6, 2.2, 2.6), [2] = Vector3.new(1.9, 2.0, 1.9), [3] = Vector3.new(1.2, 1.8, 1.2) }
    anilloSeguro = {}
    lenaNodos, bayas, cofres, jaulas, jaulasPos = {}, {}, {}, {}, {}
    local fresasPorClave = {}
    for _, d in ipairs(Bosque:GetDescendants()) do
      if d:IsA("BasePart") then
        local g = d:GetAttribute("Grupo")
        if g == "Llama" then
          llamaParts[d:GetAttribute("Idx") or 1] = d
        elseif g == "Anillo" then
          table.insert(anilloSeguro, { part = d, ang = d:GetAttribute("Ang") or 0 })
        end
        if d:GetAttribute("Rol") == "Deposito" then
          deposito = d
        elseif d:GetAttribute("Rol") == "FireAnchor" then
          fireBoardAnchor = d
          fuegoPos = d.Position - Vector3.new(0, 11, 0)
        end
        local tipo = d:GetAttribute("Tipo")
        if tipo == "Lena" then
          table.insert(lenaNodos, { part = d, pos = d.Position, listoEn = 0 })
        elseif tipo == "Baya" or tipo == "Tapa" or tipo == "Tallo" then
          local gi = d:GetAttribute("Arbusto") or 1
          local fj = d:GetAttribute("Fresa") or 1
          local clave = gi .. "/" .. fj
          fresasPorClave[clave] = fresasPorClave[clave] or {}
          fresasPorClave[clave][tipo] = d
        elseif tipo == "Cofre" then
          table.insert(cofres, { pos = d.Position, listo = 0, base = d })
        end
      elseif d:IsA("Model") and d:GetAttribute("Jaula") then
        -- se completa abajo junto con su ancla
      end
    end
    for _, conj in pairs(fresasPorClave) do
      if conj.Baya then
        table.insert(fresas, { berry = conj.Baya, tapa = conj.Tapa, tallo = conj.Tallo, disponible = true })
      end
    end
    if llamaParts[1] then
      llamaLight = llamaParts[1]:FindFirstChildOfClass("PointLight")
      chispasFuego = llamaParts[1]:FindFirstChild("FireSparks")
    end
    -- jaulas: anclas etiquetadas con su indice
    for _, d in ipairs(Bosque:GetDescendants()) do
      if d:IsA("BasePart") and d:GetAttribute("Jaula") and d.Name == "CageAnchor" then
        local ci = d:GetAttribute("Jaula")
        local posJ = d.Position - Vector3.new(0, 10, 0)
        jaulasPos[ci] = posJ
        local gui = d:FindFirstChildOfClass("BillboardGui")
        jaulas[ci] = {
          pos = posJ,
          fig = nil,
          barrotes = {},
          label = gui and gui:FindFirstChildOfClass("TextLabel"),
          libre = false,
          rescatado = false,
        }
      end
    end
    for _, d in ipairs(Bosque:GetDescendants()) do
      if d:IsA("Model") and d:GetAttribute("Jaula") then
        local j = jaulas[d:GetAttribute("Jaula")]
        if j then
          j.fig = d
        end
      elseif d:IsA("BasePart") and d:GetAttribute("Jaula") and d.Name == "CageBar" then
        local j = jaulas[d:GetAttribute("Jaula")]
        if j then
          table.insert(j.barrotes, d)
        end
      end
    end
    if fireBoardAnchor then
      local gui = fireBoardAnchor:FindFirstChildOfClass("BillboardGui")
      if gui then
        fireStatus = gui:FindFirstChild("FireStatus")
      end
    end
  end

  return true
end

-- Archivo PARTIDA: la supervivencia en el Bosque Prohibido (noche, llama, hambre, Sombras, rescates).
local Players = game:GetService("Players")
local LOBBY_SPAWN = Vector3.new(0, 6, 0)

-- CARTELES
--===========================================================
local function updateCircleBoard()
  if not (circleTitle and circleStatus and circleSub) then
    return -- el cartel aun no aparece: el hilo del circulo sigue vivo
  end
  if SE.on then
    circleTitle.Text = "PARTIDA EN CURSO"
    circleStatus.Text = "Noche " .. math.max(SE.noche, 1) .. " de " .. NOCHES_META .. " - Llama al " .. math.floor(SE.llama) .. "%"
    circleSub.Text = "La siguiente partida empieza al terminar esta"
  elseif SE.cuentaAtras > 0 then
    circleTitle.Text = "BOSQUE PROHIBIDO"
    circleStatus.Text = "La partida empieza en " .. math.ceil(SE.cuentaAtras) .. "..."
    local n = 0
    for _ in pairs(SE.enCirculo) do
      n += 1
    end
    circleSub.Text = n .. " mago(s) entrando - entra tu tambien"
  else
    circleTitle.Text = "BOSQUE PROHIBIDO"
    circleStatus.Text = "Párate en el círculo para entrar"
    circleSub.Text = "Sobrevive 7 noches - Rescata a los 4 aprendices"
  end
end

local function updateFireBoard()
  if not (llamaParts and llamaBase and fuegoPos) then
    return -- el bosque aun no se descubre: nada que actualizar
  end
  if fireStatus then
    fireStatus.Text = "Llama "
    .. math.floor(SE.llama)
    .. "% - Noche "
    .. math.max(SE.noche, 1)
    .. "/"
    .. NOCHES_META
    .. " - Aprendices "
    .. SE.aprendices
    .. "/4"
  end
  -- el tamano y el baile de la llama los lleva el animador (abajo);
  -- aqui solo respira el anillo seguro en el suelo
  local radio = 9 + SE.llama * 0.11
  for _, sd in ipairs(anilloSeguro) do
    sd.part.CFrame = CFrame.new(fuegoPos.X, fuegoPos.Y + 0.12, fuegoPos.Z) * CFrame.Angles(0, -sd.ang, 0) * CFrame.new(0, 0, radio)
  end
end

local function radioSeguro()
  return 9 + SE.llama * 0.11
end

--===========================================================
--===========================================================
-- PUENTES CON EL NUCLEO (por nombre, sin require ni shared)
--===========================================================
local bfDanoCache, bfBajaCache
local function danoHechizo(nombre)
  if not bfDanoCache then
    bfDanoCache = game:GetService("ServerScriptService"):FindFirstChild("AvadaDanoHechizo")
  end
  if bfDanoCache then
    local ok, d = pcall(function()
      return bfDanoCache:Invoke(nombre)
    end)
    if ok then
      return d
    end
  end
  return nil
end
local function bajaKill(player)
  if not bfBajaCache then
    bfBajaCache = game:GetService("ServerScriptService"):FindFirstChild("AvadaRegistrarBaja")
  end
  if bfBajaCache then
    pcall(function()
      bfBajaCache:Invoke(player)
    end)
  end
end

--===========================================================

--===========================================================
-- OBJETOS: fresas en la mano, SACO MAGICO (x/5) y acciones
-- (como en 99 Noches: Comer, Desgarrar, Tienda, Desalmacenar)
--===========================================================
local RSvc = game:GetService("ReplicatedStorage")
local function remotoBosque(nombre)
  local r = RSvc:FindFirstChild(nombre)
  if not r then
    r = Instance.new("RemoteEvent")
    r.Name = nombre
    r.Parent = RSvc
  end
  return r
end
local RE_UI = remotoBosque("AvadaBosqueUI")
local RE_ACC = remotoBosque("AvadaBosqueAccion")
local SACO_MAX = 5

local function sincronizaUI(player)
  local d = SE.players[player]
  if not (player and player.Parent) then
    return
  end
  pcall(function()
    RE_UI:FireClient(player, {
      enPartida = SE.on and d ~= nil,
      hambre = d and math.floor(d.hambre or 100) or 100,
      mano = (d and d.toolFresa ~= nil) or false,
      saco = d and #(d.saco or {}) or 0,
      sacoMax = SACO_MAX,
      sacoEnMano = (d and d.sacoEnMano) or false,
      noche = SE.noche,
      fase = SE.fase,
    })
  end)
end

local function parteDeTool(nombre, size, cf, color, material)
  local pt = Instance.new("Part")
  pt.Name = nombre
  pt.Size = size
  pt.CFrame = cf
  pt.Color = color
  pt.Material = material or Enum.Material.SmoothPlastic
  pt.CanCollide = false
  pt.CastShadow = false
  pt.Massless = true
  return pt
end

-- La fresa en la mano (se puede comer, desgarrar o guardar en el saco)
local function darFresaEnMano(player)
  local d = SE.players[player]
  if not d or d.toolFresa then
    return
  end
  local tool = Instance.new("Tool")
  tool.Name = "Fresa"
  tool.ToolTip = "Fresa del Bosque Prohibido"
  tool.CanBeDropped = false
  local h = parteDeTool("Handle", Vector3.new(0.66, 0.8, 0.66), CFrame.new(0, 3, 0), Color3.fromRGB(232, 42, 52))
  h.Shape = Enum.PartType.Ball
  h.Parent = tool
  local tapa = parteDeTool("BerryCap", Vector3.new(0.46, 0.2, 0.46), CFrame.new(), Color3.fromRGB(40, 120, 44))
  tapa.Shape = Enum.PartType.Ball
  tapa.CFrame = h.CFrame * CFrame.new(0, 0.45, 0)
  tapa.Parent = tool
  local w = Instance.new("WeldConstraint")
  w.Part0 = h
  w.Part1 = tapa
  w.Parent = tapa
  tool.Parent = player:FindFirstChildOfClass("Backpack")
  d.toolFresa = tool
  local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum then
    pcall(function()
      hum:EquipTool(tool)
    end)
  end
  sincronizaUI(player)
end

-- El saco del mago: marron con banda purpura y estrella dorada, guarda 5
local function darSacoMago(player)
  local d = SE.players[player]
  if not d or d.toolSaco then
    return
  end
  local tool = Instance.new("Tool")
  tool.Name = "Saco mágico"
  tool.ToolTip = "Tu saco de mago: guarda hasta " .. SACO_MAX .. " cosas"
  tool.CanBeDropped = false
  local h = parteDeTool("Handle", Vector3.new(1.05, 1.2, 1.05), CFrame.new(0, 3, 0), Color3.fromRGB(156, 108, 62))
  h.Shape = Enum.PartType.Ball
  h.Parent = tool
  local function piezaSaco(nombre, size, off, color, material)
    local pz = parteDeTool(nombre, size, CFrame.new(), color, material)
    pz.CFrame = h.CFrame * CFrame.new(off)
    pz.Parent = tool
    local w = Instance.new("WeldConstraint")
    w.Part0 = h
    w.Part1 = pz
    w.Parent = pz
    return pz
  end
  piezaSaco("SackBand", Vector3.new(0.78, 0.3, 0.78), Vector3.new(0, 0.48, 0), Color3.fromRGB(96, 52, 140))
  local nudo = piezaSaco("SackKnot", Vector3.new(0.42, 0.42, 0.42), Vector3.new(0, 0.78, 0), Color3.fromRGB(120, 80, 44))
  nudo.Shape = Enum.PartType.Ball
  local estrella = piezaSaco("SackStar", Vector3.new(0.4, 0.4, 0.12), Vector3.new(0, -0.05, -0.52), Color3.fromRGB(255, 196, 48), Enum.Material.Neon)
  estrella.CFrame = h.CFrame * CFrame.new(0, -0.05, -0.52) * CFrame.Angles(0, 0, math.rad(45))
  tool.Parent = player:FindFirstChildOfClass("Backpack")
  d.toolSaco = tool
  tool.Equipped:Connect(function()
    if SE.players[player] == d then
      d.sacoEnMano = true
      sincronizaUI(player)
    end
  end)
  tool.Unequipped:Connect(function()
    if SE.players[player] == d then
      d.sacoEnMano = false
      sincronizaUI(player)
    end
  end)
  sincronizaUI(player)
end

local function comerFresa(player, desdeSaco)
  local d = SE.players[player]
  if not d then
    return
  end
  if desdeSaco then
    if #d.saco <= 0 then
      return
    end
    table.remove(d.saco, 1)
  else
    if not d.toolFresa then
      return
    end
    d.toolFresa:Destroy()
    d.toolFresa = nil
  end
  d.hambre = math.min(100, d.hambre + 30)
  sincronizaUI(player)
end

local function desgarrarFresa(player)
  local d = SE.players[player]
  if not d or not d.toolFresa then
    return
  end
  d.toolFresa:Destroy()
  d.toolFresa = nil
  -- la fresa cae al suelo y otro mago (o tu mismo) la puede recoger
  local char = player.Character
  local hrp = char and char:FindFirstChild("HumanoidRootPart")
  if hrp then
    local pos = hrp.Position + hrp.CFrame.LookVector * 2.5
    local suelta = Instance.new("Model")
    suelta.Name = "FresaSuelta"
    local fb = parteDeTool("Berry", Vector3.new(0.6, 0.74, 0.6), CFrame.new(pos.X, 2.6, pos.Z), Color3.fromRGB(232, 42, 52))
    fb.Shape = Enum.PartType.Ball
    fb.Anchored = true
    fb.Parent = suelta
    local tapa = parteDeTool("BerryCap", Vector3.new(0.44, 0.18, 0.44), CFrame.new(pos.X, 3.05, pos.Z), Color3.fromRGB(40, 120, 44))
    tapa.Shape = Enum.PartType.Ball
    tapa.Anchored = true
    tapa.Parent = suelta
    local pr = Instance.new("ProximityPrompt")
    pr.ActionText = "Recoger"
    pr.ObjectText = "Fresa"
    pr.HoldDuration = 0
    pr.MaxActivationDistance = 9
    pr.RequiresLineOfSight = false
    pr.Parent = fb
    pr.Triggered:Connect(function(otro)
      if jugadorEnPartida(otro) and SE.players[otro].vivo and not SE.players[otro].toolFresa then
        suelta:Destroy()
        darFresaEnMano(otro)
      end
    end)
    suelta.Parent = workspace
  end
  sincronizaUI(player)
end

local function guardarEnSaco(player) -- boton "Tienda": mete la fresa al saco
  local d = SE.players[player]
  if not d or not d.toolFresa or #d.saco >= SACO_MAX then
    return
  end
  d.toolFresa:Destroy()
  d.toolFresa = nil
  table.insert(d.saco, "Fresa")
  sincronizaUI(player)
end

local function desalmacenar(player) -- saca una fresa del saco a la mano
  local d = SE.players[player]
  if not d or d.toolFresa or #d.saco <= 0 then
    return
  end
  table.remove(d.saco, 1)
  darFresaEnMano(player)
  sincronizaUI(player)
end

local function limpiarObjetos(player)
  local d = SE.players[player]
  if not d then
    return
  end
  if d.toolFresa then
    d.toolFresa:Destroy()
    d.toolFresa = nil
  end
  if d.toolSaco then
    d.toolSaco:Destroy()
    d.toolSaco = nil
  end
  d.saco = {}
  d.sacoEnMano = false
end

local function recogerFresaDelArbusto(player, fr)
  if not fr.disponible or not jugadorEnPartida(player) then
    return
  end
  local d = SE.players[player]
  if not d.vivo or d.toolFresa then
    return
  end
  fr.disponible = false
  for _, parte in ipairs({ fr.berry, fr.tapa, fr.tallo }) do
    if parte then
      parte.Transparency = 1
    end
  end
  if fr.prompt then
    fr.prompt.Enabled = false
  end
  darFresaEnMano(player)
  task.delay(18, function()
    fr.disponible = true
    for _, parte in ipairs({ fr.berry, fr.tapa, fr.tallo }) do
      if parte and parte.Parent then
        parte.Transparency = 0
      end
    end
    if fr.prompt then
      fr.prompt.Enabled = true
    end
  end)
end

RE_ACC.OnServerEvent:Connect(function(player, accion)
  if not jugadorEnPartida(player) or not SE.players[player].vivo then
    return
  end
  if accion == "Comer" then
    if SE.players[player].toolFresa then
      comerFresa(player, false)
    else
      comerFresa(player, true)
    end
  elseif accion == "Desgarrar" then
    desgarrarFresa(player)
  elseif accion == "Tienda" then
    guardarEnSaco(player)
  elseif accion == "Desalmacenar" then
    desalmacenar(player)
  end
end)

-- el hambre baja sin parar: la barra de la interfaz se refresca sola
task.spawn(function()
  while true do
    task.wait(1.5)
    if SE.on then
      for player, _ in pairs(SE.players) do
        sincronizaUI(player)
      end
    end
  end
end)

-- SOMBRAS (las criaturas de la noche)
--===========================================================
local function crearSombra(pos, esGuardian, jaulaIdx, tipo)
  tipo = tipo or "normal"
  local esc = (tipo == "gigante") and 1.9 or 1
  local model = Instance.new("Model")
  model.Name = "Sombra"
  local root = Instance.new("Part")
  root.Name = "Root"
  root.Size = Vector3.new(2.1 * esc, 3.2 * esc, 1.1 * esc)
  root.BrickColor = BrickColor.new("White")
  root.Color = Color3.fromRGB(18, 16, 28)
  root.Material = Enum.Material.SmoothPlastic
  root.Anchored = true
  root.CanCollide = false
  root.CastShadow = false
  root.CFrame = CFrame.new(pos)
  root.Parent = model
  local head = Instance.new("Part")
  head.Name = "Head"
  head.Size = Vector3.new(1.5 * esc, 1.3 * esc, 1.3 * esc)
  head.BrickColor = BrickColor.new("White")
  head.Color = Color3.fromRGB(13, 12, 22)
  head.Material = Enum.Material.SmoothPlastic
  head.Anchored = true
  head.CanCollide = false
  head.CastShadow = false
  head.CFrame = CFrame.new(pos + Vector3.new(0, 2.25 * esc, 0))
  head.Parent = model
  local cuernos = {}
  if tipo == "gigante" then
    for _, sd in ipairs({ -1, 1 }) do
      local cuerno = Instance.new("WedgePart")
      cuerno.Name = "Cuerno"
      cuerno.Size = Vector3.new(0.55, 1.7, 0.55)
      cuerno.BrickColor = BrickColor.new("White")
      cuerno.Color = Color3.fromRGB(230, 224, 210)
      cuerno.Material = Enum.Material.SmoothPlastic
      cuerno.Anchored = true
      cuerno.CanCollide = false
      cuerno.CastShadow = false
      cuerno.CFrame = CFrame.new(pos + Vector3.new(sd * 1.25, 3.6, 0)) * CFrame.Angles(0, 0, math.rad(-sd * 34))
      cuerno.Parent = model
      table.insert(cuernos, { part = cuerno, off = Vector3.new(sd * 1.25, 3.6, 0), ang = math.rad(-sd * 34) })
    end
  end
  local ojos = {}
  for _, sd in ipairs({ -0.35, 0.35 }) do
    local eye = Instance.new("Part")
    eye.Name = "Eye"
    eye.Size = Vector3.new(0.28, 0.2, 0.1)
    eye.BrickColor = BrickColor.new("White")
    eye.Color = Color3.fromRGB(255, 64, 84)
    eye.Material = Enum.Material.Neon
    eye.Anchored = true
    eye.CanCollide = false
    eye.CastShadow = false
    eye.CFrame = CFrame.new(pos + Vector3.new(sd * esc, 2.35 * esc, 0.68 * esc))
    eye.Parent = model
    table.insert(ojos, { part = eye, off = Vector3.new(sd * esc, 2.35 * esc, 0.68 * esc) })
  end
  local gl = Instance.new("BillboardGui")
  gl.Size = UDim2.new(5, 0, 1, 0)
  gl.StudsOffset = Vector3.new(0, 3.4, 0)
  gl.AlwaysOnTop = true
  gl.LightInfluence = 0
  gl.MaxDistance = 90
  gl.Parent = root
  local glLbl = Instance.new("TextLabel")
  glLbl.Size = UDim2.new(1, 0, 1, 0)
  glLbl.BackgroundTransparency = 1
  glLbl.Font = Enum.Font.GothamBold
  glLbl.TextScaled = true
  glLbl.TextColor3 = Color3.fromRGB(255, 120, 130)
  glLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  glLbl.TextStrokeTransparency = 0.3
  glLbl.Text = (tipo == "gigante") and "EL SIN NOMBRE" or ((tipo == "raider") and "Adepto Sombra" or "Sombra")
  glLbl.Parent = gl
  model.Parent = workspace
  clasicoEn(model)
  local hp = esGuardian and 220 or (90 + SE.noche * 25)
  if tipo == "gigante" then
    hp = 100000 -- El Sin Nombre no muere: solo se aturde
  elseif tipo == "raider" then
    hp = 200
  end
  local som = {
    model = model,
    root = root,
    head = head,
    headOff = 2.25 * esc,
    ojos = ojos,
    cuernos = cuernos,
    tipo = tipo,
    aturdidoHasta = 0,
    label = glLbl,
    hp = hp,
    hpMax = hp,
    guardian = esGuardian,
    jaula = jaulaIdx,
    golpeEn = 0,
  }
  table.insert(SE.sombras, som)
  return som
end

local function matarSombra(som, killer)
  for i, s2 in ipairs(SE.sombras) do
    if s2 == som then
      table.remove(SE.sombras, i)
      break
    end
  end
  if killer then
    bajaKill(killer)
  end
  if som.guardian and som.jaula then
    local quedan = false
    for _, s2 in ipairs(SE.sombras) do
      if s2.guardian and s2.jaula == som.jaula then
        quedan = true
        break
      end
    end
    if not quedan then
      local j = jaulas[som.jaula]
      if j and not j.libre then
        j.libre = true
        for _, bar in ipairs(j.barrotes) do
          bar.Transparency = 0.75
          bar.CanCollide = false
        end
        j.label.Text = "Jaula abierta: toca al aprendiz"
      end
    end
  end
  if som.model then
    som.model:Destroy()
  end
end

local function danarSombra(som, dmg, de, player)
  if som.tipo == "gigante" then
    som.aturdidoHasta = os.clock() + 2.2
    if som.label then
      som.label.Text = "EL SIN NOMBRE (aturdido)"
    end
  end
  som.hp -= dmg
  if som.label then
    if som.tipo ~= "gigante" then som.label.Text = (som.tipo == "raider" and "Adepto " or "Sombra ") .. math.max(math.floor(som.hp), 0) .. "/" .. som.hpMax end
  end
  if som.root and som.root.Parent then
    local dir = (som.root.Position - de).Unit
    dir = Vector3.new(dir.X, 0, dir.Z)
    som.root.CFrame = som.root.CFrame + dir * 1.6
    if som.head then
      som.head.CFrame = som.head.CFrame + dir * 1.6
    end
    if som.ojos then
      for _, oj in ipairs(som.ojos) do
        oj.part.CFrame = oj.part.CFrame + dir * 1.6
      end
    end
    local old = som.root.Color
    som.root.Color = Color3.fromRGB(255, 240, 240)
    task.delay(0.08, function()
      if som.root and som.root.Parent then
        som.root.Color = old
      end
    end)
  end
  if som.hp <= 0 then
    if som.tipo == "gigante" then
      som.hp = som.hpMax -- nunca muere
      if som.label then
        som.label.Text = "EL SIN NOMBRE"
      end
    else
      matarSombra(som, player)
    end
  end
end

-- Hechizos contra las Sombras (sin duelo: golpea la mas cercana)
local function golpeSombra(caster, spellName)
  if not jugadorEnPartida(caster) then
    return false
  end
  if not SE.players[caster].vivo then
    return true
  end
  local dmgBase = danoHechizo(spellName)
  if not dmgBase then
    return true
  end
  local char = caster.Character
  if not char then
    return true
  end
  local wand = char:FindFirstChild("Varita Magica")
  if wand then
    wand:SetAttribute("CastSpell", spellName)
    wand:SetAttribute("Casting", true)
    task.delay(0.5, function()
      if wand and wand.Parent then
        wand:SetAttribute("Casting", false)
      end
    end)
  end
  local now = os.clock()
  if castCd[caster] and now - castCd[caster] < 0.5 then
    return true
  end
  castCd[caster] = now
  local hrp = char:FindFirstChild("HumanoidRootPart")
  if not hrp then
    return true
  end
  local best, bestD
  for _, som in ipairs(SE.sombras) do
    if som.root and som.root.Parent then
      local d = (som.root.Position - hrp.Position).Magnitude
      if d <= 34 and (not bestD or d < bestD) then
        best, bestD = som, d
      end
    end
  end
  if best then
    local dmg = dmgBase or 40
    if spellName ~= "AvadaKedavra" then
      dmg = math.floor(dmg * 1.4)
    end
    danarSombra(best, dmg, hrp.Position, caster)
  end
  return true
end

--===========================================================
local bfGolpe = Instance.new("BindableFunction")
bfGolpe.Name = "AvadaGolpeSombra"
bfGolpe.Parent = game:GetService("ServerScriptService")
bfGolpe.OnInvoke = function(caster, spellName)
  return golpeSombra(caster, spellName)
end

-- FLUJO DE LA PARTIDA
--===========================================================
local LightingSvc = game:GetService("Lighting")

local function volverAlLobby(player)
  limpiarObjetos(player)
  local char = player and player.Character
  if char then
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
      hum.Health = hum.MaxHealth
    end
    if hrp then
      hrp.CFrame = CFrame.new(LOBBY_SPAWN + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
    end
  end
end

local function finPartida(victoria)
  if not SE.on then
    return
  end
  SE.on = false
  for i = #SE.sombras, 1, -1 do
    local som = SE.sombras[i]
    if som.model then
      som.model:Destroy()
    end
    table.remove(SE.sombras, i)
  end
  LightingSvc.ClockTime = 13.2
  LightingSvc.FogEnd = 100000
  if circleTitle and circleStatus and circleSub then
    if victoria then
      circleTitle.Text = "BOSQUE SUPERADO"
      circleStatus.Text = "Los magos vencieron las " .. NOCHES_META .. " noches"
    else
      circleTitle.Text = "BOSQUE PROHIBIDO"
      circleStatus.Text = "La partida termino en la noche " .. math.max(SE.noche, 1)
    end
    circleSub.Text = "Párate en el círculo para jugar otra vez"
  end
  for player, _ in pairs(SE.players) do
    volverAlLobby(player)
  end
  SE.players = {}
  SE.cuentaAtras = 0
  SE.enCirculo = {}
  task.delay(6, function()
    if not SE.on then
      updateCircleBoard()
    end
  end)
end

local function marcarMuerto(player)
  local d = SE.players[player]
  if not d or not d.vivo then
    return
  end
  d.vivo = false
  volverAlLobby(player)
  if vivosEnPartida() <= 0 then
    finPartida(false)
  end
end

local function nocheSombras()
  local total
  if SE.noche == 1 then
    total = 1 -- primera noche suave, como en 99 Noches
  else
    total = math.min(2 + SE.noche, 10)
  end
  for i = 1, total do
    local a = math.random() * math.pi * 2
    local pos = Vector3.new(FC.X + math.cos(a) * 205, 5.5, FC.Z + math.sin(a) * 205)
    crearSombra(pos, false, nil, "normal")
  end
  -- incursiones: en las noches 3 y 6 los Adeptos entran hasta la fogata
  if SE.noche == 3 or SE.noche == 6 then
    local n = (SE.noche == 3) and 2 or 4
    for i = 1, n do
      local a = math.random() * math.pi * 2
      local pos = Vector3.new(FC.X + math.cos(a) * 175, 5.5, FC.Z + math.sin(a) * 175)
      crearSombra(pos, false, nil, "raider")
    end
  end
  -- El Sin Nombre ronda desde la noche 2 (no muere: se aturde con hechizos)
  if SE.noche >= 2 then
    local yaHay = false
    for _, som in ipairs(SE.sombras) do
      if som.tipo == "gigante" then
        yaHay = true
        break
      end
    end
    if not yaHay then
      local a = math.random() * math.pi * 2
      crearSombra(Vector3.new(FC.X + math.cos(a) * 215, 7.5, FC.Z + math.sin(a) * 215), false, nil, "gigante")
    end
  end
end

local function cicloPartida()
  while SE.on do
    -- DIA
    SE.fase = "dia"
    LightingSvc.ClockTime = 13.2
    LightingSvc.FogEnd = 100000
    updateFireBoard()
    local tDia = 0
    while SE.on and tDia < DIA_LEN do
      task.wait(1)
      tDia += 1
      for player, d in pairs(SE.players) do
        if d.vivo then
          d.hambre = math.max(0, d.hambre - 0.5)
          if d.hambre <= 0 then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
              hum:TakeDamage(1.5)
            end
          end
        end
      end
    end
    if not SE.on then
      break
    end
    -- NOCHE
    SE.noche += 1
    SE.fase = "noche"
    LightingSvc.ClockTime = 0.4
    LightingSvc.FogColor = Color3.fromRGB(16, 18, 34)
    LightingSvc.FogStart = 20
    LightingSvc.FogEnd = 110
    nocheSombras()
    updateFireBoard()
    updateCircleBoard()
    local tNoche = 0
    local nocheDur = math.max(NOCHE_LEN - SE.aprendices * 12, 70)
    while SE.on and tNoche < nocheDur do
      task.wait(1)
      tNoche += 1
      -- la llama se consume mas rapido de noche
      SE.llama = math.max(0, SE.llama - (100 / (NOCHE_LEN * 1.25)))
      for player, d in pairs(SE.players) do
        if d.vivo then
          d.hambre = math.max(0, d.hambre - 0.8)
          if d.hambre <= 0 then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
              hum:TakeDamage(2)
            end
          end
        end
      end
      if SE.llama <= 0 then
        circleStatus.Text = "LA LLAMA SE APAGO - fin de la partida"
        task.wait(2)
        finPartida(false)
        return
      end
      updateFireBoard()
    end
    if not SE.on then
      break
    end
    -- amanecer: las sombras de la noche se queman
    for i = #SE.sombras, 1, -1 do
      local som = SE.sombras[i]
      if not som.guardian then
        if som.model then
          som.model:Destroy()
        end
        table.remove(SE.sombras, i)
      end
    end
    if SE.noche >= NOCHES_META then
      finPartida(true)
      return
    end
    updateCircleBoard()
  end
end

local function bucleSombras()
  while true do
    task.wait(0.25)
    if SE.on then
      for _, som in ipairs(SE.sombras) do
        if som.root and som.root.Parent and os.clock() >= (som.aturdidoHasta or 0) then
          -- objetivo: el mago vivo mas cercano
          local bestP, bestD, bestPos
          for player, d in pairs(SE.players) do
            if d.vivo and player.Character then
              local hrp = player.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                local dist = (hrp.Position - som.root.Position).Magnitude
                if not bestD or dist < bestD then
                  bestP, bestD, bestPos = player, dist, hrp.Position
                end
              end
            end
          end
          -- los guardianes no se alejan de su jaula
          if som.guardian and som.jaula then
            local jp = jaulas[som.jaula].pos
            if (som.root.Position - jp).Magnitude > 60 then
              bestPos = Vector3.new(jp.X, som.root.Position.Y, jp.Z)
              bestD = (bestPos - som.root.Position).Magnitude
            end
          end
          if bestPos then
            local rp = som.root.Position
            local dfx, dfz = rp.X - fuegoPos.X, rp.Z - fuegoPos.Z
            local toFire = math.sqrt(dfx * dfx + dfz * dfz)
            local destino = bestPos
            -- la llama protege: no entran al anillo mientras arda
            -- (los Adeptos de las incursiones SI entran, como en 99 Noches)
            if SE.llama > 0 and som.tipo ~= "raider" then
              local pfx, pfz = bestPos.X - fuegoPos.X, bestPos.Z - fuegoPos.Z
              local pf = math.sqrt(pfx * pfx + pfz * pfz)
              if pf < radioSeguro() + 1 then
                local dx, dz = dfx, dfz
                local dm = math.sqrt(dx * dx + dz * dz)
                if dm < 1 then
                  dx, dz, dm = 1, 0, 1
                end
                local rr = radioSeguro() + 2.5
                destino = Vector3.new(fuegoPos.X + (dx / dm) * rr, rp.Y, fuegoPos.Z + (dz / dm) * rr)
              end
            end
            local dir = destino - rp
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude > 0.15 then
              local vel = (som.tipo == "gigante") and 13.5 or (11 + SE.noche * 0.5)
              local paso = dir.Unit * math.min(dir.Magnitude, vel * 0.25)
              local nuevo = rp + paso
              local cf = CFrame.new(nuevo, nuevo + dir.Unit)
              som.root.CFrame = cf
              if som.head then
                som.head.CFrame = cf * CFrame.new(0, som.headOff or 2.25, 0)
              end
              if som.ojos then
                for _, oj in ipairs(som.ojos) do
                  oj.part.CFrame = cf * CFrame.new(oj.off)
                end
              end
              if som.cuernos then
                for _, cu in ipairs(som.cuernos) do
                  cu.part.CFrame = cf * CFrame.new(cu.off) * CFrame.Angles(0, 0, cu.ang)
                end
              end
              rp = nuevo
            end
            -- golpe al mago
            local alcanze = (som.tipo == "gigante") and 4.6 or 3.4
            if bestP and bestD and bestD <= alcanze and SE.players[bestP] and SE.players[bestP].vivo then
              local now = os.clock()
              if now - (som.golpeEn or 0) >= 0.9 then
                som.golpeEn = now
                local hum = bestP.Character and bestP.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                  hum:TakeDamage((som.tipo == "gigante") and 20 or ((som.tipo == "raider") and 10 or 8))
                end
              end
            end
            -- el fuego las quema si entran al campamento
            if SE.llama > 25 and toFire < 6 then
              danarSombra(som, 30, fuegoPos, nil)
            end
          end
        end
      end
    end
  end
end
task.spawn(bucleSombras)

-- Recursos: recoger con el toque
local function conectarToques()
  local function jugadorDe(hit)
    local char = hit and hit.Parent
    local player = char and Players:GetPlayerFromCharacter(char)
    return player
  end
  for _, nodo in ipairs(lenaNodos) do
    nodo.part.Touched:Connect(function(hit)
      if not SE.on or os.clock() < nodo.listoEn then
        return
      end
      local player = jugadorDe(hit)
      if player and jugadorEnPartida(player) and SE.players[player].vivo then
        SE.players[player].lenos += 1
        nodo.listoEn = os.clock() + 25
        nodo.part.Transparency = 1
        nodo.part.CanCollide = false
        task.delay(25, function()
          nodo.part.Transparency = 0
          nodo.part.CanCollide = false
        end)
      end
    end)
  end
  for _, fr in ipairs(fresas) do
    local pr = Instance.new("ProximityPrompt")
    pr.Name = "RecogerFresa"
    pr.ActionText = "Recoger"
    pr.ObjectText = "Fresa"
    pr.HoldDuration = 0
    pr.MaxActivationDistance = 9
    pr.RequiresLineOfSight = false
    pr.Parent = fr.berry
    fr.prompt = pr
    pr.Triggered:Connect(function(player)
      recogerFresaDelArbusto(player, fr)
    end)
  end
  deposito.Touched:Connect(function(hit)
    if not SE.on then
      return
    end
    local player = jugadorDe(hit)
    if player and jugadorEnPartida(player) and SE.players[player].vivo then
      local d = SE.players[player]
      if d.lenos > 0 then
        SE.llama = math.min(100, SE.llama + d.lenos * 18)
        d.lenos = 0
        updateFireBoard()
      end
    end
  end)
  -- jaulas: tocar al aprendiz cuando la jaula esta abierta
  for ci, j in ipairs(jaulas) do
    for _, pp in ipairs(j.fig:GetChildren()) do
      if pp:IsA("BasePart") then
        pp.Touched:Connect(function(hit)
          if not SE.on or not j.libre or j.rescatado then
            return
          end
          local player = jugadorDe(hit)
          if player and jugadorEnPartida(player) and SE.players[player].vivo then
            j.rescatado = true
            SE.aprendices += 1
            j.label.Text = "Aprendiz rescatado"
            -- el aprendiz se muda junto a la fogata
            local ang = ci * (math.pi / 2) + 0.4
            local dest = Vector3.new(fuegoPos.X + math.cos(ang) * 11, fuegoPos.Y, fuegoPos.Z + math.sin(ang) * 11)
            for _, f2 in ipairs(j.fig:GetChildren()) do
              local off = f2.CFrame.Position - j.pos
              f2.CFrame = CFrame.new(dest + Vector3.new(off.X, off.Y - 0.8, off.Z)) * CFrame.Angles(0, -ang - math.pi / 2, 0)
            end
            updateFireBoard()
            updateCircleBoard()
          end
        end)
      end
    end
  end
  -- Cofres: toque en la base (hambre o lenos, cada 30 s)
  for _, cof in ipairs(cofres) do
  if cof.base then
    cof.base.Touched:Connect(function(hit)
      if not SE.on or os.clock() < cof.listo then
        return
      end
      local char = hit and hit.Parent
      local player = char and Players:GetPlayerFromCharacter(char)
      if player and jugadorEnPartida(player) and SE.players[player].vivo then
        cof.listo = os.clock() + 30
        if math.random() < 0.5 then
          SE.players[player].lenos += 2
        else
          SE.players[player].hambre = math.min(100, SE.players[player].hambre + 40)
        end
      end
    end)
  end
  end
end

local function prepararMundo()
  SE.llama = 100
  SE.noche = 0
  SE.aprendices = 0
  for i = #SE.sombras, 1, -1 do
    if SE.sombras[i].model then
      SE.sombras[i].model:Destroy()
    end
    table.remove(SE.sombras, i)
  end
  for ci, j in ipairs(jaulas) do
    j.libre = false
    j.rescatado = false
    for _, bar in ipairs(j.barrotes) do
      bar.Transparency = 0
      bar.CanCollide = false
    end
    j.label.Text = "Aprendiz atrapado: vence a sus guardianes"
    -- figura de vuelta en la jaula
    for _, pp in ipairs(j.fig:GetChildren()) do
      local offY = ({ Piernas = 0.55, Tunica = 1.95, Cabeza = 3.3, Sombrero = 4.05 })[pp.Name] or 1
      pp.CFrame = CFrame.new(j.pos.X, j.pos.Y + 0.8 + offY, j.pos.Z)
    end
    -- guardianes de la jaula
    crearSombra(j.pos + Vector3.new(-7, 3.5, -7), true, ci)
    crearSombra(j.pos + Vector3.new(7, 3.5, -7), true, ci)
  end
  updateFireBoard()
end

local function iniciarPartida(lista)
  SE.on = true
  SE.players = {}
  prepararMundo()
  local k = 0
  for _, player in ipairs(lista) do
    if player and player.Parent then
      k += 1
      SE.players[player] = { vivo = true, lenos = 0, hambre = 100, saco = {}, sacoEnMano = false, toolFresa = nil, toolSaco = nil }
      darSacoMago(player)
      local char = player.Character
      if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
          hum.Health = hum.MaxHealth
          hum.Died:Connect(function()
            marcarMuerto(player)
          end)
        end
        if hrp then
          local ang = (k / math.max(#lista, 1)) * math.pi * 2
          hrp.CFrame = CFrame.new(fuegoPos + Vector3.new(math.cos(ang) * 9, 1.5, math.sin(ang) * 9))
        end
      end
    end
  end
  updateCircleBoard()
  task.spawn(cicloPartida)
end

-- Circulo del lobby: quien este dentro cuando la cuenta llega a 0, entra
task.spawn(function()
  while true do
    task.wait(0.3)
    if not SE.on then
      local dentro = {}
      for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
          local flat = Vector2.new(hrp.Position.X, hrp.Position.Z)
          if flat.Magnitude <= 12.5 and hrp.Position.Y > 1 and hrp.Position.Y < 14 then
            dentro[player] = true
          end
        end
      end
      SE.enCirculo = dentro
      local n = 0
      for _ in pairs(dentro) do
        n += 1
      end
      if n >= 1 and SE.cuentaAtras <= 0 then
        SE.cuentaAtras = 12
      end
      if SE.cuentaAtras > 0 then
        SE.cuentaAtras -= 0.3
        if SE.cuentaAtras <= 0 then
          local lista = {}
          for player, _ in pairs(dentro) do
            table.insert(lista, player)
          end
          if #lista >= 1 then
            iniciarPartida(lista)
          end
        end
      end
      updateCircleBoard()
    end
  end
end)

--===========================================================
-- PLAYER EVENTS
--===========================================================
Players.PlayerAdded:Connect(function(player)
  player.CharacterAdded:Connect(function(char)
    castCd[player] = nil
    if jugadorEnPartida(player) and SE.players[player].vivo then
      -- reaparecio estando vivo en el bosque: cuenta como caido
      marcarMuerto(player)
      return
    end
    -- si no esta en partida, el NUCLEO ya lo mando al lobby
  end)
end)

Players.PlayerRemoving:Connect(function(player)
  if SE.players[player] then
    SE.players[player] = nil
    if SE.on and vivosEnPartida() <= 0 then
      finPartida(false)
    end
  end
  SE.enCirculo[player] = nil
  castCd[player] = nil
end)

-- ANIMADOR DE LA LLAMA: pulso, lengua que sube y se recoge, luz que tiembla
task.spawn(function()
  local t = 0
  while true do
    task.wait(0.1)
    t += 0.1
    if llamaParts and llamaBase and fuegoPos then
      local viva = SE.llama > 0
      local f = viva and (0.35 + (SE.llama / 100) * 0.85) or 0.02
      for i, fp in ipairs(llamaParts) do
        local bse = llamaBase[i]
        local pulso = 1 + 0.14 * math.sin(t * (5.2 + i * 1.9) + i * 2.4) + 0.06 * math.sin(t * 11.7 + i * 0.9)
        local subida = 0
        if i == 3 then
          -- la lengua de arriba sube y se recoge, como fuego de verdad
          local fase = (t * 0.55) % 1
          subida = fase * 1.5 * f
          pulso *= (1 - fase * 0.45)
        end
        fp.Size = Vector3.new(bse.X * f * pulso, bse.Y * f * (1.06 - 0.1 * math.sin(t * 7 + i)), bse.Z * f * pulso)
        fp.CFrame = CFrame.new(
          fuegoPos.X + 0.1 * math.sin(t * 2.6 + i * 1.7),
          fuegoPos.Y + 0.7 + (i - 1) * 1.4 * f + subida,
          fuegoPos.Z + 0.08 * math.cos(t * 3.1 + i)
        ) * CFrame.Angles(0, t * (0.5 + i * 0.13), 0)
      end
      if llamaLight then
        llamaLight.Brightness = viva and (2.0 + (SE.llama / 100) * 0.9 + 0.35 * math.sin(t * 9.3) + 0.18 * math.sin(t * 23.7)) or 0
        llamaLight.Range = (16 + SE.llama * 0.2) * (0.95 + 0.05 * math.sin(t * 6.1))
      end
      if chispasFuego then
        chispasFuego.Enabled = viva
      end
    end
  end
end)

task.spawn(function()
  local intentos = 0
  while not escanearBosque() do
    intentos += 1
    if intentos == 200 then
      print("[Avada] Todavia no aparece el bosque: falta poner el archivo BOSQUE")
    end
    task.wait(0.25)
  end
  conectarToques()
  updateFireBoard()
end)

-- cartel del circulo (lo construye BOSQUE dentro del lobby)
task.spawn(function()
  local t1 = os.clock()
  while os.clock() - t1 < 40 and not circleStatus do
    local lm = workspace:FindFirstChild("IslandLobby")
    local anch = lm and lm:FindFirstChild("CircleBoardAnchor")
    local gui = anch and anch:FindFirstChild("CircleBoard")
    if gui then
      circleTitle = gui:FindFirstChild("Title")
      circleStatus = gui:FindFirstChild("Status")
      circleSub = gui:FindFirstChild("Sub")
    end
    if not circleStatus then
      task.wait(0.3)
    end
  end
  updateCircleBoard()
end)

print("[Avada] Bosque Prohibido listo: supervivencia de magos en 7 noches")

-- FIN PARTIDA
