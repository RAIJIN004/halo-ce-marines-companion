# Aplica el modo de caza automatica (b30) a una mision ya moddeada.
param([Parameter(Mandatory=$true)][string]$Map)
$ErrorActionPreference='Continue'
$root='C:\Users\jhonv\Downloads\Halo-Editor'
$env:Path="$root;$env:Path"
$pj="$root\Proyectos\$Map"; $rel="levels\$Map\$Map.scenario"
$hsc="$pj\data\levels\$Map\scripts\extracted.hsc"

# --- 1) generar cadena de caza desde los encuentros del tag ---
$chainPath="$pj\cadena-caza.hsc"
powershell -ExecutionPolicy Bypass -File "$root\Proyectos\a10\herramientas\generar-cadenas-caza-mision.ps1" -Map $Map -Salida $chainPath | Out-Null
$chain=[System.IO.File]::ReadAllText($chainPath)

# --- 2) bloque de bucle nuevo ---
$nuevo=@'
(script continuous mod_marines_chase_loop
  (sleep 3)
  (if (= mod_marines_escort 1)
    (begin
      (if (>= (ai_status mod_marines) 5)
        (begin
          (if (= mod_marines_combat 0)
            (begin
              (ai_attack mod_marines)
              (ai_maneuver_enable mod_marines 0)
              (ai_follow_target_disable mod_marines)))
          (set mod_marines_combat 1)
          (mod_marines_hunt_target))
        (begin
          (if (= mod_marines_combat 1)
            (begin
              (objects_attach (player0) "" modlure "")
              (ai_maneuver_enable mod_marines 0)
              (ai_follow_target_players mod_marines)
              (ai_defend mod_marines)))
          (set mod_marines_combat 0)))
      ; orden SIEMPRE: el senuelo esta en el jugador o en el enemigo
      (objects_detach modlure moddum01)
      (objects_detach modlure moddum02)
      (objects_detach modlure moddum03)
      (ai_go_to_vehicle mod_marines modlure "")
      (ai_go_to_vehicle mod_marines modlure "")
      (ai_go_to_vehicle mod_marines modlure "")
      (ai_go_to_vehicle mod_marines modlure "")
      (ai_go_to_vehicle mod_marines modlure "")
      (ai_go_to_vehicle mod_marines modlure "")
      (ai_go_to_vehicle mod_marines modlure "")
      (ai_go_to_vehicle mod_marines modlure "")
      (unit_enter_vehicle moddum01 modlure "W-driver")
      (unit_enter_vehicle moddum02 modlure "W-passenger")
      (unit_enter_vehicle moddum03 modlure "W-gunner")))
)
'@

$t=[System.IO.File]::ReadAllText($hsc)
# quitar cadena previa si existe
$i=$t.IndexOf('; cadena de caza:')
if($i -ge 0){
  $j=$t.IndexOf('(script continuous mod_marines_chase_loop', $i)
  if($j -gt $i){ $t=$t.Substring(0,$i)+$t.Substring($j) }
}
# reemplazar bloque del bucle
$inicio=$t.IndexOf('(script continuous mod_marines_chase_loop')
$fin=[regex]::Match($t,';.*F6:',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Index
if($inicio -lt 0 -or $fin -le $inicio){ "$Map : NO encontre bloque de bucle"; exit 1 }
$t=$t.Substring(0,$inicio) + $chain + "`r`n" + $nuevo + "`r`n" + $t.Substring($fin)
[System.IO.File]::WriteAllText($hsc,$t,(New-Object System.Text.UTF8Encoding($false)))
"$Map : HSC actualizado ($((Get-Content $hsc).Count) lineas)"

# --- 3) compilar ---
$c = & invader-script -g gbx-retail -t "$pj\tags" -d "$pj\data" $rel.Replace('.scenario','') 2>&1
$last = ($c | Select-Object -Last 3) -join ' | '
"$Map : $last"
