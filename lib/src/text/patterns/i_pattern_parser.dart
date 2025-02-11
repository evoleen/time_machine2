// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

/// Internal interface used by FixedFormatInfoPatternParser. Unfortunately
/// even though this is internal, implementations must either use public methods
/// or explicit interface implementation.
@internal
abstract class IPatternParser<T> {
  IPattern<T> parsePattern(String pattern, TimeMachineFormatInfo formatInfo);
}
