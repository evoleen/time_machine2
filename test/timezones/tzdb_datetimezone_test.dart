// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';

import '../time_machine_testing.dart';

late Iterable<DateTimeZone> allTzdbZones;

Future main() async {
  await TimeMachineTest.initialize();
  allTzdbZones = await DateTimeZoneProviders.defaultProvider!.getAllZones();

  await runTests();
}

@Test()
@TestCaseSource(#allTzdbZones)
void AllZonesStartAndEndOfTime(DateTimeZone zone) {
  var firstInterval = zone.getZoneInterval(Instant.minValue);
  expect(firstInterval.hasStart, isFalse);
  var lastInterval = zone.getZoneInterval(Instant.maxValue);
  expect(lastInterval.hasEnd, isFalse);
}
