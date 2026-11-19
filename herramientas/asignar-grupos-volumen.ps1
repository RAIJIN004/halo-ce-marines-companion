# Asigna cada posicion de tiro nueva a la letra del escuadron vacio (adv_*)
# cuya sala (volumen mz_*) la contiene. Asi cada escuadron tiene posiciones
# en SU sala y la migracion automatica lleva a los marines a la sala del
# jugador.
$ErrorActionPreference = "Stop"
$csv = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\tiros-a-anadir.csv"

# volumenes mz_*: nombre => letra del escuadron (adv_<letra>)
# cajas alineadas: [x0,x1] x [y0,y1]
$volumenes = @(
  @{ letra = 'b'; x0 = -43.804310; x1 = -43.804310 + 10.608715; y0 = -24.526428; y1 = -24.526428 + 10.608715 },
  @{ letra = 'c'; x0 = -49.191505; x1 = -49.191505 + 10.608715; y0 = -19.501173; y1 = -19.501173 + 10.608715 },
  @{ letra = 'd'; x0 = -39.010059; x1 = -39.010059 + 14.536604; y0 = -18.991501; y1 = -18.991501 + 14.536604 },
  @{ letra = 'e'; x0 = -11.226510; x1 = -11.226510 + 12.801611; y0 = -6.889103;  y1 = -6.889103  + 12.801611 },
  @{ letra = 'f'; x0 = -39.959858; x1 = -39.959858 + 15.761704; y0 = 22.677345;  y1 = 22.677345  + 15.761704 },
  @{ letra = 'g'; x0 = -45.643963; x1 = -45.643963 + 15.761704; y0 = 13.323323;  y1 = 13.323323  + 15.761704 },
  @{ letra = 'h'; x0 = -58.004971; x1 = -58.004971 + 18.901411; y0 = 21.513477;  y1 = 21.513477  + 18.901411 },
  @{ letra = 'i'; x0 = -69.900856; x1 = -69.900856 + 18.901411; y0 = 27.061378;  y1 = 27.061378  + 18.901411 },
  @{ letra = 'j'; x0 = -92.063278; x1 = -92.063278 + 10.446819; y0 = 15.237008;  y1 = 15.237008  + 10.446819 },
  @{ letra = 'k'; x0 = -99.145203; x1 = -99.145203 + 10.446819; y0 = 16.811014;  y1 = 16.811014  + 10.446819 },
  @{ letra = 'l'; x0 = -95.755577; x1 = -95.755577 + 23.303926; y0 = 40.115185;  y1 = 40.115185  + 23.303926 },
  @{ letra = 'm'; x0 = -86.237000; x1 = -86.237000 + 21.661098; y0 = 27.288965;  y1 = 27.288965  + 21.661098 },
  @{ letra = 'n'; x0 = -19.388159; x1 = -19.388159 + 12.801611; y0 = -10.413269; y1 = -10.413269 + 12.801611 },
  @{ letra = 'o'; x0 = -58.500000; x1 = -58.500000 + 15.000000; y0 = -8.000000;  y1 = -8.000000  + 25.000000 }
)

$puntos = @(Get-Content $csv | ForEach-Object { $v = $_ -split ','; [pscustomobject]@{ x = [double]$v[0]; y = [double]$v[1]; z = [double]$v[2] } })
"posiciones: $($puntos.Count)"

$lineas = New-Object System.Collections.Generic.List[string]
$sinVolumen = 0
$porLetra = @{}
foreach ($p in $puntos) {
  $letra = $null
  foreach ($v in $volumenes) {
    if ($p.x -ge $v.x0 -and $p.x -le $v.x1 -and $p.y -ge $v.y0 -and $p.y -le $v.y1) { $letra = $v.letra; break }
  }
  if (-not $letra) {
    # fuera de todos los volumenes: la sala cuya caja queda mas cerca
    $mejor = $null; $mejorDist = [double]::MaxValue
    foreach ($v in $volumenes) {
      $dx = 0.0
      if ($p.x -lt $v.x0) { $dx = $v.x0 - $p.x } elseif ($p.x -gt $v.x1) { $dx = $p.x - $v.x1 }
      $dy = 0.0
      if ($p.y -lt $v.y0) { $dy = $v.y0 - $p.y } elseif ($p.y -gt $v.y1) { $dy = $p.y - $v.y1 }
      $d = $dx * $dx + $dy * $dy
      if ($d -lt $mejorDist) { $mejorDist = $d; $mejor = $v.letra }
    }
    $letra = $mejor
    $sinVolumen++
  }
  if (-not $porLetra.ContainsKey($letra)) { $porLetra[$letra] = 0 }
  $porLetra[$letra]++
  $lineas.Add([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0},{1},{2},{3}", $p.x, $p.y, $p.z, $letra))
}
$out = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\tiros-a-anadir-grupos.csv"
[System.IO.File]::WriteAllLines($out, [string[]]$lineas, (New-Object System.Text.UTF8Encoding($false)))
"sin volumen (grupo a): $sinVolumen"
"por letra:"
$porLetra.GetEnumerator() | Sort-Object Name | ForEach-Object { "  {0}: {1}" -f $_.Name, $_.Value }
"-> $out"