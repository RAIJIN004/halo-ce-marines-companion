# Hace que los marines vengan cerca del jugador:
#  - mod_marines_clump  : acerca a tus pies los marines creados por F6
#  - mod_marines_migrar_sala : manda todos los actores al escuadron
#    vacio de la letra de tu sala (1=b .. 17=r), cuyas posiciones de
#    tiro son las de esa sala: por eso vienen andando hasta ti
#  - F6 y F7 usan las dos cosas; el vigilante de sala tambien migra
#  - mod_marines_place pide seguimiento con distancia 0 (migracion
#    continuada, sin esperar 2 world units de diferencia)
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)

$fixtures = @(
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\bloque-mod.txt",
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\data\levels\a10\scripts\extracted.hsc"
)

# -------------------------------------------------------------- nuevo codigo
$clump = New-Object System.Collections.Generic.List[string]
$clump.Add("; --- F7: traer a tus pies los marines creados por F6 ----------------")
$clump.Add("; Las ordenes de objeto mueven cosas que YA existen: el marine se")
$clump.Add("; cuelga de la raiz del jugador (su posicion pasa a ser la del")
$clump.Add("; jugador) y al soltarlo se queda ahi. Con eso F7 acerca de golpe")
$clump.Add("; a los marines de F6 (mod_m01..mod_m24) y luego los manda a las")
$clump.Add("; posiciones de tiro de tu sala, que es como vienen andando.")
$clump.Add(";")
$clump.Add("; Solo sirve para los marines de F6: los tres del principio salen")
$clump.Add("; de (ai_place mod_marines/marines) y su objeto no tiene nombre en")
$clump.Add("; el escenario, asi que no se pueden nombrar desde el script.")
$clump.Add("; Si la ranura esta libre (aun no has creado ese marine) las dos")
$clump.Add("; ordenes no hacen nada: comprueban el indice del objeto antes de")
$clump.Add("; tocar nada (objects_scripting_attach / objects_scripting_detach).")
$clump.Add("(script static void mod_marines_clump")
for ($i = 1; $i -le 24; $i++) {
  $n = "mod_m{0:D2}" -f $i
  $clump.Add("  (objects_attach (player0) `"`" $n `"`")")
  $clump.Add("  (objects_detach (player0) $n)")
}
$clump.Add(")")
$clump.Add("")

$mig = New-Object System.Collections.Generic.List[string]
$mig.Add("; --- llevar los marines a la sala en la que estas (migrar) --------")
$mig.Add("; (ai_migrate <encuentro> <escuadron>) mueve a TODOS los actores del")
$mig.Add("; encuentro de origen al escuadron destino. El destino es el escuadron")
$mig.Add("; VACIO de la letra de tu sala (1=b .. 17=r), que solo tiene")
$mig.Add("; posiciones de tiro: las de esa sala. Al migrar, los actores pasan a")
$mig.Add("; formar parte de ese escuadron y van andando a ocupar sus posiciones,")
$mig.Add("; es decir, vienen hasta donde estas.")
$mig.Add(";")
$mig.Add("; Es la misma orden que usa el nivel original (containment_2 ->")
$mig.Add("; (ai_migrate stairs containment_2)) pero entre escuadrones del mismo")
$mig.Add("; encuentro.")
$mig.Add(";")
$mig.Add("; mod_marines_zone lo fija (mod_marines_nearest) cada vez que se")
$mig.Add("; pulsa F6/F7 y el vigilante cuando cambias de sala.")
$mig.Add("(script static void mod_marines_migrar_sala")
for ($z = 1; $z -le 17; $z++) {
  $letra = [char](97 + $z)
  $mig.Add("  (if (= mod_marines_zone " + $z.ToString().PadLeft(2) + ") (ai_migrate mod_marines mod_marines/adv_" + $letra + "))")
}
$mig.Add(")")

$nuevo = New-Object System.Collections.Generic.List[string]
$nuevo.AddRange([string[]]$clump)
$nuevo.Add("")
$nuevo.AddRange([string[]]$mig)
$nuevo.Add("")
$nuevo.Add("")

# ------------------------------------------------------------- ramas de teclas
$f6nuevo = @'
      (mod_marines_aqui)
      (if (< mod_marines_slot 24)
        (set mod_marines_slot (+ mod_marines_slot 2)))
      (ai_force_active mod_marines 1)
      (ai_allow_dormant mod_marines 0)
      ; los nuevos se van andando a las posiciones de tiro de tu sala
      (mod_marines_migrar_sala)
      (sleep 2)
      (ai_follow_target_players mod_marines)))
'@ -split "`r?`n"

$f6viejo = @'
      (mod_marines_aqui)
      (if (< mod_marines_slot 24)
        (set mod_marines_slot (+ mod_marines_slot 2)))
      (ai_force_active mod_marines 1)
      (ai_allow_dormant mod_marines 0)
      (sleep 2)
      (ai_follow_target_players mod_marines)))
'@ -split "`r?`n"

$f7nuevo = @'
  ; F7: venir aqui
  ;   1) (mod_marines_nearest): en que sala estas ahora mismo
  ;   2) (mod_marines_clump): los marines de F6 a tus pies
  ;   3) (mod_marines_migrar_sala): y de ahi, a las posiciones de tiro
  ;      de tu sala andando (la migracion manda)
  (if (= mod_marines_accion 2)
    (begin
      (set mod_marines_ready 1)
      (mod_marines_nearest)
      (if (> mod_marines_cand 0)
        (begin
          (set mod_marines_zone mod_marines_cand)
          (set mod_marines_stage mod_marines_cand)))
      (mod_marines_clump)
      (ai_force_active mod_marines 1)
      (ai_allow_dormant mod_marines 0)
      (mod_marines_migrar_sala)
      (sleep 1)
      (ai_follow_target_players mod_marines)))
'@ -split "`r?`n"

$f7viejo = @'
  ; F7: venir aqui (orden de seguir, sin migrar)
  (if (= mod_marines_accion 2)
    (begin
      (set mod_marines_ready 1)
      (mod_marines_nearest)
      (if (> mod_marines_cand 0)
        (begin
          (set mod_marines_zone mod_marines_cand)
          (set mod_marines_stage mod_marines_cand)))
      (mod_marines_seguir)))
'@ -split "`r?`n"

# seguimiento continuo: distancia 0 (migracion al grupo mas cercano)
$placeViejo = @'
  (ai_allow_dormant mod_marines 0)
  (set mod_marines_ready 1)
'@ -split "`r?`n"
$placeNuevo = @'
  (ai_allow_dormant mod_marines 0)
  ; tolerancia de migracion 0: en cuanto el grupo mas cercano al jugador
  ; cambia un mundo unit, cambian de grupo (si no, se quedan parados a
  ; los 2 world units que viene por defecto)
  (ai_follow_distance mod_marines 0)
  (set mod_marines_ready 1)
'@ -split "`r?`n"

# vigilante: al cambiar de sala, migrar (no solo volver a ordenar seguir)
$scanViejo = @'
        (set mod_marines_stage mod_marines_zone)
        ; de momento solo se vuelve a ordenar seguir (sin migrar)
        (mod_marines_seguir)
'@ -split "`r?`n"
$scanNuevo = @'
        (set mod_marines_stage mod_marines_zone)
        ; al cambiar de sala se van andando a las posiciones de tiro de
        ; la sala nueva: por eso te siguen de sala en sala
        (mod_marines_migrar_sala)
        (mod_marines_seguir)
'@ -split "`r?`n"

# -------------------------------------------------------------------- parche
function Parchear([string]$ruta) {
  $t = [System.IO.File]::ReadAllText($ruta)
  $largo = $t.Length
  $t = [regex]::Replace($t, "(?m)^\(script static void mod_marines_migrar_sala\r?\n", "")
  if ($t -match "mod_marines_clump") { "  $ruta : ya estaba parcheado, no toco"; return }

  $bloque = ($nuevo -join "`r`n")
  $ancla = "; --- metodo ANTIGUO (ai_place por sala): DESACTIVADO ---------------"
  if (-not $t.Contains($ancla)) { throw "no encuentro el ancla del metodo antiguo en $ruta" }
  $t = $t.Replace($ancla, ($bloque + $ancla))

  $viejo = ($f6viejo -join "`r`n"); $n = ($f6nuevo -join "`r`n")
  if (-not $t.Contains($viejo)) { throw "no encuentro la rama F6 en $ruta" }
  $t = $t.Replace($viejo, $n)

  $viejo = ($f7viejo -join "`r`n"); $n = ($f7nuevo -join "`r`n")
  if (-not $t.Contains($viejo)) { throw "no encuentro la rama F7 en $ruta" }
  $t = $t.Replace($viejo, $n)

  $viejo = ($placeViejo -join "`r`n"); $n = ($placeNuevo -join "`r`n")
  if (-not $t.Contains($viejo)) { throw "no encuentro mod_marines_place en $ruta" }
  $t = $t.Replace($viejo, $n)

  $viejo = ($scanViejo -join "`r`n"); $n = ($scanNuevo -join "`r`n")
  if (-not $t.Contains($viejo)) { throw "no encuentro mod_marines_scan en $ruta" }
  $t = $t.Replace($viejo, $n)

  [System.IO.File]::WriteAllText($ruta, $t, $enc)
  "  $ruta : parcheado ($($largo) -> $($t.Length) bytes)"
}

foreach ($f in $fixtures) { Parchear $f }