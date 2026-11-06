// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

/// A platform's own time zone data, as used by [SystemDateTimeZoneSource].
///
/// Implementations read the operating system's (or browser's) time zone
/// database. They never fall back to Time Machine's embedded TZDB data.
abstract class SystemTimeZoneBackend {
  /// Where the data comes from, e.g. 'Windows' or 'TZif (/usr/share/zoneinfo)'.
  String get description;

  /// Whether this platform can provide time zone data at all.
  bool get isSupported;

  /// The version of the platform's time zone data, if it's known
  /// (e.g. '2025b' for TZDB-based data).
  String? get dataVersion;

  /// The IDs of the zones the platform provides.
  List<String> getIds();

  /// Builds the zone with the given ID, or returns null if the platform
  /// doesn't have it. The ID may be one that [getIds] doesn't list but the
  /// platform recognises (an IANA ID on Windows); the zone has the given ID.
  DateTimeZone? loadZone(String id);

  /// The ID of the system's current time zone, if it can be determined and is
  /// one of [getIds].
  String? get systemDefaultId;
}

/// Backend for platforms with no time zone data.
class UnsupportedSystemTimeZoneBackend implements SystemTimeZoneBackend {
  final String reason;

  const UnsupportedSystemTimeZoneBackend(this.reason);

  @override
  String get description => 'unsupported ($reason)';

  @override
  bool get isSupported => false;

  @override
  String? get dataVersion => null;

  @override
  List<String> getIds() => const [];

  @override
  DateTimeZone? loadZone(String id) => null;

  @override
  String? get systemDefaultId => null;
}
