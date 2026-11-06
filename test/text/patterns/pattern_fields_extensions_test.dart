// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

void main() {
  test('IsUsed_NoMatch', IsUsed_NoMatch);
  test('IsUsed_SingleValueMatch', IsUsed_SingleValueMatch);
  test('IsFieldUsed_MultiValueMatch', IsFieldUsed_MultiValueMatch);
  test('AllAreUsed_NoMatch', AllAreUsed_NoMatch);
  test('AllAreUsed_PartialMatch', AllAreUsed_PartialMatch);
  test('AllAreUsed_CompleteMatch', AllAreUsed_CompleteMatch);
  test('AllAreUsed_CompleteMatchWithMore', AllAreUsed_CompleteMatchWithMore);
}

void IsUsed_NoMatch() {
  expect(
      (PatternFields.hours12 | PatternFields.minutes)
          .hasAny(PatternFields.hours24),
      isFalse);
}

void IsUsed_SingleValueMatch() {
  expect(PatternFields.hours24.hasAny(PatternFields.hours24), isTrue);
}

void IsFieldUsed_MultiValueMatch() {
  expect(
      (PatternFields.hours24 | PatternFields.minutes)
          .hasAny(PatternFields.hours24),
      isTrue);
}

void AllAreUsed_NoMatch() {
  expect(
      (PatternFields.hours12 | PatternFields.minutes)
          .hasAll(PatternFields.hours24 | PatternFields.seconds),
      isFalse);
}

void AllAreUsed_PartialMatch() {
  expect(
      (PatternFields.hours12 | PatternFields.minutes)
          .hasAll(PatternFields.hours12 | PatternFields.seconds),
      isFalse);
}

void AllAreUsed_CompleteMatch() {
  expect(
      (PatternFields.hours12 | PatternFields.minutes)
          .hasAll(PatternFields.hours12 | PatternFields.minutes),
      isTrue);
}

void AllAreUsed_CompleteMatchWithMore() {
  expect(
      (PatternFields.hours24 | PatternFields.minutes | PatternFields.hours12)
          .hasAll(PatternFields.hours24 | PatternFields.minutes),
      isTrue);
}
