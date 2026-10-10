-- PartidaMundo: ModuleScript en ServerScriptService (mundo, fuego, animacion).
-- Fabrica por sesion: crear(E, SE, ctx, W).
local function crear(E, SE, ctx, W)
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
W.Bosque, W.fuegoPos, W.deposito, W.llamaParts, W.llamaBase, W.llamaLight, W.anilloSeguro, W.chispasFuego, W.paredes = nil, nil, nil, nil, nil, nil, nil, nil, nil
W.jaulas, W.jaulasPos, W.moras, W.hongos, W.cofres, W.fireStatus = {}, {}, {}, {}, {}, nil
W.bosqueListo = false
SE.lobosFaltan, SE.loboAvisoDado = false, false
W.fireBoardAnchor = nil

local function escanearBosque()
  W.Bosque = ctx.modelo
  if not (W.Bosque and W.Bosque:GetAttribute("Listo")) then
    return false
  end

  if W.Bosque then
    -- fuego y W.deposito
    W.llamaParts = {}
    W.llamaBase = { [1] = Vector3.new(2.6, 2.2, 2.6), [2] = Vector3.new(1.9, 2.0, 1.9), [3] = Vector3.new(1.2, 1.8, 1.2) }
    W.anilloSeguro = {}
    W.paredes = {}
    W.moras, W.hongos, W.cofres, W.jaulas, W.jaulasPos = {}, {}, {}, {}, {}
    local morasPorClave = {}
    local hongosPorId = {}
    for _, d in ipairs(W.Bosque:GetDescendants()) do
      if d:IsA("BasePart") then
        local g = d:GetAttribute("Grupo")
        if g == "Llama" then
          W.llamaParts[d:GetAttribute("Idx") or 1] = d
        elseif g == "Anillo" then
          table.insert(W.anilloSeguro, { part = d, ang = d:GetAttribute("Ang") or 0 })
        elseif g == "Pared" then
          table.insert(W.paredes, { part = d, ang = d:GetAttribute("Ang") or 0, tapa = d:GetAttribute("Tapa") == true })
        end
        if d:GetAttribute("Rol") == "Deposito" then
          W.deposito = d
        elseif d:GetAttribute("Rol") == "FireAnchor" then
          W.fireBoardAnchor = d
          W.fuegoPos = d.Position - Vector3.new(0, 11, 0)
        end
        local tipo = d:GetAttribute("Tipo")
        if tipo == "Mora" or tipo == "MoraCorona" or tipo == "MoraRabito" then
          local gi = d:GetAttribute("Arbusto") or 1
          local mj = d:GetAttribute("MoraId") or 1
          local clave = gi .. "/" .. mj
          morasPorClave[clave] = morasPorClave[clave] or {}
          morasPorClave[clave][tipo] = d
        elseif tipo == "Cofre" then
          table.insert(W.cofres, { pos = d.Position, listo = 0, base = d })
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
        table.insert(W.moras, { mora = conj.Mora, corona = conj.MoraCorona, rabito = conj.MoraRabito, disponible = true })
      end
    end
    for _, hg in pairs(hongosPorId) do
      if hg.cap then
        hg.disponible = true
        table.insert(W.hongos, hg)
      end
    end
    if W.llamaParts[1] then
      W.llamaLight = W.llamaParts[1]:FindFirstChildOfClass("PointLight")
      W.chispasFuego = W.llamaParts[1]:FindFirstChild("FireSparks")
    end
    -- W.jaulas: anclas etiquetadas con su indice
    for _, d in ipairs(W.Bosque:GetDescendants()) do
      if d:IsA("BasePart") and d:GetAttribute("Jaula") and d.Name == "CageAnchor" then
        local ci = d:GetAttribute("Jaula")
        local posJ = d.Position - Vector3.new(0, 10, 0)
        W.jaulasPos[ci] = posJ
        local gui = d:FindFirstChildOfClass("BillboardGui")
        W.jaulas[ci] = {
          pos = posJ,
          fig = nil,
          barrotes = {},
          label = gui and gui:FindFirstChildOfClass("TextLabel"),
          libre = false,
          rescatado = false,
        }
      end
    end
    for _, d in ipairs(W.Bosque:GetDescendants()) do
      if d:IsA("Model") and d:GetAttribute("Jaula") then
        local j = W.jaulas[d:GetAttribute("Jaula")]
        if j then
          j.fig = d
        end
      elseif d:IsA("BasePart") and d:GetAttribute("Jaula") and d.Name == "CageBar" then
        local j = W.jaulas[d:GetAttribute("Jaula")]
        if j then
          table.insert(j.barrotes, d)
        end
      end
    end
    if W.fireBoardAnchor then
      local gui = W.fireBoardAnchor:FindFirstChildOfClass("BillboardGui")
      if gui then
        W.fireStatus = gui:FindFirstChild("FireStatus")
      end
    end
  end

  W.bosqueListo = true
  return true
end

-- Archivo PARTIDA: la supervivencia en el W.Bosque Prohibido (noche, llama, hambre, lobos, rescates).
local Players = game:GetService("Players")
local LOBBY_SPAWN = Vector3.new(0, 6, 0)

-- CARTELES
--===========================================================
local function updateFireBoard()
  if not (W.llamaParts and W.llamaBase and W.fuegoPos) then
    return -- el bosque aun no se descubre: nada que actualizar
  end
  if W.fireStatus and SE.lobosFaltan and SE.on then
    W.fireStatus.Text = "FALTAN LOS LOBOS: pega el Script LOBOS"
  elseif W.fireStatus then
    W.fireStatus.Text = "Llama "
    .. math.floor(SE.llama)
    .. "% - Fogata Nivel "
    .. (SE.nivel or 1)
    .. " - Noche "
    .. math.max(SE.noche, 1)
    .. "/"
    .. E.NOCHES_META
    .. " - Aprendices "
    .. SE.aprendices
    .. "/4"
  end
  -- el tamano y el baile de la llama los lleva el animador (abajo);
  -- aqui solo respira el anillo seguro en el suelo
  local radio = 16 + (SE.nivel or 1) * 3 + SE.llama * 0.08
  local largoSeg = math.max(3.4, radio * 0.22)
  for _, sd in ipairs(W.anilloSeguro) do
    sd.part.Size = Vector3.new(largoSeg, 0.25, 0.8)
    sd.part.CFrame = CFrame.new(W.fuegoPos.X, W.fuegoPos.Y + 0.12, W.fuegoPos.Z) * CFrame.Angles(0, -sd.ang, 0) * CFrame.new(0, 0, radio)
  end
end

local function radioSeguro()
  return 16 + (SE.nivel or 1) * 3 + SE.llama * 0.08
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
  if not W.fuegoPos then
    return
  end
  local R = paredRadio()
  for _, pw in ipairs(W.paredes or {}) do
    local px = W.fuegoPos.X + math.cos(pw.ang) * R
    local pz = W.fuegoPos.Z + math.sin(pw.ang) * R
    local y = pw.tapa and 20.4 or 11
    pw.part.CFrame = CFrame.new(Vector3.new(px, y, pz), Vector3.new(W.fuegoPos.X, y, W.fuegoPos.Z))
  end
end

--===========================================================
--===========================================================
-- La Fogata Magica (fogata nueva del dueno): encendida mientras la
-- llama tenga nivel; al llegar a 0 se apaga sola (attribute Lit)
W.fogataModelo = nil
local function sincronizarFogata()
  if not W.fogataModelo or not W.fogataModelo.Parent then
    W.fogataModelo = ctx.fogata
  end
  if W.fogataModelo then
    W.fogataModelo:SetAttribute("Lit", SE.llama > 0)
  end
end
task.spawn(function()
  while not SE.terminada do
    task.wait(0.5)
    sincronizarFogata()
  end
end)
-- ANIMADOR DE LA LLAMA: pulso, lengua que sube y se recoge, luz que tiembla
task.spawn(function()
  local t = 0
  while not SE.terminada do
    task.wait(0.1)
    t += 0.1
    if W.llamaParts and W.llamaBase and W.fuegoPos then
      local viva = SE.llama > 0
      local f = viva and (0.35 + (SE.llama / 100) * 0.85) or 0.02
      for i, fp in ipairs(W.llamaParts) do
        local bse = W.llamaBase[i]
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
          W.fuegoPos.X + 0.1 * math.sin(t * 2.6 + i * 1.7),
          W.fuegoPos.Y + 0.7 + (i - 1) * 1.4 * f + subida,
          W.fuegoPos.Z + 0.08 * math.cos(t * 3.1 + i)
        ) * CFrame.Angles(0, t * (0.5 + i * 0.13), 0)
      end
      if W.llamaLight then
        W.llamaLight.Brightness = viva and (2.0 + (SE.llama / 100) * 0.9 + 0.35 * math.sin(t * 9.3) + 0.18 * math.sin(t * 23.7)) or 0
        W.llamaLight.Range = (16 + SE.llama * 0.2) * (0.95 + 0.05 * math.sin(t * 6.1))
      end
      if W.chispasFuego then
        W.chispasFuego.Enabled = viva
      end
    end
  end
end)


  return {
    escanearBosque = escanearBosque,
    clasicoEn = clasicoEn,
    updateFireBoard = updateFireBoard,
    moverPared = moverPared,
    radioSeguro = radioSeguro,
    lenosParaNivel = lenosParaNivel,
  }
end
return crear
-- FIN MODULO PARTIDA MUNDO
