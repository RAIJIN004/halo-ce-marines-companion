# Inspecciona el struct encounter_definition DENTRO del cache compilado (.map).
# Halo 1 usa big-endian en tags/cache.
# Layout (OpenCE source/ai/ai_scenario_definitions.h):
#   +0    char name[32]
#   +32   uint32 flags
#   +36   int16 team_index
#   +38   int16 version
#   +40   int16 searching
#   +42   int16 manual_bsp_index
#   +44   float respawn_low
#   +48   float respawn_high
#   +52   uint32 unused[18]
#   +124  uint16 pad2
#   +126  int16 runtime_structure_bsp_reference_index
#   +128  tag_block squads (count int32 BE)
param(
  [string]$Mapa = "C:\Users\jhonv\Downloads\Halo-PC\MAPS\a10.map",
  [string[]]$Nombres = @("cryo_tech","cryo_search","crossfire","containment_2","containment_3","mod_marines")
)
if (!(Test-Path $Mapa)) { "No existe: $Mapa"; exit 1 }
$b = [System.IO.File]::ReadAllBytes($Mapa)
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)
"Mapa: $Mapa  ($($b.Length) bytes)"
function BE16([int]$o) { return (($b[$o] -shl 8) -bor $b[$o+1]) }
function BE32([int]$o) { return ([uint32]$b[$o] -shl 24) -bor ([uint32]$b[$o+1] -shl 16) -bor ([uint32]$b[$o+2] -shl 8) -bor [uint32]$b[$o+3] }
function SBE16([int]$o) { $v = BE16 $o; if ($v -ge 32768) { return $v - 65536 } else { return $v } }
foreach ($n in $Nombres) {
  $pos = 0
  $found = $false
  while (($pos = $s.IndexOf($n, $pos)) -ge 0) {
    $h = $pos
    $flags = BE32 ($h + 32)
    $team = SBE16 ($h + 36)
    $man  = SBE16 ($h + 42)
    $rt   = SBE16 ($h + 126)
    $sq   = BE32 ($h + 128)
    $valid = ($flags -le 0x7F) -and ($team -ge 0) -and ($team -le 9) -and ($sq -ge 0) -and ($sq -le 120)
    if ($valid) {
      $found = $true
      "{0,-14} 0x{1:X7} flags=0x{2:X} team={3} manual={4} runtime={5} squads={6}" -f $n, $h, $flags, $team, $man, $rt, $sq
      # nombre siguiente (para confirmar vecindad de encounter)
      $nx = $s.Substring($h, 40) -replace "`0", "."
      "                 nombre+40: [$nx]"
    }
    $pos += 1
  }
  if (-not $found) { "$n : sin coincidencia valida" }
}
