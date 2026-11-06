// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';
import 'package:time_machine2/time_machine2.dart';

import 'time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  parameterizedTest(
      'JulianDateConversions',
      [
        [2436116.31, 1957, 9, 21, 19, 26, 24].options(
            customDescriptionBuilder: (_, __, ___) =>
                'Sample from Astronomical Algorithms 2nd Edition, chapter 7'),
        [2456293.520833, 2012, 12, 19, 0, 30, 0].options(
            customDescriptionBuilder: (_, __, ___) => 'Sample from Wikipedia'),
        [1842713.0, 333, 1, 27, 12, 0, 0].options(
            customDescriptionBuilder: (_, __, ___) =>
                'Another sample from Astronomical Algorithms 2nd Edition, chapter 7'),
        [0.0, -4712, 1, 1, 12, 0, 0]
            .options(customDescriptionBuilder: (_, __, ___) => 'Julian epoch'),
      ],
      JulianDateConversions,
      customDescriptionBuilder: describeArguments);
  test('BasicSpanTests', BasicSpanTests);
  test('FromUtcNoSeconds', FromUtcNoSeconds);
  test('FromUtcWithSeconds', FromUtcWithSeconds);
  test('InUtc', InUtc);
  test('InZone', InZone);
  test('WithOffset', WithOffset);
  test('WithOffset_NonIsoCalendar', WithOffset_NonIsoCalendar);
  test('FromTicksSinceUnixEpoch', FromTicksSinceUnixEpoch);
  test('FromUnixTimeMilliseconds_Valid', FromUnixTimeMilliseconds_Valid);
  test('FromUnixTimeSeconds_Valid', FromUnixTimeSeconds_Valid);
  parameterizedTest(
      'ToUnixTimeSeconds',
      [
        [-1500, -2],
        [-1001, -2],
        [-1000, -1],
        [-999, -1],
        [-500, -1],
        [0, 0],
        [500, 0],
        [999, 0],
        [1000, 1],
        [1001, 1],
        [1500, 1],
      ],
      ToUnixTimeSeconds,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'ToUnixTimeMilliseconds',
      [
        [-15000, -2],
        [-10001, -2],
        [-10000, -1],
        [-9999, -1],
        [-5000, -1],
        [0, 0],
        [5000, 0],
        [9999, 0],
        [10000, 1],
        [10001, 1],
        [15000, 1],
      ],
      ToUnixTimeMilliseconds,
      customDescriptionBuilder: describeArguments);
  test('UnixConversions_ExtremeValues', UnixConversions_ExtremeValues);
  test('InZoneWithCalendar', InZoneWithCalendar);
  test('Max', Max);
  test('Min', Min);
  test('ToDateTimeUtc', ToDateTimeUtc);
  test('ToDateTimeLocal', ToDateTimeLocal);
  test('DefaultConstructor', DefaultConstructor);
  parameterizedTest(
      'TicksTruncatesDown',
      [
        [-101, -2],
        [-100, -1],
        [-99, -1],
        [-1, -1],
        [0, 0],
        [99, 0],
        [100, 1],
        [101, 1],
      ],
      TicksTruncatesDown,
      customDescriptionBuilder: describeArguments);
  test('IsValid', IsValid);
  test('InvalidValues', InvalidValues);
  test('PlusDuration_Overflow', PlusDuration_Overflow);
  test('ExtremeArithmetic', ExtremeArithmetic);
  test('PlusOffset_Overflow', PlusOffset_Overflow);
  test('FromUnixTimeMilliseconds_Range', FromUnixTimeMilliseconds_Range);
  test('FromUnixTimeSeconds_Range', FromUnixTimeSeconds_Range);
  test('FromTicksSinceUnixEpoch_Range', FromTicksSinceUnixEpoch_Range);
  test('PlusOffset', PlusOffset);
  test('SafePlus_NormalTime', SafePlus_NormalTime);
  parameterizedTest(
      'SafePlus_NearStartOfTime',
      [
        [null, 0, null],
        [null, 1, null],
        [null, -1, null],
        [1, -1, 0],
        [1, -2, null],
        [2, 1, 3],
      ],
      SafePlus_NearStartOfTime,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'SafePlus_NearEndOfTime',
      [
        [null, 0, null],
        [null, 1, null],
        [null, -1, null],
        [-1, 1, 0],
        [-1, 2, null],
        [-2, -1, -3],
      ],
      SafePlus_NearEndOfTime,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'InstantEpochConstructors',
      [
        [0],
        [-1],
        [1],
        [123456789],
        [-123456789],
      ],
      InstantEpochConstructors,
      customDescriptionBuilder: describeArguments);
}

final Instant one = IInstant.untrusted(Time(nanoseconds: 1));
final Instant threeMillion = IInstant.untrusted(Time(nanoseconds: 3000000));
final Instant negativeFiftyMillion =
    IInstant.untrusted(Time(nanoseconds: -50000000));

// Gregorian calendar: 1957-10-04
// Gregorian calendar: 2013-01-01
void JulianDateConversions(double julianDate, int year, int month, int day,
    int hour, int minute, int second) {
  // When dealing with floating point binary data, if we're accurate to 50 milliseconds, that's fine...
  // (0.000001 days = ~86ms, as a guide to the scale involved...)
  Instant actual = Instant.julianDate(julianDate);
  var expected = LocalDateTime(year, month, day, hour, minute, second,
          calendar: CalendarSystem.julian)
      .inUtc()
      .toInstant();

  // var ldt = new LocalDateTime.fromInstant(new LocalInstant(expected.timeSinceEpoch));
  expect(expected.epochMilliseconds, closeTo(actual.epochMilliseconds, 50),
      reason: 'Expected $expected, was $actual');
  expect(julianDate, closeTo(expected.toJulianDate(), 0.000001));
}

void BasicSpanTests() {
  var aSpan = Time(days: 11, nanoseconds: 2 * TimeConstants.nanosecondsPerDay);
// print('aSpan.totalDays = ${aSpan.totalDays}');

  expect(aSpan.totalDays, 11 + 2);
}

void FromUtcNoSeconds() {
  Instant viaUtc = ZonedDateTime.atStrictly(
          LocalDateTime(2008, 4, 3, 10, 35, 0), DateTimeZone.utc)
      .toInstant();
  expect(viaUtc, Instant.utc(2008, 4, 3, 10, 35));
}

void FromUtcWithSeconds() {
  Instant viaUtc = ZonedDateTime.atStrictly(
          LocalDateTime(2008, 4, 3, 10, 35, 23), DateTimeZone.utc)
      .toInstant();
  expect(viaUtc, Instant.utc(2008, 4, 3, 10, 35, 23));
}

void InUtc() {
  ZonedDateTime viaInstant = Instant.utc(2008, 4, 3, 10, 35, 23).inUtc();
  ZonedDateTime expected = ZonedDateTime.atStrictly(
      LocalDateTime(2008, 4, 3, 10, 35, 23), DateTimeZone.utc);
  expect(expected, viaInstant);
}

Future InZone() async {
  // todo: this is absurd
  final london = await DateTimeZoneProviders.defaultProvider?['Europe/London'];
  ZonedDateTime viaInstant =
      Instant.utc(2008, 6, 10, 13, 16, 17).inZone(london!);

  // London is UTC+1 in the Summer, so the above is 14:16:17 local.
  LocalDateTime local = LocalDateTime(2008, 6, 10, 14, 16, 17);
  ZonedDateTime expected = ZonedDateTime.atStrictly(local, london);

  expect(expected, viaInstant);
}

void WithOffset() {
  // Jon talks about Noda Time at Leetspeak in Sweden on October 12th 2013, at 13:15 UTC+2
  Instant instant = Instant.utc(2013, 10, 12, 11, 15);
  Offset offset = Offset.hours(2);
  OffsetDateTime actual = instant.withOffset(offset);
  OffsetDateTime expected =
      OffsetDateTime(LocalDateTime(2013, 10, 12, 13, 15, 0), offset);
  expect(expected, actual);
}

void WithOffset_NonIsoCalendar() {
  // October 12th 2013 ISO is 1434-12-07 Islamic
  CalendarSystem calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  Instant instant = Instant.utc(2013, 10, 12, 11, 15);
  Offset offset = Offset.hours(2);
  OffsetDateTime actual = instant.withOffset(offset, calendar);
  OffsetDateTime expected = OffsetDateTime(
      LocalDateTime(1434, 12, 7, 13, 15, 0, calendar: calendar), offset);
  expect(expected, actual);
}

void FromTicksSinceUnixEpoch() {
  Instant instant = Instant.fromEpochMicroseconds(12345);
  expect(12345, instant.epochMicroseconds);
}

void FromUnixTimeMilliseconds_Valid() {
  Instant actual = Instant.fromEpochMilliseconds(12345);
  Instant expected = Instant.fromEpochMicroseconds(
      12345 * TimeConstants.microsecondsPerMillisecond);
  expect(expected, instantIsCloseTo(actual));
}

// @Test()
void FromUnixTimeMilliseconds_TooLarge() {
  expect(() => Instant.fromEpochMilliseconds(Platform.int64MaxValue ~/ 100),
      throwsException);
}

// @Test()
void FromUnixTimeMilliseconds_TooSmall() {
  // expect(() => throw new Exception('boom'), throwsException);
  expect(Instant.fromEpochMilliseconds(Platform.int64MinValue ~/ 100),
      throwsException);
}

void FromUnixTimeSeconds_Valid() {
  Instant actual = Instant.fromEpochSeconds(12345);
  Instant expected = Instant.fromEpochMicroseconds(
      12345 * TimeConstants.microsecondsPerSecond);
  expect(expected, instantIsCloseTo(actual));
}

//@Test()
void FromUnixTimeSeconds_TooLarge() {
  expect(() => Instant.fromEpochSeconds(Platform.int64MaxValue ~/ 1000000),
      throwsException);
}

//@Test()
void FromUnixTimeSeconds_TooSmall() {
  expect(() => Instant.fromEpochSeconds(Platform.int64MinValue ~/ 1000000),
      throwsException);
}

void ToUnixTimeSeconds(int milliseconds, int expectedSeconds) {
  var instant = Instant.fromEpochMilliseconds(milliseconds);
  expect(instant.epochSeconds, expectedSeconds);
}

void ToUnixTimeMilliseconds(int ticks, int expectedMilliseconds) {
  // todo: rework this test
  var instant = Instant().add(Time(nanoseconds: ticks * 100));
  expect(instant.epochMilliseconds, expectedMilliseconds);
}

void UnixConversions_ExtremeValues() {
  // Round down to a whole second to make round-tripping work.
  // 'max' is 1 second away from from the end of the day, instead of 1 nanosecond away from the end of the day
  var max = Instant.maxValue.subtract(Time(seconds: 1)).add(Time.epsilon);
  expect(max, Instant.fromEpochSeconds(max.epochSeconds));
  expect(max, Instant.fromEpochMilliseconds(max.epochMilliseconds));
  if (Platform.isVM)
    expect(max, Instant.fromEpochMicroseconds(max.epochMicroseconds));

  var min = Instant.minValue;
  expect(min, Instant.fromEpochSeconds(min.epochSeconds));
  expect(min, Instant.fromEpochMilliseconds(min.epochMilliseconds));
  if (Platform.isVM)
    expect(min, Instant.fromEpochMicroseconds(min.epochMicroseconds));
}

Future InZoneWithCalendar() async {
  CalendarSystem copticCalendar = CalendarSystem.coptic;
  final london = await DateTimeZoneProviders.defaultProvider?['Europe/London'];
  ZonedDateTime viaInstant =
      Instant.utc(2004, 6, 9, 11, 10).inZone(london!, copticCalendar);

  // Date taken from CopticCalendarSystemTest. Time will be 12:10 (London is UTC+1 in Summer)
  LocalDateTime local =
      LocalDateTime(1720, 10, 2, 12, 10, 0, calendar: copticCalendar);
  ZonedDateTime expected = ZonedDateTime.atStrictly(local, london);
  expect(viaInstant, expected);
}

void Max() {
  Instant x = Instant.fromEpochMicroseconds(100);
  Instant y = Instant.fromEpochMicroseconds(200);
  expect(y, Instant.max(x, y));
  expect(y, Instant.max(y, x));
  expect(x, Instant.max(x, Instant.minValue));
  expect(x, Instant.max(Instant.minValue, x));
  expect(Instant.maxValue, Instant.max(Instant.maxValue, x));
  expect(Instant.maxValue, Instant.max(x, Instant.maxValue));
}

void Min() {
  Instant x = Instant.fromEpochMicroseconds(100);
  Instant y = Instant.fromEpochMicroseconds(200);
  expect(x, Instant.min(x, y));
  expect(x, Instant.min(y, x));
  expect(Instant.minValue, Instant.min(x, Instant.minValue));
  expect(Instant.minValue, Instant.min(Instant.minValue, x));
  expect(x, Instant.min(Instant.maxValue, x));
  expect(x, Instant.min(x, Instant.maxValue));
}

void ToDateTimeUtc() {
  Instant x = Instant.utc(2011, 08, 18, 20, 53);
  DateTime expected = DateTime.utc(2011, 08, 18, 20, 53, 0);
  DateTime actual = x.toDateTimeUtc();
  expect(expected, actual);

  // Kind isn't checked by Equals...
  expect(true, actual.isUtc);
}

void ToDateTimeLocal() {
  Instant x = Instant.utc(2011, 08, 18, 20, 53);
  DateTime expected = x
      .inLocalZone()
      .toDateTimeLocal(); //new DateTime.utc(2011, 08, 18, 20, 53, 0);
  DateTime actual = x.toDateTimeLocal();
  expect(expected, actual);

  // Kind isn't checked by Equals...
  expect(false, actual.isUtc);
}
// See issue 269, but now we throw a nicer exception.
//@Test()
//void ToBclTypes_DateOutOfRange()
//{
//  var instant = Instant.FromUtc(1, 1, 1, 0, 0).PlusNanoseconds(-1);
//  Assert.Throws<InvalidOperationException>(() => instant.ToDateTimeUtc());
//  Assert.Throws<InvalidOperationException>(() => instant.ToDateTimeOffset());
//}

//@Test()
//@TestCase(const [100])
//@TestCase(const [1900])
//@TestCase(const [2900])
//void ToBclTypes_TruncateNanosTowardStartOfTime(int year)
//{
//  var instant = new Instant.fromUtc(year, 1, 1, 13, 15, 55).plus(new Span(nanoseconds: TimeConstants.nanosecondsPerSecond - 1)); //.PlusNanoseconds(NodaConstants.NanosecondsPerSecond - 1);
//  var expectedDateTimeUtc = new DateTime(year, 1, 1, 13, 15, 55) //, DateTimeKind.Unspecified)
//      .AddTicks(NodaConstants.TicksPerSecond - 1);
//  var actualDateTimeUtc = instant.ToDateTimeUtc();
//  Assert.AreEqual(expectedDateTimeUtc, actualDateTimeUtc);
//  var expectedDateTimeOffset = new DateTimeOffset(expectedDateTimeUtc, TimeSpan.Zero);
//  var actualDateTimeOffset = instant.ToDateTimeOffset();
//  Assert.AreEqual(expectedDateTimeOffset, actualDateTimeOffset);
//}

//@Test()
//void ToDateTimeOffset()
//{
//  Instant x = new Instant.fromUtc(2011, 08, 18, 20, 53);
//  DateTimeOffset expected = new DateTimeOffset(2011, 08, 18, 20, 53, 0, TimeSpan.Zero);
//  Assert.AreEqual(expected, x.ToDateTimeOffset());
//}

//@Test()
//void FromDateTimeOffset()
//{
//  DateTimeOffset dateTimeOffset = new DateTimeOffset(2011, 08, 18, 20, 53, 0, TimeSpan.FromHours(5));
//  Instant expected = Instant.FromUtc(2011, 08, 18, 15, 53);
//  Assert.AreEqual(expected, Instant.FromDateTimeOffset(dateTimeOffset));
//}

//@Test()
//void FromDateTimeUtc_Invalid()
//{
//  Assert.Throws<ArgumentException>(() => Instant.FromDateTimeUtc(new DateTime(2011, 08, 18, 20, 53, 0, DateTimeKind.Local)));
//  Assert.Throws<ArgumentException>(() => Instant.FromDateTimeUtc(new DateTime(2011, 08, 18, 20, 53, 0, DateTimeKind.Unspecified)));
//}

//@Test()
//void FromDateTimeUtc_Valid()
//{
//  DateTime x = new DateTime(2011, 08, 18, 20, 53, 0, DateTimeKind.Utc);
//  Instant expected = Instant.FromUtc(2011, 08, 18, 20, 53);
//  Assert.AreEqual(expected, Instant.FromDateTimeUtc(x));
//}

/// Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO Calendar
void DefaultConstructor() {
  var actual = Instant();
  expect(TimeConstants.unixEpoch, actual);
}

void TicksTruncatesDown(int nanoseconds, int expectedTicks) {
  Time nanos = Time(nanoseconds: nanoseconds);
  Instant instant = IInstant.untrusted(nanos); //.FromUntrustedDuration(nanos);
  // todo: maybe change this test up a bit?
  expect(
      (instant.timeSinceEpoch.totalNanoseconds / 100)
          .floor() /*.toUnixTimeTicks()*/,
      expectedTicks);
}

void IsValid() {
  expect(IInstant.beforeMinValue.isValid, isFalse);
  expect(Instant.minValue.isValid, isTrue);
  expect(Instant.maxValue.isValid, isTrue);
  expect(IInstant.afterMaxValue.isValid, isFalse);
}

void InvalidValues() {
  expect(IInstant.afterMaxValue, greaterThan(Instant.maxValue));
  expect(IInstant.beforeMinValue, lessThan(Instant.minValue));
}

void PlusDuration_Overflow() {
// todo: I owe you, overflow behavior
// TestHelper.AssertOverflow(Instant.minValue.plus, -Duration.Epsilon);
// TestHelper.AssertOverflow(Instant.maxValue.plus, Duration.Epsilon);
}

void ExtremeArithmetic() {
  Time hugeAndPositive = Instant.minValue.timeUntil(Instant.maxValue);
  Time hugeAndNegative = Instant.maxValue.timeUntil(Instant.minValue);
  expect(hugeAndNegative, -hugeAndPositive);
  expect(Instant.maxValue, Instant.minValue - hugeAndNegative);
  expect(Instant.maxValue, Instant.minValue + hugeAndPositive);
  expect(Instant.minValue, Instant.maxValue + hugeAndNegative);
  expect(Instant.minValue, Instant.maxValue - hugeAndPositive);
}

void PlusOffset_Overflow() {
// todo: I owe you, overflow behavior
// TestHelper.AssertOverflow(Instant.MinValue.Plus, Offset.FromSeconds(-1));
// TestHelper.AssertOverflow(Instant.MaxValue.Plus, Offset.FromSeconds(1));
}

void FromUnixTimeMilliseconds_Range() {
  // todo: I owe you, exception behavior
  //int smallestValid = Instant.minValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerMillisecond;
  //int largestValid = Instant.maxValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerMillisecond;
  //expect(() => Instant.fromEpochMilliseconds(smallestValid), isNot(throwsException));
  //expect(() => Instant.fromEpochMilliseconds(smallestValid - 1), throwsException);
  //expect(() => Instant.fromEpochMilliseconds(largestValid), isNot(throwsException));
  //expect(() => Instant.fromEpochMilliseconds(largestValid + 1), throwsException);

  //TestHelper.AssertValid(Instant.fromUnixTimeMilliseconds, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.fromUnixTimeMilliseconds, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeMilliseconds, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeMilliseconds, largestValid + 1);
}

void FromUnixTimeSeconds_Range() {
  // todo: I owe you, out of range behavior
  //int smallestValid = Instant.minValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerSecond;
  //int largestValid = Instant.maxValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerSecond;
  //TestHelper.AssertValid(Instant.FromUnixTimeSeconds, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeSeconds, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeSeconds, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeSeconds, largestValid + 1);
}

void FromTicksSinceUnixEpoch_Range() {
  // todo: I owe you, out of range behavior
  //int smallestValid = Instant.minValue.toUnixTimeMicroseconds();
  //int largestValid = Instant.maxValue.toUnixTimeMicroseconds();
  //TestHelper.AssertValid(Instant.FromUnixTimeTicks, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeTicks, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeTicks, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeTicks, largestValid + 1);
}

void PlusOffset() {
  var localInstant =
      IInstant.plusOffset(TimeConstants.unixEpoch, Offset.hours(1));
  expect(Time(hours: 1), localInstant.timeSinceLocalEpoch);
}

void SafePlus_NormalTime() {
  var localInstant =
      IInstant.safePlus(TimeConstants.unixEpoch, Offset.hours(1));
  expect(Time(hours: 1), localInstant.timeSinceLocalEpoch);
}

void SafePlus_NearStartOfTime(
    int? initialOffset, int offsetToAdd, int? finalOffset) {
  var start = initialOffset == null
      ? IInstant.beforeMinValue
      : Instant.minValue + Time(hours: initialOffset);
  var expected = finalOffset == null
      ? LocalInstant.beforeMinValue
      : IInstant.plusOffset(Instant.minValue, Offset.hours(finalOffset));
  var actual = IInstant.safePlus(start, Offset.hours(offsetToAdd));
  expect(actual, expected);
}

// A null offset indicates 'AfterMaxValue'. Otherwise, MaxValue.Plus(offset)
void SafePlus_NearEndOfTime(
    int? initialOffset, int offsetToAdd, int? finalOffset) {
  var start = initialOffset == null
      ? IInstant.afterMaxValue
      : Instant.maxValue + Time(hours: initialOffset);
  var expected = finalOffset == null
      ? LocalInstant.afterMaxValue
      : IInstant.plusOffset(Instant.maxValue, Offset.hours(finalOffset));
  var actual = IInstant.safePlus(start, Offset.hours(offsetToAdd));

  expect(actual, expected);
}

void InstantEpochConstructors(int value) {
  expect(Instant.fromEpochSeconds(value).epochSeconds, value);
  expect(Instant.fromEpochMilliseconds(value).epochMilliseconds, value);
  expect(Instant.fromEpochMicroseconds(value).epochMicroseconds, value);
  expect(Instant.fromEpochNanoseconds(value).epochNanoseconds, value);
  expect(
      Instant.fromEpochBigIntNanoseconds(BigInt.from(value))
          .epochNanosecondsAsBigInt
          .toInt(),
      value);
}
