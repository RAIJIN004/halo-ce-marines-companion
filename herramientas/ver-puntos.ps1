param([int]$Enc = 39, [int]$MaxSquads = 60)
$ErrorActionPreference = 'Stop'
$d = 'C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\scenario-dump.txt'

$enc = -1; $sq = -1; $sl = -1
$res = New-Object System.Collections.ArrayList
foreach ($ln in (Get-Content $d)) {
    if ($ln -match '\u2500\u2500encounters\[(\d+)\]\s+struct') {
        $enc = [int]$Matches[1]; $sq = -1
        if ($enc -eq $Enc) { continue }
        elseif ($enc -gt $Enc) { break }
        continue
    }
    if ($enc -ne $Enc) { continue }
    if ($ln -match '\u2500\u2500squads\[(\d+)\]\s+struct') {
        $sq = [int]$Matches[1]; $sl = -1
        if ($sq -lt $MaxSquads) {
            [void]$res.Add(@{ num = $sq; nombre = ''; tipo = ''; pts = (New-Object System.Collections.ArrayList) })
        }
        continue
    }
    if ($ln -match '\u2500\u2500(platoons|player_starting_locations|command_lists|firing_positions)\[') { $sq = -1; continue }
    if ($sq -lt 0 -or $sq -ge $MaxSquads) { continue }
    $s = $res[$sq]
    if ($ln -match '\u2500\u2500name \((.*)\)\s+string') { $s.nombre = $Matches[1]; continue }
    if ($ln -match '\u2500\u2500actor_type \((\d+)\)') { $s.tipo = $Matches[1]; continue }
    if ($ln -match '\u2500\u2500starting_locations\[(\d+)\]\s+struct') { $sl = [int]$Matches[1]; continue }
    if ($ln -match '\u2500\u2500position \(([-\d.]+),([-\d.]+),([-\d.]+)\)') {
        if ($sl -ge 0) { [void]$s.pts.Add(("{0,10:N1},{1,8:N1},{2,8:N1}" -f [double]$Matches[1], [double]$Matches[2], [double]$Matches[3])) }
        continue
    }
}

Write-Output ("===== encuentro {0}: puntos de aparicion por escuadron =====" -f $Enc)
foreach ($s in $res) {
    $c = if ($s.pts.Count -eq 0) { '(sin puntos)' } else { $s.pts -join ' | ' }
    Write-Output ("[{0,2}] {1,-12} tipo={2,-4} pts={3}  {4}" -f $s.num, $s.nombre, $s.tipo, $s.pts.Count, $c)
}
