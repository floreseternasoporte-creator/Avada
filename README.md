# Avada — Sobrevive en el Bosque Prohibido

Juego de supervivencia en Roblox (estilo 99 Noches, mundo propio):
círculo del campamento con cuenta atrás, partidas de 7 noches
(día 50 s / noche 140 s), Llama Mágica, hambre, Lobo Sombrío,
caldero, tienda y vendedora mágica, esencias como moneda.

## Estructura

**Servidor** — van en `ServerScriptService`:

| Archivo | Clase en Studio | Nombre en Studio | Última línea |
|---|---|---|---|
| serverscript_partida.lua | Script | `AvadaPartida` | `-- FIN PARTIDA` |
| modulo_partida_estado.lua | ModuleScript | `PartidaEstado` | `-- FIN MODULO PARTIDA ESTADO` |
| modulo_partida_mundo.lua | ModuleScript | `PartidaMundo` | `-- FIN MODULO PARTIDA MUNDO` |
| modulo_partida_objetos.lua | ModuleScript | `PartidaObjetos` | `-- FIN MODULO PARTIDA OBJETOS` |
| modulo_partida_lobos.lua | ModuleScript | `PartidaLobos` | `-- FIN MODULO PARTIDA LOBOS` |
| modulo_partida_flujo.lua | ModuleScript | `PartidaFlujo` | `-- FIN MODULO PARTIDA FLUJO` |
| modulo_partida_sesion.lua | ModuleScript | `PartidaSesion` | `-- FIN MODULO PARTIDA SESION` |
| serverscript_nucleo.lua | Script | (el de siempre) | (ver archivo) |
| serverscript_bosque.lua | Script | (el de siempre) | `-- FIN BOSQUE` |
| serverscript_isla.lua | Script | (el de siempre) | `-- FIN ISLA (lobby visual: isla flotante + tabla TOP SORCERERS)` |
| serverscript_tienda.lua | Script | (el de siempre) | `-- FIN TIENDA` |
| serverscript_lobos.lua | Script | (el de siempre) | `-- FIN LOBOS` |
| serverscript_vendedora.lua | Script | (el de siempre) | `-- FIN VENDEDORA` |
| serverscript_caldero.lua | Script | (el de siempre) | `-- FIN CALDERO` |

La partida está dividida en 6 módulos + 1 loader. El loader
(`AvadaPartida`) crea los remotos SIEMPRE primero y carga los
módulos con `pcall`: si falta uno, avisa cuál es en el Output
en vez de colgarse. Los nombres de los ModuleScript tienen que
ser EXACTOS.

**Cliente** — van en `StarterPlayer > StarterPlayerScripts`,
un `LocalScript` por archivo:

| Archivo | Última línea a verificar |
|---|---|
| localscript.lua | (ver archivo) |
| localscript_bosque.lua | `-- FIN LOCAL BOSQUE` |
| localscript_caldero.lua | `-- FIN LOCAL CALDERO` |
| localscript_caldero_anim.lua | `-- FIN LOCAL CALDERO ANIM` |
| localscript_esencias.lua | `-- FIN LOCAL ESENCIAS` |

## Regla de pegado en Studio (importante)

Roblox rechaza el pegado si el Script acumula texto viejo
(límite: 200.000 caracteres). Siempre:

1. Borrar el OBJETO completo en el Explorer (clic derecho → Delete),
   no solo el texto.
2. Crear un `Script` / `LocalScript` / `ModuleScript` nuevo y vacío
   con el nombre exacto de la tabla.
3. Pegar UNA sola vez y verificar la última línea de la tabla.
4. Stop → Play.

## Verificación

Pega el `detector_modulos.lua` (está en el repo local, no aquí)
en View → Command Bar de Studio y dale Enter: todo debe salir OK.
Si falta un módulo, el Output del servidor lo dice al arrancar.
