// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'package:universal_io/io.dart' as io;

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/datetimezone_providers.dart';
import 'package:time_machine2/time_machine2.dart';

import 'package:time_machine2/src/timezones/zone_guesser.dart';

import 'platform_io.dart';
import 'unix_time_zone.dart';
import 'windows_time_zone.dart';
import 'windows_tz_environment.dart';

Future initialize(Map<String, dynamic> args, {testing = false}) {
  String? timeZoneOverride = args['timeZone'];
  String? cultureOverride = args['culture'];

  // initialize platform IO methods.
  PlatformIO(config: args);

  return TimeMachine.initialize(timeZoneOverride, cultureOverride);
}

class TimeMachine {
  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize(
      String? timeZoneOverride, String? cultureOverride) async {
    Platform.startVM();

    // todo: we want this for flutter -- do we want this for the VM too?
    ICultures.loadAllCulturesInformation_SetFlag();

    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    IDateTimeZoneProviders.defaultProvider = tzdb;

    var local = timeZoneOverride != null
        ? await tzdb.getZoneOrNull(timeZoneOverride)
        : await _figureOutTimeZone(tzdb);

    // todo: cache local more directly? (this is indirect caching)
    tzdb.setSystemDefault(local!.id);

    // Default Culture
    var cultureId = cultureOverride ??
        io.Platform.localeName.split('.').first.replaceAll('_', '-');

    // POSIX default culture will be reported as "C". We manually remap this
    // to en-US, as most systems with POSIX defaults should also be configured
    // to use American English
    if (cultureId == 'C') {
      cultureId = 'en-US';
    }

    Culture? culture = await Cultures.getCulture(cultureId);

    // fall back to en-US if system's culture doesn't exist (can happen if a
    // system is configured to something unusual, such as de-EN)
    culture ??= await Cultures.getCulture("en-US");

    ICultures.currentCulture = culture!;
    // todo: remove Culture.currentCulture
  }

  /// Works out the system time zone the way Noda Time does, which relies on
  /// .NET's `TimeZoneInfo.Local.Id`:
  ///
  /// * Windows: an IANA or Windows zone ID in `TZ` (as Python's tzlocal and
  ///   Node.js honour IANA IDs), else the Windows zone ID, mapped to a TZDB zone with the CLDR data
  ///   embedded in the TZDB data. The ID is the same in every display language.
  /// * Linux, macOS and Android: the IANA zone ID, found the way .NET finds it.
  /// * Otherwise (or if the ID isn't known): the zone whose offsets best match
  ///   the system's over the next five years.
  ///
  /// As a last resort, a fixed zone with the system's current offset.
  static Future<DateTimeZone> _figureOutTimeZone(
      DateTimeZoneProvider provider) async {
    var zone = io.Platform.isWindows
        ? await _figureOutWindowsTimeZone(provider)
        : await _figureOutUnixTimeZone(provider);
    if (zone != null) return zone;

    zone = await _guessTimeZoneByTransitions(provider);
    if (zone != null) return zone;

    // This is UTC on a UTC system, but avoids silently treating every other
    // system as UTC.
    return DateTimeZone.forOffset(
        Offset(DateTime.now().timeZoneOffset.inSeconds));
  }

  /// On Windows: an IANA ID in the `TZ` environment variable, as Python's
  /// tzlocal and Node.js honour it, or a Windows zone ID (mapped with CLDR;
  /// see [windowsTzEnvironmentZoneId]);
  /// otherwise the Windows zone ID (the registry key name from
  /// `GetDynamicTimeZoneInformation`, which .NET uses for
  /// `TimeZoneInfo.Local.Id`) mapped with CLDR. Returns null if neither gives
  /// a known zone.
  static Future<DateTimeZone?> _figureOutWindowsTimeZone(
      DateTimeZoneProvider provider) async {
    var source = IDateTimeZoneProviders.tzdbSource;
    // TZ may name an IANA zone or, on Windows, a Windows zone ID.
    var tzId = windowsTzEnvironmentZoneId(io.Platform.environment['TZ'], {
      ...source.canonicalIdMap.keys,
      ...source.windowsMapping.primaryMapping.keys,
    });
    if (tzId != null) {
      var id = source.mapSystemTimeZoneId(tzId);
      if (id != null && provider.ids.contains(id)) return await provider[id];
    }

    var info = readWindowsTimeZoneInfo();
    if (info == null) return null;

    // With "Adjust for daylight saving time automatically" turned off, the
    // system ignores the zone's DST rules (as does .NET's TimeZoneInfo.Local),
    // so the mapped zone would be wrong for part of the year. The clock is
    // then the zone's standard offset all year: guess from that, as reported
    // by Windows (Dart's DateTime follows the C runtime, which applies TZ).
    if (info.dynamicDaylightTimeDisabled) {
      var offset = Offset(info.standardOffsetSeconds);
      return await _guessTimeZoneByTransitions(provider, (_) => offset) ??
          DateTimeZone.forOffset(offset);
    }

    var id =
        IDateTimeZoneProviders.tzdbSource.mapSystemTimeZoneId(info.keyName);
    if (id == null || !provider.ids.contains(id)) return null;
    return await provider[id];
  }

  /// Looks up the IANA zone ID found as .NET finds it on Unix. Returns null if
  /// there isn't one, or it isn't in the TZDB data.
  static Future<DateTimeZone?> _figureOutUnixTimeZone(
      DateTimeZoneProvider provider) async {
    var canonicalIdMap = IDateTimeZoneProviders.tzdbSource.canonicalIdMap;
    var canonicalIds = canonicalIdMap.values.toSet().toList()..sort();
    var aliases = canonicalIdMap.keys
        .where((id) => canonicalIdMap[id] != id)
        .toList()
      ..sort();
    var systemId = readUnixTimeZoneId([...canonicalIds, ...aliases]);
    var id = systemId == null
        ? null
        : IDateTimeZoneProviders.tzdbSource.mapSystemTimeZoneId(systemId);
    if (id == null || !provider.ids.contains(id)) return null;
    return await provider[id];
  }

  /// Picks the TZDB zone whose offsets best match the system's (as reported by
  /// dart:core) at every transition in the next five years. See
  /// [guessZoneIdByTransitions].
  static Future<DateTimeZone?> _guessTimeZoneByTransitions(
      DateTimeZoneProvider provider,
      [Offset Function(Instant instant)? systemOffset]) async {
    var source = IDateTimeZoneProviders.tzdbSource;
    var ids = source.canonicalIdMap.values
        .toSet()
        .where(provider.ids.contains)
        .toList()
      ..sort();
    var candidates = [for (var id in ids) await provider[id]];
    var id = guessZoneIdByTransitions(
        systemOffset ??
            (instant) => Offset(
                DateTime.fromMillisecondsSinceEpoch(instant.epochMilliseconds)
                    .timeZoneOffset
                    .inSeconds),
        candidates);
    return id == null ? null : await provider[id];
  }
}
