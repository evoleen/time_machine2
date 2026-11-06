// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import 'time_machine_testing.dart';

void main() {
  test('StartOfMonth', StartOfMonth);
  test('EndOfMonth', EndOfMonth);
  test('DayOfMonth', DayOfMonth);
  parameterizedTest(
      'NextOrSame',
      [
        [
          2014,
          8,
          18,
          DayOfWeek.monday,
          2014,
          8,
          18
        ].options(customDescriptionBuilder: (_, __, ___) => 'Same day-of-week'),
        [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 19],
        [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 24],
        [2014, 8, 31, DayOfWeek.monday, 2014, 9, 1]
            .options(customDescriptionBuilder: (_, __, ___) => 'Wrap month'),
      ],
      NextOrSame,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'PreviousOrSame',
      [
        [
          2014,
          8,
          18,
          DayOfWeek.monday,
          2014,
          8,
          18
        ].options(customDescriptionBuilder: (_, __, ___) => 'Same day-of-week'),
        [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 12],
        [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 17],
        [2014, 8, 1, DayOfWeek.thursday, 2014, 7, 31]
            .options(customDescriptionBuilder: (_, __, ___) => 'Wrap month'),
      ],
      PreviousOrSame,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'Next',
      [
        [
          2014,
          8,
          18,
          DayOfWeek.monday,
          2014,
          8,
          25
        ].options(customDescriptionBuilder: (_, __, ___) => 'Same day-of-week'),
        [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 19],
        [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 24],
        [2014, 8, 31, DayOfWeek.monday, 2014, 9, 1]
            .options(customDescriptionBuilder: (_, __, ___) => 'Wrap month'),
      ],
      Next,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'Previous',
      [
        [
          2014,
          8,
          18,
          DayOfWeek.monday,
          2014,
          8,
          11
        ].options(customDescriptionBuilder: (_, __, ___) => 'Same day-of-week'),
        [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 12],
        [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 17],
        [2014, 8, 1, DayOfWeek.thursday, 2014, 7, 31]
            .options(customDescriptionBuilder: (_, __, ___) => 'Wrap month'),
      ],
      Previous,
      customDescriptionBuilder: describeArguments);
  test('Month_Valid', Month_Valid);
  test('Month_InvalidAdjustment', Month_InvalidAdjustment);
  test('IsoDayOfWeekAdjusters_Invalid', IsoDayOfWeekAdjusters_Invalid);
}

void StartOfMonth() {
  var start = LocalDate(2014, 6, 27);
  var end = LocalDate(2014, 6, 1);
  expect(end, DateAdjusters.startOfMonth(start));
}

void EndOfMonth() {
  var start = LocalDate(2014, 6, 27);
  var end = LocalDate(2014, 6, 30);
  expect(end, DateAdjusters.endOfMonth(start));
}

void DayOfMonth() {
  var start = LocalDate(2014, 6, 27);
  var end = LocalDate(2014, 6, 19);
  var adjuster = DateAdjusters.dayOfMonth(19);
  expect(end, adjuster(start));
}

void NextOrSame(int year, int month, int day, DayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay) {
  LocalDate start = LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.nextOrSame(dayOfWeek));
  LocalDate expected = LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

void PreviousOrSame(int year, int month, int day, DayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay) {
  LocalDate start = LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.previousOrSame(dayOfWeek));
  LocalDate expected = LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

void Next(int year, int month, int day, DayOfWeek dayOfWeek, int expectedYear,
    int expectedMonth, int expectedDay) {
  LocalDate start = LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.next(dayOfWeek));
  LocalDate expected = LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

void Previous(int year, int month, int day, DayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay) {
  LocalDate start = LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.previous(dayOfWeek));
  LocalDate expected = LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

void Month_Valid() {
  var adjuster = DateAdjusters.month(2);
  var start = LocalDate(2017, 8, 21, CalendarSystem.julian);
  var actual = start.adjust(adjuster);
  var expected = LocalDate(2017, 2, 21, CalendarSystem.julian);
  expect(expected, actual);
}

void Month_InvalidAdjustment() {
  var adjuster = DateAdjusters.month(2);
  var start = LocalDate(2017, 8, 30, CalendarSystem.julian);
  // Assert.Throws<ArgumentOutOfRangeException>(() => start.With(adjuster));
  expect(() => start.adjust(adjuster), throwsRangeError);
}

void IsoDayOfWeekAdjusters_Invalid() {
  var invalid = const DayOfWeek(10); //IsoDayOfWeek) 10;
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.Next(invalid));
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.NextOrSame(invalid));
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.Previous(invalid));
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.PreviousOrSame(invalid));
  expect(() => DateAdjusters.next(invalid), throwsRangeError);
  expect(() => DateAdjusters.nextOrSame(invalid), throwsRangeError);
  expect(() => DateAdjusters.previous(invalid), throwsRangeError);
  expect(() => DateAdjusters.previousOrSame(invalid), throwsRangeError);
}
