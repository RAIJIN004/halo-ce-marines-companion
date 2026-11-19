# Extrae el HSC original almacenado dentro de un scenario tag de Invader.
# Invader guarda la fuente como texto plano en source_files[0].source:
#   ;*<CRLF>==== ... extracted.hsc, file 1 of 1 ... <codigo> <NULL>
param(
  [Parameter(Mandatory=$true)][string]$Tag,
  [Parameter(Mandatory=$true)][string]$Salida
)
$ErrorActionPreference = "Stop"
$b = [System.IO.File]::ReadAllBytes($Tag)
$marca = [System.Text.Encoding]::ASCII.GetBytes("extracted.hsc, file 1 of 1")
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)
$i = $s.IndexOf("extracted.hsc, file 1 of 1")
if ($i -lt 0) { throw "no encontre la marca de fuente HSC en $Tag" }
# retroceder hasta la marca ";*" que inicia el bloque
$start = -1
for ($k = $i; $k -ge [Math]::Max(0, $i - 400); $k--) {
  if ($b[$k] -eq 0x3B -and $k+1 -lt $b.Length -and $b[$k+1] -eq 0x2A) { $start = $k; break }
}
if ($start -lt 0) { throw "no encontre el inicio ';*' de la fuente" }
# fin: primer byte 0 despues del inicio
$end = -1
for ($k = $start; $k -lt $b.Length; $k++) { if ($b[$k] -eq 0) { $end = $k; break } }
if ($end -lt 0) { throw "no encontre el fin de la fuente" }
$txt = [System.Text.Encoding]::ASCII.GetString($b, $start, $end - $start)
$txt = $txt.TrimEnd([char]13, [char]10)
$dir = [System.IO.Path]::GetDirectoryName($Salida)
if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
[System.IO.File]::WriteAllText($Salida, $txt, (New-Object System.Text.UTF8Encoding($false)))
"extraidas $($txt.Length) chars desde 0x{0:X} a 0x{1:X} -> $Salida" -f $start,$end
