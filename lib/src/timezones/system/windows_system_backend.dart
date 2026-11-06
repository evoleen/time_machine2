// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:ffi';

import 'package:time_machine2/src/platforms/windows_time_zone.dart';
import 'package:time_machine2/src/platforms/windows_tz_environment.dart';
import 'package:universal_io/io.dart' as io;
import 'package:time_machine2/src/time_machine_internal.dart';

import 'system_time_zone_backend.dart';
import 'windows_icu.dart';
import 'windows_rules.dart';

/// Windows: the Win32 dynamic time zone API (kernel32 and advapi32), which is
/// what .NET's `TimeZoneInfo` reads too.
///
/// * IDs are the registry key names from `EnumDynamicTimeZoneInformation`,
///   e.g. 'AUS Eastern Standard Time'.
/// * [loadZone] also accepts IANA IDs, as .NET's `FindSystemTimeZoneById`
///   does on Windows: it maps them to a Windows zone with Windows' own ICU
///   (so links such as 'Asia/Calcutta' work too) and returns that zone's
///   rules under the requested ID. [getIds] lists only Windows IDs.
/// * Zone interval names are the localized standard and daylight names.
/// * Each zone's rules come from `GetTimeZoneInformationForYear` for every
///   year in `GetDynamicTimeZoneInformationEffectiveYears` (or, for zones
///   without dynamic DST data, the zone's single rule for all time), and are
///   converted as Noda Time's `BclDateTimeZone` converts Windows adjustment
///   rules: see [buildWindowsZone].
///
/// The zones ignore the "Adjust for daylight saving time automatically"
/// setting, as .NET's `FindSystemTimeZoneById` does.
class WindowsSystemTimeZoneBackend implements SystemTimeZoneBackend {
  _Win32? _api;
  bool _apiLoaded = false;
  Map<String, int>? _indexById;

  _Win32? get _win32 {
    if (!_apiLoaded) {
      _apiLoaded = true;
      try {
        _api = _Win32();
      } catch (_) {
        _api = null;
      }
    }
    return _api;
  }

  Map<String, int> get _zones {
    var zones = _indexById;
    if (zones != null) return zones;
    zones = <String, int>{};
    var api = _win32;
    if (api != null) {
      api.withDtzi((dtzi) {
        for (var index = 0;; index++) {
          var result = api.enumDynamicTimeZoneInformation(index, dtzi);
          if (result != _errorSuccess) break; // ERROR_NO_MORE_ITEMS or failure
          var id = _readWideString(dtzi.ref.timeZoneKeyName, 128);
          if (id.isNotEmpty) zones![id] = index;
        }
      });
    }
    return _indexById = zones;
  }

  @override
  String get description => 'Windows';

  @override
  bool get isSupported => _zones.isNotEmpty;

  @override
  String? get dataVersion => _win32?.readTzVersion();

  @override
  List<String> getIds() => _zones.keys.toList()..sort();

  @override
  DateTimeZone? loadZone(String id) {
    var windowsId = _zones.containsKey(id) ? id : ianaToWindowsIdWithIcu(id);
    var index = windowsId == null ? null : _zones[windowsId];
    var api = _win32;
    if (index == null || api == null) return null;
    return api.withDtzi((dtzi) {
      if (api.enumDynamicTimeZoneInformation(index, dtzi) != _errorSuccess ||
          _readWideString(dtzi.ref.timeZoneKeyName, 128) != windowsId) {
        return null;
      }
      return _buildZone(api, id, dtzi);
    });
  }

  /// The zone named by the `TZ` environment variable, if any, as for
  /// `DateTimeZone.local` (following Python's tzlocal and Node.js): a Windows
  /// zone ID, or an IANA ID mapped to a Windows zone with Windows' own ICU.
  /// Otherwise the system's zone (`TimeZoneKeyName`).
  @override
  String? get systemDefaultId {
    var fromTz = zoneIdFromTz(io.Platform.environment['TZ']);
    if (fromTz != null) return fromTz;
    var keyName = readWindowsTimeZoneInfo()?.keyName;
    return keyName != null && _zones.containsKey(keyName) ? keyName : null;
  }

  /// The Windows zone ID that [tz] (a `TZ` value) names, or null.
  String? zoneIdFromTz(String? tz) {
    for (var candidate in windowsTzEnvironmentCandidates(tz)) {
      if (_zones.containsKey(candidate)) return candidate;
      var windowsId = ianaToWindowsIdWithIcu(candidate);
      if (windowsId != null && _zones.containsKey(windowsId)) return windowsId;
    }
    return null;
  }

  static DateTimeZone _buildZone(
      _Win32 api, String id, Pointer<_DynamicTimeZoneInformation> dtzi) {
    var info = dtzi.ref;
    var standardName = _readWideString(info.standardName, 32);
    var daylightName = _readWideString(info.daylightName, 32);
    var zoneRule = WindowsZoneRule(
        bias: info.bias,
        standardBias: info.standardBias,
        daylightBias: info.daylightBias,
        standardDate: _transitionDate(info.standardDate),
        daylightDate: _transitionDate(info.daylightDate));

    var rules = <WindowsYearRule>[];
    var years = api.effectiveYears(dtzi);
    if (years != null) {
      var rulesByYear = <WindowsZoneRule>[];
      for (var year = years.first; year <= years.last; year++) {
        var rule = api.timeZoneInformationForYear(year, dtzi);
        if (rule == null) {
          rulesByYear.clear();
          break;
        }
        rulesByYear.add(rule);
      }
      rules = coalesceWindowsYearRules(years.first, rulesByYear);
    }
    if (rules.isEmpty) {
      // No dynamic DST data: the zone's own rule applies to all time.
      rules = [WindowsYearRule(1, 9999, zoneRule)];
    }
    return buildWindowsZone(id, standardName, daylightName, rules);
  }
}

/// Uses the operating system (`SystemTimeToTzSpecificLocalTimeEx`) to find
/// the UTC offset in seconds of the Windows zone [id] at each of
/// [epochMilliseconds]. For testing the backend against the OS itself.
///
/// Returns null if the zone isn't found or the call fails. Instants must be
/// in the range SYSTEMTIME can represent (1601 onwards).
@visibleForTesting
List<int>? windowsSystemOffsets(String id, List<int> epochMilliseconds) {
  _Win32 api;
  try {
    api = _Win32();
  } catch (_) {
    return null;
  }
  return api.withDtzi((dtzi) {
    var found = false;
    for (var index = 0;; index++) {
      if (api.enumDynamicTimeZoneInformation(index, dtzi) != _errorSuccess) {
        break;
      }
      if (_readWideString(dtzi.ref.timeZoneKeyName, 128) == id) {
        found = true;
        break;
      }
    }
    if (!found) return null;
    var utc = api.alloc(2 * sizeOf<_SystemTime>()).cast<_SystemTime>();
    var local = utc + 1;
    try {
      var result = <int>[];
      for (var ms in epochMilliseconds) {
        _writeSystemTime(utc.ref, ms);
        if (api.systemTimeToTzSpecificLocalTimeEx(dtzi, utc, local) == 0) {
          return null;
        }
        result.add((_readSystemTime(local.ref) - ms) ~/ 1000);
      }
      return result;
    } finally {
      api.free(utc);
    }
  });
}

/// The SYSTEMTIME of the time zone [id]'s rule for [year], as reported by
/// `GetTimeZoneInformationForYear`, for diagnostics and tests.
@visibleForTesting
WindowsZoneRule? windowsRuleForYear(String id, int year) {
  var api = _Win32();
  return api.withDtzi((dtzi) {
    for (var index = 0;; index++) {
      if (api.enumDynamicTimeZoneInformation(index, dtzi) != _errorSuccess) {
        return null;
      }
      if (_readWideString(dtzi.ref.timeZoneKeyName, 128) == id) {
        return api.timeZoneInformationForYear(year, dtzi);
      }
    }
  });
}

// ---------------------------------------------------------------------------
// Win32 interop. No package:ffi: memory comes from LocalAlloc/LocalFree.
// ---------------------------------------------------------------------------

const int _errorSuccess = 0;
const int _lptr = 0x0040; // LMEM_FIXED | LMEM_ZEROINIT
const int _hkeyLocalMachine = -0x7FFFFFFE; // (HKEY) (LONG) 0x80000002
const int _rrfRtAny = 0x0000FFFF;
const int _regSz = 1;
const int _regDword = 4;

final class _SystemTime extends Struct {
  @Uint16()
  external int wYear;
  @Uint16()
  external int wMonth;
  @Uint16()
  external int wDayOfWeek;
  @Uint16()
  external int wDay;
  @Uint16()
  external int wHour;
  @Uint16()
  external int wMinute;
  @Uint16()
  external int wSecond;
  @Uint16()
  external int wMilliseconds;
}

final class _TimeZoneInformation extends Struct {
  @Int32()
  external int bias;
  @Array(32)
  external Array<Uint16> standardName;
  external _SystemTime standardDate;
  @Int32()
  external int standardBias;
  @Array(32)
  external Array<Uint16> daylightName;
  external _SystemTime daylightDate;
  @Int32()
  external int daylightBias;
}

final class _DynamicTimeZoneInformation extends Struct {
  @Int32()
  external int bias;
  @Array(32)
  external Array<Uint16> standardName;
  external _SystemTime standardDate;
  @Int32()
  external int standardBias;
  @Array(32)
  external Array<Uint16> daylightName;
  external _SystemTime daylightDate;
  @Int32()
  external int daylightBias;
  @Array(128)
  external Array<Uint16> timeZoneKeyName;
  @Uint8()
  external int dynamicDaylightTimeDisabled;
}

String _readWideString(Array<Uint16> chars, int length) {
  var codeUnits = <int>[];
  for (var i = 0; i < length && chars[i] != 0; i++) {
    codeUnits.add(chars[i]);
  }
  return String.fromCharCodes(codeUnits);
}

WindowsTransitionDate _transitionDate(_SystemTime time) =>
    WindowsTransitionDate(
        year: time.wYear,
        month: time.wMonth,
        dayOfWeek: time.wDayOfWeek,
        day: time.wDay,
        hour: time.wHour,
        minute: time.wMinute,
        second: time.wSecond,
        milliseconds: time.wMilliseconds);

void _writeSystemTime(_SystemTime time, int epochMilliseconds) {
  var dateTime =
      DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: true);
  time
    ..wYear = dateTime.year
    ..wMonth = dateTime.month
    ..wDayOfWeek = dateTime.weekday % 7
    ..wDay = dateTime.day
    ..wHour = dateTime.hour
    ..wMinute = dateTime.minute
    ..wSecond = dateTime.second
    ..wMilliseconds = dateTime.millisecond;
}

int _readSystemTime(_SystemTime time) => DateTime.utc(time.wYear, time.wMonth,
        time.wDay, time.wHour, time.wMinute, time.wSecond, time.wMilliseconds)
    .millisecondsSinceEpoch;

class _Win32 {
  final Pointer Function(int, int) _localAlloc;
  final Pointer Function(Pointer) _localFree;
  final int Function(int, Pointer<_DynamicTimeZoneInformation>)
      _enumDynamicTimeZoneInformation;
  final int Function(Pointer<_DynamicTimeZoneInformation>, Pointer<Uint32>,
      Pointer<Uint32>) _getDynamicTimeZoneInformationEffectiveYears;
  final int Function(int, Pointer<_DynamicTimeZoneInformation>,
      Pointer<_TimeZoneInformation>) _getTimeZoneInformationForYear;
  final int Function(Pointer<_DynamicTimeZoneInformation>, Pointer<_SystemTime>,
      Pointer<_SystemTime>) _systemTimeToTzSpecificLocalTimeEx;
  final int Function(int, Pointer<Uint16>, Pointer<Uint16>, int,
      Pointer<Uint32>, Pointer, Pointer<Uint32>) _regGetValue;

  factory _Win32() {
    var kernel32 = DynamicLibrary.open('kernel32.dll');
    var advapi32 = DynamicLibrary.open('advapi32.dll');
    return _Win32._(
      kernel32.lookupFunction<Pointer Function(Uint32, IntPtr),
          Pointer Function(int, int)>('LocalAlloc'),
      kernel32.lookupFunction<Pointer Function(Pointer),
          Pointer Function(Pointer)>('LocalFree'),
      advapi32.lookupFunction<
          Uint32 Function(Uint32, Pointer<_DynamicTimeZoneInformation>),
          int Function(int, Pointer<_DynamicTimeZoneInformation>)>(
        'EnumDynamicTimeZoneInformation',
      ),
      advapi32.lookupFunction<
          Uint32 Function(Pointer<_DynamicTimeZoneInformation>, Pointer<Uint32>,
              Pointer<Uint32>),
          int Function(Pointer<_DynamicTimeZoneInformation>, Pointer<Uint32>,
              Pointer<Uint32>)>(
        'GetDynamicTimeZoneInformationEffectiveYears',
      ),
      kernel32.lookupFunction<
          Int32 Function(Uint16, Pointer<_DynamicTimeZoneInformation>,
              Pointer<_TimeZoneInformation>),
          int Function(int, Pointer<_DynamicTimeZoneInformation>,
              Pointer<_TimeZoneInformation>)>(
        'GetTimeZoneInformationForYear',
      ),
      kernel32.lookupFunction<
          Int32 Function(Pointer<_DynamicTimeZoneInformation>,
              Pointer<_SystemTime>, Pointer<_SystemTime>),
          int Function(Pointer<_DynamicTimeZoneInformation>,
              Pointer<_SystemTime>, Pointer<_SystemTime>)>(
        'SystemTimeToTzSpecificLocalTimeEx',
      ),
      advapi32.lookupFunction<
          Int32 Function(IntPtr, Pointer<Uint16>, Pointer<Uint16>, Uint32,
              Pointer<Uint32>, Pointer, Pointer<Uint32>),
          int Function(int, Pointer<Uint16>, Pointer<Uint16>, int,
              Pointer<Uint32>, Pointer, Pointer<Uint32>)>('RegGetValueW'),
    );
  }

  _Win32._(
      this._localAlloc,
      this._localFree,
      this._enumDynamicTimeZoneInformation,
      this._getDynamicTimeZoneInformationEffectiveYears,
      this._getTimeZoneInformationForYear,
      this._systemTimeToTzSpecificLocalTimeEx,
      this._regGetValue);

  Pointer alloc(int size) {
    var pointer = _localAlloc(_lptr, size);
    if (pointer.address == 0) throw StateError('LocalAlloc failed');
    return pointer;
  }

  void free(Pointer pointer) => _localFree(pointer);

  T withDtzi<T>(T Function(Pointer<_DynamicTimeZoneInformation> dtzi) action) {
    var dtzi = alloc(sizeOf<_DynamicTimeZoneInformation>())
        .cast<_DynamicTimeZoneInformation>();
    try {
      return action(dtzi);
    } finally {
      free(dtzi);
    }
  }

  int enumDynamicTimeZoneInformation(
          int index, Pointer<_DynamicTimeZoneInformation> dtzi) =>
      _enumDynamicTimeZoneInformation(index, dtzi);

  int systemTimeToTzSpecificLocalTimeEx(
          Pointer<_DynamicTimeZoneInformation> dtzi,
          Pointer<_SystemTime> utc,
          Pointer<_SystemTime> local) =>
      _systemTimeToTzSpecificLocalTimeEx(dtzi, utc, local);

  /// The first and last years with dynamic DST data, or null if the zone has
  /// none.
  ({int first, int last})? effectiveYears(
      Pointer<_DynamicTimeZoneInformation> dtzi) {
    var years = alloc(2 * sizeOf<Uint32>()).cast<Uint32>();
    try {
      if (_getDynamicTimeZoneInformationEffectiveYears(
              dtzi, years, years + 1) !=
          _errorSuccess) {
        return null;
      }
      var first = years[0];
      var last = years[1];
      if (first == 0 || last < first || last > 9999) return null;
      return (first: first, last: last);
    } finally {
      free(years);
    }
  }

  WindowsZoneRule? timeZoneInformationForYear(
      int year, Pointer<_DynamicTimeZoneInformation> dtzi) {
    var tzi =
        alloc(sizeOf<_TimeZoneInformation>()).cast<_TimeZoneInformation>();
    try {
      if (_getTimeZoneInformationForYear(year, dtzi, tzi) == 0) return null;
      var info = tzi.ref;
      return WindowsZoneRule(
          bias: info.bias,
          standardBias: info.standardBias,
          daylightBias: info.daylightBias,
          standardDate: _transitionDate(info.standardDate),
          daylightDate: _transitionDate(info.daylightDate));
    } finally {
      free(tzi);
    }
  }

  /// HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\TzVersion:
  /// a REG_DWORD on current Windows versions, reported in hex.
  String? readTzVersion() {
    const subKey = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones';
    const valueName = 'TzVersion';
    const bufferSize = 512;
    const stringsSize = (subKey.length + 1 + valueName.length + 1) * 2;
    // Two DWORDs (type and size), the data, and slack for alignment.
    var memory = alloc(stringsSize + 8 + bufferSize + 8);
    try {
      var subKeyPointer = memory.cast<Uint16>();
      var valueNamePointer = subKeyPointer + subKey.length + 1;
      _writeWideString(subKeyPointer, subKey);
      _writeWideString(valueNamePointer, valueName);
      var typePointer =
          Pointer<Uint32>.fromAddress((memory.address + stringsSize + 7) & ~7);
      var sizePointer = typePointer + 1;
      var data = sizePointer + 1;
      sizePointer.value = bufferSize;
      var status = _regGetValue(_hkeyLocalMachine, subKeyPointer,
          valueNamePointer, _rrfRtAny, typePointer, data, sizePointer);
      if (status != _errorSuccess) return null;
      switch (typePointer.value) {
        case _regDword:
          return '0x${data.value.toRadixString(16).padLeft(8, '0')}';
        case _regSz:
          var chars = data.cast<Uint16>();
          var codeUnits = <int>[];
          for (var i = 0; i < sizePointer.value ~/ 2 && chars[i] != 0; i++) {
            codeUnits.add(chars[i]);
          }
          return String.fromCharCodes(codeUnits);
        default:
          return null;
      }
    } catch (_) {
      return null;
    } finally {
      free(memory);
    }
  }
}

void _writeWideString(Pointer<Uint16> destination, String value) {
  for (var i = 0; i < value.length; i++) {
    destination[i] = value.codeUnitAt(i);
  }
  destination[value.length] = 0;
}
