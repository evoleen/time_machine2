class TimeZoneInfo {
  final String standardName;
  final int standardOffset;
  final String? daylightName;
  final int? daylightOffset;
  final TransitionRule? startRule;
  final TransitionRule? endRule;

  TimeZoneInfo({
    required this.standardName,
    required this.standardOffset,
    this.daylightName,
    this.daylightOffset,
    this.startRule,
    this.endRule,
  });

  @override
  String toString() {
    return 'TimeZoneInfo(standardName: $standardName, standardOffset: $standardOffset, daylightName: $daylightName, daylightOffset: $daylightOffset, startRule: $startRule, endRule: $endRule)';
  }
}

abstract class TransitionRule {}

class JulianDayRule extends TransitionRule {
  final int day;
  final bool leapIncluded;

  JulianDayRule({required this.day, required this.leapIncluded});

  @override
  String toString() {
    return 'JulianDayRule(day: $day, leapIncluded: $leapIncluded)';
  }
}

class MonthlyRule extends TransitionRule {
  final int month;
  final int week;
  final int weekday;
  final int hour;

  MonthlyRule(
      {required this.month,
      required this.week,
      required this.weekday,
      required this.hour});

  @override
  String toString() {
    return 'MonthlyRule(month: $month, week: $week, weekday: $weekday, hour: $hour)';
  }
}

TimeZoneInfo parsePosixTimeZone(String posixString) {
  final pattern = RegExp(
      r'^(?<std><[A-Za-z0-9+-]+>|[A-Za-z]{3,})(?<stdOffset>[-+]?\d{1,2}(:\d{2}(:\d{2})?)?)(?<dst><[A-Za-z0-9+-]+>|[A-Za-z]{3,})?(?<dstOffset>[-+]?\d{1,2}(:\d{2}(:\d{2})?)?)?(?:,(?<start>[^,]+),(?<end>[^,]+))?$');

  final match = pattern.firstMatch(posixString);
  if (match == null) {
    throw FormatException('Invalid POSIX timezone string');
  }

  String parseName(String? name) {
    if (name == null) throw FormatException('Missing time zone name');
    return name.startsWith('<') && name.endsWith('>')
        ? name.substring(1, name.length - 1)
        : name;
  }

  int parseOffset(String offset) {
    final parts = offset.split(':');
    int hours = int.parse(parts[0]);
    int minutes = parts.length > 1 ? int.parse(parts[1]) : 0;
    int seconds = parts.length > 2 ? int.parse(parts[2]) : 0;
    return (hours.abs() * 3600 + minutes * 60 + seconds) *
        (offset.startsWith('-') ? -1 : 1);
  }

  TransitionRule? parseRule(String? rule) {
    if (rule == null) return null;

    final julianPattern = RegExp(r'^(J(?<julianDay>\d+)|(?<day>\d+))$');
    final monthlyPattern = RegExp(
        r'^M(?<month>\d+)\.(?<week>\d+)\.(?<weekday>\d+)(/(?<hour>[-+]?\d+(:\d{2}(:\d{2})?)?))?$');

    final julianMatch = julianPattern.firstMatch(rule);
    if (julianMatch != null) {
      final day = int.parse(julianMatch.namedGroup('julianDay') ??
          julianMatch.namedGroup('day')!);
      final leapIncluded = julianMatch.namedGroup('julianDay') != null;
      return JulianDayRule(day: day, leapIncluded: leapIncluded);
    }

    final monthlyMatch = monthlyPattern.firstMatch(rule);
    if (monthlyMatch != null) {
      final month = int.parse(monthlyMatch.namedGroup('month')!);
      final week = int.parse(monthlyMatch.namedGroup('week')!);
      final weekday = int.parse(monthlyMatch.namedGroup('weekday')!);
      final hour = monthlyMatch.namedGroup('hour') != null
          ? parseOffset(monthlyMatch.namedGroup('hour')!) ~/ 3600
          : 2; // Default to 02:00
      return MonthlyRule(
          month: month, week: week, weekday: weekday, hour: hour);
    }

    throw FormatException('Invalid transition rule: $rule');
  }

  final standardName = parseName(match.namedGroup('std'));
  final standardOffset = match.namedGroup('stdOffset') != null
      ? parseOffset(match.namedGroup('stdOffset')!)
      : 0;
  final daylightName = match.namedGroup('dst') != null
      ? parseName(match.namedGroup('dst'))
      : null;
  final daylightOffset = match.namedGroup('dstOffset') != null
      ? parseOffset(match.namedGroup('dstOffset')!)
      : (daylightName != null ? standardOffset - 3600 : null);
  final startRule = parseRule(match.namedGroup('start'));
  final endRule = parseRule(match.namedGroup('end'));

  return TimeZoneInfo(
    standardName: standardName,
    standardOffset: standardOffset,
    daylightName: daylightName,
    daylightOffset: daylightOffset,
    startRule: startRule,
    endRule: endRule,
  );
}

void main() {
  // const posixString = "CET-1CEST,M3.5.0,M10.5.0/3";
  const posixString = "EET-2EEST,M3.5.0/3,M10.5.0/4";
  // const posixString = "WET0WEST,M3.5.0/1,M10.5.0";

  try {
    final timeZoneInfo = parsePosixTimeZone(posixString);
    print(timeZoneInfo);
  } catch (e) {
    print('Error: $e');
  }
}
