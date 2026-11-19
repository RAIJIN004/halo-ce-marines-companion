# Genera la cadena de caza para una mision, leyendo los encuentros del tag.
param(
  [Parameter(Mandatory=$true)][string]$Map,
  [Parameter(Mandatory=$true)][string]$Salida
)
$ErrorActionPreference='Continue'
$root='C:\Users\jhonv\Downloads\Halo-Editor'
$env:Path="$root;$env:Path"
$pj="$root\Proyectos\$Map"; $rel="levels\$Map\$Map.scenario"
$ne=[int](& invader-edit -t "$pj\tags" -C encounters $rel 2>&1 | Select-Object -First 1)
$nombres=@()
for($i=0;$i -lt $ne;$i++){
  $n=[string](& invader-edit -t "$pj\tags" -G "encounters[$i].name" $rel 2>&1 | Select-Object -First 1)
  if($n -eq 'mod_marines'){ continue }
  if($n -match 'marine|downed|crew|_inv'){ continue }
  $nombres += $n
}
$L=New-Object System.Collections.Generic.List[string]
$L.Add('; cadena de caza: engancha el senuelo al encuentro enemigo que nos ve')
$L.Add('(global short mod_marines_hunt_found 0)')
$L.Add('(script static void mod_marines_hunt_target')
$L.Add('  (set mod_marines_hunt_found 0)')
foreach($n in $nombres){
  $L.Add("  (if (and (= mod_marines_hunt_found 0) (>= (ai_status $n) 4))")
  $L.Add('    (begin')
  $L.Add("      (objects_attach (list_get (ai_actors $n) 0) `"`" modlure `"`")")
  $L.Add('      (set mod_marines_hunt_found 1)))')
}
$L.Add(')')
[System.IO.File]::WriteAllLines($Salida,[string[]]$L,(New-Object System.Text.UTF8Encoding($false)))
"mision $Map : $($nombres.Count) encuentros -> $($L.Count) lineas"
