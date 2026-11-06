// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

void main() {
  test('LeapYears', LeapYears);
  test('EraProperty', EraProperty);
  test('AddMonths_BoundaryCondition', AddMonths_BoundaryCondition);
}

void LeapYears() {
  var calendar = CalendarSystem.gregorian;
  expect(calendar.isLeapYear(1900), isFalse);
  expect(calendar.isLeapYear(1901), isFalse);
  expect(calendar.isLeapYear(1904), isTrue);
  expect(calendar.isLeapYear(1996), isTrue);
  expect(calendar.isLeapYear(2000), isTrue);
  expect(calendar.isLeapYear(2100), isFalse);
  expect(calendar.isLeapYear(2400), isTrue);
}

void EraProperty() {
  CalendarSystem calendar = CalendarSystem.gregorian;
  LocalDateTime startOfEra =
      LocalDateTime(1, 1, 1, 0, 0, 0, calendar: calendar);
  expect(Era.common, startOfEra.era);
  expect(Era.beforeCommon, startOfEra.addMicroseconds(-1).era);
}

void AddMonths_BoundaryCondition() {
  var start = LocalDate(2017, 8, 20);
  var end = start.addMonths(-19);
  var expected = LocalDate(2016, 1, 20);
  expect(expected, end);
}
