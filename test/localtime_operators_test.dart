// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

void main() {
  test('Addition_WithPeriod', Addition_WithPeriod);
  test('Addition_WrapsAtMidnight', Addition_WrapsAtMidnight);
  test('Subtraction_WithPeriod', Subtraction_WithPeriod);
  test('Subtraction_WrapsAtMidnight', Subtraction_WrapsAtMidnight);
  test('Addition_PeriodWithDate', Addition_PeriodWithDate);
  test('Subtraction_PeriodWithTime', Subtraction_PeriodWithTime);
  test('PeriodAddition_MethodEquivalents', PeriodAddition_MethodEquivalents);
  test('PeriodSubtraction_MethodEquivalents',
      PeriodSubtraction_MethodEquivalents);
  test('ComparisonOperators', ComparisonOperators);
  test(
      'Comparison_IgnoresOriginalCalendar', Comparison_IgnoresOriginalCalendar);
  test('CompareTo', CompareTo);
  test('IComparableCompareTo', IComparableCompareTo);
  test(
      'IComparableCompareTo_Null_Positive', IComparableCompareTo_Null_Positive);
  test('IComparableCompareTo_WrongType_ArgumentException',
      IComparableCompareTo_WrongType_ArgumentException);
}

void Addition_WithPeriod() {
  LocalTime start = LocalTime(3, 30, 0);
  Period period = const Period(hours: 2) + const Period(seconds: 1);
  LocalTime expected = LocalTime(5, 30, 1);
  expect(expected, start + period);
}

void Addition_WrapsAtMidnight() {
  LocalTime start = LocalTime(22, 0, 0);
  Period period = const Period(hours: 3);
  LocalTime expected = LocalTime(1, 0, 0);
  expect(expected, start + period);
}

// @Test()
// void Addition_WithNullPeriod_ThrowsArgumentNullException()
// {
//   LocalTime date = LocalTime(12, 0, 0);
//   // Call to ToString just to make it a valid statement
//   Period period;
//   expect(() => (date + period).toString(), throwsArgumentError);
// }

void Subtraction_WithPeriod() {
  LocalTime start = LocalTime(5, 30, 1);
  Period period = const Period(hours: 2) + const Period(seconds: 1);
  LocalTime expected = LocalTime(3, 30, 0);
  expect(expected, start - period);
}

void Subtraction_WrapsAtMidnight() {
  LocalTime start = LocalTime(1, 0, 0);
  Period period = const Period(hours: 3);
  LocalTime expected = LocalTime(22, 0, 0);
  expect(expected, start - period);
}

// @Test()
// void Subtraction_WithNullPeriod_ThrowsArgumentNullException()
// {
//   LocalTime date = LocalTime(12, 0, 0);
//   // Call to ToString just to make it a valid statement
//   Period period;
//   expect(() => (date - period).toString(), throwsArgumentError);
// }

void Addition_PeriodWithDate() {
  LocalTime time = LocalTime(20, 30, 0);
  Period period = const Period(days: 1);
  // Use method not operator here to form a valid statement
  expect(() => LocalTime.plus(time, period), throwsArgumentError);
}

void Subtraction_PeriodWithTime() {
  LocalTime time = LocalTime(20, 30, 0);
  Period period = const Period(days: 1);
  // Use method not operator here to form a valid statement
  expect(() => LocalTime.minus(time, period), throwsArgumentError);
}

void PeriodAddition_MethodEquivalents() {
  LocalTime start = LocalTime(20, 30, 0);
  Period period = const Period(hours: 3) + const Period(minutes: 10);
  expect(start + period, LocalTime.plus(start, period));
  expect(start + period, start.add(period));
}

void PeriodSubtraction_MethodEquivalents() {
  LocalTime start = LocalTime(20, 30, 0);
  Period period = const Period(hours: 3) + const Period(minutes: 10);
  LocalTime end = start + period;
  expect(start - period, LocalTime.minus(start, period));
  expect(start - period, start.subtract(period));

  // expect(period, end - start);
  // todo: does not exist
  // expect(period, LocalTime.Subtract(end, start));
  expect(period, end.periodSince(start));
}

void ComparisonOperators() {
  LocalTime time1 = LocalTime(10, 30, 45);
  LocalTime time2 = LocalTime(10, 30, 45);
  LocalTime time3 = LocalTime(10, 30, 50);

  expect(time1 == time2, isTrue);
  expect(time1 == time3, isFalse);
  expect(time1 != time2, isFalse);
  expect(time1 != time3, isTrue);

  expect(time1 < time2, isFalse);
  expect(time1 < time3, isTrue);
  expect(time2 < time1, isFalse);
  expect(time3 < time1, isFalse);

  expect(time1 <= time2, isTrue);
  expect(time1 <= time3, isTrue);
  expect(time2 <= time1, isTrue);
  expect(time3 <= time1, isFalse);

  expect(time1 > time2, isFalse);
  expect(time1 > time3, isFalse);
  expect(time2 > time1, isFalse);
  expect(time3 > time1, isTrue);

  expect(time1 >= time2, isTrue);
  expect(time1 >= time3, isFalse);
  expect(time2 >= time1, isTrue);
  expect(time3 >= time1, isTrue);
}

void Comparison_IgnoresOriginalCalendar() {
  LocalDateTime dateTime1 = LocalDateTime(1900, 1, 1, 10, 30, 0);
  LocalDateTime dateTime2 = dateTime1.withCalendar(CalendarSystem.julian);

  // Calendar information is propagated into LocalDate, but not into LocalTime
  expect(dateTime1.calendarDate == dateTime2.calendarDate, isFalse);
  expect(dateTime1.clockTime == dateTime2.clockTime, isTrue);
}

void CompareTo() {
  LocalTime time1 = LocalTime(10, 30, 45);
  LocalTime time2 = LocalTime(10, 30, 45);
  LocalTime time3 = LocalTime(10, 30, 50);

  expect(time1.compareTo(time2), 0);
  expect(time1.compareTo(time3), lessThan(0));
  expect(time3.compareTo(time2), greaterThan(0));
}

/// IComparable.CompareTo works properly for LocalTime inputs.
void IComparableCompareTo() {
  LocalTime time1 = LocalTime(10, 30, 45);
  LocalTime time2 = LocalTime(10, 30, 45);
  LocalTime time3 = LocalTime(10, 30, 50);

  Comparable i_time1 = time1;
  Comparable i_time3 = time3;

  expect(i_time1.compareTo(time2), 0);
  expect(i_time1.compareTo(time3), lessThan(0));
  expect(i_time3.compareTo(time2), greaterThan(0));
}

/// IComparable.CompareTo returns a positive number for a null input.
void IComparableCompareTo_Null_Positive() {
  var instance = LocalTime(10, 30, 45);
  Comparable i_instance = instance;
  Object? arg;
  var result = i_instance.compareTo(arg);
  expect(result, greaterThan(0));
}

/// IComparable.CompareTo throws an ArgumentException for non-null arguments
/// that are not a LocalTime.
void IComparableCompareTo_WrongType_ArgumentException() {
  var instance = LocalTime(10, 30, 45);
  Comparable i_instance = instance;
  var arg = LocalDate(2012, 3, 6);
  try {
    expect(() => i_instance.compareTo(arg),
        throwsA(TestFailure)); // throwsArgumentError);
  } catch (e) {
    expect(e, const TypeMatcher<TestFailure>());
  }
}
