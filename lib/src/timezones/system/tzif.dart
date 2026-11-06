// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Reading compiled TZif time zone files (RFC 8536, tzfile(5)), as found in
// /usr/share/zoneinfo and inside Android's tzdata bundle, and the POSIX TZ
// strings in their footers. Pure Dart, so it can be tested on any platform.

import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'map_datetimezone.dart';

/// A local time type ("ttinfo") in a TZif file.
@immutable
@internal
class TzifLocalTimeType {
  /// The UT offset in seconds (east of Greenwich is positive).
  final int utOffset;
  final bool isDst;
  final String abbreviation;

  const TzifLocalTimeType(this.utOffset, this.isDst, this.abbreviation);

  @override
  String toString() => '$abbreviation $utOffset${isDst ? ' (DST)' : ''}';
}

/// The contents of a TZif file that matter for time zone conversion. Leap
/// second records and the standard/wall and UT/local indicators are skipped.
@immutable
@internal
class TzifData {
  /// The format version: 1, 2, 3 or 4.
  final int version;

  /// Transition times in seconds since the Unix epoch, ascending.
  final List<int> transitionTimes;

  /// For each transition, the index into [localTimeTypes] of the type that
  /// applies from it.
  final List<int> transitionTypes;

  final List<TzifLocalTimeType> localTimeTypes;

  /// The POSIX TZ string for instants after the last transition (version 2
  /// and later), or null. May be empty, meaning "unspecified".
  final String? footer;

  const TzifData(this.version, this.transitionTimes, this.transitionTypes,
      this.localTimeTypes, this.footer);
}

/// Whether [bytes] start with the TZif magic number.
@internal
bool hasTzifMagic(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x54 && // T
    bytes[1] == 0x5A && // Z
    bytes[2] == 0x69 && // i
    bytes[3] == 0x66; // f

/// Parses TZif data (versions 1 to 4). For version 2 and later, the 64-bit
/// data block and the footer are used.
///
/// Throws a [FormatException] if the data is malformed.
@internal
TzifData parseTzif(Uint8List bytes) {
  var data = ByteData.sublistView(bytes);
  if (!hasTzifMagic(bytes) || bytes.length < 44) {
    throw const FormatException('Not TZif data');
  }
  var versionByte = bytes[4];
  var version = versionByte == 0 ? 1 : versionByte - 0x30;
  if (version < 1 || version > 9) {
    throw FormatException('Unknown TZif version $versionByte');
  }

  var header = _TzifHeader(data, 0);
  var position = 44;
  if (version >= 2) {
    // Skip the version 1 block; the version 2+ block has 64-bit times.
    position += header.blockSize(4);
    if (position + 44 > bytes.length) {
      throw const FormatException('Truncated TZif data');
    }
    header = _TzifHeader(data, position);
    position += 44;
    return _readBlock(bytes, data, header, position, 8, version);
  }
  return _readBlock(bytes, data, header, position, 4, version);
}

class _TzifHeader {
  final int isUtCount;
  final int isStdCount;
  final int leapCount;
  final int timeCount;
  final int typeCount;
  final int charCount;

  _TzifHeader(ByteData data, int offset)
      : isUtCount = data.getUint32(offset + 20),
        isStdCount = data.getUint32(offset + 24),
        leapCount = data.getUint32(offset + 28),
        timeCount = data.getUint32(offset + 32),
        typeCount = data.getUint32(offset + 36),
        charCount = data.getUint32(offset + 40);

  int blockSize(int timeSize) =>
      timeCount * timeSize +
      timeCount +
      typeCount * 6 +
      charCount +
      leapCount * (timeSize + 4) +
      isStdCount +
      isUtCount;
}

TzifData _readBlock(Uint8List bytes, ByteData data, _TzifHeader header,
    int position, int timeSize, int version) {
  if (position + header.blockSize(timeSize) > bytes.length) {
    throw const FormatException('Truncated TZif data');
  }
  if (header.typeCount == 0) {
    throw const FormatException('TZif data has no local time types');
  }
  var times = <int>[];
  for (var i = 0; i < header.timeCount; i++) {
    times.add(timeSize == 8
        ? _getInt64(data, position + i * 8)
        : data.getInt32(position + i * 4));
  }
  position += header.timeCount * timeSize;
  var types = <int>[];
  for (var i = 0; i < header.timeCount; i++) {
    var type = bytes[position + i];
    if (type >= header.typeCount) {
      throw FormatException('Bad TZif transition type $type');
    }
    types.add(type);
  }
  position += header.timeCount;

  var typeRecords = <(int, bool, int)>[];
  for (var i = 0; i < header.typeCount; i++) {
    var offset = position + i * 6;
    typeRecords.add(
        (data.getInt32(offset), bytes[offset + 4] != 0, bytes[offset + 5]));
  }
  position += header.typeCount * 6;
  var chars = bytes.sublist(position, position + header.charCount);
  position += header.charCount;
  var localTimeTypes = [
    for (var (utOffset, isDst, index) in typeRecords)
      TzifLocalTimeType(utOffset, isDst, _abbreviation(chars, index)),
  ];

  // Leap second records and the indicators aren't needed.
  position +=
      header.leapCount * (timeSize + 4) + header.isStdCount + header.isUtCount;

  String? footer;
  if (version >= 2 && position < bytes.length && bytes[position] == 0x0A) {
    var end = bytes.indexOf(0x0A, position + 1);
    if (end > position) {
      footer =
          ascii.decode(bytes.sublist(position + 1, end), allowInvalid: true);
    }
  }
  return TzifData(version, times, types, localTimeTypes, footer);
}

int _getInt64(ByteData data, int offset) {
  // ByteData.getInt64 isn't supported when compiled to JavaScript.
  var high = data.getInt32(offset);
  var low = data.getUint32(offset + 4);
  return high * 0x100000000 + low;
}

String _abbreviation(Uint8List chars, int index) {
  if (index >= chars.length) return '';
  var end = chars.indexOf(0, index);
  if (end < 0) end = chars.length;
  return ascii.decode(chars.sublist(index, end), allowInvalid: true);
}

// Transitions outside this range (a day inside the range of Instant) are
// ignored. zic emits a transition at -2**59 for the "big bang" in some
// configurations.
const int _minTransitionSeconds = IInstant.minDays * 86400 + 86400;
const int _maxTransitionSeconds = IInstant.maxDays * 86400 - 86400;

/// Builds a [DateTimeZone] from parsed TZif data.
///
/// Each zone interval gets the time type's abbreviation as its name. Since
/// TZif data only records whether a time type is daylight saving time, not
/// the standard offset, the savings of a DST interval are taken to be its
/// offset minus the most recent standard time offset, with fallbacks where
/// that's implausible (see below). So the standard/daylight split can differ
/// from TZDB's source data (and so from [DateTimeZoneProviders.tzdb]) where
/// the standard offset changed while DST was in effect. The footer's POSIX TZ
/// rule, if there is one, applies after the last transition.
///
/// Throws a [FormatException] if the data can't be represented (e.g. an
/// offset beyond +/- 18 hours).
@internal
DateTimeZone tzifToDateTimeZone(String id, TzifData data) {
  PosixTimeZone? tail;
  var footer = data.footer;
  if (footer != null && footer.isNotEmpty) {
    tail = PosixTimeZone.parse(footer);
    if (tail == null) throw FormatException('Bad TZif footer', footer);
  }

  // The time type before the first (usable) transition is type 0.
  var initialType = 0;
  var times = <int>[];
  var types = <int>[];
  for (var i = 0; i < data.transitionTimes.length; i++) {
    var time = data.transitionTimes[i];
    if (time < _minTransitionSeconds) {
      initialType = data.transitionTypes[i];
      continue;
    }
    if (time > _maxTransitionSeconds) break;
    if (times.isNotEmpty && time <= times.last) {
      throw const FormatException('TZif transitions are not in order');
    }
    times.add(time);
    types.add(data.transitionTypes[i]);
  }

  if (times.isEmpty && tail != null) {
    // No transitions: the TZ string applies to all of time.
    return tail.toDateTimeZone(id);
  }

  var typeSequence = [initialType, ...types];
  var localTimeTypes = data.localTimeTypes;

  // The next standard offset after typeSequence[index] (or failing that the
  // footer's), or null.
  int? nextStandardFrom(int index) {
    for (var j = index + 1; j < typeSequence.length; j++) {
      var type = localTimeTypes[typeSequence[j]];
      if (!type.isDst) return type.utOffset;
    }
    return tail?.standardOffset;
  }

  // The savings for each element of typeSequence: zero for standard time;
  // for DST, the offset minus the most recent standard offset (or the next
  // one, for DST before any standard time). Where that's implausible (zero,
  // or more than 3 hours either way), the next standard offset is tried, and
  // failing that one hour is assumed. Examples: Argentina in 1999, which
  // changed its standard offset from -03 to -04 as it started DST (so the
  // DST offset equals the previous standard offset), and Pacific/Apia, which
  // moved from -10 (DST) to +14 (DST) across the date line in 2011. (Noda
  // Time similarly assumes one hour for zero-savings DST in
  // BclDateTimeZone.)
  bool plausible(int savings) => savings != 0 && savings.abs() <= 3 * 3600;
  var savingsList = <int>[];
  int? lastStandard;
  for (var i = 0; i < typeSequence.length; i++) {
    var type = localTimeTypes[typeSequence[i]];
    if (!type.isDst) {
      lastStandard = type.utOffset;
      savingsList.add(0);
      continue;
    }
    var candidates = [lastStandard, nextStandardFrom(i)];
    var savings = 3600;
    for (var standard in candidates) {
      if (standard != null && plausible(type.utOffset - standard)) {
        savings = type.utOffset - standard;
        break;
      }
    }
    savingsList.add(savings);
  }

  // Build the intervals. With a tail, the last transition starts the tail.
  var intervalCount = tail != null ? times.length : times.length + 1;
  var periods = <ZoneInterval>[];
  for (var i = 0; i < intervalCount; i++) {
    var type = localTimeTypes[typeSequence[i]];
    var start = i == 0
        ? IInstant.beforeMinValue
        : Instant.fromEpochSeconds(times[i - 1]);
    var end = i < times.length
        ? Instant.fromEpochSeconds(times[i])
        : IInstant.afterMaxValue;
    var wallOffset = _offset(type.utOffset);
    var savings = _offset(savingsList[i]);
    if (periods.isNotEmpty) {
      var previous = periods.last;
      if (previous.name == type.abbreviation &&
          previous.wallOffset == wallOffset &&
          previous.savings == savings) {
        // Not a real transition: extend the previous interval.
        periods[periods.length - 1] = IZoneInterval.newZoneInterval(
            previous.name,
            IZoneInterval.rawStart(previous),
            end,
            wallOffset,
            savings);
        continue;
      }
    }
    periods.add(IZoneInterval.newZoneInterval(
        type.abbreviation, start, end, wallOffset, savings));
  }

  // Drop trailing intervals that the TZ string describes identically, so the
  // tail starts at the last real transition. "Fat" TZif files (e.g. Ubuntu's)
  // end with a no-op transition at 2038-01-19T03:14:07Z for 32-bit readers.
  var tailMap = tail?.toZoneIntervalMap();
  if (tailMap != null) {
    while (periods.length > 1) {
      var last = periods.last;
      var fromTail = tailMap.getZoneInterval(IZoneInterval.rawStart(last));
      // Only if the TZ string gives the same interval for all of it.
      if (fromTail.name != last.name ||
          fromTail.wallOffset != last.wallOffset ||
          fromTail.savings != last.savings ||
          IZoneInterval.rawEnd(fromTail) < IZoneInterval.rawEnd(last)) {
        break;
      }
      periods.removeLast();
    }
  }

  if (tail == null &&
      periods.length == 1 &&
      periods.single.savings == Offset.zero) {
    var only = periods.single;
    return FixedDateTimeZone(id, only.wallOffset, only.name);
  }
  return CachedDateTimeZone.forZone(
      PrecalculatedDateTimeZone(id, periods, tailMap));
}

Offset _offset(int seconds) {
  if (seconds < Offset.minValue.inSeconds ||
      seconds > Offset.maxValue.inSeconds) {
    throw FormatException('Offset out of range: $seconds seconds');
  }
  return Offset(seconds);
}

// ---------------------------------------------------------------------------
// POSIX TZ strings
// ---------------------------------------------------------------------------

/// The kinds of date in a POSIX TZ rule.
@internal
enum PosixDateKind {
  /// `Jn`: day n (1-365) of the year, never counting February 29th.
  julian,

  /// `n`: zero-based day n (0-365) of the year, counting February 29th.
  zeroBased,

  /// `Mm.w.d`: day d (0 = Sunday) of week w (1-5, 5 = last) of month m.
  monthWeekDay,
}

/// A transition date and time in a POSIX TZ rule.
@immutable
@internal
class PosixTransition {
  final PosixDateKind kind;

  /// The day for [PosixDateKind.julian] and [PosixDateKind.zeroBased].
  final int day;
  final int month;
  final int week;
  final int dayOfWeek;

  /// The local time of day of the transition, in seconds. Version 3 TZif
  /// allows this to be negative or more than 24 hours (-167 to 167 hours).
  final int timeOfDay;

  const PosixTransition.julian(this.day, this.timeOfDay)
      : kind = PosixDateKind.julian,
        month = 0,
        week = 0,
        dayOfWeek = 0;

  const PosixTransition.zeroBased(this.day, this.timeOfDay)
      : kind = PosixDateKind.zeroBased,
        month = 0,
        week = 0,
        dayOfWeek = 0;

  const PosixTransition.monthWeekDay(
      this.month, this.week, this.dayOfWeek, this.timeOfDay)
      : kind = PosixDateKind.monthWeekDay,
        day = 0;

  /// The local date and time of this transition in [year], in seconds since
  /// the epoch as if local time were UTC.
  int localSecondsInYear(int year) {
    int epochDay;
    switch (kind) {
      case PosixDateKind.julian:
        var dayOfYear = day;
        if (_isLeapYear(year) && day >= 60) dayOfYear++;
        epochDay = _daysFromCivil(year, 1, 1) + dayOfYear - 1;
        break;
      case PosixDateKind.zeroBased:
        epochDay = _daysFromCivil(year, 1, 1) + day;
        break;
      case PosixDateKind.monthWeekDay:
        var first = _daysFromCivil(year, month, 1);
        // 1970-01-01 was a Thursday (4).
        var firstDayOfWeek = (first + 4) % 7;
        epochDay =
            first + (dayOfWeek - firstDayOfWeek + 7) % 7 + (week - 1) * 7;
        var nextMonth = month == 12
            ? _daysFromCivil(year + 1, 1, 1)
            : _daysFromCivil(year, month + 1, 1);
        while (epochDay >= nextMonth) {
          epochDay -= 7;
        }
        break;
    }
    return epochDay * 86400 + timeOfDay;
  }

  @override
  bool operator ==(Object other) =>
      other is PosixTransition &&
      kind == other.kind &&
      day == other.day &&
      month == other.month &&
      week == other.week &&
      dayOfWeek == other.dayOfWeek &&
      timeOfDay == other.timeOfDay;

  @override
  int get hashCode =>
      hashObjects([kind, day, month, week, dayOfWeek, timeOfDay]);

  @override
  String toString() {
    var date = switch (kind) {
      PosixDateKind.julian => 'J$day',
      PosixDateKind.zeroBased => '$day',
      PosixDateKind.monthWeekDay => 'M$month.$week.$dayOfWeek',
    };
    return '$date/${timeOfDay}s';
  }
}

/// A POSIX TZ string such as `EST5EDT,M3.2.0,M11.1.0`, as used in TZif
/// footers, with the tzfile(5) extensions: angle-bracket quoted names
/// (`<+0330>-3:30`) and transition times from -167 to 167 hours.
///
/// Offsets here are UT offsets (east of Greenwich positive), i.e. the
/// negation of the POSIX notation.
@immutable
@internal
class PosixTimeZone {
  final String standardName;

  /// The standard time UT offset in seconds.
  final int standardOffset;

  /// Null if there's no daylight saving time.
  final String? daylightName;

  /// The daylight time UT offset in seconds; null without DST.
  final int? daylightOffset;

  /// When daylight saving time starts (local standard time); null without
  /// DST.
  final PosixTransition? start;

  /// When daylight saving time ends (local daylight time); null without
  /// DST.
  final PosixTransition? end;

  const PosixTimeZone(this.standardName, this.standardOffset,
      [this.daylightName, this.daylightOffset, this.start, this.end]);

  bool get hasDaylightSavingTime => daylightName != null;

  /// Parses a POSIX TZ string, returning null if it's not valid.
  static PosixTimeZone? parse(String text) => _PosixParser(text).parse();

  @override
  String toString() => hasDaylightSavingTime
      ? '$standardName $standardOffset $daylightName $daylightOffset '
          '$start $end'
      : '$standardName $standardOffset';

  /// The UTC instant (seconds) at which DST starts in [year].
  int _startSeconds(int year) =>
      start!.localSecondsInYear(year) - standardOffset;

  /// The UTC instant (seconds) at which DST ends in [year].
  int _endSeconds(int year) => end!.localSecondsInYear(year) - daylightOffset!;

  /// A map for all of time following this rule.
  ZoneIntervalMapWithMinMax toZoneIntervalMap() {
    if (!hasDaylightSavingTime) return _fixedMap(false);
    // tzfile(5): DST is in effect all year if it starts January 1 at 00:00
    // and ends December 31 at 24:00 plus the DST difference; that is, if
    // DST ends exactly when it starts the following year. Check a leap and
    // a non-leap year.
    if (_endSeconds(2023) == _startSeconds(2024) &&
        _endSeconds(2024) == _startSeconds(2025)) {
      return _fixedMap(true);
    }
    if (_startSeconds(2023) == _endSeconds(2023) &&
        _startSeconds(2024) == _endSeconds(2024)) {
      return _fixedMap(false);
    }
    return _PosixRuleMap(this);
  }

  DateTimeZone toDateTimeZone(String id) {
    var map = toZoneIntervalMap();
    if (map is _FixedMap) {
      // FixedDateTimeZone has no savings, so isn't used for all-year DST.
      return map.interval.savings == Offset.zero
          ? FixedDateTimeZone(id, map.interval.wallOffset, map.interval.name)
          : MapDateTimeZone(id, map, map.minOffset, map.maxOffset);
    }
    return CachedDateTimeZone.forZone(
        MapDateTimeZone(id, map, map.minOffset, map.maxOffset));
  }

  _FixedMap _fixedMap(bool daylight) {
    var interval = daylight
        ? IZoneInterval.newZoneInterval(
            daylightName!,
            IInstant.beforeMinValue,
            IInstant.afterMaxValue,
            _offset(daylightOffset!),
            _offset(daylightOffset! - standardOffset))
        : IZoneInterval.newZoneInterval(standardName, IInstant.beforeMinValue,
            IInstant.afterMaxValue, _offset(standardOffset), Offset.zero);
    return _FixedMap(interval);
  }
}

class _FixedMap implements ZoneIntervalMapWithMinMax {
  final ZoneInterval interval;

  _FixedMap(this.interval);

  @override
  ZoneInterval getZoneInterval(Instant instant) => interval;

  @override
  Offset get minOffset => interval.wallOffset;

  @override
  Offset get maxOffset => interval.wallOffset;
}

/// Alternating standard and daylight time following a POSIX TZ rule.
///
/// This doesn't use [StandardDaylightAlternatingMap], as [ZoneYearOffset]
/// can't represent all POSIX rules: zero-based day-of-year dates, and the
/// version 3 transition times beyond 24:00 or before 00:00 (e.g.
/// `M3.4.4/26`, which is a Friday after the fourth Thursday, possibly in the
/// next month).
class _PosixRuleMap implements ZoneIntervalMapWithMinMax {
  // The years of Instant; transitions outside its range are ignored.
  static const int _minYear = -9998;
  static const int _maxYear = 9999;
  static const int _minSeconds = IInstant.minDays * 86400;
  static const int _maxSeconds = IInstant.maxDays * 86400 + 86399;

  final PosixTimeZone _zone;
  final Offset _standardOffset;
  final Offset _daylightOffset;
  final Offset _savings;

  _PosixRuleMap(this._zone)
      : _standardOffset = _offset(_zone.standardOffset),
        _daylightOffset = _offset(_zone.daylightOffset!),
        _savings = _offset(_zone.daylightOffset! - _zone.standardOffset);

  @override
  Offset get minOffset =>
      _standardOffset < _daylightOffset ? _standardOffset : _daylightOffset;

  @override
  Offset get maxOffset =>
      _standardOffset > _daylightOffset ? _standardOffset : _daylightOffset;

  @override
  ZoneInterval getZoneInterval(Instant instant) {
    var year = _yearFromEpochDay(_floorDiv(instant.epochSeconds, 86400));
    for (var radius = 1; radius <= 3; radius++) {
      var transitions = <(Instant, bool)>[];
      for (var y = year - radius; y <= year + radius; y++) {
        if (y < _minYear || y > _maxYear) continue;
        for (var (seconds, daylight) in [
          (_zone._startSeconds(y), true),
          (_zone._endSeconds(y), false)
        ]) {
          if (seconds >= _minSeconds && seconds <= _maxSeconds) {
            transitions.add((Instant.fromEpochSeconds(seconds), daylight));
          }
        }
      }
      transitions.sort((a, b) => a.$1.compareTo(b.$1));

      // The last transition at or before the instant decides the state.
      var previousIndex = -1;
      for (var i = 0; i < transitions.length; i++) {
        if (transitions[i].$1 <= instant) previousIndex = i;
      }
      bool daylight;
      Instant? start;
      if (previousIndex >= 0) {
        daylight = transitions[previousIndex].$2;
        start = transitions[previousIndex].$1;
        // Skip back over transitions that don't change the state.
        for (var i = previousIndex - 1; i >= 0; i--) {
          if (transitions[i].$2 != daylight) break;
          start = transitions[i].$1;
        }
      } else if (transitions.isNotEmpty) {
        daylight = !transitions.first.$2;
      } else {
        daylight = false;
      }
      Instant? end;
      for (var i = previousIndex + 1; i < transitions.length; i++) {
        if (transitions[i].$2 != daylight) {
          end = transitions[i].$1;
          break;
        }
      }
      var atStartOfYears = year - radius <= _minYear;
      var atEndOfYears = year + radius >= _maxYear;
      if ((start != null || atStartOfYears) && (end != null || atEndOfYears)) {
        return daylight
            ? IZoneInterval.newZoneInterval(
                _zone.daylightName!, start, end, _daylightOffset, _savings)
            : IZoneInterval.newZoneInterval(
                _zone.standardName, start, end, _standardOffset, Offset.zero);
      }
    }
    throw StateError('No transitions found for ${_zone.toString()}');
  }
}

class _PosixParser {
  final String text;
  int _position = 0;

  _PosixParser(this.text);

  bool get _atEnd => _position >= text.length;

  String get _current => text[_position];

  PosixTimeZone? parse() {
    try {
      var standardName = _name();
      var standardOffset = _offsetValue();
      if (standardName == null || standardOffset == null) return null;
      if (_atEnd) return PosixTimeZone(standardName, -standardOffset);

      var daylightName = _name();
      if (daylightName == null) return null;
      var daylightOffset = standardOffset - 3600;
      if (!_atEnd && _current != ',') {
        var parsed = _offsetValue();
        if (parsed == null) return null;
        daylightOffset = parsed;
      }

      PosixTransition? start;
      PosixTransition? end;
      if (_atEnd) {
        // tzfile(5): the default rule is the US one.
        start = const PosixTransition.monthWeekDay(3, 2, 0, 7200);
        end = const PosixTransition.monthWeekDay(11, 1, 0, 7200);
      } else {
        if (!_consume(',')) return null;
        start = _transition();
        if (start == null || !_consume(',')) return null;
        end = _transition();
        if (end == null || !_atEnd) return null;
      }
      return PosixTimeZone(standardName, -standardOffset, daylightName,
          -daylightOffset, start, end);
    } on FormatException {
      return null;
    }
  }

  bool _consume(String char) {
    if (!_atEnd && _current == char) {
      _position++;
      return true;
    }
    return false;
  }

  String? _name() {
    if (_consume('<')) {
      var end = text.indexOf('>', _position);
      if (end < 0) return null;
      var name = text.substring(_position, end);
      _position = end + 1;
      return name.isEmpty ? null : name;
    }
    var start = _position;
    while (!_atEnd && _isAlpha(_current.codeUnitAt(0))) {
      _position++;
    }
    return _position - start >= 1 ? text.substring(start, _position) : null;
  }

  /// [+-]hh[:mm[:ss]] in seconds, or null.
  int? _offsetValue() => _signedHms(24);

  /// A transition time, [+-]hhh[:mm[:ss]] in seconds (-167 to 167 hours).
  int? _time() => _signedHms(167);

  int? _signedHms(int maxHours) {
    var sign = 1;
    if (_consume('-')) {
      sign = -1;
    } else {
      _consume('+');
    }
    var hours = _number(3);
    if (hours == null || hours > maxHours) return null;
    var seconds = hours * 3600;
    if (_consume(':')) {
      var minutes = _number(2);
      if (minutes == null || minutes > 59) return null;
      seconds += minutes * 60;
      if (_consume(':')) {
        var secs = _number(2);
        if (secs == null || secs > 59) return null;
        seconds += secs;
      }
    }
    return sign * seconds;
  }

  int? _number(int maxDigits) {
    var start = _position;
    while (!_atEnd &&
        _position - start < maxDigits &&
        _isDigit(_current.codeUnitAt(0))) {
      _position++;
    }
    if (_position == start) return null;
    return int.parse(text.substring(start, _position));
  }

  PosixTransition? _transition() {
    var time = 7200;
    PosixTransition Function(int time)? make;
    if (_consume('J')) {
      var day = _number(3);
      if (day == null || day < 1 || day > 365) return null;
      make = (time) => PosixTransition.julian(day, time);
    } else if (_consume('M')) {
      var month = _number(2);
      if (month == null || month < 1 || month > 12 || !_consume('.')) {
        return null;
      }
      var week = _number(1);
      if (week == null || week < 1 || week > 5 || !_consume('.')) return null;
      var dayOfWeek = _number(1);
      if (dayOfWeek == null || dayOfWeek > 6) return null;
      make =
          (time) => PosixTransition.monthWeekDay(month, week, dayOfWeek, time);
    } else {
      var day = _number(3);
      if (day == null || day > 365) return null;
      make = (time) => PosixTransition.zeroBased(day, time);
    }
    if (_consume('/')) {
      var parsed = _time();
      if (parsed == null) return null;
      time = parsed;
    }
    return make(time);
  }

  static bool _isAlpha(int c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122);

  static bool _isDigit(int c) => c >= 48 && c <= 57;
}

// ---------------------------------------------------------------------------
// Proleptic Gregorian calendar arithmetic (Howard Hinnant's algorithms),
// valid for any year.
// ---------------------------------------------------------------------------

int _floorDiv(int a, int b) => (a - a % b) ~/ b;

bool _isLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

int _daysFromCivil(int year, int month, int day) {
  var y = month <= 2 ? year - 1 : year;
  var era = _floorDiv(y, 400);
  var yearOfEra = y - era * 400;
  var dayOfYear =
      (153 * (month > 2 ? month - 3 : month + 9) + 2) ~/ 5 + day - 1;
  var dayOfEra =
      yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
  return era * 146097 + dayOfEra - 719468;
}

int _yearFromEpochDay(int epochDay) {
  var z = epochDay + 719468;
  var era = _floorDiv(z, 146097);
  var dayOfEra = z - era * 146097;
  var yearOfEra =
      (dayOfEra - dayOfEra ~/ 1460 + dayOfEra ~/ 36524 - dayOfEra ~/ 146096) ~/
          365;
  var dayOfYear =
      dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
  var mp = (5 * dayOfYear + 2) ~/ 153;
  var month = mp < 10 ? mp + 3 : mp - 9;
  return yearOfEra + era * 400 + (month <= 2 ? 1 : 0);
}
