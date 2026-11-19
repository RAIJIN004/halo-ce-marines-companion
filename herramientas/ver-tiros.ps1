$ErrorActionPreference = 'Stop'
$d = "$env:TEMP\dump-new.txt"
$lin = [System.IO.File]::ReadAllLines($d)
$a = -1
for ($i = 0; $i -lt $lin.Length; $i++) { if ($lin[$i] -match '──firing_positions\[\d+\]\s+array') { $a = $i; break } }
if ($a -lt 0) { Write-Output 'no firing_positions'; exit }
$grupos = @{}
$cur = $null; $n = 0
for ($i = $a; $i -lt [Math]::Min($a + 6000, $lin.Length); $i++) {
    $l = $lin[$i]
    if ($i -gt $a -and $l -match '^\s*[│ ]*[├└]──(platoons|command_lists|player_starting_locations|encounters)\[') { break }
    if ($l -match '──firing_positions\[(\d+)\]') {
        if ($l -match 'struct') { $cur = [pscustomobject]@{ pos = ''; grupo = '' }; $n++ ; continue }
        else { continue }
    }
    if ($null -eq $cur) { continue }
    if ($l -match '──position \(([-\d.]+),([-\d.]+),([-\d.]+)\)') { $cur.pos = ("{0,8:N1},{1,7:N1},{2,7:N1}" -f [double]$Matches[1], [double]$Matches[2], [double]$Matches[3]); continue }
    if ($l -match '──group_index') { $cur.grupo = ''; continue }
    if ($l -match '──([a-z]) \(([* ])\)\s+enum value') { $cur.grupo = $Matches[1]; continue }
    if ($l -match '──(position|group_index|_3d_firing_positions)') { continue }
}
Write-Output "total entradas recorridas: $n"
