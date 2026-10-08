-- Archivo PARTIDA: la supervivencia en el Bosque Prohibido (llama, hambre, lobos, rescates, 7 noches).
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
  nivel = 1,
  fogataXP = 0,
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
local Bosque, fuegoPos, deposito, llamaParts, llamaBase, llamaLight, anilloSeguro, chispasFuego, paredes
local jaulas, jaulasPos, moras, hongos, cofres, fireStatus = {}, {}, {}, {}, {}, nil
local bosqueListo = false
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
    paredes = {}
    moras, hongos, cofres, jaulas, jaulasPos = {}, {}, {}, {}, {}
    local morasPorClave = {}
    local hongosPorId = {}
    for _, d in ipairs(Bosque:GetDescendants()) do
      if d:IsA("BasePart") then
        local g = d:GetAttribute("Grupo")
        if g == "Llama" then
          llamaParts[d:GetAttribute("Idx") or 1] = d
        elseif g == "Anillo" then
          table.insert(anilloSeguro, { part = d, ang = d:GetAttribute("Ang") or 0 })
        elseif g == "Pared" then
          table.insert(paredes, { part = d, ang = d:GetAttribute("Ang") or 0, tapa = d:GetAttribute("Tapa") == true })
        end
        if d:GetAttribute("Rol") == "Deposito" then
          deposito = d
        elseif d:GetAttribute("Rol") == "FireAnchor" then
          fireBoardAnchor = d
          fuegoPos = d.Position - Vector3.new(0, 11, 0)
        end
        local tipo = d:GetAttribute("Tipo")
        if tipo == "Mora" or tipo == "MoraCorona" or tipo == "MoraRabito" then
          local gi = d:GetAttribute("Arbusto") or 1
          local mj = d:GetAttribute("MoraId") or 1
          local clave = gi .. "/" .. mj
          morasPorClave[clave] = morasPorClave[clave] or {}
          morasPorClave[clave][tipo] = d
        elseif tipo == "Cofre" then
          table.insert(cofres, { pos = d.Position, listo = 0, base = d })
        elseif tipo == "Hongo" then
          local hid = d:GetAttribute("HongoId") or 0
          hongosPorId[hid] = hongosPorId[hid] or { partes = {} }
          hongosPorId[hid].cap = d
        end
        local hid2 = d:GetAttribute("HongoId")
        if hid2 then
          hongosPorId[hid2] = hongosPorId[hid2] or { partes = {} }
          table.insert(hongosPorId[hid2].partes, d)
        end
      elseif d:IsA("Model") and d:GetAttribute("Jaula") then
        -- se completa abajo junto con su ancla
      end
    end
    for _, conj in pairs(morasPorClave) do
      if conj.Mora then
        table.insert(moras, { mora = conj.Mora, corona = conj.MoraCorona, rabito = conj.MoraRabito, disponible = true })
      end
    end
    for _, hg in pairs(hongosPorId) do
      if hg.cap then
        hg.disponible = true
        table.insert(hongos, hg)
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

  bosqueListo = true
  return true
end

-- Archivo PARTIDA: la supervivencia en el Bosque Prohibido (noche, llama, hambre, lobos, rescates).
local Players = game:GetService("Players")
local LOBBY_SPAWN = Vector3.new(0, 6, 0)

-- CARTELES
--===========================================================
local function updateCircleBoard()
  if not (circleTitle and circleStatus and circleSub) then
    return -- el cartel aun no aparece: el hilo del circulo sigue vivo
  end
  if not bosqueListo then
    local bq = workspace:FindFirstChild("BosqueProhibido")
    circleTitle.Text = "AVADA"
    if not bq then
      circleStatus.Text = "EL BOSQUE NO EXISTE EN EL MAPA"
      circleSub.Text = "El Script BOSQUE no esta corriendo"
    else
      circleStatus.Text = "BOSQUE CARGANDO: " .. tostring(bq:GetAttribute("Etapa") or "inicio")
      circleSub.Text = "Si no avanza, mandame una captura"
    end
    return
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
  if fireStatus and lobosFaltan and SE.on then
    fireStatus.Text = "FALTAN LOS LOBOS: pega el Script LOBOS"
  elseif fireStatus then
    fireStatus.Text = "Llama "
    .. math.floor(SE.llama)
    .. "% - Fogata Nivel "
    .. (SE.nivel or 1)
    .. " - Noche "
    .. math.max(SE.noche, 1)
    .. "/"
    .. NOCHES_META
    .. " - Aprendices "
    .. SE.aprendices
    .. "/4"
  end
  -- el tamano y el baile de la llama los lleva el animador (abajo);
  -- aqui solo respira el anillo seguro en el suelo
  local radio = 10 + (SE.nivel or 1) * 2.5 + SE.llama * 0.09
  for _, sd in ipairs(anilloSeguro) do
    sd.part.CFrame = CFrame.new(fuegoPos.X, fuegoPos.Y + 0.12, fuegoPos.Z) * CFrame.Angles(0, -sd.ang, 0) * CFrame.new(0, 0, radio)
  end
end

local function radioSeguro()
  return 10 + (SE.nivel or 1) * 2.5 + SE.llama * 0.09
end

-- Fogata por NIVELES (como 99 Noches): depositar lenos la hace subir;
-- cada nivel el anillo seguro crece y la PARED del mapa se expande,
-- abriendo mas bosque para explorar. A cambio la llama dura mas.
local NIVEL_MAX = 6
local function lenosParaNivel(n)
  return 4 + n * 2
end
local function paredRadio()
  return 164 + (SE.nivel or 1) * 11
end
local function moverPared()
  if not fuegoPos then
    return
  end
  local R = paredRadio()
  for _, pw in ipairs(paredes or {}) do
    local px = fuegoPos.X + math.cos(pw.ang) * R
    local pz = fuegoPos.Z + math.sin(pw.ang) * R
    local y = pw.tapa and 20.4 or 11
    pw.part.CFrame = CFrame.new(Vector3.new(px, y, pz), Vector3.new(fuegoPos.X, y, fuegoPos.Z))
  end
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
-- OBJETOS: comida en la mano (moras y hongos), SACO MAGICO (x/5)
-- y acciones como en 99 Noches: Comer, Desgarrar, Tienda, Desalmacenar
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
local RE_SFX = remotoBosque("AvadaSonidos")
local SACO_MAX = 5
local COMIDA = { Mora = 30, Hongo = 40 } -- cuanto de hambre devuelve cada una

local function sonar(player, nombre)
  if player and player.Parent then
    pcall(function()
      RE_SFX:FireClient(player, nombre)
    end)
  end
end
local function sonarTodos(nombre)
  for pl, _ in pairs(SE.players) do
    sonar(pl, nombre)
  end
end

local function sincronizaUI(player)
  local d = SE.players[player]
  if not (player and player.Parent) then
    return
  end
  -- el saco en la mano se comprueba mirando al personaje directamente:
  -- asi el contador X/5 nunca depende de que un aviso llegue o no
  local sacoEnLaMano = false
  local chS = player.Character
  if chS and chS:FindFirstChild("Saco mágico") then
    sacoEnLaMano = true
  end
  if d then
    d.sacoEnMano = sacoEnLaMano
  end
  pcall(function()
    RE_UI:FireClient(player, {
      enPartida = SE.on and d ~= nil,
      hambre = d and math.floor(d.hambre or 100) or 100,
      mano = (d and d.enMano ~= nil) or false,
      saco = d and #(d.saco or {}) or 0,
      sacoMax = SACO_MAX,
      sacoEnMano = sacoEnLaMano,
      noche = SE.noche,
      fase = SE.fase,
      lenos = d and d.lenos or 0,
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

local function soldarA(tool, handle, parte, off)
  parte.CFrame = handle.CFrame * CFrame.new(off)
  parte.Parent = tool
  local w = Instance.new("WeldConstraint")
  w.Part0 = handle
  w.Part1 = parte
  w.Parent = parte
  return parte
end

-- El Boletus del dueno en miniatura: mismas piezas (tallo por segmentos
-- y cupula de anillos) para la mano y para cuando cae al suelo
local HB = {
  ALT_T = 9, RAD_S = 7.6, ALT_S = 4.6,
  PERFIL = {
    { 0.00, 1.90 }, { 0.03, 2.55 }, { 0.08, 3.05 },
    { 0.16, 2.80 }, { 0.40, 2.70 }, { 0.70, 2.55 }, { 1.00, 2.15 },
  },
  ARRIBA = Color3.fromRGB(226, 202, 148),
  ABAJO = Color3.fromRGB(188, 150, 98),
  TOPE = Color3.fromRGB(140, 82, 52),
  BORDE = Color3.fromRGB(190, 135, 92),
  POROS = Color3.fromRGB(228, 208, 152),
}
local function radioTalloH(t)
  local pf = HB.PERFIL
  for i = 1, #pf - 1 do
    local p0, p1 = pf[i], pf[i + 1]
    if t <= p1[1] then
      local k = math.clamp((t - p0[1]) / (p1[1] - p0[1]), 0, 1)
      return p0[2] + (p1[2] - p0[2]) * (k * k * (3 - 2 * k))
    end
  end
  return pf[#pf][2]
end
-- devuelve piezas { nombre, size, y (local), color, material } del Boletus
local function piezasBoletus(escala, segmentos, anillos)
  local piezas = {}
  local n = segmentos or 10
  for i = 1, n do
    local tm = ((i - 1) / n + i / n) / 2
    local radio = radioTalloH(tm)
    table.insert(piezas, {
      nombre = "TalloSeg" .. i,
      size = Vector3.new(HB.ALT_T / n + 0.05, radio * 2, radio * 2) * escala,
      y = tm * HB.ALT_T * escala,
      color = HB.ABAJO:Lerp(HB.ARRIBA, math.clamp(tm * 1.4, 0, 1)),
      material = Enum.Material.Fabric,
    })
  end
  local base = HB.ALT_T * 0.88
  table.insert(piezas, { nombre = "Labio", size = Vector3.new(0.5, HB.RAD_S * 2, HB.RAD_S * 2) * escala, y = (base + 0.25) * escala, color = HB.BORDE, material = Enum.Material.Fabric })
  table.insert(piezas, { nombre = "Poros", size = Vector3.new(0.3, HB.RAD_S * 1.9, HB.RAD_S * 1.9) * escala, y = (base + 0.05) * escala, color = HB.POROS, material = Enum.Material.Sand })
  local an = anillos or 8
  local angMax = math.rad(86)
  for i = 1, an do
    local a0 = (i - 1) / an * angMax
    local a1 = i / an * angMax
    local y0 = HB.ALT_S * math.sin(a0)
    local y1 = HB.ALT_S * math.sin(a1)
    local hAnillo = math.max(y1 - y0, 0.2) + 0.08
    local radio = HB.RAD_S * math.cos((a0 + a1) / 2) ^ 0.85
    local color = HB.BORDE:Lerp(HB.TOPE, ((i - 1) / (an - 1)) ^ 0.6)
    table.insert(piezas, {
      nombre = "Cupula" .. i,
      size = Vector3.new(hAnillo, radio * 2, radio * 2) * escala,
      y = (base + 0.5 + (y0 + y1) / 2) * escala,
      color = color,
      material = Enum.Material.Fabric,
    })
  end
  return piezas
end
local function discoEn(parent, pieza, cfBase)
  local pt = parteDeTool(pieza.nombre, pieza.size, cfBase * CFrame.new(0, pieza.y, 0) * CFrame.Angles(0, 0, math.rad(90)), pieza.color, pieza.material)
  pt.Shape = Enum.PartType.Cylinder
  pt.Parent = parent
  return pt
end

-- La comida en la mano: una mora azul con corona oscura, o el Boletus mini
local function darEnMano(player, tipo)
  local d = SE.players[player]
  if not d or d.enMano then
    return
  end
  local tool = Instance.new("Tool")
  tool.Name = tipo
  tool.CanBeDropped = false
  local h
  if tipo == "Hongo" then
    tool.ToolTip = "Tu Boletus del bosque: se come"
    local piezas = piezasBoletus(0.085, 10, 8)
    local baseP = piezas[1]
    -- bolita en la base del tallo como agarre: el Boletus queda DERECHO
    h = parteDeTool("Handle", Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 3, 0), baseP.color, baseP.material)
    h.Shape = Enum.PartType.Ball
    h.Parent = tool
    local baseY = baseP.y
    for i = 1, #piezas do
      local pz = piezas[i]
      local extra = parteDeTool(pz.nombre, pz.size, CFrame.new(0, 3 + (pz.y - baseY), 0) * CFrame.Angles(0, 0, math.rad(90)), pz.color, pz.material)
      extra.Shape = Enum.PartType.Cylinder
      extra.Parent = tool
      local w = Instance.new("WeldConstraint")
      w.Part0 = h
      w.Part1 = extra
      w.Parent = extra
    end
  else
    tipo = "Mora"
    tool.ToolTip = "Mora del Bosque Prohibido"
    h = parteDeTool("Handle", Vector3.new(0.62, 0.6, 0.62), CFrame.new(0, 3, 0), Color3.fromRGB(52, 60, 118))
    h.Shape = Enum.PartType.Ball
    h.Parent = tool
    local corona = parteDeTool("MoraCorona", Vector3.new(0.1, 0.36, 0.36), CFrame.new(), Color3.fromRGB(22, 18, 38))
    corona.Shape = Enum.PartType.Cylinder
    corona.CFrame = h.CFrame * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
    corona.Parent = tool
    local wc = Instance.new("WeldConstraint")
    wc.Part0 = h
    wc.Part1 = corona
    wc.Parent = corona
  end
  tool.Parent = player:FindFirstChildOfClass("Backpack")
  d.enMano = { tipo = tipo, tool = tool }
  local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum then
    pcall(function()
      hum:EquipTool(tool)
    end)
  end
  sincronizaUI(player)
end

-- El saco de tela del dueno (Burlap): panza abultada y arrugada, boca
-- acampanada, cuerda crema con nudo y puntas colgando, asa curva.
-- Es el "Saco magico" que el jugador lleva en la mano.
local SC_ALTURA = 10.3
local SC_PERFIL = {
  { 0.00, 1.70 }, { 0.35, 2.90 }, { 1.20, 3.30 }, { 2.50, 3.55 },
  { 3.70, 3.70 }, { 5.00, 3.35 }, { 6.20, 3.00 }, { 7.00, 2.50 },
  { 7.60, 1.85 }, { 8.00, 1.65 }, { 8.50, 1.70 }, { 9.20, 2.00 },
  { 10.0, 2.30 }, { 10.3, 2.42 },
}
local SC_ASA = {
  Vector3.new(-1.5, 7.9, 0), Vector3.new(-2.1, 8.3, 0), Vector3.new(-2.6, 8.85, 0),
  Vector3.new(-3.3, 9.0, 0), Vector3.new(-3.9, 8.95, 0), Vector3.new(-4.4, 8.5, 0),
  Vector3.new(-4.8, 7.5, 0), Vector3.new(-5.1, 5.4, 0), Vector3.new(-5.0, 4.1, 0),
  Vector3.new(-4.7, 2.8, 0), Vector3.new(-4.1, 2.0, 0), Vector3.new(-3.0, 1.5, 0),
}
local SC_ARRIBA = Color3.fromRGB(176, 124, 92)
local SC_ABAJO = Color3.fromRGB(138, 90, 63)
local SC_ASA_C = Color3.fromRGB(122, 80, 55)
local SC_BOCA = Color3.fromRGB(88, 58, 41)
local SC_CUERDA_A = Color3.fromRGB(228, 208, 162)
local SC_CUERDA_B = Color3.fromRGB(204, 180, 134)

local function scRadio(y)
  for i = 1, #SC_PERFIL - 1 do
    local p0, p1 = SC_PERFIL[i], SC_PERFIL[i + 1]
    if y <= p1[1] then
      local k = math.clamp((y - p0[1]) / (p1[1] - p0[1]), 0, 1)
      return p0[2] + (p1[2] - p0[2]) * (k * k * (3 - 2 * k))
    end
  end
  return SC_PERFIL[#SC_PERFIL][2]
end
local function scVariar(color, v)
  return Color3.new(
    math.clamp(color.R + v, 0, 1),
    math.clamp(color.G + v * 0.85, 0, 1),
    math.clamp(color.B + v * 0.7, 0, 1)
  )
end
local function curvaSuaveSaco(puntos, sub)
  local salida = {}
  for i = 1, #puntos - 1 do
    local p0 = puntos[math.max(i - 1, 1)]
    local p1 = puntos[i]
    local p2 = puntos[i + 1]
    local p3 = puntos[math.min(i + 2, #puntos)]
    for t0 = 0, sub - 1 do
      local t = t0 / sub
      table.insert(salida, 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t ^ 2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t ^ 3))
    end
  end
  table.insert(salida, puntos[#puntos])
  return salida
end

-- piezas { nombre, size, cf (local), color, material } del saco
local function piezasSaco(escala, semilla)
  local azar = Random.new(semilla)
  local piezas = {}
  local function disco(nombre, y, altura, radio, color, material, dx, dz, incl)
    local c = CFrame.new((dx or 0) * escala, y * escala, (dz or 0) * escala)
    if incl then
      c = c * CFrame.Angles(incl.X, 0, incl.Z)
    end
    c = c * CFrame.Angles(0, 0, math.rad(90))
    table.insert(piezas, { nombre = nombre, size = Vector3.new(altura, radio * 2, radio * 2) * escala, cf = c, color = color, material = material })
  end
  local function segmento(nombre, a, b, grosor, color, material)
    local A, B = a * escala, b * escala
    local largo = (B - A).Magnitude
    table.insert(piezas, {
      nombre = nombre,
      size = Vector3.new(largo + 0.05 * escala, grosor * 2 * escala, grosor * 2 * escala),
      cf = CFrame.lookAt((A + B) / 2, B) * CFrame.Angles(0, math.rad(90), 0),
      color = color,
      material = material,
    })
  end
  -- cuerpo arrugado
  local n = 26
  for i = 1, n do
    local y0, y1 = (i - 1) / n * SC_ALTURA, i / n * SC_ALTURA
    local ym = (y0 + y1) / 2
    local radio = scRadio(ym)
    local peso = math.clamp(1 - (ym - 6) / 2, 0, 1)
    local dx = azar:NextNumber(-0.14, 0.14) * peso
    local dz = azar:NextNumber(-0.14, 0.14) * peso
    radio = radio * (1 + azar:NextNumber(-0.035, 0.035) * peso)
    local color = SC_ABAJO:Lerp(SC_ARRIBA, math.clamp(ym / SC_ALTURA * 1.2, 0, 1))
    disco("SacoCuerpo" .. i, ym, SC_ALTURA / n + 0.06, radio, scVariar(color, azar:NextNumber(-0.035, 0.035)), Enum.Material.Fabric, dx, dz)
  end
  disco("SacoBordeBoca", SC_ALTURA - 0.1, 0.22, 2.44, scVariar(SC_ARRIBA, 0.03), Enum.Material.Fabric)
  disco("SacoInterior", SC_ALTURA + 0.02, 0.08, 1.95, SC_BOCA, Enum.Material.Fabric)
  -- cuerda del cuello con nudo y puntas colgando
  for i, y in ipairs({ 7.75, 8.0, 8.25 }) do
    disco("SacoCuerda" .. i, y, 0.26, scRadio(y) + 0.14, (i % 2 == 0) and SC_CUERDA_B or SC_CUERDA_A, Enum.Material.Fabric, 0, 0,
      Vector3.new(math.rad(azar:NextNumber(-4, 4)), 0, math.rad(azar:NextNumber(-4, 4))))
  end
  local angNudo = math.rad(20)
  local rNudo = (scRadio(8.05) + 0.2) * escala
  table.insert(piezas, {
    nombre = "SacoNudo",
    size = Vector3.new(0.85, 0.75, 0.85) * escala,
    cf = CFrame.new(math.sin(angNudo) * rNudo, 8.05 * escala, math.cos(angNudo) * rNudo),
    color = SC_CUERDA_A,
    material = Enum.Material.Fabric,
    bola = true,
  })
  local function punta(nombre, yIni, yFin, aIni, aFin, grosor, pasos)
    local anterior
    for j = 0, pasos do
      local k = j / pasos
      local y = yIni + (yFin - yIni) * k
      local ang = math.rad(aIni + (aFin - aIni) * k) + math.sin(j * 0.9) * 0.04
      local r = scRadio(y) + 0.16
      local punto = Vector3.new(math.sin(ang) * r, y, math.cos(ang) * r)
      if anterior then
        segmento(nombre .. j, anterior, punto, grosor, (j % 2 == 0) and SC_CUERDA_A or SC_CUERDA_B, Enum.Material.Fabric)
      end
      anterior = punto
    end
  end
  punta("SacoPuntaA", 7.9, 4.3, 16, 40, 0.13, 9)
  punta("SacoPuntaB", 7.9, 3.4, 24, 30, 0.13, 10)
  -- el asa curva
  local curva = curvaSuaveSaco(SC_ASA, 3)
  for i = 1, #curva - 1 do
    segmento("SacoAsa" .. i, curva[i], curva[i + 1], 0.32, scVariar(SC_ASA_C, azar:NextNumber(-0.025, 0.025)), Enum.Material.Fabric)
  end
  return piezas
end

local function darSacoMago(player)
  local d = SE.players[player]
  if not d or d.toolSaco then
    return
  end
  local tool = Instance.new("Tool")
  tool.Name = "Saco mágico"
  tool.ToolTip = "Tu saco de tela: guarda hasta " .. SACO_MAX .. " cosas"
  tool.CanBeDropped = false
  local piezas = piezasSaco(0.19, 7674 + (player.UserId % 97))
  -- se agarra por una bolita dentro del cuello: sin giro, para que el
  -- saco quede DERECHO en la mano (colgando del cuello)
  local h = parteDeTool("Handle", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 8.0 * 0.19, 0), Color3.fromRGB(176, 124, 92), Enum.Material.Fabric)
  h.Shape = Enum.PartType.Ball
  h.Parent = tool
  for i = 1, #piezas do
    local pz = piezas[i]
    local extra = parteDeTool(pz.nombre, pz.size, pz.cf, pz.color, pz.material)
    extra.Shape = pz.bola and Enum.PartType.Ball or Enum.PartType.Cylinder
    extra.Parent = tool
    local w = Instance.new("WeldConstraint")
    w.Part0 = h
    w.Part1 = extra
    w.Parent = extra
  end
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

local function comerEnMano(player)
  local d = SE.players[player]
  if not d or not d.enMano then
    return
  end
  local valor = COMIDA[d.enMano.tipo] or 25
  d.enMano.tool:Destroy()
  d.enMano = nil
  d.hambre = math.min(100, d.hambre + valor)
  sonar(player, "Comer")
  sincronizaUI(player)
end

local function comerDesdeSaco(player)
  local d = SE.players[player]
  if not d or #d.saco <= 0 then
    return
  end
  local tipo = table.remove(d.saco, 1)
  d.hambre = math.min(100, d.hambre + (COMIDA[tipo] or 25))
  sonar(player, "Comer")
  sincronizaUI(player)
end

-- Desgarrar: lo de la mano cae al suelo y cualquiera lo puede recoger
local entregarComida -- se define mas abajo; este aviso la hace visible aqui

-- Suelta una comida en el suelo frente al jugador: ahi queda guardada
-- (en la casa/fogata) y se recoge TOCANDOLA, sin letreros de recoger.
local function soltarAlSuelo(player, tipo)
  local char = player.Character
  local hrp = char and char:FindFirstChild("HumanoidRootPart")
  if hrp then
    local pos = hrp.Position + hrp.CFrame.LookVector * 4
    local suelta = Instance.new("Model")
    suelta.Name = tipo .. "Suelta"
    local ancla
    if tipo == "Hongo" then
      local cfSuelo = CFrame.new(pos.X, 2.0, pos.Z)
      for _, pz in ipairs(piezasBoletus(0.16, 12, 9)) do
        local pt = discoEn(suelta, pz, cfSuelo)
        pt.Anchored = true
        ancla = ancla or pt
      end
    else
      local fb = parteDeTool("Mora", Vector3.new(0.58, 0.56, 0.58), CFrame.new(pos.X, 2.45, pos.Z), Color3.fromRGB(52, 60, 118))
      fb.Shape = Enum.PartType.Ball
      fb.Anchored = true
      fb.Parent = suelta
      local corona = parteDeTool("MoraCorona", Vector3.new(0.09, 0.34, 0.34), CFrame.new(pos.X, 2.78, pos.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(22, 18, 38))
      corona.Shape = Enum.PartType.Cylinder
      corona.Anchored = true
      corona.Parent = suelta
      ancla = fb
    end
    local function recogerSuelta(otro)
      if jugadorEnPartida(otro) and entregarComida(otro, tipo) then
        suelta:Destroy()
      end
    end
    -- zona de toque grande e invisible sobre lo soltado: con tap o
    -- pisandola se levanta, sin punteria fina
    local zonaS = Instance.new("Part")
    zonaS.Name = "ZonaToque"
    zonaS.Size = Vector3.new(2.6, 2.8, 2.6)
    zonaS.CFrame = CFrame.new(pos.X, 3.1, pos.Z)
    zonaS.Transparency = 1
    zonaS.CanCollide = false
    zonaS.CanTouch = true
    zonaS.Anchored = true
    zonaS.Parent = suelta
    -- marco blanco que marca lo que esta tirado en el piso
    local marca = Instance.new("Highlight")
    marca.FillColor = Color3.new(1, 1, 1)
    marca.FillTransparency = 0.88
    marca.OutlineColor = Color3.new(1, 1, 1)
    marca.OutlineTransparency = 0.1
    marca.DepthMode = Enum.HighlightDepthMode.Occluded
    marca.Parent = suelta
    local cdS = Instance.new("ClickDetector")
    cdS.MaxActivationDistance = 14
    cdS.Parent = zonaS
    cdS.MouseClick:Connect(recogerSuelta)
    local ultimoToqueS = 0
    local nacioEn = os.clock()
    zonaS.Touched:Connect(function(hit)
      local ahora = os.clock()
      if ahora - nacioEn < 1.2 or ahora - ultimoToqueS < 0.35 then
        return
      end
      ultimoToqueS = ahora
      local modelo = hit and hit:FindFirstAncestorOfClass("Model")
      local pl = modelo and Players:GetPlayerFromCharacter(modelo)
      if pl then
        recogerSuelta(pl)
      end
    end)
    suelta.Parent = workspace
  end
end

local function desgarrarEnMano(player)
  local d = SE.players[player]
  if not d or not d.enMano then
    return
  end
  local tipo = d.enMano.tipo
  d.enMano.tool:Destroy()
  d.enMano = nil
  soltarAlSuelo(player, tipo)
  sincronizaUI(player)
end

local function guardarEnSaco(player) -- boton "Tienda": mete lo de la mano al saco
  local d = SE.players[player]
  if not d or not d.enMano or #d.saco >= SACO_MAX then
    return
  end
  local tipo = d.enMano.tipo
  d.enMano.tool:Destroy()
  d.enMano = nil
  table.insert(d.saco, tipo)
  sonar(player, "Guardar")
  sincronizaUI(player)
end

local function desalmacenar(player) -- saca una comida del saco y cae al suelo
  local d = SE.players[player]
  if not d or #d.saco <= 0 then
    return
  end
  local tipo = table.remove(d.saco)
  soltarAlSuelo(player, tipo)
  sincronizaUI(player)
end

local function limpiarObjetos(player)
  local d = SE.players[player]
  if not d then
    return
  end
  if d.enMano then
    d.enMano.tool:Destroy()
    d.enMano = nil
  end
  if d.toolSaco then
    d.toolSaco:Destroy()
    d.toolSaco = nil
  end
  d.saco = {}
  d.sacoEnMano = false
end

-- Como en 99 Noches: lo que tocas entra a tu mano si esta libre, y si
-- ya llevas algo (o el saco puesto), entra directo al saco si hay hueco
entregarComida = function(player, tipo)
  local d = SE.players[player]
  if not d or not d.vivo then
    return false
  end
  if not d.enMano then
    local char = player.Character
    if char and char:FindFirstChild("Saco mágico") then
      -- con el saco puesto: tocar algo lo guarda directo en el saco
      if #d.saco < SACO_MAX then
        table.insert(d.saco, tipo)
        sonar(player, "Recoger")
        sincronizaUI(player)
        return true
      end
      return false
    end
    darEnMano(player, tipo)
    sonar(player, "Recoger")
    sincronizaUI(player)
    return true
  end
  if #d.saco < SACO_MAX then
    table.insert(d.saco, tipo)
    sonar(player, "Recoger")
    sincronizaUI(player)
    return true
  end
  return false
end

local function recogerMoraDelArbusto(player, fr)
  if not fr.disponible or not jugadorEnPartida(player) then
    return
  end
  if not entregarComida(player, "Mora") then
    return
  end
  fr.disponible = false
  for _, parte in ipairs({ fr.mora, fr.corona, fr.rabito }) do
    if parte then
      parte.Transparency = 1
    end
  end
  if fr.prompt then
    fr.prompt.Enabled = false
  end
  task.delay(18, function()
    fr.disponible = true
    for _, parte in ipairs({ fr.mora, fr.corona, fr.rabito }) do
      if parte and parte.Parent then
        parte.Transparency = 0
      end
    end
    if fr.prompt then
      fr.prompt.Enabled = true
    end
  end)
end

-- Rebrote como en 99 Noches: lo que recoges vuelve a salir en OTRO
-- sitio del mapa, asi el bosque nunca se queda sin comida ni lena.
local function posRebrote()
  local a = math.random() * math.pi * 2
  local r = 45 + math.random() * 150
  return Vector3.new(FC.X + math.cos(a) * r, 2.0, FC.Z + math.sin(a) * r)
end

-- Los arboles de cristales dan lena: tocas el tronco (o le das tap)
-- y sale un leno para tu cuenta; el arbol vuelve a dar a los 25 s.
-- Nada de madera tirada por el suelo.
local arbolesListos = false
local arbolesZona = {}
local function tocarArbol(player, arb)
  if not arb or os.clock() < (arb.listoEn or 0) then
    return
  end
  if not (SE.on and jugadorEnPartida(player) and SE.players[player].vivo) then
    return
  end
  arb.listoEn = os.clock() + 25
  SE.players[player].lenos += 1
  sonar(player, "Lena")
  sincronizaUI(player)
end
local function conectarArboles()
  if arbolesListos or not Bosque then
    return arbolesListos
  end
  if Bosque:GetAttribute("ArbolesListos") ~= true then
    return false
  end
  for _, modelo in ipairs(Bosque:GetChildren()) do
    if modelo:IsA("Model") and string.match(modelo.Name, "^ArbolCristal%d+$") then
      local raiz = modelo:FindFirstChild("Root", true)
      if raiz and raiz:IsA("BasePart") then
        local arb = { listoEn = 0 }
        local zona = Instance.new("Part")
        zona.Name = "ZonaArbol"
        zona.Shape = Enum.PartType.Cylinder
        zona.Size = Vector3.new(10, 9, 9)
        zona.CFrame = CFrame.new(raiz.Position.X, 6, raiz.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
        zona.Transparency = 1
        zona.CanCollide = false
        zona.CanTouch = true
        zona.Anchored = true
        zona.Parent = workspace
        table.insert(arbolesZona, zona)
        local cd = Instance.new("ClickDetector")
        cd.MaxActivationDistance = 16
        cd.Parent = zona
        cd.MouseClick:Connect(function(player)
          tocarArbol(player, arb)
        end)
        local ultimoToqueA = 0
        zona.Touched:Connect(function(hit)
          local ahora = os.clock()
          if ahora - ultimoToqueA < 0.35 then
            return
          end
          ultimoToqueA = ahora
          local modeloChar = hit and hit:FindFirstAncestorOfClass("Model")
          local player = modeloChar and Players:GetPlayerFromCharacter(modeloChar)
          if player then
            tocarArbol(player, arb)
          end
        end)
      end
    end
  end
  arbolesListos = true
  print("[Avada] Arboles listos para dar lena: " .. #arbolesZona)
  return true
end
task.spawn(function()
  while not conectarArboles() do
    task.wait(1)
  end
end)

local function recogerHongo(player, hg)
  if not hg.disponible or not jugadorEnPartida(player) then
    return
  end
  if not entregarComida(player, "Hongo") then
    return
  end
  hg.disponible = false
  if hg.zona then
    hg.zona.CanQuery = false
  end
  for _, parte in ipairs(hg.partes) do
    if parte then
      parte.Transparency = 1
      parte.CanCollide = false
      parte.CanQuery = false
    end
  end
  if hg.prompt then
    hg.prompt.Enabled = false
  end
  task.delay(25, function()
    -- el hongo REBROTA en otro sitio del mapa
    if hg.cap and hg.cap.Parent then
      local destino = posRebrote()
      local d = Vector3.new(destino.X - hg.cap.Position.X, 0, destino.Z - hg.cap.Position.Z)
      for _, parte in ipairs(hg.partes) do
        if parte and parte.Parent then
          parte.CFrame = parte.CFrame + d
        end
      end
      if hg.zona and hg.zona.Parent then
        hg.zona.CFrame = hg.zona.CFrame + d
      end
    end
    hg.disponible = true
    if hg.zona then
      hg.zona.CanQuery = true
    end
    for _, parte in ipairs(hg.partes) do
      if parte and parte.Parent then
        parte.Transparency = 0
        parte.CanCollide = true
        parte.CanQuery = true
      end
    end
    if hg.prompt then
      hg.prompt.Enabled = true
    end
  end)
end

RE_ACC.OnServerEvent:Connect(function(player, accion)
  if not jugadorEnPartida(player) or not SE.players[player].vivo then
    return
  end
  if accion == "Comer" then
    if SE.players[player].enMano then
      comerEnMano(player)
    else
      comerDesdeSaco(player)
    end
  elseif accion == "Desgarrar" then
    desgarrarEnMano(player)
  elseif accion == "Tienda" then
    guardarEnSaco(player)
  elseif accion == "Desalmacenar" then
    desalmacenar(player)
  end
end)

-- La Fogata Magica (fogata nueva del dueno): encendida mientras la
-- llama tenga nivel; al llegar a 0 se apaga sola (attribute Lit)
local fogataModelo
local function sincronizarFogata()
  if not fogataModelo or not fogataModelo.Parent then
    fogataModelo = workspace:FindFirstChild("FogataMagica")
  end
  if fogataModelo then
    fogataModelo:SetAttribute("Lit", SE.llama > 0)
  end
end
task.spawn(function()
  while true do
    task.wait(0.5)
    sincronizarFogata()
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

-- LOBOS SOMBRÍOS (los enemigos de la noche: el lobo del dueno del
-- juego, archivo LOBOS; PARTIDA solo lo invoca al caer la noche y
-- vigila las reglas del bosque: el fuego quema y el amanecer borra)
--===========================================================
local function llamarEsencias(player, cantidad)
  local bf = game:GetService("ServerScriptService"):FindFirstChild("AvadaEsencias")
  if bf then
    pcall(function()
      bf:Invoke("sumar", player, cantidad)
    end)
  end
end

local lobosFaltan = false
local loboAvisoDado = false
local function llamarLobos(accion, a, b)
  local bf = game:GetService("ServerScriptService"):FindFirstChild("AvadaLobos")
  if not bf then
    return nil
  end
  local ok, res = pcall(function()
    return bf:Invoke(accion, a, b)
  end)
  if ok then
    return res
  end
  warn("[Avada] El Script LOBOS respondio con error: " .. tostring(res))
  return nil
end

local function quitarLoboDeLaLista(som)
  for i, s2 in ipairs(SE.sombras) do
    if s2 == som then
      table.remove(SE.sombras, i)
      break
    end
  end
end

local function loboCayo(som)
  quitarLoboDeLaLista(som)
  if som.ultimoGolpe then
    bajaKill(som.ultimoGolpe)
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
        if j.label then j.label.Text = "Jaula abierta: toca al aprendiz" end
      end
    end
  end
end

local function crearLoboPartida(pos, tipo, jaulaIdx)
  local opts = nil
  if tipo == "grande" then
    opts = { escala = 1.5, vida = 100000, dano = 26 }
  end
  local modelo = llamarLobos("crear", pos, opts)
  if not modelo then
    lobosFaltan = true
    if not loboAvisoDado then
      loboAvisoDado = true
      warn("[Avada] LOS LOBOS NO SALEN: falta el Script LOBOS completo en ServerScriptService (su ultima linea dice -- FIN LOBOS)")
    end
    return nil
  end
  lobosFaltan = false
  local som = {
    model = modelo,
    root = modelo:FindFirstChild("HumanoidRootPart"),
    hum = modelo:FindFirstChildOfClass("Humanoid"),
    tipo = tipo or "normal",
    guardian = jaulaIdx ~= nil,
    jaula = jaulaIdx,
    ultimoGolpe = nil,
  }
  table.insert(SE.sombras, som)
  if som.hum then
    som.hum.Died:Connect(function()
      loboCayo(som)
    end)
  end
  return som
end

local function danarLobo(som, dmg, de, player)
  if player then
    som.ultimoGolpe = player
  end
  if som.tipo == "grande" and som.root then
    -- EL GRANDE no cae con hechizos: se clava en el sitio un momento
    som.root.Anchored = true
    task.delay(1.2, function()
      if som.root and som.root.Parent then
        som.root.Anchored = false
      end
    end)
  end
  if som.hum then
    pcall(function()
      som.hum:TakeDamage(dmg)
    end)
  end
end

local function destruirLobos(soloNocturnos)
  llamarLobos("sinReaparicion")
  for i = #SE.sombras, 1, -1 do
    local som = SE.sombras[i]
    if (not soloNocturnos) or (not som.guardian and som.tipo ~= "bosque") then
      if som.model then
        som.model:Destroy()
      end
      table.remove(SE.sombras, i)
    end
  end
end

-- Hechizos contra los lobos (sin duelo: golpea al mas cercano)
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
    danarLobo(best, dmg, hrp.Position, caster)
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

--===========================================================
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
  destruirLobos(false)
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
    sonar(player, "MusicaLobby")
    sincronizaUI(player)
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

-- Lobos sueltos del bosque: pasean de dia por la parte profunda, como
-- en 99 Noches (de dia tambien hay lobos). Se repuebla cada amanecer.
local function asegurarLobosDelBosque()
  local vivos = 0
  for _, som in ipairs(SE.sombras) do
    if som.tipo == "bosque" then
      vivos += 1
    end
  end
  for i = vivos + 1, 3 do
    local a = i * 2.1 + 0.7
    local r = 150 + (i % 2) * 30
    crearLoboPartida(Vector3.new(FC.X + math.cos(a) * r, 2.0, FC.Z + math.sin(a) * r), "bosque")
  end
end

local function nocheLobos()
  local total
  if SE.noche == 1 then
    total = 1 -- primera noche suave, como en 99 Noches
  else
    total = math.min(1 + SE.noche, 6)
  end
  for i = 1, total do
    local a = math.random() * math.pi * 2
    local pos = Vector3.new(FC.X + math.cos(a) * 150, 2.0, FC.Z + math.sin(a) * 150)
    crearLoboPartida(pos, "normal")
  end
  -- incursiones: en las noches 3 y 6 algunos lobos entran hasta la fogata
  if SE.noche == 3 or SE.noche == 6 then
    local n = (SE.noche == 3) and 2 or 4
    for i = 1, n do
      local a = math.random() * math.pi * 2
      local pos = Vector3.new(FC.X + math.cos(a) * 130, 2.0, FC.Z + math.sin(a) * 130)
      crearLoboPartida(pos, "raider")
    end
  end
  -- EL GRANDE ronda desde la noche 2 (no muere: los hechizos lo clavan)
  if SE.noche >= 2 then
    local yaHay = false
    for _, som in ipairs(SE.sombras) do
      if som.tipo == "grande" then
        yaHay = true
        break
      end
    end
    if not yaHay then
      local a = math.random() * math.pi * 2
      crearLoboPartida(Vector3.new(FC.X + math.cos(a) * 160, 2.0, FC.Z + math.sin(a) * 160), "grande")
    end
  end
end

local function cicloPartida()
  while SE.on do
    -- DIA
    SE.fase = "dia"
    LightingSvc.ClockTime = 13.2
    LightingSvc.FogEnd = 100000
    asegurarLobosDelBosque()
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
    nocheLobos()
    sonarTodos("Aullido")
    updateFireBoard()
    updateCircleBoard()
    local tNoche = 0
    local nocheDur = math.max(NOCHE_LEN - SE.aprendices * 12, 70)
    while SE.on and tNoche < nocheDur do
      task.wait(1)
      tNoche += 1
      -- la llama se consume mas rapido de noche
      SE.llama = math.max(0, SE.llama - (100 / (NOCHE_LEN * 1.25)) * (1 - 0.07 * ((SE.nivel or 1) - 1)))
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
    -- recompensa: sobrevivir la noche paga Esencias (la noche 1 paga
    -- 1, la 2 paga 2... una partida perfecta paga 28 en total)
    for player, d in pairs(SE.players) do
      if d.vivo then
        llamarEsencias(player, SE.noche)
      end
    end
    -- amanecer: los lobos de la noche desaparecen
    sonarTodos("Amanecer")
    destruirLobos(true)
    if SE.noche >= NOCHES_META then
      finPartida(true)
      return
    end
    updateCircleBoard()
  end
end

-- El lobo trae su propia IA (archivo LOBOS). Este bucle vigila la
-- regla de la fogata: el anillo de la llama es una PARED para los
-- lobos (salvo los de las incursiones 3 y 6): el que lo cruza es
-- empujado fuera al instante y el fuego lo quema.
local function bucleLobos()
  while true do
    task.wait(0.15)
    if SE.on then
      local radio = 9 + SE.llama * 0.11
      for _, som in ipairs(SE.sombras) do
        if som.root and som.root.Parent and som.tipo ~= "raider" then
          local rp = som.root.Position
          local dx, dz = rp.X - fuegoPos.X, rp.Z - fuegoPos.Z
          local dist = math.sqrt(dx * dx + dz * dz)
          if SE.llama > 0 and dist < radio + 4 then
            local dm = math.max(dist, 0.01)
            local nx = fuegoPos.X + (dx / dm) * (radio + 3)
            local nz = fuegoPos.Z + (dz / dm) * (radio + 3)
            local look = som.root.CFrame.LookVector
            pcall(function()
              som.root.CFrame = CFrame.new(Vector3.new(nx, rp.Y, nz), Vector3.new(nx + look.X, rp.Y, nz + look.Z))
            end)
            danarLobo(som, (dist < 7) and 26 or 8, fuegoPos, nil)
          end
        end
      end
    end
  end
end
task.spawn(bucleLobos)

-- Recursos: recoger con el toque
local function conectarToques()
  local function jugadorDe(hit)
    local char = hit and hit.Parent
    local player = char and Players:GetPlayerFromCharacter(char)
    return player
  end
  for _, fr in ipairs(moras) do
    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 14
    cd.Parent = fr.mora
    cd.MouseClick:Connect(function(player)
      recogerMoraDelArbusto(player, fr)
    end)
    local ultimoToqueM = 0
    fr.mora.Touched:Connect(function(hit)
      local ahora = os.clock()
      if ahora - ultimoToqueM < 0.35 then
        return
      end
      ultimoToqueM = ahora
      local pl = jugadorDe(hit)
      if pl then
        recogerMoraDelArbusto(pl, fr)
      end
    end)
  end
  for _, hg in ipairs(hongos) do
    local zona = Instance.new("Part")
    zona.Name = "ZonaHongo"
    zona.Size = Vector3.new(2.8, 3, 2.8)
    zona.CFrame = CFrame.new(hg.cap.Position.X, hg.cap.Position.Y + 1.2, hg.cap.Position.Z)
    zona.Transparency = 1
    zona.CanCollide = false
    zona.CanTouch = true
    zona.Anchored = true
    zona.Parent = workspace
    hg.zona = zona
    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 14
    cd.Parent = zona
    cd.MouseClick:Connect(function(player)
      recogerHongo(player, hg)
    end)
    local ultimoToqueH = 0
    zona.Touched:Connect(function(hit)
      local ahora = os.clock()
      if ahora - ultimoToqueH < 0.35 then
        return
      end
      ultimoToqueH = ahora
      local pl = jugadorDe(hit)
      if pl then
        recogerHongo(pl, hg)
      end
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
        SE.fogataXP = (SE.fogataXP or 0) + d.lenos
        d.lenos = 0
        sonar(player, "Depositar")
        sincronizaUI(player)
        while (SE.nivel or 1) < NIVEL_MAX and SE.fogataXP >= lenosParaNivel(SE.nivel or 1) do
          SE.fogataXP = SE.fogataXP - lenosParaNivel(SE.nivel or 1)
          SE.nivel = (SE.nivel or 1) + 1
          moverPared()
          print("[Avada] La fogata subio al nivel " .. SE.nivel .. ": el bosque se expande")
        end
        updateFireBoard()
      end
    end
  end)
  -- jaulas: tocar al aprendiz cuando la jaula esta abierta
  for ci, j in ipairs(jaulas) do
    for _, pp in ipairs(j.fig and j.fig:GetChildren() or {}) do
      if pp:IsA("BasePart") then
        pp.Touched:Connect(function(hit)
          if not SE.on or not j.libre or j.rescatado then
            return
          end
          local player = jugadorDe(hit)
          if player and jugadorEnPartida(player) and SE.players[player].vivo then
            j.rescatado = true
            SE.aprendices += 1
            if j.label then j.label.Text = "Aprendiz rescatado" end
            -- el aprendiz se muda junto a la fogata
            local ang = ci * (math.pi / 2) + 0.4
            local dest = Vector3.new(fuegoPos.X + math.cos(ang) * 11, fuegoPos.Y, fuegoPos.Z + math.sin(ang) * 11)
            for _, f2 in ipairs(j.fig and j.fig:GetChildren() or {}) do
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
        sonar(player, "Cofre")
        sincronizaUI(player)
      end
    end)
  end
  end
end

local function prepararMundo()
  lobosFaltan = false
  loboAvisoDado = false
  SE.llama = 100
  SE.nivel = 1
  SE.fogataXP = 0
  moverPared()
  SE.noche = 0
  SE.aprendices = 0
  destruirLobos(false)
  llamarLobos("conReaparicion")
  for ci, j in ipairs(jaulas) do
    j.libre = false
    j.rescatado = false
    for _, bar in ipairs(j.barrotes) do
      bar.Transparency = 0
      bar.CanCollide = false
    end
    if j.label then j.label.Text = "Aprendiz atrapado: vence a sus guardianes" end
    -- figura de vuelta en la jaula
    for _, pp in ipairs(j.fig and j.fig:GetChildren() or {}) do
      local offY = ({ Piernas = 0.55, Tunica = 1.95, Cabeza = 3.3, Sombrero = 4.05 })[pp.Name] or 1
      pp.CFrame = CFrame.new(j.pos.X, j.pos.Y + 0.8 + offY, j.pos.Z)
    end
    -- guardianes de la jaula: dos lobos sombrios
    crearLoboPartida(Vector3.new(j.pos.X - 7, 2.0, j.pos.Z - 7), "guardian", ci)
    crearLoboPartida(Vector3.new(j.pos.X + 7, 2.0, j.pos.Z - 7), "guardian", ci)
  end
  updateFireBoard()
end

local function iniciarPartida(lista)
  if not bosqueListo then
    escanearBosque()
  end
  if not bosqueListo then
    print("[Avada] La partida espera: falta descubrir el bosque (archivo BOSQUE)")
    return
  end
  SE.on = true
  SE.players = {}
  prepararMundo()
  local k = 0
  for _, player in ipairs(lista) do
    if player and player.Parent then
      k += 1
      SE.players[player] = { vivo = true, lenos = 0, hambre = 100, saco = {}, sacoEnMano = false, enMano = nil, toolSaco = nil }
      darSacoMago(player)
      sonar(player, "MusicaBosque")
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
        if hrp and fuegoPos then
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
