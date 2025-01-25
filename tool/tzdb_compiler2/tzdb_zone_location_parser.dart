import 'tzdb_zone_1970_location.dart';
import 'tzdb_zone_location.dart';

/// Provides parsing functionality for zone location data from zone.tab and iso3166.tab.
///
/// Stateless and static, this class is separate for organizational clarity.
class TzdbZoneLocationParser {
  /// Parses a zone location line into a [TzdbZoneLocation].
  static TzdbZoneLocation parseLocation(
    String line,
    Map<String, String> countryMapping,
  ) {
    final parts = line.split('\t');
    Preconditions.checkArgument(
      parts.length == 3 || parts.length == 4,
      'Line must have 3 or 4 tab-separated values',
    );

    final countryCode = parts[0];
    final countryName = countryMapping[countryCode] ??
        (throw ArgumentError('Unknown country code: $countryCode'));
    final latLong = parseCoordinates(parts[1]);
    final zoneId = parts[2];
    final comment = parts.length == 4 ? parts[3] : '';

    return TzdbZoneLocation(
      latitude: latLong[0],
      longitude: latLong[1],
      countryName: countryName,
      countryCode: countryCode,
      zoneId: zoneId,
      comment: comment,
    );
  }

  /// Parses an enhanced zone location line into a [TzdbZone1970Location].
  static TzdbZone1970Location parseEnhancedLocation(
    String line,
    Map<String, TzdbZone1970LocationCountry> countryMapping,
  ) {
    final parts = line.split('\t');
    Preconditions.checkArgument(
      parts.length == 3 || parts.length == 4,
      'Line must have 3 or 4 tab-separated values',
    );

    final countryCodes = parts[0];
    final countries = countryCodes.split(',').map((code) {
      return countryMapping[code] ??
          (throw ArgumentError('Unknown country code: $code'));
    }).toList();
    final latLong = parseCoordinates(parts[1]);
    final zoneId = parts[2];
    final comment = parts.length == 4 ? parts[3] : '';

    return TzdbZone1970Location(
      latitude: latLong[0],
      longitude: latLong[1],
      countries: countries,
      zoneId: zoneId,
      comment: comment,
    );
  }

  /// Parses a string such as "-7750+16636" or "+484531-0913718" into a pair
  /// of integer values: the latitude and longitude of the coordinates, in seconds.
  static List<int> parseCoordinates(String text) {
    Preconditions.checkArgument(
      text.length == 11 || text.length == 15,
      'Invalid coordinates',
    );

    late int latDegrees, latMinutes, latSeconds, latSign;
    late int longDegrees, longMinutes, longSeconds, longSign;

    if (text.length == 11) {
      // +-DDMM+-DDDMM
      latSign = text[0] == '-' ? -1 : 1;
      latDegrees = int.parse(text.substring(1, 3));
      latMinutes = int.parse(text.substring(3, 5));
      latSeconds = 0;

      longSign = text[5] == '-' ? -1 : 1;
      longDegrees = int.parse(text.substring(6, 9));
      longMinutes = int.parse(text.substring(9, 11));
      longSeconds = 0;
    } else {
      // +-DDMMSS+-DDDMMSS
      latSign = text[0] == '-' ? -1 : 1;
      latDegrees = int.parse(text.substring(1, 3));
      latMinutes = int.parse(text.substring(3, 5));
      latSeconds = int.parse(text.substring(5, 7));

      longSign = text[7] == '-' ? -1 : 1;
      longDegrees = int.parse(text.substring(8, 11));
      longMinutes = int.parse(text.substring(11, 13));
      longSeconds = int.parse(text.substring(13, 15));
    }

    return [
      latSign * (latDegrees * 3600 + latMinutes * 60 + latSeconds),
      longSign * (longDegrees * 3600 + longMinutes * 60 + longSeconds),
    ];
  }
}

/// Utility class for precondition checks.
class Preconditions {
  static void checkArgument(bool condition, String message) {
    if (!condition) {
      throw ArgumentError(message);
    }
  }
}
