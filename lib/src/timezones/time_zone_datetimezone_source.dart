import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:time_machine/src/time_machine_internal.dart';

class TimeZoneDateTimeZoneSource extends DateTimeZoneSource {
  static bool _initialized = false;

  static Future _init() async {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  @override
  Future<DateTimeZone> forId(String id) async {
    await _init();

    return forCachedId(id);
  }

  @override
  DateTimeZone forCachedId(String id) {
    final location = tz.getLocation(id);

    final zoneIntervals = List<ZoneInterval>.empty(growable: true);

    // if we don't have any transitions, use the default zone as the only zone
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
    }

    for (var i = 0; i < location.transitionAt.length; i++) {
      var zoneStart = location.transitionAt[i];
      var zoneEnd = location.transitionAt.length > i + 1
          ? location.transitionAt[i + 1]
          : null;

      final zone = location.zones[location.transitionZone[i]];

      final zoneInterval = IZoneInterval.newZoneInterval(
        zone.abbreviation,
        Instant.fromEpochMilliseconds(zoneStart),
        zoneEnd != null ? Instant.fromEpochMilliseconds(zoneEnd) : null,
        Offset(zone.offset ~/ 1000),
        Offset(
          zone.offset ~/ 1000 + (zone.isDst ? 3600 : 0),
        ),
      );

      zoneIntervals.add(zoneInterval);
    }

    final precalculatedZone =
        PrecalculatedDateTimeZone(id, zoneIntervals, null);

    return precalculatedZone;
  }

  @override
  Future<Iterable<String>> getIds() async {
    await _init();
    return tz.timeZoneDatabase.locations.keys;
  }

  @override
  String get systemDefaultId => tz.local.name;

  @override
  Future<String> get versionId => Future.sync(() => 'TZDB: 2024a');
}
