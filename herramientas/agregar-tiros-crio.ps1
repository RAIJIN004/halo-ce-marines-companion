# Añade posiciones de tiro personalizadas en la bahía criogenica (grupo o)
# alrededor del punto de spawn (-55.43, 0.80, 0.001) y por la sala, para
# probar si los marines se mueven a la posición más cercana al jugador.
$ErrorActionPreference = "Stop"
$ie   = "C:\Users\jhonv\Downloads\Halo-Editor\invader-edit.exe"
$tg   = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags"
$rel  = "levels\a10\a10.scenario"
$bk   = "$tg\levels\a10\a10.scenario.bak-tiros-crio"

if (!(Test-Path $bk)) {
  Copy-Item (Join-Path $tg $rel) $bk -Force
  "backup: $bk"
}

# Posiciones en la bahía criogenica (grupo o = letra o)
$crio = @(
  "-55.43,0.80,0.001",   # justo en el spawn
  "-54.0,0.80,0.001",
  "-56.0,0.80,0.001",
  "-55.43,2.0,0.001",
  "-55.43,-2.0,0.001",
  "-53.0,0.80,0.001",
  "-57.0,0.80,0.001",
  "-55.43,4.0,0.001",
  "-55.43,-4.0,0.001",
  "-52.0,0.80,0.001",
  "-58.0,0.80,0.001",
  "-55.43,6.0,0.001",
  "-55.43,-6.0,0.001",
  "-50.0,0.80,0.001",
  "-59.0,0.80,0.001"
)

$antes = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
& $ie -t $tg -I "encounters[39].firing_positions" $crio.Count end $rel 2>&1
$despues = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
"insertadas: $antes -> $despues"

$idx = $antes
foreach ($pos in $crio) {
  & $ie -t $tg -S "encounters[39].firing_positions[$idx].position" $pos $rel 2>&1 | Out-Null
  & $ie -t $tg -S "encounters[39].firing_positions[$idx].group_index" o $rel 2>&1 | Out-Null
  "  [$idx] grupo=o pos=$pos"
  $idx++
}

$final = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
"final: firing_positions = $final"
