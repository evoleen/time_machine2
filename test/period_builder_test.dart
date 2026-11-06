// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
//import 'package:matcher/matcher.dart';

void main() {
  test('Indexer_Getter_ValidUnits', Indexer_Getter_ValidUnits);
  test('Index_Getter_InvalidUnits', Index_Getter_InvalidUnits);
  test('Indexer_Setter_ValidUnits', Indexer_Setter_ValidUnits);
  test('Index_Setter_InvalidUnits', Index_Setter_InvalidUnits);
  test('Build_SingleUnit', Build_SingleUnit);
  test('Build_MultipleUnits', Build_MultipleUnits);
  test('Build_Zero', Build_Zero);
}

void Indexer_Getter_ValidUnits() {
  var builder = PeriodBuilder()
    ..months = 1
    ..weeks = 2
    ..days = 3
    ..hours = 4
    ..minutes = 5
    ..seconds = 6
    ..milliseconds = 7
    ..microseconds = 8
    ..nanoseconds = 9;

  expect(0, builder[PeriodUnits.years]);
  expect(1, builder[PeriodUnits.months]);
  expect(2, builder[PeriodUnits.weeks]);
  expect(3, builder[PeriodUnits.days]);
  expect(4, builder[PeriodUnits.hours]);
  expect(5, builder[PeriodUnits.minutes]);
  expect(6, builder[PeriodUnits.seconds]);
  expect(7, builder[PeriodUnits.milliseconds]);
  expect(8, builder[PeriodUnits.microseconds]);
  expect(9, builder[PeriodUnits.nanoseconds]);
}

void Call(Object ignored) {}

void Index_Getter_InvalidUnits() {
  var builder = PeriodBuilder();
  expect(() => Call(builder[const PeriodUnits(0)]), throwsArgumentError);
  expect(() => Call(builder[const PeriodUnits(-1)]), throwsArgumentError);
  expect(() => Call(builder[PeriodUnits.dateAndTime]), throwsArgumentError);
}

void Indexer_Setter_ValidUnits() {
  var builder = PeriodBuilder();
  builder[PeriodUnits.months] = 1;
  builder[PeriodUnits.weeks] = 2;
  builder[PeriodUnits.days] = 3;
  builder[PeriodUnits.hours] = 4;
  builder[PeriodUnits.minutes] = 5;
  builder[PeriodUnits.seconds] = 6;
  builder[PeriodUnits.milliseconds] = 7;
  builder[PeriodUnits.microseconds] = 8;
  var expectedBuilder = PeriodBuilder()
    ..years = 0
    ..months = 1
    ..weeks = 2
    ..days = 3
    ..hours = 4
    ..minutes = 5
    ..seconds = 6
    ..milliseconds = 7
    ..microseconds = 8;

  var expected = expectedBuilder.build();
  expect(expected, builder.build());
}

void Index_Setter_InvalidUnits() {
  var builder = PeriodBuilder();
  expect(() => builder[const PeriodUnits(0)] = 1, throwsArgumentError);
  expect(() => builder[const PeriodUnits(-1)] = 1, throwsArgumentError);
  expect(() => builder[PeriodUnits.dateAndTime] = 1, throwsArgumentError);
}

void Build_SingleUnit() {
  Period period = (PeriodBuilder()..hours = 10).build();
  Period expected = const Period(hours: 10);
  expect(expected, period);
}

void Build_MultipleUnits() {
  Period period = (PeriodBuilder()
        ..days = 5
        ..minutes = -10)
      .build();
  Period expected = const Period(days: 5) + const Period(minutes: -10);
  expect(expected, period);
}

void Build_Zero() {
  expect(Period.zero, PeriodBuilder().build());
}
