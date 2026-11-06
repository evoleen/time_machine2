// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Port of Noda Time's NodaTime.Test/TimeZones/TzdbDateTimeZoneSourceTest.cs.
// Not ported: tests of .NET-only behaviour (BCL time zones, TimeZoneInfo
// replacement, loading 1.x resources), ForId_Null (null-safe in Dart),
// ForId_Unknown (this source falls back to UTC for unknown IDs; the provider
// throws instead) and the zone location tests (zone locations aren't loaded).
import 'dart:async';

import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:time_machine2/src/timezones/zone_guesser.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachineTest.initialize();
  await runTests();
}

TzdbDateTimeZoneSource get source => TzdbDateTimeZoneSource.defaultSource;

@Test()
Future ForId_AllIds() async {
  for (var id in await source.getIds()) {
    expect(await source.forId(id), isNotNull);
  }
}

@Test()
Future UtcEqualsBuiltIn() async {
  var zone = await source.forId('UTC');
  expect(zone.getUtcOffset(Instant.unixEpoch), Offset.zero);
  expect(zone.id, 'UTC');
}

// The following tests all make assumptions about the built-in TZDB data.
// This is simpler than constructing fake data, and validates that the creation
// mechanism matches the reading mechanism, too.
@Test()
void Aliases() {
  var aliases = source.aliases;
  expect(aliases['Europe/London'], [
    'Europe/Belfast',
    'Europe/Guernsey',
    'Europe/Isle_of_Man',
    'Europe/Jersey',
    'GB',
    'GB-Eire'
  ]);
  expect(aliases['Europe/London'],
      orderedEquals([...aliases['Europe/London']!]..sort()));
  expect(aliases['Europe/Jersey'] ?? const <String>[], isEmpty);
}

@Test()
void CanonicalIdMap_Contents() {
  var map = source.canonicalIdMap;
  expect(map['Europe/Jersey'], 'Europe/London');
  expect(map['Europe/London'], 'Europe/London');
}

@Test()
void CanonicalIdMap_IsReadOnly() {
  var map = source.canonicalIdMap;
  expect(() => map['Foo'] = 'Bar', throwsUnsupportedError);
}

@Test()
void TzdbVersion() {
  expect(source.tzdbVersion, startsWith('20'));
}

@Test()
Future FixedDateTimeZoneName() async {
  var zulu = await DateTimeZoneProviders.defaultProvider!['Etc/Zulu'];
  expect(zulu.getZoneInterval(Instant.unixEpoch).name, 'UTC');
}

@Test()
void VersionId() {
  expect(source.versionId, startsWith('TZDB: ${source.tzdbVersion}'));
}

@Test()
void ValidateDefault() => source.validate();

// By retrieving this once, we can massively speed up the guess test.
Future<List<DateTimeZone>> _canonicalZones() async {
  var provider = DateTimeZoneProviders.defaultProvider!;
  var ids = source.canonicalIdMap.values.toSet().toList()..sort();
  return [for (var id in ids) await provider[id]];
}

/// Noda Time runs this for every system time zone. Dart can't enumerate the
/// system's zones, so each Windows zone's TZDB zone stands in for the system
/// zone: the guess must agree with it on at least 74% of the days in this
/// year and next.
@Test()
Future GuessZoneIdByTransitionsUncached() async {
  var provider = DateTimeZoneProviders.defaultProvider!;
  var candidates = await _canonicalZones();
  var thisYear = DateTime.now().toUtc().year;
  var failures = <String>[];

  for (var tzdbId in source.windowsToTzdbIds.values.toSet()) {
    var systemZone = await provider[tzdbId];
    var id = guessZoneIdByTransitions(systemZone.getUtcOffset, candidates);
    if (id == null) {
      failures.add('Unable to guess time zone for $tzdbId');
      continue;
    }
    var tzdbZone = await provider[id];

    var total = 0, correct = 0;
    LocalDate? lastIncorrectDate;
    for (var date = LocalDate(thisYear, 1, 1);
        date.year < thisYear + 2;
        date = date.addDays(1)) {
      var startOfUtcDay = date.atMidnight().inUtc().toInstant();
      if (tzdbZone.getUtcOffset(startOfUtcDay) ==
          systemZone.getUtcOffset(startOfUtcDay)) {
        correct++;
      } else {
        lastIncorrectDate = date;
      }
      total++;
    }
    if (correct * 100.0 / total < 74.0) {
      failures
          .add('Last incorrect date for $tzdbId vs $id: $lastIncorrectDate');
    }
  }
  expect(failures, isEmpty);
}

/// Noda Time maps `TimeZoneInfo.Local.Id`; Time Machine maps the Windows zone
/// ID or the IANA ID read from the system in the same way.
@Test()
@TestCase(['Pacific Standard Time', 0, 'America/Los_Angeles'], 'Windows ID')
@TestCase(['America/Los_Angeles', 0, 'America/Los_Angeles'], 'TZDB ID')
// Both Pacific/Honolulu and Etc/GMT+10 match with the same score; we use
// Etc/GMT+10 as it comes first lexically.
@TestCase(['Lilo and Stitch', -10, 'Etc/GMT+10'], 'Guess by transitions')
Future MapTimeZoneInfoId(
    String timeZoneInfoId, int standardUtc, String expectedId) async {
  var mappedId = source.mapSystemTimeZoneId(timeZoneInfoId) ??
      guessZoneIdByTransitions(
          (_) => Offset.hours(standardUtc), await _canonicalZones());
  expect(mappedId, expectedId);
}

// Validation. In the sample data, zone3 is an alias for zone1.
const _sampleCanonicalIdMap = {
  'zone1': 'zone1',
  'zone2': 'zone2',
  'zone3': 'zone1',
};

void _assertInvalid(List<MapZone> mapZones,
    [Map<String, String> canonicalIdMap = _sampleCanonicalIdMap]) {
  expect(
      () => TzdbDateTimeZoneSource.validateData(
          canonicalIdMap,
          WindowsZones(
              'cldr-version', 'tzdb-version', 'windows-version', mapZones)),
      throwsA(isA<InvalidDateTimeZoneSourceError>()));
}

@Test()
void ValidSample() => TzdbDateTimeZoneSource.validateData(
    _sampleCanonicalIdMap,
    WindowsZones('cldr-version', 'tzdb-version', 'windows-version', [
      MapZone('windows-id', MapZone.primaryTerritory, ['zone1']),
      MapZone('windows-id', 'UK', ['zone1']),
    ]));

@Test()
void CanonicalIdMapValueIsNotAKey() =>
    _assertInvalid(const [], {..._sampleCanonicalIdMap, 'zone4': 'zone5'});

@Test()
void CanonicalIdMapValueIsNotCanonical() =>
    _assertInvalid(const [], {..._sampleCanonicalIdMap, 'zone4': 'zone3'});

@Test()
void WindowsMappingWithoutPrimaryTerritory() => _assertInvalid([
      MapZone('windows-id', 'nonprimary', ['zone1', 'zone2'])
    ]);

@Test()
void WindowsMappingPrimaryTerritoryNotInNonPrimary() => _assertInvalid([
      MapZone('windows-id', MapZone.primaryTerritory, ['zone1']),
      MapZone('windows-id', 'UK', ['zone2']),
    ]);

@Test()
void WindowsMappingUsesMissingId() => _assertInvalid([
      MapZone('windows-id', MapZone.primaryTerritory, ['zone4']),
      MapZone('windows-id', 'UK', ['zone4']),
    ]);

@Test()
void WindowsMappingContainsDuplicateTzdbIds_SameTerritory() => _assertInvalid([
      MapZone('windows-id', MapZone.primaryTerritory, ['zone1']),
      MapZone('windows-id', 'UK', ['zone1']),
      MapZone('windows-id', 'CA', ['zone2', 'zone2']),
    ]);

@Test()
void WindowsMappingContainsDuplicateTzdbIds_SameWindowsIdDifferentTerritory() =>
    _assertInvalid([
      MapZone('windows-id', MapZone.primaryTerritory, ['zone1']),
      MapZone('windows-id', 'UK', ['zone1']),
      MapZone('windows-id', 'CA', ['zone1']),
    ]);

@Test()
void WindowsMappingContainsDuplicateTzdbIds_DifferentTerritories() =>
    _assertInvalid([
      MapZone('windows-id1', MapZone.primaryTerritory, ['zone1']),
      MapZone('windows-id1', 'CA', ['zone1']),
      MapZone('windows-id2', MapZone.primaryTerritory, ['zone1']),
      MapZone('windows-id2', 'UK', ['zone1']),
    ]);

@Test()
void WindowsMappingContainsWindowsIdWithNoPrimaryTerritory() => _assertInvalid([
      MapZone('windows-id1', 'CA', ['zone1']),
    ]);

@Test()
void WindowsMappingContainsWindowsIdWithDuplicateTerritories() =>
    _assertInvalid([
      MapZone('windows-id1', MapZone.primaryTerritory, ['zone1']),
      MapZone('windows-id1', 'CA', ['zone2']),
      MapZone('windows-id1', 'CA', ['zone3']),
    ]);

/// Canonical IDs: zone1 to zone6. Aliases, linked to the obvious corresponding
/// IDs: link1, link2, link3a, link3b, link3c. Windows mappings:
/// win1: zone1 (primary, UK); win2: link2 (primary, UK); win3: link3a (primary, UK);
/// win4: zone4 (primary, UK), zone5 (FR), link3b (CA).
final _complexCanonicalIdMap = {
  for (var i = 1; i <= 6; i++) 'zone$i': 'zone$i',
  'link1': 'zone1',
  'link2': 'zone2',
  'link3a': 'zone3',
  'link3b': 'zone3',
  'link3c': 'zone3',
};

final _complexWindowsMapping =
    WindowsZones('cldr-version', 'tzdb-version', 'windows-version', [
  MapZone('win1', MapZone.primaryTerritory, ['zone1']),
  MapZone('win1', 'UK', ['zone1']),
  MapZone('win2', MapZone.primaryTerritory, ['link2']),
  MapZone('win2', 'UK', ['link2']),
  MapZone('win3', MapZone.primaryTerritory, ['link3a']),
  MapZone('win3', 'UK', ['link3a']),
  MapZone('win4', MapZone.primaryTerritory, ['zone4']),
  MapZone('win4', 'UK', ['zone4']),
  MapZone('win4', 'FR', ['zone5']),
  MapZone('win4', 'CA', ['link3b']),
]);

@Test()
void WindowsToTzdbIds() {
  TzdbDateTimeZoneSource.validateData(
      _complexCanonicalIdMap, _complexWindowsMapping);
  var actual = TzdbDateTimeZoneSource.buildWindowsToTzdbIdMap(
      _complexWindowsMapping, _complexCanonicalIdMap);
  expect(actual, {
    'win1': 'zone1',
    'win2': 'zone2',
    'win3': 'zone3',
    'win4': 'zone4',
  });
}

@Test()
void TzdbToWindowsIds() {
  var actual = TzdbDateTimeZoneSource.buildTzdbToWindowsIdMap(
      _complexWindowsMapping, _complexCanonicalIdMap);
  expect(actual, {
    'zone1': 'win1',
    'link1': 'win1',
    'zone2': 'win2',
    'link2': 'win2',
    // No explicit zone3 mapping; link3a and link3b map to win3 and win4 respectively;
    // link3a "wins" as it's earlier lexicographically.
    'zone3': 'win3',
    'link3a': 'win3',
    // Explicit mapping to win4 from link3b. This is unusual, but we handle it.
    'link3b': 'win4',
    // link3c isn't mentioned at all, so we use the canonical ID
    'link3c': 'win3',
    'zone4': 'win4',
    'zone5': 'win4',
    // zone6 isn't mapped at all
  });
}

// We'll need to adjust the documentation if either of these tests starts to fail.
@Test()
void TzdbToWindowsIdDocumentationExamples() {
  const kolkata = 'Asia/Kolkata';
  const calcutta = 'Asia/Calcutta';
  const indiaStandardTime = 'India Standard Time';
  const asmara = 'Africa/Asmara';
  const eastAfricaStandardTime = 'E. Africa Standard Time';
  const nairobi = 'Africa/Nairobi';

  // Validate the claims about the source data
  var mappedIds = source.windowsMapping.mapZones.expand((mz) => mz.tzdbIds);
  expect(source.canonicalIdMap[calcutta], kolkata);
  expect(mappedIds, isNot(contains(kolkata)));
  expect(source.canonicalIdMap[asmara], nairobi);
  expect(mappedIds, isNot(contains(asmara)));

  // And the mappings
  expect(source.tzdbToWindowsIds[kolkata], indiaStandardTime);
  expect(source.tzdbToWindowsIds[asmara], eastAfricaStandardTime);
}

@Test()
void UtcMappings() {
  // Note: was Etc/GMT before CLDR v39.
  expect(source.windowsToTzdbIds['UTC'], 'Etc/UTC');
  expect(source.tzdbToWindowsIds['Etc/UTC'], 'UTC');
  // We follow the link
  expect(source.tzdbToWindowsIds['Etc/GMT+0'], 'UTC');
}

@Test()
void WindowsToTzdbIdDocumentationExamples() {
  const kolkata = 'Asia/Kolkata';
  const calcutta = 'Asia/Calcutta';
  const indiaStandardTime = 'India Standard Time';

  // Validate the claims about the source data
  expect(source.canonicalIdMap[calcutta], kolkata);
  expect(source.windowsMapping.mapZones.expand((mz) => mz.tzdbIds),
      isNot(contains(kolkata)));

  // And the mapping
  expect(source.windowsToTzdbIds[indiaStandardTime], kolkata);
}
