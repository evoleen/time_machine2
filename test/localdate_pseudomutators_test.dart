// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import 'time_machine_testing.dart';

void main() {
  test('PlusYear_Simple', PlusYear_Simple);
  test('PlusYear_LeapToNonLeap', PlusYear_LeapToNonLeap);
  test('PlusYear_LeapToLeap', PlusYear_LeapToLeap);
  test('PlusMonth_Simple', PlusMonth_Simple);
  test('PlusMonth_ChangingYear', PlusMonth_ChangingYear);
  test('PlusMonth_WithTruncation', PlusMonth_WithTruncation);
  test('PlusDays_SameMonth', PlusDays_SameMonth);
  test('PlusDays_MonthBoundary', PlusDays_MonthBoundary);
  test('PlusDays_YearBoundary', PlusDays_YearBoundary);
  test('PlusDays_EndOfFebruary_InLeapYear', PlusDays_EndOfFebruary_InLeapYear);
  test('PlusDays_EndOfFebruary_NotInLeapYear',
      PlusDays_EndOfFebruary_NotInLeapYear);
  test('PlusDays_LargeValue', PlusDays_LargeValue);
  test('PlusWeeks_Simple', PlusWeeks_Simple);
  parameterizedTest(
      'PlusDays_OutOfRange',
      [
        [-9998, 1, 1, -1],
        [-9996, 1, 1, -1000],
        [9999, 12, 31, 1],
        [9997, 12, 31, 1000],
        [2000, 1, 1, Platform.int32MaxValue],
        [1, 1, 1, Platform.int32MinValue],
      ],
      PlusDays_OutOfRange,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'Next',
      [
        [10, DayOfWeek.wednesday, 16],
        [10, DayOfWeek.friday, 11],
        [10, DayOfWeek.thursday, 17],
        [11, DayOfWeek.wednesday, 16],
        [11, DayOfWeek.thursday, 17],
        [11, DayOfWeek.friday, 18],
        [11, DayOfWeek.saturday, 12],
        [11, DayOfWeek.sunday, 13],
        [12, DayOfWeek.friday, 18],
        [13, DayOfWeek.friday, 18],
      ],
      Next,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'Next_InvalidArgument',
      [
        [0],
        [-1],
        [8],
      ],
      Next_InvalidArgument,
      customDescriptionBuilder: describeArguments,
      skip:
          'Never ran before #17 (no @Test): a Dart int is not a DayOfWeek, which C# casts');
  parameterizedTest(
      'Previous',
      [
        [10, DayOfWeek.wednesday, 9],
        [10, DayOfWeek.friday, 4],
        [10, DayOfWeek.thursday, 3],
        [11, DayOfWeek.wednesday, 9],
        [11, DayOfWeek.thursday, 10],
        [11, DayOfWeek.friday, 4],
        [11, DayOfWeek.saturday, 5],
        [11, DayOfWeek.sunday, 6],
        [12, DayOfWeek.friday, 11],
        [13, DayOfWeek.friday, 11],
      ],
      Previous,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'Previous_InvalidArgument',
      [
        [0],
        [-1],
        [8],
      ],
      Previous_InvalidArgument,
      customDescriptionBuilder: describeArguments,
      skip:
          'Never ran before #17 (no @Test): a Dart int is not a DayOfWeek, which C# casts');
  test('With', With);
}

void PlusYear_Simple() {
  LocalDate start = LocalDate(2011, 6, 26);
  LocalDate expected = LocalDate(2016, 6, 26);
  expect(expected, start.addYears(5));

  expected = LocalDate(2006, 6, 26);
  expect(expected, start.addYears(-5));
}

void PlusYear_LeapToNonLeap() {
  LocalDate start = LocalDate(2012, 2, 29);
  LocalDate expected = LocalDate(2013, 2, 28);
  expect(expected, start.addYears(1));

  expected = LocalDate(2011, 2, 28);
  expect(expected, start.addYears(-1));
}

void PlusYear_LeapToLeap() {
  LocalDate start = LocalDate(2012, 2, 29);
  LocalDate expected = LocalDate(2016, 2, 29);
  expect(expected, start.addYears(4));
}

void PlusMonth_Simple() {
  LocalDate start = LocalDate(2012, 4, 15);
  LocalDate expected = LocalDate(2012, 8, 15);
  expect(expected, start.addMonths(4));
}

void PlusMonth_ChangingYear() {
  LocalDate start = LocalDate(2012, 10, 15);
  LocalDate expected = LocalDate(2013, 2, 15);
  expect(expected, start.addMonths(4));
}

void PlusMonth_WithTruncation() {
  LocalDate start = LocalDate(2011, 1, 30);
  LocalDate expected = LocalDate(2011, 2, 28);
  expect(expected, start.addMonths(1));
}

void PlusDays_SameMonth() {
  LocalDate start = LocalDate(2011, 1, 15);
  LocalDate expected = LocalDate(2011, 1, 23);
  expect(expected, start.addDays(8));

  expected = LocalDate(2011, 1, 7);
  expect(expected, start.addDays(-8));
}

void PlusDays_MonthBoundary() {
  LocalDate start = LocalDate(2011, 1, 26);
  LocalDate expected = LocalDate(2011, 2, 3);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusDays_YearBoundary() {
  LocalDate start = LocalDate(2011, 12, 26);
  LocalDate expected = LocalDate(2012, 1, 3);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusDays_EndOfFebruary_InLeapYear() {
  LocalDate start = LocalDate(2012, 2, 26);
  LocalDate expected = LocalDate(2012, 3, 5);
  expect(expected, start.addDays(8));
  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusDays_EndOfFebruary_NotInLeapYear() {
  LocalDate start = LocalDate(2011, 2, 26);
  LocalDate expected = LocalDate(2011, 3, 6);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusDays_LargeValue() {
  LocalDate start = LocalDate(2013, 2, 26);
  LocalDate expected = LocalDate(2015, 2, 26);
  expect(expected, start.addDays(365 * 2));
}

void PlusWeeks_Simple() {
  LocalDate start = LocalDate(2011, 4, 2);
  LocalDate expectedForward = LocalDate(2011, 4, 23);
  LocalDate expectedBackward = LocalDate(2011, 3, 12);
  expect(expectedForward, start.addWeeks(3));
  expect(expectedBackward, start.addWeeks(-3));
}

void PlusDays_OutOfRange(int year, int month, int day, int days) {
  var start = LocalDate(year, month, day);
  TestHelper.AssertOverflow<int, LocalDate>(start.addDays, days);
}

// Each test case gives a day-of-month in November 2011 and a target 'next day of week';
// the result is the next day-of-month in November 2011 with that target day.
// The tests are picked somewhat arbitrarily...
void Next(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult) {
  LocalDate start = LocalDate(2011, 11, dayOfMonth);
  LocalDate target = start.next(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.monthOfYear);
  expect(target.dayOfMonth, expectedResult);
}

void Next_InvalidArgument(DayOfWeek targetDayOfWeek) {
  LocalDate start = LocalDate(2011, 1, 1);
  expect(() => start.next(targetDayOfWeek), throwsRangeError);
}

// Each test case gives a day-of-month in November 2011 and a target 'next day of week';
// the result is the next day-of-month in November 2011 with that target day.
void Previous(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult) {
  LocalDate start = LocalDate(2011, 11, dayOfMonth);
  LocalDate target = start.previous(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.monthOfYear);
  expect(target.dayOfMonth, expectedResult);
}

void Previous_InvalidArgument(DayOfWeek targetDayOfWeek) {
  LocalDate start = LocalDate(2011, 1, 1);
  expect(() => start.previous(targetDayOfWeek), throwsRangeError);
}

// No tests for non-ISO-day-of-week calendars as we don't have any yet.

void With() {
  LocalDate start = LocalDate(2014, 6, 27);
  LocalDate expected = LocalDate(2014, 6, 30);
  expect(expected, start.adjust(DateAdjusters.endOfMonth));
}
