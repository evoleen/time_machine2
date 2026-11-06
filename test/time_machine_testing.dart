// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/time_machine2.dart' as public_machine;
import 'testing/test_helper.dart' as helper;

export 'testing/time_matchers.dart';
export 'testing/test_helper.dart';

export 'testing/fake_clock.dart';
export 'testing/timezones/single_transition_datetimezone.dart';
export 'testing/timezones/multi_transition_datetimezone.dart';
export 'testing/timezones/fake_datetimezone_source.dart';

export 'testing/skip.dart';

import 'dart:async';
import 'package:time_machine2/src/time_machine_internal.dart';

/// Names each case of a `parameterizedTest` after its arguments, such as
/// `[2011, 1, 1]`, as NUnit and the old test harness did (by default,
/// parameterized_test quotes strings and pads the brackets).
Object? describeArguments(
        Object? groupDescription, int index, List<dynamic> values) =>
    '$values';

abstract class TimeMachineTest {
  TimeMachineTest() {
    throw StateError('TimeMachine can not be instantiated.');
  }

  static Future initialize([Map args = const {}]) async {
    helper.setFunctions();
    await public_machine.TimeMachine.initialize({...args, 'testing': true});
  }
}

// From Testing Objects
abstract class TestObjects {
  /// Creates a positive offset from the given values.
  ///
  /// [hours]: The number of hours, in the range [0, 24).
  /// [minutes]: The number of minutes, in the range [0, 60).
  /// [seconds]: The number of seconds, in the range [0, 60).
  /// Returns: A new [Offset] representing the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  static Offset CreatePositiveOffset(int hours, int minutes, int seconds) {
    Preconditions.checkArgumentRange('hours', hours, 0, 23);
    Preconditions.checkArgumentRange('minutes', minutes, 0, 59);
    Preconditions.checkArgumentRange('seconds', seconds, 0, 59);
    seconds += minutes * TimeConstants.secondsPerMinute;
    seconds += hours * TimeConstants.secondsPerHour;
    return Offset(seconds);
  }

  /// Creates a negative offset from the given values.
  ///
  /// [hours]: The number of hours, in the range [0, 24).
  /// [minutes]: The number of minutes, in the range [0, 60).
  /// [seconds]: The number of seconds, in the range [0, 60).
  /// Returns: A new [Offset] representing the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  static Offset CreateNegativeOffset(int hours, int minutes, int seconds) {
    return Offset(-CreatePositiveOffset(hours, minutes, seconds).inSeconds);
  }
}
