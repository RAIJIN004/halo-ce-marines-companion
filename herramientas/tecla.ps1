param(
  [string]$Key = 'enter',
  [int]$Ms = 90,
  [string]$Name = 'shot',
  [switch]$Shot,
  [int]$TurnPx = 0
)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SD {
  [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT {
      public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo;
  }
  [StructLayout(LayoutKind.Sequential)] public struct INPUT {
      public uint type; public KEYBDINPUT ki; public long pad;
  }
  [DllImport("user32.dll", SetLastError=true)] public static extern uint SendInput(uint n, INPUT[] p, int cb);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool at);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern void mouse_event(uint fl, int dx, int dy, uint data, UIntPtr ex);
  public static uint KeyScan(ushort scan, bool up) {
      INPUT[] a = new INPUT[1];
      a[0].type = 1;
      a[0].ki.wVk = 0;
      a[0].ki.wScan = scan;
      a[0].ki.dwFlags = (up ? 0x0002u : 0u) | 0x0008u;
      a[0].ki.time = 0;
      a[0].ki.dwExtraInfo = IntPtr.Zero;
      return SendInput(1, a, Marshal.SizeOf(typeof(INPUT)));
  }
  public static void Move(int dx,int dy){ mouse_event(0x0001,dx,dy,0,UIntPtr.Zero); }
}
"@
$p = Get-Process halo -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Output 'halo no corre'; exit 1 }
$h = $p.MainWindowHandle
$fg = [SD]::GetForegroundWindow()
$tFg = [SD]::GetWindowThreadProcessId($fg, [ref]$null)
$tMe = [SD]::GetCurrentThreadId()
[void][SD]::AttachThreadInput($tMe, $tFg, $true)
[void][SD]::ShowWindow($h, 9)
[void][SD]::BringWindowToTop($h)
[void][SD]::SetForegroundWindow($h)
[void][SD]::AttachThreadInput($tMe, $tFg, $false)
Start-Sleep -Milliseconds 600

$sc = @{ 'escape'=0x01; 'w'=0x11; 'e'=0x12; 'r'=0x13; 'q'=0x10; 'a'=0x1E; 's'=0x1F; 'd'=0x20;
         'space'=0x39; 'enter'=0x1C; 'tab'=0x0F; 'tilde'=0x29;
         'f1'=0x3B;'f2'=0x3C;'f3'=0x3D;'f4'=0x3E;'f5'=0x3F;'f6'=0x40;'f7'=0x41;'f8'=0x42;
         'f9'=0x43;'f10'=0x44;'f11'=0x57;'f12'=0x58;
         'up'=0x48;'down'=0x50;'left'=0x4B;'right'=0x4D }

if ($TurnPx -ne 0) {
  $step = if ($TurnPx -gt 0) { 15 } else { -15 }
  $n = [Math]::Abs($TurnPx) / 15
  for ($i = 0; $i -lt $n; $i++) { [SD]::Move($step, 0); Start-Sleep -Milliseconds 20 }
  Start-Sleep -Milliseconds 200
}

if ($Key -ne '') {
  $s = $sc[$Key.ToLower()]
  if ($null -eq $s) { Write-Output "tecla desconocida: $Key" }
  else {
    [void][SD]::KeyScan([uint16]$s, $false)
    Start-Sleep -Milliseconds $Ms
    [void][SD]::KeyScan([uint16]$s, $true)
    Write-Output ("tecla {0} enviada" -f $Key)
  }
  Start-Sleep -Milliseconds 800
}

if ($Shot) {
  $b = [System.Windows.Forms.SystemInformation]::VirtualScreen
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
  $out = "C:\Users\jhonv\Downloads\Halo-Editor\Proyectos\a10\herramientas\$Name.png"
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Output "shot -> $out"
}
