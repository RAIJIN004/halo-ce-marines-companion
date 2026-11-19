# Un solo pase sobre cada fichero: se calculan TODOS los anchors sobre el
# array original y se construye la salida de una vez (no hay desplazamiento
# de índices entre operaciones).
# Quita: (1) el viejo mod_marines_migrar (sin llamar) y (2) el cuerpo de
# mod_marines_spawn (sustituido por mod_marines_aqui). Se dejan comentarios.
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$fixtures = @(
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\bloque-mod.txt",
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\data\levels\a10\scripts\extracted.hsc"
)

foreach ($ruta in $fixtures) {
  $l = [System.IO.File]::ReadAllLines($ruta)
  $antes = $l.Count

  $startMigrar = -1; $startScan = -1
  $startSpawn = -1;  $startTeclas = -1
  for ($i = 0; $i -lt $l.Count; $i++) {
    if ($startMigrar -lt 0 -and $l[$i] -match '^\(script static void mod_marines_migrar\b') { $startMigrar = $i }
    if ($startScan  -lt 0 -and $l[$i] -match '^\(script static void mod_marines_scan\b')  { $startScan  = $i }
    if ($startSpawn -lt 0 -and $l[$i] -match '^\(script static void mod_marines_spawn\b')  { $startSpawn = $i }
    if ($startTeclas-lt 0 -and $l[$i] -match '^; --- teclas\b')                            { $startTeclas= $i }
  }

  $salida = New-Object System.Collections.Generic.List[string]
  $i = 0
  while ($i -lt $l.Count) {
    if ($i -eq $startMigrar -and $startScan -gt $startMigrar) {
      # reemplaza todo el bloque mod_marines_migrar (hasta justo antes de scan) por comentarios
      $salida.Add("; (ai_migrate) por sala: DEPRECADO. Se usaba para mover los actores al escuadron")
      $salida.Add("; vacio de la letra de la sala. Reemplazado por mod_marines_migrar_sala (misma")
      $salida.Add("; tabla de letras, sin duplicar codigo). Este bloque se conserva como referencia")
      $salida.Add("; local de documentacion, no se compila.")
      $salida.Add("")
      $i = $startScan
      continue
    }
    if ($i -eq $startSpawn -and $startTeclas -gt $startSpawn) {
      $salida.Add("; mod_marines_spawn: DESACTIVADO.")
      $salida.Add(";   Ya no se usa: F6 crea marines con mod_marines_aqui (objeto_create_anew")
      $salida.Add(";   + attach/detach al jugador + ai_attach), que los sitúa en tus pies")
      $salida.Add(";   en cualquier sala. El cuerpo de ai_place por sala se conserva como")
      $salida.Add(";   referencia historica pero no compila (ahorra nodos de script).")
      $salida.Add("")
      $i = $startTeclas
      continue
    }
    $salida.Add($l[$i])
    $i++
  }

  [System.IO.File]::WriteAllLines($ruta, [string[]]$salida, $enc)
  "  $ruta : $antes -> $($salida.Count) lineas  (migrar=$startMigrar scan=$startScan spawn=$startSpawn teclas=$startTeclas)"
}
