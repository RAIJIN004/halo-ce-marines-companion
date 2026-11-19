param([int]$X = 640, [int]$Y = 400)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class C4 {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool at);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint fl, int dx, int dy, uint data, UIntPtr ex);
  public static void LeftDown(){ mouse_event(0x0002,0,0,0,UIntPtr.Zero); }
  public static void LeftUp(){ mouse_event(0x0004,0,0,0,UIntPtr.Zero); }
}
"@
$p = Get-Process halo -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Output 'halo no corre'; exit 1 }
$h = $p.MainWindowHandle
$fg = [C4]::GetForegroundWindow()
$tFg = [C4]::GetWindowThreadProcessId($fg, [ref]$null)
$tMe = [C4]::GetCurrentThreadId()
[void][C4]::AttachThreadInput($tMe, $tFg, $true)
[void][C4]::ShowWindow($h, 9)
[void][C4]::BringWindowToTop($h)
[void][C4]::SetForegroundWindow($h)
[void][C4]::AttachThreadInput($tMe, $tFg, $false)
Start-Sleep -Milliseconds 500
[void][C4]::SetCursorPos($X, $Y)
Start-Sleep -Milliseconds 250
[C4]::LeftDown(); Start-Sleep -Milliseconds 90; [C4]::LeftUp()
Write-Output "clic en $X,$Y"
