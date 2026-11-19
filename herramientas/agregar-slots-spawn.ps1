# Agrega "ranuras" de aparicion para el mod: un biped NO colocado por
# escenario + un nombre de objeto ("mod_m01"..) por cada marine que F6
# pueda crear en la posicion del jugador.
#
# POR QUE HACE FALTA
#   HaloScript no puede crear un objeto en una posicion arbitraria: la
#   unica orden que fabrica un objeto es (object_create_anew <nombre>) y
#   el nombre tiene que existir en el escenario, apuntando (por el campo
#   "name" del placement) a un biped del bloque "bipeds".
#   Como "anew" BORRA el objeto anterior con ese nombre, cada pulsacion
#   de F6 necesita una ranura propia: nunca pisa a los marines que ya
#   tienes.
#
# QUE ESCRIBE
#   1) N copias de bipeds[0] (marine_armored) al final de "bipeds" con
#        type   = 1               (marines\marine_armored)
#        name   = indice nuevo en object_names
#        not_placed.automatically = 1   (no aparece al empezar el nivel)
#        position/rotation = un punto valido del suelo de la bahia
#        flags.dead = 0           (si estuviera "dead" no se puede atar
#                                  un actor: actor_create_for_unit lo
#                                  rechaza)
#   2) N nombres nuevos "mod_m01.." en "object_names".
#      OJO: invader-edit marca "object_names" como read-only, asi que esa
#      parte se hace con insercion de bytes a mano: los tags de Halo 1 no
#      tienen punteros, las tablas son contiguas y el contador del bloque
#      esta en +0x244 (big-endian). Entrada = 36 bytes (32 de nombre + 4
#      de relleno, siempre 0). Base de la tabla en +0x1064.
#      La base se autodetecta con la cadena cortana_x20/keyes/chief.
#   3) Vuelve a fijar runtime_structure_bsp_reference_index de mod_marines
#      = -1 (invader-edit reescribe el tag entero y ese campo no lo
#      modela: ver fijar-runtime-bsp.ps1).
param(
  [string]$Tags = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\tags",
  [int]$Cuenta = 24,
  [string]$Prefijo = "mod_m",
  [int]$Tipo = 1,
  [string]$Posicion = "-55.430302,0.799534,0.000998",
  [int]$Donante = 0,
  [switch]$SoloVer
)

$ErrorActionPreference = "Stop"
$ie      = "C:\Users\jhonv\Downloads\Halo-Editor\invader-edit.exe"
$tagPath = Join-Path $Tags "levels\a10\a10.scenario"
$rel     = "levels\a10\a10.scenario"
$herr    = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas"

if (!(Test-Path $tagPath)) { throw "No existe $tagPath" }

$nBipeds = [int](& $ie -t $Tags -C "bipeds" $rel)
$nNombres = [int](& $ie -t $Tags -C "object_names" $rel)
"antes: bipeds=$nBipeds  object_names=$nNombres"

# ---------------------------------------------------------------- nombres
$b = [System.IO.File]::ReadAllBytes($tagPath)

# base de la tabla object_names: cortana_x20 (335) / keyes (336) / chief (337), paso 36
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)
$paso = 36
$o335 = -1
$pos = 0
while (($pos = $s.IndexOf("cortana_x20`0", $pos)) -ge 0) {
  if ($pos + 2 * $paso + 6 -lt $b.Length) {
    $a = [System.Text.Encoding]::ASCII.GetString($b, $pos + $paso, 6)
    $c = [System.Text.Encoding]::ASCII.GetString($b, $pos + 2 * $paso, 6)
    if ($a.StartsWith("keyes") -and $c.StartsWith("chief")) { $o335 = $pos; break }
  }
  $pos++
}
if ($o335 -lt 0) { throw "no pude localizar la tabla object_names (cadena de nombres esperada)" }
$base = $o335 - 335 * $paso

# contador del bloque en +0x244 (big-endian) - comprobar que dice lo mismo
$cuentaTag = ([int]$b[0x244] -shl 24) -bor ([int]$b[0x245] -shl 16) -bor ([int]$b[0x246] -shl 8) -bor [int]$b[0x247]
"tabla object_names: base=0x{0:X}  paso={1}  contador_en_tag={2}  contador_invader={3}" -f $base, $paso, $cuentaTag, $nNombres
if ($cuentaTag -ne $nNombres) { throw "el contador del tag ($cuentaTag) no coincide con invader ($nNombres): no toco nada" }

$ultimo = ([System.Text.Encoding]::ASCII.GetString($b, $base + ($nNombres - 1) * $paso, 32)).Split([char]0)[0]
"ultimo nombre actual: $ultimo"

$yaHay = $false
for ($i = 0; $i -lt $Cuenta; $i++) {
  $nombre = "{0}{1:D2}" -f $Prefijo, ($i + 1)
  $desde = $base
  $largo = $nNombres * $paso
  $bloque = [System.Text.Encoding]::ASCII.GetString($b, $desde, $largo)
  if ($bloque.Contains($nombre + "`0")) { $yaHay = $true }
}
if ($yaHay) { "las ranuras ya existen: no hago nada"; exit 0 }

if ($SoloVer) { "solo ver: no escribo"; exit 0 }

# ------------------------------------------------------------- placements
Copy-Item $tagPath "$tagPath.bak4" -Force
"copia de seguridad: $tagPath.bak4"

for ($i = 0; $i -lt $Cuenta; $i++) {
  & $ie -t $Tags -c "bipeds[$Donante]" end $rel 2>&1 | Out-Null
}
for ($i = 0; $i -lt $Cuenta; $i++) {
  $k = $nBipeds + $i
  $nombreIdx = $nNombres + $i
  & $ie -t $Tags -S "bipeds[$k].type" $Tipo $rel 2>&1 | Out-Null
  & $ie -t $Tags -S "bipeds[$k].name" $nombreIdx $rel 2>&1 | Out-Null
  & $ie -t $Tags -S "bipeds[$k].not_placed.automatically" 1 $rel 2>&1 | Out-Null
  & $ie -t $Tags -S "bipeds[$k].position" $Posicion $rel 2>&1 | Out-Null
  & $ie -t $Tags -S "bipeds[$k].rotation" "0,0,0" $rel 2>&1 | Out-Null
  & $ie -t $Tags -S "bipeds[$k].flags.dead" 0 $rel 2>&1 | Out-Null
  & $ie -t $Tags -S "bipeds[$k].body_vitality_modifier" 0 $rel 2>&1 | Out-Null
  "  bipeds[$k] -> {0}{1:D2}" -f $Prefijo, ($i + 1)
}

# --------------------------------------------------------- nombres (bytes)
$b = [System.IO.File]::ReadAllBytes($tagPath)
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)
$o335 = -1
$pos = 0
while (($pos = $s.IndexOf("cortana_x20`0", $pos)) -ge 0) {
  if ($pos + 2 * $paso + 6 -lt $b.Length) {
    $a = [System.Text.Encoding]::ASCII.GetString($b, $pos + $paso, 6)
    $c = [System.Text.Encoding]::ASCII.GetString($b, $pos + 2 * $paso, 6)
    if ($a.StartsWith("keyes") -and $c.StartsWith("chief")) { $o335 = $pos; break }
  }
  $pos++
}
if ($o335 -lt 0) { throw "no pude localizar la tabla object_names tras la edicion" }
$base = $o335 - 335 * $paso
$nNombres = [int](& $ie -t $Tags -C "object_names" $rel)

$nuevo = New-Object byte[] ($b.Length + $Cuenta * $paso)
$finTabla = $base + $nNombres * $paso
[Array]::Copy($b, 0, $nuevo, 0, $finTabla)
for ($i = 0; $i -lt $Cuenta; $i++) {
  $nombre = "{0}{1:D2}" -f $Prefijo, ($i + 1)
  $bytes = [System.Text.Encoding]::ASCII.GetBytes($nombre)
  $dest = $finTabla + $i * $paso
  [Array]::Copy($bytes, 0, $nuevo, $dest, $bytes.Length)   # resto ya son ceros
}
[Array]::Copy($b, $finTabla, $nuevo, $finTabla + $Cuenta * $paso, $b.Length - $finTabla)

$nuevoCuenta = $nNombres + $Cuenta
$nuevo[0x244] = ($nuevoCuenta -shr 24) -band 0xFF
$nuevo[0x245] = ($nuevoCuenta -shr 16) -band 0xFF
$nuevo[0x246] = ($nuevoCuenta -shr 8) -band 0xFF
$nuevo[0x247] = $nuevoCuenta -band 0xFF
[System.IO.File]::WriteAllBytes($tagPath, $nuevo)
"insertados $Cuenta nombres en object_names (base 0x{0:X}, fin 0x{1:X}); contador {2} -> {3}" -f $base, $finTabla, $nNombres, $nuevoCuenta

# ------------------------------------------------------------- verificar
$nBipeds2  = [int](& $ie -t $Tags -C "bipeds" $rel)
$nNombres2 = [int](& $ie -t $Tags -C "object_names" $rel)
"despues: bipeds=$nBipeds2  object_names=$nNombres2"
foreach ($i in 0, ($Cuenta - 1)) {
  $k = $nBipeds + $i
  $n = "{0}{1:D2}" -f $Prefijo, ($i + 1)
  "  bipeds[$k].name = " + (& $ie -t $Tags -G "bipeds[$k].name" $rel) + "   object_names[" + ($nNombres + $i) + "].name = " + (& $ie -t $Tags -G "object_names[$($nNombres + $i)].name" $rel)
}

# --------------------------------------------------- runtime del encuentro
& powershell -ExecutionPolicy Bypass -File (Join-Path $herr "fijar-runtime-bsp.ps1") -Tag $tagPath -Runtime -1
