$ErrorActionPreference = 'Stop'
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
$ed   = 'C:\Users\jhonv\Downloads\Halo-Editor'
$sc   = 'levels\a10\a10.scenario'
$t    = "$ed\Proyectos\a10\tags"
$her  = "$ed\Proyectos\a10\herramientas"
function InvEd([string[]]$argv) {
    $o = & "$ed\invader-edit.exe" @argv $sc -t $t 2>&1
    if ($LASTEXITCODE -ne 0) { throw "fallo: $($argv -join ' ')`n$o" }
    return ($o | Out-String).Trim()
}

# ---------- 1) volcar el escenario y sacar posiciones por grupo ----------
$dump = "$her\scenario-dump.txt"
if (-not (Test-Path $dump) -or (Get-Item $dump).Length -lt 1000000) {
    Write-Output "volcando escenario (puede tardar)..."
    & "$ed\invader-edit.exe" -L 'levels\a10\a10.scenario' -t $t 1> $dump 2> "$env:TEMP\ld.err"
    Write-Output ("  dump: {0:N1} KB" -f ((Get-Item $dump).Length/1KB))
}
$lines = Get-Content $dump

$pos = @{}
$curEnc = -1; $inFP = $false; $pending = $null
for ($i = 0; $i -lt $lines.Count; $i++) {
    $ln = $lines[$i]
    if ($ln -match '[\u251c\u2514]\u2500\u2500encounters\[(\d+)\]\s+struct') { $curEnc = [int]$Matches[1]; $inFP = $false; $pending = $null }
    if ($ln -match '\u2500\u2500firing_positions\[\d+\]\s+array') { if ($curEnc -eq 39) { $inFP = $true }; $pending = $null; continue }
    if ($inFP) {
        if ($ln -match '\u2500\u2500position \(([-0-9.]+),([-0-9.]+),([-0-9.]+)\)') {
            $pending = @([double]$Matches[1],[double]$Matches[2],[double]$Matches[3])
        } elseif ($pending -ne $null -and $ln -match '\u2500\u2500([a-z]+) \(\*\)\s+enum value') {
            $g = $Matches[1]
            if (-not $pos.ContainsKey($g)) { $pos[$g] = New-Object System.Collections.ArrayList }
            [void]$pos[$g].Add($pending)
            $pending = $null
        } elseif ($ln -match '\u2500\u2500(platoons|player_starting_locations)\[\d+\]\s+array') { $inFP = $false }
    }
}
Write-Output ("grupos con posiciones: {0}" -f (($pos.Keys | Sort-Object) -join ' '))

# ---------- 2) puntos de aparicion para cada escuadron sp_ ----------
Write-Output "=== puntos de aparicion ==="
$tot = [int](InvEd @('-C','encounters[39].squads'))
$hechos = 0
for ($idx = 18; $idx -lt $tot; $idx++) {
    $b = "encounters[39].squads[$idx]"
    $nm = InvEd @('-G', "$b.name")
    if ($nm -notmatch '^sp_([a-z])(\d)$') { Write-Output "  [$idx] '$nm' no es sp_*, se salta"; continue }
    $L = $Matches[1]
    $lista = $pos[$L]
    if (-not $lista -or $lista.Count -eq 0) { Write-Output "  [$idx] $nm SIN posiciones para el grupo $L"; continue }

    # dejar 4 puntos de aparicion, uno por cada posicion del grupo
    while ([int](InvEd @('-C', "$b.starting_locations")) -gt 0) { InvEd @('-E', "$b.starting_locations[0]") | Out-Null }
    for ($k = 0; $k -lt 4; $k++) {
        InvEd @('-I', "$b.starting_locations", '1', 'end') | Out-Null
        $p = $lista[$k % $lista.Count]
        InvEd @('-S', "$b.starting_locations[$k].position", ("{0:N6},{1:N6},{2:N6}" -f $p[0],$p[1],$p[2])) | Out-Null
        InvEd @('-S', "$b.starting_locations[$k].facing", '0.0') | Out-Null
    }
    $hechos++
    if ($hechos % 6 -eq 0) { Write-Output ("  ... {0} escuadrones listos" -f $hechos) }
}
Write-Output ("escuadrones con puntos de aparicion: {0}" -f $hechos)

Write-Output "=== comprobacion ==="
foreach ($idx in 18,19,50,51) {
    $b = "encounters[39].squads[$idx]"
    Write-Output ("  [{0}] {1,-8} n_puntos={2} p0={3}" -f $idx, (InvEd @('-G',"$b.name")),
        (InvEd @('-C',"$b.starting_locations")), (InvEd @('-G',"$b.starting_locations[0].position")))
}
Write-Output "LISTO"
