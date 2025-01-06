import 'package:time_machine/src/time_machine_internal.dart';

import 'package:time_machine/src/timezones/tzdb_datetimezone_source_native_impl.dart'
    if (dart.library.html) 'tzdb_datetimezone_source_browser_impl.dart';

import 'tzdb_io.dart';
import 'tzdb_location_database.dart';

class TzdbDateTimeZoneSource extends DateTimeZoneSource {
  bool _initialized = false;

  // map of date time zones that are deserialized from TZF entries on init
  final _dateTimeZones = <String, DateTimeZone>{};

  String _defaultId = "UTC";

  Future<void> _init() async {
    if (!_initialized) {
      final tzdbData = await getTzdbData("latest_10y.tzf");
      final database = _deserializeTzdbDatabase(tzdbData);

      // convert all tzf entries into Time Machine's zone format
      for (final id in database.locations.keys) {
        final location = database.locations[id];

        if (location == null) {
          throw Exception("Internal consistency error.");
        }

        final zoneIntervals = List<ZoneInterval>.empty(growable: true);

        // if we don't have any transitions, this is a fixed zone
        if (location.transitionAt.isEmpty) {
          final firstInterval = IZoneInterval.newZoneInterval(
            location.zones.first.abbreviation,
            IInstant.beforeMinValue,
            IInstant.afterMaxValue,
            Offset(location.zones.first.offset ~/ 1000),
            Offset(
              location.zones.first.offset ~/ 1000 +
                  (location.zones.first.isDst ? 3600 : 0),
            ),
          );

          zoneIntervals.add(firstInterval);
        } else {
          // if it's not a fixed zone, use the transition map
          for (var i = 0; i < location.transitionAt.length; i++) {
            var zoneStart =
                Instant.fromEpochMilliseconds(location.transitionAt[i]);
            var zoneEnd = i == location.transitionAt.length - 1
                ? null
                : Instant.fromEpochMilliseconds(location.transitionAt[i + 1]);

            final zone = location.zones[location.transitionZone[i]];

            final zoneInterval = IZoneInterval.newZoneInterval(
              zone.abbreviation,
              zoneStart,
              zoneEnd,
              Offset(zone.offset ~/ 1000),
              zone.isDst ? Offset(3600) : Offset.zero,
            );

            zoneIntervals.add(zoneInterval);
          }
        }

        final precalculatedZone =
            PrecalculatedDateTimeZone(id, zoneIntervals, null);

        _dateTimeZones[id] = precalculatedZone;
      }

      _initialized = true;
    }
  }

  /// Takes raw TZF data and deserializes
  TzdbLocationDatabase _deserializeTzdbDatabase(List<int> rawData) {
    final database = TzdbLocationDatabase();

    for (final l in tzdbDeserialize(rawData)) {
      database.add(l);
    }

    return database;
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

  @override
  String get systemDefaultId => _defaultId;

  @override
  Future<String> get versionId => Future.sync(() => 'TZDB: 2024b');

  @override
  void setSystemDefaultId(String id) {
    _defaultId = id;
  }
}
