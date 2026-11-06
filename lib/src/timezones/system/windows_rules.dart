// Portions of this work are Copyright 2026 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2012 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Pure Dart conversion of Windows time zone rules (TIME_ZONE_INFORMATION) to
// zone interval maps, ported from Noda Time's BclDateTimeZone. Kept free of
// dart:ffi so it can be unit tested on any platform.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'map_datetimezone.dart';

/// The values of a Win32 `SYSTEMTIME` used as a transition date in a
/// `TIME_ZONE_INFORMATION`.
///
/// * [month] 0 means the zone has no daylight saving time.
/// * [year] 0 means a floating ("day-of-week") date: [day] is the week of
///   the month (1-5, where 5 means the last), and [dayOfWeek] is 0 (Sunday)
///   to 6 (Saturday).
/// * Otherwise it's an absolute date: [day] is the day of the month.
///
/// The time of day is wall time: the daylight transition is in standard time
/// and the standard transition is in daylight time.
@immutable
@internal
class WindowsTransitionDate {
  final int year;
  final int month;
  final int dayOfWeek;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final int milliseconds;

  const WindowsTransitionDate(
      {this.year = 0,
      required this.month,
      this.dayOfWeek = 0,
      required this.day,
      this.hour = 0,
      this.minute = 0,
      this.second = 0,
      this.milliseconds = 0});

  /// A transition date meaning "no daylight saving time".
  static const WindowsTransitionDate none =
      WindowsTransitionDate(month: 0, day: 0);

  bool get isNone => month == 0;

  @override
  bool operator ==(Object other) =>
      other is WindowsTransitionDate &&
      year == other.year &&
      month == other.month &&
      dayOfWeek == other.dayOfWeek &&
      day == other.day &&
      hour == other.hour &&
      minute == other.minute &&
      second == other.second &&
      milliseconds == other.milliseconds;

  @override
  int get hashCode => hashObjects(
      [year, month, dayOfWeek, day, hour, minute, second, milliseconds]);

  @override
  String toString() => 'SYSTEMTIME(y:$year m:$month dow:$dayOfWeek d:$day '
      '$hour:$minute:$second.$milliseconds)';
}

/// The rule values of a Win32 `TIME_ZONE_INFORMATION`, in effect for one or
/// more years. Biases are in minutes, with UTC = local time + bias.
@immutable
@internal
class WindowsZoneRule {
  final int bias;
  final int standardBias;
  final int daylightBias;
  final WindowsTransitionDate standardDate;
  final WindowsTransitionDate daylightDate;

  const WindowsZoneRule(
      {required this.bias,
      this.standardBias = 0,
      this.daylightBias = -60,
      this.standardDate = WindowsTransitionDate.none,
      this.daylightDate = WindowsTransitionDate.none});

  /// The UTC offset in standard time: -(Bias + StandardBias).
  Offset get standardOffset => Offset(-(bias + standardBias) * 60);

  /// The UTC offset in daylight time: -(Bias + DaylightBias).
  Offset get daylightOffset => Offset(-(bias + daylightBias) * 60);

  /// The daylight savings: the daylight offset minus the standard offset.
  Offset get savings => Offset((standardBias - daylightBias) * 60);

  /// Whether this rule observes daylight saving time at all.
  ///
  /// Rules with transitions but no difference between the standard and
  /// daylight offsets are treated as standard time only: the offsets are the
  /// same either way, and a zero-savings "daylight" period isn't meaningful.
  /// (Noda Time fakes one hour of savings in this case, for Mono's sake; the
  /// Windows API doesn't need that.)
  bool get observesDaylightTime =>
      !standardDate.isNone &&
      !daylightDate.isNone &&
      savings != Offset.zero &&
      standardDate != daylightDate;

  @override
  bool operator ==(Object other) =>
      other is WindowsZoneRule &&
      bias == other.bias &&
      standardBias == other.standardBias &&
      daylightBias == other.daylightBias &&
      standardDate == other.standardDate &&
      daylightDate == other.daylightDate;

  @override
  int get hashCode => hashObjects(
      [bias, standardBias, daylightBias, standardDate, daylightDate]);

  @override
  String toString() => 'WindowsZoneRule(bias: $bias, standardBias: '
      '$standardBias, daylightBias: $daylightBias, standardDate: '
      '$standardDate, daylightDate: $daylightDate)';
}

/// A [WindowsZoneRule] in effect from [firstYear] to [lastYear] inclusive.
@immutable
@internal
class WindowsYearRule {
  final int firstYear;
  final int lastYear;
  final WindowsZoneRule rule;

  const WindowsYearRule(this.firstYear, this.lastYear, this.rule);

  @override
  String toString() => '$firstYear-$lastYear: $rule';
}

/// Coalesces per-year rules (in ascending year order, with no gaps) into
/// [WindowsYearRule]s covering runs of consecutive years with identical
/// rules.
@internal
List<WindowsYearRule> coalesceWindowsYearRules(
    int firstYear, List<WindowsZoneRule> rulesByYear) {
  var result = <WindowsYearRule>[];
  for (var i = 0; i < rulesByYear.length; i++) {
    var year = firstYear + i;
    var rule = rulesByYear[i];
    if (result.isNotEmpty && result.last.rule == rule) {
      result[result.length - 1] =
          WindowsYearRule(result.last.firstYear, year, rule);
    } else {
      result.add(WindowsYearRule(year, year, rule));
    }
  }
  return result;
}

final LocalTime _oneMillisecondBeforeMidnight = LocalTime(23, 59, 59, ms: 999);

/// Whether [date] is Windows' "start of the year" marker: a floating date in
/// the first week of January at 00:00. The dynamic DST data uses it for a
/// year that starts in daylight time (as the daylight date) or that ends
/// daylight time as the year starts (as the standard date). Its day of the
/// week is the one January 1st has in the year the data was written for, but
/// Windows treats it as January 1st in every year it applies the rule to.
@internal
bool isWindowsStartOfYearMarker(WindowsTransitionDate date) =>
    date.year == 0 &&
    date.month == 1 &&
    date.day == 1 &&
    date.hour == 0 &&
    date.minute == 0 &&
    date.second == 0 &&
    date.milliseconds == 0;

/// Converts a Windows transition date to a [ZoneYearOffset], as Noda Time's
/// `BclDateTimeZone.ConvertTransition` does.
///
/// Windows represents transitions at 24:00 as 23:59:59.999 (so that a rule
/// can say "Saturday 24:00" rather than "Sunday 00:00"). That's clearly a
/// data fudge, so like Noda Time we convert it to midnight at the start of
/// the following day. (Windows itself makes such transitions one millisecond
/// early.)
///
/// The start of year marker (see [isWindowsStartOfYearMarker]) becomes
/// January 1st, as Windows treats it.
@internal
ZoneYearOffset windowsTransitionToZoneYearOffset(WindowsTransitionDate date) {
  if (date.isNone) {
    throw ArgumentError.value(date, 'date', 'No transition (month 0)');
  }
  if (isWindowsStartOfYearMarker(date)) {
    return ZoneYearOffset(
        TransitionMode.wall, 1, 1, 0, false, LocalTime.midnight);
  }

  var timeOfDay =
      LocalTime(date.hour, date.minute, date.second, ms: date.milliseconds);
  var addDay = false;
  if (timeOfDay == _oneMillisecondBeforeMidnight) {
    timeOfDay = LocalTime.midnight;
    addDay = true;
  }

  if (date.year != 0) {
    // An absolute date: only meaningful for its own year, which is the only
    // year a rule with an absolute date is used for.
    return ZoneYearOffset(
        TransitionMode.wall, date.month, date.day, 0, false, timeOfDay, addDay);
  }

  // Floating: e.g. the second Sunday in March. SYSTEMTIME uses 0 = Sunday;
  // ISO uses 7 = Sunday.
  var dayOfWeek = date.dayOfWeek == 0 ? 7 : date.dayOfWeek;
  int dayOfMonth;
  bool advance;
  if (date.day >= 5) {
    // "Last"
    dayOfMonth = -1;
    advance = false;
  } else {
    // Week 1 corresponds to ">=1", week 2 to ">=8" etc.
    dayOfMonth = date.day * 7 - 6;
    advance = true;
  }
  return ZoneYearOffset(TransitionMode.wall, date.month, dayOfMonth, dayOfWeek,
      advance, timeOfDay, addDay);
}

/// Builds a [DateTimeZone] from Windows rules, along the lines of Noda Time's
/// `BclDateTimeZone.BuildMap` for Windows adjustment rules: each rule becomes
/// a [StandardDaylightAlternatingMap] (or a single interval if it has no
/// daylight saving time) for its years, and the pieces are joined with
/// [PartialZoneIntervalMap.convertToFullMap].
///
/// [rules] must be in year order with no gaps. The first rule extends back
/// to the start of time and the last rule forward to the end of time, as
/// Windows uses the first and last years' rules for earlier and later years.
///
/// Where rules meet, this follows what Windows itself does (checked against
/// `SystemTimeToTzSpecificLocalTimeEx` for every zone) rather than what Noda
/// Time does, as Noda Time interprets the boundaries the way .NET's
/// `TimeZoneInfo` does, which doesn't match Windows around some New Years:
///
/// * A rule takes over at 00:00 on January 1st of its first year, local time
///   according to the previous rule (in the offset the previous rule has at
///   the end of its last year). Noda Time uses the zone's current standard
///   offset, which for zones whose offset has changed since can be hours
///   (for Samoa, a day) away.
/// * Start of year markers (see [isWindowsStartOfYearMarker]) only apply at
///   the start of the rule's own years: a rule whose daylight date is the
///   marker starts in daylight time, one whose standard date is the marker
///   starts in standard time, and the marker for the year after a rule's
///   last year doesn't take effect (the next rule decides).
@internal
DateTimeZone buildWindowsZone(String id, String standardName,
    String daylightName, List<WindowsYearRule> rules) {
  Preconditions.checkArgument(rules.isNotEmpty, 'rules', 'No rules');
  if (rules.length == 1 && !rules.single.rule.observesDaylightTime) {
    return FixedDateTimeZone(
        id, rules.single.rule.standardOffset, standardName);
  }

  Offset? minOffset;
  Offset? maxOffset;
  var ruleMaps = <ZoneIntervalMap>[];
  for (var yearRule in rules) {
    var rule = yearRule.rule;
    var standardOffset = rule.standardOffset;
    if (rule.observesDaylightTime) {
      var daylightRecurrence = ZoneRecurrence(
          daylightName,
          rule.savings,
          windowsTransitionToZoneYearOffset(rule.daylightDate),
          Platform.int32MinValue,
          Platform.int32MaxValue);
      var standardRecurrence = ZoneRecurrence(
          standardName,
          Offset.zero,
          windowsTransitionToZoneYearOffset(rule.standardDate),
          Platform.int32MinValue,
          Platform.int32MaxValue);
      ruleMaps.add(StandardDaylightAlternatingMap(
          standardOffset, standardRecurrence, daylightRecurrence));
      minOffset = _min(minOffset, rule.daylightOffset);
      maxOffset = _max(maxOffset, rule.daylightOffset);
    } else {
      ruleMaps.add(SingleZoneIntervalMap(IZoneInterval.newZoneInterval(
          standardName,
          IInstant.beforeMinValue,
          IInstant.afterMaxValue,
          standardOffset,
          Offset.zero)));
    }
    minOffset = _min(minOffset, standardOffset);
    maxOffset = _max(maxOffset, standardOffset);
  }

  Instant startOfYear(int year, Offset offset) =>
      LocalDate(year, 1, 1).atMidnight().withOffset(offset).toInstant();

  // The instant at which rule i's start of year marker for the year after
  // its last year would take effect, or null if it has none.
  Instant? followingYearMarker(int i) {
    var rule = rules[i].rule;
    if (!rule.observesDaylightTime) return null;
    var year = rules[i].lastYear + 1;
    if (isWindowsStartOfYearMarker(rule.daylightDate)) {
      return startOfYear(year, rule.standardOffset);
    }
    if (isWindowsStartOfYearMarker(rule.standardDate)) {
      return startOfYear(year, rule.daylightOffset);
    }
    return null;
  }

  // The zone interval rule i is in at the end of its last year.
  ZoneInterval stateAtEnd(int i) {
    var map = ruleMaps[i];
    var guess =
        startOfYear(rules[i].lastYear + 1, rules[i].rule.standardOffset);
    var interval = map.getZoneInterval(guess - Time.epsilon);
    var marker = followingYearMarker(i);
    if (marker != null && IZoneInterval.rawStart(interval) == marker) {
      interval = map.getZoneInterval(marker - Time.epsilon);
    }
    return interval;
  }

  var boundaries = [
    IInstant.beforeMinValue,
    for (var i = 1; i < rules.length; i++)
      startOfYear(rules[i].firstYear, stateAtEnd(i - 1).wallOffset),
    IInstant.afterMaxValue,
  ];

  var maps = <PartialZoneIntervalMap>[];
  for (var i = 0; i < rules.length; i++) {
    var yearRule = rules[i];
    var rule = yearRule.rule;
    var map = ruleMaps[i];
    var start = boundaries[i];
    var end = boundaries[i + 1];
    if (start >= end) continue;

    // A start of year marker at the start of this rule: the rule starts in
    // daylight (or standard) time, even before the marker's instant in this
    // rule's own offsets.
    if (i > 0 && rule.observesDaylightTime) {
      var year = yearRule.firstYear;
      Instant? markerInstant;
      ZoneInterval? initial;
      if (isWindowsStartOfYearMarker(rule.daylightDate)) {
        markerInstant = startOfYear(year, rule.standardOffset);
        initial = IZoneInterval.newZoneInterval(
            daylightName, null, null, rule.daylightOffset, rule.savings);
      } else if (isWindowsStartOfYearMarker(rule.standardDate)) {
        markerInstant = startOfYear(year, rule.daylightOffset);
        initial = IZoneInterval.newZoneInterval(
            standardName, null, null, rule.standardOffset, Offset.zero);
      }
      if (markerInstant != null && start < markerInstant) {
        var initialEnd = markerInstant < end ? markerInstant : end;
        maps.add(PartialZoneIntervalMap.forSingleZoneInterval(initial!.name,
            start, initialEnd, initial.wallOffset, initial.savings));
        start = initialEnd;
        if (start >= end) continue;
      }
    }

    // The marker for the following year doesn't take effect: this rule's
    // state at the end of its last year continues until the next rule.
    if (i < rules.length - 1) {
      var marker = followingYearMarker(i);
      if (marker != null && start < marker && marker < end) {
        var last = stateAtEnd(i);
        maps.add(PartialZoneIntervalMap(start, marker, map));
        maps.add(PartialZoneIntervalMap.forSingleZoneInterval(
            last.name, marker, end, last.wallOffset, last.savings));
        continue;
      }
    }
    maps.add(PartialZoneIntervalMap(start, end, map));
  }

  var fullMap = PartialZoneIntervalMap.convertToFullMap(maps);
  return MapDateTimeZone(
      id, CachingZoneIntervalMap.cacheMap(fullMap), minOffset!, maxOffset!);
}

Offset _min(Offset? a, Offset b) => a == null || b < a ? b : a;
Offset _max(Offset? a, Offset b) => a == null || b > a ? b : a;
