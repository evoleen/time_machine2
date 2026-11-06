// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';

void main() {
  test('GetMaxYearOfEra', GetMaxYearOfEra);
  test('GetMinYearOfEra', GetMinYearOfEra);
  test('GetAbsoluteYear', GetAbsoluteYear);
  test('EraProperty', EraProperty);
}

CalendarSystem Julian = CalendarSystem.julian;

void GetMaxYearOfEra() {
  LocalDate date = LocalDate(Julian.maxYear, 1, 1, Julian);
  expect(date.yearOfEra, Julian.getMaxYearOfEra(Era.common));
  expect(Era.common, date.era);
  date = LocalDate(Julian.minYear, 1, 1, Julian);
  expect(Julian.minYear, date.year);
  expect(date.yearOfEra, Julian.getMaxYearOfEra(Era.beforeCommon));
  expect(Era.beforeCommon, date.era);
}

void GetMinYearOfEra() {
  LocalDate date = LocalDate(1, 1, 1, Julian);
  expect(date.yearOfEra, Julian.getMinYearOfEra(Era.common));
  expect(Era.common, date.era);
  date = LocalDate(0, 1, 1, Julian);
  expect(date.yearOfEra, Julian.getMinYearOfEra(Era.beforeCommon));
  expect(Era.beforeCommon, date.era);
}

void GetAbsoluteYear() {
  expect(1, Julian.getAbsoluteYear(1, Era.common));
  expect(0, Julian.getAbsoluteYear(1, Era.beforeCommon));
  expect(-1, Julian.getAbsoluteYear(2, Era.beforeCommon));
  expect(Julian.maxYear,
      Julian.getAbsoluteYear(Julian.getMaxYearOfEra(Era.common), Era.common));
  expect(
      Julian.minYear,
      Julian.getAbsoluteYear(
          Julian.getMaxYearOfEra(Era.beforeCommon), Era.beforeCommon));
}

void EraProperty() {
  CalendarSystem calendar = CalendarSystem.julian;
  LocalDateTime startOfEra =
      LocalDateTime(1, 1, 1, 0, 0, 0, calendar: calendar);
  expect(Era.common, startOfEra.era);
  expect(Era.beforeCommon, startOfEra.addMicroseconds(-1).era);
}
