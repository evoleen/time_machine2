// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

import 'text_cursor_test_base_tests.dart';

void main() {
  group('ValueCursorTest', () {
    final fixture = ValueCursorTest();
    test('Match_Char', fixture.Match_Char);
    test('Match_String', fixture.Match_String);
    test('Match_StringNotMatched', fixture.Match_StringNotMatched);
    test('Match_StringOverLongStringToMatch',
        fixture.Match_StringOverLongStringToMatch);
    test('MatchCaseInsensitive_MatchAndMove',
        fixture.MatchCaseInsensitive_MatchAndMove);
    test('MatchCaseInsensitive_MatchWithoutMoving',
        fixture.MatchCaseInsensitive_MatchWithoutMoving);
    test('MatchCaseInsensitive_StringNotMatched',
        fixture.MatchCaseInsensitive_StringNotMatched);
    test('MatchCaseInsensitive_StringOverLongStringToMatch',
        fixture.MatchCaseInsensitive_StringOverLongStringToMatch);
    test('Match_StringPartial', fixture.Match_StringPartial);
    test('ParseDigits_TooFewDigits', fixture.ParseDigits_TooFewDigits);
    test('ParseDigits_NoNumber', fixture.ParseDigits_NoNumber);
    test('ParseDigits_Maximum', fixture.ParseDigits_Maximum);
    test(
        'ParseDigits_MaximumMoreDigits', fixture.ParseDigits_MaximumMoreDigits);
    test('ParseDigits_Minimum', fixture.ParseDigits_Minimum);
    test('ParseDigits_MinimumNonDigits', fixture.ParseDigits_MinimumNonDigits);
    test('ParseDigits_NonAscii_NeverMatches',
        fixture.ParseDigits_NonAscii_NeverMatches);
    test(
        'ParseInt64Digits_TooFewDigits', fixture.ParseInt64Digits_TooFewDigits);
    test('ParseInt64Digits_NoNumber', fixture.ParseInt64Digits_NoNumber);
    test('ParseInt64Digits_Maximum', fixture.ParseInt64Digits_Maximum);
    test('ParseInt64Digits_MaximumMoreDigits',
        fixture.ParseInt64Digits_MaximumMoreDigits);
    test('ParseInt64Digits_Minimum', fixture.ParseInt64Digits_Minimum);
    test('ParseInt64Digits_MinimumNonDigits',
        fixture.ParseInt64Digits_MinimumNonDigits);
    test('ParseInt64Digits_NonAscii_NeverMatches',
        fixture.ParseInt64Digits_NonAscii_NeverMatches);
    test('ParseInt64Digits_LargeNumber', fixture.ParseInt64Digits_LargeNumber);
    test('ParseFraction_NonAscii_NeverMatches',
        fixture.ParseFraction_NonAscii_NeverMatches);
    test('ParseInt64_Simple', fixture.ParseInt64_Simple);
    test('ParseInt64_Negative', fixture.ParseInt64_Negative);
    test('ParseInt64_NonNumber', fixture.ParseInt64_NonNumber);
    test(
        'ParseInt64_DoubleNegativeSign', fixture.ParseInt64_DoubleNegativeSign);
    test('ParseInt64_NegativeThenNonDigit',
        fixture.ParseInt64_NegativeThenNonDigit);
    test('ParseInt64_NumberOutOfRange_LowLeadingDigits',
        fixture.ParseInt64_NumberOutOfRange_LowLeadingDigits);
    test('ParseInt64_NumberOutOfRange_HighLeadingDigits',
        fixture.ParseInt64_NumberOutOfRange_HighLeadingDigits);
    test('ParseInt64_NumberOutOfRange_MaxValueLeadingDigits',
        fixture.ParseInt64_NumberOutOfRange_MaxValueLeadingDigits);
    test('ParseInt64_NumberOutOfRange_MinValueLeadingDigits',
        fixture.ParseInt64_NumberOutOfRange_MinValueLeadingDigits);
    test('ParseInt64_MaxValue', fixture.ParseInt64_MaxValue);
    test('ParseInt64_MinValue', fixture.ParseInt64_MinValue);
    test('CompareOrdinal_ExactMatchToEndOfValue',
        fixture.CompareOrdinal_ExactMatchToEndOfValue);
    test('CompareOrdinal_ExactMatchValueContinues',
        fixture.CompareOrdinal_ExactMatchValueContinues);
    test(
        'CompareOrdinal_ValueIsEarlier', fixture.CompareOrdinal_ValueIsEarlier);
    test('CompareOrdinal_ValueIsLater', fixture.CompareOrdinal_ValueIsLater);
    test('CompareOrdinal_LongMatch_EqualToEnd',
        fixture.CompareOrdinal_LongMatch_EqualToEnd);
    test('CompareOrdinal_LongMatch_ValueIsEarlier',
        fixture.CompareOrdinal_LongMatch_ValueIsEarlier);
    test('CompareOrdinal_LongMatch_ValueIsLater',
        fixture.CompareOrdinal_LongMatch_ValueIsLater);
    test('ParseInt64_TooManyDigits', fixture.ParseInt64_TooManyDigits);
    test('TestConstructor', fixture.TestConstructor);
    test('TestMove', fixture.TestMove);
    test('TestMove_NextPrevious', fixture.TestMove_NextPrevious);
    test('TestMove_invalid', fixture.TestMove_invalid);
  });
}

class ValueCursorTest extends TextCursorTestBase {
  void ValidateCurrentCharacter(TextCursor cursor, int expectedCurrentIndex,
          String /*char*/ expectedCurrentCharacter) =>
      TextCursorTestBase.ValidateCurrentCharacter(
          cursor, expectedCurrentIndex, expectedCurrentCharacter);

  @internal
  @override
  TextCursor MakeCursor(String value) {
    return ValueCursor(value);
  }

  void Match_Char() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchSingle('a'), isTrue, reason: "First character");
    expect(value.matchSingle('b'), isTrue, reason: "Second character");
    expect(value.matchSingle('c'), isTrue, reason: "Third character");
    expect(value.moveNext(), isFalse, reason: 'GetNext() end');
  }

  void Match_String() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchText('abc'), isTrue);
    expect(value.moveNext(), isFalse, reason: 'GetNext() end');
  }

  void Match_StringNotMatched() {
    var value = ValueCursor('xabcdef');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchText('abc'), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  void Match_StringOverLongStringToMatch() {
    var value = ValueCursor('x');
    expect(value.moveNext(), isTrue);
    expect(value.matchText('long String'), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  void MatchCaseInsensitive_MatchAndMove() {
    var value = ValueCursor('abcd');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(
        value.matchCaseInsensitive('AbC', Culture.invariant.compareInfo, true),
        isTrue);
    ValidateCurrentCharacter(value, 3, 'd');
  }

  void MatchCaseInsensitive_MatchWithoutMoving() {
    var value = ValueCursor('abcd');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(
        value.matchCaseInsensitive('AbC', Culture.invariant.compareInfo, false),
        isTrue);
    // We're still looking at the start
    ValidateCurrentCharacter(value, 0, 'a');
  }

  void MatchCaseInsensitive_StringNotMatched() {
    var value = ValueCursor('xabcdef');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(
        value.matchCaseInsensitive('abc', Culture.invariant.compareInfo, true),
        isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  void MatchCaseInsensitive_StringOverLongStringToMatch() {
    var value = ValueCursor('x');
    expect(value.moveNext(), isTrue);
    expect(
        value.matchCaseInsensitive(
            'long String', Culture.invariant.compareInfo, true),
        isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  void Match_StringPartial() {
    var value = ValueCursor('abcdef');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchText('abc'), isTrue);
    ValidateCurrentCharacter(value, 3, 'd');
  }

  void ParseDigits_TooFewDigits() {
    var value = ValueCursor('a12b');
    expect(value.moveNext(), isTrue);
    ValidateCurrentCharacter(value, 0, 'a');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(3, 3, out int actual), isFalse);
    expect(value.parseDigits(3, 3), isNull);
    ValidateCurrentCharacter(value, 1, '1');
  }

  void ParseDigits_NoNumber() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isFalse);
    expect(value.parseDigits(1, 2), isNull);
    ValidateCurrentCharacter(value, 0, 'a');
  }

  void ParseDigits_Maximum() {
    var value = ValueCursor('12');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(actual, 12);
  }

  void ParseDigits_MaximumMoreDigits() {
    var value = ValueCursor('1234');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(actual, 12);
    ValidateCurrentCharacter(value, 2, '3');
  }

  void ParseDigits_Minimum() {
    var value = ValueCursor('1');
    value.moveNext();
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(actual, 1);
    TextCursorTestBase.ValidateEndOfString(value);
  }

  void ParseDigits_MinimumNonDigits() {
    var value = ValueCursor('1abc');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(1, actual);
    ValidateCurrentCharacter(value, 1, 'a');
  }

  void ParseDigits_NonAscii_NeverMatches() {
    // Arabic-Indic digits 0 and 1. See
    // http://www.unicode.org/charts/PDF/U0600.pdf
    var value = ValueCursor("\u0660\u0661");
    expect(value.moveNext(), isTrue);
    expect(value.parseDigits(1, 2), isNull);
  }

  void ParseInt64Digits_TooFewDigits() {
    var value = ValueCursor('a12b');
    expect(value.moveNext(), isTrue);
    ValidateCurrentCharacter(value, 0, 'a');
    expect(value.moveNext(), isTrue);
    expect(value.parseInt64Digits(3, 3), isNull);
    ValidateCurrentCharacter(value, 1, '1');
  }

  void ParseInt64Digits_NoNumber() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue);
    expect(value.parseInt64Digits(1, 2), isNull);
    ValidateCurrentCharacter(value, 0, 'a');
  }

  void ParseInt64Digits_Maximum() {
    var value = ValueCursor('12');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(12, actual);
  }

  void ParseInt64Digits_MaximumMoreDigits() {
    var value = ValueCursor('1234');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(12, actual);
    ValidateCurrentCharacter(value, 2, '3');
  }

  void ParseInt64Digits_Minimum() {
    var value = ValueCursor('1');
    value.moveNext();
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(1, actual);
    TextCursorTestBase.ValidateEndOfString(value);
  }

  void ParseInt64Digits_MinimumNonDigits() {
    var value = ValueCursor('1abc');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(1, actual);
    ValidateCurrentCharacter(value, 1, 'a');
  }

  void ParseInt64Digits_NonAscii_NeverMatches() {
    // Arabic-Indic digits 0 and 1. See
    // http://www.unicode.org/charts/PDF/U0600.pdf
    var value = ValueCursor("\u0660\u0661");
    expect(value.moveNext(), isTrue);
    expect(value.parseInt64Digits(1, 2), isNull);
  }

  void ParseInt64Digits_LargeNumber() {
    var value = ValueCursor('9999999999999');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 13), isNotNull);
    expect(actual, 9999999999999 /*L*/);
    // Assert.Greater(9999999999999/*L*/, Utility.int32MaxValue);
    expect(9999999999999 /*L*/, greaterThan(Platform.int32MaxValue));
  }

  void ParseFraction_NonAscii_NeverMatches() {
    // Arabic-Indic digits 0 and 1. See
    // http://www.unicode.org/charts/PDF/U0600.pdf
    var value = ValueCursor("\u0660\u0661");
    expect(value.moveNext(), isTrue);
    expect(value.parseFraction(2, 2, 2), isNull);
  }

  void ParseInt64_Simple() {
    var value = ValueCursor('56x');
    expect(value.moveNext(), isTrue);
    var pr = value.parseInt64<String>('String');
    expect(pr.success, isTrue);
    expect(56 /*L*/, pr.value);
    // Cursor ends up post-number
    expect(2, value.index);
  }

  void ParseInt64_Negative() {
    var value = ValueCursor('-56x');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isTrue);
    expect(-56 /*L*/, result.value);
  }

  void ParseInt64_NonNumber() {
    var value = ValueCursor('xyz');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  void ParseInt64_DoubleNegativeSign() {
    var value = ValueCursor('--10xyz');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  void ParseInt64_NegativeThenNonDigit() {
    var value = ValueCursor('-x');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  void ParseInt64_NumberOutOfRange_LowLeadingDigits() {
    var value = ValueCursor('1000000000000000000000000');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  void ParseInt64_NumberOutOfRange_HighLeadingDigits() {
    var value = ValueCursor('999999999999999999999999');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  void ParseInt64_NumberOutOfRange_MaxValueLeadingDigits() {
    var value = ValueCursor('9223372036854775808');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  void ParseInt64_NumberOutOfRange_MinValueLeadingDigits() {
    var value = ValueCursor('-9223372036854775809');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  void ParseInt64_MaxValue() {
    // Can't parse this in JS
    if (Platform.isWeb) return;

    var value = ValueCursor('9223372036854775807');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isTrue);
    expect(Platform.int64MaxValue, result.value);
  }

  void ParseInt64_MinValue() {
    // Can't parse this in JS
    if (Platform.isWeb) return;

    var value = ValueCursor('-9223372036854775808');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isTrue);
    expect(Platform.int64MinValue, result.value);
  }

  void CompareOrdinal_ExactMatchToEndOfValue() {
    var value = ValueCursor('xabc');
    value.move(1);
    expect(0, value.compareOrdinal('abc'));
    expect(1, value.index); // Cursor hasn't moved
  }

  void CompareOrdinal_ExactMatchValueContinues() {
    var value = ValueCursor('xabc');
    value.move(1);
    expect(0, value.compareOrdinal('ab'));
    expect(1, value.index); // Cursor hasn't moved
  }

  void CompareOrdinal_ValueIsEarlier() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Less(value.CompareOrdinal('mm'), 0);
    expect(value.compareOrdinal('mm'), lessThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  void CompareOrdinal_ValueIsLater() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Greater(value.CompareOrdinal('aa'), 0);
    expect(value.compareOrdinal('aa'), greaterThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  void CompareOrdinal_LongMatch_EqualToEnd() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Less(value.CompareOrdinal('abcd'), 0);
    expect(value.compareOrdinal('abcd'), lessThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  void CompareOrdinal_LongMatch_ValueIsEarlier() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Less(value.CompareOrdinal('cccc'), 0);
    expect(value.compareOrdinal('cccc'), lessThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  void CompareOrdinal_LongMatch_ValueIsLater() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Greater(value.CompareOrdinal('aaaa'), 0);
    expect(value.compareOrdinal('aaaa'), greaterThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  void ParseInt64_TooManyDigits() {
    // We can cope as far as 9223372036854775807, but the trailing 1 causes a failure.
    var value = ValueCursor('92233720368547758071');
    value.move(0);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Assert.IsInstanceOf<UnparsableValueException>(parseResult.Exception);
    expect(result.error, const TypeMatcher<UnparsableValueError>());
    expect(0, value.index); // Cursor hasn't moved
  }
}
