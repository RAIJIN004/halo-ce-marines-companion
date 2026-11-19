$ErrorActionPreference = 'Stop'
$f = 'C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\data\levels\a10\scripts\extracted.hsc'
$b = 'C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\bloque-mod.txt'
$t = Get-Content $f -Raw
$i = $t.IndexOf('; ============================================================')
if ($i -lt 0) { throw 'no encuentro el marcador del bloque' }
$t = $t.Substring(0, $i).TrimEnd()
$bloque = Get-Content $b -Raw
Set-Content -Path $f -Value ($t + "`r`n`r`n" + $bloque) -Encoding ASCII -NoNewline
Write-Output "hsc lineas=$((Get-Content $f | Measure-Object).Count)"
Write-Output "gancho de la cinematica:"
Select-String -Path $f -Pattern 'wake mod_marines_boot' | ForEach-Object { "{0,5}: {1}" -f $_.LineNumber, $_.Line.Trim() }
Write-Output "referencias a escuadrones sp_:"
Write-Output ("  ai_place sp_*: {0}" -f (Select-String -Path $f -Pattern 'ai_place mod_marines/sp_').Count)
Write-Output ("  ai_place mod_marines suelto (peligroso): {0}" -f (Select-String -Path $f -Pattern '\(ai_place mod_marines\)$').Count)
