// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

void main() {
  test('Sanity', Sanity);
}

//void InstanceNow()
//{
//  int frameworkNowTicks = TimeConstants.bclEpoch.plus(DateTime.UtcNow).ToUnixTimeTicks();
//  int nodaTicks = SystemClock.instance.getCurrentInstant().toUnixTimeTicks();
//  assert((nodaTicks - frameworkNowTicks).abs() == new Span(seconds: 1).totalTicks);
//  // Assert.Less(Math.Abs(nodaTicks - frameworkNowTicks), Duration.FromSeconds(1).BclCompatibleTicks);
//}

void Sanity() {
  // Previously all the conversions missed the SystemConversions.DateTimeEpochTicks,
  // so they were self-consistent but not consistent with sanity.
  Instant minimumExpected = Instant.utc(2011, 8, 1, 0, 0);
  Instant maximumExpected = Instant.utc(2030, 1, 1, 0, 0);
  Instant now = SystemClock.instance.getCurrentInstant();
  expect(minimumExpected.epochMicroseconds, lessThan(now.epochMicroseconds));
  expect(now.epochMicroseconds, lessThan(maximumExpected.epochMicroseconds));
}
