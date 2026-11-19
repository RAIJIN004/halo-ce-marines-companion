# Selecciona firing positions retail bien repartidas espacialmente para
# copiarlas al encuentro mod_marines. El motor busca posiciones de tiro
# dentro de 15 world units del actor; con posiciones separadas ~7 wu la
# cobertura es buena en todo el mapa.
$ErrorActionPreference = "Stop"
$c = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\tiros-retail.csv"
$d = Import-Csv $c

$puntos = @()
foreach ($r in $d) {
  $puntos += [pscustomobject]@{ x = [double]$r.x; y = [double]$r.y; z = [double]$r.z; enc = $r.encuentro }
}
"retail: $($puntos.Count)"

$separacion = 4.0
$max = 300
$elegidos = New-Object System.Collections.Generic.List[object]

# ordenar por encuentro para que queden de todas las zonas
$orden = $puntos | Sort-Object enc, x, y
foreach ($p in $orden) {
  $ok = $true
  foreach ($e in $elegidos) {
    $dx = $p.x - $e.x; $dy = $p.y - $e.y
    if (($dx * $dx + $dy * $dy) -lt ($separacion * $separacion)) { $ok = $false; break }
  }
  if ($ok) {
    $elegidos.Add($p)
    if ($elegidos.Count -ge $max) { break }
  }
}
"elegidos: $($elegidos.Count) (separacion $separacion wu)"

# volcar a CSV
$out = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\datos\tiros-a-anadir.csv"
$lineas = New-Object System.Collections.Generic.List[string]
foreach ($e in $elegidos) { $lineas.Add([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0},{1},{2}", $e.x, $e.y, $e.z)) }
[System.IO.File]::WriteAllLines($out, [string[]]$lineas, (New-Object System.Text.UTF8Encoding($false)))
"-> $out"
