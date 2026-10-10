-- PartidaEstado: ModuleScript en ServerScriptService. Se requiere PRIMERO:
-- crea los remotos compartidos. El loader le inyecta E.crearPartida.
local E = {}
E.crearPartida = nil -- la asigna el loader (fabrica de PartidaSesion)
-- Archivo PARTIDA: la supervivencia en el Bosque Prohibido. Como en 99
-- Noches, nadie espera a nadie: cada grupo que entra al circulo juega SU
-- partida en SU propio mundo (un clon del bosque plantilla), asi que
-- puede haber varias partidas a la vez, cada una en su bosque.
local Players = game:GetService("Players")
local LOBBY_SPAWN = Vector3.new(0, 6, 0)

-- ESTADO DE LA PARTIDA
--===========================================================
local NOCHES_META = 7
local NOCHE_LEN = 140
local DIA_LEN = 50
local FC = Vector3.new(0, 0, 4200) -- centro del bosque plantilla

-- Remotos compartidos por todas las sesiones
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

--===========================================================
-- ENCARGADO DE SESIONES: reparte jugadores, mundos y avisos
--===========================================================
local SESIONES = {} -- [player] = sesion
local PARTIDAS = {} -- sesiones vivas (sin limite: mundos los que hagan falta)
local slotsEnUso = {}
local tplBosque, tplFogata, tplCaldero
local plantillasListas = false
local lobby = { cuentaAtras = 0, enCirculo = {} }
local circleTitle, circleStatus, circleSub
local ultimoCartel

local function pintarCartel(t, e, s)
  if circleTitle and circleStatus and circleSub then
    circleTitle.Text = t
    circleStatus.Text = e
    circleSub.Text = s
  end
end

local function refrescarCartelCirculo(titulo, estado, sub)
  if titulo ~= nil then
    ultimoCartel = { t = titulo, e = estado or "", s = sub or "", hasta = os.clock() + 6 }
    pintarCartel(titulo, estado or "", sub or "")
    return
  end
  if ultimoCartel and os.clock() < ultimoCartel.hasta and lobby.cuentaAtras <= 0 then
    pintarCartel(ultimoCartel.t, ultimoCartel.e, ultimoCartel.s)
    return
  end
  if not plantillasListas then
    local bq = workspace:FindFirstChild("BosqueProhibido")
    if not bq then
      pintarCartel("AVADA", "EL BOSQUE NO EXISTE EN EL MAPA", "El Script BOSQUE no esta corriendo")
    else
      pintarCartel("AVADA", "BOSQUE CARGANDO: " .. tostring(bq:GetAttribute("Etapa") or "inicio"), "Si no avanza, mandame una captura")
    end
    return
  end
  if lobby.cuentaAtras > 0 then
    local n = 0
    for _ in pairs(lobby.enCirculo) do
      n += 1
    end
    pintarCartel("BOSQUE PROHIBIDO", "La partida empieza en " .. math.ceil(lobby.cuentaAtras) .. "...", n .. " mago(s) entrando - entra tu tambien")
  elseif #PARTIDAS > 0 then
    pintarCartel("BOSQUE PROHIBIDO", #PARTIDAS .. " partida(s) en curso", "Párate en el círculo y empieza la tuya")
  else
    pintarCartel("BOSQUE PROHIBIDO", "Párate en el círculo para entrar", "Sobrevive 7 noches - Rescata a los 4 aprendices")
  end
end

-- El golpe de hechizo a los lobos llega aqui y se reparte a la sesion
-- del lanzador (cada partida tiene sus propios lobos)
local bfGolpeSesion = Instance.new("BindableFunction")
bfGolpeSesion.Name = "AvadaGolpeSombra"
bfGolpeSesion.Parent = game:GetService("ServerScriptService")
bfGolpeSesion.OnInvoke = function(caster, spellName)
  local s = SESIONES[caster]
  if s and s.golpe then
    return s.golpe(caster, spellName)
  end
  return false
end

-- Las acciones de los botones llegan aqui y van a la sesion del jugador
local RE_ACCION = remotoBosque("AvadaBosqueAccion")
RE_ACCION.OnServerEvent:Connect(function(player, accion)
  local s = SESIONES[player]
  if s and s.accion then
    s.accion(player, accion)
  end
end)

--===========================================================
-- UNA SESION = UNA PARTIDA EN SU PROPIO MUNDO
--===========================================================
function E.jugadorEnPartida(SE, player)
  return SE.on and SE.players[player] ~= nil
end

function E.vivosEnPartida(SE)
  local n = 0
  for _, d in pairs(SE.players) do
    if d.vivo then
      n += 1
    end
  end
  return n
end
local bfDanoCache, bfBajaCache
function E.danoHechizo(nombre)
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
function E.bajaKill(player)
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
-- CREAR UNA SESION: clona el mundo plantilla a su propio centro
--===========================================================
local function crearSesion(lista)
  if not E.crearPartida then
    warn("[AvadaPartida] Estado sin fabrica: falta el ModuleScript PartidaSesion")
    return false
  end
  if not plantillasListas then
    return false
  end
  local slot = 1
  while slotsEnUso[slot] do
    slot += 1
  end
  slotsEnUso[slot] = true
  local delta = Vector3.new(3000 * slot, 0, 0)
  local modelo = tplBosque:Clone()
  local fog = tplFogata:Clone()
  local cal = tplCaldero:Clone()
  local function mover(m)
    pcall(function()
      m:PivotTo(CFrame.new(delta) * m:GetPivot())
    end)
    m.Parent = workspace
  end
  mover(modelo)
  mover(fog)
  mover(cal)
  local entrada = { slot = slot }
  local function limpiarEntrada()
    if entrada.api and entrada.api.cerrar then
      pcall(entrada.api.cerrar)
    end
    slotsEnUso[slot] = nil
    for i, e in ipairs(PARTIDAS) do
      if e == entrada then
        table.remove(PARTIDAS, i)
        break
      end
    end
    for pl, s in pairs(SESIONES) do
      if s == entrada.api then
        SESIONES[pl] = nil
      end
    end
    pcall(function()
      modelo:Destroy()
    end)
    pcall(function()
      fog:Destroy()
    end)
    pcall(function()
      cal:Destroy()
    end)
    refrescarCartelCirculo()
  end
  local ctx = {
    modelo = modelo,
    fogata = fog,
    caldero = cal,
    avisar = function(t, e, s)
      refrescarCartelCirculo(t, e, s)
    end,
    alTerminar = function()
      limpiarEntrada()
    end,
  }
  local api = E.crearPartida(E, ctx)
  entrada.api = api
  table.insert(PARTIDAS, entrada)
  local vivos = {}
  for _, pl in ipairs(lista) do
    if pl and pl.Parent then
      table.insert(vivos, pl)
      SESIONES[pl] = api
    end
  end
  if #vivos == 0 then
    limpiarEntrada()
    return false
  end
  local okIniciar, resIniciar = pcall(function()
    return api.iniciar(vivos)
  end)
  if not okIniciar or resIniciar ~= true then
    limpiarEntrada()
    return false
  end
  refrescarCartelCirculo()
  return true
end

-- Circulo del lobby: la cuenta atras arranca sola en cuanto alguien
-- entra, haya o no otra partida en curso (cada quien a su mundo)
task.spawn(function()
  while true do
    task.wait(0.3)
    local dentro = {}
    for _, player in ipairs(Players:GetPlayers()) do
      if not SESIONES[player] then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
          local flat = Vector2.new(hrp.Position.X, hrp.Position.Z)
          if flat.Magnitude <= 12.5 and hrp.Position.Y > 1 and hrp.Position.Y < 14 then
            dentro[player] = true
          end
        end
      end
    end
    lobby.enCirculo = dentro
    local n = 0
    for _ in pairs(dentro) do
      n += 1
    end
    if n >= 1 and lobby.cuentaAtras <= 0 then
      lobby.cuentaAtras = 12
    end
    if lobby.cuentaAtras > 0 then
      lobby.cuentaAtras -= 0.3
      if lobby.cuentaAtras <= 0 then
        local lista = {}
        for player, _ in pairs(dentro) do
          table.insert(lista, player)
        end
        if #lista >= 1 and not crearSesion(lista) then
          lobby.cuentaAtras = 6 -- mundos llenos o cargando: reintenta
        end
      end
    end
    refrescarCartelCirculo()
  end
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
  refrescarCartelCirculo()
end)

-- las plantillas: el bosque que construye BOSQUE, la fogata y el
-- caldero quedan de molde; cada partida clona los suyos
task.spawn(function()
  while not plantillasListas do
    local b = workspace:FindFirstChild("BosqueProhibido")
    local f = workspace:FindFirstChild("FogataMagica")
    local c = workspace:FindFirstChild("Cauldron")
    if b and b:GetAttribute("Completo") and f and c then
      tplBosque, tplFogata, tplCaldero = b, f, c
      plantillasListas = true
      print("[Avada] Mundos listos: cada partida tendra su propio bosque")
    end
    task.wait(0.5)
  end
end)

Players.PlayerRemoving:Connect(function(player)
  SESIONES[player] = nil
  lobby.enCirculo[player] = nil
end)

print("[Avada] Bosque Prohibido listo: supervivencia de magos en 7 noches")

-- exports para los demas modulos
E.Players = Players
E.RE_UI = RE_UI
E.RE_ACCION = RE_ACCION
E.NOCHES_META = NOCHES_META
E.NOCHE_LEN = NOCHE_LEN
E.DIA_LEN = DIA_LEN
E.LOBBY_SPAWN = LOBBY_SPAWN
E.FC = FC
E.SESIONES = SESIONES
E.PARTIDAS = PARTIDAS
E.lobby = lobby
E.refrescarCartelCirculo = refrescarCartelCirculo
E.crearSesion = crearSesion
return E
-- FIN MODULO PARTIDA ESTADO
