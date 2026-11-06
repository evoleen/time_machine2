// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';
import 'time_machine_testing.dart';

void main() {
  parameterizedTest('MaxDate', SupportedCalendars, MaxDate,
      customDescriptionBuilder: describeArguments);
  parameterizedTest('MinDate', SupportedCalendars, MinDate,
      customDescriptionBuilder: describeArguments);
}

final Iterable<String> SupportedIds = CalendarSystem.ids.toList();
final List<CalendarSystem> SupportedCalendars =
    SupportedIds.map(CalendarSystem.forId).toList();

void MaxDate(CalendarSystem calendar) {
  // Construct the largest LocalDate we can, and validate that all the properties can be fetched without
  // issues.
  ValidateProperties(
      calendar, ICalendarSystem.maxDays(calendar), calendar.maxYear);
}

void MinDate(CalendarSystem calendar) {
  // Construct the smallest LocalDate we can, and validate that all the properties can be fetched without
  // issues.
  ValidateProperties(
      calendar, ICalendarSystem.minDays(calendar), calendar.minYear);
}

void ValidateProperties(
    CalendarSystem calendar, int daysSinceEpoch, int expectedYear) {
  var localDate = LocalDate.fromEpochDay(daysSinceEpoch, calendar);
  expect(localDate.year, expectedYear);

// todo: investigate test and replicate
//  for (var property in typeof(LocalDate).GetTypeInfo().DeclaredProperties)
//  {
//    property.GetValue(localDate, null);
//  }
}
