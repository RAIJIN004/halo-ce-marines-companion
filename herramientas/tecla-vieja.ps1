param(
  [string]$Key = 'f6',
  [int]$Ms = 90,
  [int]$TurnPx = 0,
  [string]$Name = 'k1',
  [switch]$Shot
)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class K2 {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool at);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint fl, UIntPtr ex);
  [DllImport("user32.dll")] public static extern void mouse_event(uint fl, int dx, int dy, uint data, UIntPtr ex);
  public static void Down(byte v){ keybd_event(v,0,0,UIntPtr.Zero); }
  public static void Up(byte v){ keybd_event(v,0,2,UIntPtr.Zero); }
  public static void Move(int dx,int dy){ mouse_event(0x0001,dx,dy,0,UIntPtr.Zero); }
}
"@
$p = Get-Process halo -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Output 'halo no corre'; exit 1 }
$h = $p.MainWindowHandle
$fg = [K2]::GetForegroundWindow()
$tFg = [K2]::GetWindowThreadProcessId($fg, [ref]$null)
$tMe = [K2]::GetCurrentThreadId()
[void][K2]::AttachThreadInput($tMe, $tFg, $true)
[void][K2]::ShowWindow($h, 9)
[void][K2]::BringWindowToTop($h)
[void][K2]::SetForegroundWindow($h)
[void][K2]::AttachThreadInput($tMe, $tFg, $false)
Start-Sleep -Milliseconds 600
$fg2 = [K2]::GetForegroundWindow()
if ($fg2 -ne $h) { Write-Output "AVISO: foco en $fg2, no en $h" }

if ($TurnPx -ne 0) {
  $step = if ($TurnPx -gt 0) { 15 } else { -15 }
  $n = [Math]::Abs($TurnPx) / 15
  for ($i = 0; $i -lt $n; $i++) { [K2]::Move($step, 0); Start-Sleep -Milliseconds 20 }
  Start-Sleep -Milliseconds 200
}

$vkmap = @{ 'w'=0x57;'a'=0x41;'s'=0x53;'d'=0x44;'e'=0x45;'q'=0x51;'r'=0x52;'space'=0x20;
            'f1'=0x70;'f2'=0x71;'f3'=0x72;'f4'=0x73;'f5'=0x74;'f6'=0x75;'f7'=0x76;'f8'=0x77;
            'f9'=0x78;'f10'=0x79;'f11'=0x7A;'f12'=0x7B;
            'escape'=0x1B;'enter'=0x0D;'tab'=0x09;'tilde'=0xC0 }
if ($Key -ne '') {
  $vk = $vkmap[$Key.ToLower()]
  if ($null -eq $vk) { Write-Output "tecla desconocida: $Key" }
  else {
    [K2]::Down([byte]$vk); Start-Sleep -Milliseconds $Ms; [K2]::Up([byte]$vk)
    Write-Output "tecla $Key enviada (foco ok=$($fg2 -eq $h))"
  }
  Start-Sleep -Milliseconds 600
}

if ($Shot) {
  $b = [System.Windows.Forms.SystemInformation]::VirtualScreen
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
  $out = Join-Path 'C:\Users\jhonv\AppData\Local\Temp\opencode\halo' "$Name.png"
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Output "shot -> $out"
}
