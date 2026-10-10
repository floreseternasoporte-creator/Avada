-- PartidaFlujo: ModuleScript en ServerScriptService (ciclo dia/noche, sesiones).
-- Fabrica por sesion: crear(E, SE, ctx, W, M, O, L).
local function crear(E, SE, ctx, W, M, O, L)
-- FLUJO DE LA PARTIDA
--===========================================================
local LightingSvc = game:GetService("Lighting")

local function volverAlLobby(player)
  O.limpiarObjetos(player)
  local char = player and player.Character
  if char then
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
      hum.Health = hum.MaxHealth
    end
    if hrp then
      hrp.CFrame = CFrame.new(E.LOBBY_SPAWN + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
    end
  end
end

local function finPartida(victoria)
  if not SE.on then
    return
  end
  SE.on = false
  L.destruirLobos(false)
  LightingSvc.ClockTime = 13.2
  LightingSvc.FogEnd = 100000
  if ctx.avisar then
    if victoria then
      ctx.avisar("BOSQUE SUPERADO", "Los magos vencieron las " .. E.NOCHES_META .. " noches", "Párate en el círculo para jugar otra vez")
    else
      ctx.avisar("BOSQUE PROHIBIDO", "La partida termino en la noche " .. math.max(SE.noche, 1), "Párate en el círculo para jugar otra vez")
    end
  end
  for player, _ in pairs(SE.players) do
    O.sincronizaUI(player)
    volverAlLobby(player)
  end
  SE.players = {}
  SE.cuentaAtras = 0
  SE.enCirculo = {}
  SE.terminada = true
  if ctx.alTerminar then
    ctx.alTerminar()
  end
end

local function marcarMuerto(player)
  local d = SE.players[player]
  if not d or not d.vivo then
    return
  end
  d.vivo = false
  volverAlLobby(player)
  if E.vivosEnPartida(SE) <= 0 then
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
    L.crearLoboPartida(Vector3.new(W.fuegoPos.X + math.cos(a) * r, 2.0, W.fuegoPos.Z + math.sin(a) * r), "bosque")
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
    local pos = Vector3.new(W.fuegoPos.X + math.cos(a) * 150, 2.0, W.fuegoPos.Z + math.sin(a) * 150)
    L.crearLoboPartida(pos, "normal")
  end
  -- incursiones: en las noches 3 y 6 algunos lobos entran hasta la fogata
  if SE.noche == 3 or SE.noche == 6 then
    local n = (SE.noche == 3) and 2 or 4
    for i = 1, n do
      local a = math.random() * math.pi * 2
      local pos = Vector3.new(W.fuegoPos.X + math.cos(a) * 130, 2.0, W.fuegoPos.Z + math.sin(a) * 130)
      L.crearLoboPartida(pos, "raider")
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
      L.crearLoboPartida(Vector3.new(W.fuegoPos.X + math.cos(a) * 160, 2.0, W.fuegoPos.Z + math.sin(a) * 160), "grande")
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
    M.updateFireBoard()
    local tDia = 0
    while SE.on and tDia < E.DIA_LEN do
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
    M.updateFireBoard()
    if ctx.avisar then ctx.avisar() end
    local tNoche = 0
    local nocheDur = math.max(E.NOCHE_LEN - SE.aprendices * 12, 70)
    while SE.on and tNoche < nocheDur do
      task.wait(1)
      tNoche += 1
      -- la llama se consume mas rapido de noche
      SE.llama = math.max(0, SE.llama - (100 / (E.NOCHE_LEN * 1.25)) * (1 - 0.07 * ((SE.nivel or 1) - 1)))
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
        if ctx.avisar then ctx.avisar("BOSQUE PROHIBIDO", "LA LLAMA SE APAGO - fin de la partida", "") end
        task.wait(2)
        finPartida(false)
        return
      end
      M.updateFireBoard()
    end
    if not SE.on then
      break
    end
    -- recompensa: sobrevivir la noche paga Esencias (la noche 1 paga
    -- 1, la 2 paga 2... una partida perfecta paga 28 en total)
    for player, d in pairs(SE.players) do
      if d.vivo then
        L.llamarEsencias(player, SE.noche)
      end
    end
    -- amanecer: los lobos de la noche desaparecen
    L.destruirLobos(true)
    if SE.noche >= E.NOCHES_META then
      finPartida(true)
      return
    end
    if ctx.avisar then ctx.avisar() end
  end
end

-- El lobo trae su propia IA (archivo LOBOS). Este bucle vigila la
-- regla de la fogata: el anillo de la llama es una PARED para los
-- lobos (salvo los de las incursiones 3 y 6): el que lo cruza es
-- empujado fuera al instante y el fuego lo quema.
local function bucleLobos()
  while not SE.terminada do
    task.wait(0.15)
    if SE.on then
      local radio = M.radioSeguro()
      for _, som in ipairs(SE.sombras) do
        if som.root and som.root.Parent and som.tipo ~= "raider" then
          local rp = som.root.Position
          local dx, dz = rp.X - W.fuegoPos.X, rp.Z - W.fuegoPos.Z
          local dist = math.sqrt(dx * dx + dz * dz)
          if SE.llama > 0 and dist < radio + 4 then
            local dm = math.max(dist, 0.01)
            local nx = W.fuegoPos.X + (dx / dm) * (radio + 3)
            local nz = W.fuegoPos.Z + (dz / dm) * (radio + 3)
            local look = som.root.CFrame.LookVector
            pcall(function()
              som.root.CFrame = CFrame.new(Vector3.new(nx, rp.Y, nz), Vector3.new(nx + look.X, rp.Y, nz + look.Z))
            end)
            L.danarLobo(som, (dist < 7) and 26 or 8, W.fuegoPos, nil)
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
    local player = char and E.Players:GetPlayerFromCharacter(char)
    return player
  end
  for _, fr in ipairs(W.moras) do
    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 14
    cd.Parent = fr.mora
    cd.MouseClick:Connect(function(player)
      O.recogerMoraDelArbusto(player, fr)
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
        O.recogerMoraDelArbusto(pl, fr)
      end
    end)
  end
  for _, hg in ipairs(W.hongos) do
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
      O.recogerHongo(player, hg)
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
        O.recogerHongo(pl, hg)
      end
    end)
  end
  W.deposito.Touched:Connect(function(hit)
    if not SE.on then
      return
    end
    local player = jugadorDe(hit)
    if player and E.jugadorEnPartida(SE, player) and SE.players[player].vivo then
      local d = SE.players[player]
      if d.lenos > 0 then
        SE.llama = math.min(100, SE.llama + d.lenos * 18)
        SE.fogataXP = (SE.fogataXP or 0) + d.lenos
        d.lenos = 0
        O.sincronizaUI(player)
        while (SE.nivel or 1) < E.NIVEL_MAX and SE.fogataXP >= M.lenosParaNivel(SE.nivel or 1) do
          SE.fogataXP = SE.fogataXP - M.lenosParaNivel(SE.nivel or 1)
          SE.nivel = (SE.nivel or 1) + 1
          M.moverPared()
          print("[Avada] La fogata subio al nivel " .. SE.nivel .. ": el bosque se expande")
        end
        M.updateFireBoard()
      end
    end
  end)
  -- W.jaulas: tocar al aprendiz cuando la jaula esta abierta
  for ci, j in ipairs(W.jaulas) do
    for _, pp in ipairs(j.fig and j.fig:GetChildren() or {}) do
      if pp:IsA("BasePart") then
        pp.Touched:Connect(function(hit)
          if not SE.on or not j.libre or j.rescatado then
            return
          end
          local player = jugadorDe(hit)
          if player and E.jugadorEnPartida(SE, player) and SE.players[player].vivo then
            j.rescatado = true
            SE.aprendices += 1
            if j.label then j.label.Text = "Aprendiz rescatado" end
            -- el aprendiz se muda junto a la fogata
            local ang = ci * (math.pi / 2) + 0.4
            local dest = Vector3.new(W.fuegoPos.X + math.cos(ang) * 11, W.fuegoPos.Y, W.fuegoPos.Z + math.sin(ang) * 11)
            for _, f2 in ipairs(j.fig and j.fig:GetChildren() or {}) do
              local off = f2.CFrame.Position - j.pos
              f2.CFrame = CFrame.new(dest + Vector3.new(off.X, off.Y - 0.8, off.Z)) * CFrame.Angles(0, -ang - math.pi / 2, 0)
            end
            M.updateFireBoard()
            if ctx.avisar then ctx.avisar() end
          end
        end)
      end
    end
  end
  -- Cofres: toque en la base (hambre o lenos, cada 30 s)
  for _, cof in ipairs(W.cofres) do
  if cof.base then
    cof.base.Touched:Connect(function(hit)
      if not SE.on or os.clock() < cof.listo then
        return
      end
      local char = hit and hit.Parent
      local player = char and E.Players:GetPlayerFromCharacter(char)
      if player and E.jugadorEnPartida(SE, player) and SE.players[player].vivo then
        cof.listo = os.clock() + 30
        if math.random() < 0.5 then
          SE.players[player].lenos += 2
        else
          SE.players[player].hambre = math.min(100, SE.players[player].hambre + 40)
        end
        O.sincronizaUI(player)
      end
    end)
  end
  end
end

local function prepararMundo()
  SE.lobosFaltan = false
  SE.loboAvisoDado = false
  SE.llama = 100
  SE.nivel = 1
  SE.fogataXP = 0
  SE.calderoHongos = 0
  M.moverPared()
  SE.noche = 0
  SE.aprendices = 0
  L.destruirLobos(false)
  L.llamarLobos("conReaparicion")
  for ci, j in ipairs(W.jaulas) do
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
    L.crearLoboPartida(Vector3.new(j.pos.X - 7, 2.0, j.pos.Z - 7), "guardian", ci)
    L.crearLoboPartida(Vector3.new(j.pos.X + 7, 2.0, j.pos.Z - 7), "guardian", ci)
  end
  M.updateFireBoard()
end

local function iniciarPartida(lista)
  if not W.bosqueListo then
    M.escanearBosque()
  end
  if not W.bosqueListo then
    print("[Avada] La partida espera: falta descubrir el bosque (archivo BOSQUE)")
    return false
  end
  conectarToques()
  SE.on = true
  SE.players = {}
  prepararMundo()
  local k = 0
  for _, player in ipairs(lista) do
    if player and player.Parent then
      k += 1
      SE.players[player] = { vivo = true, lenos = 0, hambre = 100, saco = {}, sacoEnMano = false, enMano = nil, toolSaco = nil }
      O.darSacoMago(player)
      O.sincronizaUI(player)
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
        if hrp and W.fuegoPos then
          local ang = (k / math.max(#lista, 1)) * math.pi * 2
          hrp.CFrame = CFrame.new(W.fuegoPos + Vector3.new(math.cos(ang) * 9, 1.5, math.sin(ang) * 9))
        end
      end
    end
  end
  if ctx.avisar then ctx.avisar() end
  task.spawn(cicloPartida)
  return true
end

--===========================================================
  return {
    iniciarPartida = iniciarPartida,
    marcarMuerto = marcarMuerto,
    finPartida = finPartida,
  }
end
return crear
-- FIN MODULO PARTIDA FLUJO
