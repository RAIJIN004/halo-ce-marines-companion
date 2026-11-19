# Anade un placement de VEHICULO senuelo (warthog) no colocado, con nombre
# "modlure" en object_names, para usar con ai_go_to_vehicle_override.
# El vehiculo se crea con object_create_anew y se attacha a los pies del
# jugador; los marines caminan hacia el (hacia ti) sin subirse, porque el
# bucle re-emite la orden antes de que puedan entrar al asiento.
$ErrorActionPreference = "Stop"
$ie   = "C:\Users\jhonv\Downloads\Halo-Editor\invader-edit.exe"
$tg   = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags"
$rel  = "levels\a10\a10.scenario"
$p    = Join-Path $tg $rel
$bk   = "$p.bak-lure"

if (!(Test-Path $bk)) { Copy-Item $p $bk -Force; "backup: $bk" }

# --- 1) añadir nombre "modlure" a object_names (insercion de bytes) ---
$ieArgs = @("-t", $tg, "-C", "object_names", $rel)
$nNames = [int](& $ie @ieArgs 2>&1)
"object_names antes: $nNames"

# localizar base de la tabla (misma tecnica que agregar-slots-spawn.ps1)
$b = [System.IO.File]::ReadAllBytes($p)
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)
$paso = 36
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

# ver si ya existe modlure
$existe = $false
for ($i = 0; $i -lt $nNames; $i++) {
  $nm = [System.Text.Encoding]::ASCII.GetString($b, $base + $i * $paso, 32).Split([char]0)[0]
  if ($nm -eq "modlure") { $existe = $true; "modlure ya existe en indice $i"; break }
}

$nombreIdx = -1
if (-not $existe) {
  # insertar 1 entrada de 36 bytes al final de la tabla
  $finTabla = $base + $nNames * $paso
  $nuevo = New-Object byte[] ($b.Length + $paso)
  [Array]::Copy($b, 0, $nuevo, 0, $finTabla)
  $bytes = [System.Text.Encoding]::ASCII.GetBytes("modlure")
  [Array]::Copy($bytes, 0, $nuevo, $finTabla, $bytes.Length)
  [Array]::Copy($b, $finTabla, $nuevo, $finTabla + $paso, $b.Length - $finTabla)
  $nuevoCuenta = $nNames + 1
  $nuevo[0x244] = ($nuevoCuenta -shr 24) -band 0xFF
  $nuevo[0x245] = ($nuevoCuenta -shr 16) -band 0xFF
  $nuevo[0x246] = ($nuevoCuenta -shr 8) -band 0xFF
  $nuevo[0x247] = $nuevoCuenta -band 0xFF
  [System.IO.File]::WriteAllBytes($p, $nuevo)
  $nombreIdx = $nNames
  "anadido modlure en indice $nombreIdx (object_names $nNames -> $nuevoCuenta)"
} else {
  # encontrar el indice
  for ($i = 0; $i -lt $nNames; $i++) {
    $nm = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($p), $base + $i * $paso, 32).Split([char]0)[0]
    if ($nm -eq "modlure") { $nombreIdx = $i; break }
  }
}

# --- 2) añadir placement de vehiculo ---
$nVeh = [int](& $ie -t $tg -C "vehicles" $rel 2>&1)
"vehicles antes: $nVeh"
# copiar vehicles[0] como plantilla
& $ie -t $tg -c "vehicles[0]" end $rel 2>&1 | Out-Null
# configurar el nuevo placement (indice nVeh)
$k = $nVeh
& $ie -t $tg -S "vehicles[$k].type" 4 $rel 2>&1 | Out-Null           # warthog (paleta idx 4)
& $ie -t $tg -S "vehicles[$k].name" $nombreIdx $rel 2>&1 | Out-Null
& $ie -t $tg -S "vehicles[$k].not_placed.automatically" 1 $rel 2>&1 | Out-Null
& $ie -t $tg -S "vehicles[$k].position" "-55.430302,0.799534,0.000998" $rel 2>&1 | Out-Null
& $ie -t $tg -S "vehicles[$k].rotation" "0,0,0" $rel 2>&1 | Out-Null
& $ie -t $tg -S "vehicles[$k].flags.dead" 0 $rel 2>&1 | Out-Null
"placement vehiculo[$k] creado (type=4 warthog, name=$nombreIdx, not_auto=1)"

# verificar
"vehicles despues: " + (& $ie -t $tg -C "vehicles" $rel 2>&1)
"object_names despues: " + (& $ie -t $tg -C "object_names" $rel 2>&1)
Write-Output ("nombre en indice {0}: {1}" -f $nombreIdx, (& $ie -t $tg -G "object_names[$nombreIdx].name" $rel 2>&1))
