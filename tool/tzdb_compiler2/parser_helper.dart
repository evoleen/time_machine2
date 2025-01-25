import 'package:time_machine2/time_machine2.dart';
import 'dart:core';

class ParserHelper {
  static final List<LocalTimePattern> _timePatterns = [
    LocalTimePattern.createWithInvariantCulture("H:mm:ss.FFF"),
    LocalTimePattern.createWithInvariantCulture("H:mm"),
    LocalTimePattern.createWithInvariantCulture("%H"),
    // Handle "somewhat broken" data such as a DAVT rule in Antarctica 2009r, with a date/time of "2009 Oct 18 2:0"
    LocalTimePattern.createWithInvariantCulture("H:m")
  ];

  /// Converts an hour string to its equivalent in ticks.
  static int convertHourToTicks(String text) {
    if (text == null) throw ArgumentError.notNull('text');
    final value = int.parse(text);
    if (value < -23 || value > 23) {
      throw FormatException("Hours out of valid range [-23, 23]: $value");
    }
    return value * TimeConstants.ticksPerHour;
  }

  /// Converts a minute string to its equivalent in ticks.
  static int convertMinuteToTicks(String text) {
    if (text == null) throw ArgumentError.notNull('text');
    final value = int.parse(text.trim());
    if (value < 0 || value > 59) {
      throw FormatException("Minutes out of valid range [0, 59]: $value");
    }
    return value * TimeConstants.ticksPerMinute;
  }

  /// Converts a second string with fractional parts to its equivalent in ticks.
  static int convertSecondsWithFractionalToTicks(String text) {
    if (text == null) throw ArgumentError.notNull('text');
    final number = double.parse(text.trim());
    if (number < 0.0 || number >= 60.0) {
      throw FormatException("Seconds out of valid range [0, 60): $number");
    }
    return (number *
            TimeConstants.millisecondsPerSecond *
            TimeConstants.ticksPerMillisecond)
        .toInt();
  }

  /// Formats an optional string, converting null to '-'.
  static String formatOptional(String? value) => value ?? "-";

  /// Parses an integer from the given text or returns a default value if parsing fails.
  static int parseInteger(String? text, int defaultValue) {
    if (text == null) return defaultValue;
    return int.tryParse(text.trim()) ?? defaultValue;
  }

  /// Parses a time offset string into an Offset object.
  static Offset parseOffset(String text) {
    if (text == null) throw ArgumentError.notNull('text');
    if (text == "-") return Offset(0);

    var sign = 1;
    if (text.startsWith("-")) {
      sign = -1;
      text = text.substring(1);
    }
    final parts = text.split(":");
    if (parts.length > 3) {
      throw FormatException("Offset has too many parts (max 3 allowed): $text");
    }

    var ticks = convertHourToTicks(parts[0]);
    if (parts.length > 1) {
      ticks += convertMinuteToTicks(parts[1]);
      if (parts.length > 2) {
        ticks += convertSecondsWithFractionalToTicks(parts[2]);
      }
    }
    return Offset(sign * ticks);
  }

  /// Parses a time string into a LocalTime object.
  static LocalTime parseTime(String text) {
    for (var pattern in _timePatterns) {
      try {
        return pattern.parse(text).value;
      } catch (_) {
        // Ignore and try the next pattern
      }
    }
    throw FormatException("Invalid time in rules: $text");
  }

  /// Parses an optional string value, returning null if the string is "-".
  static String? parseOptional(String text) {
    if (text == null) throw ArgumentError.notNull('text');
    return text == "-" ? null : text;
  }

  /// Parses a year string, returning the parsed value or handling special cases like "min", "max", and "only".
  static int parseYear(String text, int defaultValue) {
    if (text == null) throw ArgumentError.notNull('text');
    final lowerText = text.toLowerCase();
    switch (lowerText) {
      case "min":
      case "minimum":
        return double.negativeInfinity.toInt();
      case "max":
      case "maximum":
        return double.infinity.toInt();
      case "only":
        return defaultValue;
      default:
        return int.parse(text.trim());
    }
  }
}
