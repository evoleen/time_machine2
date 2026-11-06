// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:universal_io/io.dart' as io;

/// The zone IDs the `TZ` environment variable could name on Windows, most
/// likely first, following Python's tzlocal (and Node.js, which supports IANA
/// IDs in `TZ` on Windows):
///
/// * Unset or empty: none (Windows' own zone is used).
/// * A leading ':' is ignored.
/// * The value itself, e.g. 'Asia/Tokyo' or, as on Windows only, a Windows
///   zone ID such as 'SA Western Standard Time'.
/// * For an absolute path to an existing file, the path's trailing
///   components, longest first (e.g. '.../zoneinfo/Asia/Tokyo' gives
///   'zoneinfo/Asia/Tokyo', then 'Asia/Tokyo', then 'Tokyo').
///
/// Callers take the first candidate they know. Values that name nothing, such
/// as POSIX rules like 'XST5XDT', are ignored. Unlike on Unix (and in .NET and
/// Noda Time, which ignore `TZ` on Windows), an empty or unrecognised `TZ`
/// doesn't mean UTC.
List<String> windowsTzEnvironmentCandidates(String? tz) {
  if (tz == null || tz.isEmpty) return const [];
  if (tz.startsWith(':')) tz = tz.substring(1);
  if (tz.isEmpty) return const [];
  var candidates = [tz];

  if (_isAbsolute(tz)) {
    try {
      var file = io.File(tz);
      if (file.existsSync()) {
        var parts = file
            .resolveSymbolicLinksSync()
            .split(RegExp(r'[\\/]'))
            .where((part) => part.isNotEmpty)
            .toList();
        for (var start = 0; start < parts.length; start++) {
          candidates.add(parts.sublist(start).join('/'));
        }
      }
    } catch (_) {
      // Unreadable path: only the value itself.
    }
  }
  return candidates;
}

/// The first of [windowsTzEnvironmentCandidates] that's in [knownIds], or null.
String? windowsTzEnvironmentZoneId(String? tz, Set<String> knownIds) {
  for (var candidate in windowsTzEnvironmentCandidates(tz)) {
    if (knownIds.contains(candidate)) return candidate;
  }
  return null;
}

// C:\..., C:/..., \\server\share\... or /...
bool _isAbsolute(String path) =>
    RegExp(r'^([A-Za-z]:[\\/]|[\\/])').hasMatch(path);
