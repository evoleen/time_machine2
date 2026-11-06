// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Checks SystemDateTimeZoneSource on the web (the Intl backend), where the
// mirrors-based test suite can't run. Build and run with node:
//
//   dart compile js -O2 tool/system_tz_web_check.dart -o check.js
//   (echo "globalThis.self = globalThis;"; cat check.js) > check_node.js
//   node check_node.js
//
//   dart compile wasm tool/system_tz_web_check.dart -o check.wasm
//   node tool/system_tz_web_check_wasm.mjs check.wasm
//
// It checks a sample of zones for self-consistency (each zone interval
// contains the instant it was found for, offsets change at every boundary,
// neighbouring intervals adjoin) and some well-known facts, first finding
// transitions by searching and then, if the JS engine has Temporal, with
// Temporal, and checks that the two agree. It prints the results, and exits
// with an error if anything fails.

// This is a test that can't live in test/ (which needs dart:mirrors).
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:time_machine2/time_machine2.dart';
// ignore: implementation_imports
import 'package:time_machine2/src/timezones/system/intl_backend.dart';

const _sampleZones = [
  'UTC',
  'America/New_York',
  'America/Los_Angeles',
  'America/St_Johns',
  'America/Sao_Paulo',
  'America/Nuuk',
  'Europe/London',
  'Europe/Dublin',
  'Europe/Moscow',
  'Africa/Casablanca',
  'Asia/Kolkata',
  'Asia/Kathmandu',
  'Asia/Tehran',
  'Asia/Tokyo',
  'Asia/Gaza',
  'Australia/Sydney',
  'Australia/Lord_Howe',
  'Pacific/Apia',
  'Pacific/Chatham',
  'Pacific/Kiritimati',
  'Antarctica/Troll',
];

final List<String> _failures = [];

void _check(bool condition, String message) {
  if (!condition) _failures.add(message);
}

String _format(Instant instant) =>
    DateTime.fromMillisecondsSinceEpoch(instant.epochMilliseconds, isUtc: true)
        .toIso8601String();

String _describe(ZoneInterval interval) =>
    '${interval.name} [${interval.hasStart ? _format(interval.start) : '-inf'}, '
    '${interval.hasEnd ? _format(interval.end) : '+inf'}) '
    '${interval.wallOffset.inSeconds}s (savings ${interval.savings.inSeconds}s)';

final List<Instant> _instants = [
  for (var ms = Instant.utc(1890, 1, 1, 0, 0).epochMilliseconds;
      ms < Instant.utc(2060, 1, 1, 0, 0).epochMilliseconds;
      ms += 97 * 86400000 + 3600000)
    Instant.fromEpochMilliseconds(ms),
  Instant.utc(1700, 6, 1, 0, 0),
  Instant.utc(2500, 6, 1, 0, 0),
  Instant.utc(9999, 6, 1, 0, 0),
];

/// Checks [zoneIds] in a new source; returns each zone's intervals (as
/// strings) at [_instants].
Future<Map<String, List<String>>> _checkZones(
    String label, Iterable<String> zoneIds) async {
  var stopwatch = Stopwatch()..start();
  var source = SystemDateTimeZoneSource();
  var results = <String, List<String>>{};
  var lookups = 0;
  var distinct = 0;
  for (var id in zoneIds) {
    var zoneStopwatch = Stopwatch()..start();
    var zone = source.forCachedId(id);
    _check(zone.id == id, '$id: wrong ID ${zone.id}');
    var seen = <String>{};
    var described = results[id] = [];
    for (var instant in _instants) {
      lookups++;
      var interval = zone.getZoneInterval(instant);
      described.add(_describe(interval));
      if (!interval.contains(instant)) {
        _failures.add('$label $id: ${_describe(interval)} does not contain '
            '${_format(instant)}');
        continue;
      }
      if (!seen.add(_describe(interval))) continue;
      distinct++;
      _check(interval.savings.inSeconds.abs() <= 3 * 3600,
          '$label $id: implausible savings in ${_describe(interval)}');
      if (interval.hasStart) {
        var previous = zone.getZoneInterval(interval.start - Time.epsilon);
        _check(
            previous.hasEnd && previous.end == interval.start,
            '$label $id: ${_describe(previous)} does not adjoin '
            '${_describe(interval)}');
        _check(previous.wallOffset != interval.wallOffset,
            '$label $id: no offset change at the start of ${_describe(interval)}');
      }
      if (interval.hasEnd) {
        var next = zone.getZoneInterval(interval.end);
        _check(
            next.hasStart && next.start == interval.end,
            '$label $id: ${_describe(next)} does not follow '
            '${_describe(interval)}');
      }
    }
    var elapsed = zoneStopwatch.elapsedMilliseconds;
    if (elapsed > 1000) print('  $label: $id took ${elapsed}ms');
  }
  print('$label: checked ${zoneIds.length} zones at ${_instants.length} '
      'instants ($lookups lookups, $distinct distinct intervals) in '
      '${stopwatch.elapsedMilliseconds}ms');
  return results;
}

Future<void> main() async {
  print('SystemDateTimeZoneSource.isSupported: '
      '${SystemDateTimeZoneSource.isSupported}');
  var source = SystemDateTimeZoneSource();
  print('versionId: ${source.versionId}');
  print('systemDefaultId: ${source.systemDefaultId}');
  var ids = (await source.getIds()).toList();
  print('${ids.length} zone IDs');
  _check(ids.length > 300, 'Expected over 300 zone IDs');
  _check(ids.contains('UTC'), 'UTC is missing');
  var defaultId = source.systemDefaultId;
  _check(defaultId != null && ids.contains(defaultId),
      'The system default ($defaultId) is not a zone ID');

  // Not found, rather than falling back to TZDB.
  try {
    source.forCachedId('Not/AZone');
    _failures.add('Not/AZone was found');
  } on DateTimeZoneNotFoundError {
    // Expected.
  }
  var provider = await DateTimeZoneProviders.system;
  _check((await provider.getZoneOrNull('Not/AZone')) == null,
      'Provider found Not/AZone');

  // The sample, plus every 25th zone. Browsers list one ID per zone (V8
  // lists ICU's, e.g. Asia/Calcutta) but the source accepts any ID the
  // browser does.
  var unlisted = _sampleZones.where((id) => !ids.contains(id)).toList();
  if (unlisted.isNotEmpty) print('Sample IDs not listed: $unlisted');
  var zoneIds = {
    ..._sampleZones,
    for (var i = 0; i < ids.length; i += 25) ids[i],
  };

  IntlDateTimeZone.useTemporal = false;
  var searched = await _checkZones('Search', zoneIds);
  IntlDateTimeZone.useTemporal = true;
  if (IntlDateTimeZone('UTC').usesTemporal) {
    var temporal = await _checkZones('Temporal', zoneIds);
    var differences = 0;
    for (var id in zoneIds) {
      for (var i = 0; i < _instants.length; i++) {
        if (searched[id]![i] != temporal[id]![i]) {
          differences++;
          _failures.add('$id at ${_format(_instants[i])}: search found '
              '${searched[id]![i]}, Temporal ${temporal[id]![i]}');
        }
      }
    }
    print('Search and Temporal: $differences differences');
  } else {
    print('Temporal is not available');
  }

  // Some well-known facts.
  var newYork = source.forCachedId('America/New_York');
  var summer = newYork.getZoneInterval(Instant.utc(2024, 7, 1, 0, 0));
  print('America/New_York, July 2024: ${_describe(summer)}');
  _check(summer.start == Instant.utc(2024, 3, 10, 7, 0),
      'New York DST 2024 start');
  _check(summer.end == Instant.utc(2024, 11, 3, 6, 0), 'New York DST 2024 end');
  _check(summer.wallOffset == Offset.hours(-4), 'New York EDT offset');
  _check(summer.savings == Offset.hours(1), 'New York EDT savings');
  _check(summer.name == 'EDT', 'New York EDT name');

  var sydney = source.forCachedId('Australia/Sydney');
  var sydneySummer = sydney.getZoneInterval(Instant.utc(2025, 1, 1, 0, 0));
  print('Australia/Sydney, January 2025: ${_describe(sydneySummer)}');
  _check(sydneySummer.start == Instant.utc(2024, 10, 5, 16, 0),
      'Sydney DST start');
  _check(sydneySummer.end == Instant.utc(2025, 4, 5, 16, 0), 'Sydney DST end');
  _check(sydneySummer.savings == Offset.hours(1), 'Sydney savings');

  var kolkata = source.forCachedId('Asia/Kolkata');
  var kolkataNow = kolkata.getZoneInterval(Instant.utc(2025, 1, 1, 0, 0));
  print('Asia/Kolkata, 2025: ${_describe(kolkataNow)}');
  _check(
      kolkataNow.wallOffset == Offset.hoursAndMinutes(5, 30), 'Kolkata offset');
  _check(!kolkataNow.hasEnd, 'Kolkata has no future transitions');
  _check(kolkataNow.savings == Offset.zero, 'Kolkata savings');

  var apia = source.forCachedId('Pacific/Apia');
  // Samoa skipped December 30th 2011.
  _check(
      apia.getUtcOffset(Instant.utc(2011, 12, 30, 9, 59)) == Offset.hours(-10),
      'Apia before the date line change');
  _check(
      apia.getUtcOffset(Instant.utc(2011, 12, 30, 10, 0)) == Offset.hours(14),
      'Apia after the date line change');

  var local = LocalDateTime(2024, 7, 1, 12, 0, 0).inZoneStrictly(newYork);
  _check(local.offset == Offset.hours(-4), 'Local mapping in New York');

  if (_failures.isEmpty) {
    print('OK');
  } else {
    print('${_failures.length} FAILURES:');
    for (var failure in _failures.take(100)) {
      print('  $failure');
    }
    throw StateError('${_failures.length} failures');
  }
}
