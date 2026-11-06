// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

import '../time_machine_testing.dart';

void main() {
  test('Value_Success', Value_Success);
  test('Value_Failure', Value_Failure);
  test('Exception_Success', Exception_Success);
  test('Exception_Failure', Exception_Failure);
  test('GetValueOrThrow_Success', GetValueOrThrow_Success);
  test('GetValueOrThrow_Failure', GetValueOrThrow_Failure);
  test('TryGetValue_Success', TryGetValue_Success);
  test('TryGetValue_Failure', TryGetValue_Failure);
  test('Convert_ForFailureResult', Convert_ForFailureResult);
  test('Convert_ForSuccessResult', Convert_ForSuccessResult);
  test('ConvertError_ForFailureResult', ConvertError_ForFailureResult);
  test('ConvertError_ForSuccessResult', ConvertError_ForSuccessResult);
  test('ForException', ForException);
}

final ParseResult<int> _failureResult =
    IParseResult.forInvalidValue<int>(ValueCursor('text'), "text");

void Value_Success() {
  ParseResult<int> result = ParseResult.forValue<int>(5);
  expect(5, result.value);
}

void Value_Failure() {
  expect(
      () => _failureResult.value.hashCode, willThrow<UnparsableValueError>());
}

void Exception_Success() {
  ParseResult<int> result = ParseResult.forValue<int>(5);
  expect(() => result.error.hashCode, throwsStateError);
}

void Exception_Failure() {
  // Assert.IsInstanceOf<UnparsableValueError>(FailureResult.Exception);
  expect(_failureResult.error, const TypeMatcher<UnparsableValueError>());
}

void GetValueOrThrow_Success() {
  ParseResult<int> result = ParseResult.forValue<int>(5);
  expect(5, result.getValueOrThrow());
}

void GetValueOrThrow_Failure() {
  expect(() => _failureResult.getValueOrThrow(),
      willThrow<UnparsableValueError>());
}

void TryGetValue_Success() {
  ParseResult<int> result = ParseResult.forValue<int>(5);
  //expect(result.TryGetValue(-1, out int actual), isTrue);
  int actual;
  expect(actual = result.TryGetValue(-1), isNot(-1));
  expect(5, actual);
}

void TryGetValue_Failure() {
// expect(FailureResult.TryGetValue(-1, out int actual), isFalse);

  int actual;
  expect(actual = _failureResult.TryGetValue(-1), -1);
  expect(-1, actual);
}

void Convert_ForFailureResult() {
  ParseResult<String> converted = _failureResult.convert((x) => 'xx${x}xx');
  expect(() => converted.getValueOrThrow(), willThrow<UnparsableValueError>());
}

void Convert_ForSuccessResult() {
  ParseResult<int> original = ParseResult.forValue<int>(10);
  ParseResult<String> converted = original.convert((x) => 'xx${x}xx');
  expect('xx10xx', converted.value);
}

void ConvertError_ForFailureResult() {
  ParseResult<String> converted = _failureResult.convertError<String>();
  expect(() => converted.getValueOrThrow(), willThrow<UnparsableValueError>());
}

void ConvertError_ForSuccessResult() {
  ParseResult<int> original = ParseResult.forValue<int>(10);
  expect(() => original.convertError<String>(), throwsStateError);
}

void ForException() {
  Error e = Error();
  ParseResult<int> result = ParseResult.forError<int>(() => e);
  expect(result.success, isFalse);
  expect(identical(e, result.error), isTrue);
}
