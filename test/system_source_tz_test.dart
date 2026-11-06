// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// The TZ environment variable selects the same zone for DateTimeZone.local
// (TZDB) and for the system provider's default (the platform's own data).
//
// On Windows, TZ may name an IANA zone or a Windows zone: DateTimeZone.local
// maps Windows IDs with CLDR, and the system provider (whose IDs are Windows
// IDs) maps IANA IDs with Windows' own ICU. Empty or unrecognised values
// leave Windows' own zone. On Linux and macOS both follow .NET's rules.

// Uses dart:ffi (Windows ICU) and processes.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:time_machine2/src/platforms/windows_time_zone.dart';
import 'package:time_machine2/src/timezones/system/windows_icu.dart';
import 'package:universal_io/io.dart' as io;

import 'time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  test('Windows_IcuMapsIanaToWindowsIds', Windows_IcuMapsIanaToWindowsIds);
  test('Windows_TzSelectsTheSameZoneForBothProviders',
      Windows_TzSelectsTheSameZoneForBothProviders);
  test('Unix_TzSelectsTheSameZoneForBothProviders',
      Unix_TzSelectsTheSameZoneForBothProviders);
}

// The probe is compiled once, so each child process starts quickly.
Future<String>? _probe;

Future<String> _compileProbe() async {
  var dir = io.Directory.systemTemp.createTempSync('tm_system_probe_');
  var exe =
      '${dir.path}/print_system_default${io.Platform.isWindows ? '.exe' : ''}';
  var result = await io.Process.run(io.Platform.resolvedExecutable,
      ['compile', 'exe', 'test/support/print_system_default.dart', '-o', exe]);
  if (result.exitCode != 0) {
    throw StateError('Compiling the probe failed: ${result.stderr}');
  }
  return exe;
}

/// (DateTimeZone.local's ID, the system default's ID, 'match' or a difference)
/// in a child process with TZ set (or removed, for null).
Future<(String, String, String)> _withTz(String? tz) async {
  var exe = await (_probe ??= _compileProbe());
  var environment = Map.of(io.Platform.environment);
  environment.removeWhere((key, _) => key.toUpperCase() == 'TZ');
  if (tz != null) environment['TZ'] = tz;
  var result = await io.Process.run(exe, const [],
      environment: environment,
      includeParentEnvironment: false,
      stdoutEncoding: utf8);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  var parts =
      LineSplitter.split(result.stdout as String).last.trim().split('|');
  return (parts[0], parts[1], parts[2]);
}

Future<void> _expectZones(String? tz, String local, String system) async {
  var (actualLocal, actualSystem, match) = await _withTz(tz);
  expect(actualLocal, local, reason: 'DateTimeZone.local with TZ=$tz');
  expect(actualSystem, system, reason: 'system default with TZ=$tz');
  expect(match, 'match', reason: 'offsets with TZ=$tz');
}

void Windows_IcuMapsIanaToWindowsIds() {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;
  expect(ianaToWindowsIdWithIcu('Asia/Tokyo'), 'Tokyo Standard Time');
  expect(ianaToWindowsIdWithIcu('America/La_Paz'), 'SA Western Standard Time');
  expect(ianaToWindowsIdWithIcu('Asia/Calcutta'), 'India Standard Time');
  expect(ianaToWindowsIdWithIcu('Asia/Kolkata'), 'India Standard Time');
  expect(ianaToWindowsIdWithIcu('Not/AZone'), isNull);
  expect(ianaToWindowsIdWithIcu(''), isNull);
}

Future Windows_TzSelectsTheSameZoneForBothProviders() async {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;
  // IANA IDs, and Windows IDs (Windows only).
  await _expectZones('Asia/Tokyo', 'Asia/Tokyo', 'Tokyo Standard Time');
  await _expectZones(':Asia/Tokyo', 'Asia/Tokyo', 'Tokyo Standard Time');
  await _expectZones(
      'Tokyo Standard Time', 'Asia/Tokyo', 'Tokyo Standard Time');
  await _expectZones(
      'SA Western Standard Time', 'America/La_Paz', 'SA Western Standard Time');
  await _expectZones('Europe/London', 'Europe/London', 'GMT Standard Time');

  // Unset, empty and unrecognised values leave Windows' own zone for both:
  // the same zone, though not always the same offsets, as Windows' data can
  // differ from TZDB's (e.g. Morocco).
  var (local, system, _) = await _withTz(null);
  // With DST adjustment off, DateTimeZone.local is the fixed standard offset
  // the clock shows, but the system zone keeps its rules.
  if (!readWindowsTimeZoneInfo()!.dynamicDaylightTimeDisabled) {
    var mapped =
        TzdbDateTimeZoneSource.defaultSource.mapSystemTimeZoneId(system);
    // An unmapped Windows zone is guessed by transitions instead.
    if (mapped != null) expect(local, mapped, reason: 'zones without TZ');
  }
  for (var tz in ['', 'XST5XDT,M3.2.0,M11.1.0', 'Mars/Olympus_Mons']) {
    var (actualLocal, actualSystem, _) = await _withTz(tz);
    expect(actualLocal, local, reason: 'DateTimeZone.local with TZ=$tz');
    expect(actualSystem, system, reason: 'system default with TZ=$tz');
  }
}

Future Unix_TzSelectsTheSameZoneForBothProviders() async {
  if (skipUnless(!io.Platform.isWindows && !io.Platform.isAndroid,
      'Linux and macOS only')) {
    return;
  }
  // Both providers use IANA IDs here; the system provider needs the zone in
  // the OS's zoneinfo directory.
  if (skipUnless(io.File('/usr/share/zoneinfo/Asia/Tokyo').existsSync(),
      'No zoneinfo files (install tzdata)')) {
    return;
  }
  await _expectZones('Asia/Tokyo', 'Asia/Tokyo', 'Asia/Tokyo');
  await _expectZones(':Europe/London', 'Europe/London', 'Europe/London');
}
