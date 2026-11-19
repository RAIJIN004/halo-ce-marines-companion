param([int[]]$Encs = @(32, 34, 39), [int]$MaxSquads = 60)
$ErrorActionPreference = 'Stop'
$d = 'C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\scenario-dump.txt'
$estados = @('attacking','attacking_search','attacking_guard','defending','defending_search','defending_guard')

$enc = -1; $sq = -1; $campo = ''
$res = @{}
foreach ($ln in (Get-Content $d)) {
    if ($ln -match '\u2500\u2500encounters\[(\d+)\]\s+struct') {
        $enc = [int]$Matches[1]; $sq = -1; $campo = ''
        if ($Encs -contains $enc) { $res[$enc] = New-Object System.Collections.ArrayList }
        continue
    }
    if ($ln -match '\u2500\u2500squads\[(\d+)\]\s+struct') {
        $sq = [int]$Matches[1]; $campo = ''
        if ($Encs -contains $enc -and $sq -lt $MaxSquads) {
            [void]$res[$enc].Add(@{ num = $sq; nombre = ''; tipo = ''; cnt = ''; ini = ''; ret = ''; pts = 0; masks = @{}; pursue = @() })
        }
        continue
    }
    if (-not $res.ContainsKey($enc) -or $sq -lt 0 -or $sq -ge $MaxSquads) { continue }
    $s = $res[$enc][$sq]
    if ($ln -match '\u2500\u2500(platoons|player_starting_locations|command_lists|firing_positions)\[') { $sq = -1; $campo = ''; continue }
    if ($ln -match '\u2500\u2500name \((.*)\)\s+string') { $s.nombre = $Matches[1]; $campo = ''; continue }
    if ($ln -match '\u2500\u2500actor_type \((\d+)\)') { $s.tipo = $Matches[1]; $campo = ''; continue }
    if ($ln -match '\u2500\u2500normal_diff_count \((\d+)\)') { $s.cnt = $Matches[1]; $campo = ''; continue }
    if ($ln -match '\u2500\u2500starting_locations\[(\d+)\]\s+struct') { if ([int]$Matches[1] + 1 -gt $s.pts) { $s.pts = [int]$Matches[1] + 1 }; $campo = ''; continue }
    if ($ln -match '\u2500\u2500(initial_state|return_state)\s+enum') { $campo = $Matches[1]; continue }
    if ($ln -match '\u2500\u2500([a-z_]+) \(\*\)\s+enum value') {
        if ($campo -eq 'initial_state') { $s.ini = $Matches[1] }
        elseif ($campo -eq 'return_state') { $s.ret = $Matches[1] }
        $campo = ''; continue
    }
    if ($ln -match '\u2500\u2500(attacking|attacking_search|attacking_guard|defending|defending_search|defending_guard|pursuing)\s+bitmask') {
        $campo = $Matches[1]; $s.masks[$campo] = @(); continue
    }
    if ($ln -match '\u2500\u2500([a-z]) \(\*\)\s+bitfield') { $campo = ''; continue }
    if ($ln -match '\u2500\u2500([a-z]) \(1\)\s+bitfield') {
        if ($estados -contains $campo -or $campo -eq 'pursuing') { $s.masks[$campo] += $Matches[1] }
        continue
    }
}

foreach ($e in ($Encs | Sort-Object)) {
    if (-not $res.ContainsKey($e)) { Write-Output ("== encuentro {0}: no encontrado ==" -f $e); continue }
    Write-Output ("===== encuentro {0}  ({1} escuadrones) =====" -f $e, $res[$e].Count)
    foreach ($s in $res[$e]) {
        $v = foreach ($m in $estados) { if ($s.masks.ContainsKey($m) -and $s.masks[$m].Count -gt 0) { $s.masks[$m] -join '' } else { '-' } }
        $pu = if ($s.masks.ContainsKey('pursuing') -and $s.masks['pursuing'].Count -gt 0) { $s.masks['pursuing'] -join '' } else { '-' }
        Write-Output ("  [{0,2}] {1,-16} tipo={2,-5} n={3,-2} puntos={4} {5,-24} ret={6,-26} masks={7}  purs={8}" -f `
            $s.num, $s.nombre, $s.tipo, $s.cnt, $s.pts, $s.ini, $s.ret, ($v -join ' '), $pu)
    }
}
