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

# ---------- 0) volcado del escenario ----------
$dump = "$her\scenario-dump.txt"
$nTag = [int](InvEd @('-C', 'trigger_volumes'))
$nDump = -1
if (Test-Path $dump) {
    $cab = Select-String -Path $dump -Pattern 'trigger_volumes\[(\d+)\]\s+array' | Select-Object -First 1
    if ($cab) { $nDump = [int]$cab.Matches[0].Groups[1].Value }
}
if ($nDump -ne $nTag) {
    Write-Output "volcado desfasado (dump=$nDump tag=$nTag), regenerando..."
    & "$ed\invader-edit.exe" -L 'levels\a10\a10.scenario' -t $t 1> $dump 2> "$env:TEMP\ld.err"
    Write-Output ("  dump: {0:N1} KB" -f ((Get-Item $dump).Length / 1KB))
}
$lines = Get-Content $dump

# ---------- 1) centros de sala ----------
$pos = @{}
$curEnc = -1; $inFP = $false; $pending = $null
$nombresVol = New-Object System.Collections.ArrayList
$inVol = $false
foreach ($ln in $lines) {
    if ($ln -match '^trigger_volumes\[(\d+)\]\s+array') { $inVol = $true }
    if ($inVol -and $ln -match '\u2500\u2500name \((.*)\)\s+string') { [void]$nombresVol.Add($Matches[1]) }
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

$letras = 'b','c','d','e','f','g','h','i','j','k','l','m','n'
$zonas = New-Object System.Collections.ArrayList   # cada zona: @{ num; nombre; cx; cy; cz; hx; hy; hz }

for ($k = 0; $k -lt $letras.Count; $k++) {
    $L = $letras[$k]
    if (-not $pos.ContainsKey($L)) { throw "el grupo $L no tiene posiciones" }
    $xs = @($pos[$L] | ForEach-Object { $_[0] }); $ys = @($pos[$L] | ForEach-Object { $_[1] }); $zs = @($pos[$L] | ForEach-Object { $_[2] })
    [void]$zonas.Add(@{
        num = $k + 1; nombre = "mz_$L"
        cx = [double](($xs | Measure-Object -Average).Average)
        cy = [double](($ys | Measure-Object -Average).Average)
        cz = [double](($zs | Measure-Object -Average).Average)
        hx = 0.0; hy = 0.0; hz = 3.0
    })
}

# la sala de criogenia es UNA sola (zonas 14..17 son cuatro rincones de la
# misma sala): un unico volumen grande, zona 14
$cryo = @{ num = 14; nombre = 'mz_cryo'; cx = -51.0; cy = 4.5; cz = 0.75; hx = 7.5; hy = 12.5; hz = 3.0 }
[void]$zonas.Add($cryo)
function ZonaNombre([int]$n) { if ($n -eq 14) { 'mz_cryo' } else { "mz_$($letras[$n-1])" } }

# ---------- 2) tamanos: hasta medio camino de la sala vecina ----------
Write-Output "=== volumen de cada sala ==="
$final = New-Object System.Collections.ArrayList
foreach ($z in $zonas) {
    if ($z.nombre -eq 'mz_cryo') { [void]$final.Add($z); continue }
    $dmin = 99999.0
    foreach ($o in $zonas) {
        if ($o.nombre -eq $z.nombre) { continue }
        $d = [Math]::Sqrt([Math]::Pow($z.cx - $o.cx, 2) + [Math]::Pow($z.cy - $o.cy, 2))
        if ($d -lt $dmin) { $dmin = $d }
    }
    $r = 0.72 * $dmin
    if ($r -lt 5.0) { $r = 5.0 }
    if ($r -gt 18.0) { $r = 18.0 }
    $z.hx = $r; $z.hy = $r
    [void]$final.Add($z)
}
foreach ($z in $final) {
    $vol = (2 * $z.hx) * (2 * $z.hy) * (2 * $z.hz)
    $z | Add-Member -NotePropertyName vol -NotePropertyValue $vol -Force
    Write-Output ("  zona {0,2}  {1,-8} centro=({2,8:N2},{3,8:N2},{4,6:N2})  semiejes=({5:N1},{6:N1},{7:N1})" -f `
        $z.num, $z.nombre, $z.cx, $z.cy, $z.cz, $z.hx, $z.hy, $z.hz)
}

# ---------- 3) crear / actualizar los volumenes ----------
$idxVol = @{}
for ($i = 0; $i -lt $nombresVol.Count; $i++) {
    if ($nombresVol[$i] -match '^mz_') { $idxVol[$nombresVol[$i]] = $i }
}
Write-Output ("=== volumenes: {0} en el escenario, {1} del mod ===" -f $nombresVol.Count, $idxVol.Count)

foreach ($z in $final) {
    $ini = "{0:F6},{1:F6},{2:F6}" -f ($z.cx - $z.hx), ($z.cy - $z.hy), ($z.cz - $z.hz)
    $off = "{0:F6},{1:F6},{2:F6}" -f (2 * $z.hx), (2 * $z.hy), (2 * $z.hz)
    if ($idxVol.ContainsKey($z.nombre)) {
        $i = $idxVol[$z.nombre]
    } else {
        $i = [int](InvEd @('-C', 'trigger_volumes'))
        InvEd @('-I', 'trigger_volumes', '1', 'end') | Out-Null
        InvEd @('-S', "trigger_volumes[$i].type", 'fixed') | Out-Null
        InvEd @('-S', "trigger_volumes[$i].name", $z.nombre) | Out-Null
        InvEd @('-S', "trigger_volumes[$i].rotation_vector_forward", '1,0,0') | Out-Null
        InvEd @('-S', "trigger_volumes[$i].rotation_vector_up", '0,0,1') | Out-Null
    }
    InvEd @('-S', "trigger_volumes[$i].starting_corner", $ini) | Out-Null
    InvEd @('-S', "trigger_volumes[$i].ending_corner_offset", $off) | Out-Null
    Write-Output ("  {0,-8} [{1}]  min={2}  tam={3}" -f $z.nombre, $i, $ini, $off)
}

# ---------- 4) codigo HSC (mas grande primero: gana el mas especifico) ----------
$orden = @($final | Sort-Object -Property vol -Descending)
$hsc = New-Object System.Collections.ArrayList
foreach ($z in $orden) {
    [void]$hsc.Add(("  (if (volume_test_objects {0} (players)) (set mod_marines_cand {1}))" -f $z.nombre, $z.num))
}
$ruta = "$her\zonas-hsc.txt"
Set-Content -Path $ruta -Value ($hsc -join "`r`n") -Encoding ASCII -NoNewline
Write-Output "=== orden de prueba (mayor -> menor) ==="
foreach ($z in $orden) { Write-Output ("  {0,-8} zona {1,2}  volumen {2:N0}" -f $z.nombre, $z.num, $z.vol) }

# ---------- 5) pegar en el bloque ----------
$blk = "$her\bloque-mod.txt"
$txt = Get-Content $blk -Raw
$a = $txt.IndexOf('; ZONAS-INICIO'); $b = $txt.IndexOf('; ZONAS-FIN')
if ($a -lt 0 -or $b -lt 0) { throw 'faltan los marcadores ZONAS-INICIO / ZONAS-FIN en bloque-mod.txt' }
$txt = $txt.Substring(0, $a + '; ZONAS-INICIO'.Length) + "`r`n" + ($hsc -join "`r`n") + "`r`n" + $txt.Substring($b)
Set-Content -Path $blk -Value $txt -Encoding ASCII -NoNewline
Write-Output "bloque actualizado: $((Get-Content $blk | Measure-Object).Count) lineas"
Write-Output "LISTO"
