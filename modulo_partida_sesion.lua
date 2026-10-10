-- PartidaSesion: ModuleScript en ServerScriptService (fabrica de sesiones).
-- El loader ya cargo los modulos; aqui se requieren por nombre (cache de require).
local SSS = game:GetService("ServerScriptService")
local ModMundo = require(SSS:WaitForChild("PartidaMundo", 15))
local ModObjetos = require(SSS:WaitForChild("PartidaObjetos", 15))
local ModLobos = require(SSS:WaitForChild("PartidaLobos", 15))
local ModFlujo = require(SSS:WaitForChild("PartidaFlujo", 15))

local function crear(E, ctx)
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
  calderoHongos = 0,
}
  local W = {}
  SE.castCd = {}
  local M = ModMundo(E, SE, ctx, W)
  local O = ModObjetos(E, SE, ctx, W)
  local L = ModLobos(E, SE, ctx, W, M)
  local F = ModFlujo(E, SE, ctx, W, M, O, L)
-- PLAYER EVENTS
--===========================================================
E.Players.PlayerAdded:Connect(function(player)
  player.CharacterAdded:Connect(function(char)
    SE.castCd[player] = nil
    if E.jugadorEnPartida(SE, player) and SE.players[player].vivo then
      -- reaparecio estando vivo en el bosque: cuenta como caido
      F.marcarMuerto(player)
      return
    end
    -- si no esta en partida, el NUCLEO ya lo mando al lobby
  end)
end)

E.Players.PlayerRemoving:Connect(function(player)
  if SE.players[player] then
    SE.players[player] = nil
    if SE.on and E.vivosEnPartida(SE) <= 0 then
      F.finPartida(false)
    end
  end
  SE.enCirculo[player] = nil
  SE.castCd[player] = nil
end)
  return {
    iniciar = F.iniciarPartida,
    golpe = L.golpeSombra,
    accion = O.accionRemota,
    cerrar = function()
      SE.terminada = true
    end,
  }
end
return crear
-- FIN MODULO PARTIDA SESION
