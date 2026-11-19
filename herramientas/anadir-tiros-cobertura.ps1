# Anade las posiciones de tiro de cobertura (seleccionadas del retail) al
# encuentro mod_marines, en el grupo 'a'. Squad 0 tiene todas las letras en
# sus mascaras, asi que puede usarlas; y al ser el escuadron con la posicion
# mas cercana al jugador, los marines acaban en el.
$ErrorActionPreference = "Stop"
$ie  = "C:\Users\jhonv\Downloads\Halo-Editor\invader-edit.exe"
$tg  = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags"
$rel = "levels\a10\a10.scenario"
$csv = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\tiros-a-anadir.csv"
$bk  = "$tg\levels\a10\a10.scenario.bak-cobertura"

if (!(Test-Path $bk)) { Copy-Item (Join-Path $tg $rel) $bk -Force; "backup: $bk" }

$puntos = @(Get-Content $csv | ForEach-Object { $v = $_ -split ','; [pscustomobject]@{ x = $v[0]; y = $v[1]; z = $v[2] } })
"a anadir: $($puntos.Count) posiciones (grupo a)"

$antes = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
if ($antes + $puntos.Count -gt 512) { throw "se pasaria del limite 512 ($antes + $($puntos.Count))" }
& $ie -t $tg -I "encounters[39].firing_positions" $puntos.Count end $rel 2>&1
$despues = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
"insertadas: $antes -> $despues"

$idx = $antes
foreach ($p in $puntos) {
  $pos = "{0},{1},{2}" -f $p.x, $p.y, $p.z
  & $ie -t $tg -S "encounters[39].firing_positions[$idx].position" $pos $rel 2>&1 | Out-Null
  & $ie -t $tg -S "encounters[39].firing_positions[$idx].group_index" a $rel 2>&1 | Out-Null
  if ($idx % 20 -eq 0) { "  $idx / $despues" }
  $idx++
}
"listo: $despues posiciones de tiro"