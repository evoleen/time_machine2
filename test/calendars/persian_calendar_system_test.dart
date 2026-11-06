// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';
// import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

/// Tests for PersianYearMonthDayCalculator via the Persian CalendarSystem.
void main() {
  test('BclThroughHistory', BclThroughHistory, skip: 'Unsure how to implement');
  parameterizedTest(
      'ArithmeticExamples',
      [
        [1016, 1637, 21],
        [1049, 1670, 21],
        [1078, 1699, 21],
        [1082, 1703, 22],
        [1111, 1732, 21],
        [1115, 1736, 21],
        [1144, 1765, 21],
        [1177, 1798, 21],
        [1210, 1831, 22],
        [1243, 1864, 21],
        [1404, 2025, 20],
        [1437, 2058, 20],
        [1532, 2153, 20],
        [1565, 2186, 20],
        [1569, 2190, 20],
        [1598, 2219, 21],
        [1631, 2252, 20],
        [1660, 2281, 20],
        [1664, 2285, 20],
        [1693, 2314, 21],
        [1697, 2318, 21],
        [1726, 2347, 21],
        [1730, 2351, 21],
        [1759, 2380, 20],
        [1763, 2384, 20],
        [1788, 2409, 20],
        [1792, 2413, 20],
        [1796, 2417, 20],
      ],
      ArithmeticExamples,
      customDescriptionBuilder: describeArguments);
}

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
void ArithmeticExamples(
    int persianYear, int gregorianYear, int gregorianDayOfMarch) {
  var persian = LocalDate(persianYear, 1, 1, CalendarSystem.persianArithmetic);
  var gregorian = persian.withCalendar(CalendarSystem.gregorian);
  expect(gregorianYear, gregorian.year);
  expect(3, gregorian.monthOfYear);
  expect(gregorianDayOfMarch, gregorian.dayOfMonth);
}
