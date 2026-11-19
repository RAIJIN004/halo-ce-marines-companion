# Estado de los mapas (v1.3.0)

v1.3.0 añade la caza automática: en combate, el señuelo invisible se engancha al encuentro enemigo que ve a los marines y estos avanzan hacia él con el mismo mecanismo del escolta. Las maniobras de la escuadra se desactivan para evitar la voz de "retirada" y se emiten 8 órdenes por ciclo para reducir los trabones.

Mapas con build e instalación v1.3.0:

| Mapa | CRC instalado | Estado |
|---|---|---|
| a10 | `0x24C1DC26` | ✅ completo (cadena de caza reducida a 9 encuentros por el límite de nodos) |
| a30 | `0xDFF9A736` | ✅ completo |
| a50 | `0xE6186431` | ✅ completo |
| b30 | `0xA677ADB1` | ✅ completo (prototipo de la caza, verificado en juego) |
| b40 | `0x38BDB14B` | ✅ completo |
| c10 | `0xC9A9AD50` | ✅ completo |
| c40 | `0x56943CA2` | ✅ completo |
| d40 | `0x94084A5F` | ✅ completo |
| c20 | build anterior | ⚠️ sin mod funcional: el tag original no tiene paleta de vehículos y no se pudo crear el señuelo |
| d20 | `0x92E6D826` | ⚠️ F6 funciona; F8/caza no se pudieron habilitar porque el mapa supera el límite de 23 MiB de tag space |

Todos los mapas v1.3.0 verificados tienen el encuentro `mod_marines` con `runtime = -1` en el caché.

## Mapas no disponibles

No había archivos para: `a20`, `a40`, `b10`, `b20`, `c30`, `c50`, `d30`.
La progresión del juego no crea archivos `.map`: están en la instalación. Para modificarlos hay que copiarlos a `Halo-PC\MAPS` y ejecutar `aplicar-mod-mision.ps1 -Map <nombre>`.

## Notas de construcción

- `invader-bludgeon -T everything -b "*"` es necesario en casi todos los mapas: la extracción desde el caché deja índices, enums y lens flares inválidos que `invader-build` rechaza.
- Tras cualquier `invader-edit` hay que repetir `fijar-runtime-bsp.ps1 -Runtime -1`, porque Invader reescribe el tag.
- El juego debe estar cerrado para copiar los `.map` a `Halo-PC\MAPS`.
- `aplicar-caza-mision.ps1 -Map <mapa>` genera la cadena de encuentros leyendo los nombres del tag, reemplaza el bucle de escolta y recompila. En `a10` hay que usar una cadena reducida de 9 encuentros: el motor retail tiene un techo de 19.001 nodos de script y el mapa ya estaba en 18.976.
