# Genera el bloque HSC del mod, sin dependencias de volumenes ni de
# scripts propios de a10. Sirve para cualquier mision de campana.
param([Parameter(Mandatory=$true)][string]$Salida)
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$L = New-Object System.Collections.Generic.List[string]
function A($s){ $L.Add($s) }

A '; ============================================================'
A '; MOD GENERICO: marines invocables y escolta (F6/F7/F8)'
A '; ============================================================'
A '(global short mod_marines_request 0)'
A '(global short mod_marines_slot 0)'
A '(global short mod_marines_accion 0)'
A '(global short mod_marines_ready 0)'
A '(global short mod_marines_escort 0)'
A '(global short mod_marines_combat 0)'
A ''
A '(script dormant mod_marines_boot'
A '  (sleep 120)'
A '  (mod_marines_place)'
A ')'
A '(script continuous mod_marines_seguro'
A '  (sleep 2400)'
A '  (if (= mod_marines_ready 0) (mod_marines_place))'
A ')'
A '(script static void mod_marines_place'
A '  (set mod_marines_slot 0)'
A '  (ai_place mod_marines/marines)'
A '  (ai_force_active mod_marines 1)'
A '  (ai_allow_dormant mod_marines 0)'
A '  (ai_follow_distance mod_marines 0)'
A '  (set mod_marines_ready 1)'
A '  (sleep 30)'
A '  (ai_follow_target_players mod_marines)'
A ')'
A ''
A '; escolta: 3 dummies bloquean los 3 asientos; cada ciclo se sueltan,'
A '; se da la orden y se sientan otra vez. Sin override = no reinicia paths.'
A '; combate automatico: ai_status>=5 (enemigo visible/enganchado) pausa el seguimiento'
A '(script continuous mod_marines_chase_loop'
A '  (sleep 3)'
A '  (if (= mod_marines_escort 1)'
A '    (begin'
A '      (if (>= (ai_status mod_marines) 5)'
A '        (set mod_marines_combat 1)'
A '        (begin'
A '          (set mod_marines_combat 0)'
A '          (objects_detach modlure moddum01)'
A '          (objects_detach modlure moddum02)'
A '          (objects_detach modlure moddum03)'
A '          (ai_go_to_vehicle mod_marines modlure "")'
A '          (ai_go_to_vehicle mod_marines modlure "")'
A '          (ai_go_to_vehicle mod_marines modlure "")'
A '          (ai_go_to_vehicle mod_marines modlure "")'
A '          (unit_enter_vehicle moddum01 modlure "W-driver")'
A '          (unit_enter_vehicle moddum02 modlure "W-passenger")'
A '          (unit_enter_vehicle moddum03 modlure "W-gunner"))))'
A '))'
A ''
A '; F6: crear marines en los pies del jugador (12 pares de ranuras)'
A '(script static void mod_marines_aqui'
for($s=0;$s -lt 24;$s+=2){
  $a=$s+1; $b=$s+2
  A ('  (if (= mod_marines_slot {0})' -f $s)
  A '    (begin'
  foreach($n in @($a,$b)){
    $nm='mod_m{0:D2}' -f $n
    A ('      (object_create_anew {0})' -f $nm)
    A ('      (objects_attach (player0) "" {0} "")' -f $nm)
    A ('      (objects_detach (player0) {0})' -f $nm)
    A ('      (ai_attach {0} mod_marines/marines)' -f $nm)
  }
  A '    ))'
}
A ')'
A ''
A '; F7: juntar a los marines creados por F6 en los pies del jugador'
A '(script static void mod_marines_clump'
for($n=1;$n -le 24;$n++){
  $nm='mod_m{0:D2}' -f $n
  A ('  (objects_attach (player0) "" {0} "")' -f $nm)
  A ('  (objects_detach (player0) {0})' -f $nm)
}
A ')'
A ''
A '; teclas: F6 spawn, F7 juntar, F8 seguir/apagar'
A '(script continuous mod_marines_hotkey'
A '  (sleep_until (!= mod_marines_request 0) 1)'
A '  (set mod_marines_accion mod_marines_request)'
A '  (set mod_marines_request 0)'
A '  (if (= mod_marines_accion 1)'
A '    (begin'
A '      (mod_marines_aqui)'
A '      (if (>= mod_marines_slot 24)'
A '        (set mod_marines_slot 0)'
A '        (set mod_marines_slot (+ mod_marines_slot 2)))'
A '      (ai_force_active mod_marines 1)'
A '      (ai_allow_dormant mod_marines 0)'
A '      (sleep 2)'
A '      (ai_follow_target_players mod_marines)))'
A '  (if (= mod_marines_accion 2)'
A '    (begin'
A '      (set mod_marines_ready 1)'
A '      (mod_marines_clump)'
A '      (sleep 1)'
A '      (ai_follow_target_players mod_marines)))'
A '  (if (= mod_marines_accion 8)'
A '    (begin'
A '      (set mod_marines_ready 1)'
A '      (if (= mod_marines_escort 0)'
A '        (begin'
A '          (object_create_anew modlure)'
A '          (objects_attach (player0) "" modlure "")'
A '          (object_set_scale modlure 0.01 0)'
A '          (object_set_collideable modlure 0)'
A '          (object_create_anew moddum01)'
A '          (object_create_anew moddum02)'
A '          (object_create_anew moddum03)'
A '          (object_set_scale moddum01 0.01 0)'
A '          (object_set_scale moddum02 0.01 0)'
A '          (object_set_scale moddum03 0.01 0)'
A '          (object_set_collideable moddum01 0)'
A '          (object_set_collideable moddum02 0)'
A '          (object_set_collideable moddum03 0)'
A '          (unit_set_maximum_vitality moddum01 100000 100000)'
A '          (unit_set_maximum_vitality moddum02 100000 100000)'
A '          (unit_set_maximum_vitality moddum03 100000 100000)'
A '          (unit_enter_vehicle moddum01 modlure "W-driver")'
A '          (unit_enter_vehicle moddum02 modlure "W-passenger")'
A '          (unit_enter_vehicle moddum03 modlure "W-gunner")'
A '          (set mod_marines_escort 1))'
A '        (begin'
A '          (object_destroy modlure)'
A '          (set mod_marines_escort 0)))))'
A ')'

[System.IO.File]::WriteAllLines($Salida, [string[]]$L, $enc)
"generado: $Salida ($($L.Count) lineas)"
