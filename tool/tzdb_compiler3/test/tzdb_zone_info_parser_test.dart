import 'dart:convert';
import 'package:test/test.dart';
import 'package:time_machine2/src/time_machine_internal.dart';

import '../tzdb/tzdb_zone_info_parser.dart';
import '../tzdb/tokens.dart';
import '../tzdb/tzdb_database.dart';

void main() {
  // Helper methods
  Offset toOffset(int hours, int minutes) {
    return Offset.hoursAndMinutes(hours, minutes);
  }

  void validateCounts(
      TzdbDatabase database, int ruleSets, int zoneLists, int links) {
    expect(database.rules.length, equals(ruleSets), reason: "Rules");
    expect(database.zones.length, equals(zoneLists), reason: "Zones");
    expect(database.aliases.length, equals(links), reason: "Links");
  }

  TzdbDatabase parseText(String text) {
    var parser = TzdbZoneInfoParser();
    var database = TzdbDatabase("version");
    var bytes = utf8.encode(text);
    parser.parser(bytes, database);
    return database;
  }

  group('TzdbZoneInfoParser', () {
    test('ParseDateTimeOfYear_emptyString', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("");
      expect(() => parser.parseDateTimeOfYear(tokens, true),
          throwsA(isA<Exception>()));
    });

    test('ParseDateTimeOfYear_missingAt_invalidForRule', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar lastSun";
      var tokens = Tokens.tokenize(text);
      expect(() => parser.parseDateTimeOfYear(tokens, true),
          throwsA(isA<Exception>()));
    });

    test('ParseDateTimeOfYear_missingOn_invalidForRule', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar";
      var tokens = Tokens.tokenize(text);
      expect(() => parser.parseDateTimeOfYear(tokens, true),
          throwsA(isA<Exception>()));
    });

    test('ParseDateTimeOfYear_missingAt_validForZone', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar lastSun";
      var tokens = Tokens.tokenize(text);
      var actual = parser.parseDateTimeOfYear(tokens, false);
      var expected = ZoneYearOffset(
          TransitionMode.wall, 3, -1, 7, false, LocalTime.midnight);
      expect(actual, equals(expected));
    });

    test('ParseDateTimeOfYear_missingOn_validForZone', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar";
      var tokens = Tokens.tokenize(text);
      var actual = parser.parseDateTimeOfYear(tokens, false);
      var expected = ZoneYearOffset(
          TransitionMode.wall, 3, 1, 0, false, LocalTime.midnight);
      expect(actual, equals(expected));
    });

    test('ParseLine_comment', () {
      const line = "# Comment";
      var database = parseText(line);
      validateCounts(database, 0, 0, 0);
    });

    test('ParseLine_commentWithLeadingWhitespace', () {
      const line = "   # Comment";
      var database = parseText(line);
      validateCounts(database, 0, 0, 0);
    });

    test('ParseLine_emptyString', () {
      var database = parseText("");
      validateCounts(database, 0, 0, 0);
    });

    test('ParseDateTimeOfYear_onAfter', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar Tue>=14 2:00";
      var tokens = Tokens.tokenize(text);
      var actual = parser.parseDateTimeOfYear(tokens, true);
      var expected =
          ZoneYearOffset(TransitionMode.wall, 3, 14, 2, true, LocalTime(2, 0));
      expect(actual, equals(expected));
    });

    test('ParseDateTimeOfYear_onBefore', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar Tue<=14 2:00";
      var tokens = Tokens.tokenize(text);
      var actual = parser.parseDateTimeOfYear(tokens, true);
      var expected =
          ZoneYearOffset(TransitionMode.wall, 3, 14, 2, false, LocalTime(2, 0));
      expect(actual, equals(expected));
    });

    test('ParseDateTimeOfYear_onLast', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar lastTue 2:00";
      var tokens = Tokens.tokenize(text);
      var actual = parser.parseDateTimeOfYear(tokens, true);
      var expected =
          ZoneYearOffset(TransitionMode.wall, 3, -1, 2, false, LocalTime(2, 0));
      expect(actual, equals(expected));
    });

    test('ParseLine_commentAtEndOfLine', () {
      var line = "Link from to#Comment";
      var database = parseText(line);
      validateCounts(database, 0, 0, 1);
      expect(database.aliases["to"], equals("from"));
    });

    test('ParseLine_link', () {
      const line = "Link from to";
      var database = parseText(line);
      validateCounts(database, 0, 0, 1);
    });

    test('ParseLine_whiteSpace', () {
      const line = "    \t\t\n";
      var database = parseText(line);
      validateCounts(database, 0, 0, 0);
    });

    test('ParseLine_zone', () {
      const line = "Zone PST 2:00 US P%sT";
      var database = parseText(line);
      validateCounts(database, 0, 1, 0);
      expect(database.zones.values.single.length, equals(1));
    });

    test('ParseLine_zonePlus', () {
      var lines = "Zone PST 2:00 US P%sT\n"
          "  3:00 US P%sT";
      var database = parseText(lines);
      validateCounts(database, 0, 1, 0);
      expect(database.zones["PST"]!.length, equals(2));
    });

    test('ParseLink_emptyString_exception', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("");
      expect(() => parser.parseLink(tokens), throwsA(isA<Exception>()));
    });

    test('ParseLink_simple', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("from to");
      var actual = parser.parseLink(tokens);
      expect(actual[0], equals("from"));
      expect(actual[1], equals("to"));
    });

    test('ParseLink_tooFewWords_exception', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("from");
      expect(() => parser.parseLink(tokens), throwsA(isA<Exception>()));
    });

    test('ParseMonth_nullOrEmpty', () {
      expect(() => TzdbZoneInfoParser.parseMonth(""),
          throwsA(isA<ArgumentError>()));
    });

    test('ParseMonth_invalidMonth', () {
      expect(() => TzdbZoneInfoParser.parseMonth("Able"),
          throwsA(isA<Exception>()));
    });

    test('ParseMonth_shortMonthNames', () {
      var shortMonths = [
        '',
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      for (int i = 1; i <= 12; i++) {
        expect(TzdbZoneInfoParser.parseMonth(shortMonths[i]), equals(i));
      }
    });

    test('ParseMonth_longMonthNames', () {
      var longMonths = [
        '',
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ];
      for (int i = 1; i <= 12; i++) {
        expect(TzdbZoneInfoParser.parseMonth(longMonths[i]), equals(i));
      }
    });

    test('ParseZone_badOffset_exception', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("asd US P%sT 1969 Mar 23 14:53:27.856s");
      expect(
          () => parser.parseZone("", tokens), throwsA(isA<FormatException>()));
    });

    test('ParseZone_emptyString_exception', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("");
      expect(() => parser.parseZone("", tokens), throwsA(isA<Exception>()));
    });

    test('ParseZone_optionalRule', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 - P%sT");
      var expected = ZoneLine("", toOffset(2, 0), null, "P%sT",
          Platform.int32MaxValue, ZoneYearOffset.startOfYear);
      expect(parser.parseZone("", tokens), equals(expected));
    });

    test('ParseZone_simple', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 US P%sT");
      var expected = ZoneLine("", toOffset(2, 0), "US", "P%sT",
          Platform.int32MaxValue, ZoneYearOffset.startOfYear);
      expect(parser.parseZone("", tokens), equals(expected));
    });

    test('ParseZone_tooFewWords1_exception', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 US");
      expect(() => parser.parseZone("", tokens), throwsA(isA<Exception>()));
    });

    test('ParseZone_tooFewWords2_exception', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00");
      expect(() => parser.parseZone("", tokens), throwsA(isA<Exception>()));
    });

    test('ParseZone_withYear', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 US P%sT 1969");
      var expected = ZoneLine(
          "",
          toOffset(2, 0),
          "US",
          "P%sT",
          1969,
          ZoneYearOffset(
              TransitionMode.wall, 1, 1, 0, false, LocalTime.midnight));
      expect(parser.parseZone("", tokens), equals(expected));
    });

    test('ParseZone_withYearMonthDay', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 US P%sT 1969 Mar 23");
      var expected = ZoneLine(
          "",
          toOffset(2, 0),
          "US",
          "P%sT",
          1969,
          ZoneYearOffset(
              TransitionMode.wall, 3, 23, 0, false, LocalTime.midnight));
      expect(parser.parseZone("", tokens), equals(expected));
    });

    test('ParseZone_withYearMonthDayTime', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 US P%sT 1969 Mar 23 14:53:27.856");
      var expected = ZoneLine(
          "",
          toOffset(2, 0),
          "US",
          "P%sT",
          1969,
          ZoneYearOffset(TransitionMode.wall, 3, 23, 0, false,
              LocalTime(14, 53, 27, 856)));
      expect(parser.parseZone("", tokens), equals(expected));
    });

    test('ParseZone_withYearMonthDayTimeZone', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 US P%sT 1969 Mar 23 14:53:27.856s");
      var expected = ZoneLine(
          "",
          toOffset(2, 0),
          "US",
          "P%sT",
          1969,
          ZoneYearOffset(TransitionMode.standard, 3, 23, 0, false,
              LocalTime(14, 53, 27, 856)));
      expect(parser.parseZone("", tokens), equals(expected));
    });

    test('ParseZone_withDayOfWeek', () {
      var parser = TzdbZoneInfoParser();
      var tokens = Tokens.tokenize("2:00 US P%sT 1969 Mar lastSun");
      var expected = ZoneLine(
          "",
          toOffset(2, 0),
          "US",
          "P%sT",
          1969,
          ZoneYearOffset(
              TransitionMode.wall, 3, -1, 7, false, LocalTime.midnight));
      expect(parser.parseZone("", tokens), equals(expected));
    });

    test('Parse_threeLines', () {
      const text = "# A comment\n"
          "Zone PST 2:00 US P%sT\n"
          "         3:00 -  P%sT\n";
      var database = parseText(text);
      validateCounts(database, 0, 1, 0);
      expect(database.zones.values.single.length, equals(2));
    });

    test('Parse_threeLinesWithComment', () {
      const text = "# A comment\n"
          "Zone PST 2:00 US P%sT # An end of line comment\n"
          "         3:00 -  P%sT\n";
      var database = parseText(text);
      validateCounts(database, 0, 1, 0);
      expect(database.zones.values.single.length, equals(2));
    });

    test('Parse_twoLines', () {
      const text = "# A comment\n"
          "Zone PST 2:00 US P%sT\n";
      var database = parseText(text);
      validateCounts(database, 0, 1, 0);
      expect(database.zones.values.single.length, equals(1));
    });

    test('Parse_twoLinks', () {
      const text = "# First line must be a comment\n"
          "Link from to\n"
          "Link target source\n";
      var database = parseText(text);
      validateCounts(database, 0, 0, 2);
    });

    test('Parse_twoZones', () {
      const text = "# A comment\n"
          "Zone PST 2:00 US P%sT # An end of line comment\n"
          "         3:00 -  P%sT\n"
          "         4:00 -  P%sT\n"
          "Zone EST 2:00 US E%sT # An end of line comment\n"
          "         3:00 -  E%sT\n";
      var database = parseText(text);
      validateCounts(database, 0, 2, 0);
      expect(database.zones["PST"]!.length, equals(3));
      expect(database.zones["EST"]!.length, equals(2));
    });

    test('Parse_twoZonesTwoRule', () {
      const text = "# A comment\n"
          "Rule US 1987 2006 - Apr Sun>=1 2:00 1:00 D\n"
          "Rule US 2007 max  - Mar Sun>=8 2:00 1:00 D\n"
          "Zone PST 2:00 US P%sT # An end of line comment\n"
          "         3:00 -  P%sT\n"
          "         4:00 -  P%sT\n"
          "Zone EST 2:00 US E%sT # An end of line comment\n"
          "         3:00 -  E%sT\n";
      var database = parseText(text);
      validateCounts(database, 1, 2, 0);
      expect(database.zones["PST"]!.length, equals(3));
      expect(database.zones["EST"]!.length, equals(2));
    });

    test('Parse_2500_FromDay_AtLeast_Sunday', () {
      var parser = TzdbZoneInfoParser();
      const text = "Apr Sun>=1  25:00";
      var tokens = Tokens.tokenize(text);
      var rule = parser.parseDateTimeOfYear(tokens, true);
      var actual = rule.getOccurrenceForYear(2012);
      var expected = LocalDateTime(2012, 4, 2, 1, 0).toLocalInstant();
      expect(actual, equals(expected));
    });

    test('Parse_2400_FromDay_AtLeast_Sunday', () {
      var parser = TzdbZoneInfoParser();
      const text = "Apr Sun>=1  24:00";
      var tokens = Tokens.tokenize(text);
      var rule = parser.parseDateTimeOfYear(tokens, true);
      var actual = rule.getOccurrenceForYear(2012);
      var expected = LocalDateTime(2012, 4, 2, 0, 0).toLocalInstant();
      expect(actual, equals(expected));
    });

    test('Parse_2400_FromDay_AtMost_Sunday', () {
      var parser = TzdbZoneInfoParser();
      const text = "Apr Sun<=7  24:00";
      var tokens = Tokens.tokenize(text);
      var rule = parser.parseDateTimeOfYear(tokens, true);
      var actual = rule.getOccurrenceForYear(2012);
      var expected = LocalDateTime(2012, 4, 2, 0, 0).toLocalInstant();
      expect(actual, equals(expected));
    });

    test('Parse_2400_FromDay_AtLeast_Wednesday', () {
      var parser = TzdbZoneInfoParser();
      const text = "Apr Wed>=1  24:00";
      var tokens = Tokens.tokenize(text);
      var rule = parser.parseDateTimeOfYear(tokens, true);
      var actual = rule.getOccurrenceForYear(2012);
      var expected = LocalDateTime(2012, 4, 5, 0, 0).toLocalInstant();
      expect(actual, equals(expected));
    });

    test('Parse_2400_FromDay_AtMost_Wednesday', () {
      var parser = TzdbZoneInfoParser();
      const text = "Apr Wed<=14  24:00";
      var tokens = Tokens.tokenize(text);
      var rule = parser.parseDateTimeOfYear(tokens, true);
      var actual = rule.getOccurrenceForYear(2012);
      var expected = LocalDateTime(2012, 4, 12, 0, 0).toLocalInstant();
      expect(actual, equals(expected));
    });

    test('Parse_2400_FromDay', () {
      var parser = TzdbZoneInfoParser();
      const text = "Apr Sun>=1  24:00";
      var tokens = Tokens.tokenize(text);
      var actual = parser.parseDateTimeOfYear(tokens, true);
      var expected = ZoneYearOffset(
          TransitionMode.wall, 4, 1, 7, true, LocalTime.midnight, true);
      expect(actual, equals(expected));
    });

    test('Parse_2400_Last', () {
      var parser = TzdbZoneInfoParser();
      const text = "Mar lastSun 24:00";
      var tokens = Tokens.tokenize(text);
      var actual = parser.parseDateTimeOfYear(tokens, true);
      var expected = ZoneYearOffset(
          TransitionMode.wall, 3, -1, 7, false, LocalTime.midnight, true);
      expect(actual, equals(expected));
    });

    test('Parse_Fixed_Eastern', () {
      const text = "# A comment\n"
          "Zone\tEtc/GMT-9\t9\t-\tGMT-9\n";
      var database = parseText(text);

      validateCounts(database, 0, 1, 0);
      var zone = database.zones["Etc/GMT-9"]!.single;
      expect(zone.standardOffset, equals(Offset.hoursAndMinutes(9, 0)));
      expect(zone.rules, isNull);
      expect(zone.untilYear, equals(Platform.int32MaxValue));
    });

    test('Parse_Fixed_Western', () {
      const text = "# A comment\n"
          "Zone\tEtc/GMT+9\t-9\t-\tGMT+9\n";
      var database = parseText(text);

      validateCounts(database, 0, 1, 0);
      var zone = database.zones["Etc/GMT+9"]!.single;
      expect(zone.standardOffset, equals(Offset.hoursAndMinutes(-9, 0)));
      expect(zone.rules, isNull);
      expect(zone.untilYear, equals(Platform.int32MaxValue));
    });

    test('Parse_RuleWithType', () {
      String line = "Rule BrokenRule 2010 2020 odd Apr Sun>=1 2:00 1:00 D\n";
      expect(() => parseText(line), throwsA(isA<UnimplementedError>()));
    });
  });
}
