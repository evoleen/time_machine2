// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:js_interop';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'system_time_zone_backend.dart';

/// The web (JavaScript and WebAssembly): the browser's `Intl` time zone data,
/// through `dart:js_interop`.
///
/// * IDs are `Intl.supportedValuesOf('timeZone')`, plus 'UTC' and the
///   browser's own zone.
/// * The system default is `Intl.DateTimeFormat().resolvedOptions().timeZone`.
///
/// Browsers don't expose time zone rules, only the UTC offset (and a display
/// name) at a given instant, so zones are [IntlDateTimeZone]s, which find
/// transitions by searching. See there for the limitations that implies.
class IntlTimeZoneBackend implements SystemTimeZoneBackend {
  List<String>? _ids;
  final Map<String, IntlDateTimeZone> _zones = {};

  @override
  String get description => 'Intl';

  @override
  bool get isSupported {
    try {
      return _intl?.supportedValuesOfFunction != null;
    } catch (_) {
      return false;
    }
  }

  @override
  String? get dataVersion => null;

  @override
  List<String> getIds() {
    var ids = _ids;
    if (ids != null) return ids;
    var result = <String>{};
    if (isSupported) {
      try {
        for (var id in _intl!.supportedValuesOf('timeZone').toDart) {
          result.add(id.toDart);
        }
      } catch (_) {
        // Leave the list empty.
      }
      if (result.isNotEmpty) {
        result.add('UTC');
        var local = _resolvedTimeZone();
        if (local != null) result.add(local);
      }
    }
    return _ids = result.toList()..sort();
  }

  /// Loads [id] if the browser accepts it. That includes IDs that aren't in
  /// [getIds]: browsers list one ID per zone (V8, for instance, lists ICU's
  /// canonical IDs such as 'Asia/Calcutta') but accept the IANA aliases too
  /// (such as 'Asia/Kolkata'). Lookups through a [DateTimeZoneProvider] are
  /// limited to [getIds].
  @override
  DateTimeZone? loadZone(String id) {
    var zone = _zones[id];
    if (zone != null) return zone;
    if (!isSupported) return null;
    try {
      return _zones[id] = IntlDateTimeZone(id);
    } catch (_) {
      // The browser rejected the ID (a RangeError).
      return null;
    }
  }

  @override
  String? get systemDefaultId {
    var id = _resolvedTimeZone();
    return id != null && getIds().contains(id) ? id : null;
  }

  static String? _resolvedTimeZone() {
    try {
      return _DateTimeFormat.defaults().resolvedOptions().timeZone;
    } catch (_) {
      return null;
    }
  }
}

/// A [DateTimeZone] backed by the browser's `Intl` data.
///
/// The UTC offset at an instant comes from formatting it with
/// `Intl.DateTimeFormat(..., {timeZoneName: 'longOffset'})`. To find the zone
/// interval containing an instant, this steps away from it (in steps growing
/// from an hour to a week) until the offset changes, then binary searches
/// for the transition to the millisecond. If Temporal is available,
/// `ZonedDateTime.getTimeZoneTransition` is used instead. Intervals found are
/// cached.
///
/// Limitations, as browsers only expose offsets:
///
/// * Only offset changes are found: a change of name alone (or of the split
///   between standard time and DST with the same total offset) isn't a
///   transition here.
/// * Without Temporal, a pair of transitions less than a week apart that
///   return to the same offset can be missed. Transitions are assumed not to
///   happen before 1800, and to repeat yearly after 2100 (as browsers apply
///   the final rules), which bounds the searches.
/// * Whether an interval is daylight saving time is inferred: an interval
///   lasting a year or more is standard time; otherwise its standard offset
///   is the smallest offset within a year either side of it (ignoring
///   offsets more than 3 hours lower), and the savings are the difference. So negative DST (e.g. Europe/Dublin's winter time,
///   or Morocco during Ramadan) shows as positive DST at other times of
///   year, and a permanent change of standard offset can look like DST for
///   up to a year around it.
/// * Names are the browser's short names in US English (e.g. 'PST', or
///   'GMT+1' where there's no common abbreviation).
/// * [minOffset] and [maxOffset] are the widest possible (-18 and +18
///   hours), as the real range isn't known up front.
@internal
class IntlDateTimeZone extends DateTimeZone {
  // 1800-01-01 and 2100-01-01 UTC.
  static const int _earliestTransition = -5364662400000;
  static const int _finalRulesStart = 4102444800000;
  static const int _year = 366 * 86400000;
  static const int _maxSavings = 3 * 3600;
  static const int _minStep = 3600000;
  static const int _maxStep = 7 * 86400000;
  // The range of Instant, which is well within the range of JS dates.
  static const int _minMs = IInstant.minDays * 86400000;
  static const int _maxMs = IInstant.maxDays * 86400000 + 86399999;

  final _DateTimeFormat _offsetFormat;
  late final _DateTimeFormat _nameFormat = _DateTimeFormat(
      'en-US', _FormatOptions(timeZone: id, timeZoneName: 'short'));

  /// Whether to use Temporal when it's available. For testing the search.
  @visibleForTesting
  static bool useTemporal = true;

  final List<_RawInterval> _cache = [];
  final Map<int, int> _offsetCache = {};
  final bool _useTemporal;

  /// Whether this zone finds transitions with Temporal (rather than by
  /// searching).
  @visibleForTesting
  bool get usesTemporal => _useTemporal;

  IntlDateTimeZone(String id)
      : _offsetFormat = _DateTimeFormat(
            'en-US', _FormatOptions(timeZone: id, timeZoneName: 'longOffset')),
        _useTemporal = useTemporal && _hasTemporal(),
        super(id, false, Offset.minValue, Offset.maxValue);

  @override
  ZoneInterval getZoneInterval(Instant instant) {
    var ms = _floorMilliseconds(instant).clamp(_minMs, _maxMs);
    var raw = _rawInterval(ms);
    return raw.zoneInterval ??= _toZoneInterval(raw);
  }

  /// The floor of [instant]'s milliseconds since the epoch, exactly.
  /// (Instant.epochMilliseconds goes through a double, which loses the
  /// nanoseconds; and on the web, the nanosecond part of a Time can be
  /// negative.)
  static int _floorMilliseconds(Instant instant) {
    var time = instant.timeSinceEpoch;
    var milliseconds = ITime.millisecondsOf(time);
    var nanoseconds = ITime.nanosecondsIntervalOf(time);
    if (nanoseconds >= 0) return milliseconds + nanoseconds ~/ 1000000;
    return milliseconds - (-nanoseconds + 999999) ~/ 1000000;
  }

  ZoneInterval _toZoneInterval(_RawInterval raw) {
    var standard = raw.offset;
    var start = raw.start;
    var end = raw.end;
    if (start != null && end != null && end - start < _year) {
      // The smallest offset within a year either side.
      // Offsets more than 3 hours lower aren't considered: no DST is that
      // large, but a zone can jump across the date line (Pacific/Apia).
      bool candidate(int offset) =>
          offset < standard && raw.offset - offset <= _maxSavings;
      for (var t = start - 1; t >= start - _year && t >= _minMs;) {
        var previous = _rawInterval(t);
        if (candidate(previous.offset)) standard = previous.offset;
        if (previous.start == null) break;
        t = previous.start! - 1;
      }
      for (var t = end; t <= end + _year && t <= _maxMs;) {
        var next = _rawInterval(t);
        if (candidate(next.offset)) standard = next.offset;
        if (next.end == null) break;
        t = next.end!;
      }
    }
    var nameAt = start ?? (end != null ? end - 1 : 0);
    return IZoneInterval.newZoneInterval(
        _name(nameAt),
        start == null ? null : Instant.fromEpochMilliseconds(start),
        end == null ? null : Instant.fromEpochMilliseconds(end),
        Offset(raw.offset),
        Offset(raw.offset - standard));
  }

  /// The interval (by offset alone) containing [ms].
  _RawInterval _rawInterval(int ms) {
    // Binary search the cache, which is sorted and non-overlapping.
    var lower = 0;
    var upper = _cache.length;
    while (lower < upper) {
      var middle = (lower + upper) >> 1;
      var candidate = _cache[middle];
      if (candidate.start != null && ms < candidate.start!) {
        upper = middle;
      } else if (candidate.end != null && ms >= candidate.end!) {
        lower = middle + 1;
      } else {
        return candidate;
      }
    }
    var offset = _offset(ms);
    int? start;
    int? end;
    if (_useTemporal) {
      try {
        start = _temporalTransition(ms + 1, 'previous');
        end = _temporalTransition(ms, 'next');
        if (start != null && start < _minMs) start = null;
        if (end != null && end > _maxMs) end = null;
      } catch (_) {
        start = _findStart(ms, offset);
        end = _findEnd(ms, offset);
      }
    } else {
      start = _findStart(ms, offset);
      end = _findEnd(ms, offset);
    }
    var interval = _RawInterval(start, end, offset);
    _cache.insert(lower, interval);
    return interval;
  }

  int? _temporalTransition(int ms, String direction) {
    var transition = _TemporalInstant.fromEpochMilliseconds(ms.toDouble())
        .toZonedDateTimeISO(id)
        .getTimeZoneTransition(direction);
    return transition?.epochMilliseconds.toInt();
  }

  /// The first millisecond of the run of [offset] containing [ms], or null if
  /// it extends to the start of time.
  int? _findStart(int ms, int offset) {
    var known = ms; // [known, ms] all has the offset.
    var step = _minStep;
    while (true) {
      // No transitions before 1800.
      if (known < _earliestTransition) return null;
      // After 2100 the rules repeat yearly, so two quiet years mean there are
      // no transitions back to 2100.
      if (known > _finalRulesStart && ms - known >= 2 * _year) {
        if (_offset(_finalRulesStart) != offset) {
          return _searchChange(_finalRulesStart, known, offset, false);
        }
        known = _finalRulesStart;
        continue;
      }
      var probe = known - step < _minMs ? _minMs : known - step;
      if (probe == known) return null;
      if (_offset(probe) != offset) {
        return _searchChange(probe, known, offset, false);
      }
      known = probe;
      step = step * 2 > _maxStep ? _maxStep : step * 2;
    }
  }

  /// The first millisecond after the run of [offset] containing [ms], or null
  /// if it extends to the end of time.
  int? _findEnd(int ms, int offset) {
    var known = ms; // [ms, known] all has the offset.
    var step = _minStep;
    while (true) {
      // No transitions before 1800: skip ahead.
      if (known < _earliestTransition) {
        if (_offset(_earliestTransition) != offset) {
          return _searchChange(known, _earliestTransition, offset, true);
        }
        known = _earliestTransition;
        continue;
      }
      // After 2100 the rules repeat yearly, so two quiet years mean there are
      // no more transitions.
      var quietFrom = ms > _finalRulesStart ? ms : _finalRulesStart;
      if (known - quietFrom >= 2 * _year) return null;
      var probe = known + step > _maxMs ? _maxMs : known + step;
      if (probe == known) return null;
      if (_offset(probe) != offset) {
        return _searchChange(known, probe, offset, true);
      }
      known = probe;
      step = step * 2 > _maxStep ? _maxStep : step * 2;
    }
  }

  /// Binary searches (lower, upper] for the transition. If [fromOffset], the
  /// offset at [lower] is [offset] and the result is the first millisecond
  /// without it; otherwise the offset at [upper] is [offset] and the result
  /// is the first millisecond with it.
  int _searchChange(int lower, int upper, int offset, bool fromOffset) {
    while (upper - lower > 1) {
      var middle = lower + ((upper - lower) >> 1);
      var matches = _offset(middle) == offset;
      if (matches == fromOffset) {
        lower = middle;
      } else {
        upper = middle;
      }
    }
    return upper;
  }

  /// The UTC offset in seconds at [ms].
  int _offset(int ms) {
    var cached = _offsetCache[ms];
    if (cached != null) return cached;
    var parts = _offsetFormat.formatToParts(ms.toDouble()).toDart;
    for (var part in parts) {
      if (part.type == 'timeZoneName') {
        var offset = parseLongOffset(part.value);
        if (_offsetCache.length > 4096) _offsetCache.clear();
        return _offsetCache[ms] = offset;
      }
    }
    throw StateError('No time zone name formatting $ms in $id');
  }

  String _name(int ms) {
    try {
      for (var part in _nameFormat.formatToParts(ms.toDouble()).toDart) {
        if (part.type == 'timeZoneName') return part.value;
      }
    } catch (_) {
      // Fall through.
    }
    return id;
  }

  static bool _hasTemporal() {
    try {
      var temporal = _temporal;
      if (temporal == null || temporal.instant == null) return false;
      return temporal.zonedDateTime?.prototype?.getTimeZoneTransition != null;
    } catch (_) {
      return false;
    }
  }
}

/// Parses a 'longOffset' time zone name: 'GMT', 'GMT+10:00', 'GMT-03:30' or
/// 'GMT-04:56:02', in seconds.
@internal
int parseLongOffset(String text) {
  var match =
      RegExp(r'^(?:GMT|UTC)(?:([+\-−])(\d{1,2})(?::?(\d{2}))?(?::?(\d{2}))?)?$')
          .firstMatch(text.trim());
  if (match == null) {
    throw FormatException('Unexpected time zone offset', text);
  }
  if (match.group(1) == null) return 0;
  var seconds = int.parse(match.group(2)!) * 3600 +
      int.parse(match.group(3) ?? '0') * 60 +
      int.parse(match.group(4) ?? '0');
  return match.group(1) == '+' ? seconds : -seconds;
}

class _RawInterval {
  final int? start;
  final int? end;
  final int offset;
  ZoneInterval? zoneInterval;

  _RawInterval(this.start, this.end, this.offset);
}

// ---------------------------------------------------------------------------
// JS interop
// ---------------------------------------------------------------------------

@JS('Intl')
external _Intl? get _intl;

extension type _Intl._(JSObject _) implements JSObject {
  @JS('supportedValuesOf')
  external JSFunction? get supportedValuesOfFunction;

  external JSArray<JSString> supportedValuesOf(String key);
}

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external factory _DateTimeFormat(String locale, _FormatOptions options);
  external factory _DateTimeFormat.defaults();

  external JSArray<_FormatPart> formatToParts(double date);
  external _ResolvedOptions resolvedOptions();
}

extension type _FormatOptions._(JSObject _) implements JSObject {
  external factory _FormatOptions({String timeZone, String timeZoneName});
}

extension type _FormatPart._(JSObject _) implements JSObject {
  external String get type;
  external String get value;
}

extension type _ResolvedOptions._(JSObject _) implements JSObject {
  external String? get timeZone;
}

@JS('Temporal')
external _Temporal? get _temporal;

extension type _Temporal._(JSObject _) implements JSObject {
  @JS('Instant')
  external JSObject? get instant;
  @JS('ZonedDateTime')
  external _Constructor? get zonedDateTime;
}

extension type _Constructor._(JSObject _) implements JSObject {
  external _ZonedDateTimePrototype? get prototype;
}

extension type _ZonedDateTimePrototype._(JSObject _) implements JSObject {
  external JSFunction? get getTimeZoneTransition;
}

@JS('Temporal.Instant')
extension type _TemporalInstant._(JSObject _) implements JSObject {
  external static _TemporalInstant fromEpochMilliseconds(double ms);
  external _ZonedDateTime toZonedDateTimeISO(String timeZone);
}

extension type _ZonedDateTime._(JSObject _) implements JSObject {
  external _ZonedDateTime? getTimeZoneTransition(String direction);
  external double get epochMilliseconds;
}
