# Anade moddum02 y moddum03: bipeds no colocados para bloquear los
# asientos W-passenger y W-gunner del warthog senuelo (modlure).
# Se copia el placement de moddum01 (bipeds[131], type=1 marine).
$ErrorActionPreference = "Stop"
$ie   = "C:\Users\jhonv\Downloads\Halo-Editor\invader-edit.exe"
$tg   = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags"
$rel  = "levels\a10\a10.scenario"
$p    = Join-Path $tg $rel
$paso = 36

# --- 1) object_names: insertar 2 entradas al final de la tabla ---
$nNames = [int](& $ie -t $tg -C "object_names" $rel 2>&1)
"object_names antes: $nNames"

$b = [System.IO.File]::ReadAllBytes($p)
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)
$o335 = -1
$pos = 0
while (($pos = $s.IndexOf("cortana_x20`0", $pos)) -ge 0) {
  if ($pos + 2 * $paso + 6 -lt $b.Length) {
    $a = [System.Text.Encoding]::ASCII.GetString($b, $pos + $paso, 6)
    $c = [System.Text.Encoding]::ASCII.GetString($b, $pos + 2 * $paso, 6)
    if ($a.StartsWith("keyes") -and $c.StartsWith("chief")) { $o335 = $pos; break }
  }
  $pos++
}
if ($o335 -lt 0) { throw "no encontre tabla object_names" }
$base = $o335 - 335 * $paso
"tabla object_names base=0x{0:X}" -f $base

$nuevos = @("moddum02", "moddum03")
$indices = @()
$nombresYa = @()
for ($i = 0; $i -lt $nNames; $i++) {
  $nombresYa += [System.Text.Encoding]::ASCII.GetString($b, $base + $i * $paso, 32).Split([char]0)[0]
}
$bytes = $b
$cnt = $nNames
foreach ($name in $nuevos) {
  $idx = [Array]::IndexOf($nombresYa, $name)
  if ($idx -ge 0) {
    "ya existe $name en indice $idx"
  } else {
    $idx = $cnt
    $fin = $base + $cnt * $paso
    $tmp = New-Object byte[] ($bytes.Length + $paso)
    [Array]::Copy($bytes, 0, $tmp, 0, $fin)
    $nb = [System.Text.Encoding]::ASCII.GetBytes($name)
    [Array]::Copy($nb, 0, $tmp, $fin, $nb.Length)
    [Array]::Copy($bytes, $fin, $tmp, $fin + $paso, $bytes.Length - $fin)
    $bytes = $tmp
    $cnt++
    "anadido $name en indice $idx"
    $nombresYa += $name
  }
  $indices += $idx
}
if ($cnt -ne $nNames) {
  $bytes[0x244] = ($cnt -shr 24) -band 0xFF
  $bytes[0x245] = ($cnt -shr 16) -band 0xFF
  $bytes[0x246] = ($cnt -shr 8) -band 0xFF
  $bytes[0x247] = $cnt -band 0xFF
  [System.IO.File]::WriteAllBytes($p, $bytes)
}
"object_names despues: $cnt"

# --- 2) bipeds: copiar bipeds[131] (moddum01) dos veces ---
$nBip = [int](& $ie -t $tg -C "bipeds" $rel 2>&1)
"bipeds antes: $nBip"
$plantilla = 131   # moddum01
for ($j = 0; $j -lt $nuevos.Count; $j++) {
  $k = $nBip + $j
  & $ie -t $tg -c "bipeds[$plantilla]" end $rel 2>&1 | Out-Null
  & $ie -t $tg -S "bipeds[$k].name" $indices[$j] $rel 2>&1 | Out-Null
  & $ie -t $tg -S "bipeds[$k].type" 1 $rel 2>&1 | Out-Null
  & $ie -t $tg -S "bipeds[$k].not_placed.automatically" 1 $rel 2>&1 | Out-Null
  "biped[$k] = $($nuevos[$j]) (name=$($indices[$j]), type=1, not_auto)"
}
"bipeds despues: " + (& $ie -t $tg -C "bipeds" $rel 2>&1)
