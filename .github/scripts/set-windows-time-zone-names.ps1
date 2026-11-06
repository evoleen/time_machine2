# Makes the current Windows time zone report localized display names, as it
# does on non-English Windows, while keeping its ID (the registry key name)
# and rules. GitHub has no non-English Windows runners, and language packs
# can't be installed on them.
#
# Uses SetDynamicTimeZoneInformation, which needs SeTimeZonePrivilege
# (runners run as an administrator).
param(
  [Parameter(Mandatory)][string]$Standard,
  [Parameter(Mandatory)][string]$Daylight
)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class TzSet {
  [StructLayout(LayoutKind.Sequential)] public struct SYSTEMTIME { public ushort a,b,c,d,e,f,g,h; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct DTZI {
    public int Bias;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string StandardName;
    public SYSTEMTIME StandardDate; public int StandardBias;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DaylightName;
    public SYSTEMTIME DaylightDate; public int DaylightBias;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string TimeZoneKeyName;
    [MarshalAs(UnmanagedType.U1)] public bool DynamicDaylightTimeDisabled;
  }
  [StructLayout(LayoutKind.Sequential)] public struct LUID { public uint Low; public int High; }
  [StructLayout(LayoutKind.Sequential)] public struct TOKEN_PRIVILEGES { public uint Count; public LUID Luid; public uint Attr; }
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] public static extern uint GetDynamicTimeZoneInformation(out DTZI i);
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern bool SetDynamicTimeZoneInformation(ref DTZI i);
  [DllImport("advapi32.dll", SetLastError = true)] public static extern bool OpenProcessToken(IntPtr p, uint access, out IntPtr token);
  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern bool LookupPrivilegeValue(string sys, string name, out LUID luid);
  [DllImport("advapi32.dll", SetLastError = true)] public static extern bool AdjustTokenPrivileges(IntPtr t, bool disableAll, ref TOKEN_PRIVILEGES p, uint len, IntPtr prev, IntPtr retLen);
  [DllImport("kernel32.dll")] public static extern IntPtr GetCurrentProcess();
  public static string Set(string std, string dlt) {
    IntPtr token; OpenProcessToken(GetCurrentProcess(), 0x28, out token);
    var tp = new TOKEN_PRIVILEGES { Count = 1, Attr = 2 };
    LookupPrivilegeValue(null, "SeTimeZonePrivilege", out tp.Luid);
    AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    DTZI i; GetDynamicTimeZoneInformation(out i);
    i.StandardName = std; i.DaylightName = dlt;
    bool ok = SetDynamicTimeZoneInformation(ref i);
    return ok ? "ok" : ("failed " + Marshal.GetLastWin32Error());
  }
}
'@
$result = [TzSet]::Set($Standard, $Daylight)
if ($result -ne 'ok') { throw "SetDynamicTimeZoneInformation $result" }

$info = New-Object TzSet+DTZI
[void][TzSet]::GetDynamicTimeZoneInformation([ref]$info)
"Time zone $($info.TimeZoneKeyName): '$($info.StandardName)' / '$($info.DaylightName)'"
if ($info.StandardName -ne $Standard) { throw 'The display names were not applied' }
