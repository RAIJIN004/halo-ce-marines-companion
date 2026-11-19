# Halo CE — Marines Companion (v1.3.0)

Mod para la campaña retail de **Halo: Combat Evolved (2003, Gearbox)** que permite invocar marines armados en la posición del jugador, ordenarles que lo sigan caminando sin subirse a vehículos y hacer que cacen a los enemigos que detecten.

## Estado

✅ **v1.3.0** — caza automática: los marines avanzan hacia el encuentro enemigo que los ve.
✅ **v1.2.0** — `ai_attack` / `ai_defend` al entrar y salir de combate.
✅ **v1.1.0** — modo combate automático añadido.
✅ **v1.0.0** — primera versión funcional.
- Compatible con el juego retail original (PC, build 01.00.00.0564).
- El multijugador en línea sigue funcionando: no se tocan mapas de multiplayer ni el `globals` compartido.
- Solo herramientas oficiales/abiertas: Invader (`invader-edit`, `invader-script`, `invader-build`, `invader-extract`, `invader-bludgeon`) y Chimera para los atajos de teclado.

## Funciones

| Tecla | Acción |
|---|---|
| **F6** | Crea 2 marines armados justo en los pies del jugador. 24 ranuras (12 pulsaciones) antes de reciclar. Nunca sobrescribe marines vivos. |
| **F7** | Trae a todos los marines creados por F6 hasta los pies del jugador. |
| **F8** | Activa/desactiva el modo escolta: los marines caminan hacia el jugador de forma continua y se detienen cerca, **sin subirse al vehículo**. |

### Cómo funciona el seguimiento (el truco del warthog)

HaloScript no tiene una orden "camina hacia esta unidad y quédate ahí". `ai_go_to_vehicle` sí hace pathfinding directo hacia un vehículo, pero el actor intenta entrar en él al llegar. La solución:

1. Se crea un warthog **invisible y silencioso** (`object_set_scale 0.01`, sin sonido de motor, no colisionable y no obstáculo de pathfinding) pegado al jugador.
2. Tres **dummies** invisibles e invulnerables ocupan los tres asientos (`W-driver`, `W-passenger`, `W-gunner`).
3. Cada 0.1 s el bucle suelta los dummies (los asientos quedan libres), da la orden `ai_go_to_vehicle` (sin `override`, para no reiniciar paths ya en curso) y vuelve a sentar a los dummies.
4. Los marines caminan hacia el vehículo, pero al llegar encuentran los asientos ocupados: `action_vehicle_evaluate_seat` falla limpiamente y se detienen cerca del jugador, sin montarse y sin morir.
5. Si el jugador se aleja, el vehículo se mueve con él y la siguiente orden reanuda la marcha.

Apagar F8 destruye el objetivo: los marines se quedan donde están (no se los "baja" de nada).

### Combate y caza automática (v1.3.0)

Con F8 activo, el bucle consulta `ai_status mod_marines`. El motor devuelve **5** cuando un marine *ve* a un enemigo y **6** cuando está enganchado en combate. En ese caso:

- Se desactivan las maniobras de la escuadra (`ai_maneuver_enable 0`) y se da `ai_attack` / `ai_follow_target_disable`.
- La cadena de caza recorre los encuentros de la misión y engancha el warthog señuelo al primer actor del encuentro con `ai_status >= 4` (`ai_actors` + `list_get`). Como el señuelo es invisible, los marines **caminan hacia el enemigo** con el mismo mecanismo del escolta, sin montarse.
- Se emiten 8 órdenes por ciclo (antes 4) para reducir los trabones al caminar.

Al terminar el combate, el señuelo vuelve a engancharse al jugador y los marines reanudan el escolta.

El motor no tiene un estado de IA "atacar/avanzar": `ai_attack` solo cambia el modo de la escuadra y `search` se traduce en quedarse quieto. Por eso el movimiento ofensivo se consigue redirigiendo el objetivo del warthog invisible.

> En `a10` el techo de 19.001 nodos del motor retail solo permite incluir 9 encuentros en la cadena (hay que quitar los scripts de migración por salas, que ya no se usaban). El resto de misiones incluyen todos sus encuentros de combate.

El "retirada" que se escucha a veces no es una huida: es la línea de voz que el motor reproduce al dar la orden de vehículo bajo fuego.

## Mapas incluidos

Los 10 mapas de campaña presentes en la instalación:

`a10`, `a30`, `a50`, `b30`, `b40`, `c10`, `c20`, `c40`, `d20`, `d40`

> `c20` y `d20` tienen limitaciones conocidas (ver `documentacion/ESTADO.md`).

## Estructura del repositorio

- `hsc/bloque-mod.txt` — fuente maestra del mod para `a10`, con toda la lógica documentada.
- `hsc/bloque-generico.hsc` — bloque HSC sin dependencias de `a10`, usado por el automatismo.
- `herramientas/` — scripts PowerShell de extracción, parche, compilación y build.
- `documentacion/` — notas técnicas, estado y hoja de ruta.

## Uso

Los scripts están pensados para ejecutarse desde `Halo-Editor\Proyectos\a10\herramientas`. El flujo completo para una misión:

```powershell
.\aplicar-mod-mision.ps1 -Map a30
```

Eso extrae los tags del `.map`, recupera el HSC original incrustado en el tag, parchea el escenario (nombres, ranuras, dummies, señuelo, encuentro), añade el bloque del mod, compila, aplica `runtime = -1` al encuentro y construye el mapa.

Para añadir la caza automática a un mapa ya moddeado:

```powershell
.\aplicar-caza-mision.ps1 -Map b40
```

Genera la cadena de encuentros desde el tag del escenario, reemplaza el bucle de escolta y vuelve a compilar. Los CRCs instalados de cada versión están en `documentacion/ESTADO.md`.

Requisitos: Invader en `C:\Users\jhonv\Downloads\Halo-Editor` y los `.map` retail en `C:\Users\jhonv\Downloads\Halo-PC\MAPS` (rutas configurables dentro de los scripts).

## Créditos

Basado en el análisis del código abierto de **OpenCE** (`source/ai/action_vehicle.c`, `source/ai/ai_script.c`, `source/units/units.c`, `source/objects/objects.c`).

Licencia: MIT.
