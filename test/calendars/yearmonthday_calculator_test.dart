// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

// Here the term 'Islamic' only refers to whether the implementation is IslamicYearMonthDayCalculator,
// not whether the calendar itself is based on Islamic scripture.
List<TestCaseData> NonIslamicCalculators = [
  TestCaseData(GregorianYearMonthDayCalculator())..name = 'Gregorian',
  TestCaseData(CopticYearMonthDayCalculator())..name = 'Coptic',
  TestCaseData(JulianYearMonthDayCalculator())..name = 'Julian',
  TestCaseData(HebrewYearMonthDayCalculator(HebrewMonthNumbering.civil))
    ..name = 'HebrewCivil',
  TestCaseData(HebrewYearMonthDayCalculator(HebrewMonthNumbering.scriptural))
    ..name = 'HebrewScriptural',
  TestCaseData(PersianSimple())..name = 'PersianSimple',
  TestCaseData(PersianArithmetic())..name = 'PersianArithmetic',
  TestCaseData(PersianAstronomical())..name = 'PersianAstronomical',
  TestCaseData(UmAlQuraYearMonthDayCalculator())..name = 'UmAlQura',
];

List<TestCaseData> IslamicCalculators = [
  for (var epoch in IslamicEpoch.values)
    for (var leapYearPattern in IslamicLeapYearPattern.values)
      TestCaseData(IslamicYearMonthDayCalculator(leapYearPattern, epoch))
        ..name = 'Islamic;${epoch.name};${leapYearPattern.name}'
];

Iterable<TestCaseData> AllCalculators =
    [NonIslamicCalculators, IslamicCalculators].expand((x) => x);

// Note for tests using TestCaseSource:
// We can't make the parameter of type YearMonthDayCalculator, because that's internal.
// We can't make the method internal, as then it isn't a test. Casting is all we've got.

@Test()
@TestCaseSource(#AllCalculators)
void ValidateStartOfYear1Days(Object calculatorAsObject) {
  var calculator = calculatorAsObject as YearMonthDayCalculator;
  // Some calendars (e.g. Um Al Qura) don't support year 1, so the DaysAtStartOfYear1
  // is somewhat theoretical. (It's still used in such calendars, but only to get a guess
  // as to a year number given a day number.)
  if (calculator.minYear > 1 || calculator.maxYear < 0) {
    return;
  }
  expect(calculator.getStartOfYearInDays(1), calculator.daysAtStartOfYear1);
}

@Test()
@TestCaseSource(#AllCalculators)
void GetYearConsistentWithGetYearDays(Object calculatorAsObject) {
  var calculator = calculatorAsObject as YearMonthDayCalculator;
  for (int year = calculator.minYear; year <= calculator.maxYear; year++) {
    int startOfYearDays = calculator.getStartOfYearInDays(year);

    var tmp = calculator.getYear(startOfYearDays);
    var yearCandidate = tmp[0];
    var dayOfYear = tmp[1];
    expect(yearCandidate, year, reason: 'Start of year $year');
    expect(dayOfYear, 0); // Zero-based...

    tmp = calculator.getYear(startOfYearDays - 1);
    yearCandidate = tmp[0];
    dayOfYear = tmp[1];
    expect(yearCandidate, year - 1, reason: 'End of year ${year - 1}');
    expect(calculator.getDaysInYear(year - 1) - 1, dayOfYear);
  }
}
