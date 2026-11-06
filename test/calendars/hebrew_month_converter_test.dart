// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';
// import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

void main() {
  parameterizedTest(
      'NonLeapYear',
      [
        [1, 7],
        [2, 8],
        [3, 9],
        [4, 10],
        [5, 11],
        [6, 12],
        [7, 1],
        [8, 2],
        [9, 3],
        [10, 4],
        [11, 5],
        [12, 6],
      ],
      NonLeapYear,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'LeapYear',
      [
        [1, 8],
        [2, 9],
        [3, 10],
        [4, 11],
        [5, 12],
        [6, 13],
        [7, 1],
        [8, 2],
        [9, 3],
        [10, 4],
        [11, 5],
        [12, 6],
        [13, 7],
      ],
      LeapYear,
      customDescriptionBuilder: describeArguments);
}

const int SampleLeapYear = 5502;
const int SampleNonLeapYear = 5501;

// Nisan
// Iyyar
// Sivan
// Tammuz
// Av
// Elul
// Tishri
// Heshvan
// Kislev
// Teveth
// Shevat
// Adar
void NonLeapYear(int scriptural, int civil) {
  expect(scriptural,
      HebrewMonthConverter.civilToScriptural(SampleNonLeapYear, civil));
  expect(civil,
      HebrewMonthConverter.scripturalToCivil(SampleNonLeapYear, scriptural));
}

// Nisan
// Iyyar
// Sivan
// Tammuz
// Av
// Elul
// Tishri
// Heshvan
// Kislev
// Teveth
// Shevat
// Adar I
// Adar II
void LeapYear(int scriptural, int civil) {
  expect(scriptural,
      HebrewMonthConverter.civilToScriptural(SampleLeapYear, civil));
  expect(civil,
      HebrewMonthConverter.scripturalToCivil(SampleLeapYear, scriptural));
}
