// Copyright 2009 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0,
// as found in the LICENSE.txt file.

import 'dart:convert';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'tokens.dart';
import 'tzdb_database.dart';
import 'parser_helper.dart';
import 'zone_line.dart';
import 'rule_line.dart';

/// Provides a parser for TZDB time zone description files.
class TzdbZoneInfoParser {
  /// An offset that specifies the beginning of the year.
  static final ZoneYearOffset startOfYearZoneOffset = ZoneYearOffset(
    TransitionMode.wall,
    1,
    1,
    0,
    false,
    LocalTime.midnight,
  );

  /// The keyword that specifies the line defines an alias link.
  static const String keywordLink = 'Link';

  /// The keyword that specifies the line defines a daylight savings rule.
  static const String keywordRule = 'Rule';

  /// The keyword that specifies the line defines a time zone.
  static const String keywordZone = 'Zone';

  /// The days of the week names as they appear in the TZDB zone files.
  /// They are always the short name in US English.
  static const List<String> daysOfWeek = [
    '',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  /// The months of the year names as they appear in the TZDB zone files.
  /// They are always the short name in US English.
  static const List<String> shortMonths = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  /// The long month names (for older files).
  static const List<String> longMonths = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  int _nextMonth(Tokens tokens, String name) {
    String value = _nextString(tokens, name);
    return parseMonth(value);
  }

  Offset _nextOffset(Tokens tokens, String name) {
    return ParserHelper.parseOffset(_nextString(tokens, name));
  }

  String? _nextOptional(Tokens tokens, String name) {
    return ParserHelper.parseOptional(_nextString(tokens, name));
  }

  String _nextString(Tokens tokens, String name) {
    if (!tokens.hasNextToken) {
      throw FormatException('Missing zone info token: $name');
    }
    return tokens.nextToken(name);
  }

  static int _nextYear(Tokens tokens, int defaultValue) {
    if (tokens.tryNextToken()) {
      return ParserHelper.parseYear(tokens.currentToken, defaultValue);
    }
    return defaultValue;
  }

  void parse(Stream<List<int>> input, TzdbDatabase database) {
    parseFromReader(
        utf8.decoder.bind(input).transform(LineSplitter()), database);
  }

  void parseFromReader(Stream<String> reader, TzdbDatabase database) async {
    String? currentZone;
    await for (final line in reader) {
      currentZone = _parseLine(line, currentZone, database);
    }
  }

  ZoneYearOffset parseDateTimeOfYear(Tokens tokens, bool forRule) {
    TransitionMode mode = startOfYearZoneOffset.mode;
    LocalTime timeOfDay = startOfYearZoneOffset.timeOfDay;

    int monthOfYear = _nextMonth(tokens, 'MonthOfYear');

    int dayOfMonth = 1;
    int dayOfWeek = 0;
    bool advanceDayOfWeek = false;
    bool addDay = false;

    if (tokens.hasNextToken || forRule) {
      String on = _nextString(tokens, 'On');
      if (on.startsWith('last')) {
        dayOfMonth = -1;
        dayOfWeek = _parseDayOfWeek(on.substring(4));
      } else {
        int index = on.indexOf('>=');
        if (index > 0) {
          dayOfMonth = int.parse(on.substring(index + 2));
          dayOfWeek = _parseDayOfWeek(on.substring(0, index));
          advanceDayOfWeek = true;
        } else {
          index = on.indexOf('<=');
          if (index > 0) {
            dayOfMonth = int.parse(on.substring(index + 2));
            dayOfWeek = _parseDayOfWeek(on.substring(0, index));
          } else {
            dayOfMonth = int.parse(on);
          }
        }
      }

      if (tokens.hasNextToken || forRule) {
        String atTime = _nextString(tokens, 'AT');
        if (atTime.isNotEmpty) {
          if (atTime.endsWith('s')) {
            mode = TransitionMode.standard;
            atTime = atTime.substring(0, atTime.length - 1);
          }
          if (atTime == '24:00') {
            timeOfDay = LocalTime.midnight;
            addDay = true;
          } else {
            timeOfDay = ParserHelper.parseTime(atTime);
          }
        }
      }
    }

    return ZoneYearOffset(
      mode,
      monthOfYear,
      dayOfMonth,
      dayOfWeek,
      advanceDayOfWeek,
      timeOfDay,
      addDay,
    );
  }

  int _parseDayOfWeek(String text) {
    Preconditions.checkArgument(
        text.isNotEmpty, 'Value must not be empty or null');
    int index = daysOfWeek.indexOf(text);
    if (index == -1) {
      throw FormatException('Invalid day of week: $text');
    }
    return index;
  }

  String? _parseLine(String line, String? previousZone, TzdbDatabase database) {
    int index = line.indexOf('#');
    if (index >= 0) {
      line = line.substring(0, index);
    }
    line = line.trim();
    if (line.isEmpty) {
      return previousZone;
    }

    Tokens tokens = Tokens.tokenize(line);
    String keyword = _nextString(tokens, 'Keyword');
    switch (keyword) {
      case keywordRule:
        database.addRule(_parseRule(tokens));
        return null;
      case keywordLink:
        var alias = _parseLink(tokens);
        database.addAlias(alias.item1, alias.item2);
        return null;
      case keywordZone:
        var name = _nextString(tokens, 'Name');
        database.addZone(_parseZone(name, tokens));
        return name;
      default:
        if (keyword.isEmpty) {
          if (previousZone == null) {
            throw FormatException('Zone continuation with no previous zone');
          }
          database.addZone(_parseZone(previousZone, tokens));
          return previousZone;
        } else {
          throw FormatException('Unexpected keyword: $keyword');
        }
    }
  }

  Tuple<String, String> _parseLink(Tokens tokens) {
    String existing = _nextString(tokens, 'Existing');
    String alias = _nextString(tokens, 'Alias');
    return Tuple(existing, alias);
  }

  RuleLine _parseRule(Tokens tokens) {
    String name = _nextString(tokens, 'Name');
    int fromYear = _nextYear(tokens, 0);
    int toYear = _nextYear(tokens, fromYear);

    String? type = _nextOptional(tokens, 'Type');
    if (type != null) {
      throw UnsupportedError('Rule types are not supported.');
    }

    ZoneYearOffset yearOffset = parseDateTimeOfYear(tokens, true);
    Offset savings = _nextOffset(tokens, 'SaveMillis');
    String? daylightSavingsIndicator = _nextOptional(tokens, 'LetterS');

    ZoneRecurrence recurrence =
        ZoneRecurrence(name, savings, yearOffset, fromYear, toYear);
    return RuleLine(recurrence, daylightSavingsIndicator);
  }

  ZoneLine _parseZone(String name, Tokens tokens) {
    Offset offset = _nextOffset(tokens, 'GmtOffset');
    String? rules = _nextOptional(tokens, 'Rules');
    String format = _nextString(tokens, 'Format');
    int year = _nextYear(tokens, 9999);

    if (tokens.hasNextToken) {
      ZoneYearOffset until = parseDateTimeOfYear(tokens, false);
      return ZoneLine(name, offset, rules, format, year, until);
    }
    return ZoneLine(name, offset, rules, format, year, startOfYearZoneOffset);
  }

  static int parseMonth(String text) {
    Preconditions.checkArgument(
        text.isNotEmpty, 'Value must not be empty or null');
    int index = shortMonths.indexOf(text);
    if (index == -1) {
      index = longMonths.indexOf(text);
      if (index == -1) {
        throw FormatException('Invalid month: $text');
      }
    }
    return index;
  }
}
