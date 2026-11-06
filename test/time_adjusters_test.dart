// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';

void main() {
  test('TruncateToSecond', TruncateToSecond);
  test('TruncateToMinute', TruncateToMinute);
  test('TruncateToHour', TruncateToHour);
}

void TruncateToSecond() {
  var start = LocalTime(7, 4, 30,
      ns: 123 * TimeConstants.nanosecondsPerMillisecond + 4567 * 100);
  var end = LocalTime(7, 4, 30);
  expect(end, TimeAdjusters.truncateToSecond(start));
}

void TruncateToMinute() {
  var start = LocalTime(7, 4, 30,
      ns: 123 * TimeConstants.nanosecondsPerMillisecond + 4567 * 100);
  var end = LocalTime(7, 4, 0);
  expect(end, TimeAdjusters.truncateToMinute(start));
}

void TruncateToHour() {
  var start = LocalTime(7, 4, 30,
      ns: 123 * TimeConstants.nanosecondsPerMillisecond + 4567 * 100);
  var end = LocalTime(7, 0, 0);
  expect(end, TimeAdjusters.truncateToHour(start));
}
