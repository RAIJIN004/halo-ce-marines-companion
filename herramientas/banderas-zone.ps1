$ErrorActionPreference = 'Stop'
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
$ed  = 'C:\Users\jhonv\Downloads\Halo-Editor'
$sc  = 'levels\a10\a10.scenario'
$t   = "$ed\Proyectos\a10\tags"
$her = "$ed\Proyectos\a10\herramientas"

function InvEd([string[]]$argv) {
    $o = & "$ed\invader-edit.exe" @argv $sc -t $t 2>&1
    if ($LASTEXITCODE -ne 0) { throw "fallo: $($argv -join ' ')`n$o" }
    return ($o | Out-String).Trim()
}

# ---------- 0) volcado del escenario (se rehace si esta desfasado) ----------
$dump = "$her\scenario-dump.txt"
$nTag = [int](InvEd @('-C', 'cutscene_flags'))
$nDump = -1
if (Test-Path $dump) {
    $cab = Select-String -Path $dump -Pattern '^cutscene_flags\[(\d+)\]' | Select-Object -First 1
    if ($cab) { $nDump = [int]$cab.Matches[0].Groups[1].Value }
}
if ($nDump -ne $nTag) {
    Write-Output "volcado desfasado (dump=$nDump tag=$nTag), regenerando..."
    & "$ed\invader-edit.exe" -L 'levels\a10\a10.scenario' -t $t 1> $dump 2> "$env:TEMP\ld.err"
    Write-Output ("  dump: {0:N1} KB" -f ((Get-Item $dump).Length / 1KB))
}
$lines = Get-Content $dump

# ---------- 1) centro de cada grupo de posiciones (encuentro 39) ----------
$pos = @{}
$curEnc = -1; $inFP = $false; $pending = $null
$flagsDump = New-Object System.Collections.ArrayList
$inFlags = $false
foreach ($ln in $lines) {
    if ($ln -match '^cutscene_flags\[(\d+)\]') { $inFlags = $true }
    if ($inFlags -and $ln -match '\u2500\u2500name \((.*)\)\s+string') { [void]$flagsDump.Add($Matches[1]) }
    if ($ln -match '[\u251c\u2514]\u2500\u2500encounters\[(\d+)\]\s+struct') { $curEnc = [int]$Matches[1]; $inFP = $false; $pending = $null; continue }
    if ($ln -match '\u2500\u2500firing_positions\[\d+\]\s+array') { $inFP = ($curEnc -eq 39); $pending = $null; continue }
    if (-not $inFP) { continue }
    if ($ln -match '\u2500\u2500position \(([-0-9.]+),([-0-9.]+),([-0-9.]+)\)') {
        $pending = @([double]$Matches[1], [double]$Matches[2], [double]$Matches[3])
    } elseif ($null -ne $pending -and $ln -match '\u2500\u2500([a-z]+) \(\*\)\s+enum value') {
        $g = $Matches[1]
        if (-not $pos.ContainsKey($g)) { $pos[$g] = New-Object System.Collections.ArrayList }
        [void]$pos[$g].Add($pending)
        $pending = $null
    } elseif ($ln -match '\u2500\u2500(platoons|player_starting_locations|command_lists)\[\d+\]\s+(array|struct)') { $inFP = $false }
}

$letras = 'b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r'
$centro = @{}
Write-Output "=== centro de cada sala (grupo de posiciones) ==="
for ($k = 0; $k -lt $letras.Count; $k++) {
    $L = $letras[$k]
    if (-not $pos.ContainsKey($L) -or $pos[$L].Count -eq 0) { throw "el grupo $L no tiene posiciones" }
    $xs = @($pos[$L] | ForEach-Object { $_[0] }); $ys = @($pos[$L] | ForEach-Object { $_[1] }); $zs = @($pos[$L] | ForEach-Object { $_[2] })
    $c = @([double](($xs | Measure-Object -Average).Average), [double](($ys | Measure-Object -Average).Average), [double](($zs | Measure-Object -Average).Average))
    $centro[$L] = $c
    $dx = ($xs | Measure-Object -Maximum).Maximum - ($xs | Measure-Object -Minimum).Minimum
    $dy = ($ys | Measure-Object -Maximum).Maximum - ($ys | Measure-Object -Minimum).Minimum
    Write-Output ("  zona {0,2} ({1})  n={2,2}  centro=({3,9:N2},{4,9:N2},{5,7:N2})  ancho={6:N1} x {7:N1}" -f `
        ($k + 1), $L, $pos[$L].Count, $c[0], $c[1], $c[2], $dx, $dy)
}

# ---------- 2) crear / actualizar las banderas mod_z* ----------
$idxFlag = @{}
for ($i = 0; $i -lt $flagsDump.Count; $i++) {
    if ($flagsDump[$i] -match '^mod_z([a-r])$') { $idxFlag[$Matches[1]] = $i }
}
Write-Output ("=== banderas: {0} en el escenario, {1} del mod ===" -f $flagsDump.Count, $idxFlag.Count)

foreach ($L in $letras) {
    $nm = "mod_z$L"
    $c = $centro[$L]
    $p = "{0:F6},{1:F6},{2:F6}" -f $c[0], $c[1], $c[2]
    if ($idxFlag.ContainsKey($L)) {
        $i = $idxFlag[$L]
        InvEd @('-S', "cutscene_flags[$i].position", $p) | Out-Null
        Write-Output ("  {0,-8} ya existia [{1}] -> posicion corregida  {2}" -f $nm, $i, $p)
    } else {
        $i = [int](InvEd @('-C', 'cutscene_flags'))
        InvEd @('-I', 'cutscene_flags', '1', 'end') | Out-Null
        InvEd @('-S', "cutscene_flags[$i].name", $nm) | Out-Null
        InvEd @('-S', "cutscene_flags[$i].position", $p) | Out-Null
        InvEd @('-S', "cutscene_flags[$i].facing", '0,0') | Out-Null
        Write-Output ("  {0,-8} creada [{1}]  {2}" -f $nm, $i, $p)
    }
}

Write-Output "=== comprobacion ==="
$tot2 = [int](InvEd @('-C', 'cutscene_flags'))
Write-Output "  banderas ahora: $tot2 (antes $nTag)"
foreach ($L in 'b','h','o','r') {
    $i = $idxFlag[$L]
    if ($null -eq $i) { $i = $nTag + ($letras.IndexOf($L)) }
    Write-Output ("  mod_z{0} [{1}] {2} pos={3}" -f $L, $i, (InvEd @('-G', "cutscene_flags[$i].name")), (InvEd @('-G', "cutscene_flags[$i].position")))
}
Write-Output "LISTO"
