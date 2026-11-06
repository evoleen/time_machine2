// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import '../time_machine_testing.dart';

void main() {
  parameterizedTest(
      'IsoPattern',
      [
        ['2017-02-23T16:40:50.123456789'],
        ['2017-02-23T16:40:50.123'],
        ['2017-02-23T16:40:50'],
        ['2017-02-23T16:40'],
      ],
      IsoPattern,
      customDescriptionBuilder: describeArguments);
  test('Format_NoValidPattern', Format_NoValidPattern);
  test('Parse', Parse);
  test('Build_Empty', Build_Empty);
  test('Enumerators', Enumerators, skip: 'unimplemented');
}

// See https://github.com/nodatime/nodatime/issues/607
void IsoPattern(String text) {
  // We assert that the text round-trips. If it does, it's
  // reasonable to assume it parsed correctly...
  var shortPattern = LocalDateTimePattern.createWithInvariantCulture(
      "uuuu'-'MM'-'dd'T'HH':'mm");
  var pattern = (CompositePatternBuilder<LocalDateTime>()
        ..add(LocalDateTimePattern.extendedIso, (_) => true)
        ..add(shortPattern,
            (ldt) => ldt.secondOfMinute == 0 && ldt.nanosecondOfSecond == 0))
      .build();
  var value = pattern.parse(text).value;
  String formatted = pattern.format(value);
  expect(text, formatted);
}

void Format_NoValidPattern() {
  var pattern = (CompositePatternBuilder<LocalDate>()
        ..add(LocalDatePattern.iso, (_) => false)
        ..add(
            LocalDatePattern.createWithInvariantCulture('yyyy'), (_) => false))
      .build();

  expect(() => pattern.format(LocalDate(2017, 1, 1)),
      willThrow<FormatException>());
}

void Parse() {
  var pattern = (CompositePatternBuilder<LocalDate>()
        ..add(LocalDatePattern.iso, (_) => true)
        ..add(
            LocalDatePattern.createWithInvariantCulture('yyyy'), (_) => false))
      .build();
  expect(pattern.parse('2017-03-20').success, isTrue);
  expect(pattern.parse('2017-03').success, isFalse);
  expect(pattern.parse('2017').success, isTrue);
}

void Build_Empty() {
  var pattern = CompositePatternBuilder<LocalDate>();
  expect(() => pattern.build(), throwsStateError);
}

void Enumerators() {
  var pattern1 = LocalDatePattern.iso;
  var pattern2 = LocalDatePattern.createWithInvariantCulture('yyyy');

  var builder = (CompositePatternBuilder<LocalDate>()
        ..add(pattern1, (_) => true)
        ..add(pattern2, (_) => false))
      .build();

  /*
      CollectionAssert.AreEqual(new[] { pattern1, pattern2 }, builder.ToList());
      CollectionAssert.AreEqual(new[] { pattern1, pattern2 }, builder.OfType<LocalDatePattern>().ToList());
  */

  expect([pattern1, pattern2], (builder as dynamic)._patterns); //.ToList());
  expect(
      [pattern1, pattern2],
      (builder as dynamic)._patterns as List<
          LocalDatePattern>); // builder.OfType<LocalDatePattern>().ToList());
}
