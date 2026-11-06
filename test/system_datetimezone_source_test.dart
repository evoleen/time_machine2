// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Uses dart:ffi (the Windows backend) and dart:io.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/platforms/windows_time_zone.dart';
import 'package:time_machine2/src/timezones/system/android_tzdata_backend.dart';
import 'package:time_machine2/src/timezones/system/map_datetimezone.dart';
import 'package:time_machine2/src/timezones/system/system_time_zone_backend.dart';
import 'package:time_machine2/src/timezones/system/tzif.dart';
import 'package:time_machine2/src/timezones/system/tzif_directory_backend.dart';
import 'package:time_machine2/src/timezones/system/windows_rules.dart';
import 'package:time_machine2/src/timezones/system/windows_system_backend.dart';
import 'package:universal_io/io.dart' as io;

import 'time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  test('MapDateTimeZoneIsFixedWhenOffsetBoundsAreEqual',
      MapDateTimeZoneIsFixedWhenOffsetBoundsAreEqual);
  test('SystemZonesReportIsFixedFromTheirOffsets',
      SystemZonesReportIsFixedFromTheirOffsets);
  test('UnsupportedPlatformThrowsAndNeverFallsBack',
      UnsupportedPlatformThrowsAndNeverFallsBack);
  test('UnknownIdIsNotFound', UnknownIdIsNotFound);
  test('WindowsFloatingTransition', WindowsFloatingTransition);
  test('WindowsLastWeekTransition', WindowsLastWeekTransition);
  test('WindowsTransitionOneMillisecondBeforeMidnight',
      WindowsTransitionOneMillisecondBeforeMidnight);
  test('WindowsAbsoluteTransition', WindowsAbsoluteTransition);
  test('WindowsStartOfYearMarkerIsJanuaryFirst',
      WindowsStartOfYearMarkerIsJanuaryFirst);
  test('WindowsRuleOffsets', WindowsRuleOffsets);
  test('WindowsYearRulesAreCoalesced', WindowsYearRulesAreCoalesced);
  test('WindowsSingleRuleZone', WindowsSingleRuleZone);
  test('WindowsFixedZone', WindowsFixedZone);
  test('WindowsRuleChangeAtNewYearUsesPreviousRuleOffset',
      WindowsRuleChangeAtNewYearUsesPreviousRuleOffset);
  test('WindowsStartOfYearMarkers', WindowsStartOfYearMarkers);
  test('PosixStandardOnly', PosixStandardOnly);
  test('PosixWithRules', PosixWithRules);
  parameterizedTest(
      'PosixInvalid',
      [
        [''],
        ['5'],
        ['EST'],
        ['EST5EDT,M3.2.0'],
        ['EST5EDT,M13.2.0,M11.1.0'],
        ['EST5EDT,M3.6.0,M11.1.0'],
        ['EST5EDT,J0,J365'],
        ['<+03-3'],
        ['EST5EDT,M3.2.0/168,M11.1.0'],
        ['EST5EDT,M3.2.0,M11.1.0x'],
      ],
      PosixInvalid,
      customDescriptionBuilder: describeArguments);
  test('PosixUsRules', PosixUsRules);
  test('PosixSouthernHemisphere', PosixSouthernHemisphere);
  test('PosixExtendedHours', PosixExtendedHours);
  test('PosixJulianAndZeroBasedDays', PosixJulianAndZeroBasedDays);
  test('PosixDaylightAllYear', PosixDaylightAllYear);
  test('PosixFarFromNow', PosixFarFromNow);
  test('TzifParse', TzifParse);
  test('TzifParseVersion1', TzifParseVersion1);
  test('TzifRejectsMalformedData', TzifRejectsMalformedData);
  test('TzifZone', TzifZone);
  test('TzifZoneVersion1WithoutFooter', TzifZoneVersion1WithoutFooter);
  test('TzifSavingsUseTheStandardOffsetInEffect',
      TzifSavingsUseTheStandardOffsetInEffect);
  test('TzifWithoutTransitions', TzifWithoutTransitions);
  test('AndroidBundle', AndroidBundle);
  test('AndroidBundleRejectsMalformedData', AndroidBundleRejectsMalformedData);
  test('TzifDirectory', TzifDirectory);
  test('TzifDirectoryMissing', TzifDirectoryMissing);
  // Comparisons with the OS: every zone, so slower than the default 30s
  // timeout allows on a busy machine.
  test('WindowsSourceMatchesTheOperatingSystem',
      WindowsSourceMatchesTheOperatingSystem,
      timeout: _osComparisonTimeout);
  test('WindowsNamesVersionAndDefault', WindowsNamesVersionAndDefault);
  test('TzifSourceMatchesZdump', TzifSourceMatchesZdump,
      timeout: _osComparisonTimeout);
  test('TzifSourceDefaultsAndProvider', TzifSourceDefaultsAndProvider);
}

const _osComparisonTimeout = Timeout(Duration(minutes: 5));

Instant _utc(int year, int month, int day, [int hour = 0, int minute = 0]) =>
    Instant.utc(year, month, day, hour, minute);

int _epochSeconds(int year, int month, int day,
        [int hour = 0, int minute = 0, int second = 0]) =>
    DateTime.utc(year, month, day, hour, minute, second)
        .millisecondsSinceEpoch ~/
    1000;

/// The starts of the zone intervals of [zone] in [from, to).
List<Instant> _transitions(DateTimeZone zone, Instant from, Instant to) => [
      for (var interval in zone.getZoneIntervals(Interval(from, to)))
        if (interval.hasStart && interval.start > from) interval.start
    ];

// ---------------------------------------------------------------------------
// SystemDateTimeZoneSource itself
// ---------------------------------------------------------------------------

class _FakeBackend implements SystemTimeZoneBackend {
  @override
  String get description => 'fake';
  @override
  bool get isSupported => true;
  @override
  String? get dataVersion => '2099z';
  @override
  List<String> getIds() => ['Fake/Zone'];
  @override
  DateTimeZone? loadZone(String id) => id == 'Fake/Zone'
      ? FixedDateTimeZone('Fake/Zone', Offset.hours(3), 'FAKE')
      : null;
  @override
  String? get systemDefaultId => 'Fake/Zone';
}

/// MapDateTimeZone (used for Windows zones and TZif rules) is fixed exactly
/// when its offset bounds are equal, e.g. a zone in DST all year.
void MapDateTimeZoneIsFixedWhenOffsetBoundsAreEqual() {
  var interval = IZoneInterval.newZoneInterval('XDT', IInstant.beforeMinValue,
      IInstant.afterMaxValue, Offset.hours(3), Offset.hours(1));
  var map = SingleZoneIntervalMap(interval);
  expect(
      IDateTimeZone.isFixed(
          MapDateTimeZone('Test/Fixed', map, Offset.hours(3), Offset.hours(3))),
      isTrue);
  expect(
      IDateTimeZone.isFixed(MapDateTimeZone(
          'Test/Variable', map, Offset.hours(2), Offset.hours(3))),
      isFalse);
}

/// A zone is fixed only if it has the same offset at every instant, as in
/// Noda Time.
Future SystemZonesReportIsFixedFromTheirOffsets() async {
  if (skipUnless(SystemDateTimeZoneSource.isSupported,
      'No system time zone data on this platform')) {
    return;
  }
  var source = SystemDateTimeZoneSource();
  var (fixed, variable) = io.Platform.isWindows
      ? ('UTC', 'Pacific Standard Time')
      : ('Etc/UTC', 'America/Los_Angeles');
  var fixedZone = await source.forId(fixed);
  expect(IDateTimeZone.isFixed(fixedZone), isTrue, reason: fixed);
  expect(fixedZone.minOffset, fixedZone.maxOffset);
  expect(IDateTimeZone.isFixed(await source.forId(variable)), isFalse,
      reason: variable);
}

Future UnsupportedPlatformThrowsAndNeverFallsBack() async {
  var source = SystemDateTimeZoneSource.withBackend(
      const UnsupportedSystemTimeZoneBackend('test'));
  expect(() => source.getIds(), throwsUnsupportedError);
  expect(() => source.forCachedId('Europe/London'), throwsUnsupportedError);
  expect(source.systemDefaultId, isNull);
}

Future UnknownIdIsNotFound() async {
  var source = SystemDateTimeZoneSource.withBackend(_FakeBackend());
  expect(await source.getIds(), ['Fake/Zone']);
  expect(source.forCachedId('Fake/Zone').getUtcOffset(Instant.unixEpoch),
      Offset.hours(3));
  // No fallback to TZDB, even for a zone TZDB has.
  expect(() => source.forCachedId('Europe/London'),
      throwsA(isA<DateTimeZoneNotFoundError>()));
  expect(source.versionId, 'System: fake 2099z');
  expect(source.systemDefaultId, 'Fake/Zone');
}

// ---------------------------------------------------------------------------
// Windows rule conversion (pure Dart)
// ---------------------------------------------------------------------------

void WindowsFloatingTransition() {
  // Second Sunday in March, 02:00.
  var offset = windowsTransitionToZoneYearOffset(
      const WindowsTransitionDate(month: 3, dayOfWeek: 0, day: 2, hour: 2));
  expect(offset.getOccurrenceForYear(2024),
      ILocalDateTime.toLocalInstant(LocalDateTime(2024, 3, 10, 2, 0, 0)));
  expect(offset.getOccurrenceForYear(2025),
      ILocalDateTime.toLocalInstant(LocalDateTime(2025, 3, 9, 2, 0, 0)));
}

void WindowsLastWeekTransition() {
  // Last Sunday in October, 03:00.
  var offset = windowsTransitionToZoneYearOffset(
      const WindowsTransitionDate(month: 10, dayOfWeek: 0, day: 5, hour: 3));
  expect(offset.getOccurrenceForYear(2024),
      ILocalDateTime.toLocalInstant(LocalDateTime(2024, 10, 27, 3, 0, 0)));
  expect(offset.getOccurrenceForYear(2021),
      ILocalDateTime.toLocalInstant(LocalDateTime(2021, 10, 31, 3, 0, 0)));
}

void WindowsTransitionOneMillisecondBeforeMidnight() {
  // Brazil's old rule: third Saturday in February at 23:59:59.999, i.e.
  // midnight at the start of the Sunday.
  var offset = windowsTransitionToZoneYearOffset(const WindowsTransitionDate(
      month: 2,
      dayOfWeek: 6,
      day: 3,
      hour: 23,
      minute: 59,
      second: 59,
      milliseconds: 999));
  expect(offset.getOccurrenceForYear(2012),
      ILocalDateTime.toLocalInstant(LocalDateTime(2012, 2, 19, 0, 0, 0)));
}

void WindowsAbsoluteTransition() {
  var offset = windowsTransitionToZoneYearOffset(
      const WindowsTransitionDate(year: 2010, month: 4, day: 4, hour: 3));
  expect(offset.getOccurrenceForYear(2010),
      ILocalDateTime.toLocalInstant(LocalDateTime(2010, 4, 4, 3, 0, 0)));
}

void WindowsStartOfYearMarkerIsJanuaryFirst() {
  // "First Thursday of January at 00:00", written for a year starting on a
  // Thursday, means January 1st in every year (as Windows treats it).
  const marker = WindowsTransitionDate(month: 1, dayOfWeek: 4, day: 1);
  expect(isWindowsStartOfYearMarker(marker), isTrue);
  expect(
      isWindowsStartOfYearMarker(
          const WindowsTransitionDate(month: 1, dayOfWeek: 4, day: 1, hour: 2)),
      isFalse);
  var offset = windowsTransitionToZoneYearOffset(marker);
  expect(offset.getOccurrenceForYear(1971),
      ILocalDateTime.toLocalInstant(LocalDateTime(1971, 1, 1, 0, 0, 0)));
}

void WindowsRuleOffsets() {
  const rule = WindowsZoneRule(bias: 300, standardBias: 0, daylightBias: -60);
  expect(rule.standardOffset, Offset.hours(-5));
  expect(rule.daylightOffset, Offset.hours(-4));
  expect(rule.savings, Offset.hours(1));
  expect(rule.observesDaylightTime, isFalse); // no transition dates
}

void WindowsYearRulesAreCoalesced() {
  const a = WindowsZoneRule(bias: 0);
  const b = WindowsZoneRule(bias: 60);
  var rules = coalesceWindowsYearRules(2000, [a, a, b, b, b, a]);
  expect(rules.map((r) => '${r.firstYear}-${r.lastYear}'),
      ['2000-2001', '2002-2004', '2005-2005']);
}

const _usDaylight =
    WindowsTransitionDate(month: 3, dayOfWeek: 0, day: 2, hour: 2);
const _usStandard =
    WindowsTransitionDate(month: 11, dayOfWeek: 0, day: 1, hour: 2);

void WindowsSingleRuleZone() {
  var zone = buildWindowsZone('Eastern Standard Time', 'Eastern Standard Time',
      'Eastern Daylight Time', const [
    WindowsYearRule(
        2007,
        2007,
        WindowsZoneRule(
            bias: 300, standardDate: _usStandard, daylightDate: _usDaylight))
  ]);
  // The single rule applies to all years.
  expect(_transitions(zone, _utc(2024, 1, 1), _utc(2025, 1, 1)),
      [_utc(2024, 3, 10, 7), _utc(2024, 11, 3, 6)]);
  expect(_transitions(zone, _utc(1990, 1, 1), _utc(1991, 1, 1)),
      [_utc(1990, 3, 11, 7), _utc(1990, 11, 4, 6)]);
  var summer = zone.getZoneInterval(_utc(2024, 7, 1));
  expect(summer.name, 'Eastern Daylight Time');
  expect(summer.savings, Offset.hours(1));
  expect(summer.standardOffset, Offset.hours(-5));
  expect(zone.minOffset, Offset.hours(-5));
  expect(zone.maxOffset, Offset.hours(-4));
}

void WindowsFixedZone() {
  var zone = buildWindowsZone(
      'UTC', 'Coordinated Universal Time', 'Coordinated Universal Time', const [
    WindowsYearRule(1, 9999, WindowsZoneRule(bias: 0)),
  ]);
  expect(zone, isA<FixedDateTimeZone>());
  expect(zone.getZoneInterval(Instant.unixEpoch).name,
      'Coordinated Universal Time');
}

void WindowsRuleChangeAtNewYearUsesPreviousRuleOffset() {
  // Like "Turks And Caicos Standard Time": -04 with no DST in 2017, then
  // -05 with US DST from 2018. Windows switches at midnight local time
  // according to the old rule (04:00 UTC), not the zone's current standard
  // offset (which would be 05:00 UTC).
  var zone = buildWindowsZone('T', 'S', 'D', const [
    WindowsYearRule(2015, 2017, WindowsZoneRule(bias: 240)),
    WindowsYearRule(
        2018,
        2018,
        WindowsZoneRule(
            bias: 300, standardDate: _usStandard, daylightDate: _usDaylight)),
  ]);
  expect(zone.getUtcOffset(_utc(2018, 1, 1, 3, 59)), Offset.hours(-4));
  expect(zone.getUtcOffset(_utc(2018, 1, 1, 4)), Offset.hours(-5));
  // Before the first rule: the first rule. After the last: the last rule.
  expect(zone.getUtcOffset(_utc(1990, 7, 1)), Offset.hours(-4));
  expect(zone.getUtcOffset(_utc(2030, 7, 1)), Offset.hours(-4));
  expect(zone.getUtcOffset(_utc(2030, 1, 1)), Offset.hours(-5));
}

void WindowsStartOfYearMarkers() {
  // Like "N. Central Asia Standard Time": +07 in 2013; in 2014 "daylight"
  // (+07) from the start of the year until October, then +06.
  var zone = buildWindowsZone('N', 'S', 'D', const [
    WindowsYearRule(2013, 2013, WindowsZoneRule(bias: -420)),
    WindowsYearRule(
        2014,
        2014,
        WindowsZoneRule(
            bias: -360,
            standardDate:
                WindowsTransitionDate(month: 10, dayOfWeek: 0, day: 5, hour: 2),
            daylightDate:
                WindowsTransitionDate(month: 1, dayOfWeek: 3, day: 1))),
    WindowsYearRule(2015, 2015, WindowsZoneRule(bias: -360)),
  ]);
  // No glitch at New Year: +07 throughout until October 2014.
  for (var hour = 12; hour < 24; hour++) {
    expect(zone.getUtcOffset(_utc(2013, 12, 31, hour)), Offset.hours(7));
  }
  expect(zone.getUtcOffset(_utc(2014, 10, 25, 18, 59)), Offset.hours(7));
  expect(zone.getUtcOffset(_utc(2014, 10, 25, 19)), Offset.hours(6));
  // The 2014 rule's marker for 2015 doesn't take effect.
  expect(zone.getUtcOffset(_utc(2014, 12, 31, 17, 30)), Offset.hours(6));
  // The only change at New Year 2014 is from standard to "daylight" time.
  expect(_transitions(zone, _utc(2013, 1, 1), _utc(2016, 1, 1)),
      [_utc(2013, 12, 31, 17), _utc(2014, 10, 25, 19)]);
  expect(zone.getZoneInterval(_utc(2014, 1, 1)).savings, Offset.hours(1));
}

// ---------------------------------------------------------------------------
// POSIX TZ strings
// ---------------------------------------------------------------------------

void PosixStandardOnly() {
  var tz = PosixTimeZone.parse('EST5')!;
  expect(tz.standardName, 'EST');
  expect(tz.standardOffset, -5 * 3600);
  expect(tz.hasDaylightSavingTime, isFalse);

  tz = PosixTimeZone.parse('<+0330>-3:30')!;
  expect(tz.standardName, '+0330');
  expect(tz.standardOffset, 3 * 3600 + 1800);

  tz = PosixTimeZone.parse('<-03>3')!;
  expect(tz.standardName, '-03');
  expect(tz.standardOffset, -3 * 3600);

  tz = PosixTimeZone.parse('UTC0')!;
  expect(tz.standardOffset, 0);

  tz = PosixTimeZone.parse('LMT-0:53:28')!;
  expect(tz.standardOffset, 53 * 60 + 28);
}

void PosixWithRules() {
  var tz = PosixTimeZone.parse('EST5EDT,M3.2.0,M11.1.0')!;
  expect(tz.daylightName, 'EDT');
  expect(tz.daylightOffset, -4 * 3600);
  expect(tz.start, const PosixTransition.monthWeekDay(3, 2, 0, 7200));
  expect(tz.end, const PosixTransition.monthWeekDay(11, 1, 0, 7200));

  tz = PosixTimeZone.parse('CET-1CEST,M3.5.0,M10.5.0/3')!;
  expect(tz.standardOffset, 3600);
  expect(tz.daylightOffset, 7200);
  expect(tz.end, const PosixTransition.monthWeekDay(10, 5, 0, 3 * 3600));

  tz = PosixTimeZone.parse('IST-2IDT,M3.4.4/26,M10.5.0')!;
  expect(tz.start, const PosixTransition.monthWeekDay(3, 4, 4, 26 * 3600));

  tz = PosixTimeZone.parse('<-03>3<-02>,M3.5.0/-2,M10.5.0/-1')!;
  expect(tz.start, const PosixTransition.monthWeekDay(3, 5, 0, -2 * 3600));
  expect(tz.end, const PosixTransition.monthWeekDay(10, 5, 0, -3600));

  tz = PosixTimeZone.parse('WART4WARST,J1/0,J365/25')!;
  expect(tz.start, const PosixTransition.julian(1, 0));
  expect(tz.end, const PosixTransition.julian(365, 25 * 3600));

  tz = PosixTimeZone.parse('NZST-12NZDT-13,M9.5.0,M4.1.0/3')!;
  expect(tz.daylightOffset, 13 * 3600);

  // Explicit DST offset with a sign, and a zero-based day.
  tz = PosixTimeZone.parse('XXX3YYY+2,59/2,300')!;
  expect(tz.daylightOffset, -2 * 3600);
  expect(tz.start, const PosixTransition.zeroBased(59, 7200));

  // No rule: the US rules are the default.
  tz = PosixTimeZone.parse('EST5EDT')!;
  expect(tz.start, const PosixTransition.monthWeekDay(3, 2, 0, 7200));
}

void PosixInvalid(String text) {
  expect(PosixTimeZone.parse(text), isNull);
}

void PosixUsRules() {
  var map = PosixTimeZone.parse('EST5EDT,M3.2.0,M11.1.0')!.toZoneIntervalMap();
  var summer = map.getZoneInterval(_utc(2024, 7, 1));
  expect(summer.name, 'EDT');
  expect(summer.start, _utc(2024, 3, 10, 7));
  expect(summer.end, _utc(2024, 11, 3, 6));
  expect(summer.wallOffset, Offset.hours(-4));
  expect(summer.savings, Offset.hours(1));
  var winter = map.getZoneInterval(_utc(2025, 1, 1));
  expect(winter.name, 'EST');
  expect(winter.start, _utc(2024, 11, 3, 6));
  expect(winter.end, _utc(2025, 3, 9, 7));
  expect(winter.savings, Offset.zero);
  expect(map.minOffset, Offset.hours(-5));
  expect(map.maxOffset, Offset.hours(-4));
}

void PosixSouthernHemisphere() {
  var map = PosixTimeZone.parse('NZST-12NZDT-13,M9.5.0,M4.1.0/3')!
      .toZoneIntervalMap();
  var summer = map.getZoneInterval(_utc(2025, 1, 1));
  expect(summer.name, 'NZDT');
  // 2024-09-29 02:00 NZST; 2025-04-06 03:00 NZDT.
  expect(summer.start, _utc(2024, 9, 28, 14));
  expect(summer.end, _utc(2025, 4, 5, 14));
}

void PosixExtendedHours() {
  // Israel: Friday before the last Sunday in March (the fourth Thursday at
  // 26:00), to the last Sunday in October at 02:00.
  var map =
      PosixTimeZone.parse('IST-2IDT,M3.4.4/26,M10.5.0')!.toZoneIntervalMap();
  var summer = map.getZoneInterval(_utc(2024, 7, 1));
  expect(summer.start, _utc(2024, 3, 29, 0)); // Fri 02:00 IST
  expect(summer.end, _utc(2024, 10, 26, 23)); // Sun 02:00 IDT

  // Greenland: negative times (-02:00 and -01:00 on the last Sundays).
  map = PosixTimeZone.parse('<-03>3<-02>,M3.5.0/-2,M10.5.0/-1')!
      .toZoneIntervalMap();
  summer = map.getZoneInterval(_utc(2024, 7, 1));
  expect(summer.name, '-02');
  expect(summer.start, _utc(2024, 3, 31, 1)); // Sat 22:00 -03
  expect(summer.end, _utc(2024, 10, 27, 1)); // Sat 23:00 -02
}

void PosixJulianAndZeroBasedDays() {
  // J60 is always March 1st; zero-based 59 is February 29th in leap years.
  var map = PosixTimeZone.parse('AAA0BBB,J60/0,J300/0')!.toZoneIntervalMap();
  expect(map.getZoneInterval(_utc(2024, 6, 1)).start, _utc(2024, 3, 1));
  expect(map.getZoneInterval(_utc(2023, 6, 1)).start, _utc(2023, 3, 1));
  map = PosixTimeZone.parse('AAA0BBB,59/0,300/0')!.toZoneIntervalMap();
  expect(map.getZoneInterval(_utc(2024, 6, 1)).start, _utc(2024, 2, 29));
  expect(map.getZoneInterval(_utc(2023, 6, 1)).start, _utc(2023, 3, 1));
}

void PosixDaylightAllYear() {
  // tzfile(5): DST all year.
  var tz = PosixTimeZone.parse('WART4WARST,J1/0,J365/25')!;
  var zone = tz.toDateTimeZone('Test');
  expect(zone.minOffset, zone.maxOffset);
  var interval = zone.getZoneInterval(_utc(2024, 1, 1));
  expect(interval.name, 'WARST');
  expect(interval.wallOffset, Offset.hours(-3));
  expect(interval.savings, Offset.hours(1));
}

void PosixFarFromNow() {
  var map = PosixTimeZone.parse('EST5EDT,M3.2.0,M11.1.0')!.toZoneIntervalMap();
  expect(map.getZoneInterval(_utc(9999, 12, 31, 12)).name, 'EST');
  expect(map.getZoneInterval(_utc(-9998, 1, 1, 12)).name, 'EST');
  expect(map.getZoneInterval(_utc(9999, 7, 1)).name, 'EDT');
}

// ---------------------------------------------------------------------------
// TZif parsing
// ---------------------------------------------------------------------------

/// Builds TZif data. [types] are (utoff, isdst, abbreviation).
Uint8List _buildTzif(
    {int version = 2,
    List<int> times = const [],
    List<int> transitionTypes = const [],
    required List<(int, bool, String)> types,
    String? footer,
    int leapCount = 0}) {
  var chars = <int>[];
  var abbreviationIndexes = <int>[];
  for (var (_, _, abbreviation) in types) {
    abbreviationIndexes.add(chars.length);
    chars
      ..addAll(ascii.encode(abbreviation))
      ..add(0);
  }

  List<int> block(int timeSize, List<int> blockTimes, List<int> blockTypes) {
    var builder = BytesBuilder();
    var header = ByteData(44);
    var magic = ascii.encode('TZif');
    for (var i = 0; i < 4; i++) {
      header.setUint8(i, magic[i]);
    }
    header.setUint8(4, version == 1 ? 0 : 0x30 + version);
    header.setUint32(20, 0); // isutcnt
    header.setUint32(24, 0); // isstdcnt
    header.setUint32(28, leapCount);
    header.setUint32(32, blockTimes.length);
    header.setUint32(36, types.length);
    header.setUint32(40, chars.length);
    builder.add(header.buffer.asUint8List());
    for (var time in blockTimes) {
      var data = ByteData(timeSize);
      if (timeSize == 8) {
        data.setInt32(0, (time / 0x100000000).floor());
        data.setUint32(4, time & 0xFFFFFFFF);
      } else {
        data.setInt32(0, time);
      }
      builder.add(data.buffer.asUint8List());
    }
    builder.add(blockTypes);
    for (var i = 0; i < types.length; i++) {
      var data = ByteData(6);
      data.setInt32(0, types[i].$1);
      data.setUint8(4, types[i].$2 ? 1 : 0);
      data.setUint8(5, abbreviationIndexes[i]);
      builder.add(data.buffer.asUint8List());
    }
    builder.add(chars);
    // Leap second records: (time, correction).
    for (var i = 0; i < leapCount; i++) {
      builder.add(List.filled(timeSize + 4, 0));
    }
    return builder.takeBytes();
  }

  var builder = BytesBuilder();
  // The version 1 block only has the transitions that fit in 32 bits.
  var v1Times = <int>[];
  var v1Types = <int>[];
  for (var i = 0; i < times.length; i++) {
    if (times[i] >= -0x80000000 && times[i] <= 0x7FFFFFFF) {
      v1Times.add(times[i]);
      v1Types.add(transitionTypes[i]);
    }
  }
  builder.add(block(4, v1Times, v1Types));
  if (version >= 2) {
    builder.add(block(8, times, transitionTypes));
    builder.add(ascii.encode('\n${footer ?? ''}\n'));
  }
  return builder.takeBytes();
}

// A London-like zone: LMT, then GMT/BST transitions, then a POSIX rule.
Uint8List _londonLike({int version = 2, int leapCount = 0}) => _buildTzif(
      version: version,
      leapCount: leapCount,
      times: [
        -576460752303423488, // -2**59, the "big bang"
        _epochSeconds(1847, 12, 1, 0, 1, 15),
        _epochSeconds(1996, 3, 31, 1),
        _epochSeconds(1996, 10, 27, 1),
        _epochSeconds(1997, 3, 30, 1),
      ],
      transitionTypes: [0, 1, 2, 1, 2],
      types: [(-75, false, 'LMT'), (0, false, 'GMT'), (3600, true, 'BST')],
      footer: version >= 2 ? 'GMT0BST,M3.5.0/1,M10.5.0' : null,
    );

void TzifParse() {
  var data = parseTzif(_londonLike(leapCount: 2));
  expect(data.version, 2);
  expect(data.transitionTimes.first, -576460752303423488);
  expect(data.transitionTimes.length, 5);
  expect(data.transitionTypes, [0, 1, 2, 1, 2]);
  expect(data.localTimeTypes.map((t) => t.abbreviation), ['LMT', 'GMT', 'BST']);
  expect(data.localTimeTypes.map((t) => t.utOffset), [-75, 0, 3600]);
  expect(data.localTimeTypes.map((t) => t.isDst), [false, false, true]);
  expect(data.footer, 'GMT0BST,M3.5.0/1,M10.5.0');
}

void TzifParseVersion1() {
  var data = parseTzif(_londonLike(version: 1));
  expect(data.version, 1);
  // The big bang and 1847 don't fit in 32 bits.
  expect(data.transitionTimes.length, 3);
  expect(data.footer, isNull);
}

void TzifRejectsMalformedData() {
  expect(() => parseTzif(Uint8List.fromList(ascii.encode('TZxf'))),
      throwsFormatException);
  var truncated = _londonLike().sublist(0, 60);
  expect(() => parseTzif(truncated), throwsFormatException);
}

void TzifZone() {
  var zone = tzifToDateTimeZone('Test/London', parseTzif(_londonLike()));
  expect(zone.id, 'Test/London');
  var lmt = zone.getZoneInterval(_utc(1800, 1, 1));
  expect(lmt.name, 'LMT');
  expect(lmt.hasStart, isFalse);
  expect(lmt.wallOffset, Offset(-75));
  expect(
      lmt.end, Instant.fromEpochSeconds(_epochSeconds(1847, 12, 1, 0, 1, 15)));

  var gmt = zone.getZoneInterval(_utc(1990, 1, 1));
  expect(gmt.name, 'GMT');
  expect(gmt.end, _utc(1996, 3, 31, 1));

  var bst = zone.getZoneInterval(_utc(1996, 7, 1));
  expect(bst.name, 'BST');
  expect(bst.wallOffset, Offset.hours(1));
  expect(bst.savings, Offset.hours(1));
  expect(bst.standardOffset, Offset.zero);

  // After the last transition, the footer: last Sunday in March 01:00 UTC
  // to last Sunday in October 01:00 UTC.
  var later = zone.getZoneInterval(_utc(2024, 7, 1));
  expect(later.name, 'BST');
  expect(later.start, _utc(2024, 3, 31, 1));
  expect(later.end, _utc(2024, 10, 27, 1));
  // The transition into the tail is seamless.
  expect(zone.getZoneInterval(_utc(1997, 7, 1)).start, _utc(1997, 3, 30, 1));
  expect(zone.getZoneInterval(_utc(1997, 7, 1)).end, _utc(1997, 10, 26, 1));
}

void TzifZoneVersion1WithoutFooter() {
  var zone = tzifToDateTimeZone('Test/V1', parseTzif(_londonLike(version: 1)));
  // The last transition's type continues forever.
  expect(zone.getZoneInterval(_utc(2024, 1, 1)).name, 'BST');
  expect(zone.getZoneInterval(_utc(2024, 1, 1)).hasEnd, isFalse);
}

void TzifSavingsUseTheStandardOffsetInEffect() {
  var zone = tzifToDateTimeZone(
      'Test/Savings',
      parseTzif(_buildTzif(
        times: [
          _epochSeconds(1940, 1, 1),
          _epochSeconds(1950, 1, 1),
          _epochSeconds(1960, 1, 1),
          _epochSeconds(1970, 1, 1),
        ],
        // DST first (before any standard time), then standard +2, then
        // double summer time, then standard +3.
        transitionTypes: [1, 0, 2, 3],
        types: [
          (7200, false, 'STD'),
          (10800, true, 'DST'),
          (14400, true, 'DDST'),
          (10800, false, 'NEW'),
        ],
        footer: '<NEW>-3',
      )));
  var first = zone.getZoneInterval(_utc(1945, 1, 1));
  expect(first.name, 'DST');
  expect(first.savings, Offset.hours(1)); // the next standard offset is +2
  var doubleSummer = zone.getZoneInterval(_utc(1965, 1, 1));
  expect(doubleSummer.savings, Offset.hours(2));
  var fixed = zone.getZoneInterval(_utc(2000, 1, 1));
  expect(fixed.name, 'NEW');
  expect(fixed.savings, Offset.zero);
  expect(fixed.hasEnd, isFalse);
}

void TzifWithoutTransitions() {
  var zone = tzifToDateTimeZone(
      'Etc/Test',
      parseTzif(_buildTzif(
          types: [(19800, false, '+0530')], footer: '<+0530>-5:30')));
  expect(zone, isA<FixedDateTimeZone>());
  expect(zone.getUtcOffset(Instant.unixEpoch), Offset.hoursAndMinutes(5, 30));
  expect(zone.getZoneInterval(Instant.unixEpoch).name, '+0530');
}

// ---------------------------------------------------------------------------
// Android tzdata bundle
// ---------------------------------------------------------------------------

Uint8List _buildAndroidBundle(String version, Map<String, Uint8List> zones) {
  var names = zones.keys.toList()..sort();
  var indexOffset = 24;
  var dataOffset = indexOffset + 52 * names.length;
  var index = BytesBuilder();
  var data = BytesBuilder();
  for (var name in names) {
    var entry = ByteData(52);
    var nameBytes = ascii.encode(name);
    for (var i = 0; i < nameBytes.length; i++) {
      entry.setUint8(i, nameBytes[i]);
    }
    entry.setInt32(40, data.length);
    entry.setInt32(44, zones[name]!.length);
    entry.setInt32(48, 0);
    index.add(entry.buffer.asUint8List());
    data.add(zones[name]!);
  }
  var header = ByteData(24);
  var headerText = ascii.encode('tzdata$version');
  for (var i = 0; i < headerText.length; i++) {
    header.setUint8(i, headerText[i]);
  }
  header.setInt32(12, indexOffset);
  header.setInt32(16, dataOffset);
  header.setInt32(20, dataOffset + data.length);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(index.takeBytes())
        ..add(data.takeBytes()))
      .takeBytes();
}

void AndroidBundle() {
  var bundle = AndroidTzdataBundle.parse(_buildAndroidBundle('2025b', {
    'Europe/London': _londonLike(),
    'Etc/UTC': _buildTzif(types: [(0, false, 'UTC')], footer: 'UTC0'),
  }));
  expect(bundle.version, '2025b');
  expect(bundle.ids, ['Etc/UTC', 'Europe/London']);
  expect(
      bundle.loadZone('Europe/London')!.getZoneInterval(_utc(2024, 7, 1)).name,
      'BST');
  expect(
      bundle.loadZone('Etc/UTC')!.getUtcOffset(Instant.unixEpoch), Offset.zero);
  expect(bundle.loadZone('Europe/Paris'), isNull);

  var backend = AndroidTzdataBackend('/test/tzdata', bundle);
  expect(backend.isSupported, isTrue);
  expect(backend.dataVersion, '2025b');
  expect(backend.getIds(), ['Etc/UTC', 'Europe/London']);
}

void AndroidBundleRejectsMalformedData() {
  expect(
      () => AndroidTzdataBundle.parse(
          Uint8List.fromList(ascii.encode('notatzdatafile-at-all-really'))),
      throwsFormatException);
  var bundle = _buildAndroidBundle('2025b', {'A/B': _londonLike()});
  // Entry length beyond the end of the file.
  expect(() => AndroidTzdataBundle.parse(bundle.sublist(0, bundle.length - 10)),
      throwsFormatException);
}

// ---------------------------------------------------------------------------
// The TZif directory backend, over a synthetic zoneinfo directory
// ---------------------------------------------------------------------------

void TzifDirectory() {
  var temp = io.Directory.systemTemp.createTempSync('zoneinfo');
  try {
    var root = temp.path.replaceAll(r'\', '/');
    void write(String name, List<int> bytes) {
      var file = io.File('$root/$name');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    }

    var london = _londonLike();
    var utc = _buildTzif(types: [(0, false, 'UTC')], footer: 'UTC0');
    write('Europe/London', london);
    write('GB', london);
    write('Etc/UTC', utc);
    write('posix/Europe/London', london); // excluded
    write('right/Europe/London', london); // excluded
    write('localtime', london); // excluded
    write('posixrules', london); // excluded
    write('Factory', utc); // excluded
    write('zone.tab', ascii.encode('GB\t+513030-0000731\tEurope/London\n'));
    write('tzdata.zi', ascii.encode('# version 2025z\nZ Europe/London 0 -\n'));

    var backend = TzifDirectoryBackend(root);
    expect(backend.description, 'TZif ($root)');
    expect(backend.isSupported, isTrue);
    expect(backend.getIds(), ['Etc/UTC', 'Europe/London', 'GB']);
    expect(backend.dataVersion, '2025z');
    expect(
        backend.loadZone('GB')!.getZoneInterval(_utc(2024, 7, 1)).name, 'BST');
    expect(backend.loadZone('posix/Europe/London'), isNull);
    expect(backend.loadZone('zone.tab'), isNull);

    var source = SystemDateTimeZoneSource.withBackend(backend);
    expect(source.versionId, 'System: TZif ($root) 2025z');
  } finally {
    temp.deleteSync(recursive: true);
  }
}

void TzifDirectoryMissing() {
  var backend = TzifDirectoryBackend('/no/such/zoneinfo/directory');
  expect(backend.isSupported, isFalse);
  expect(backend.getIds(), isEmpty);
  expect(backend.dataVersion, isNull);
}

// ---------------------------------------------------------------------------
// Windows: compare every zone with the OS itself
// ---------------------------------------------------------------------------

Future WindowsSourceMatchesTheOperatingSystem() async {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;
  var backend = WindowsSystemTimeZoneBackend();
  expect(backend.isSupported, isTrue);
  var ids = backend.getIds();
  expect(ids, contains('UTC'));
  expect(ids, contains('Pacific Standard Time'));

  var start = _utc(1970, 1, 1);
  var end = _utc(2041, 1, 1);
  var mismatches = <String>[];
  var checks = 0;
  for (var id in ids) {
    var zone = backend.loadZone(id)!;
    expect(zone.id, id);
    var instants = <int>{};
    // Every 13 days at varying times of day, and hourly around New Year.
    for (var ms = start.epochMilliseconds;
        ms < end.epochMilliseconds;
        ms += 13 * 86400000 + 3600000) {
      instants.add(ms);
    }
    for (var year = 1970; year <= 2040; year++) {
      var newYear = DateTime.utc(year).millisecondsSinceEpoch;
      for (var hour = -30; hour <= 30; hour++) {
        instants.add(newYear + hour * 3600000);
      }
    }
    // Hourly around each transition we produce.
    var transitions = _transitions(zone, start, end);
    for (var transition in transitions) {
      for (var hour = -3; hour <= 3; hour++) {
        instants.add(transition.epochMilliseconds + hour * 3600000);
      }
    }
    var sorted = instants.toList()..sort();
    var expected = windowsSystemOffsets(id, sorted)!;
    for (var i = 0; i < sorted.length; i++) {
      checks++;
      var instant = Instant.fromEpochMilliseconds(sorted[i]);
      var actual = zone.getUtcOffset(instant).inSeconds;
      if (actual != expected[i]) {
        mismatches.add('$id at $instant: ours ${actual ~/ 60} min, '
            'Windows ${expected[i] ~/ 60} min');
      }
    }
    // Windows makes transitions at 24:00 one millisecond early (as
    // 23:59:59.999); we deliberately don't. Check that's the only
    // difference just before each transition.
    var before = [for (var t in transitions) t.epochMilliseconds - 1];
    var beforeExpected = windowsSystemOffsets(id, before)!;
    for (var i = 0; i < before.length; i++) {
      var instant = Instant.fromEpochMilliseconds(before[i]);
      var actual = zone.getUtcOffset(instant).inSeconds;
      var after = zone.getUtcOffset(transitions[i]).inSeconds;
      if (actual != beforeExpected[i] && after != beforeExpected[i]) {
        mismatches.add('$id just before ${transitions[i]}: ours '
            '${actual ~/ 60} min, Windows ${beforeExpected[i] ~/ 60} min');
      }
    }
  }
  print('Windows: compared ${ids.length} zones at $checks instants; '
      '${mismatches.length} mismatches');
  for (var mismatch in mismatches.take(50)) {
    print('  $mismatch');
  }
  expect(mismatches, isEmpty);
}

Future WindowsNamesVersionAndDefault() async {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;
  var source = SystemDateTimeZoneSource();
  expect(source.description, 'Windows');
  expect(source.versionId, startsWith('System: Windows'));

  var info = readWindowsTimeZoneInfo()!;
  expect(source.systemDefaultId, info.keyName);
  var provider = await DateTimeZoneProviders.system;
  expect((await provider.getSystemDefault()).id, info.keyName);

  // The standard name is the localized display name the OS reports.
  var local = await provider.getZoneOrNull(info.keyName);
  // Every interval in 2025: Windows' Morocco, for one, is on its 'daylight'
  // time all year except during Ramadan.
  var names = local!
      .getZoneIntervals(Interval(_utc(2025, 1, 1), _utc(2026, 1, 1)))
      .map((i) => i.name);
  // CI's non-English Windows leg localizes only the current zone's names
  // (SetDynamicTimeZoneInformation); the per-zone names Windows enumerates
  // stay in the installed language there. On real localized Windows both are
  // localized, so only compare them when that simulation isn't in use.
  if (io.Platform.environment['TIME_MACHINE_EXPECT_LOCALIZED_WINDOWS'] != '1') {
    expect(names, contains(info.standardName));
  }

  var pacific = await provider['Pacific Standard Time'];
  var winter = pacific.getZoneInterval(_utc(2025, 1, 15));
  var summer = pacific.getZoneInterval(_utc(2025, 7, 15));
  expect(winter.wallOffset, Offset.hours(-8));
  expect(summer.wallOffset, Offset.hours(-7));
  expect(summer.savings, Offset.hours(1));
  expect(winter.name, isNot(summer.name));
  expect(winter.start, _utc(2024, 11, 3, 9));
  expect(winter.end, _utc(2025, 3, 9, 10));

  // IANA IDs are accepted (mapped with Windows' ICU, as .NET does), but
  // not listed; an ID neither Windows nor ICU knows is still missing.
  expect((await provider['America/Los_Angeles']).id, 'America/Los_Angeles');
  expect(provider.ids, isNot(contains('America/Los_Angeles')));
  expect(provider['Not/AZone'], throwsA(isA<DateTimeZoneNotFoundError>()));
}

// ---------------------------------------------------------------------------
// Linux: compare every zone with zdump
// ---------------------------------------------------------------------------

final _zdumpLine = RegExp(
    r'^(\S+)\s+\w{3} (\w{3}) +(\d+) (\d\d):(\d\d):(\d\d) (-?\d+) UT = .* (\S+) isdst=(\d) gmtoff=(-?\d+)$');
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

Future TzifSourceMatchesZdump() async {
  if (skipUnless(
      io.Platform.isLinux || io.Platform.isMacOS, 'Linux and macOS only')) {
    return;
  }
  var backend = TzifDirectoryBackend.create();
  if (skipUnless(backend.isSupported, 'No zoneinfo directory')) return;
  var ids = backend.getIds();
  print('${backend.description} ${backend.dataVersion}: ${ids.length} zones; '
      'system default ${backend.systemDefaultId}');
  expect(ids, contains('Europe/London'));
  expect(ids.where((id) => id.startsWith('posix/')), isEmpty);

  // One zdump run for all zones; each output line starts with the zone's
  // path. (-V rather than -v: the same output without the extreme values,
  // which are slow to compute.)
  io.ProcessResult result;
  try {
    result = await io.Process.run('zdump', [
      '-V',
      '-c',
      '1970,2040',
      for (var id in ids) '${backend.directory}$id',
    ]);
  } on io.ProcessException {
    markTestSkipped('zdump is not available');
    return;
  }
  // E.g. an older zdump without -V.
  if (skipUnless(
      result.exitCode == 0, 'zdump failed: ${result.stderr}'.trim())) {
    return;
  }
  var zdumpLines = <String, List<String>>{};
  for (var line in (result.stdout as String).split('\n')) {
    var path = line.split(' ').first;
    if (!path.startsWith(backend.directory)) continue;
    zdumpLines
        .putIfAbsent(path.substring(backend.directory.length), () => [])
        .add(line);
  }

  var from = _utc(1970, 1, 1);
  var to = _utc(2040, 1, 1);
  var mismatches = <String>[];
  var checked = 0;
  var lines = 0;
  var notComparable = <String>[];
  for (var id in ids) {
    var zone = backend.loadZone(id);
    if (zone == null) {
      mismatches.add('$id: failed to load');
      continue;
    }
    // macOS's zdump doesn't evaluate TZ strings with negative transition times
    // (a TZif version 3 extension; e.g. Greenland's
    // '<-02>2<-01>,M3.5.0/-1,M10.5.0/0', changing at 01:00 UTC), so it
    // reports no transitions after the explicit ones. glibc's zdump does.
    if (io.Platform.isMacOS &&
        _usesNegativeTransitionTimes(
            parseTzif(io.File('${backend.directory}$id').readAsBytesSync())
                .footer)) {
      notComparable.add(id);
      continue;
    }
    var zdumpTransitions = <Instant>{};
    for (var line in zdumpLines[id] ?? const <String>[]) {
      var match = _zdumpLine.firstMatch(line.trim());
      if (match == null) continue;
      var year = int.parse(match.group(7)!);
      if (year < 1970 || year >= 2040) continue;
      var instant = Instant.utc(
          year,
          _months.indexOf(match.group(2)!) + 1,
          int.parse(match.group(3)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
          int.parse(match.group(6)!));
      lines++;
      var abbreviation = match.group(8)!;
      var isDst = match.group(9) == '1';
      var offset = int.parse(match.group(10)!);
      var interval = zone.getZoneInterval(instant);
      if (interval.wallOffset.inSeconds != offset ||
          interval.name != abbreviation ||
          (interval.savings != Offset.zero) != isDst) {
        mismatches.add('$id at $instant: ours ${interval.name} '
            '${interval.wallOffset} (savings ${interval.savings}), '
            'zdump $abbreviation $offset isdst=$isDst');
      }
      // zdump prints each transition as a pair: one second before, and at.
      zdumpTransitions.add(instant);
    }
    for (var transition in _transitions(zone, from, to)) {
      checked++;
      if (!zdumpTransitions.contains(transition)) {
        mismatches.add('$id: transition at $transition not reported by zdump');
      }
    }
  }
  print('TZif: compared ${ids.length - notComparable.length} zones with zdump '
      '($lines zdump lines, $checked transitions); '
      '${mismatches.length} mismatches');
  if (notComparable.isNotEmpty) {
    print('Not compared (zdump cannot evaluate their TZ string): '
        '${notComparable.join(', ')}');
  }
  for (var mismatch in mismatches.take(50)) {
    print('  $mismatch');
  }
  expect(mismatches, isEmpty);
}

/// Whether a TZ string has negative transition times (a TZif version 3
/// extension), e.g. 'M3.5.0/-1'.
bool _usesNegativeTransitionTimes(String? tz) =>
    tz != null && RegExp(r',[^,]*/-').hasMatch(tz);

Future TzifSourceDefaultsAndProvider() async {
  if (skipUnless(
      io.Platform.isLinux || io.Platform.isMacOS, 'Linux and macOS only')) {
    return;
  }
  if (skipUnless(
      SystemDateTimeZoneSource.isSupported, 'No system time zone data')) {
    return;
  }
  var provider = await DateTimeZoneProviders.system;
  var london = await provider['Europe/London'];
  expect(london.getZoneInterval(_utc(2024, 7, 1)).name, 'BST');
  expect(london.getZoneInterval(_utc(2024, 7, 1)).start, _utc(2024, 3, 31, 1));
  expect(provider['Not/AZone'], throwsA(isA<DateTimeZoneNotFoundError>()));
  var source = SystemDateTimeZoneSource();
  var defaultId = source.systemDefaultId;
  if (defaultId != null) {
    expect(await source.getIds(), contains(defaultId));
  }
}
