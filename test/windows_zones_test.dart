// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Uses dart:ffi (the Windows time zone API) and processes.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:time_machine2/src/platforms/windows_time_zone.dart';
import 'package:universal_io/io.dart' as io;

import 'time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  test('WindowsMappingIsEmbedded', WindowsMappingIsEmbedded);
  test('WindowsStandardNamesThatDifferFromTheId',
      WindowsStandardNamesThatDifferFromTheId);
  test('LocalZoneMatchesSystemOffset', LocalZoneMatchesSystemOffset);
  test('WindowsTimeZoneIdIsReadViaWin32', WindowsTimeZoneIdIsReadViaWin32);
  test(
      'WindowsLocalZoneIsMappedFromZoneId', WindowsLocalZoneIsMappedFromZoneId);
  test('AllWindowsRegistryZonesAreMapped', AllWindowsRegistryZonesAreMapped);
  test('WindowsDisplayNamesAreLocalizedWhenExpected',
      WindowsDisplayNamesAreLocalizedWhenExpected);
}

TzdbDateTimeZoneSource get source => TzdbDateTimeZoneSource.defaultSource;

// Windows-specific tests: the embedded CLDR mapping and local zone detection.
// The ported Noda Time tests are in tzdb_datetimezone_source_test.dart and
// cldr_windows_zones_test.dart.

void WindowsMappingIsEmbedded() {
  expect(source.windowsMapping.mapZones, isNotEmpty);
  expect(source.windowsMapping.windowsVersion, isNotEmpty);
  expect(
      source.windowsToTzdbIds['AUS Eastern Standard Time'], 'Australia/Sydney');
  expect(source.windowsToTzdbIds['W. Europe Standard Time'], 'Europe/Berlin');
}

void WindowsStandardNamesThatDifferFromTheId() {
  expect(source.windowsStandardNameToTzdbId('Coordinated Universal Time'),
      'Etc/UTC');
  expect(source.windowsStandardNameToTzdbId('Malay Peninsula Standard Time'),
      'Asia/Singapore');
  expect(source.windowsStandardNameToTzdbId('Not A Zone'), isNull);
}

// ---------------------------------------------------------------------------
// Local zone detection.
// ---------------------------------------------------------------------------

void LocalZoneMatchesSystemOffset() {
  // Whatever zone is detected, it must agree with the system's current offset.
  var now = DateTime.now();
  var offset = DateTimeZone.local.getUtcOffset(Instant.dateTime(now));
  expect(offset.inSeconds, now.timeZoneOffset.inSeconds);
}

Future<String?> _registryValue(String key, String name) async {
  var result = await io.Process.run('reg', ['query', key, '/v', name],
      stdoutEncoding: utf8);
  if (result.exitCode != 0) return null;
  var match = RegExp('^\\s+$name\\s+REG_\\w+\\s+(.*)\$', multiLine: true)
      .firstMatch(result.stdout as String);
  return match?.group(1)?.trim();
}

const _timeZoneInformationKey =
    r'HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation';

Future WindowsTimeZoneIdIsReadViaWin32() async {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;
  var expected =
      await _registryValue(_timeZoneInformationKey, 'TimeZoneKeyName');
  var info = readWindowsTimeZoneInfo();
  expect(info, isNotNull);
  expect(info!.keyName, expected);

  // The standard offset is -(Bias + StandardBias) minutes; the registry
  // stores them as (possibly negative) DWORDs.
  int dword(String? value) =>
      int.parse(value!.substring(2), radix: 16).toSigned(32);
  var bias = dword(await _registryValue(_timeZoneInformationKey, 'Bias'));
  var standardBias =
      dword(await _registryValue(_timeZoneInformationKey, 'StandardBias'));
  expect(info.standardOffsetSeconds, -(bias + standardBias) * 60);
}

/// The local zone comes from the Windows zone ID, which is the same in every
/// display language, so this holds on non-English Windows too.
Future WindowsLocalZoneIsMappedFromZoneId() async {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;
  var keyName =
      await _registryValue(_timeZoneInformationKey, 'TimeZoneKeyName');
  var dstDisabled = await _registryValue(
      _timeZoneInformationKey, 'DynamicDaylightTimeDisabled');
  if (skipUnless(dstDisabled != '0x1',
      'Automatic DST adjustment is off: detection deliberately guesses')) {
    return;
  }

  // As Noda Time does, the CLDR primary mapping as written (e.g. Asia/Calcutta).
  var expected = source.windowsMapping.primaryMapping[keyName];
  if (expected == null) {
    // Unmapped legacy zone (see below): detection falls back to guessing.
    expect(_knownUnmappedWindowsIds, contains(keyName));
    return;
  }
  expect(DateTimeZone.local.id, expected,
      reason: 'Windows zone "$keyName", '
          'display name "${DateTime.now().timeZoneName}"');
}

/// Legacy Windows zones that CLDR deliberately doesn't map (Noda Time has the
/// same gap). Detection falls back to guessing by transitions for these.
const _knownUnmappedWindowsIds = {
  'Kamchatka Standard Time',
  'Mid-Atlantic Standard Time',
};

/// Equivalent of Noda Time's NameIdMappingSupport test: every zone in the
/// Windows registry must be mappable from its ID, and from its English
/// standard name (used when the ID can't be read).
Future AllWindowsRegistryZonesAreMapped() async {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;

  var result = await io.Process.run(
      'reg',
      [
        'query',
        r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones',
        '/s',
        '/v',
        'Std',
      ],
      stdoutEncoding: utf8);
  expect(result.exitCode, 0, reason: '${result.stderr}');

  var unmapped = <String>[];
  String? windowsId;
  for (var line in LineSplitter.split(result.stdout as String)) {
    if (line.startsWith('HKEY_')) {
      windowsId = line.substring(line.lastIndexOf(r'\') + 1).trim();
      continue;
    }
    var match = RegExp(r'^\s+Std\s+REG_SZ\s+(.*)$').firstMatch(line);
    if (match == null || windowsId == null) continue;
    if (_knownUnmappedWindowsIds.contains(windowsId)) continue;
    var standardName = match.group(1)!.trim();

    if (source.windowsToTzdbIds[windowsId] == null) {
      unmapped.add('ID "$windowsId"');
    }
    if ((source.windowsStandardNameToTzdbId(standardName) ??
            source.windowsToTzdbIds[standardName]) ==
        null) {
      unmapped.add('standard name "$standardName" (ID "$windowsId")');
    }
  }
  expect(unmapped, isEmpty,
      reason: 'Add missing standard names to '
          'tool/tzdb_compiler/tzdb/named_id_mapping_support.dart, '
          'or add a newer CLDR windowsZones file, then rerun the TZDB compiler');
}

/// Guards the non-English Windows CI leg: with
/// TIME_MACHINE_EXPECT_LOCALIZED_WINDOWS=1, the display names Dart reports
/// must not be the English ones, otherwise that leg isn't testing anything.
Future WindowsDisplayNamesAreLocalizedWhenExpected() async {
  if (skipUnless(
      io.Platform.isWindows &&
          io.Platform.environment['TIME_MACHINE_EXPECT_LOCALIZED_WINDOWS'] ==
              '1',
      'Only on Windows with TIME_MACHINE_EXPECT_LOCALIZED_WINDOWS=1 '
      '(the localized Windows CI leg)')) {
    return;
  }
  var keyName =
      await _registryValue(_timeZoneInformationKey, 'TimeZoneKeyName');
  var zoneKey =
      r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\' +
          keyName!;
  var englishNames = {
    await _registryValue(zoneKey, 'Std'),
    await _registryValue(zoneKey, 'Dlt'),
  };
  var year = DateTime.now().year;
  var reported = {
    DateTime(year, 1, 1).timeZoneName,
    DateTime(year, 7, 1).timeZoneName,
  };
  expect(reported.intersection(englishNames), isEmpty,
      reason: 'Dart reports $reported for Windows zone "$keyName"');
}
