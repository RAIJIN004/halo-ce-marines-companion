# Libera nodos de HaloScript (el motor de retail tiene un techo, y el
# mapa se paso con ~344 nodos de mas: 19345 > 19001).
# Quita el codigo MUERTO: mod_marines_migrar (antiguo, sin llamar) y el
# cuerpo de mod_marines_spawn (sustituido por mod_marines_aqui). Se dejan
# comentarios explicativos (no cuentan como nodos).
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$fixtures = @(
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\bloque-mod.txt",
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\data\levels\a10\scripts\extracted.hsc"
)

foreach ($ruta in $fixtures) {
  $l = [System.IO.File]::ReadAllLines($ruta)
  $antes = $l.Count

  $startMigrar = -1
  $startScan = -1
  for ($i = 0; $i -lt $l.Count; $i++) {
    if ($startMigrar -lt 0 -and $l[$i] -match '^\(script static void mod_marines_migrar\b') { $startMigrar = $i }
    if ($startScan -lt 0 -and $l[$i] -match '^\(script static void mod_marines_scan\b') { $startScan = $i }
    if ($startMigrar -ge 0 -and $startScan -ge 0) { break }
  }

  $startSpawn = -1
  $startTeclas = -1
  for ($i = 0; $i -lt $l.Count; $i++) {
    if ($startSpawn -lt 0 -and $l[$i] -match '^\(script static void mod_marines_spawn\b') { $startSpawn = $i }
    if ($startTeclas -lt 0 -and $l[$i] -match '^; --- teclas\b') { $startTeclas = $i }
    if ($startSpawn -ge 0 -and $startTeclas -ge 0) { break }
  }

  $salida = New-Object System.Collections.Generic.List[string]

  if ($startMigrar -ge 0 -and $startScan -ge 0 -and $startScan -gt $startMigrar) {
    $salida.AddRange([string[]]$l[0..$startMigrar])
    $salida.Add("")
    $salida.Add("; (ai_migrate) por sala: DEPRECADO.")
    $salida.Add(";   Se usaba para mover los actores al escuadron vacio de la letra de")
    $salida.Add(";   la sala. Reemplazado por mod_marines_migrar_sala (misma tabla de")
    $salida.Add(";   letras, sin duplicar codigo). No se borra del tag: se conserva")
    $salida.Add(";   esta referencia para que la documentacion siga siendo local.")
    $salida.Add("")
    $salida.AddRange([string[]]$l[$startScan..($l.Count - 1)])
    $l = [string[]]$salida
    "  $ruta : quitado mod_marines_migrar (antiguo) entre lineas $($startMigrar+1)-$($startScan+1)"
  } else {
    "  $ruta : no encontrado bloque mod_marines_migrar -> mod_marines_scan (startMigrar=$startMigrar startScan=$startScan)"
  }

  if ($startSpawn -ge 0 -and $startTeclas -ge 0 -and $startTeclas -gt $startSpawn) {
    $salida = New-Object System.Collections.Generic.List[string]
    $salida.AddRange([string[]]$l[0..$startSpawn])
    $salida.Add("")
    $salida.Add("; mod_marines_spawn: DESACTIVADO.")
    $salida.Add(";   Ya no se usa: F6 crea marines con mod_marines_aqui (objeto_create_anew")
    $salida.Add(";   + attach/detach al jugador + ai_attach), que los sitúa en tus pies")
    $salida.Add(";   en cualquier sala. El cuerpo de ai_place por sala se conserva como")
    $salida.Add(";   referencia historica pero no compila (ahorra nodos de script).")
    $salida.Add("")
    $salida.AddRange([string[]]$l[$startTeclas..($l.Count - 1)])
    $l = [string[]]$salida
    "  $ruta : cuerpo de mod_marines_spawn vaciado (lineas $($startSpawn+1)-$($startTeclas+1))"
  } else {
    "  $ruta : no encontrado hueco mod_marines_spawn -> teclas (startSpawn=$startSpawn startTeclas=$startTeclas)"
  }

  [System.IO.File]::WriteAllLines($ruta, [string[]]$l, $enc)
  "  guardado: $antes -> $($l.Count) lineas"
}
