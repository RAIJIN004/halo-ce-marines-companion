# Lee el campo runtime_structure_bsp_reference_index de los encuentros
# directamente del cache compilado (.map), sin depender de invader-edit.
#
# Layout del struct encounter_definition en cache:
#   +0    char name[32]
#   +32   uint32 flags
#   +36   int16  team_index
#   +38   int16  version        (tag: search_behavior)
#   +40   int16  searching
#   +42   int16  manual_bsp_index
#   +44   float  respawn_low
#   +48   float  respawn_high
#   +52   uint32 unused[18]
#   +124  uint16 pad2
#   +126  int16  runtime_structure_bsp_reference_index   <-- el importante
#   +128  tag_block squads (count, ...)
param(
  [string]$Mapa = "C:\Users\jhonv\Downloads\Halo-PC\MAPS\a10.map",
  [string[]]$Nombres = @("cryo_tech","cryo_search","crossfire","containment_2","containment_3","mod_marines")
)

if (!(Test-Path $Mapa)) { "No existe: $Mapa"; exit 1 }
$b = [System.IO.File]::ReadAllBytes($Mapa)
"Mapa: $Mapa  ($($b.Length) bytes)"

foreach ($n in $Nombres) {
  $pat = [System.Text.Encoding]::ASCII.GetBytes($n)
  $hits = @()
  for ($i = 0; $i -le $b.Length - $pat.Length; $i++) {
    if ($b[$i] -ne $pat[0]) { continue }
    $ok = $true
    for ($j = 1; $j -lt $pat.Length; $j++) { if ($b[$i+$j] -ne $pat[$j]) { $ok = $false; break } }
    if ($ok) { $hits += $i }
  }
  if ($hits.Count -eq 0) { "$n : NO ENCONTRADO"; continue }
  foreach ($h in $hits) {
    # validar que parezca un encounter: flags pequeno y squads.count razonable
    $flags  = [BitConverter]::ToUInt32($b, $h + 32)
    $team   = [BitConverter]::ToInt16($b, $h + 36)
    $search = [BitConverter]::ToInt16($b, $h + 40)
    $manual = [BitConverter]::ToInt16($b, $h + 42)
    $runtime= [BitConverter]::ToInt16($b, $h + 126)
    $squads = [BitConverter]::ToInt32($b, $h + 128)
    $platoons = [BitConverter]::ToInt32($b, $h + 128 + 12)
    $fps      = [BitConverter]::ToInt32($b, $h + 128 + 24)
    $valid = ($flags -lt 1024) -and ($team -ge 0) -and ($team -le 9) -and ($squads -ge 0) -and ($squads -lt 200)
    "{0,-14} off=0x{1:X7} flags=0x{2:X} team={3} search={4} manual={5} runtime={6} squads={7} platoons={8} firingpos={9} {10}" -f `
      $n, $h, $flags, $team, $search, $manual, $runtime, $squads, $platoons, $fps, $(if($valid){"OK"}else{"(dudoso)"})
  }
}
