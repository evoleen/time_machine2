// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';

import 'time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  test('TzdbProviderUsesTzdbSource', TzdbProviderUsesTzdbSource);
  test('AllTzdbTimeZonesLoad', AllTzdbTimeZonesLoad);
  test('FixedOffsetIdWorksAsTheSystemDefault',
      FixedOffsetIdWorksAsTheSystemDefault);
}

Future TzdbProviderUsesTzdbSource() async {
  expect(DateTimeZoneProviders.defaultProvider?.versionId?.startsWith('TZDB: '),
      isTrue);
}

Future AllTzdbTimeZonesLoad() async {
  var tzdb = DateTimeZoneProviders.defaultProvider;
  var allZones = tzdb?.ids.map((id) => tzdb[id]).toList();
  // Just to stop the variable from being lonely. In reality, it's likely there'll be a breakpoint here to inspect a particular zone...
  expect(allZones!.length > 50, isTrue);
}

/// TimeMachine.initialize's last resort is a fixed zone with the system's
/// offset; its ID (e.g. 'UTC+05:30') isn't a TZDB ID but, as in Noda Time,
/// every provider resolves fixed-offset IDs, so it works as the default.
Future FixedOffsetIdWorksAsTheSystemDefault() async {
  var tzdb = await DateTimeZoneProviders.tzdb;
  var original = tzdb.getCachedSystemDefault().id;
  try {
    for (var offset in [Offset.hoursAndMinutes(5, 30), Offset.hours(-8)]) {
      var id = DateTimeZone.forOffset(offset).id;
      tzdb.setSystemDefault(id);
      expect(DateTimeZone.local.getUtcOffset(Instant.unixEpoch), offset);
      expect((await tzdb.getSystemDefault()).id, id);
    }
  } finally {
    tzdb.setSystemDefault(original);
  }
}
