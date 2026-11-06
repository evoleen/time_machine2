import 'dart:collection';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:time_machine2/src/platforms/platform_io.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/cldr/windows_zones.dart';
import 'package:time_machine2/src/timezones/datetimezone_providers.dart';
import 'package:time_machine2/src/timezones/tzdb_stream_reader.dart';

/// Provides an implementation of [DateTimeZoneSource] that loads data
/// originating from the [tz database](https://www.iana.org/time-zones)
/// (also known as the IANA Time Zone database, or zoneinfo or Olson database).
///
/// The data is embedded in Time Machine and loaded by
/// `TimeMachine.initialize()`. The members that expose the data
/// ([tzdbVersion], [canonicalIdMap], [windowsMapping], [windowsToTzdbIds],
/// [tzdbToWindowsIds] and [validate]) throw a [StateError] if they're used
/// before that.
class TzdbDateTimeZoneSource extends DateTimeZoneSource {
  bool _initialized = false;

  // map of date time zones that are deserialized from TZF entries on init
  final _dateTimeZones = <String, DateTimeZone>{};
  final _aliases = <String, String>{};
  final _windowsStandardNameToTzdbId = <String, String>{};

  String _defaultId = "UTC";
  String _versionId = 'Uninitialized';
  String _tzdbVersion = '';
  Map<String, String> _canonicalIdMap = const {};
  WindowsZones _windowsMapping = WindowsZones('', '', '', const []);
  Map<String, String>? _windowsToTzdbIds;
  Map<String, String>? _tzdbToWindowsIds;
  Map<String, List<String>>? _aliasLookup;

  TzdbDateTimeZoneSource();

  /// The TZDB source embedded in Time Machine, as used by
  /// [DateTimeZoneProviders.tzdb].
  static TzdbDateTimeZoneSource get defaultSource =>
      IDateTimeZoneProviders.tzdbSource;

  Future<void> _init() async {
    if (!_initialized) {
      final xzDecoder = XZDecoder();

      final tzdbData = xzDecoder.decodeBytes(
          (await PlatformIO.local.getBinary('tzdb', 'tzdb.bin'))
              .buffer
              .asUint8List(),
          verify: true);

      final streamReader = TzdbStreamReader(ByteData.sublistView(tzdbData));

      _tzdbVersion = streamReader.tzdbVersion;
      _windowsMapping = streamReader.windowsZones;
      _versionId = _windowsMapping.version.isEmpty
          ? 'TZDB: $_tzdbVersion'
          : 'TZDB: $_tzdbVersion (mapping: ${_windowsMapping.version})';
      _aliases.clear();
      _aliases.addAll(streamReader.aliases);

      _windowsStandardNameToTzdbId
        ..clear()
        ..addAll(streamReader.windowsStandardNameToTzdbId);

      final dateTimeZones = streamReader.timeZones;

      _dateTimeZones.clear();
      _dateTimeZones.addAll(dateTimeZones);

      _canonicalIdMap = UnmodifiableMapView({
        for (final id in dateTimeZones.keys) id: id,
        ..._aliases,
      });
      _windowsToTzdbIds = null;
      _tzdbToWindowsIds = null;
      _aliasLookup = null;

      // Add time zones under their alias names as well
      final aliases = streamReader.aliases;
      for (final entry in aliases.entries) {
        final aliasId = entry.key;
        final canonicalId = entry.value;
        if (_dateTimeZones.containsKey(canonicalId)) {
          final originalZone = _dateTimeZones[canonicalId]!;
          if (originalZone is FixedDateTimeZone) {
            _dateTimeZones[aliasId] = FixedDateTimeZone(
                aliasId, originalZone.offset, originalZone.name);
          } else if (originalZone is PrecalculatedDateTimeZone) {
            _dateTimeZones[aliasId] = PrecalculatedDateTimeZone(
                aliasId, originalZone.periods, originalZone.tailZone);
          } else {
            // For any other type, just use the original instance
            _dateTimeZones[aliasId] = originalZone;
          }
        }
      }

      _initialized = true;
    }
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('The TZDB data has not been loaded yet. '
          'Call TimeMachine.initialize() first.');
    }
  }

  @override
  Future<DateTimeZone> forId(String id) async {
    await _init();

    return forCachedId(id);
  }

  @override
  DateTimeZone forCachedId(String id) {
    return _dateTimeZones[id] ?? _dateTimeZones['UTC']!;
  }

  @override
  Future<Iterable<String>> getIds() async {
    await _init();
    return _dateTimeZones.keys;
  }

  /// The TZDB version (e.g. '2026a') of the source data.
  String get tzdbVersion {
    _checkInitialized();
    return _tzdbVersion;
  }

  /// A map from time zone ID to the canonical ID for that zone. Canonical IDs
  /// map to themselves; aliases (such as 'Asia/Calcutta') map to their
  /// canonical ID (such as 'Asia/Kolkata').
  Map<String, String> get canonicalIdMap {
    _checkInitialized();
    return _canonicalIdMap;
  }

  /// A lookup from canonical time zone ID (e.g. 'Europe/London') to the aliases
  /// of that ID (e.g. 'Europe/Belfast', 'Europe/Guernsey'), in ordinal order.
  ///
  /// Only canonical IDs that have aliases are present; any other ID (including
  /// an alias) isn't a key.
  Map<String, List<String>> get aliases {
    _checkInitialized();
    return _aliasLookup ??= UnmodifiableMapView({
      for (final entry in (() {
        final lookup = <String, List<String>>{};
        for (final pair in _canonicalIdMap.entries) {
          if (pair.key != pair.value) {
            lookup.putIfAbsent(pair.value, () => []).add(pair.key);
          }
        }
        return lookup;
      })()
          .entries)
        entry.key: List.unmodifiable(entry.value..sort()),
    });
  }

  /// Maps a system time zone ID to a TZDB ID, as Noda Time's
  /// `TzdbDateTimeZoneSource.MapTimeZoneInfoId` does: first as a Windows
  /// zone ID (using the CLDR primary mapping), then as a TZDB ID. Returns null
  /// if it's neither; callers then guess by transitions.
  @internal
  String? mapSystemTimeZoneId(String id) {
    _checkInitialized();
    // First see if it's a Windows time zone ID.
    final result = _windowsMapping.primaryMapping[id];
    if (result != null) return result;
    // Next see if it's already a TZDB ID (e.g. on Linux or macOS).
    if (_canonicalIdMap.containsKey(id)) return id;
    return null;
  }

  /// The Windows time zone mapping information provided in the CLDR
  /// supplemental 'windowsZones.xml' file.
  WindowsZones get windowsMapping {
    _checkInitialized();
    return _windowsMapping;
  }

  /// A map from Windows time zone IDs to canonical TZDB IDs, using the primary
  /// mapping in each [MapZone].
  ///
  /// Sometimes the Windows mapping contains values which are not canonical TZDB IDs.
  /// Every value in the returned map is a canonical ID. For example, the Windows
  /// mapping contains 'Asia/Calcutta' for the Windows ID 'India Standard Time', but
  /// 'Asia/Calcutta' is an alias for 'Asia/Kolkata'. The entry for 'India Standard Time'
  /// in the returned map therefore has 'Asia/Kolkata' as the value.
  Map<String, String> get windowsToTzdbIds {
    _checkInitialized();
    return _windowsToTzdbIds ??= UnmodifiableMapView(
        buildWindowsToTzdbIdMap(_windowsMapping, _canonicalIdMap));
  }

  /// Builds the map returned by [windowsToTzdbIds]. Exposed for testing.
  @visibleForTesting
  static Map<String, String> buildWindowsToTzdbIdMap(
          WindowsZones windowsMapping, Map<String, String> canonicalIdMap) =>
      {
        for (final entry in windowsMapping.primaryMapping.entries)
          entry.key: canonicalIdMap[entry.value] ?? entry.value,
      };

  /// A map from TZDB IDs to Windows IDs.
  ///
  /// Where a TZDB alias isn't present directly in the Windows mapping, but its canonical ID is,
  /// the map contains an entry for the alias as well. For example, the TZDB ID
  /// 'Africa/Asmara' is an alias for 'Africa/Nairobi', which has a Windows ID of 'E. Africa Standard Time'.
  /// 'Africa/Asmara' doesn't appear in the Windows mapping directly, but it is still present in the
  /// returned map.
  ///
  /// Where a TZDB canonical ID isn't present in the Windows mapping, but an alias is, the map
  /// contains an entry for the canonical ID as well. For example, the Windows mapping uses the
  /// TZDB ID 'Asia/Calcutta' for 'India Standard Time'. This is an alias for 'Asia/Kolkata' in TZDB,
  /// so the returned map has an entry mapping 'Asia/Kolkata' to 'India Standard Time'.
  /// If multiple aliases for the same canonical ID have entries in the Windows mapping with different
  /// Windows IDs, the alias that is earliest in lexicographical ordering determines the value for the entry.
  ///
  /// If a canonical ID is not present in the mapping, nor any of its aliases, it is not present in
  /// the returned map.
  Map<String, String> get tzdbToWindowsIds {
    _checkInitialized();
    return _tzdbToWindowsIds ??= UnmodifiableMapView(
        buildTzdbToWindowsIdMap(_windowsMapping, _canonicalIdMap));
  }

  /// Builds the map returned by [tzdbToWindowsIds]. Exposed for testing.
  @visibleForTesting
  static Map<String, String> buildTzdbToWindowsIdMap(
      WindowsZones windowsMapping, Map<String, String> canonicalIdMap) {
    final mutable = <String, String>{};
    // First map everything from the WindowsZones.
    for (final zone in windowsMapping.mapZones
        .where((mz) => mz.territory != MapZone.primaryTerritory)) {
      for (final tzdbId in zone.tzdbIds) {
        mutable[tzdbId] = zone.windowsId;
      }
    }

    final aliases =
        canonicalIdMap.entries.where((pair) => pair.key != pair.value).toList();

    // Now map any missing canonical IDs based on aliases, ordered by alias for predictability.
    final aliasesForMissingCanonical = aliases
        .where((pair) => !mutable.containsKey(pair.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in aliasesForMissingCanonical) {
      // An earlier alias may already have provided an ID.
      final windowsId = mutable[entry.key];
      if (!mutable.containsKey(entry.value) && windowsId != null) {
        mutable[entry.value] = windowsId;
      }
    }

    // Finally map any missing aliases based on canonical IDs.
    for (final entry
        in aliases.where((pair) => !mutable.containsKey(pair.key)).toList()) {
      final windowsId = mutable[entry.value];
      if (windowsId != null) {
        mutable[entry.key] = windowsId;
      }
    }
    return mutable;
  }

  /// Maps a Windows time zone standard name to a TZDB ID, for the zones whose
  /// standard name differs from their Windows ID (e.g. 'Coordinated Universal Time').
  ///
  /// On Windows, Dart's [DateTime.timeZoneName] returns the standard name in the
  /// display language; this only knows the English names.
  @internal
  String? windowsStandardNameToTzdbId(String name) {
    _checkInitialized();
    return _windowsStandardNameToTzdbId[name];
  }

  /// Validates that the data within this source is consistent with itself.
  ///
  /// The data shipped with Time Machine is validated when it's compiled, so this
  /// only needs to be called for data from a source you're unsure of.
  ///
  /// Throws [InvalidDateTimeZoneSourceError] if the source data is invalid.
  void validate() {
    _checkInitialized();
    validateData(_canonicalIdMap, _windowsMapping);
  }

  /// Validates the given data, as [validate] does. Exposed for the TZDB compiler and tests.
  @internal
  static void validateData(
      Map<String, String> canonicalIdMap, WindowsZones windowsMapping) {
    void fail(String message) => throw InvalidDateTimeZoneSourceError(message);

    // Check that each entry has a canonical value. (Every mapping x to y
    // should be such that y maps to itself.)
    for (final entry in canonicalIdMap.entries) {
      final canonical = canonicalIdMap[entry.value];
      if (canonical == null) {
        fail('Mapping for entry ${entry.key} (${entry.value}) is missing');
      }
      if (entry.value != canonical) {
        fail('Mapping for entry ${entry.key} (${entry.value}) is not canonical '
            '(${entry.value} maps to $canonical)');
      }
    }

    // Check Windows mappings:
    // - Each MapZone uses TZDB IDs that are known to this source,
    // - Each TZDB ID only occurs once except for the primary territory
    // - Every ID has a primary territory
    // - Within each ID, the territories are unique
    // - Each primary territory TZDB ID occurs as a non-primary territory
    final mappedTzdbIds = <String>{};
    for (final mapZone in windowsMapping.mapZones) {
      for (final id in mapZone.tzdbIds) {
        if (!canonicalIdMap.containsKey(id)) {
          fail('Windows mapping uses TZDB ID $id which is missing');
        }
        // The primary territory ID is also present as a non-primary territory,
        // so don't include it in duplicate detection. Everything else should be unique.
        if (mapZone.territory != MapZone.primaryTerritory &&
            !mappedTzdbIds.add(id)) {
          fail('Windows mapping has multiple entries for TZDB ID $id');
        }
      }
    }

    final territoriesByWindowsId = <String, List<MapZone>>{};
    for (final mapZone in windowsMapping.mapZones) {
      territoriesByWindowsId
          .putIfAbsent(mapZone.windowsId, () => [])
          .add(mapZone);
    }
    for (final group in territoriesByWindowsId.entries) {
      final zones = group.value;
      if (zones.map((zone) => zone.territory).toSet().length != zones.length) {
        fail('Windows mapping has duplicate territories entries for Windows ID '
            '${group.key}');
      }
      final primary = zones
          .where((zone) => zone.territory == MapZone.primaryTerritory)
          .firstOrNull;
      if (primary == null) {
        fail('Windows mapping has no primary territory entry for Windows ID '
            '${group.key}');
      }
      if (primary!.tzdbIds.length != 1) {
        fail('Windows mapping primary territory entry for Windows ID '
            '${group.key} has ${primary.tzdbIds.length} TZDB IDs');
      }
      final primaryTzdb = primary.tzdbIds.single;
      if (!zones.any((zone) =>
          zone.territory != MapZone.primaryTerritory &&
          zone.tzdbIds.contains(primaryTzdb))) {
        fail('Windows mapping primary territory entry for Windows ID '
            '${group.key} has TZDB ID $primaryTzdb which does not occur in a '
            'non-primary territory');
      }
    }
  }

  @override
  String get systemDefaultId => _defaultId;

  @override
  String get versionId => _versionId;

  @override
  void setSystemDefaultId(String id) {
    _defaultId = id;
  }
}
