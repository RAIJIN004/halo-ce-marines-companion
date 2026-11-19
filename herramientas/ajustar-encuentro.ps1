$ErrorActionPreference = 'Stop'
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
$ed = 'C:\Users\jhonv\Downloads\Halo-Editor'
$sc = 'levels\a10\a10.scenario'
$t  = "$ed\Proyectos\a10\tags"

function Set1([string]$k, [string]$v) {
    $o = & "$ed\invader-edit.exe" -S $k $v $sc -t $t 2>&1
    if ($LASTEXITCODE -ne 0) { throw "fallo al poner $k = $v`n$o" }
}
function Get1([string]$k) { ((& "$ed\invader-edit.exe" -G $k $sc -t $t 2>&1 | Out-String).Trim()) }

# ---------------------------------------------------------------
# 1) escuadrones VACIOS (adv_b..adv_r, indices 1..17)
#    retail containment_3 les pone actor_type = 3 (escuadron vacio
#    pero con tipo de actor). Solo cambia eso.
# ---------------------------------------------------------------
Write-Output "=== 1) actor_type=3 en los escuadrones vacios ==="
foreach ($i in 1..17) {
    Set1 "encounters[39].squads[$i].actor_type" '3'
}
foreach ($i in 1, 9, 17) {
    Write-Output ("  squads[{0,2}] {1,-6} actor_type={2}" -f $i, (Get1 "encounters[39].squads[$i].name"), (Get1 "encounters[39].squads[$i].actor_type"))
}

# ---------------------------------------------------------------
# 2) pursuing = z en TODOS los escuadrones
#    El escuadron retail init_marine y los 6 vacios de
#    containment_3 llevan pursuing.z; es la marca estandar de
#    "sin persecucion propia" en un encuentro que sigue al jugador.
# ---------------------------------------------------------------
Write-Output "=== 2) pursuing.z=1 en los 52 escuadrones ==="
foreach ($i in 0..51) { Set1 "encounters[39].squads[$i].pursuing.z" '1' }
foreach ($i in 0, 1, 51) {
    Write-Output ("  squads[{0,2}] pursuing.z={1}" -f $i, (Get1 "encounters[39].squads[$i].pursuing.z"))
}

# ---------------------------------------------------------------
# 3) variantes de humano en los 6 escuadrones libres
#    Paleta del escenario (actor_palette):
#      1 = crewman security pistol   6 = crewman engineer
#     11 = crewman command           7 = crewman science
#     12 = crewman pilot             2 = marine_armored assault rifle
#    Los sp_o/p/q/r no los usa la F6 (zonas 15..17 ya no existen),
#    asi que se usan solo para la prueba de tipos (tecla F9).
# ---------------------------------------------------------------
Write-Output "=== 3) variantes distintas en los escuadrones libres ==="
$variantes = @(
    @{ idx = 46; tipo = '1';  que = 'crewman security pistol' },
    @{ idx = 47; tipo = '6';  que = 'crewman engineer' },
    @{ idx = 48; tipo = '11'; que = 'crewman command' },
    @{ idx = 49; tipo = '7';  que = 'crewman science' },
    @{ idx = 50; tipo = '12'; que = 'crewman pilot' },
    @{ idx = 51; tipo = '2';  que = 'marine_armored assault rifle' }
)
foreach ($v in $variantes) {
    Set1 "encounters[39].squads[$($v.idx)].actor_type" $v.tipo
    Write-Output ("  squads[{0,2}] {1,-7} -> actor_type={2,-3} {3}" -f $v.idx, (Get1 "encounters[39].squads[$($v.idx)].name"), $v.tipo, $v.que)
}

Write-Output "=== comprobacion final de los escuadrones de la F6 ==="
foreach ($i in 18, 19, 44, 45) {
    Write-Output ("  squads[{0,2}] {1,-8} actor_type={2}" -f $i, (Get1 "encounters[39].squads[$i].name"), (Get1 "encounters[39].squads[$i].actor_type"))
}
Write-Output "LISTO"
