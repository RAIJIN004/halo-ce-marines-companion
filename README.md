# Halo CE — Marines Companion (v1.1.0)

Mod para la campaña retail de **Halo: Combat Evolved (2003, Gearbox)** que permite invocar marines armados en la posición del jugador y ordenarles que lo sigan caminando, sin subirse a vehículos.

## Estado

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

### Combate automático (v1.1.0)

Con F8 activo, el bucle consulta `ai_status mod_marines`. El motor devuelve **5** cuando un marine *ve* a un enemigo y **6** cuando está enganchado en combate. En ese caso el mod **deja de emitir la orden de seguimiento**: los marines pelean por su cuenta con la IA nativa, dejando de "seguir como patitos". Cuando el enemigo muere o se pierde de vista, `ai_status` baja y al siguiente ciclo vuelven a caminar hacia ti. No hace falta declarar encuentros enemigos ni nombres por misión: la detección es genérica y funciona en cualquier mapa.

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

Requisitos: Invader en `C:\Users\jhonv\Downloads\Halo-Editor` y los `.map` retail en `C:\Users\jhonv\Downloads\Halo-PC\MAPS` (rutas configurables dentro de los scripts).

## Créditos

Basado en el análisis del código abierto de **OpenCE** (`source/ai/action_vehicle.c`, `source/ai/ai_script.c`, `source/units/units.c`, `source/objects/objects.c`).

Licencia: MIT.
