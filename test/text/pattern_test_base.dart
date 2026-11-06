// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import 'pattern_test_data.dart';

/// Base class for all the pattern tests (when we've migrated OffsetPattern off FormattingTestSupport).
/// Derived classes provide the test cases as InvalidPatternData, ParseFailureData, ParseData and
/// FormatData, and each subclass's test file registers these methods with parameterizedTest.
/// If a test isn't appropriate (e.g. there's no configurable pattern), that file doesn't
/// register it.
abstract class PatternTestBase<T> {
  void InvalidPatterns(PatternTestData<T> data) {
    data.TestInvalidPattern();
  }

  void ParseFailures(PatternTestData<T> data) {
    data.TestParseFailure();
  }

  void Parse(PatternTestData<T> data) {
    data.TestParse();
  }

  void Format(PatternTestData<T> data) {
    data.TestFormat();
  }

  // Testing this for every item is somewhat overkill, but not too slow.
  void AppendFormat(PatternTestData<T> data) {
    data.TestAppendFormat();
  }

  void AssertRoundTrip(T value, IPattern<T> pattern) {
    String text = pattern.format(value);
    var parseResult = pattern.parse(text);
    expect(value, parseResult.value);
  }

  // void AssertParseNull(IPattern<T> pattern)
  // {
  //   var result = pattern.parse(null);
  //   expect(result.success, isFalse);
  //   // Assert.IsInstanceOf<ArgumentNullException>(result.Exception);
  //   expect(result.error, TypeMatcher<ArgumentError>());
  // }
}
