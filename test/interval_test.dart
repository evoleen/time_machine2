// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import 'time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  test('Construction_Success', Construction_Success);
  test('Construction_EqualStartAndEnd', Construction_EqualStartAndEnd);
  test('Construction_EndBeforeStart', Construction_EndBeforeStart);
  test('Equals', Equals);
  test('Operators', Operators);
  test('Duration', Duration);
  test('ToStringUsesExtendedIsoFormat', ToStringUsesExtendedIsoFormat);
  test('ToString_Infinite', ToString_Infinite);
  parameterizedTest(
      'Contains',
      [
        [
          '1990-01-01T00:00:00Z',
          false
        ].options(customDescriptionBuilder: (_, __, ___) => "Before interval"),
        ['2000-01-01T00:00:00Z', true].options(
            customDescriptionBuilder: (_, __, ___) => "Start of interval"),
        [
          '2010-01-01T00:00:00Z',
          true
        ].options(customDescriptionBuilder: (_, __, ___) => "Within interval"),
        ['2020-01-01T00:00:00Z', false].options(
            customDescriptionBuilder: (_, __, ___) =>
                "End instant of interval"),
        [
          '2030-01-01T00:00:00Z',
          false
        ].options(customDescriptionBuilder: (_, __, ___) => "After interval"),
      ],
      Contains,
      customDescriptionBuilder: describeArguments);
  test('Contains_Infinite', Contains_Infinite);
  test('HasStart', HasStart);
  test('HasEnd', HasEnd);
  test('Start', Start);
  test('End', End);
  test('Contains_EmptyInterval', Contains_EmptyInterval);
  test('Contains_EmptyInterval_MaxValue', Contains_EmptyInterval_MaxValue);
  parameterizedTest(
      'Interval_Overlapping',
      [
        ['2020-01-01T00:00:00Z', "2030-01-01T00:00:00Z", false]
            .options(customDescriptionBuilder: (_, __, ___) => "0"),
        ['1910-01-01T00:00:00Z', "2000-01-01T00:00:00Z", false]
            .options(customDescriptionBuilder: (_, __, ___) => "1"),
        ['1910-01-01T00:00:00Z', "2000-01-01T00:00:01Z", true]
            .options(customDescriptionBuilder: (_, __, ___) => "2"),
        ['2020-01-01T00:00:00Z', "2030-01-01T00:00:01Z", false]
            .options(customDescriptionBuilder: (_, __, ___) => "3"),
        ['2019-12-31T23:59:59Z', "2030-01-01T00:00:01Z", true]
            .options(customDescriptionBuilder: (_, __, ___) => "4"),
      ],
      Interval_Overlapping,
      customDescriptionBuilder: describeArguments);
}

final Instant one = IInstant.untrusted(Time(nanoseconds: 1));
final Instant threeMillion = IInstant.untrusted(Time(nanoseconds: 3000000));
final Instant negativeFiftyMillion =
    IInstant.untrusted(Time(nanoseconds: -50000000));

final Instant SampleStart =
    TimeConstants.unixEpoch.add(Time(nanoseconds: -30001));
final Instant SampleEnd = TimeConstants.unixEpoch.add(Time(nanoseconds: 40001));

void Construction_Success() {
  var interval = Interval(SampleStart, SampleEnd);
  expect(SampleStart, interval.start);
  expect(SampleEnd, interval.end);
}

void Construction_EqualStartAndEnd() {
  var interval = Interval(SampleStart, SampleStart);
  expect(SampleStart, interval.start);
  expect(SampleStart, interval.end);
  expect(Time.zero, interval.totalTime);
}

void Construction_EndBeforeStart() {
  expect(() => Interval(SampleEnd, SampleStart), throwsRangeError);
  expect(() => Interval(SampleEnd, SampleStart), throwsRangeError);
}

void Equals() {
  TestHelper.TestEqualsStruct(
      Interval(SampleStart, SampleEnd),
      Interval(SampleStart, SampleEnd),
      [Interval(TimeConstants.unixEpoch, SampleEnd)]);
  TestHelper.TestEqualsStruct(
      Interval(null, SampleEnd),
      Interval(null, SampleEnd),
      [Interval(TimeConstants.unixEpoch, SampleEnd)]);
  TestHelper.TestEqualsStruct(
      Interval(SampleStart, SampleEnd),
      Interval(SampleStart, SampleEnd),
      [Interval(TimeConstants.unixEpoch, SampleEnd)]);
  TestHelper.TestEqualsStruct(Interval(null, null), Interval(null, null),
      [Interval(TimeConstants.unixEpoch, SampleEnd)]);
}

void Operators() {
  TestHelper.TestOperatorEquality(
      Interval(SampleStart, SampleEnd),
      Interval(SampleStart, SampleEnd),
      Interval(TimeConstants.unixEpoch, SampleEnd));
}

void Duration() {
  var interval = Interval(SampleStart, SampleEnd);
  expect(Time(nanoseconds: 70002), interval.totalTime);
}

/*
@Test()
void DefaultConstructor()
{
  var actual = new Interval();
  expect(NodaTime.time.Zero, actual.time);
}*/

void ToStringUsesExtendedIsoFormat() {
  // var start = new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).PlusNanoseconds(123456789).InUtc().ToInstant();
  // var end = new LocalDateTime.fromYMDHMSM(2013, 10, 12, 17, 1, 2, 120).InUtc().ToInstant();

  var start = LocalDateTime(2013, 4, 12, 17, 53, 23)
      .addNanoseconds(123456789)
      .inUtc()
      .toInstant();
  var end = LocalDateTime(2013, 10, 12, 17, 1, 2)
      .addMilliseconds(120)
      .inUtc()
      .toInstant();

  var value = Interval(start, end);
  expect('2013-04-12T17:53:23.123456789Z/2013-10-12T17:01:02.12Z',
      value.toString());
}

void ToString_Infinite() {
  var value = Interval(null, null);
  expect('StartOfTime/EndOfTime', value.toString());
}

void Contains(String candidateText, bool expectedResult) {
  var start = Instant.utc(2000, 1, 1, 0, 0);
  var end = Instant.utc(2020, 1, 1, 0, 0);
  var interval = Interval(start, end);
  var candidate = InstantPattern.extendedIso.parse(candidateText).value;
  expect(expectedResult, interval.contains(candidate));
}

void Contains_Infinite() {
  var interval = Interval(null, null);
  expect(interval.contains(Instant.maxValue), isTrue);
  expect(interval.contains(Instant.minValue), isTrue);
}

void HasStart() {
  expect(Interval(Instant.minValue, null).hasStart, isTrue);
  expect(Interval(null, Instant.minValue).hasStart, isFalse);
}

void HasEnd() {
  expect(Interval(null, Instant.maxValue).hasEnd, isTrue);
  expect(Interval(Instant.maxValue, null).hasEnd, isFalse);
}

void Start() {
  expect(
      TimeConstants.unixEpoch, Interval(TimeConstants.unixEpoch, null).start);
  Interval noStart = Interval(null, TimeConstants.unixEpoch);
  expect(() => noStart.start.toString(), throwsStateError);
}

void End() {
  expect(TimeConstants.unixEpoch, Interval(null, TimeConstants.unixEpoch).end);
  Interval noEnd = Interval(TimeConstants.unixEpoch, null);
  expect(() => noEnd.end.toString(), throwsStateError);
}

void Contains_EmptyInterval() {
  var instant = TimeConstants.unixEpoch;
  var interval = Interval(instant, instant);
  expect(interval.contains(instant), isFalse);
}

void Contains_EmptyInterval_MaxValue() {
  var instant = Instant.maxValue;
  var interval = Interval(instant, instant);
  expect(interval.contains(instant), isFalse);
}

void Interval_Overlapping(
    String otherStart, String otherEnd, bool expectedResult) {
  var start = Instant.utc(2000, 1, 1, 0, 0);
  var end = Instant.utc(2020, 1, 1, 0, 0);
  var interval = Interval(start, end);
  var other = Interval(InstantPattern.extendedIso.parse(otherStart).value,
      InstantPattern.extendedIso.parse(otherEnd).value);
  expect(interval.overlaps(other), expectedResult);
}

/*
@Test()
void Deconstruction_IntervalWithoutStart() {
  Instant ? start;
  var end = new Instant(1500, 1_000_000);
  var value = new Interval(start, end);

  (Instant ? actualStart, Instant? actualEnd) = value;

  expect(start, actualStart);
  expect(end, actualEnd);
}*/

/*
@Test()
void Deconstruction_IntervalWithoutEnd() {
  var start = new Instant(1500, 1_000_000);
  Instant ? end;
  var value = new Interval(start, end);

  (Instant ? actualStart, Instant? actualEnd) = value;

  expect(start, actualStart);
  expect(end, actualEnd);
}*/
