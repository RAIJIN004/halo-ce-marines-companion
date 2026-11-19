# Autodetecta el array de encuentros dentro de un .map (PC, little-endian) y
# muestra flags / manual_bsp_index / runtime_structure_bsp_reference_index.
# El struct mide 176 bytes (0xB0). Layout:
#   +0x00 name[32]            +0x20 uint32 flags        +0x24 int16 team
#   +0x26 int16 version       +0x28 int16 searching     +0x2A int16 manual_bsp
#   +0x2C float respawn_low   +0x30 float respawn_high  +0x34 uint32 unused[18]
#   +0x7C uint16 pad2         +0x7E int16 runtime_bsp   +0x80 tag_block squads
param(
  [string]$Mapa = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\maps\a10.map",
  [int]$Count = 40
)
if (!(Test-Path $Mapa)) { "No existe: $Mapa"; exit 1 }
$b = [System.IO.File]::ReadAllBytes($Mapa)
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)

# localizar "cryo_tech" cuyo struct tenga flags 0x41 y 2 squads
$base = -1
$pos = 0
while (($pos = $s.IndexOf("cryo_tech", $pos)) -ge 0) {
  if (($pos + 0x84) -lt $b.Length) {
    $flags = [BitConverter]::ToUInt32($b, $pos + 0x20)
    $sq = [BitConverter]::ToUInt32($b, $pos + 0x80)
    if ($flags -eq 0x41 -and $sq -eq 2) { $base = $pos; break }
  }
  $pos++
}
if ($base -lt 0) { "No pude localizar el array de encuentros en $Mapa"; exit 1 }

"Mapa: $Mapa  ($($b.Length) bytes)  base=0x{0:X}" -f $base
"idx  offset     flags   team ver srch man  runtime  squads  nombre"
for ($i = 0; $i -lt $Count; $i++) {
  $o = $base + $i * 0xB0
  $n = [System.Text.Encoding]::ASCII.GetString($b, $o, 32).Split([char]0)[0]
  "{0,3}  0x{1:X7}  0x{2:X4}  {3,2}   {4,2}  {5,3}  {6,3}  {7,6}  {8,5}   {9}" -f `
    $i, $o, ([BitConverter]::ToUInt32($b, $o + 0x20)), ([BitConverter]::ToInt16($b, $o + 0x24)), `
    ([BitConverter]::ToInt16($b, $o + 0x26)), ([BitConverter]::ToInt16($b, $o + 0x28)), `
    ([BitConverter]::ToInt16($b, $o + 0x2A)), ([BitConverter]::ToInt16($b, $o + 0x7E)), `
    ([BitConverter]::ToUInt32($b, $o + 0x80)), $n
}
