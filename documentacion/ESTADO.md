# Estado de los mapas (v1.1.0)

v1.1.0 añade combate automático (`ai_status >= 5` pausa el seguimiento). Mapas con build v1.1.0: `a10` (`0xC8B958B9`), `a30` (`0xE924C28D`), `a50` (`0x990EFF56`), `b30` (`0x01F411FF`), `b40` (`0xCEC64D0A`), `c10` (`0x9A91B413`), `c40` (`0xC982381C`), `d40` (`0x198E6D09`). Aún no instalados porque el juego estaba abierto.

Todos los mapas verificados tienen el encuentro `mod_marines` con `runtime = -1` en el caché.

| Mapa | CRC instalado | Estado |
|---|---|---|
| a10 | `0xB521EA14` | ✅ completo (F6 / F7 / F8, dummies invisibles) |
| a30 | `0xBA9E8121` | ✅ completo |
| a50 | `0x81064D51` | ✅ completo |
| b30 | `0xAE541F63` | ✅ completo |
| b40 | `0x796857C4` | ✅ completo |
| c10 | `0xC2CEDBCB` | ✅ completo |
| c40 | `0x3792776F` | ✅ completo |
| d40 | `0x1407E58B` | ✅ completo |
| c20 | build anterior | ⚠️ sin mod funcional: el tag original no tiene paleta de vehículos y no se pudo crear el señuelo |
| d20 | `0x92E6D826` | ⚠️ F6 funciona; F8 no se pudo habilitar porque el mapa supera el límite de 23 MiB de tag space |

## Mapas no disponibles

No había archivos para: `a20`, `a40`, `b10`, `b20`, `c30`, `c50`, `d30`.
La progresión del juego no crea archivos `.map`: están en la instalación. Para modificarlos hay que copiarlos a `Halo-PC\MAPS` y ejecutar `aplicar-mod-mision.ps1 -Map <nombre>`.

## Notas de construcción

- `invader-bludgeon -T everything -b "*"` es necesario en casi todos los mapas: la extracción desde el caché deja índices, enums y lens flares inválidos que `invader-build` rechaza.
- Tras cualquier `invader-edit` hay que repetir `fijar-runtime-bsp.ps1 -Runtime -1`, porque Invader reescribe el tag.
- El juego debe estar cerrado para copiar los `.map` a `Halo-PC\MAPS`.
