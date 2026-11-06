// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

final Iterable<String> SupportedIds = CalendarSystem.ids.toList();
final List<CalendarSystem> SupportedCalendars =
    SupportedIds.map(CalendarSystem.forId).toList();

@Test()
@TestCaseSource(Symbol('SupportedIds'))
void ValidId(String id) {
  expect(CalendarSystem.forId(id), const TypeMatcher<CalendarSystem>());
// Assert.IsInstanceOf<CalendarSystem>(CalendarSystem.ForId(id));
}

@Test()
@TestCaseSource(Symbol('SupportedIds'))
void IdsAreCaseSensitive(String id) {
  expect(() => CalendarSystem.forId(id.toLowerCase()), throwsArgumentError);
// Assert.Throws<KeyNotFoundException>(() => CalendarSystem.ForId(id.ToLowerInvariant()));
}

@Test()
void AllIdsGiveDifferentCalendars() {
  var allCalendars = SupportedIds.map(CalendarSystem.forId).toList();
  expect(SupportedIds.length, allCalendars.toSet().length);
// Assert.AreEqual(SupportedIds.Count(), allCalendars.Distinct().Count());
}

@Test()
void BadId() {
  expect(() => CalendarSystem.forId('bad'), throwsArgumentError);
// Assert.Throws<KeyNotFoundException>(() => CalendarSystem.ForId('bad'));
}

@Test()
void NoSubstrings() {
  // CompareInfo comparison = Culture.invariantCulture.CompareInfo;
  for (var firstId in CalendarSystem.ids) {
    for (var secondId in CalendarSystem.ids) {
      // We're looking for firstId being a substring of secondId, which can only
      // happen if firstId is shorter...
      if (firstId.length >= secondId.length) {
        continue;
      }
      expect(
          stringOrdinalIgnoreCaseCompare(
              firstId, 0, secondId, 0, firstId.length),
          isNot(0),
          reason: '$firstId is a leading substring of $secondId');

      // Assert.AreNotEqual(0, comparison.Compare(firstId, 0, firstId.length, secondId, 0, firstId.length, CompareOptions.IgnoreCase),
      //     '$firstId is a leading substring of $secondId');
    }
  }
}

// Ordinals are similar enough to IDs to keep the tests in this file too...

@Test()
@TestCaseSource(Symbol('SupportedCalendars'))
void ForOrdinal_Roundtrip(CalendarSystem calendar) {
  expect(
      identical(calendar,
          ICalendarSystem.forOrdinal(ICalendarSystem.ordinal(calendar))),
      isTrue);
  // Assert.AreSame(calendar, CalendarSystem.ForOrdinal(calendar.Ordinal));
}

@Test()
@TestCaseSource(Symbol('SupportedCalendars'))
void ForOrdinalUncached_Roundtrip(CalendarSystem calendar) {
  var target =
      ICalendarSystem.forOrdinalUncached(ICalendarSystem.ordinal(calendar));
  expect(identical(calendar, target), isTrue);
  // Assert.AreSame(calendar, CalendarSystem.ForOrdinalUncached(calendar.Ordinal));
}

@Test()
void ForOrdinalUncached_Invalid() {
  expect(() => ICalendarSystem.forOrdinalUncached(const CalendarOrdinal(9999)),
      throwsStateError);
// Assert.Throws<InvalidOperationException>(() => CalendarSystem.ForOrdinalUncached((CalendarOrdinal)9999));
}

// The tests below have no direct Noda Time equivalent: they pin the IDs, names and ordinals to Noda Time's
// values (see CalendarSystem.Id in Noda Time), so that values can be exchanged with Noda Time.

final List<List<Object>> NodaTimeCalendars = [
  ['ISO', 'ISO', CalendarOrdinal.iso, 'Iso'],
  ['Gregorian', 'Gregorian', CalendarOrdinal.gregorian, 'Gregorian'],
  ['Julian', 'Julian', CalendarOrdinal.julian, 'Julian'],
  ['Coptic', 'Coptic', CalendarOrdinal.coptic, 'Coptic'],
  ['Hebrew Civil', 'Hebrew', CalendarOrdinal.hebrewCivil, 'HebrewCivil'],
  [
    'Hebrew Scriptural',
    'Hebrew',
    CalendarOrdinal.hebrewScriptural,
    'HebrewScriptural'
  ],
  ['Persian Simple', 'Persian', CalendarOrdinal.persianSimple, 'PersianSimple'],
  [
    'Persian Arithmetic',
    'Persian',
    CalendarOrdinal.persianArithmetic,
    'PersianArithmetic'
  ],
  [
    'Persian Algorithmic',
    'Persian',
    CalendarOrdinal.persianAstronomical,
    'PersianAstronomical'
  ],
  [
    'Hijri Astronomical-Base15',
    'Hijri',
    CalendarOrdinal.islamicAstronomicalBase15,
    'IslamicAstronomicalBase15'
  ],
  [
    'Hijri Astronomical-Base16',
    'Hijri',
    CalendarOrdinal.islamicAstronomicalBase16,
    'IslamicAstronomicalBase16'
  ],
  [
    'Hijri Astronomical-Indian',
    'Hijri',
    CalendarOrdinal.islamicAstronomicalIndian,
    'IslamicAstronomicalIndian'
  ],
  [
    'Hijri Astronomical-HabashAlHasib',
    'Hijri',
    CalendarOrdinal.islamicAstronomicalHabashAlHasib,
    'IslamicAstronomicalHabashAlHasib'
  ],
  [
    'Hijri Civil-Base15',
    'Hijri',
    CalendarOrdinal.islamicCivilBase15,
    'IslamicCivilBase15'
  ],
  [
    'Hijri Civil-Base16',
    'Hijri',
    CalendarOrdinal.islamicCivilBase16,
    'IslamicCivilBase16'
  ],
  [
    'Hijri Civil-Indian',
    'Hijri',
    CalendarOrdinal.islamicCivilIndian,
    'IslamicCivilIndian'
  ],
  [
    'Hijri Civil-HabashAlHasib',
    'Hijri',
    CalendarOrdinal.islamicCivilHabashAlHasib,
    'IslamicCivilHabashAlHasib'
  ],
  ['Um Al Qura', 'Um Al Qura', CalendarOrdinal.umAlQura, 'UmAlQura'],
  ['Badi', 'Badi', CalendarOrdinal.badi, 'Badi'],
];

@Test()
void IdsMatchNodaTime() {
  expect(CalendarSystem.ids.toSet(),
      NodaTimeCalendars.map((calendar) => calendar[0]).toSet());
  expect(CalendarSystem.ids.length, NodaTimeCalendars.length);
}

@Test()
@TestCaseSource(Symbol('NodaTimeCalendars'))
void IdNameAndOrdinalMatchNodaTime(
    String id, String name, CalendarOrdinal ordinal, String ordinalName) {
  var calendar = CalendarSystem.forId(id);
  expect(calendar.id, id);
  expect(calendar.toString(), id);
  expect(calendar.name, name);
  expect(ICalendarSystem.ordinal(calendar), ordinal);
  expect(identical(ICalendarSystem.forOrdinal(ordinal), calendar), isTrue);
  expect(ordinal.toString(), ordinalName);
  expect(CalendarOrdinal.parse(ordinalName), ordinal);
}

@Test()
void IslamicCalendarIds() {
  expect(
      CalendarSystem.getIslamicCalendar(
              IslamicLeapYearPattern.indian, IslamicEpoch.civil)
          .id,
      'Hijri Civil-Indian');
  expect(
      CalendarSystem.getIslamicCalendar(
              IslamicLeapYearPattern.habashAlHasib, IslamicEpoch.astronomical)
          .id,
      'Hijri Astronomical-HabashAlHasib');
  expect(CalendarSystem.islamicBcl.id, 'Hijri Astronomical-Base16');
}
