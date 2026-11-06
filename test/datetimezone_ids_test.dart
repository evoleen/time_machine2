// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

void main() {
  test('UtcIsNotNull', UtcIsNotNull);
}

/// Tests for code in DateTimeZone and code which will be moving out
/// of DateTimeZones into DateTimeZone over time.
void UtcIsNotNull() {
  expect(DateTimeZone.utc, isNotNull);
}
