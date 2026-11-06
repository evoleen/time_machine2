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
  test('PlusDays_Simple', PlusDays_Simple);
  test('PlusDays_MonthBoundary', PlusDays_MonthBoundary);
  test('PlusDays_YearBoundary', PlusDays_YearBoundary);
  test('PlusDays_EndOfFebruary_InLeapYear', PlusDays_EndOfFebruary_InLeapYear);
  test('PlusDays_EndOfFebruary_NotInLeapYear',
      PlusDays_EndOfFebruary_NotInLeapYear);
  test('PlusWeeks_Simple', PlusWeeks_Simple);
  test('PlusHours_Simple', PlusHours_Simple);
  test('PlusHours_CrossingDayBoundary', PlusHours_CrossingDayBoundary);
  test('PlusHours_CrossingYearBoundary', PlusHours_CrossingYearBoundary);
  test('PlusMinutes_Simple', PlusMinutes_Simple);
  test('PlusSeconds_Simple', PlusSeconds_Simple);
  test('PlusMilliseconds_Simple', PlusMilliseconds_Simple);
  test('PlusTicks_Simple', PlusTicks_Simple);
  test('PlusTicks_Long', PlusTicks_Long);
  test('PlusNanoseconds_Simple', PlusNanoseconds_Simple);
  test('PlusTicks_CrossingDay', PlusTicks_CrossingDay);
  test('Plus_FullPeriod', Plus_FullPeriod);
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
  test('Operator_MethodEquivalents', Operator_MethodEquivalents);
  test('With_TimeAdjuster', With_TimeAdjuster);
  test('With_DateAdjuster', With_DateAdjuster);
  parameterizedTest(
      'PlusHours_Overflow',
      [
        [-9998, 1, 1, -1],
        [9999, 12, 31, 24],
        [1970, 1, 1, Platform.int64MaxValue],
        [1970, 1, 1, Platform.int64MinValue],
      ],
      PlusHours_Overflow,
      customDescriptionBuilder: describeArguments);
}

void PlusYear_Simple() {
  LocalDateTime start = LocalDateTime(2011, 6, 26, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2016, 6, 26, 12, 15, 8);
  expect(expected, start.addYears(5));

  expected = LocalDateTime(2006, 6, 26, 12, 15, 8);
  expect(expected, start.addYears(-5));
}

void PlusYear_LeapToNonLeap() {
  LocalDateTime start = LocalDateTime(2012, 2, 29, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2013, 2, 28, 12, 15, 8);
  expect(expected, start.addYears(1));

  expected = LocalDateTime(2011, 2, 28, 12, 15, 8);
  expect(expected, start.addYears(-1));
}

void PlusYear_LeapToLeap() {
  LocalDateTime start = LocalDateTime(2012, 2, 29, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2016, 2, 29, 12, 15, 8);
  expect(expected, start.addYears(4));
}

void PlusMonth_Simple() {
  LocalDateTime start = LocalDateTime(2012, 4, 15, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2012, 8, 15, 12, 15, 8);
  expect(expected, start.addMonths(4));
}

void PlusMonth_ChangingYear() {
  LocalDateTime start = LocalDateTime(2012, 10, 15, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2013, 2, 15, 12, 15, 8);
  expect(expected, start.addMonths(4));
}

void PlusMonth_WithTruncation() {
  LocalDateTime start = LocalDateTime(2011, 1, 30, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2011, 2, 28, 12, 15, 8);
  expect(expected, start.addMonths(1));
}

void PlusDays_Simple() {
  LocalDateTime start = LocalDateTime(2011, 1, 15, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2011, 1, 23, 12, 15, 8);
  expect(expected, start.addDays(8));

  expected = LocalDateTime(2011, 1, 7, 12, 15, 8);
  expect(expected, start.addDays(-8));
}

void PlusDays_MonthBoundary() {
  LocalDateTime start = LocalDateTime(2011, 1, 26, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2011, 2, 3, 12, 15, 8);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusDays_YearBoundary() {
  LocalDateTime start = LocalDateTime(2011, 12, 26, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2012, 1, 3, 12, 15, 8);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusDays_EndOfFebruary_InLeapYear() {
  LocalDateTime start = LocalDateTime(2012, 2, 26, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2012, 3, 5, 12, 15, 8);
  expect(expected, start.addDays(8));
  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusDays_EndOfFebruary_NotInLeapYear() {
  LocalDateTime start = LocalDateTime(2011, 2, 26, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2011, 3, 6, 12, 15, 8);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

void PlusWeeks_Simple() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  LocalDateTime expectedForward = LocalDateTime(2011, 4, 23, 12, 15, 8);
  LocalDateTime expectedBackward = LocalDateTime(2011, 3, 12, 12, 15, 8);
  expect(expectedForward, start.addWeeks(3));
  expect(expectedBackward, start.addWeeks(-3));
}

void PlusHours_Simple() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  LocalDateTime expectedForward = LocalDateTime(2011, 4, 2, 14, 15, 8);
  LocalDateTime expectedBackward = LocalDateTime(2011, 4, 2, 10, 15, 8);
  expect(expectedForward, start.addHours(2));
  expect(expectedBackward, start.addHours(-2));
}

void PlusHours_CrossingDayBoundary() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2011, 4, 3, 8, 15, 8);
  expect(expected, start.addHours(20));
  expect(start, start.addHours(20).addHours(-20));
}

void PlusHours_CrossingYearBoundary() {
  // Christmas day + 10 days and 1 hour
  LocalDateTime start = LocalDateTime(2011, 12, 25, 12, 15, 8);
  LocalDateTime expected = LocalDateTime(2012, 1, 4, 13, 15, 8);
  expect(start.addHours(241), expected);
  expect(start.addHours(241).addHours(-241), start);
}

// Having tested that hours cross boundaries correctly, the other time unit
// tests are straightforward
void PlusMinutes_Simple() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  LocalDateTime expectedForward = LocalDateTime(2011, 4, 2, 12, 17, 8);
  LocalDateTime expectedBackward = LocalDateTime(2011, 4, 2, 12, 13, 8);
  expect(expectedForward, start.addMinutes(2));
  expect(expectedBackward, start.addMinutes(-2));
}

void PlusSeconds_Simple() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  LocalDateTime expectedForward = LocalDateTime(2011, 4, 2, 12, 15, 18);
  LocalDateTime expectedBackward = LocalDateTime(2011, 4, 2, 12, 14, 58);
  expect(expectedForward, start.addSeconds(10));
  expect(expectedBackward, start.addSeconds(-10));
}

void PlusMilliseconds_Simple() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8, ms: 300);
  LocalDateTime expectedForward = LocalDateTime(2011, 4, 2, 12, 15, 8, ms: 700);
  LocalDateTime expectedBackward =
      LocalDateTime(2011, 4, 2, 12, 15, 7, ms: 900);
  expect(expectedForward, start.addMilliseconds(400));
  expect(expectedBackward, start.addMilliseconds(-400));
}

void PlusTicks_Simple() {
  LocalDate date = LocalDate(2011, 4, 2);
  LocalTime startTime = LocalTime(12, 15, 8,
      ns: 300 * TimeConstants.nanosecondsPerMillisecond + 7500 * 100);
  LocalTime expectedForwardTime = LocalTime(12, 15, 8,
      ns: 301 * TimeConstants.nanosecondsPerMillisecond + 1500 * 100);
  LocalTime expectedBackwardTime = LocalTime(12, 15, 8,
      ns: 300 * TimeConstants.nanosecondsPerMillisecond + 3500 * 100);
  expect(
      date.at(expectedForwardTime), (date.at(startTime)).addMicroseconds(400));
  expect(date.at(expectedBackwardTime),
      (date.at(startTime)).addMicroseconds(-400));
}

void PlusTicks_Long() {
  expect(TimeConstants.microsecondsPerDay > Platform.int32MaxValue, isTrue);
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  LocalDateTime expectedForward = LocalDateTime(2011, 4, 3, 12, 15, 8);
  LocalDateTime expectedBackward = LocalDateTime(2011, 4, 1, 12, 15, 8);
  expect(
      expectedForward, start.addMicroseconds(TimeConstants.microsecondsPerDay));
  expect(expectedBackward,
      start.addMicroseconds(-TimeConstants.microsecondsPerDay));
}

void PlusNanoseconds_Simple() {
  // Just use the ticks values
  LocalDate date = LocalDate(2011, 4, 2);
  LocalTime startTime = LocalTime(12, 15, 8,
      ns: 300 * TimeConstants.nanosecondsPerMillisecond + 7500 * 100);
  LocalTime expectedForwardTime = LocalTime(12, 15, 8,
      ns: 300 * TimeConstants.nanosecondsPerMillisecond + 7540 * 100);
  LocalTime expectedBackwardTime = LocalTime(12, 15, 8,
      ns: 300 * TimeConstants.nanosecondsPerMillisecond + 7460 * 100);
  expect(
      date.at(expectedForwardTime), (date.at(startTime)).addNanoseconds(4000));
  expect(date.at(expectedBackwardTime),
      (date.at(startTime)).addNanoseconds(-4000));
}

void PlusTicks_CrossingDay() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  LocalDateTime expectedForward = LocalDateTime(2011, 4, 3, 12, 15, 8);
  LocalDateTime expectedBackward = LocalDateTime(2011, 4, 1, 12, 15, 8);
  expect(
      expectedForward, start.addNanoseconds(TimeConstants.nanosecondsPerDay));
  expect(
      expectedBackward, start.addNanoseconds(-TimeConstants.nanosecondsPerDay));
}

void Plus_FullPeriod() {
  LocalDateTime start = LocalDateTime(2011, 4, 2, 12, 15, 8);
  var builder = PeriodBuilder()
    ..years = 1
    ..months = 2
    ..weeks = 3
    ..days = 4
    ..hours = 5
    ..minutes = 6
    ..seconds = 7
    ..milliseconds = 8
    ..microseconds = 9
    ..nanoseconds = 11;

  var period = builder.build();
  var actual = start.add(period);
  var expected = LocalDateTime(2012, 6, 27, 17, 21, 15).addNanoseconds(8009011);

  expect(expected, actual,
      reason:
          "${expected.toString('yyyy-MM-dd HH:mm:ss.fffffffff')} != ${actual.toString('yyyy-MM-dd HH:mm:ss.fffffffff')}");
}

// Each test case gives a day-of-month in November 2011 and a target 'next day of week';
// the result is the next day-of-month in November 2011 with that target day.
// The tests are picked somewhat arbitrarily...
void Next(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult) {
  LocalDateTime start =
      LocalDateTime(2011, 11, dayOfMonth, 15, 25, 30).addNanoseconds(123456789);
  LocalDateTime target = start.next(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.monthOfYear);
  expect(start.clockTime, target.clockTime);
  expect(target.dayOfMonth, expectedResult);
}

void Next_InvalidArgument(DayOfWeek targetDayOfWeek) {
  LocalDateTime start =
      LocalDateTime(2011, 1, 1, 15, 25, 30).addNanoseconds(123456789);
  expect(() => start.next(targetDayOfWeek), throwsRangeError);
}

// Each test case gives a day-of-month in November 2011 and a target 'next day of week';
// the result is the next day-of-month in November 2011 with that target day.
void Previous(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult) {
  LocalDateTime start =
      LocalDateTime(2011, 11, dayOfMonth, 15, 25, 30).addNanoseconds(123456789);
  LocalDateTime target = start.previous(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.monthOfYear);
  expect(target.dayOfMonth, expectedResult);
}

void Previous_InvalidArgument(DayOfWeek targetDayOfWeek) {
  LocalDateTime start =
      LocalDateTime(2011, 1, 1, 15, 25, 30).addNanoseconds(123456789);
  expect(() => start.previous(targetDayOfWeek), throwsRangeError);
}

// No tests for non-ISO-day-of-week calendars as we don't have any yet.

void Operator_MethodEquivalents() {
  LocalDateTime start =
      LocalDateTime(2011, 1, 1, 15, 25, 30).addNanoseconds(123456789);
  Period period = const Period(hours: 1) + const Period(days: 1);
  LocalDateTime end = start + period;
  expect(start + period, LocalDateTime.plus(start, period));
  expect(start + period, start.add(period));
  expect(start - period, LocalDateTime.minus(start, period));
  expect(start - period, start.subtract(period));
  // expect(period, end - start);
  expect(period, LocalDateTime.difference(end, start));
  expect(period, end.periodSince(start));
}

void With_TimeAdjuster() {
  LocalDateTime start =
      LocalDateTime(2014, 6, 27, 12, 15, 8).addNanoseconds(123456789);
  LocalDateTime expected = LocalDateTime(2014, 6, 27, 12, 15, 8);
  expect(expected, start.adjustTime(TimeAdjusters.truncateToSecond));
}

void With_DateAdjuster() {
  LocalDateTime start =
      LocalDateTime(2014, 6, 27, 12, 5, 8).addNanoseconds(123456789);
  LocalDateTime expected =
      LocalDateTime(2014, 6, 30, 12, 5, 8).addNanoseconds(123456789);
  expect(expected, start.adjustDate(DateAdjusters.endOfMonth));
}

void PlusHours_Overflow(int year, int month, int day, int hours) {
  TestHelper.AssertOverflow<int, LocalDateTime>(
      LocalDateTime(year, month, day, 0, 0, 01).addHours, hours);
}
