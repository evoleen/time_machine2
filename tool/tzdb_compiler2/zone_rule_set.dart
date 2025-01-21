import 'package:time_machine2/src/time_machine_internal.dart';

/// A rule set associated with a single Zone line, after any rules
/// associated with it have been resolved to a collection of ZoneRecurrences.
/// It may have an upper bound, or extend to infinity: lower bounds aren't known.
/// Likewise, it may have rules associated with it, or just a fixed offset and savings.
class ZoneRuleSet {
  /// The list of ZoneRecurrence rules associated with this rule set.
  final List<ZoneRecurrence> rules = [];
  final String? name = null;
  final Offset? fixedSavings = null;
  final int upperYear;
  final ZoneYearOffset? upperYearOffset;
  final Offset standardOffset;

  ZoneRuleSet._internal(
      this.standardOffset, this.upperYear, this.upperYearOffset) {
    Preconditions.checkArgument(
      upperYear == double.infinity.toInt() || upperYearOffset != null,
      'upperYearOffset',
      'Must specify an upperYearOffset unless creating an infinite rule',
    );
  }

  factory ZoneRuleSet.withRules(
    List<ZoneRecurrence> rules,
    Offset standardOffset,
    int upperYear,
    ZoneYearOffset? upperYearOffset,
  ) {
    final ruleSet =
        ZoneRuleSet._internal(standardOffset, upperYear, upperYearOffset);
    ruleSet.rules.addAll(rules);

    return ruleSet;
  }

  factory ZoneRuleSet.fixed(
    String name,
    Offset standardOffset,
    Offset savings,
    int upperYear,
    ZoneYearOffset? upperYearOffset,
  ) {
    final ruleSet =
        ZoneRuleSet._internal(standardOffset, upperYear, upperYearOffset);
    ruleSet.name = name;
    ruleSet.fixedSavings = savings;
  }

  /// Returns `true` if this rule set extends to the end of time, or
  /// `false` if it has a finite endpoint.
  bool get isInfinite => upperYear == double.infinity.toInt();

  /// Returns `true` if this rule set is fixed, meaning it uses a single offset
  /// instead of a set of rules.
  bool get isFixed => name != null;

  /// Creates a fixed interval for this rule set starting at the given instant.
  ZoneInterval createFixedInterval(Instant start) {
    Preconditions.checkState(isFixed, 'Rule set is not fixed');
    final limit = getUpperLimit(fixedSavings);
    return ZoneInterval(
      name!,
      start,
      limit,
      standardOffset + fixedSavings,
      fixedSavings,
    );
  }

  /// Gets the inclusive upper limit of time that this rule set applies to.
  ///
  /// [savings] is the daylight savings value during the final zone interval.
  Instant getUpperLimit(Offset savings) {
    if (isInfinite) {
      return IInstant.afterMaxValue;
    }
    final localInstant = upperYearOffset!.getOccurrenceForYear(upperYear);
    final offset = upperYearOffset.getRuleOffset(standardOffset, savings);
    return localInstant.safeMinus(offset);
  }
}
