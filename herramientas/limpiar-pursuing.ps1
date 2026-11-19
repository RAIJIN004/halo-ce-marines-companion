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

$dump = "$her\scenario-dump.txt"
if (-not (Test-Path $dump)) { throw "falta $dump" }

# ---------- leer los escuadrones del encuentro 39 desde el volcado ----------
$sq = @{}
$enc = -1; $cur = -1; $campo = ''
foreach ($ln in (Get-Content $dump)) {
    if ($ln -match '\u2500\u2500encounters\[(\d+)\]\s+struct') { $enc = [int]$Matches[1]; $cur = -1; $campo = ''; continue }
    if ($enc -ne 39) { continue }
    if ($ln -match '\u2500\u2500squads\[(\d+)\]\s+struct') {
        $cur = [int]$Matches[1]; $campo = ''
        $sq[$cur] = @{ name = ''; masks = @{}; pursue = @() }
        continue
    }
    if ($cur -lt 0) { continue }
    if ($ln -match '\u2500\u2500(platoons|player_starting_locations|command_lists)\[') { $cur = -1; continue }
    if ($ln -match '\u2500\u2500name \((.*)\)\s+string') { $sq[$cur].name = $Matches[1]; $campo = ''; continue }
    if ($ln -match '\u2500\u2500(attacking|attacking_search|attacking_guard|defending|defending_search|defending_guard|pursuing)\s+bitmask') {
        $campo = $Matches[1]; $sq[$cur].masks[$campo] = @(); continue
    }
    if ($campo -ne '' -and $ln -match '\u2500\u2500([a-z]) \(1\)\s+bitfield') {
        if ($campo -eq 'pursuing') { $sq[$cur].pursue += $Matches[1] }
        else { $sq[$cur].masks[$campo] += $Matches[1] }
    }
}

Write-Output "=== escuadrones leidos: $($sq.Keys.Count) ==="
$letras = 'b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r'
function Esperada([int]$i) {
    if ($i -eq 0) { return 'a' }
    if ($i -le 17) { return $letras[$i - 1] }
    return $letras[[int][Math]::Floor(($i - 18) / 2)]
}

$estados = @('attacking','attacking_search','attacking_guard','defending','defending_search','defending_guard')
$malos = 0
Write-Output "num nombre        esperada  mascaras(6)                  pursuing"
foreach ($k in ($sq.Keys | Sort-Object)) {
    $s = $sq[$k]
    $e = Esperada $k
    $m = foreach ($x in $estados) { if ($s.masks.ContainsKey($x)) { ($s.masks[$x] -join '') } else { '?' } }
    $ok = $true
    foreach ($x in $estados) {
        if (-not $s.masks.ContainsKey($x)) { $ok = $false; continue }
        if (($s.masks[$x] -join '') -ne $e) { $ok = $false }
    }
    $pu = if ($s.pursue.Count -eq 0) { '-' } else { $s.pursue -join ',' }
    if (-not $ok -or $s.pursue.Count -ne 0) { $malos++ }
    Write-Output ("{0,3} {1,-12} {2,-9} {3,-28} {4}  {5}" -f $k, $s.name, $e, (($m -join ' ')), $pu, $(if (-not $ok) { '<-- MASCARA MAL' } else { '' }))
}
Write-Output "escuadrones con algo que corregir: $malos"

# ---------- limpiar pursuing (la guia y el retail lo dejan vacio) ----------
Write-Output "=== limpiando pursuing ==="
$n = 0
foreach ($k in ($sq.Keys | Sort-Object)) {
    foreach ($L in $sq[$k].pursue) {
        InvEd @('-S', "encounters[39].squads[$k].pursuing.$L", '0') | Out-Null
        $n++
    }
}
Write-Output "  bits de pursuing puestos a 0: $n"

# ---------- comprobacion final ----------
Write-Output "=== comprobacion ==="
foreach ($k in 0, 1, 18, 51) {
    $pu = @()
    foreach ($L in 'a','b','c','n','r','z') {
        $v = InvEd @('-G', "encounters[39].squads[$k].pursuing.$L")
        if ($v -eq '1') { $pu += $L }
    }
    $nm = InvEd @('-G', "encounters[39].squads[$k].name")
    Write-Output ("  squads[{0,2}] {1,-10} pursuing={2}" -f $k, $nm, $(if ($pu.Count -eq 0) { '(vacio)' } else { $pu -join ',' }))
}
Write-Output "LISTO"
