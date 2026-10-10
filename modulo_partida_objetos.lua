-- PartidaObjetos: ModuleScript en ServerScriptService (comida, saco magico, caldero).
-- Fabrica por sesion: crear(E, SE, ctx, W).
local function crear(E, SE, ctx, W)
-- OBJETOS: comida en la mano (W.moras y W.hongos), SACO MAGICO (x/5)
-- y acciones como en 99 Noches: Comer, Desgarrar, Tienda, Desalmacenar
--===========================================================
local SACO_MAX = 5
local COMIDA = { Mora = 30, Hongo = 40 } -- cuanto de hambre devuelve cada una

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
  local hongosEnSaco = 0
  local manoTipoCal = nil
  if d then
    manoTipoCal = d.enMano and d.enMano.tipo or nil
    for _, tipoS in ipairs(d.saco or {}) do
      if tipoS == "Hongo" then
        hongosEnSaco += 1
      end
    end
  end
  pcall(function()
    E.RE_UI:FireClient(player, {
      enPartida = SE.on and d ~= nil,
      hambre = d and math.floor(d.hambre or 100) or 100,
      mano = (d and d.enMano ~= nil) or false,
      saco = d and #(d.saco or {}) or 0,
      sacoMax = SACO_MAX,
      sacoEnMano = sacoEnLaMano,
      noche = SE.noche,
      fase = SE.fase,
      lenos = d and d.lenos or 0,
      manoTipo = manoTipoCal,
      hongosSaco = hongosEnSaco,
      calderoHongos = SE.calderoHongos or 0,
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
  sincronizaUI(player)
end

local function comerDesdeSaco(player)
  local d = SE.players[player]
  if not d or #d.saco <= 0 then
    return
  end
  local tipo = table.remove(d.saco, 1)
  d.hambre = math.min(100, d.hambre + (COMIDA[tipo] or 25))
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
      if E.jugadorEnPartida(SE, otro) and entregarComida(otro, tipo) then
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
      local pl = modelo and E.Players:GetPlayerFromCharacter(modelo)
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

W.calderoModelo = nil
local function posCaldero()
  if not W.calderoModelo or not W.calderoModelo.Parent then
    W.calderoModelo = ctx.caldero
  end
  if not W.calderoModelo then
    return nil
  end
  local ancla = W.calderoModelo:FindFirstChild("CalderoAncla")
  if ancla then
    return ancla.Position
  end
  return W.calderoModelo:GetPivot().Position
end

-- Soltar en el caldero: los W.hongos de la mano y del saco caen en el
-- caldero y quedan guardados en la base (reserva de todo el equipo).
local function depositarEnCaldero(player)
  local d = SE.players[player]
  if not d or not d.vivo then
    return
  end
  local posC = posCaldero()
  local char = player.Character
  local hrp = char and char:FindFirstChild("HumanoidRootPart")
  if not (posC and hrp) then
    return
  end
  local dx, dz = hrp.Position.X - posC.X, hrp.Position.Z - posC.Z
  if dx * dx + dz * dz > 18 * 18 then
    return
  end
  local n = 0
  if d.enMano and d.enMano.tipo == "Hongo" then
    d.enMano.tool:Destroy()
    d.enMano = nil
    n += 1
  end
  for i = #d.saco, 1, -1 do
    if d.saco[i] == "Hongo" then
      table.remove(d.saco, i)
      n += 1
    end
  end
  if n <= 0 then
    return
  end
  SE.calderoHongos = (SE.calderoHongos or 0) + n
  for pl, _ in pairs(SE.players) do
    sincronizaUI(pl)
  end
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
        sincronizaUI(player)
        return true
      end
      return false
    end
    darEnMano(player, tipo)
    sincronizaUI(player)
    return true
  end
  if #d.saco < SACO_MAX then
    table.insert(d.saco, tipo)
    sincronizaUI(player)
    return true
  end
  return false
end

local function recogerMoraDelArbusto(player, fr)
  if not fr.disponible or not E.jugadorEnPartida(SE, player) then
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
  return Vector3.new(W.fuegoPos.X + math.cos(a) * r, 2.0, W.fuegoPos.Z + math.sin(a) * r)
end

-- Los arboles de cristales dan lena: tocas el tronco (o le das tap)
-- y sale un leno para tu cuenta; el arbol vuelve a dar a los 25 s.
-- Nada de madera tirada por el suelo.
W.arbolesListos = false
W.arbolesZona = {}
local function tocarArbol(player, arb)
  if not arb or os.clock() < (arb.listoEn or 0) then
    return
  end
  if not (SE.on and E.jugadorEnPartida(SE, player) and SE.players[player].vivo) then
    return
  end
  arb.listoEn = os.clock() + 25
  SE.players[player].lenos += 1
  sincronizaUI(player)
end
local function conectarArboles()
  if W.arbolesListos or not W.Bosque then
    return W.arbolesListos
  end
  if W.Bosque:GetAttribute("ArbolesListos") ~= true then
    return false
  end
  for _, modelo in ipairs(W.Bosque:GetChildren()) do
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
        table.insert(W.arbolesZona, zona)
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
          local player = modeloChar and E.Players:GetPlayerFromCharacter(modeloChar)
          if player then
            tocarArbol(player, arb)
          end
        end)
      end
    end
  end
  W.arbolesListos = true
  print("[Avada] Arboles listos para dar lena: " .. #W.arbolesZona)
  return true
end
task.spawn(function()
  while not SE.terminada and not conectarArboles() do
    task.wait(1)
  end
end)

local function recogerHongo(player, hg)
  if not hg.disponible or not E.jugadorEnPartida(SE, player) then
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

local function accionRemota(player, accion)
  if not E.jugadorEnPartida(SE, player) or not SE.players[player].vivo then
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
  elseif accion == "Caldero" then
    depositarEnCaldero(player)
  elseif accion == "VerCaldero" then
    sincronizaUI(player)
  end
end


-- el hambre baja sin parar: la barra de la interfaz se refresca sola
task.spawn(function()
  while not SE.terminada do
    task.wait(1.5)
    if SE.on then
      for player, _ in pairs(SE.players) do
        sincronizaUI(player)
      end
    end
  end
end)

  return {
    sincronizaUI = sincronizaUI,
    darSacoMago = darSacoMago,
    limpiarObjetos = limpiarObjetos,
    accionRemota = accionRemota,
    recogerMoraDelArbusto = recogerMoraDelArbusto,
    recogerHongo = recogerHongo,
    entregarComida = entregarComida,
  }
end
return crear
-- FIN MODULO PARTIDA OBJETOS
