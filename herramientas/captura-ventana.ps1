param([string]$Salida = "$PSScriptRoot\ventana.png")
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace W -Name U -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
$p = Get-Process halo -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { throw 'halo no corre' }
$h = $p.MainWindowHandle
if ($h -eq [IntPtr]::Zero) { throw 'sin ventana principal' }
$r = New-Object W.U+RECT
[void][W.U]::GetWindowRect($h, [ref]$r)
$w = $r.Right - $r.Left; $hgt = $r.Bottom - $r.Top
Write-Output "ventana $w x $hgt  pid=$($p.Id)"
$bmp = New-Object System.Drawing.Bitmap($w, $hgt)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
$ok = [W.U]::PrintWindow($h, $hdc, 2)
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($Salida, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "PrintWindow=$ok -> $Salida"
