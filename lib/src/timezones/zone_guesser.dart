// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

/// Works out which of [candidates] best matches a system time zone whose UTC
/// offsets are given by [systemOffset], by checking the transitions within the
/// next few years. Returns null if no zone matches at least 70% of them.
///
/// This is a port of Noda Time's `TzdbDateTimeZoneSource.GuessZoneIdByTransitionsUncached`,
/// used when the system zone can't be mapped directly (for example an unknown
/// Windows zone, or when the system only reports a display name).
///
/// [candidates] should be ordered by ID, so that if several zones get the same
/// score the same one is always picked across runs and platforms.
/// [year] is the year to start from; it defaults to the current UTC year.
String? guessZoneIdByTransitions(Offset Function(Instant instant) systemOffset,
    List<DateTimeZone> candidates,
    {int? year}) {
  // Windows time zone updates sometimes sacrifice past accuracy for future
  // accuracy, so use the current year's transitions.
  final thisYear = year ?? DateTime.now().toUtc().year;
  final startOfThisYear = Instant.utc(thisYear, 1, 1, 0, 0);
  final startOfLastYear = Instant.utc(thisYear + 5, 1, 1, 0, 0);
  final interval = Interval(startOfThisYear, startOfLastYear);

  // Clamp each interval start to the start of this year. A set keeps the
  // first occurrence order and drops duplicates.
  final instants = <Instant>{
    for (final zone in candidates)
      for (final zoneInterval in zone.getZoneIntervals(interval))
        Instant.max(IZoneInterval.rawStart(zoneInterval), startOfThisYear)
  }.toList();
  final systemOffsets = [for (final instant in instants) systemOffset(instant)];

  // For a zone to be mappable, at most 30% of the checks must fail - so if we
  // get to that number (or whatever our "best" so far is) we know we can stop
  // for any particular zone.
  var lowestFailureScore = (instants.length * 30) ~/ 100;
  DateTimeZone? bestZone;
  for (final candidate in candidates) {
    var failureScore = 0;
    for (var i = 0; i < instants.length; i++) {
      if (candidate.getUtcOffset(instants[i]) != systemOffsets[i]) {
        failureScore++;
        if (failureScore == lowestFailureScore) {
          break;
        }
      }
    }
    if (failureScore < lowestFailureScore) {
      lowestFailureScore = failureScore;
      bestZone = candidate;
    }
  }
  return bestZone?.id;
}
