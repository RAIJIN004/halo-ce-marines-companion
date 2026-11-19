# Sincroniza los comentarios de bloque-mod.txt (copia maestra, para leer)
# dentro de extracted.hsc (lo que se compila). Solo cambian comentarios:
# el codigo compilado debe salir identico.
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$b = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\bloque-mod.txt"
$h = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\data\levels\a10\scripts\extracted.hsc"

$bl = [System.IO.File]::ReadAllLines($b)
$hl = [System.IO.File]::ReadAllLines($h)

# en el maestro, el codigo termina justo antes de la documentacion de la pose T
$corte = -1
for ($i = 0; $i -lt $bl.Count; $i++) { if ($bl[$i] -match '^; CAUSA REAL DE LA POSE T') { $corte = $i; break } }
if ($corte -lt 0) { throw "no encuentro el corte de la documentacion en bloque-mod.txt" }
$nuevo = New-Object System.Collections.Generic.List[string]
$nuevo.AddRange([string[]]$bl[0..($corte - 1)])
while ($nuevo.Count -gt 0 -and $nuevo[$nuevo.Count - 1].Trim() -eq "") { $nuevo.RemoveAt($nuevo.Count - 1) }

# en el hsc, el bloque del mod empieza en la linea "; ====" anterior al titulo
$ini = -1
for ($i = 0; $i -lt $hl.Count; $i++) { if ($hl[$i] -match '^; MOD: marines que te acompasan') { $ini = $i - 1; break } }
if ($ini -lt 0) { throw "no encuentro el bloque del mod en extracted.hsc" }
"hsc: reemplazo lineas $($ini+1)..$($hl.Count) por $($nuevo.Count) lineas del maestro"

$salida = New-Object System.Collections.Generic.List[string]
$salida.AddRange([string[]]$hl[0..($ini - 1)])
$salida.AddRange([string[]]$nuevo)
[System.IO.File]::WriteAllLines($h, [string[]]$salida, $enc)
"guardado: $($salida.Count) lineas"
