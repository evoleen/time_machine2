// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:ffi';

/// The Windows system time zone, as reported by `GetDynamicTimeZoneInformation`.
class WindowsTimeZoneInfo {
  /// The Windows time zone ID (e.g. 'AUS Eastern Standard Time'). This is the
  /// registry key name, so unlike the display names it's the same in every
  /// display language. It's what .NET uses for `TimeZoneInfo.Local.Id`.
  final String keyName;

  /// The standard name in the current display language.
  final String standardName;

  /// Whether "Adjust for daylight saving time automatically" is turned off, in
  /// which case the system ignores the zone's daylight saving rules.
  final bool dynamicDaylightTimeDisabled;

  /// The zone's current standard UTC offset in seconds (-(Bias + StandardBias)
  /// minutes). With [dynamicDaylightTimeDisabled], this is the system's offset
  /// all year.
  final int standardOffsetSeconds;

  WindowsTimeZoneInfo(this.keyName, this.standardName,
      this.dynamicDaylightTimeDisabled, this.standardOffsetSeconds);

  @override
  String toString() => 'WindowsTimeZoneInfo(keyName: $keyName, '
      'standardName: $standardName, '
      'dynamicDaylightTimeDisabled: $dynamicDaylightTimeDisabled, '
      'standardOffsetSeconds: $standardOffsetSeconds)';
}

// DYNAMIC_TIME_ZONE_INFORMATION from timezoneapi.h. SYSTEMTIME is eight WORDs.
final class _DynamicTimeZoneInformation extends Struct {
  @Int32()
  external int bias;
  @Array(32)
  external Array<Uint16> standardName;
  @Array(8)
  external Array<Uint16> standardDate;
  @Int32()
  external int standardBias;
  @Array(32)
  external Array<Uint16> daylightName;
  @Array(8)
  external Array<Uint16> daylightDate;
  @Int32()
  external int daylightBias;
  @Array(128)
  external Array<Uint16> timeZoneKeyName;
  @Uint8()
  external int dynamicDaylightTimeDisabled;
}

const int _timeZoneIdInvalid = 0xFFFFFFFF;
const int _lptr = 0x0040; // LMEM_FIXED | LMEM_ZEROINIT

String _readWideString(Array<Uint16> chars, int length) {
  final codeUnits = <int>[];
  for (var i = 0; i < length && chars[i] != 0; i++) {
    codeUnits.add(chars[i]);
  }
  return String.fromCharCodes(codeUnits);
}

/// Reads the system time zone via `GetDynamicTimeZoneInformation`.
///
/// Returns null if it can't be read (not on Windows, or the call fails).
WindowsTimeZoneInfo? readWindowsTimeZoneInfo() {
  try {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final getDynamicTimeZoneInformation = kernel32.lookupFunction<
        Uint32 Function(Pointer<_DynamicTimeZoneInformation>),
        int Function(Pointer<_DynamicTimeZoneInformation>)>(
      'GetDynamicTimeZoneInformation',
    );
    final localAlloc = kernel32.lookupFunction<Pointer Function(Uint32, IntPtr),
        Pointer Function(int, int)>('LocalAlloc');
    final localFree = kernel32.lookupFunction<Pointer Function(Pointer),
        Pointer Function(Pointer)>('LocalFree');

    final info = localAlloc(_lptr, sizeOf<_DynamicTimeZoneInformation>())
        .cast<_DynamicTimeZoneInformation>();
    if (info.address == 0) return null;
    try {
      if (getDynamicTimeZoneInformation(info) == _timeZoneIdInvalid) {
        return null;
      }
      final keyName = _readWideString(info.ref.timeZoneKeyName, 128);
      if (keyName.isEmpty) return null;
      return WindowsTimeZoneInfo(
        keyName,
        _readWideString(info.ref.standardName, 32),
        info.ref.dynamicDaylightTimeDisabled != 0,
        -(info.ref.bias + info.ref.standardBias) * 60,
      );
    } finally {
      localFree(info);
    }
  } catch (_) {
    return null;
  }
}
