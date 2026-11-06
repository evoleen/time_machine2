// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import 'time_machine_testing.dart';

void main() {
  parameterizedTest(
      'GetMonthsInYear_Valid',
      [
        [-9998],
        [9999],
      ],
      GetMonthsInYear_Valid,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GetMonthsInYear_Invalid',
      [
        [-9999],
        [10000],
      ],
      GetMonthsInYear_Invalid,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GetDaysInMonth_Valid',
      [
        [-9998, 1],
        [9999, 12],
      ],
      GetDaysInMonth_Valid,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GetDaysInMonth_Invalid',
      [
        [-9999, 1],
        [1, 0],
        [1, 13],
        [10000, 1],
      ],
      GetDaysInMonth_Invalid,
      customDescriptionBuilder: describeArguments);
  test('GetDaysInMonth_Hebrew', GetDaysInMonth_Hebrew);
  parameterizedTest(
      'IsLeapYear_Valid',
      [
        [-9998],
        [9999],
      ],
      IsLeapYear_Valid,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'IsLeapYear_Invalid',
      [
        [-9999],
        [10000],
      ],
      IsLeapYear_Invalid,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GetAbsoluteYear_ValidCe',
      [
        [1],
        [9999],
      ],
      GetAbsoluteYear_ValidCe,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GetAbsoluteYear_ValidBce',
      [
        [1],
        [9999],
      ],
      GetAbsoluteYear_ValidBce,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GetAbsoluteYear_InvalidCe',
      [
        [0],
        [10000],
      ],
      GetAbsoluteYear_InvalidCe,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GetAbsoluteYear_InvalidBce',
      [
        [0],
        [10000],
      ],
      GetAbsoluteYear_InvalidBce,
      customDescriptionBuilder: describeArguments);
  test('GetAbsoluteYear_InvalidEra', GetAbsoluteYear_InvalidEra);
  test('GetMinYearOfEra_InvalidEra', GetMinYearOfEra_InvalidEra);
  test('GetMaxYearOfEra_InvalidEra', GetMaxYearOfEra_InvalidEra);
}

final CalendarSystem Iso = CalendarSystem.iso;

void GetMonthsInYear_Valid(int year) {
  TestHelper.AssertValid<int, int>(Iso.getMonthsInYear, year);
}

void GetMonthsInYear_Invalid(int year) {
  TestHelper.AssertOutOfRange<int, int>(Iso.getMonthsInYear, year);
}

void GetDaysInMonth_Valid(int year, int month) {
  TestHelper.AssertValid2(Iso.getDaysInMonth, year, month);
}

void GetDaysInMonth_Invalid(int year, int month) {
  TestHelper.AssertOutOfRange2<int, int, int>(Iso.getDaysInMonth, year, month);
}

void GetDaysInMonth_Hebrew() {
  TestHelper.AssertValid2<int, int, int>(
      CalendarSystem.hebrewCivil.getDaysInMonth, 5402, 13); // Leap year
  TestHelper.AssertOutOfRange2<int, int, int>(
      CalendarSystem.hebrewCivil.getDaysInMonth, 5401, 13); // Not a leap year
}

void IsLeapYear_Valid(int year) {
  TestHelper.AssertValid<int, bool>(Iso.isLeapYear, year);
}

void IsLeapYear_Invalid(int year) {
  TestHelper.AssertOutOfRange<int, bool>(Iso.isLeapYear, year);
}

void GetAbsoluteYear_ValidCe(int year) {
  TestHelper.AssertValid2<int, Era, int>(Iso.getAbsoluteYear, year, Era.common);
}

void GetAbsoluteYear_ValidBce(int year) {
  TestHelper.AssertValid2<int, Era, int>(
      Iso.getAbsoluteYear, year, Era.beforeCommon);
}

void GetAbsoluteYear_InvalidCe(int year) {
  TestHelper.AssertOutOfRange2<int, Era, int>(
      Iso.getAbsoluteYear, year, Era.common);
}

void GetAbsoluteYear_InvalidBce(int year) {
  TestHelper.AssertOutOfRange2<int, Era, int>(
      Iso.getAbsoluteYear, year, Era.beforeCommon);
}

void GetAbsoluteYear_InvalidEra() {
  TestHelper.AssertInvalid2<int, Era, int>(
      Iso.getAbsoluteYear, 1, Era.annoPersico);
}

// @Test()
// void GetAbsoluteYear_NullEra()
// {
//   Era i;
//   TestHelper.AssertArgumentNull2<int, Era, int>(Iso.getAbsoluteYear, 1, i);
// }

// @Test()
// void GetMinYearOfEra_NullEra()
// {
//   Era i;
//   TestHelper.AssertArgumentNull<Era, int>(Iso.getMinYearOfEra, i);
// }

void GetMinYearOfEra_InvalidEra() {
  TestHelper.AssertInvalid<Era, int>(Iso.getMinYearOfEra, Era.annoPersico);
}

// @Test()
// void GetMaxYearOfEra_NullEra()
// {
//   Era i;
//   TestHelper.AssertArgumentNull<Era, int>(Iso.getMaxYearOfEra, i);
// }

void GetMaxYearOfEra_InvalidEra() {
  TestHelper.AssertInvalid<Era, int>(Iso.getMaxYearOfEra, Era.annoPersico);
}
