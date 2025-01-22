// Copyright 2009 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'rule_line.dart';
import 'tzdb_zone_1970_location.dart';
import 'tzdb_zone_location.dart';

class TzdbDatabase {
  final String version;
  final Map<String, List<ZoneLine>> zones;
  final Map<String, String> aliases;
  final Map<String, List<RuleLine>> rules;
  List<TzdbZoneLocation>? zoneLocations;
  List<TzdbZone1970Location>? zone1970Locations;

  TzdbDatabase(this.version)
      : zones = {},
        aliases = {},
        rules = {};

  void addAlias(String existing, String alias) {
    aliases[alias] = existing;
  }

  void addRule(RuleLine rule) {
    rules.putIfAbsent(rule.name, () => []).add(rule);
  }

  void addZone(ZoneLine zone) {
    zones.putIfAbsent(zone.name, () => []).add(zone);
  }

  DateTimeZone generateDateTimeZone(String zoneId) {
    String resolvedZoneId = zoneId;

    while (aliases.containsKey(resolvedZoneId)) {
      resolvedZoneId = aliases[resolvedZoneId]!;
    }

    final zoneList = zones[resolvedZoneId];
    if (zoneList == null) {
      throw ArgumentError('Zone ID not found: $zoneId');
    }

    return _createTimeZone(zoneId, zoneList);
  }

  Iterable<DateTimeZone> generateDateTimeZones() {
    return zones.entries
        .map((entry) => _createTimeZone(entry.key, entry.value));
  }

  DateTimeZone _createTimeZone(String id, List<ZoneLine> zoneList) {
    final ruleSets = zoneList.map((zone) => zone.resolveRules(rules)).toList();
    return DateTimeZoneBuilder.build(id, ruleSets);
  }

  void logCounts() {
    print('=======================================');
    print('Rule sets: ${rules.length}');
    print('Zones: ${zones.length}');
    print('Aliases: ${aliases.length}');
    print('Zone locations: ${zoneLocations?.length ?? 0}');
    print('Zone1970 locations: ${zone1970Locations?.length ?? 0}');
    print('=======================================');
  }
}

class ZoneLine {
  final String name;

  ZoneLine(this.name);

  dynamic resolveRules(Map<String, List<RuleLine>> rules) {
    // Placeholder implementation
    return null;
  }
}
