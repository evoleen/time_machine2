// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:ffi';

/// Maps an IANA time zone ID to a Windows zone ID with Windows' own ICU
/// (`icu.dll`, part of Windows since Windows 10 version 1703), as .NET's
/// `TimeZoneInfo` does on Windows. Uses `ucal_getWindowsTimeZoneID`.
///
/// Returns null if ICU isn't available or has no mapping for [ianaId].
String? ianaToWindowsIdWithIcu(String ianaId) {
  try {
    var icu = DynamicLibrary.open('icu.dll');
    var getWindowsTimeZoneId = icu.lookupFunction<
        Int32 Function(
            Pointer<Uint16>, Int32, Pointer<Uint16>, Int32, Pointer<Int32>),
        int Function(Pointer<Uint16>, int, Pointer<Uint16>, int,
            Pointer<Int32>)>('ucal_getWindowsTimeZoneID');
    var kernel32 = DynamicLibrary.open('kernel32.dll');
    var localAlloc = kernel32.lookupFunction<Pointer Function(Uint32, IntPtr),
        Pointer Function(int, int)>('LocalAlloc');
    var localFree = kernel32.lookupFunction<Pointer Function(Pointer),
        Pointer Function(Pointer)>('LocalFree');

    const lptr = 0x0040; // LMEM_FIXED | LMEM_ZEROINIT
    const capacity = 128;
    var units = ianaId.codeUnits;
    var id = localAlloc(lptr, (units.length + 1) * 2).cast<Uint16>();
    var windowsId = localAlloc(lptr, capacity * 2).cast<Uint16>();
    var status = localAlloc(lptr, 4).cast<Int32>();
    if (id.address == 0 || windowsId.address == 0 || status.address == 0) {
      return null;
    }
    try {
      for (var i = 0; i < units.length; i++) {
        id[i] = units[i];
      }
      var length =
          getWindowsTimeZoneId(id, units.length, windowsId, capacity, status);
      // UErrorCode: 0 is success, negative values are warnings.
      if (status.value > 0 || length <= 0 || length > capacity) return null;
      return String.fromCharCodes(
          [for (var i = 0; i < length; i++) windowsId[i]]);
    } finally {
      localFree(id);
      localFree(windowsId);
      localFree(status);
    }
  } catch (_) {
    return null;
  }
}
