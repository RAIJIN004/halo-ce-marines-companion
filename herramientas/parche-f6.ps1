# Parchea los dos ficheros de HaloScript (bloque-mod.txt y extracted.hsc)
# con el nuevo F6: dos marines nuevos a los pies del jugador.
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)

# ---------------------------------------------------------------- bloques
$ini = @'
; --- F6: dos marines nuevos a tus pies ---------------------------
; Por que no se usa (ai_place): ai_place pone al actor en las
; POSICIONES DE TIRO del escuadron, que son puntos fijos del mapa. Para
; que aparezcan donde estas hay que crear el biped y llevarlo hasta el
; jugador. La receta son estas cuatro ordenes, todas del Halo original:
;
;   (object_create_anew <ranura>)
;      crea el biped de esa ranura en la posicion que tiene en el tag
;      (un punto del suelo de la bahia criogenica). Tambien le pone sus
;      armas: el motor llama a unit_add_initial_weapons, que lee
;      "weapons[]" del tag del biped (marine_armored = fusil de asalto).
;
;   (objects_attach (player0) "" <ranura> "")
;      lo cuelga de la RAIZ del jugador: el nombre de marca vacio vale
;      como nodo 0, y objects_scripting_attach/object_attach_to_marker
;      le pone la posicion relativa del marcador, o sea (0,0,0). El
;      biped pasa a estar justo en los pies del jugador.
;
;   (objects_detach (player0) <ranura>)
;      lo suelta conservando la posicion del mundo: object_detach
;      recalcula la matriz con el nodo del padre, le pasa la velocidad,
;      lo reconecta al mapa (object_reconnect_to_map) y lo activa.
;
;   (ai_attach <ranura> mod_marines/marines)
;      convierte ese biped en ACTOR de verdad: ai_scripting_attach_unit
;      toma el tipo de actor de la paleta del escuadron 0 ("marines") y
;      llama a actor_create_for_unit -> encounter_attach_actor. Desde
;      ese momento anda, apunta y obedece el seguimiento del encuentro.
;
; object_create_anew BORRA el objeto anterior con el mismo nombre, asi
; que cada pulsacion gasta una ranura PROPIA (mod_m01..mod_m24 = 12
; pulsaciones de 2 marines): nunca se pisa un marine vivo. Cuando se
; acaban las ranuras F6 ya no hace nada, y tampoco borra nada.
;
; Los nombres no pueden ser dinamicos: HaloScript no tiene variables de
; tipo "nombre de objeto", asi que los 12 casos van escritos uno a uno.
; Las ranuras las crea herramientas/agregar-slots-spawn.ps1, que anade
; al escenario 24 bipeds no colocados y sus 24 nombres.
(script static void mod_marines_aqui
'@

$fin = @'
)

; --- metodo ANTIGUO (ai_place por sala): DESACTIVADO ---------------
; Se conserva escrito y SIN llamar desde ningun sitio, solo como
; referencia historica: colocaba 2 marines por pulsacion en las
; posiciones de tiro de la sala (escuadrones sp_b1..sp_r2). Funciona,
; pero siempre en puntos fijos del mapa y gastando escuadrones (el
; maximo por encuentro es 64). F6 ya no lo usa: ahora los marines nacen
; a tus pies (mod_marines_aqui). Los escuadrones sp_p1..sp_r2 se siguen
; usando en la prueba de tipos de la tecla F9.
(script static void mod_marines_spawn
'@

# cuerpo: 12 bloques de 2 marines
$cuerpo = New-Object System.Collections.Generic.List[string]
for ($p = 0; $p -lt 12; $p++) {
  $a = "{0:D2}" -f (2 * $p + 1)
  $b = "{0:D2}" -f (2 * $p + 2)
  $cuerpo.Add("  (if (= mod_marines_slot $($p * 2))")
  $cuerpo.Add("    (begin")
  foreach ($n in @($a, $b)) {
    $cuerpo.Add("      (object_create_anew mod_m$n)")
    $cuerpo.Add("      (objects_attach (player0) `"`" mod_m$n `"`")")
    $cuerpo.Add("      (objects_detach (player0) mod_m$n)")
    $cuerpo.Add("      (ai_attach mod_m$n mod_marines/marines)")
  }
  $cuerpo.Add("    ))")
}
$cuerpo.Add(")")

$nuevoF6 = ($ini -split "`r?`n") + $cuerpo + ($fin -split "`r?`n")

# rama de la tecla F6 dentro de mod_marines_hotkey
$ramaF6 = @'
  ; F6: dos marines nuevos a tus pies
  (if (= mod_marines_accion 1)
    (begin
      ; sala actual en el instante de pulsar (sin esperar al vigilante)
      (mod_marines_nearest)
      (if (> mod_marines_cand 0)
        (begin
          (set mod_marines_zone mod_marines_cand)
          (set mod_marines_stage mod_marines_cand)
          (set mod_marines_pending 0)
          (set mod_marines_pcount 0)))
      (mod_marines_aqui)
      (if (< mod_marines_slot 24)
        (set mod_marines_slot (+ mod_marines_slot 2)))
      (ai_force_active mod_marines 1)
      (ai_allow_dormant mod_marines 0)
      (sleep 2)
      (ai_follow_target_players mod_marines)))
'@ -split "`r?`n"

# --------------------------------------------------------------- parche
function Parchear([string]$ruta) {
  $l = New-Object System.Collections.Generic.List[string]
  $l.AddRange([string[]](Get-Content -LiteralPath $ruta))
  "  $ruta : $($l.Count) lineas"

  # 1) global nuevo, justo despues de mod_marines_request
  $gi = -1
  for ($i = 0; $i -lt $l.Count; $i++) { if ($l[$i] -match '^\(global short mod_marines_request 0\)') { $gi = $i; break } }
  if ($gi -lt 0) { throw "no encuentro el global mod_marines_request en $ruta" }
  if (($l -join "`n") -notmatch 'mod_marines_slot') {
    $l.Insert($gi + 1, "(global short mod_marines_slot 0)")
    "    + (global short mod_marines_slot 0)"
  } else { "    (el global mod_marines_slot ya estaba)" }

  # 2) seccion mod_marines_spawn -> mod_marines_aqui + metodo antiguo
  $si = -1
  for ($i = 0; $i -lt $l.Count; $i++) { if ($l[$i] -match '^; --- marines nuevos en la sala en la que estas') { $si = $i; break } }
  if ($si -lt 0) { throw "no encuentro la seccion 'marines nuevos' en $ruta" }
  $ti = -1
  for ($i = $si; $i -lt $l.Count; $i++) { if ($l[$i] -match '^; --- teclas') { $ti = $i; break } }
  if ($ti -lt 0) { throw "no encuentro la seccion 'teclas' en $ruta" }
  # quitar lineas en blanco finales de la seccion
  $finSeccion = $ti - 1
  while ($finSeccion -gt $si -and $l[$finSeccion].Trim() -eq "") { $finSeccion-- }
  $l.RemoveRange($si, $finSeccion - $si + 1)
  $bloque = New-Object System.Collections.Generic.List[string]
  $bloque.AddRange([string[]]$nuevoF6)
  $bloque.Add("")
  $bloque.Add("")
  $l.InsertRange($si, $bloque)
  "    seccion F6 reescrita ($($nuevoF6.Count + 2) lineas)"

  # 3) rama F6 dentro del manejador de teclas
  $fi = -1
  for ($i = 0; $i -lt $l.Count; $i++) { if ($l[$i] -match '^  ; F6: aparecer aqui$') { $fi = $i; break } }
  if ($fi -lt 0) { throw "no encuentro la rama '; F6: aparecer aqui' en $ruta" }
  $fe = -1
  for ($i = $fi; $i -lt $l.Count; $i++) { if ($l[$i].Trim() -eq '(mod_marines_spawn)))') { $fe = $i; break } }
  if ($fe -lt 0) { throw "no encuentro '(mod_marines_spawn)))' en $ruta" }
  $l.RemoveRange($fi, $fe - $fi + 1)
  $l.InsertRange($fi, [string[]]$ramaF6)
  "    rama F6 de la tecla reescrita ($($ramaF6.Count) lineas)"

  [System.IO.File]::WriteAllLines($ruta, [string[]]$l, $enc)
  "    guardado"
}

Parchear "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\bloque-mod.txt"
Parchear "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\data\levels\a10\scripts\extracted.hsc"
