param([int]$Enc = 39)
$ErrorActionPreference = 'Stop'
$d = "$env:TEMP\dump-new.txt"
$lin = [System.IO.File]::ReadAllLines($d)

function Idx([string]$pat) {
    for ($i = 0; $i -lt $lin.Length; $i++) { if ($lin[$i] -match $pat) { return $i } }
    return -1
}

$a = Idx ("encounters\[$Enc\]\s+struct")
$b = Idx '──platoons\['
if ($b -le $a) { $b = Idx '──command_lists\[' }
if ($a -lt 0) { Write-Output "no encontrado"; exit }
if ($b -le $a) { $b = $lin.Length - 1 }

$sq = @()
for ($i = $a; $i -le $b; $i++) {
    if ($lin[$i] -match '──squads\[(\d+)\]\s+struct') {
        $sq += [pscustomobject]@{ num = [int]$Matches[1]; start = $i; end = $b }
    }
}
for ($k = 0; $k -lt $sq.Count - 1; $k++) { $sq[$k].end = $sq[$k + 1].start - 1 }

Write-Output ("===== encuentro {0} ({1} escuadrones) =====" -f $Enc, $sq.Count)
foreach ($s in $sq) {
    $nombre = ''; $tipo = ''; $cnt = ''
    $sls = New-Object System.Collections.ArrayList
    $cur = $null
    for ($i = $s.start; $i -le $s.end; $i++) {
        $l = $lin[$i]
        if ($l -match '──name \((.*)\)\s+string') { $nombre = $Matches[1]; continue }
        if ($l -match '──actor_type \((\d+)\)') { $tipo = $Matches[1]; continue }
        if ($l -match '──normal_diff_count \((\d+)\)') { $cnt = $Matches[1]; continue }
        if ($l -match '──starting_locations\[(\d+)\]\s+struct') {
            $cur = [pscustomobject]@{ pos = ''; seq = ''; ini = ''; ret = '' }
            [void]$sls.Add($cur); continue
        }
        if ($null -eq $cur) { continue }
        if ($l -match '──position \(([-\d.]+),([-\d.]+),([-\d.]+)\)') {
            $cur.pos = ("{0,8:N1},{1,7:N1},{2,7:N1}" -f [double]$Matches[1], [double]$Matches[2], [double]$Matches[3]); continue
        }
        if ($l -match '──sequence_id \((\d+)\)') { $cur.seq = $Matches[1]; continue }
    }
    $seqs = ($sls | ForEach-Object { $_.seq }) -join ','
    Write-Output ("[{0,2}] {1,-12} tipo={2,-5} n={3,-2} puntos={4,-3} seq={5}" -f $s.num, $nombre, $tipo, $cnt, $sls.Count, $seqs)
    if ($sls.Count -le 6 -and $sls.Count -gt 0) {
        foreach ($p in $sls) { Write-Output ("       {0}  seq={1}" -f $p.pos, $p.seq) }
    } elseif ($sls.Count -gt 6) {
        Write-Output ("       (primeros 6) " + (($sls | Select-Object -First 6 | ForEach-Object { $_.pos }) -join ' | '))
    }
}
