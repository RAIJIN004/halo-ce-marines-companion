# Añade posiciones de tiro (firing_positions) a los grupos escasos del
# encuentro mod_marines para que los marines siempre tengan un punto cerca
# del jugador al que ir, en cualquier sala.
#
# Uso: powershell -File agregar-tiros.ps1
#   (edita tags\levels\a10\a10.scenario directamente)
#
# Grupos blancos y posiciones a anadir (aprox. en el area de cada sala):
$ErrorActionPreference = "Stop"
$ie   = "C:\Users\jhonv\Downloads\Halo-Editor\invader-edit.exe"
$tg   = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags"
$rel  = "levels\a10\a10.scenario"
$bk   = "$tg\levels\a10\a10.scenario.bak-tiros"

if (!(Test-Path $bk)) {
  Copy-Item (Join-Path $tg $rel) $bk -Force
  "copia de seguridad: $bk"
}

# {grupo} => @( "x,y,z", ... )
$grupos = @{
  e = @(
    "-4.5,0.0,0.001", "-6.0,0.0,0.001", "-3.0,0.0,0.001",
    "-4.5,2.0,0.001", "-4.5,-2.0,0.001", "-2.0,1.0,0.001"
  )
  o = @(
    "-52.7,4.5,0.001", "-51.0,4.5,0.001", "-54.0,4.5,0.001",
    "-52.7,2.0,0.001", "-52.7,7.0,0.001", "-50.0,4.5,0.001"
  )
  p = @(
    "-50.3,-1.9,1.5", "-49.0,-1.9,1.5", "-51.6,-1.9,1.5",
    "-50.3,0.5,1.5", "-50.3,-4.0,1.5", "-48.0,0.0,1.5"
  )
  q = @(
    "-48.9,11.0,2.0", "-47.5,11.0,2.0", "-50.3,11.0,2.0",
    "-48.9,9.0,2.0", "-48.9,13.0,2.0", "-47.0,12.0,2.0"
  )
  r = @(
    "-52.8,-4.4,0.0", "-51.5,-4.4,0.0", "-54.1,-4.4,0.0",
    "-52.8,-2.0,0.0", "-52.8,-6.5,0.0", "-50.0,-4.0,0.0"
  )
}

$totalNuevos = 0
foreach ($g in $grupos.Keys) { $totalNuevos += $grupos[$g].Count }
"anadiendo $totalNuevos posiciones de tiro..."

# 1) insertar todas de una vez al final
$antes = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
& $ie -t $tg -I "encounters[39].firing_positions" $totalNuevos end $rel 2>&1
$despues = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
"insertadas: $antes -> $despues"

# 2) configurar cada nueva posicion
$idx = $antes
foreach ($g in $grupos.Keys) {
  foreach ($pos in $grupos[$g]) {
    & $ie -t $tg -S "encounters[39].firing_positions[$idx].position" $pos $rel 2>&1 | Out-Null
    & $ie -t $tg -S "encounters[39].firing_positions[$idx].group_index" $g $rel 2>&1 | Out-Null
    "  [$idx] grupo=$g pos=$pos"
    $idx++
  }
}

# 3) verificar
$final = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
"final: firing_positions = $final (esperado $despues)"
if ($final -ne $despues) { throw "el conteo no coincide" }
