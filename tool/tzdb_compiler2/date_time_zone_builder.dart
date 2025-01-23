import 'package:time_machine2/src/time_machine_internal.dart';

import 'zone_rule_set.dart';
import 'zone_transition.dart';

/// A mutable class with a static entry point to convert an ID and sequence of
/// ZoneRuleSet elements into a DateTimeZone.
class DateTimeZoneBuilder {
  final List<ZoneInterval> _zoneIntervals = [];
  StandardDaylightAlternatingMap? _tailZone;

  DateTimeZoneBuilder._();

  /// Builds a time zone with the given ID from a sequence of rule sets.
  static DateTimeZone build(String id, List<ZoneRuleSet> ruleSets) {
    Preconditions.checkArgument(
      ruleSets.isNotEmpty,
      'ruleSets',
      'Cannot create a time zone without any Zone entries',
    );
    final builder = DateTimeZoneBuilder._();
    return builder._buildZone(id, ruleSets);
  }

  DateTimeZone _buildZone(String id, List<ZoneRuleSet> ruleSets) {
    // Add intervals for each rule set
    for (final ruleSet in ruleSets) {
      _addIntervals(ruleSet);
    }

    // Coalesce abutting intervals with identical properties
    _coalesceIntervals();

    // Construct the final time zone
    if (_zoneIntervals.length == 1 && _tailZone == null) {
      final interval = _zoneIntervals.first;
      return FixedDateTimeZone(id, interval.wallOffset, interval.name);
    } else {
      return PrecalculatedDateTimeZone(id, _zoneIntervals, _tailZone);
    }
  }

  void _addIntervals(ZoneRuleSet ruleSet) {
    final lastZoneInterval =
        _zoneIntervals.isEmpty ? null : _zoneIntervals.last;
    final start = lastZoneInterval?.end ?? IInstant.beforeMinValue;

    if (ruleSet.isFixed) {
      _zoneIntervals.add(ruleSet.createFixedInterval(start));
      return;
    }

    final activeRules = List.of(ruleSet.rules);
    final standardOffset = ruleSet.standardOffset;

    ZoneTransition previousTransition = lastZoneInterval != null
        ? _findFirstTransition(start, activeRules, lastZoneInterval)
        : _createInitialTransition(activeRules, start, standardOffset);

    while (true) {
      final bestTransition =
          _findBestTransition(previousTransition, activeRules, standardOffset);

      final currentUpperBound =
          ruleSet.getUpperLimit(previousTransition.savings);
      if (bestTransition == null ||
          bestTransition.instant >= currentUpperBound) {
        if (currentUpperBound > previousTransition.instant) {
          _zoneIntervals
              .add(previousTransition.toZoneInterval(currentUpperBound));
        }
        return;
      }

      _zoneIntervals
          .add(previousTransition.toZoneInterval(bestTransition.instant));
      previousTransition = bestTransition;

      _handleTailZone(ruleSet, activeRules, standardOffset);
    }
  }

  ZoneTransition _findFirstTransition(
    Instant start,
    List<ZoneRecurrence> activeRules,
    ZoneInterval lastZoneInterval,
  ) {
    final firstRule = activeRules
        .map((rule) => rule.previousOrSame(
            start, lastZoneInterval.standardOffset, lastZoneInterval.savings))
        .where((transition) => transition != null)
        .map((transition) => transition!)
        .toList()
        .lastOrNull;

    if (firstRule != null) {
      return ZoneTransition(start, firstRule.name,
          lastZoneInterval.standardOffset, firstRule.savings);
    } else {
      final name =
          activeRules.firstWhere((rule) => rule.savings == Offset.zero).name;
      return ZoneTransition(
          start, name, lastZoneInterval.standardOffset, Offset.zero);
    }
  }

  ZoneTransition _createInitialTransition(
    List<ZoneRecurrence> activeRules,
    Instant start,
    Offset standardOffset,
  ) {
    final name =
        activeRules.firstWhere((rule) => rule.savings == Offset.zero).name;
    return ZoneTransition(start, name, standardOffset, Offset.zero);
  }

  ZoneTransition? _findBestTransition(
    ZoneTransition previousTransition,
    List<ZoneRecurrence> activeRules,
    Offset standardOffset,
  ) {
    ZoneTransition? bestTransition;
    for (int i = 0; i < activeRules.length; i++) {
      final rule = activeRules[i];
      final nextTransition = rule.next(previousTransition.instant,
          standardOffset, previousTransition.savings);
      if (nextTransition == null) {
        activeRules.removeAt(i--);
        continue;
      }
      final transition = ZoneTransition(
          nextTransition.instant, rule.name, standardOffset, rule.savings);
      if (!transition.isTransitionFrom(previousTransition)) {
        continue;
      }
      if (bestTransition == null ||
          transition.instant <= bestTransition.instant) {
        bestTransition = transition;
      }
    }
    return bestTransition;
  }

  void _handleTailZone(
    ZoneRuleSet ruleSet,
    List<ZoneRecurrence> activeRules,
    Offset standardOffset,
  ) {
    if (ruleSet.isInfinite && activeRules.length == 2) {
      if (_tailZone != null) return;

      final startRule = activeRules[0];
      final endRule = activeRules[1];
      if (startRule.isInfinite && endRule.isInfinite) {
        _tailZone =
            StandardDaylightAlternatingMap(standardOffset, startRule, endRule);
      }
    }
  }

  void _coalesceIntervals() {
    for (int i = 0; i < _zoneIntervals.length - 1; i++) {
      final current = _zoneIntervals[i];
      final next = _zoneIntervals[i + 1];
      if (current.name == next.name &&
          current.wallOffset == next.wallOffset &&
          current.standardOffset == next.standardOffset) {
        _zoneIntervals[i] = IZoneInterval.withEnd(current, next.end)!;
        _zoneIntervals.removeAt(i + 1);
        i--;
      }
    }
  }
}
