# Extrae todas las firing_positions de los encuentros RETAIL (0..38) del dump
# y las volca a un CSV para analizar la cobertura del mapa.
$ErrorActionPreference = "Stop"
$d = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\dump-scenario.txt"
$lin = [System.IO.File]::ReadAllLines($d)

# localizar todos los bloques firing_positions
$bloques = @()
for ($i = 0; $i -lt $lin.Count; $i++) {
  if ($lin[$i] -match '──firing_positions\[(\d+)\]\s+array') { $bloques += [pscustomobject]@{ line = $i; count = [int]$Matches[1] } }
}
"bloques firing_positions: $($bloques.Count)"

$salida = New-Object System.Collections.Generic.List[string]
$salida.Add("encuentro,x,y,z,grupo")

foreach ($b in $bloques) {
  # encuentro al que pertenece
  $enc = -1
  for ($j = $b.line; $j -ge 0; $j--) {
    if ($lin[$j] -match '──encounters\[(\d+)\]\s+struct') { $enc = [int]$Matches[1]; break }
  }
  if ($enc -ge 39) { continue }   # solo retail (0..38)
  $cur = $null
  for ($i = $b.line; $i -lt [Math]::Min($b.line + 20000, $lin.Count); $i++) {
    $l = $lin[$i]
    if ($i -gt $b.line -and $l -match '^\s*[│ ]*[├└]──(platoons|command_lists|player_starting_locations|cutscene_flags|encounters)\[') { break }
    if ($l -match '──firing_positions\[(\d+)\]\s+struct') {
      if ($cur) { $salida.Add(("{0},{1},{2},{3},{4}" -f $enc, $cur.x, $cur.y, $cur.z, $cur.g)) }
      $cur = [pscustomobject]@{ x = ''; y = ''; z = ''; g = '' }
      continue
    }
    if (-not $cur) { continue }
    if ($l -match '──position \(([-\d.]+),([-\d.]+),([-\d.]+)\)') { $cur.x = $Matches[1]; $cur.y = $Matches[2]; $cur.z = $Matches[3]; continue }
    if ($l -match '──group_index') { continue }
    if ($l -match '──([a-z]) \(\*\)\s+enum value') { $cur.g = $Matches[1]; continue }
    if ($l -match '──(position|group_index|_3d_firing_positions)') { continue }
  }
  if ($cur) { $salida.Add(("{0},{1},{2},{3},{4}" -f $enc, $cur.x, $cur.y, $cur.z, $cur.g)) }
}

$out = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\tiros-retail.csv"
[System.IO.File]::WriteAllLines($out, [string[]]$salida, (New-Object System.Text.UTF8Encoding($false)))
"total posiciones retail: $($salida.Count - 1)  -> $out"