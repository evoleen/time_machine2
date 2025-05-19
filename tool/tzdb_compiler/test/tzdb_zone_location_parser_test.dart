import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import '../tzdb/tzdb_zone_location_parser.dart';

void main() {
  final sampleCountryMapping = {
    'CA': 'Canada',
    'GB': 'Britain (UK)',
  };

  group('TzdbZoneLocationParser', () {
    group('parseLocation', () {
      test('throws ArgumentError when line has too few values', () {
        expect(
          () => TzdbZoneLocationParser.parseLocation(
              '0\t1', sampleCountryMapping),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when line has too many values', () {
        expect(
          () => TzdbZoneLocationParser.parseLocation(
              '0\t1\t2\t3\t4', sampleCountryMapping),
          throwsArgumentError,
        );
      });

      test('throws StateError for invalid country code', () {
        // Valid line, but not with our country code mapping...
        String line = 'FK\t-5142-05751\tAtlantic/Stanley';
        expect(
          () =>
              TzdbZoneLocationParser.parseLocation(line, sampleCountryMapping),
          throwsStateError,
        );
      });

      test('parses valid line without comment', () {
        String line = 'GB\t+4000+03000\tEurope/London';
        var location =
            TzdbZoneLocationParser.parseLocation(line, sampleCountryMapping);
        expect(location.countryCode, equals('GB'));
        expect(location.countryName, equals('Britain (UK)'));
        expect(location.latitude, equals(40));
        expect(location.longitude, equals(30));
        expect(location.zoneId, equals('Europe/London'));
        expect(location.comment, equals(''));
      });

      test('parses valid line with comment', () {
        String line = 'GB\t+4000+03000\tEurope/London\tSome comment';
        var location =
            TzdbZoneLocationParser.parseLocation(line, sampleCountryMapping);
        expect(location.countryCode, equals('GB'));
        expect(location.countryName, equals('Britain (UK)'));
        expect(location.latitude, equals(40));
        expect(location.longitude, equals(30));
        expect(location.zoneId, equals('Europe/London'));
        expect(location.comment, equals('Some comment'));
      });
    });

    group('parseEnhancedLocation', () {
      test('parses valid enhanced location', () {
        final countries = {
          'CA': TzdbZone1970LocationCountry('Canada', 'CA'),
          'GB': TzdbZone1970LocationCountry('Britain (UK)', 'GB'),
          'US': TzdbZone1970LocationCountry('United States', 'US'),
        };
        String line = 'GB,CA\t+4000+03000\tEurope/London';
        var location =
            TzdbZoneLocationParser.parseEnhancedLocation(line, countries);
        expect(location.countries, equals([countries['GB'], countries['CA']]));
        expect(location.latitude, equals(40));
        expect(location.longitude, equals(30));
        expect(location.zoneId, equals('Europe/London'));
        expect(location.comment, equals(''));
      });
    });

    group('_parseCoordinates', () {
      test('throws ArgumentError for invalid length', () {
        expect(
          () => TzdbZoneLocationParser.parseCoordinates('-77+166'),
          throwsArgumentError,
        );
      });

      test('parses various coordinate formats', () {
        var testCases = {
          '+4512+10034': [45 * 3600 + 12 * 60, 100 * 3600 + 34 * 60],
          '-0502+00134': [-5 * 3600 - 2 * 60, 1 * 3600 + 34 * 60],
          '+0000-00001': [0, -1 * 60],
          '+451205+1003402': [
            45 * 3600 + 12 * 60 + 5,
            100 * 3600 + 34 * 60 + 2
          ],
          '-050205+0013402': [-5 * 3600 - 2 * 60 - 5, 1 * 3600 + 34 * 60 + 2],
          '+000005-0000102': [5, -1 * 60 - 2],
        };

        testCases.forEach((input, expected) {
          var actual = TzdbZoneLocationParser.parseCoordinates(input);
          expect(actual[0], equals(expected[0]),
              reason: 'Latitude mismatch for $input');
          expect(actual[1], equals(expected[1]),
              reason: 'Longitude mismatch for $input');
        });
      });
    });
  });
}
