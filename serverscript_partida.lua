-- AVADA PARTIDA: loader (Script normal en ServerScriptService).
-- Los 6 modulos viven como ModuleScript en ServerScriptService:
--   PartidaEstado, PartidaMundo, PartidaObjetos, PartidaLobos, PartidaFlujo, PartidaSesion
-- Este loader: 1) crea los remotos SIEMPRE primero (aunque falte un modulo,
-- los clientes nunca se cuelgan), 2) carga los modulos con pcall y avisa
-- exactamente cual falta y donde pegarlo.
local SSS = game:GetService("ServerScriptService")
local RSvc = game:GetService("ReplicatedStorage")

local function remoto(nombre)
  local r = RSvc:FindFirstChild(nombre)
  if not r then
    r = Instance.new("RemoteEvent")
    r.Name = nombre
    r.Parent = RSvc
  end
  return r
end
remoto("AvadaBosqueUI")
remoto("AvadaBosqueAccion")

local mods = {}
local todoOk = true
for _, nombre in ipairs({ "PartidaEstado", "PartidaMundo", "PartidaObjetos", "PartidaLobos", "PartidaFlujo", "PartidaSesion" }) do
  local inst = SSS:WaitForChild(nombre, 15)
  if not inst then
    warn("[AvadaPartida] FALTA el ModuleScript '" .. nombre .. "' en ServerScriptService: crealo, pegale el archivo modulo_partida_" .. string.lower(string.sub(nombre, 8)) .. ".lua y dale Play.")
    todoOk = false
  else
    local ok, mod = pcall(require, inst)
    if not ok or mod == nil then
      warn("[AvadaPartida] ERROR al cargar '" .. nombre .. "': " .. tostring(mod))
      todoOk = false
    else
      mods[nombre] = mod
    end
  end
end

if todoOk then
  mods.PartidaEstado.crearPartida = mods.PartidaSesion
  print("[Avada] Partida en modulos lista (Estado+Mundo+Objetos+Lobos+Flujo+Sesion)")
else
  warn("[AvadaPartida] Modulos incompletos: el juego NO arranca, pero los remotos ya existen. Lee los avisos de arriba.")
end

-- FIN PARTIDA
