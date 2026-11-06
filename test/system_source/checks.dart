// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

/// Platform-agnostic checks of [SystemDateTimeZoneSource] and
/// [DateTimeZoneProviders.system], run on every platform CI covers: the Dart
/// VM (Linux, Windows; test/system_source/system_source_test.dart), the web
/// (dart2js and dart2wasm in Chrome, dart2js in Node; the same file) and
/// Flutter on Android and iOS (test_apps/system_source_flutter).
///
/// Plain Dart: no dart:mirrors, no dart:io, and no dependency on a test
/// runner (only package:matcher's expect), so every harness can register
/// the checks with its own `test` / `testWidgets`. The harness must call
/// `TimeMachine.initialize` first.
library;

import 'package:matcher/expect.dart';
import 'package:time_machine2/time_machine2.dart';

import 'platform_clock.dart';

/// What the platform under test is expected to provide.
class SystemSourcePlatform {
  /// A name for failure messages, e.g. 'Windows' or 'web (dart2wasm)'.
  final String name;

  /// Whether zone IDs are Windows IDs ('W. Europe Standard Time') rather than
  /// IANA IDs ('Europe/Berlin').
  final bool usesWindowsIds;

  /// The ID the system time zone is known to be (e.g. because CI set it), or
  /// null to only check it against the platform's own report, if any.
  final String? expectedSystemDefaultId;

  const SystemSourcePlatform({
    required this.name,
    this.usesWindowsIds = false,
    this.expectedSystemDefaultId,
  });

  /// IDs that every database of this kind has.
  List<String> get expectedIds => usesWindowsIds
      ? const [
          'GMT Standard Time',
          'W. Europe Standard Time',
          'Eastern Standard Time',
          'Tokyo Standard Time',
          'AUS Eastern Standard Time',
        ]
      : const [
          'Europe/London',
          'Europe/Berlin',
          'America/New_York',
          'Asia/Tokyo',
          'Australia/Sydney',
        ];

  /// UK time, which has had the same rules since 1996 in TZDB and Windows:
  /// GMT (+00:00) in winter, BST (+01:00) from 01:00 UTC on the last Sunday
  /// of March to 01:00 UTC on the last Sunday of October.
  String get londonId => usesWindowsIds ? 'GMT Standard Time' : 'Europe/London';

  /// The ID the system time zone should have, if known.
  String? get systemDefaultIdToExpect =>
      expectedSystemDefaultId ?? (usesWindowsIds ? null : platformTimeZoneId());

  @override
  String toString() => name;
}

/// One check: a test name, its body and, if it can't run here, why.
class SystemSourceCheck {
  final String name;
  final Future<void> Function() body;

  /// Why the check is skipped, or null if it runs.
  final String? skip;

  const SystemSourceCheck(this.name, this.body, {this.skip});
}

/// An ID no platform has.
const String unknownZoneId = 'Not/AZone';

/// The checks for [platform], to be registered as tests by a harness.
List<SystemSourceCheck> systemSourceChecks(SystemSourcePlatform platform) {
  // Created by the first check that runs, not while tests are declared, so
  // that a backend that throws fails the checks instead of the test file.
  late final source = SystemDateTimeZoneSource();
  final year = DateTime.now().toUtc().year;

  return [
    SystemSourceCheck('isSupported is true', () async {
      expect(SystemDateTimeZoneSource.isSupported, isTrue,
          reason: '$platform should provide system time zone data '
              '(${source.description})');
    }),
    SystemSourceCheck('versionId names the system data (no TZDB fallback)',
        () async {
      expect(source.versionId, startsWith('System:'));
      expect(source.description, isNot(startsWith('unsupported')));
      var provider = await DateTimeZoneProviders.system;
      expect(provider.versionId, startsWith('System:'));
      var tzdb = await DateTimeZoneProviders.tzdb;
      expect(provider.versionId, isNot(tzdb.versionId));
    }),
    SystemSourceCheck('getIds is non-empty and has the expected IDs', () async {
      var ids = (await source.getIds()).toList();
      expect(ids, isNotEmpty);
      expect(ids, containsAll(platform.expectedIds));
      expect(ids, isNot(contains(unknownZoneId)));
      expect(ids.toSet(), hasLength(ids.length), reason: 'IDs are unique');
      var provider = await DateTimeZoneProviders.system;
      expect(provider.ids, containsAll(platform.expectedIds));
    }),
    SystemSourceCheck('forId loads the expected zones', () async {
      var provider = await DateTimeZoneProviders.system;
      for (var id in platform.expectedIds) {
        var zone = await source.forId(id);
        expect(zone.id, id);
        expect((await provider[id]).id, id);
      }
    }),
    SystemSourceCheck(
        'forId accepts IANA IDs, with the Windows zone\'s rules (as .NET does)',
        () async {
      var provider = await DateTimeZoneProviders.system;
      var ids = (await source.getIds()).toSet();
      // Asia/Calcutta is a link (to Asia/Kolkata), which ICU resolves too.
      const windowsIdsByIanaId = {
        'Europe/London': 'GMT Standard Time',
        'Australia/Sydney': 'AUS Eastern Standard Time',
        'Asia/Calcutta': 'India Standard Time',
      };
      for (var MapEntry(key: ianaId, value: windowsId)
          in windowsIdsByIanaId.entries) {
        expect(ids, isNot(contains(ianaId)),
            reason: 'getIds lists only Windows IDs');
        var windowsZone = await source.forId(windowsId);
        for (var zone in [await source.forId(ianaId), await provider[ianaId]]) {
          expect(zone.id, ianaId);
          for (var month = 1; month <= 12; month++) {
            var instant = Instant.utc(year, month, 15, 12, 0);
            expect(
                zone.getUtcOffset(instant), windowsZone.getUtcOffset(instant),
                reason: '$ianaId and $windowsId on $year-$month-15');
          }
        }
      }
    },
        skip: platform.usesWindowsIds
            ? null
            : 'Windows only: zone IDs are already IANA IDs here'),
    SystemSourceCheck(
        'forId throws DateTimeZoneNotFoundError for an unknown ID', () async {
      await expectLater(source.forId(unknownZoneId),
          throwsA(isA<DateTimeZoneNotFoundError>()));
      var provider = await DateTimeZoneProviders.system;
      await expectLater(
          provider[unknownZoneId], throwsA(isA<DateTimeZoneNotFoundError>()));
      expect(await provider.getZoneOrNull(unknownZoneId), isNull);
    }),
    SystemSourceCheck('systemDefaultId is one of getIds', () async {
      var ids = await source.getIds();
      var id = source.systemDefaultId;
      expect(id, isNotNull, reason: 'the system time zone should be known');
      expect(ids, contains(id));
      var provider = await DateTimeZoneProviders.system;
      expect((await provider.getSystemDefault()).id, id);
    }),
    SystemSourceCheck('systemDefaultId is the configured system time zone',
        () async {
      expect(source.systemDefaultId, platform.systemDefaultIdToExpect);
    },
        skip: platform.systemDefaultIdToExpect == null
            ? 'The system time zone ID is unknown on ${platform.name} '
                '(set TIME_MACHINE_EXPECT_SYSTEM_TIME_ZONE to check it)'
            : null),
    SystemSourceCheck(
        'the system default zone matches $platformClockDescription '
        'now and across the year', () async {
      var id = source.systemDefaultId;
      expect(id, isNotNull, reason: 'the system time zone should be known');
      var zone = await source.forId(id!);
      var instants = <int>[
        DateTime.now().millisecondsSinceEpoch,
        for (var month = 1; month <= 12; month++) ...[
          DateTime.utc(year, month, 1, 12).millisecondsSinceEpoch,
          DateTime.utc(year, month, 15, 12).millisecondsSinceEpoch,
        ],
      ];
      var mismatches = <String>[];
      for (var ms in instants) {
        var expected = platformUtcOffsetSeconds(ms);
        var actual =
            zone.getUtcOffset(Instant.fromEpochMilliseconds(ms)).inSeconds;
        if (actual != expected) {
          mismatches.add('${_utc(ms)}: $id has $actual s, '
              '$platformClockDescription has $expected s');
        }
      }
      expect(mismatches, isEmpty);
    }),
    SystemSourceCheck(
        'a DST zone has different offsets in January and July, '
        'and its zone intervals adjoin', () async {
      var zone = await source.forId(platform.londonId);
      Instant at(DateTime utc) =>
          Instant.fromEpochMilliseconds(utc.millisecondsSinceEpoch);

      var january = zone.getZoneInterval(at(DateTime.utc(year, 1, 15)));
      var july = zone.getZoneInterval(at(DateTime.utc(year, 7, 15)));
      expect(january.wallOffset.inSeconds, 0, reason: 'GMT in January');
      expect(july.wallOffset.inSeconds, 3600, reason: 'BST in July');
      expect(january.savings.inSeconds, 0, reason: 'standard time in January');
      expect(july.savings.inSeconds, 3600, reason: 'summer time in July');

      // BST runs from 01:00 UTC on the last Sunday of March to 01:00 UTC on
      // the last Sunday of October.
      expect(july.hasStart && july.hasEnd, isTrue);
      expect(_utc(july.start.epochMilliseconds),
          _utc(_lastSunday(year, 3, 1).millisecondsSinceEpoch));
      expect(_utc(july.end.epochMilliseconds),
          _utc(_lastSunday(year, 10, 1).millisecondsSinceEpoch));

      var yearStart = at(DateTime.utc(year));
      var yearEnd = at(DateTime.utc(year + 1));
      var intervals =
          zone.getZoneIntervals(Interval(yearStart, yearEnd)).toList();
      expect(intervals.length, greaterThanOrEqualTo(3),
          reason: 'GMT, BST and GMT again');
      expect(!intervals.first.hasStart || intervals.first.start <= yearStart,
          isTrue,
          reason: 'the intervals cover the start of the year');
      expect(!intervals.last.hasEnd || intervals.last.end >= yearEnd, isTrue,
          reason: 'the intervals cover the end of the year');
      for (var i = 0; i + 1 < intervals.length; i++) {
        var a = intervals[i], b = intervals[i + 1];
        expect(a.hasEnd && b.hasStart, isTrue);
        expect(b.start, a.end,
            reason: 'interval ${i + 1} starts where interval $i ends');
        expect(zone.getZoneInterval(b.start), b);
      }
      expect(intervals.map((i) => i.wallOffset.inSeconds).toSet(), {0, 3600});
    }),
  ];
}

DateTime _lastSunday(int year, int month, int hourUtc) {
  // Day 0 of the next month is the last day of this one.
  var day = DateTime.utc(year, month + 1, 0, hourUtc);
  while (day.weekday != DateTime.sunday) {
    day = DateTime.utc(day.year, day.month, day.day - 1, hourUtc);
  }
  return day;
}

String _utc(int epochMilliseconds) =>
    DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: true)
        .toIso8601String();
