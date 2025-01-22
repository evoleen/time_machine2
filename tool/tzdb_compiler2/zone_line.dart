// Copyright 2009 The Noda Time Authors.
// Use of this source code is governed by the Apache License 2.0.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'rule_line.dart';
import 'zone_rule_set.dart';

/// Contains the parsed information from one "Zone" line of the TZDB zone database.
/// Immutable and thread-safe.
class ZoneLine {
  static const String percentZPattern = 'i';

  /// The name of the time zone.
  final String name;

  /// The offset to add to UTC for this time zone's standard time.
  final Offset standardOffset;

  /// The name of the set of rules applicable to this zone line, or
  /// `null` for just standard time, or an offset for a "fixed savings" rule.
  final String? rules;

  /// The format for generating the label for this time zone.
  /// May contain "%s" to be replaced by a daylight savings indicator,
  /// or "%z" to be replaced by an offset indicator.
  final String format;

  /// The year until which this zone line applies.
  final int untilYear;

  /// The offset defining when the `untilYear` applies.
  final ZoneYearOffset untilYearOffset;

  /// Creates a new instance of [ZoneLine].
  ZoneLine(this.name, this.standardOffset, this.rules, this.format,
      this.untilYear, this.untilYearOffset);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ZoneLine) return false;

    return name == other.name &&
        standardOffset == other.standardOffset &&
        rules == other.rules &&
        format == other.format &&
        untilYear == other.untilYear &&
        (untilYear == double.infinity ||
            untilYearOffset == other.untilYearOffset);
  }

  @override
  int get hashCode {
    var hash = Object.hash(name, standardOffset, rules, format, untilYear);
    if (untilYear != double.infinity) {
      hash = Object.hash(hash, untilYearOffset.hashCode);
    }
    return hash;
  }

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('$name ')
      ..write('$standardOffset ')
      ..write('${ParserHelper.formatOptional(rules)} ')
      ..write(format);

    if (untilYear != double.infinity) {
      buffer
        ..write(' ')
        ..write(untilYear.toString().padLeft(4, '0'))
        ..write(' ')
        ..write(untilYearOffset);
    }

    return buffer.toString();
  }

  ZoneRuleSet resolveRules(Map<String, List<RuleLine>> allRules) {
    if (rules == null) {
      final name = formatName(Offset.zero, '');
      return ZoneRuleSet.fixed(
          name, standardOffset, Offset.zero, untilYear, untilYearOffset);
    }

    if (allRules.containsKey(rules)) {
      final ruleSet = allRules[rules]!;
      final ruleRecurrences =
          ruleSet.map((rule) => rule.getRecurrence(this)).toList();
      return ZoneRuleSet.withRules(
          ruleRecurrences, standardOffset, untilYear, untilYearOffset);
    } else {
      try {
        final savings = ParserHelper.parseOffset(rules!);
        final name = formatName(savings, '');
        return ZoneRuleSet.fixed(
            name, standardOffset, savings, untilYear, untilYearOffset);
      } catch (e) {
        throw ArgumentError(
            "Daylight savings rule name '$rules' for zone $name is neither a known ruleset nor a fixed offset");
      }
    }
  }

  String formatName(Offset savings, String? daylightSavingsIndicator) {
    final slashIndex = format.indexOf('/');
    if (slashIndex >= 0) {
      return savings == Offset.zero
          ? format.substring(0, slashIndex)
          : format.substring(slashIndex + 1);
    }

    final percentSIndex = format.indexOf('%s');
    if (percentSIndex >= 0) {
      final left = format.substring(0, percentSIndex);
      final right = format.substring(percentSIndex + 2);
      return '$left$daylightSavingsIndicator$right';
    }

    final percentZIndex = format.indexOf('%z');
    if (percentZIndex >= 0) {
      final left = format.substring(0, percentZIndex);
      final right = format.substring(percentZIndex + 2);
      return '$left${standardOffset + savings}$right';
    }

    return format;
  }
}
