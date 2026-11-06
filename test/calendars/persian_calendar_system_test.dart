// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

/// Tests for PersianYearMonthDayCalculator via the Persian CalendarSystem.
Future main() async {
  await runTests();
}

@Test()
@SkipMe('.NET only: compares with the BCL PersianCalendar')
// [Category('Slow')]
void BclThroughHistory() {
  // Calendar bcl = BclCalendars.Persian;
  // CalendarSystem noda = BclCalendars.CalendarSystemForCalendar(bcl);
  // Note: Noda Time stops in 9377, whereas the BCL goes into the start of 9378. This is because
  // Noda Time ensures that the whole year is valid.
  // BclEquivalenceHelper.AssertEquivalent(bcl, noda);
}

/// <summary>
/// Use the examples in Calendrical Calculations for where the arithmetic calendar differs
/// from the astronomical one.
/// </summary>
@Test()
@TestCase([1016, 1637, 21])
@TestCase([1049, 1670, 21])
@TestCase([1078, 1699, 21])
@TestCase([1082, 1703, 22])
@TestCase([1111, 1732, 21])
@TestCase([1115, 1736, 21])
@TestCase([1144, 1765, 21])
@TestCase([1177, 1798, 21])
@TestCase([1210, 1831, 22])
@TestCase([1243, 1864, 21])
@TestCase([1404, 2025, 20])
@TestCase([1437, 2058, 20])
@TestCase([1532, 2153, 20])
@TestCase([1565, 2186, 20])
@TestCase([1569, 2190, 20])
@TestCase([1598, 2219, 21])
@TestCase([1631, 2252, 20])
@TestCase([1660, 2281, 20])
@TestCase([1664, 2285, 20])
@TestCase([1693, 2314, 21])
@TestCase([1697, 2318, 21])
@TestCase([1726, 2347, 21])
@TestCase([1730, 2351, 21])
@TestCase([1759, 2380, 20])
@TestCase([1763, 2384, 20])
@TestCase([1788, 2409, 20])
@TestCase([1792, 2413, 20])
@TestCase([1796, 2417, 20])
void ArithmeticExamples(
    int persianYear, int gregorianYear, int gregorianDayOfMarch) {
  var persian = LocalDate(persianYear, 1, 1, CalendarSystem.persianArithmetic);
  var gregorian = persian.withCalendar(CalendarSystem.gregorian);
  expect(gregorianYear, gregorian.year);
  expect(3, gregorian.monthOfYear);
  expect(gregorianDayOfMarch, gregorian.dayOfMonth);
}

/// The arithmetic calendar repeats every 2820 years, including the years before 474.
/// A floored modulo puts year 24 in the same position in the cycle as year 2844.
@Test()
void ArithmeticLeapYearsRepeatEvery2820Years() {
  var calendar = CalendarSystem.persianArithmetic;
  for (var year = calendar.minYear; year + 2820 <= calendar.maxYear; year++) {
    expect(calendar.isLeapYear(year), calendar.isLeapYear(year + 2820),
        reason: 'Year $year');
  }
}

/// Leap years and new year's days before 474 use the same cycle as later years.
@Test()
@TestCase([24, false, 645, 21])
@TestCase([25, true, 646, 21])
@TestCase([57, false, 678, 21])
@TestCase([58, true, 679, 21])
@TestCase([441, false, 1062, 21])
@TestCase([442, true, 1063, 21])
void ArithmeticYearsBefore474(
    int persianYear, bool leap, int gregorianYear, int gregorianDayOfMarch) {
  expect(CalendarSystem.persianArithmetic.isLeapYear(persianYear), leap);
  var gregorian = LocalDate(persianYear, 1, 1, CalendarSystem.persianArithmetic)
      .withCalendar(CalendarSystem.gregorian);
  expect(
      gregorian,
      LocalDate(
          gregorianYear, 3, gregorianDayOfMarch, CalendarSystem.gregorian));
}

@Test()
void ArithmeticYearEndBefore474() {
  var calendar = CalendarSystem.persianArithmetic;
  var lastDayOfYear24 = LocalDate(24, 12, 29, calendar);
  expect(lastDayOfYear24.addDays(1), LocalDate(25, 1, 1, calendar));
  expect(() {
    LocalDate(24, 12, 30, calendar);
  }, throwsRangeError);

  var leapDayOfYear25 = LocalDate(25, 12, 30, calendar);
  expect(leapDayOfYear25.addDays(1), LocalDate(26, 1, 1, calendar));
}
