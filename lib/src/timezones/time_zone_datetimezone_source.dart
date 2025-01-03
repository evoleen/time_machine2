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
        var zoneStart = Instant.fromEpochMilliseconds(location.transitionAt[i]);
        var zoneEnd = i == location.transitionAt.length - 1
            ? IInstant.afterMaxValue
            : Instant.fromEpochMilliseconds(location.transitionAt[i + 1]);

        final zone = i == 0
            ? location.zones.first
            : location.zones[location.transitionZone[i - 1]];

        final zoneInterval = IZoneInterval.newZoneInterval(
          zone.abbreviation,
          zoneStart,
          zoneEnd,
          Offset(zone.offset ~/ 1000),
          Offset(
            zone.offset ~/ 1000 + (zone.isDst ? 3600 : 0),
          ),
        );

        zoneIntervals.add(zoneInterval);
      }

      /*
      final tailZone = IZoneInterval.newZoneInterval(
        location.zones[location.transitionZone.last].abbreviation,
        Instant.fromEpochMilliseconds(
            location.transitionAt[location.transitionAt.length - 2]),
        Instant.fromEpochMilliseconds(
            location.transitionAt[location.transitionAt.length - 1]),
        Offset(location.zones[location.transitionZone.last].offset ~/ 1000),
        Offset(location.zones[location.transitionZone.last].offset ~/ 1000 +
            (location.zones[location.transitionZone.last].isDst ? 3600 : 0)),
      );

      zoneIntervals.add(tailZone);
      */
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
  Future<String> get versionId => Future.sync(() => 'TZDB: 2024b');

  @override
  void setSystemDefaultId(String id) {
    final systemDefaultLocation = tz.getLocation(id);
    tz.setLocalLocation(systemDefaultLocation);
  }
}
