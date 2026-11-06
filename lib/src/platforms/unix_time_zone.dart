// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:collection/collection.dart';
import 'package:universal_io/io.dart' as io;

/// Finds the IANA ID of the system time zone on Linux, macOS and Android, the
/// way .NET's `TimeZoneInfo.Local` does (which is what Noda Time maps):
///
/// * Android: the `persist.sys.timezone` system property.
/// * Otherwise the `TZ` environment variable, if set (a leading ':' is ignored).
///   An empty value means UTC. A relative value is the ID itself.
/// * Otherwise `/etc/localtime` (or `$TZDIR/localtime`): the ID comes from
///   the symlink target, or failing that from the zoneinfo file with the same
///   contents.
///
/// [knownIds] are the TZDB IDs to accept, ordered with canonical IDs first so
/// a content match picks a canonical ID. Returns null if no known ID is found.
String? readUnixTimeZoneId(List<String> knownIds) {
  try {
    if (io.Platform.isAndroid) {
      final result = io.Process.runSync('getprop', ['persist.sys.timezone']);
      if (result.exitCode == 0) {
        final id = (result.stdout as String).trim();
        return knownIds.contains(id) ? id : null;
      }
      return null;
    }
    return resolveUnixTimeZoneId(knownIds,
        environment: io.Platform.environment);
  } catch (_) {
    return null;
  }
}

/// The non-Android part of [readUnixTimeZoneId], with the environment and the
/// path of `/etc/localtime` passed in so the rules can be tested.
///
/// * `TZ` set and empty: UTC.
/// * `TZ` set to an ID (optionally prefixed with ':'): that ID, if known. An
///   unknown ID gives null; `/etc/localtime` is not consulted, as in .NET.
///   A 'posix/' or 'right/' prefix is dropped (see [_knownId]).
/// * `TZ` set to an absolute path: the zone for that file.
/// * `TZ` unset: the zone for [etcLocaltime], then for `$TZDIR/localtime`.
String? resolveUnixTimeZoneId(List<String> knownIds,
    {required Map<String, String> environment,
    String etcLocaltime = '/etc/localtime'}) {
  final known = knownIds.toSet();
  String? accept(String? id) => id != null && known.contains(id) ? id : null;

  final zoneInfoDirectory = timeZoneDirectory(environment['TZDIR']);
  final tz = tzEnvironmentVariable(environment['TZ']);

  if (tz == null) {
    for (final path in [etcLocaltime, '${zoneInfoDirectory}localtime']) {
      final id = _idForFile(path, zoneInfoDirectory, knownIds);
      if (id != null) return accept(id);
    }
    return null;
  }

  // An empty TZ means UTC.
  if (tz.isEmpty) return accept('UTC') ?? accept('Etc/UTC');

  // A relative TZ is the ID, relative to the zoneinfo directory.
  if (!tz.startsWith('/')) return _knownId(tz, known);
  return accept(_idForFile(tz, zoneInfoDirectory, knownIds));
}

/// The value of `TZ`, without the leading ':' POSIX allows. Null if unset.
String? tzEnvironmentVariable(String? tz) =>
    tz != null && tz.startsWith(':') ? tz.substring(1) : tz;

/// The zoneinfo directory: `$TZDIR` or /usr/share/zoneinfo/, with a trailing slash.
String timeZoneDirectory(String? tzDir) {
  final directory =
      tzDir == null || tzDir.isEmpty ? '/usr/share/zoneinfo/' : tzDir;
  return directory.endsWith('/') ? directory : '$directory/';
}

/// The zone ID for a path inside a zoneinfo directory, for example
/// 'Europe/Berlin' for '/usr/share/zoneinfo/Europe/Berlin' or (on macOS)
/// '/var/db/timezone/zoneinfo/Europe/Berlin'. Null if the path isn't in one.
String? zoneIdFromPath(String path, String zoneInfoDirectory) {
  final normalized = _normalize(path);
  if (normalized.startsWith(zoneInfoDirectory)) {
    return normalized.substring(zoneInfoDirectory.length);
  }
  const marker = '/zoneinfo/';
  final index = normalized.lastIndexOf(marker);
  if (index < 0) return null;
  final id = normalized.substring(index + marker.length);
  return id.isEmpty ? null : id;
}

/// The known zone ID for a zoneinfo file, or null: from the symlink target,
/// else the file's own path, else the zoneinfo file with the same contents.
/// Path-derived IDs are only used if known, so an unknown one (such as
/// 'localtime') still gets the content match.
String? _idForFile(
    String path, String zoneInfoDirectory, List<String> knownIds) {
  final known = knownIds.toSet();

  // Prefer the symlink target, as .NET does. Unlike .NET, a dangling link
  // (e.g. on an image without tzdata) still counts: the zone it names comes
  // from the embedded TZDB data, not from the file.
  final link = io.Link(path);
  if (link.existsSync()) {
    var target = link.targetSync();
    if (!target.startsWith('/')) {
      target = '${io.File(path).parent.path}/$target';
    }
    final id = _knownId(zoneIdFromPath(target, zoneInfoDirectory), known);
    if (id != null) return id;
  }

  final file = io.File(path);
  if (!file.existsSync()) return null;

  // A file in the zoneinfo directory itself (e.g. TZ=/usr/share/zoneinfo/X).
  final direct = _knownId(zoneIdFromPath(path, zoneInfoDirectory), known);
  if (direct != null) return direct;

  // A copy rather than a link: find the zoneinfo file with the same contents.
  final contents = file.readAsBytesSync();
  const equality = ListEquality<int>();
  for (final id in knownIds) {
    final candidate = io.File('$zoneInfoDirectory$id');
    try {
      if (candidate.existsSync() &&
          candidate.lengthSync() == contents.length &&
          equality.equals(candidate.readAsBytesSync(), contents)) {
        return id;
      }
    } catch (_) {
      // Unreadable candidate; keep looking.
    }
  }
  return null;
}

/// [id] if it's known, or without a 'posix/' or 'right/' prefix if that's
/// known: zoneinfo/posix/X has X's rules, and zoneinfo/right/X X's rules
/// counting leap seconds. .NET keeps the prefix in `TimeZoneInfo.Local.Id`,
/// which Noda Time can't map and so guesses from transitions, possibly as
/// another zone with the same rules; dropping it finds X itself.
String? _knownId(String? id, Set<String> known) {
  if (id == null) return null;
  if (known.contains(id)) return id;
  for (final prefix in const ['posix/', 'right/']) {
    if (id.startsWith(prefix) && known.contains(id.substring(prefix.length))) {
      return id.substring(prefix.length);
    }
  }
  return null;
}

/// Resolves '.' and '..' segments and duplicate slashes.
String _normalize(String path) {
  final segments = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(segment);
    }
  }
  return '/${segments.join('/')}';
}
