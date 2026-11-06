// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'system_backend.dart';
import 'system_time_zone_backend.dart';

/// A [DateTimeZoneSource] that reads the platform's own time zone database,
/// as .NET's `TimeZoneInfo` (and so Noda Time's `BclDateTimeZoneSource`) does:
///
/// * Windows: the Windows time zone database, through the Win32 dynamic time
///   zone API. Zone IDs are Windows IDs, e.g. 'AUS Eastern Standard Time'.
///   [forId] (and [DateTimeZoneProviders.system]) also accepts IANA IDs, as
///   .NET 6 and later do: 'Australia/Sydney' is mapped to its Windows zone
///   with Windows' own ICU and returned with the ID 'Australia/Sydney'.
///   [getIds] lists only the Windows IDs.
/// * Linux, macOS and iOS: the compiled TZif files in `$TZDIR` or
///   `/usr/share/zoneinfo`. Zone IDs are IANA IDs.
/// * Android: the system tzdata bundle. Zone IDs are IANA IDs.
/// * The web (JavaScript and WebAssembly): the browser's `Intl` time zone
///   data. Zone IDs are IANA IDs. Browsers only expose UTC offsets, not
///   rules, so transitions are found by searching, and the split between
///   standard time and daylight saving time is inferred.
///
/// The results follow the platform's data, which may be older or newer than
/// Time Machine's embedded TZDB data, and on Windows can differ from TZDB
/// altogether.
///
/// This source never falls back to Time Machine's embedded TZDB data: on a
/// platform without time zone data, [getIds] and [forId] throw
/// [UnsupportedError], and an ID the platform doesn't know is reported as
/// missing. Use [DateTimeZoneProviders.tzdb] if you need data on every
/// platform, or combine the two providers yourself.
class SystemDateTimeZoneSource extends DateTimeZoneSource {
  final SystemTimeZoneBackend _backend;
  List<String>? _ids;
  String? _systemDefaultIdOverride;

  /// Creates a source for the current platform's time zone database.
  SystemDateTimeZoneSource() : _backend = createSystemTimeZoneBackend();

  /// Creates a source over a specific backend. For testing.
  @visibleForTesting
  SystemDateTimeZoneSource.withBackend(this._backend);

  /// Whether the current platform provides time zone data.
  ///
  /// When this is false, [getIds] and [forId] throw [UnsupportedError].
  static bool get isSupported => createSystemTimeZoneBackend().isSupported;

  /// Where this source's data comes from, e.g. 'Windows' or
  /// 'TZif (/usr/share/zoneinfo)'.
  String get description => _backend.description;

  void _checkSupported() {
    if (!_backend.isSupported) {
      throw UnsupportedError(
          'This platform has no time zone database that Time Machine can read '
          '(${_backend.description}). SystemDateTimeZoneSource never falls '
          'back to the embedded TZDB data; use DateTimeZoneProviders.tzdb '
          'instead.');
    }
  }

  List<String> _getIdsSync() {
    _checkSupported();
    return _ids ??= List.unmodifiable(_backend.getIds());
  }

  @override
  Future<Iterable<String>> getIds() async => _getIdsSync();

  @override
  Future<DateTimeZone> forId(String id) async => forCachedId(id);

  @override
  DateTimeZone forCachedId(String id) {
    _checkSupported();
    var zone = _backend.loadZone(id);
    if (zone == null) {
      throw DateTimeZoneNotFoundError(
          'Time zone $id is not available from $versionId');
    }
    return zone;
  }

  /// The zone for an ID that isn't one of [getIds] but that the platform
  /// recognises (an IANA ID on Windows), or null. Lets
  /// [DateTimeZoneProviders.system] accept the IDs [forId] does.
  @internal
  DateTimeZone? unlistedZoneOrNull(String id) =>
      _backend.isSupported ? _backend.loadZone(id) : null;

  @override
  String get versionId {
    var version = _backend.dataVersion;
    return version == null
        ? 'System: ${_backend.description}'
        : 'System: ${_backend.description} $version';
  }

  @override
  String? get systemDefaultId =>
      _systemDefaultIdOverride ??
      (_backend.isSupported ? _backend.systemDefaultId : null);

  @override
  void setSystemDefaultId(String id) {
    _systemDefaultIdOverride = id;
  }
}
