# Corrige dos detalles del parche de F6:
#  - un parentesis de cierre de mas en mod_marines_aqui
#  - el cuerpo del metodo antiguo (mod_marines_spawn) quedo vacio
$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)

$cuerpo = @'
(script static void mod_marines_spawn
  (if (= mod_marines_zone 1)  (begin (ai_place mod_marines/sp_b1) (ai_place mod_marines/sp_b2)))
  (if (= mod_marines_zone 2)  (begin (ai_place mod_marines/sp_c1) (ai_place mod_marines/sp_c2)))
  (if (= mod_marines_zone 3)  (begin (ai_place mod_marines/sp_d1) (ai_place mod_marines/sp_d2)))
  (if (= mod_marines_zone 4)  (begin (ai_place mod_marines/sp_e1) (ai_place mod_marines/sp_e2)))
  (if (= mod_marines_zone 5)  (begin (ai_place mod_marines/sp_f1) (ai_place mod_marines/sp_f2)))
  (if (= mod_marines_zone 6)  (begin (ai_place mod_marines/sp_g1) (ai_place mod_marines/sp_g2)))
  (if (= mod_marines_zone 7)  (begin (ai_place mod_marines/sp_h1) (ai_place mod_marines/sp_h2)))
  (if (= mod_marines_zone 8)  (begin (ai_place mod_marines/sp_i1) (ai_place mod_marines/sp_i2)))
  (if (= mod_marines_zone 9)  (begin (ai_place mod_marines/sp_j1) (ai_place mod_marines/sp_j2)))
  (if (= mod_marines_zone 10) (begin (ai_place mod_marines/sp_k1) (ai_place mod_marines/sp_k2)))
  (if (= mod_marines_zone 11) (begin (ai_place mod_marines/sp_l1) (ai_place mod_marines/sp_l2)))
  (if (= mod_marines_zone 12) (begin (ai_place mod_marines/sp_m1) (ai_place mod_marines/sp_m2)))
  (if (= mod_marines_zone 13) (begin (ai_place mod_marines/sp_n1) (ai_place mod_marines/sp_n2)))
  (if (= mod_marines_zone 14) (begin (ai_place mod_marines/sp_o1) (ai_place mod_marines/sp_o2)))
  (if (= mod_marines_zone 15) (begin (ai_place mod_marines/sp_p1) (ai_place mod_marines/sp_p2)))
  (if (= mod_marines_zone 16) (begin (ai_place mod_marines/sp_q1) (ai_place mod_marines/sp_q2)))
  (if (= mod_marines_zone 17) (begin (ai_place mod_marines/sp_r1) (ai_place mod_marines/sp_r2)))
)

; --- teclas
'@ -split "`r?`n"

foreach ($ruta in @(
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\bloque-mod.txt",
  "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\data\levels\a10\scripts\extracted.hsc")) {

  $t = [System.IO.File]::ReadAllText($ruta)

  # 1) parentesis de mas: "...))\n)\n)\n" -> "...))\n)\n"
  $antes = $t.Length
  $t = [regex]::Replace($t, "(?m)^    \)\)\r?\n\)\r?\n\)\r?\n", "    ))`r`n)`r`n")
  "  $ruta : parentesis corregido ($($antes - $t.Length) bytes menos)"

  # 2) cuerpo del metodo antiguo
  $pat = "(?s)\(script static void mod_marines_spawn\r?\n(\r?\n)*; --- teclas"
  if ($t -notmatch $pat) { throw "no encuentro el hueco de mod_marines_spawn en $ruta" }
  $t = [regex]::Replace($t, $pat, ($cuerpo -join "`r`n"))
  "    cuerpo de mod_marines_spawn restaurado"

  [System.IO.File]::WriteAllText($ruta, $t, $enc)
  "    guardado"
}
