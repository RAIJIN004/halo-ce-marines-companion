# Posibilidades (hoja de ruta)

## ¿Se puede hacer el "truco del warthog" sobre otros objetivos?

**Sí.** El mecanismo no depende de que el objetivo sea el jugador: `ai_go_to_vehicle <ai> <vehículo> <asiento>` da pathfinding directo hacia **cualquier unidad vehículo**, y `objects_attach <padre> <marcador> <hijo> <marcador>` permite colgar ese vehículo de cualquier objeto (jugador, otro NPC, una escenografía...).

Variantes viables:

1. **Seguir a otro NPC**: crear el señuelo y hacer `(objects_attach <npc> "" modlure "")`. Los marines caminarán hacia ese personaje. Cambiando el padre con `objects_detach` + `objects_attach` se alterna entre objetivos.
2. **Ir a una zona**: colgar el señuelo de un objeto fijo de la zona (o teletransportarlo con `object_teleport`) y dar la orden. Con varios señuelos se puede construir un "mapa de puntos de interés".
3. **Dejar de seguir y atacar**: al detectar un objetivo cercano, apagar el escolta (destruir el señuelo) y dar una orden de ataque normal (`ai_attack` / `ai_migrate` a un escuadrón con posiciones de tiro en esa zona). La IA vuelve a combatir.
4. **Máquina de estados**: `SEGUIR → LLEGAR → ATACAR → REGRESAR`, con globals HSC y un bucle `continuous`. Es exactamente la misma arquitectura que ya funciona, solo cambiando el objetivo de la orden.

## Limitaciones reales

- **Sin función de distancia**: HaloScript no expone `distance(a,b)`. La proximidad se puede aproximar con volúmenes (`volume_test_objects`) o con el propio fin de la acción de vehículo (`vehicle_entry_failed`).
- **Techo de nodos**: el motor retail admite 19.001 nodos de script. En `a10` ya estamos cerca, así que cada nueva conducta requiere quitar otra cosa (por ejemplo, reducir ranuras F6 de 24 a 12).
- **Asiento libre**: la orden solo se acepta si hay al menos un asiento libre al emitirla. Por eso el bucle suelta y vuelve a sentar a los dummies. Con N dummies se pueden dar N órdenes por ciclo.
- **Detección de enemigos**: `unit_can_see_object` / `objects_can_see_object` permiten elegir un objetivo visible, pero hay que decidir qué encuentro se consulta y evitar que los marines persigan a enemigos de misión (Rompe guiones).
- **Mapas con guion**: intervenir encuentros existentes puede romper cinemáticas. Conviene seguir usando encuentros propios (`mod_marines`) y objetivos propios.

## Orden recomendado de implementación

1. **Múltiples objetivos**: añadir 2–3 señuelos con nombres (`modlure_a`, `modlure_b`, ...) y una global `mod_marines_target` que decida cuál se usa en el bucle.
2. **Ir a zona**: reutilizar el patrón de volúmenes por sala que ya existía en versiones anteriores del mod (`mz_*`), o usar puntos fijos con `object_teleport`.
3. **Combate**: ✅ **hecho en v1.1.0** usando `ai_status >= 5` como detector genético de "enemigo visible/enganchado". El bucle deja de emitir la orden de vehículo y la IA nativa pelea. Al bajar `ai_status`, se reanuda el seguimiento. No hace falta declarar encuentros por misión.
4. **Multi-objetivo**: varios señuelos con nombres (`modlure_a`, `modlure_b`, ...) y una global `mod_marines_target` para elegir cuál se usa en el bucle. Permite "ir a la zona A, luego a la B".
5. **Persistencia entre misiones**: los globals viven por misión; no hay forma de Guardar estado entre mapas con HaloScript puro.
