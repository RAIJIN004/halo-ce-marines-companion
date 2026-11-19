# Aplica el mod F6/F7/F8 a una mision de campana.
# Uso: aplicar-mod-mision.ps1 -Map a30
param([Parameter(Mandatory=$true)][string]$Map)
$ErrorActionPreference = "Continue"   # los warnings de invader van a stderr
$root = "C:\Users\jhonv\Downloads\Halo-Editor"
$env:Path = "$root;$env:Path"
$maps = "C:\Users\jhonv\Downloads\Halo-PC\MAPS"
$proj = "$root\Proyectos\$Map"
$rel  = "levels\$Map\$Map.scenario"
$tag  = "$proj\tags\$rel"
$hsc  = "$proj\data\levels\$Map\scripts\extracted.hsc"
$ie   = "$root\invader-edit.exe"
$nombres = @('mod_m01','mod_m02','mod_m03','mod_m04','mod_m05','mod_m06',
             'mod_m07','mod_m08','mod_m09','mod_m10','mod_m11','mod_m12',
             'mod_m13','mod_m14','mod_m15','mod_m16','mod_m17','mod_m18',
             'mod_m19','mod_m20','mod_m21','mod_m22','mod_m23','mod_m24',
             'modlure','moddum01','moddum02','moddum03')

function IEdit([string[]]$parms){
  & $ie -t "$proj\tags" @parms $rel 2>&1 | ForEach-Object { "$_".Trim() }
}
function Count([string]$field){ [int](IEdit @('-C',$field)) }

"===== $Map ====="

# --- 1) extraer tags ------------------------------------------------
New-Item -ItemType Directory -Force -Path "$proj\tags","$proj\data\levels\$Map\scripts","$proj\maps" | Out-Null
if (!(Test-Path $tag)) {
  "extrayendo tags de $Map.map ..."
  & invader-extract -n -t "$proj\tags" -r "$maps\$Map.map" 2>&1 | Select-Object -Last 1
}

# --- 1b) reparar tags compartidos con copias conocidas de a10 --------
$a10tags = "$root\Proyectos\a10\tags"
$copiados = 0
Get-ChildItem "$proj\tags" -Recurse -File | ForEach-Object {
  $rel2 = $_.FullName.Substring("$proj\tags\".Length)
  if ($rel2 -match '^globals\\') { return }   # globals es propio de cada mision
  $src = Join-Path $a10tags $rel2
  if (Test-Path $src) {
    if ((Get-FileHash $_.FullName -Algorithm MD5).Hash -ne (Get-FileHash $src -Algorithm MD5).Hash) {
      Copy-Item $src $_.FullName -Force
      $copiados++
    }
  }
}
"tags compartidos reparados: $copiados"

# --- 2) extraer HSC original ----------------------------------------
powershell -ExecutionPolicy Bypass -File "$root\Proyectos\a10\herramientas\extraer-hsc-generico.ps1" -Tag $tag -Salida $hsc | Out-Null
"HSC original extraido: $((Get-Content $hsc).Count) lineas"

# --- 3) object_names: insertar 28 nombres ----------------------------
$n0 = Count 'object_names'
$b = [System.IO.File]::ReadAllBytes($tag)
$s = [System.Text.Encoding]::GetEncoding(28591).GetString($b)
$ultimo = [string](IEdit @('-G',"object_names[$($n0-1)].name"))
$primero = [string](IEdit @('-G','object_names[0].name'))
$pos = $s.IndexOf($ultimo)
$base = -1
while ($pos -ge 0) {
  $cand = $pos - ($n0-1)*36
  if ($cand -ge 0 -and $cand + $n0*36 -le $b.Length) {
    $n0txt = [System.Text.Encoding]::ASCII.GetString($b,$cand,32).Split([char]0)[0]
    if ($n0txt -eq $primero) { $base = $cand; break }
  }
  $pos = $s.IndexOf($ultimo, $pos+1)
}
if ($base -lt 0) { throw "no encontre la tabla object_names en $Map" }
$indices = @{}
for($k=0;$k -lt $nombres.Count;$k++){ $indices[$nombres[$k]] = $n0 + $k }
$fin = $base + $n0*36
$nuevo = New-Object byte[] ($b.Length + $nombres.Count*36)
[Array]::Copy($b,0,$nuevo,0,$fin)
for($k=0;$k -lt $nombres.Count;$k++){
  $nb = [System.Text.Encoding]::ASCII.GetBytes($nombres[$k])
  [Array]::Copy($nb,0,$nuevo,$fin+$k*36,$nb.Length)
}
[Array]::Copy($b,$fin,$nuevo,$fin+$nombres.Count*36,$b.Length-$fin)
$cnt = $n0 + $nombres.Count
$nuevo[0x244] = ($cnt -shr 24) -band 0xFF
$nuevo[0x245] = ($cnt -shr 16) -band 0xFF
$nuevo[0x246] = ($cnt -shr 8) -band 0xFF
$nuevo[0x247] = $cnt -band 0xFF
[System.IO.File]::WriteAllBytes($tag,$nuevo)
"object_names: $n0 -> $cnt (base 0x{0:X})" -f $base

# --- 4) copiar warthog silencioso ------------------------------------
$dst = "$proj\tags\vehicles\warthog\warthog_silent.vehicle"
New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
Copy-Item "$root\Proyectos\a10\tags\vehicles\warthog\warthog_silent.vehicle" $dst -Force

# --- 5) bipeds: 24 ranuras + 3 dummies -------------------------------
$nb0 = Count 'bipeds'
$marineIdx = -1
$npal = Count 'biped_palette'
for($i=0;$i -lt $npal;$i++){
  $nm = [string](IEdit @('-G',"biped_palette[$i].name"))
  if ($nm -match 'marine_armored\\marine_armored\.biped$') { $marineIdx = $i; break }
}
if ($marineIdx -lt 0) { $marineIdx = 0 }
$template = -1
for($i=0;$i -lt $nb0;$i++){
  $t = [int][string](IEdit @('-G',"bipeds[$i].type"))
  if ($t -eq $marineIdx) { $template = $i; break }
}
if ($template -lt 0) { $template = 0 }
"biped template=$template marineIdx=$marineIdx"
for($k=0;$k -lt 27;$k++){
  $idx = $nb0 + $k
  $name = if($k -lt 24){ 'mod_m{0:D2}' -f ($k+1) } else { 'moddum{0:D2}' -f ($k-23) }
  IEdit @('-c',"bipeds[$template]",'end') | Out-Null
  IEdit @('-S',"bipeds[$idx].name",([string]$indices[$name])) | Out-Null
  IEdit @('-S',"bipeds[$idx].type",([string]$marineIdx)) | Out-Null
  IEdit @('-S',"bipeds[$idx].not_placed.automatically",'1') | Out-Null
}
"bipeds: $nb0 -> $(Count 'bipeds')"

# --- 6) vehiculo senuelo ---------------------------------------------
$nvp0 = Count 'vehicle_palette'
$wog = -1
for($i=0;$i -lt $nvp0;$i++){
  $nm=[string](IEdit @('-G',"vehicle_palette[$i].name"))
  if($nm -match 'warthog\\warthog\.vehicle$'){ $wog=$i; break }
}
if($wog -lt 0){ $wog = 0 }
IEdit @('-c',"vehicle_palette[$wog]",'end') | Out-Null
$newPal = $nvp0
IEdit @('-S',"vehicle_palette[$newPal].name",'vehicles\warthog\warthog_silent.vehicle') | Out-Null
$nv0 = Count 'vehicles'
IEdit @('-c','vehicles[0]','end') | Out-Null
IEdit @('-S',"vehicles[$nv0].type",([string]$newPal)) | Out-Null
IEdit @('-S',"vehicles[$nv0].name",([string]$indices['modlure'])) | Out-Null
IEdit @('-S',"vehicles[$nv0].not_placed.automatically",'1') | Out-Null
IEdit @('-S',"vehicles[$nv0].position",'-55.430302,0.799534,0.000998') | Out-Null
IEdit @('-S',"vehicles[$nv0].rotation",'0,0,0') | Out-Null
"vehiculo: palette $newPal, placement $nv0"

# --- 7) encuentro mod_marines ----------------------------------------
$ne0 = Count 'encounters'
$marineEnc = 0
for($i=0;$i -lt $ne0;$i++){
  $enName = [string](IEdit @('-G',"encounters[$i].name"))
  if ($enName -match 'marine') { $marineEnc = $i; break }
}
$actorType = [int][string](IEdit @('-G',"encounters[$marineEnc].squads[0].actor_type"))
IEdit @('-c',"encounters[$marineEnc]",'end') | Out-Null
$ne = $ne0
IEdit @('-S',"encounters[$ne].name",'mod_marines') | Out-Null
IEdit @('-S',"encounters[$ne].squads[0].name",'marines') | Out-Null
IEdit @('-S',"encounters[$ne].squads[0].actor_type",([string]$actorType)) | Out-Null
$nsq = Count "encounters[$ne].squads"
for($i=0;$i -lt $nsq;$i++){ IEdit @('-S',"encounters[$ne].squads[$i].normal_diff_count",'0') | Out-Null }
IEdit @('-S',"encounters[$ne].squads[0].normal_diff_count",'3') | Out-Null
IEdit @('-S',"encounters[$ne].flags.manual_bsp_index_specified",'1') | Out-Null
IEdit @('-S',"encounters[$ne].manual_bsp_index",'65535') | Out-Null
"encuentro $ne='mod_marines' squads=$nsq actorType=$actorType"

# --- 8) anadir bloque HSC y compilar ---------------------------------
Remove-Item "$proj\data\levels\$Map\scripts\bloque.hsc" -ErrorAction SilentlyContinue
powershell -ExecutionPolicy Bypass -File "$root\Proyectos\a10\herramientas\generar-bloque-generico.ps1" -Salida "$proj\bloque.hsc" | Out-Null
$orig = [System.IO.File]::ReadAllText($hsc)
$bloque = [System.IO.File]::ReadAllText("$proj\bloque.hsc")
$finalTxt = $orig.TrimEnd() + "`r`n`r`n" + $bloque
# Algunos mapas tienen mensajes HUD que invader no puede resolver al
# recompilar desde fuente; se neutralizan esas lineas (no afectan al mod).
$lineasFinales = $finalTxt -split "`r?`n"
$lineasFinales = $lineasFinales | ForEach-Object {
  if ($_ -match '^\s*\(hud_set_(help_text|objective_text|timer_text)\s') { '; ' + $_ } else { $_ }
}
[System.IO.File]::WriteAllLines($hsc, [string[]]$lineasFinales, (New-Object System.Text.UTF8Encoding($false)))
"HSC final: $($lineasFinales.Count) lineas"
& invader-script -g gbx-retail -t "$proj\tags" -d "$proj\data" "levels\$Map\$Map" 2>&1 | Select-Object -Last 2

# --- 9) runtime, build, verificar ------------------------------------
powershell -ExecutionPolicy Bypass -File "$root\Proyectos\a10\herramientas\fijar-runtime-bsp.ps1" -Tag $tag -Runtime -1 | Select-Object -First 1
$oldEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$buildOut = & invader-build -g gbx-retail -t "$proj\tags" -o "$proj\maps\$Map.map" "levels\$Map\$Map" 2>&1
$ErrorActionPreference = $oldEap
$buildOut | Select-String -Pattern "CRC32 checksum|FATAL ERROR|Failed to compile the map"
$crc = & "$root\invader-crc.exe" "$proj\maps\$Map.map" 2>&1
"$Map CRC: $crc"
