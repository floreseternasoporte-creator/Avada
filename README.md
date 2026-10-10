# Avada — Sobrevive en el Bosque Prohibido

Juego de supervivencia en Roblox (estilo 99 Noches, mundo propio):
círculo del campamento con cuenta atrás, partidas de 7 noches
(día 50 s / noche 140 s), Llama Mágica, hambre, Lobo Sombrío,
caldero, tienda y vendedora mágica, esencias como moneda.

## Estructura (13 archivos, commit 612c176)

**Servidor** — van en `ServerScriptService`, un `Script` por archivo:

| Archivo | Última línea a verificar |
|---|---|
| serverscript_nucleo.lua | (ver archivo) |
| serverscript_bosque.lua | `-- FIN BOSQUE` |
| serverscript_partida.lua | `-- FIN PARTIDA` |
| serverscript_isla.lua | `-- FIN ISLA (lobby visual: isla flotante + tabla TOP SORCERERS)` |
| serverscript_tienda.lua | `-- FIN TIENDA` |
| serverscript_lobos.lua | `-- FIN LOBOS` |
| serverscript_vendedora.lua | `-- FIN VENDEDORA` |
| serverscript_caldero.lua | `-- FIN CALDERO` |

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
2. Crear un `Script` / `LocalScript` nuevo y vacío.
3. Pegar UNA sola vez y verificar la última línea de la tabla.
4. Stop → Play.

## Nota

Los 13 `.lua` están congelados en el commit `612c176`
("Update localscript_caldero.lua"). Este README no los modifica.
