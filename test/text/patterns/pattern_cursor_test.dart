// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import '../../time_machine_testing.dart';
import '../text_cursor_test_base_tests.dart';

void main() {
  group('PatternCursorTest', () {
    final fixture = PatternCursorTest();
    parameterizedTest(
        'GetQuotedString_Invalid',
        [
          [
            r"'abc\"
          ].options(customDescriptionBuilder: (_, __, ___) => "Escape at end"),
          ["'abc"].options(
              customDescriptionBuilder: (_, __, ___) => "Missing close quote"),
        ],
        fixture.GetQuotedString_Invalid,
        customDescriptionBuilder: describeArguments);
    parameterizedTest(
        'GetQuotedString_Valid',
        [
          ["'abc'", "abc"],
          ["''", ""],
          [
            "'\"abc\"'",
            "\"abc\""
          ].options(customDescriptionBuilder: (_, __, ___) => "Double quotes"),
          [r"'ab\c'", "abc"].options(
              customDescriptionBuilder: (_, __, ___) => "Escaped backslash"),
          [r"'ab\'c'", "ab'c"].options(
              customDescriptionBuilder: (_, __, ___) => "Escaped close quote"),
        ],
        fixture.GetQuotedString_Valid,
        customDescriptionBuilder: describeArguments);
    test('GetQuotedString_HandlesOtherQuote',
        fixture.GetQuotedString_HandlesOtherQuote);
    test('GetQuotedString_NotAtEnd', fixture.GetQuotedString_NotAtEnd);
    parameterizedTest(
        'GetRepeatCount_Valid',
        [
          ['aaa', 3],
          ['a', 1],
          ['aaadaa', 3],
        ],
        fixture.GetRepeatCount_Valid,
        customDescriptionBuilder: describeArguments);
    test('GetRepeatCount_ExceedsMax', fixture.GetRepeatCount_ExceedsMax);
    parameterizedTest(
        'GetEmbeddedPattern_Valid',
        [
          ['x<HH:mm>y', "HH:mm"]
              .options(customDescriptionBuilder: (_, __, ___) => "Simple"),
          ["x<HH:'T'mm>y", "HH:'T'mm"]
              .options(customDescriptionBuilder: (_, __, ___) => "Quoting"),
          [r"x<HH:\Tmm>y", r"HH:\Tmm"]
              .options(customDescriptionBuilder: (_, __, ___) => "Escaping"),
          [
            'x<a<b>c>y',
            "a<b>c"
          ].options(customDescriptionBuilder: (_, __, ___) => "Simple nesting"),
          ["x<a'<'bc>y", "a'<'bc"].options(
              customDescriptionBuilder: (_, __, ___) =>
                  "Quoted start embedded"),
          ["x<a'>'bc>y", "a'>'bc"].options(
              customDescriptionBuilder: (_, __, ___) => "Quoted end embedded"),
          [r"x<a\<bc>y", r"a\<bc"].options(
              customDescriptionBuilder: (_, __, ___) =>
                  "Escaped start embedded"),
          [r"x<a\>bc>y", r"a\>bc"].options(
              customDescriptionBuilder: (_, __, ___) => "Escaped end embedded"),
        ],
        fixture.GetEmbeddedPattern_Valid,
        customDescriptionBuilder: describeArguments);
    parameterizedTest(
        'GetEmbeddedPattern_Invalid',
        [
          ['x(oops)'].options(
              customDescriptionBuilder: (_, __, ___) =>
                  "Wrong start character"),
          ['x<oops)']
              .options(customDescriptionBuilder: (_, __, ___) => "No end"),
          [r"x<oops\>"]
              .options(customDescriptionBuilder: (_, __, ___) => "Escaped end"),
          ["x<oops'>'"]
              .options(customDescriptionBuilder: (_, __, ___) => "Quoted end"),
          ['x<oops<nested>'].options(
              customDescriptionBuilder: (_, __, ___) =>
                  "Incomplete after nesting"),
        ],
        fixture.GetEmbeddedPattern_Invalid,
        customDescriptionBuilder: describeArguments);
    test('TestConstructor', fixture.TestConstructor);
    test('TestMove', fixture.TestMove);
    test('TestMove_NextPrevious', fixture.TestMove_NextPrevious);
    test('TestMove_invalid', fixture.TestMove_invalid);
  });
}

class PatternCursorTest extends TextCursorTestBase {
  @internal
  @override
  TextCursor MakeCursor(String value) {
    return PatternCursor(value);
  }

  void GetQuotedString_Invalid(String pattern) {
    var cursor = PatternCursor(pattern);
    expect('\'', GetNextCharacter(cursor));
    expect(
        () => cursor.getQuotedString('\''), willThrow<InvalidPatternError>());
  }

  void GetQuotedString_Valid(String pattern, String expected) {
    var cursor = PatternCursor(pattern);
    expect('\'', GetNextCharacter(cursor));
    String actual = cursor.getQuotedString('\'');
    expect(expected, actual);
    expect(cursor.moveNext(), isFalse);
  }

  void GetQuotedString_HandlesOtherQuote() {
    var cursor = PatternCursor('[abc]');
    GetNextCharacter(cursor);
    String actual = cursor.getQuotedString(']');
    expect('abc', actual);
    expect(cursor.moveNext(), isFalse);
  }

  void GetQuotedString_NotAtEnd() {
    var cursor = PatternCursor("'abc'more");
    String openQuote = GetNextCharacter(cursor);
    String actual = cursor.getQuotedString(openQuote);
    expect('abc', actual);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, 4, '\'');

    expect('m', GetNextCharacter(cursor));
  }

  void GetRepeatCount_Valid(String text, int expectedCount) {
    var cursor = PatternCursor(text);
    expect(cursor.moveNext(), isTrue);
    int actual = cursor.getRepeatCount(10);
    expect(expectedCount, actual);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, expectedCount - 1, 'a');
  }

  void GetRepeatCount_ExceedsMax() {
    var cursor = PatternCursor('aaa');
    expect(cursor.moveNext(), isTrue);
    expect(() => cursor.getRepeatCount(2), willThrow<InvalidPatternError>());
  }

  void GetEmbeddedPattern_Valid(String pattern, String expectedEmbedded) {
    var cursor = PatternCursor(pattern);
    cursor.moveNext();
    String embedded = cursor.getEmbeddedPattern();
    expect(expectedEmbedded, embedded);
    TextCursorTestBase.ValidateCurrentCharacter(
        cursor, expectedEmbedded.length + 2, '>');
  }

  void GetEmbeddedPattern_Invalid(String text) {
    var cursor = PatternCursor(text);
    cursor.moveNext();
    expect(() => cursor.getEmbeddedPattern(), willThrow<InvalidPatternError>());
  }
}
