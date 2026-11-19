$ErrorActionPreference = 'Stop'
$d = "$env:TEMP\dump-new.txt"
$lin = [System.IO.File]::ReadAllLines($d)
$pts = New-Object System.Collections.ArrayList
$encN = ''; $isPlayer = $false
for ($i = 0; $i -lt $lin.Length; $i++) {
    $l = $lin[$i]
    if ($l -match '──encounters\[(\d+)\]\s+struct') { $encN = $Matches[1]; continue }
    if ($l -match '──(platoons|command_lists|player_starting_locations|encounters)\[(\d+)\]\s+(array|struct)' ) {
        if ($Matches[1] -ne 'encounters') { $encN = '' }
        continue
    }
    if ($encN -eq '') { continue }
    if ($l -match '──starting_locations\[(\d+)\]\s+struct') { continue }
    if ($l -match '──position \(([-\d.]+),([-\d.]+),([-\d.]+)\)') {
        [void]$pts.Add([pscustomobject]@{ enc = [int]$encN; x = [double]$Matches[1]; y = [double]$Matches[2]; z = [double]$Matches[3] })
    }
}
Write-Output ("puntos de aparicion de IA en todo el nivel: {0}" -f $pts.Count)
$zona = $pts | Where-Object { $_.x -gt -62 -and $_.x -lt -44 -and $_.y -gt -18 -and $_.y -lt 16 }
Write-Output ("en la zona de la camara criogenica (x -62..-44, y -18..16): {0}" -f $zona.Count)
$zona | Group-Object enc | Sort-Object Name | ForEach-Object { "  encuentro $($_.Name): $($_.Count) puntos" }
Write-Output '--- muestra ---'
$zona | Select-Object -First 25 | ForEach-Object { "  enc=$($_.enc) ({0:N1},{1:N1},{2:N1})" -f $_.x,$_.y,$_.z }
