// Copyright 2009 The Noda Time Authors.
// Use of this source code is governed by the Apache License 2.0.

import 'package:time_machine2/src/time_machine_internal.dart';

/// Defines one "Rule" line from the tz data. (This may be applied to multiple zones.)
/// Immutable and thread-safe.
class RuleLine {
  /// The string to replace "%s" with (if any) when formatting the zone name key.
  /// This is always used to replace %s, whether or not the recurrence
  /// actually includes savings; it is expected to be appropriate to the recurrence.
  final String? daylightSavingsIndicator;

  /// The recurrence pattern for the rule.
  final ZoneRecurrence recurrence;

  /// Returns the name of the rule set this rule belongs to.
  String get name => recurrence.name;

  /// Creates a new instance of [RuleLine].
  RuleLine(this.recurrence, this.daylightSavingsIndicator);

  /// Retrieves the recurrence, after applying the specified name format.
  ///
  /// Multiple zones may apply the same set of rules as to when they change into/out of
  /// daylight saving time, but with different names.
  ZoneRecurrence getRecurrence(ZoneLine zone) {
    final formattedName =
        zone.formatName(recurrence.savings, daylightSavingsIndicator);
    return recurrence.withName(formattedName);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RuleLine) return false;
    return recurrence == other.recurrence &&
        daylightSavingsIndicator == other.daylightSavingsIndicator;
  }

  @override
  int get hashCode => Object.hash(recurrence, daylightSavingsIndicator);

  @override
  String toString() {
    final buffer = StringBuffer()..write(recurrence);
    if (daylightSavingsIndicator != null) {
      buffer.write(' "$daylightSavingsIndicator"');
    }
    return buffer.toString();
  }
}
