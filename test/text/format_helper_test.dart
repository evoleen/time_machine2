// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import '../time_machine_testing.dart';

void main() {
  parameterizedTest(
      'TestLeftPad',
      [
        [123, 1, '123'],
        [123, 3, '123'],
        [123, 4, '0123'],
        [123, 5, '00123'],
        [123, 6, '000123'],
        [123, 7, '0000123'],
        [123, 15, '000000000000123'],
        [-123, 1, '-123'],
        [-123, 3, '-123'],
        [-123, 4, '-0123'],
        [-123, 5, '-00123'],
        [-123, 6, '-000123'],
        [-123, 7, '-0000123'],
        [-123, 15, '-000000000000123'],
        [Platform.int32MinValue, 15, '-000002147483648'],
        [Platform.int32MinValue, 10, '-2147483648'],
        [Platform.int32MinValue, 3, '-2147483648'],
      ],
      TestLeftPad,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'TestLeftPadNonNegativeInt64',
      [
        [123, 1, '123'],
        [123, 3, '123'],
        [123, 4, '0123'],
        [123, 5, '00123'],
        [123, 6, '000123'],
        [123, 7, '0000123'],
        [123, 15, '000000000000123'],
      ],
      TestLeftPadNonNegativeInt64,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'TestAppendFraction',
      [
        [1, 3, 3, '001'],
        [1200, 4, 5, '0120'],
        [1, 2, 3, '00'],
      ],
      TestAppendFraction,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'TestAppendFractionTruncate',
      [
        ['x', 1, 3, 3, "x001"],
        ['x', 1200, 4, 5, "x012"],
        ['x', 1, 2, 3, "x"],
        ['1.', 1, 2, 3, "1"],
      ],
      TestAppendFractionTruncate,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'FormatInvariant',
      [
        [0, 'x0'],
        [-1230, 'x-1230'],
        [1230, 'x1230'],
        [Platform.int64MinValue, 'x-9223372036854775808'],
      ],
      FormatInvariant,
      customDescriptionBuilder: describeArguments);
}

void TestLeftPad(int value, int length, String expected) {
  var builder = StringBuffer();
  FormatHelper.leftPad(value, length, builder);
  expect(expected, builder.toString());
}

void TestLeftPadNonNegativeInt64(int value, int length, String expected) {
  var builder = StringBuffer();
  FormatHelper.leftPadNonNegativeInt64(value, length, builder);
  expect(expected, builder.toString());
}

void TestAppendFraction(int value, int length, int scale, String expected) {
  var builder = StringBuffer();
  FormatHelper.appendFraction(value, length, scale, builder);
  expect(expected, builder.toString());
}

void TestAppendFractionTruncate(
    String initial, int value, int length, int scale, String expected) {
  var builder = StringBuffer(initial);
  FormatHelper.appendFractionTruncate(value, length, scale, builder);
  expect(expected, builder.toString());
}

void FormatInvariant(int value, String expected) {
  var builder = StringBuffer('x');
  FormatHelper.formatInvariant(value, builder);
  expect(expected, builder.toString());
}
