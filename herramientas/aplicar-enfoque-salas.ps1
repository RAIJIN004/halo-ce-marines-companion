# Enfoque por salas:
#  1) restaura el tag (184 posiciones, sin las 129 nuevas)
#  2) squad 0 vuelve a tener SOLO la letra 'a' en sus 6 mascaras
#     (si tiene todas, la migracion nunca lo elige como destino y los
#      marines se quedan en el escuadron 0 para siempre)
#  3) anade las 129 posiciones nuevas, cada una en el grupo de su sala
$ErrorActionPreference = "Stop"
$tg  = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags"
$rel = "levels\a10\a10.scenario"
$p   = Join-Path $tg $rel
$ie  = "C:\Users\jhonv\Downloads\Halo-Editor\invader-edit.exe"
$csv = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\tiros-a-anadir-grupos.csv"

# 1) restaurar
if (Test-Path "$p.bak-cobertura") { Move-Item "$p.bak-cobertura" $p -Force; "tag restaurado desde bak-cobertura" }

# 2) squad 0: solo la letra 'a' en las 6 mascaras
$masks = "attacking","attacking_search","attacking_guard","defending","defending_search","defending_guard"
$letters = "b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r"
$n = 0
foreach ($m in $masks) {
  foreach ($l in $letters) {
    & $ie -t $tg -S "encounters[39].squads[0].$m.$l" 0 $rel 2>&1 | Out-Null
    $n++
  }
}
"mascaras de squad 0 limpiadas: $n (b..r a 0 en 6 mascaras; queda solo 'a')"

# 3) anadir las 129 posiciones con su grupo
$puntos = @(Get-Content $csv | ForEach-Object { $v = $_ -split ','; [pscustomobject]@{ x = $v[0]; y = $v[1]; z = $v[2]; g = $v[3] } })
$antes = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
& $ie -t $tg -I "encounters[39].firing_positions" $puntos.Count end $rel 2>&1
$despues = [int](& $ie -t $tg -C "encounters[39].firing_positions" $rel 2>&1)
"insertadas: $antes -> $despues"
$idx = $antes
foreach ($pt in $puntos) {
  $pos = "{0},{1},{2}" -f $pt.x, $pt.y, $pt.z
  & $ie -t $tg -S "encounters[39].firing_positions[$idx].position" $pos $rel 2>&1 | Out-Null
  & $ie -t $tg -S "encounters[39].firing_positions[$idx].group_index" $pt.g $rel 2>&1 | Out-Null
  $idx++
}
"listo: $despues posiciones"