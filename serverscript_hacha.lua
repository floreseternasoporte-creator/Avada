-- Script HACHA (pegar en ServerScriptService como Script)
-- Sistema del hacha SEPARADO. NO toca partida.
-- - Crea el hacha low-poly del usuario como Tool en StarterPack.
-- - Al golpear árboles de cristal (ArbolCristal) suelta DIAMANTES al piso (no madera).
-- - Los diamantes se recogen y sirven para el caldero (pociones).
-- - Incluye animación de corte (cliente) + sacudida del árbol + estela.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterPack = game:GetService("StarterPack")
local Debris = game:GetService("Debris")

-- RemoteEvent (autocreado)
local RE = RS:FindFirstChild("HachaEvent")
if not RE then
  RE = Instance.new("RemoteEvent")
  RE.Name = "HachaEvent"
  RE.Parent = RS
end

------------------------------------------------------------------
-- CÓDIGO DEL USUARIO (hacha low-poly) — verbatim, solo MAKE_TOOL=true
------------------------------------------------------------------
local MAKE_TOOL = true                  -- true = Tool en StarterPack
local SCALE     = 0.003                 -- más pequeña (antes 0.005)
local ORIGIN    = CFrame.new(0, 6, 0)

local S = SCALE
local ANCHORED = not MAKE_TOOL

local WOOD       = Color3.fromRGB(96, 68, 48)
local WOOD_DARK  = Color3.fromRGB(58, 40, 28)
local STEEL      = Color3.fromRGB(92, 92, 95)
local STEEL_LIGHT= Color3.fromRGB(122, 122, 125)
local STEEL_FACET= Color3.fromRGB(108, 108, 111)
local STEEL_MID  = Color3.fromRGB(82, 82, 85)
local STEEL_DARK = Color3.fromRGB(62, 62, 64)
local SCRATCH    = Color3.fromRGB(165, 165, 168)

local old = Workspace:FindFirstChild("Hacha")
if old then old:Destroy() end
if StarterPack:FindFirstChild("Hacha") then StarterPack.Hacha:Destroy() end

local container
if MAKE_TOOL then
  container = Instance.new("Tool")
  container.Name = "Hacha"
  container.RequiresHandle = true
  container.CanBeDropped = true
  container.Grip = CFrame.Angles(math.rad(180), math.rad(90), 0) -- volteada: cabeza arriba
else
  container = Instance.new("Model")
  container.Name = "Hacha"
end

local ROOT = MAKE_TOOL and CFrame.new() or ORIGIN
local parts = {}
local handlePart

local function V(xpx, ypx, zpx)
  return Vector3.new((xpx - 448) * S, (600 - ypx) * S, (zpx or 0) * S)
end

local function mk(name, size, cf, color, material, isHandle)
  local p = Instance.new("Part")
  p.Name = isHandle and "Handle" or name
  p.Size = Vector3.new(math.max(size.X, 0.001), math.max(size.Y, 0.001), math.max(size.Z, 0.001))
  p.CFrame = cf
  p.Color = color
  p.Material = material
  p.Anchored = ANCHORED
  p.CanCollide = not MAKE_TOOL
  p.Massless = not isHandle
  p.TopSurface = Enum.SurfaceType.Smooth
  p.BottomSurface = Enum.SurfaceType.Smooth
  p.Parent = container
  table.insert(parts, p)
  if isHandle then handlePart = p end
  return p
end

local function boxPx(name, xl, xr, yt, yb, depthPx, color, material)
  local size = Vector3.new((xr - xl) * S, (yb - yt) * S, depthPx * S)
  local cf = ROOT * CFrame.new(V((xl + xr) / 2, (yt + yb) / 2, 0))
  return mk(name, size, cf, color, material)
end

local function interp(pts, x)
  for i = 1, #pts - 1 do
    local a, b = pts[i], pts[i + 1]
    if x >= a[1] and x <= b[1] then
      local t = (x - a[1]) / (b[1] - a[1])
      return a[2] + (b[2] - a[2]) * t
    end
  end
  return pts[#pts][2]
end

local function octSegment(name, p1, p2, wpx, color, extA, extB, isHandle)
  local a = V(p1[1], p1[2])
  local b = V(p2[1], p2[2])
  local dir = (b - a).Unit
  a = a - dir * ((extA or 0) * S)
  b = b + dir * ((extB or 0) * S)
  local len = (b - a).Magnitude
  local center = (a + b) / 2
  local right = Vector3.new(dir.Y, -dir.X, 0)
  local cf = ROOT * CFrame.fromMatrix(center, right, dir, Vector3.new(0, 0, 1))
  local w  = wpx * S
  local aw = w * 0.41421356
  local angles = {0, 45, 90, 135}
  for i, deg in ipairs(angles) do
    mk(name .. "_" .. i,
      Vector3.new(w, len + 0.0008 * i, aw),
      cf * CFrame.Angles(0, math.rad(deg), 0),
      color, Enum.Material.Wood,
      isHandle and i == 1)
  end
end

octSegment("MangoInf", {393, 540}, {395, 1105}, 92, WOOD, 8, 0, true)
octSegment("MangoSup", {377, 145}, {393, 540}, 88, WOOD, 0, 8, false)

local function handleX(y)
  if y < 540 then
    return 377 + 16 * (y - 145) / 395
  end
  return 393 + 2 * (y - 540) / 565
end

local gashes = {
  {  6, 400, 470, 10},
  {-10, 430, 455,  6},
  { -4, 520, 578,  9},
  {-12, 650, 708,  9},
  { 12, 700, 750,  8},
  { -6, 800, 838, 10},
  {  8, 858, 905,  9},
  {  0, 945, 995, 10},
}
for i, g in ipairs(gashes) do
  local ym = (g[2] + g[3]) / 2
  local xm = handleX(ym) + g[1]
  local wpx = (ym < 540) and 88 or 92
  for _, sgn in ipairs({1, -1}) do
    local pos = V(xm, ym) + Vector3.new(0, 0, sgn * (wpx / 2 * S + 0.003))
    mk("Veta" .. i .. (sgn == 1 and "F" or "B"),
      Vector3.new(g[4] * S, (g[3] - g[2]) * S, 0.01),
      ROOT * CFrame.new(pos), WOOD_DARK, Enum.Material.Wood)
  end
end

boxPx("Culata", 287, 372, 190, 322, 100, STEEL, Enum.Material.Metal)
boxPx("Ojo", 372, 447, 175, 338, 112, STEEL, Enum.Material.Metal)

local function panel(name, xl, xr, yt, yb, depthPx, color)
  for _, sgn in ipairs({1, -1}) do
    local size = Vector3.new((xr - xl) * S, (yb - yt) * S, 0.012)
    local pos = V((xl + xr) / 2, (yt + yb) / 2) + Vector3.new(0, 0, sgn * (depthPx / 2 * S + 0.004))
    mk(name .. (sgn == 1 and "F" or "B"), size, ROOT * CFrame.new(pos), color, Enum.Material.Metal)
  end
end
panel("FacetaCulataSup", 287, 372, 190, 250, 100, STEEL)
panel("FacetaCulataInf", 287, 372, 250, 322, 100, STEEL_DARK)
panel("FacetaOjoSup",    372, 447, 175, 248, 112, STEEL_FACET)
panel("FacetaOjoInf",    372, 447, 248, 338, 112, STEEL_MID)

local topPts = {{447, 163}, {582, 100}, {628, 148}, {640, 245}}
local botPts = {{447, 338}, {612, 388}, {628, 330}, {640, 245}}
local thickPts = {{447, 100}, {585, 50}, {640, 6}}

local BLADE_X0, BLADE_X1, SLICES = 447, 640, 20
local dx = (BLADE_X1 - BLADE_X0) / SLICES

for i = 1, SLICES do
  local x0 = BLADE_X0 + (i - 1) * dx
  local x1 = x0 + dx
  local xm = (x0 + x1) / 2
  local yt = interp(topPts, xm)
  local yb = interp(botPts, xm)
  local th = math.max(interp(thickPts, xm), 4)
  if yb - yt > 1 then
    local isBevel = xm > 585
    boxPx("Hoja" .. i, x0, x1 + 0.4, yt, yb, th,
      isBevel and STEEL_LIGHT or STEEL, Enum.Material.Metal)
  end
end

do
  local th = interp(thickPts, 515)
  for _, sgn in ipairs({1, -1}) do
    local pos = V(515, 312) + Vector3.new(0, 0, sgn * (th / 2 * S + 0.004))
    mk("Rayon" .. (sgn == 1 and "F" or "B"),
      Vector3.new(34 * S, 2 * S, 0.008),
      ROOT * CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(35)),
      SCRATCH, Enum.Material.Metal)
  end
end

for _, p in ipairs(parts) do
  if p ~= handlePart then
    local w = Instance.new("WeldConstraint")
    w.Part0 = handlePart
    w.Part1 = p
    w.Parent = handlePart
  end
end

if MAKE_TOOL then
  container.Parent = StarterPack
else
  container.PrimaryPart = handlePart
  container.Parent = Workspace
end

print(("Hacha creada: %d partes"):format(#parts))
-- FIN CÓDIGO DEL USUARIO
------------------------------------------------------------------

-- Referencia a la herramienta
local hachaTool = StarterPack:WaitForChild("Hacha", 10)

-- Hitbox invisible en la hoja para detectar el TOQUE al árbol (estilo 99 Noches)
if hachaTool then
  local hojaRef = hachaTool:FindFirstChild("Hoja10")
  if hojaRef then
    local hitbox = Instance.new("Part")
    hitbox.Name = "HitboxHacha"
    hitbox.Size = Vector3.new(3, 3, 3)
    hitbox.Transparency = 1
    hitbox.CanCollide = false
    hitbox.Massless = true
    hitbox.TopSurface = Enum.SurfaceType.Smooth
    hitbox.BottomSurface = Enum.SurfaceType.Smooth
    hitbox.CFrame = hojaRef.CFrame
    hitbox.Parent = hachaTool
    local w = Instance.new("WeldConstraint")
    w.Part0 = hojaRef
    w.Part1 = hitbox
    w.Parent = hitbox
  end
end

-- Estela de corte en la hoja (para la animación)
if hachaTool then
  local hoja = hachaTool:FindFirstChild("Hoja10")
  if hoja then
    local a0 = Instance.new("Attachment")
    a0.Name = "EstelaA"
    a0.Position = Vector3.new(0, hoja.Size.Y / 2, 0)
    a0.Parent = hoja
    local a1 = Instance.new("Attachment")
    a1.Name = "EstelaB"
    a1.Position = Vector3.new(0, -hoja.Size.Y / 2, 0)
    a1.Parent = hoja
    local trail = Instance.new("Trail")
    trail.Name = "Estela"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Color = ColorSequence.new(Color3.fromRGB(170, 215, 255))
    trail.Transparency = NumberSequence.new(0.25, 1)
    trail.Lifetime = 0.28
    trail.Enabled = false
    trail.Parent = hoja
  end
end

-- Dar el hacha a jugadores que ya están dentro
for _, plr in ipairs(Players:GetPlayers()) do
  local bp = plr:FindFirstChildOfClass("Backpack")
  if bp and hachaTool and not bp:FindFirstChild("Hacha") and not (plr.Character and plr.Character:FindFirstChild("Hacha")) then
    hachaTool:Clone().Parent = bp
  end
end

------------------------------------------------------------------
-- SISTEMA DE CORTE: árboles de cristal → diamantes
------------------------------------------------------------------
-- (El Bosque se busca dinámico: el script arranca en el lobby antes de que exista)
local HP_POR_ARBOL = 3        -- golpes para soltar diamantes
local DIAMANTES_POR_CORTE = 2 -- cuántos caen
local DESCANSO_ARBOL = 30     -- segundos antes de dar más diamantes
local COOLDOWN_GOLPE = 0.8    -- segundos entre golpes

local ultimoGolpe = {}

-- Forma de la gema: un CRISTAL PRISMA como los del árbol de cristal
-- (alargado, con punta y núcleo brillante, celeste hielo), NO un cubo
-- de neón: el dueño dijo que el del suelo "no parecía como el del
-- árbol". La comparten el diamante del suelo y el que se lleva en la
-- mano: lo que recoges se ve igual que lo que cargas.
local COL_GEMA = Color3.fromRGB(165, 228, 255)

local function piezaGema(nombre, size, color, material)
  local p = Instance.new("Part")
  p.Name = nombre
  p.Size = size
  p.Color = color
  p.Material = material
  p.TopSurface = Enum.SurfaceType.Smooth
  p.BottomSurface = Enum.SurfaceType.Smooth
  p.CanCollide = false
  p.CanQuery = false
  p.CanTouch = false
  p.Massless = true
  return p
end

-- Viste una raíz (el Handle de la Tool o el ancla del suelo) con las
-- piezas del cristal, soldadas a ella. Devuelve la pieza principal.
local function vestirGema(raiz, padre, escala)
  local e = escala or 1
  local function poner(pieza, offset)
    pieza.CFrame = raiz.CFrame * offset
    pieza.Parent = padre
    local w = Instance.new("WeldConstraint")
    w.Part0 = raiz
    w.Part1 = pieza
    w.Parent = pieza
    return pieza
  end
  local inclin = CFrame.Angles(math.rad(7), math.rad(24), math.rad(-5))
  local gema = poner(
    piezaGema("Gema", Vector3.new(0.62, 1.3, 0.62) * e, COL_GEMA, Enum.Material.Glass),
    CFrame.new(0, 0.4 * e, 0) * inclin
  )
  gema.Transparency = 0.18
  poner(
    piezaGema("Punta", Vector3.new(0.4, 0.5, 0.4) * e, COL_GEMA, Enum.Material.Glass),
    CFrame.new(0, 1.22 * e, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0)
  ).Transparency = 0.18
  poner(
    piezaGema("Nucleo", Vector3.new(0.26, 1.0, 0.26) * e, Color3.fromRGB(215, 246, 255), Enum.Material.Neon),
    CFrame.new(0, 0.4 * e, 0) * inclin
  )
  return gema
end

local function crearDiamanteTool()
  local tool = Instance.new("Tool")
  tool.Name = "Diamante"
  tool.RequiresHandle = true
  tool.CanBeDropped = true
  local h = Instance.new("Part")
  h.Name = "Handle"
  h.Size = Vector3.new(0.4, 0.4, 0.4)
  h.Transparency = 1
  h.CanCollide = false
  h.CanQuery = false
  h.CanTouch = false
  h.Massless = true
  h.Parent = tool
  vestirGema(h, tool, 0.85) -- el mismo cristal del suelo, en la mano
  tool.Grip = CFrame.new(0, -0.3, 0)
  return tool
end

local function soltarDiamante(pos)
  local m = Instance.new("Model")
  m.Name = "DiamanteSuelo"
  -- ancla invisible: lleva el toque de recogida y el giro/flote; las
  -- piezas del cristal van soldadas a ella y la siguen
  local raiz = Instance.new("Part")
  raiz.Name = "Toque"
  raiz.Size = Vector3.new(1.8, 1.8, 1.8)
  raiz.Transparency = 1
  raiz.CFrame = CFrame.new(pos + Vector3.new(0, 0.9, 0))
  raiz.Anchored = true
  raiz.CanCollide = false
  raiz.CanQuery = false
  raiz.Parent = m
  local gema = vestirGema(raiz, m, 1)
  local luz = Instance.new("PointLight")
  luz.Color = COL_GEMA
  luz.Range = 9
  luz.Brightness = 1.5
  luz.Parent = gema
  -- destello al aparecer (la ráfaga es Emit(12): "BurstAmount" NO
  -- existe en ParticleEmitter y asignarlo mataba esta función)
  local chispas = Instance.new("ParticleEmitter")
  chispas.Color = ColorSequence.new(Color3.fromRGB(160, 230, 255))
  chispas.Size = NumberSequence.new(0.5, 0)
  chispas.Speed = NumberRange.new(4, 8)
  chispas.Lifetime = NumberRange.new(0.4, 0.8)
  chispas.Rate = 0
  chispas.Parent = gema
  task.delay(0.1, function()
    pcall(function()
      chispas:Emit(12)
    end)
  end)
  m.PrimaryPart = raiz
  m.Parent = Workspace
  -- idle: el cristal gira despacio y flota sobre el suelo
  local base = raiz.CFrame
  task.spawn(function()
    local t0 = os.clock()
    while m.Parent do
      local t = os.clock() - t0
      raiz.CFrame = base
        * CFrame.new(0, math.sin(t * 2) * 0.1, 0)
        * CFrame.Angles(0, t * 0.8, 0)
      task.wait()
    end
  end)

  local recogido = false
  raiz.Touched:Connect(function(hit)
    if recogido then return end
    local modelo = hit and hit:FindFirstAncestorOfClass("Model")
    local plr = modelo and Players:GetPlayerFromCharacter(modelo)
    if not plr then return end
    recogido = true
    -- Como las moras/hongos: si la mano está libre va a la mano, si no al saco (mochila)
    local char = plr.Character
    local bp = plr:FindFirstChildOfClass("Backpack")
    local manoLibre = true
    if char and char:FindFirstChildOfClass("Tool") then
      manoLibre = false
    end
    local dt = crearDiamanteTool()
    if manoLibre and char then
      dt.Parent = char -- se equipa directo en la mano
    elseif bp then
      dt.Parent = bp -- al saco (mochila)
    else
      dt:Destroy()
    end
    RE:FireClient(plr, "Aviso", "¡Diamante recogido!")
    m:Destroy()
  end)
  Debris:AddItem(m, 90)
end

-- Chispas/polvo de un golpe (definida ANTES de derribarArbol: antes estaba
-- debajo y derribarArbol la llamaba como global inexistente, así que el
-- polvo al caer el árbol fallaba en silencio dentro de su pcall)
local function chispasGolpe(pos)
  local f = Instance.new("Part")
  f.Size = Vector3.new(0.5, 0.5, 0.5)
  f.CFrame = CFrame.new(pos)
  f.Anchored = true
  f.CanCollide = false
  f.CanQuery = false
  f.Transparency = 1
  f.Parent = Workspace
  local pe = Instance.new("ParticleEmitter")
  pe.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 255, 255))
  pe.Size = NumberSequence.new(0.4, 0)
  pe.Speed = NumberRange.new(6, 12)
  pe.Lifetime = NumberRange.new(0.3, 0.6)
  pe.Rate = 0
  -- SIN "BurstAmount": esa propiedad NO existe en ParticleEmitter y
  -- asignarla lanzaba un error. Como aplicarGolpe llama a chispasGolpe
  -- SIN pcall, ese error mataba el golpe entero: el HP bajaba y el
  -- árbol se sacudía, pero la ejecución moría antes de la rama del
  -- derribo -> el árbol nunca se destrozaba ni soltaba diamantes.
  -- La ráfaga real se hace con Emit(10), justo debajo.
  pe.Parent = f
  pe:Emit(10)
  Debris:AddItem(f, 1.5)
end

-- Derriba el árbol al suelo (como en 99 Noches) y lo restaura después
local function derribarArbol(arbol)
  local ok, pivote = pcall(function()
    return arbol:GetPivot()
  end)
  if not ok then return end
  arbol:SetAttribute("HachaCaido", true)
  -- aspecto original de cada pieza: al final de la caída el árbol se
  -- DESVANECE (el dueño no entendía que se quedara tirado en el suelo)
  -- y la restauración de los 60 s lo devuelve tal cual era
  local originales = {}
  for _, d in ipairs(arbol:GetDescendants()) do
    if d:IsA("BasePart") then
      originales[d] = { t = d.Transparency, c = d.CanCollide }
    end
  end
  -- La restauración se programa PRIMERO, antes de animar la caída:
  -- antes iba DESPUÉS del bucle de caída, así que si la animación
  -- petaba a mitad (esto corre en task.spawn, muere en silencio), la
  -- restauración nunca se programaba y el árbol se quedaba con
  -- HachaCaido=true para siempre, intocable. Ahora pase lo que pase
  -- se levanta solo a los 60 s.
  task.delay(60, function()
    pcall(function()
      arbol:PivotTo(pivote)
      -- reaparece COMPLETO: se le devuelve su aspecto y colisión
      for pieza, orig in pairs(originales) do
        if pieza.Parent then
          pieza.Transparency = orig.t
          pieza.CanCollide = orig.c
        end
      end
      arbol:SetAttribute("HachaCaido", false)
      arbol:SetAttribute("HachaHP", HP_POR_ARBOL)
      arbol:SetAttribute("HachaDescanso", 0)
    end)
  end)
  -- dirección aleatoria de caída
  local ang = math.random() * math.pi * 2
  local eje = Vector3.new(math.cos(ang), 0, math.sin(ang))
  -- animación de caída (acelera al caer)
  local pasos = 18
  for i = 1, pasos do
    local t = i / pasos
    local rot = math.rad(82) * t * t
    local nuevo = pivote * CFrame.fromAxisAngle(eje, rot)
    nuevo = nuevo - Vector3.new(0, t * 2.5, 0)
    pcall(function()
      arbol:PivotTo(nuevo)
    end)
    task.wait(0.035)
  end
  -- polvo al impactar el suelo
  pcall(function()
    chispasGolpe(pivote.Position + Vector3.new(0, 1, 0))
  end)
  -- y DESAPARECE: tras un respiro tirado en el suelo se desvanece y
  -- deja de chocar; reaparece ya de pie con la restauración de los
  -- 60 s (HachaCaido sigue true: no se puede golpear un árbol caído)
  task.wait(1.2)
  for i = 1, 6 do
    local f = i / 6
    for pieza, orig in pairs(originales) do
      if pieza.Parent and orig.t < 1 then
        pieza.Transparency = orig.t + (1 - orig.t) * f
      end
    end
    task.wait(0.06)
  end
  for pieza in pairs(originales) do
    if pieza.Parent then
      pieza.CanCollide = false
    end
  end
end

local function sacudirArbol(arbol)
  local ok, pivote = pcall(function()
    return arbol:GetPivot()
  end)
  if not ok then return end
  for _ = 1, 4 do
    pcall(function()
      arbol:PivotTo(pivote * CFrame.Angles(0, 0, math.rad(4)))
    end)
    task.wait(0.05)
    pcall(function()
      arbol:PivotTo(pivote * CFrame.Angles(0, 0, math.rad(-4)))
    end)
    task.wait(0.05)
  end
  pcall(function()
    arbol:PivotTo(pivote)
  end)
end

local function esArbolCristal(modelo)
  if not modelo or not modelo:IsA("Model") then return false end
  if not modelo.Name:match("^ArbolCristal") then return false end
  return true
end

-- Busca el árbol de cristal más cercano (el bosque se llama BosqueProhibido)
-- CAUSA DEL FALLO (arreglado): en Workspace hay VARIOS modelos llamados
-- "BosqueProhibido" a la vez: el bosque MOLDE original y, por cada partida
-- en curso, un CLON desplazado +3000 en X por slot (así lo crea PARTIDA).
-- Antes solo se miraba el PRIMERO (FindFirstChild = el molde), cuyos
-- árboles quedan a miles de studs del jugador que está en su partida:
-- el golpe nunca encontraba un árbol a menos de 13 studs, así que no se
-- cortaba nada, no se derribaba nada y no caía ningún diamante.
-- Ahora se buscan los árboles en TODOS los bosques y gana el más cercano.
local function buscarArbolCercano(player, rango)
  local char = player.Character
  local hrp = char and char:FindFirstChild("HumanoidRootPart")
  if not hrp then return nil end
  local mejor, mejorDist = nil, rango or 14
  for _, bosque in ipairs(Workspace:GetChildren()) do
    if bosque:IsA("Model") and bosque.Name == "BosqueProhibido" then
      for _, obj in ipairs(bosque:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^ArbolCristal%d*$") then
          local ok, pp = pcall(function()
            return obj:GetPivot().Position
          end)
          if ok then
            local d = (pp - hrp.Position).Magnitude
            if d < mejorDist then
              mejor, mejorDist = obj, d
            end
          end
        end
      end
    end
  end
  return mejor
end

local ventanaGolpe = {} -- jugador -> momento del último hachazo (para validar el toque)

local function aplicarGolpe(player, arbol)
  if not esArbolCristal(arbol) then return end
  if arbol:GetAttribute("HachaCaido") then return end -- ya está derribado

  -- el jugador debe tener el hacha en la mano
  local char = player.Character
  if not char or not char:FindFirstChild("Hacha") then return end

  -- debe estar cerca del árbol (sanidad, el toque ya lo implica)
  local hrp = char:FindFirstChild("HumanoidRootPart")
  if hrp then
    local ok, pp = pcall(function()
      return arbol:GetPivot().Position
    end)
    if ok and (pp - hrp.Position).Magnitude > 25 then
      return
    end
  end

  if os.clock() < (arbol:GetAttribute("HachaDescanso") or 0) then
    RE:FireClient(player, "Aviso", "El árbol necesita descansar")
    return
  end

  local hp = arbol:GetAttribute("HachaHP")
  if hp == nil then hp = HP_POR_ARBOL end
  hp -= 1
  arbol:SetAttribute("HachaHP", hp)

  -- efectos del golpe: la sacudida solo en golpes NO mortales. En el
  -- golpe que derriba, sacudir y derribar se lanzaban a la vez y
  -- peleaban por el pivote: la sacudida restaura el pivote recto a los
  -- ~0,4 s (cortaba la caída a mitad) y el derribo capturaba su pivote
  -- con el árbol ya inclinado por la sacudida, dejando torcida la
  -- restauración de los 60 s.
  if hp > 0 then
    task.spawn(sacudirArbol, arbol)
  end
  local ok, pp = pcall(function()
    return arbol:GetPivot().Position
  end)
  local posGolpe = nil
  if ok then
    posGolpe = pp + Vector3.new(0, 3, 0)
    -- Las chispas van en pcall: un efecto visual JAMÁS debe poder matar
    -- el golpe (así murió esta función con el BurstAmount: la llamada
    -- sin proteger tumbaba aplicarGolpe antes de la rama del derribo)
    pcall(chispasGolpe, posGolpe)
  end

  -- avisa al cliente para la animación de IMPACTO (retroceso + onda + contador)
  RE:FireClient(player, "Impacto", {
    pos = posGolpe,
    golpe = HP_POR_ARBOL - hp,
    total = HP_POR_ARBOL,
  })

  if hp <= 0 then
    -- ¡el árbol se DERRIBA al suelo y suelta diamantes!
    arbol:SetAttribute("HachaHP", HP_POR_ARBOL)
    arbol:SetAttribute("HachaDescanso", os.clock() + DESCANSO_ARBOL)
    task.spawn(derribarArbol, arbol)
    if ok then
      for _ = 1, DIAMANTES_POR_CORTE do
        local ang = math.random() * math.pi * 2
        local r = 3 + math.random() * 2.5
        local pos = pp + Vector3.new(math.cos(ang) * r, 2, math.sin(ang) * r)
        soltarDiamante(pos)
      end
    end
    RE:FireClient(player, "Aviso", "¡Diamantes del árbol!")
  end
end

RE.OnServerEvent:Connect(function(player, accion, dato)
  if accion == "Golpear" then
    -- el cliente inició un hachazo: abre ventana de 0.8s para validar toques
    local char = player.Character
    if char and char:FindFirstChild("Hacha") then
      ventanaGolpe[player] = os.clock()
      -- Respaldo confiable: si hay un árbol pegado al jugador, golpea directo
      -- (por si el Touched del filo no dispara)
      task.delay(0.25, function()
        local arbol = buscarArbolCercano(player, 13)
        if arbol then
          local ahora = os.clock()
          if not (ultimoGolpe[player] and ahora - ultimoGolpe[player] < COOLDOWN_GOLPE) then
            ultimoGolpe[player] = ahora
            aplicarGolpe(player, arbol)
          end
        end
      end)
    end
  elseif accion == "TocoArbol" then
    -- el filo TOCÓ un árbol (estilo 99 Noches): validar y aplicar
    local arbol = dato
    if typeof(arbol) ~= "Instance" or not esArbolCristal(arbol) then
      return
    end
    local v = ventanaGolpe[player]
    if not v or os.clock() - v > 0.8 then
      return -- fuera de la ventana del hachazo
    end
    local ahora = os.clock()
    if ultimoGolpe[player] and ahora - ultimoGolpe[player] < COOLDOWN_GOLPE then
      return
    end
    ultimoGolpe[player] = ahora
    aplicarGolpe(player, arbol)
  end
end)

print("[Hacha] Servidor cargado")
-- FIN SERVER HACHA
