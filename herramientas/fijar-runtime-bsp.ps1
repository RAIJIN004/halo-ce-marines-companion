# Escribe el campo runtime_structure_bsp_reference_index del encuentro
# mod_marines en el TAG de origen (tags\levels\a10\a10.scenario).
#
# Por que hace falta: Invader copia ese campo tal cual del tag al cache, pero
# invader-edit no lo expone (en las definiciones HEK figura como "unused"), y
# el valor heredado del struct copiado (4 = BSP a10d) deja al encuentro fuera
# del BSP activo: el motor nunca lo activa y los actores quedan en T-pose.
#
# Valores utiles:
#    0     -> solo BSP 0 (a10, bahia criogenica)
#    -1    -> NONE: vale en cualquier BSP (lo que queremos para seguir al jugador)
#
# El tag Halo 1 esta en big-endian. Struct encounter (176 bytes):
#   +0x00 name[32]  +0x20 flags  +0x24 team  +0x26 version  +0x28 search
#   +0x2A manual_bsp_index  +0x2C/+0x30 respawn  +0x34 unused[18] 0x7C pad2
#   +0x7E int16 runtime_bsp  +0x80 tag_block squads
#
# Validaciones para no tocar datos que no son el encuentro (p. ej. cadenas
# del script compilado que contengan la palabra "mod_marines"):
#   - el campo name[32] es exactamente "mod_marines" + NUL + ceros hasta
#     completar los 32 bytes;
#   - squads entre 1 y 64 (limite del motor por encuentro);
#   - flags <= 0x7F.
param(
  [string]$Tag = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags\levels\a10\a10.scenario",
  [string]$Encuentro = "mod_marines",
  [int]$Runtime = -1,
  [switch]$SoloVer
)
$b = [System.IO.File]::ReadAllBytes($Tag)
$nombre = [System.Text.Encoding]::ASCII.GetBytes($Encuentro)
$nombreLargo = $nombre.Length
$campoNombre = 32
$encontrados = 0
$escritos = 0
for ($i = 0; $i -le $b.Length - 176; $i++) {
  if ($b[$i] -ne $nombre[0]) { continue }
  $ok = $true
  for ($j = 1; $j -lt $nombreLargo; $j++) { if ($b[$i + $j] -ne $nombre[$j]) { $ok = $false; break } }
  if (-not $ok) { continue }
  # el nombre del struct debe rellenarse con ceros hasta los 32 bytes
  # (descarta apariciones dentro de cadenas del script compilado)
  if (($i + $campoNombre) -gt $b.Length) { continue }
  $campoLimpio = $true
  for ($k = $nombreLargo; $k -lt $campoNombre; $k++) { if ($b[$i + $k] -ne 0) { $campoLimpio = $false; break } }
  if (-not $campoLimpio) {
    "  (descartado: 'mod_marines' dentro de otra cadena en 0x{0:X})" -f $i
    continue
  }
  # flags BE en +0x20 (bits esperados: not_initially_created / manual_bsp_specified)
  $flags = (($b[$i+0x20] -shl 24) -bor ($b[$i+0x21] -shl 16) -bor ($b[$i+0x22] -shl 8) -bor $b[$i+0x23])
  $squads = (($b[$i+0x80] -shl 24) -bor ($b[$i+0x81] -shl 16) -bor ($b[$i+0x82] -shl 8) -bor $b[$i+0x83])
  $rt = (($b[$i+0x7E] -shl 8) -bor $b[$i+0x7F]); if ($rt -ge 32768) { $rt -= 65536 }
  if (($flags -gt 0x7F) -or ($squads -lt 1) -or ($squads -gt 64)) {
    "  (descartado en 0x{0:X}: flags=0x{1:X} squads={2})" -f $i, $flags, $squads
    continue
  }
  $encontrados++
  "encontrado en 0x{0:X}: flags=0x{1:X} squads={2} runtime_actual={3}" -f $i, $flags, $squads, $rt
  if (-not $SoloVer) {
    $v = $Runtime -band 0xFFFF
    $b[$i+0x7E] = ($v -shr 8) -band 0xFF
    $b[$i+0x7F] = $v -band 0xFF
    "  runtime escrito = $Runtime"
    $escritos++
  }
}
if ($encontrados -eq 0) { "No encontre el encuentro '$Encuentro' en el tag"; exit 1 }
if (-not $SoloVer) {
  [System.IO.File]::WriteAllBytes($Tag, $b)
  "Guardado $Tag  ($escritos encuentro(s) modificado(s))"
} else {
  "verificacion: $encontrados encuentro(s) valido(s)"
}
