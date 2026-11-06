/// Windows time zones whose standard name differs from their ID.
///
/// On Windows, Dart's [DateTime.timeZoneName] returns the zone's standard (or
/// daylight) name rather than its ID, so these names are needed in addition
/// to the CLDR Windows ID mapping to find the TZDB zone for a standard name.
/// The compiler embeds them in tzdb.bin, mapped to TZDB IDs via CLDR.
///
/// Ported from Noda Time's NameIdMappingSupport. The Windows-only test in
/// test/windows_zones_test.dart checks that every name in the Windows registry
/// that differs from its ID is covered; this map may be a superset of that.
abstract class NameIdMappingSupport {
  /// Hard-coded map from StandardName to Windows ID, where these are known to differ.
  static const Map<String, String> StandardNameToIdMap = {
    'Coordinated Universal Time': "UTC",
    'Co-ordinated Universal Time': "UTC",
    'Jerusalem Standard Time': "Israel Standard Time",
    'Malay Peninsula Standard Time': "Singapore Standard Time",
    'Russia TZ 1 Standard Time': "Kaliningrad Standard Time",
    'Russia TZ 2 Standard Time': "Russian Standard Time",
    'Russia TZ 3 Standard Time': "Russia Time Zone 3",
    'Russia TZ 4 Standard Time': "Ekaterinburg Standard Time",
    'Russia TZ 6 Standard Time': "North Asia Standard Time",
    'Russia TZ 7 Standard Time': "North Asia East Standard Time",
    'Russia TZ 8 Standard Time': "Yakutsk Standard Time",
    'Russia TZ 9 Standard Time': "Vladivostok Standard Time",
    'Russia TZ 10 Standard Time': "Russia Time Zone 10",
    'Russia TZ 11 Standard Time': "Russia Time Zone 11",
    'Cabo Verde Standard Time': "Cape Verde Standard Time",
    'West Bank Gaza Standard Time': "West Bank Standard Time",
    'Novosibirsk Standard Time': "N. Central Asia Standard Time",
    'Türkiye Standard Time': "Turkey Standard Time",
    // Difference here is just the case of 'and'!
    'Turks and Caicos Standard Time': "Turks And Caicos Standard Time",
    // 'Russia TZ 5 Standard Time' maps to "N.Central Asia Standard Time" on old
    // Windows versions, which isn't present in CLDR.
  };
}
