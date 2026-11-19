param([int]$NumEnc = 32)
$ErrorActionPreference = 'Stop'
$d = 'C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\scenario-dump.txt'
$sr = New-Object System.IO.StreamReader($d)
$enc = -1; $sq = -1; $campo = ''; $sub = ''
$datos = @{}
$salida = New-Object System.Collections.ArrayList
while (($ln = $sr.ReadLine()) -ne $null) {
    if ($ln -match 'encounters\[(\d+)\]\s+struct') { $enc = [int]$Matches[1]; $sq = -1; $campo = ''; continue }
    if ($enc -ne $NumEnc) { continue }
    if ($ln -match '\u2500\u2500squads\[(\d+)\]\s+struct') {
        $sq = [int]$Matches[1]; $campo = ''
        $datos[$sq] = [ordered]@{ name = ''; actor_type = ''; initial = ''; ret = ''; flags = (New-Object System.Collections.ArrayList); masks = (New-Object System.Collections.ArrayList); starts = 0 }
        continue
    }
    if ($sq -lt 0) {
        if ($ln -match '\u2500\u2500(platoons|player_starting_locations)\[') { $sq = -1 }
        continue
    }
    if ($ln -match '\u2500\u2500(platoons|player_starting_locations|command_lists)\[') { $sq = -1; continue }
    if ($ln -match '\u2500\u2500name \((.*)\)\s+string') { $datos[$sq].name = $Matches[1]; $campo = ''; continue }
    if ($ln -match '\u2500\u2500actor_type \((\d+)\)') { $datos[$sq].actor_type = $Matches[1]; $campo = ''; continue }
    if ($ln -match '\u2500\u2500(initial_state|return_state)\s+enum') { $campo = $Matches[1]; continue }
    if ($ln -match '\u2500\u2500flags\s+bitmask') { $campo = 'flags'; continue }
    if ($ln -match '\u2500\u2500(attacking|attacking_search|attacking_guard|defending|defending_search|defending_guard)\s+bitmask') { $campo = "mask:$($Matches[1])"; continue }
    if ($ln -match '\u2500\u2500starting_locations\[(\d+)\]\s+struct') { $datos[$sq].starts = [Math]::Max($datos[$sq].starts, [int]$Matches[1] + 1); continue }
    if ($ln -match '\u2500\u2500([a-z_]+) \(([0-9]+)\)\s+bitfield') {
        $bit = $Matches[1]; $val = $Matches[2]
        if (-not ('flags' -eq $campo)) { continue }
        if ($val -ne '0') { [void]$datos[$sq].flags.Add($bit) }
        continue
    }
    if ($ln -match '\u2500\u2500([a-z]+) \(\*\)\s+enum value') {
        $v = $Matches[1]
        if ($campo -eq 'initial_state') { $datos[$sq].initial = $v; $campo = '' }
        elseif ($campo -eq 'return_state') { $datos[$sq].ret = $v; $campo = '' }
        continue
    }
}
$sr.Close()
Write-Output "=== encuentro $NumEnc ==="
foreach ($k in ($datos.Keys | Sort-Object)) {
    $s = $datos[$k]
    Write-Output ("[{0,2}] {1,-10} actor_type={2,-5} ini={3,-28} ret={4,-28} puntos={5} flags={6}" -f `
        $k, $s.name, $s.actor_type, $s.initial, $s.ret, $s.starts, ($s.flags -join ','))
}
