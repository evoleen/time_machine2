// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/platforms/unix_time_zone.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:universal_io/io.dart' as io;

import 'system_time_zone_backend.dart';
import 'tzif.dart';

/// Linux, macOS, iOS and other Unix-like systems: the compiled TZif files in
/// the zoneinfo directory (`$TZDIR`, or `/usr/share/zoneinfo`), which is
/// what .NET's `TimeZoneInfo` reads on these platforms too.
///
/// * IDs are the paths of the TZif files relative to the directory (e.g.
///   'Europe/London'), excluding the `posix/` and `right/` trees and
///   `localtime`, `posixrules` and `Factory`. Links are followed, so
///   aliases are included.
/// * Zones are built by [tzifToDateTimeZone].
class TzifDirectoryBackend implements SystemTimeZoneBackend {
  static const _excludedTopLevel = {
    'posix',
    'right',
    'localtime',
    'posixrules',
    'Factory',
  };

  /// The zoneinfo directory, with a trailing slash.
  final String directory;
  List<String>? _ids;
  Set<String>? _idSet;

  TzifDirectoryBackend(String directory)
      : directory = directory.endsWith('/') ? directory : '$directory/';

  /// The backend for this system's zoneinfo directory.
  static TzifDirectoryBackend create() =>
      TzifDirectoryBackend(timeZoneDirectory(_environment('TZDIR')));

  static String? _environment(String name) {
    try {
      return io.Platform.environment[name];
    } catch (_) {
      return null;
    }
  }

  @override
  String get description =>
      'TZif (${directory.substring(0, directory.length - 1)})';

  @override
  bool get isSupported => getIds().isNotEmpty;

  @override
  String? get dataVersion {
    // tzdata.zi starts with e.g. '# version 2025b'; macOS has +VERSION.
    try {
      var zi = io.File('${directory}tzdata.zi');
      if (zi.existsSync()) {
        for (var line in zi.readAsLinesSync().take(5)) {
          var match = RegExp(r'^#\s*version\s+(\S+)').firstMatch(line);
          if (match != null) return match.group(1);
        }
      }
      var version = io.File('$directory+VERSION');
      if (version.existsSync()) {
        var text = version.readAsStringSync().trim();
        if (text.isNotEmpty) return text;
      }
    } catch (_) {
      // Unreadable; no version.
    }
    return null;
  }

  @override
  List<String> getIds() => _ids ??= _scan();

  @override
  DateTimeZone? loadZone(String id) {
    if (!(_idSet ??= getIds().toSet()).contains(id)) return null;
    try {
      var bytes = io.File('$directory$id').readAsBytesSync();
      return tzifToDateTimeZone(id, parseTzif(bytes));
    } on io.FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  String? get systemDefaultId {
    var ids = getIds();
    if (ids.isEmpty) return null;
    return readUnixTimeZoneId(_canonicalFirst(ids));
  }

  /// Orders [ids] with the canonical zones first (from tzdata.zi, or failing
  /// that zone1970.tab and zone.tab), so that when the local time zone is
  /// found by comparing file contents, a canonical ID wins over its links.
  List<String> _canonicalFirst(List<String> ids) {
    var canonical = <String>{};
    try {
      var zi = io.File('${directory}tzdata.zi');
      if (zi.existsSync()) {
        for (var line in zi.readAsLinesSync()) {
          if (line.startsWith('Z ')) {
            var parts = line.split(' ');
            if (parts.length > 1) canonical.add(parts[1]);
          }
        }
      }
      if (canonical.isEmpty) {
        for (var name in ['zone1970.tab', 'zone.tab']) {
          var tab = io.File('$directory$name');
          if (!tab.existsSync()) continue;
          for (var line in tab.readAsLinesSync()) {
            if (line.startsWith('#')) continue;
            var parts = line.split('\t');
            if (parts.length > 2) canonical.add(parts[2]);
          }
        }
      }
    } catch (_) {
      // Fall back to alphabetical order.
    }
    return [
      ...ids.where(canonical.contains),
      ...ids.where((id) => !canonical.contains(id)),
    ];
  }

  List<String> _scan() {
    var ids = <String>[];
    try {
      var root = io.Directory(directory);
      if (!root.existsSync()) return ids;
      _walk(root, '', <String>[], ids);
    } catch (_) {
      // Treat an unreadable directory as having no zones.
    }
    ids.sort();
    return ids;
  }

  void _walk(io.Directory dir, String prefix, List<String> ancestors,
      List<String> ids) {
    String resolved;
    List<io.FileSystemEntity> entries;
    try {
      resolved = dir.resolveSymbolicLinksSync();
      // A symlink back to an ancestor (e.g. posix -> .) would loop.
      if (ancestors.contains(resolved)) return;
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      return;
    }
    var path = [...ancestors, resolved];
    var dirPath = dir.path;
    for (var entry in entries) {
      var name = entry.path.substring(dirPath.length);
      while (name.startsWith('/') || name.startsWith(r'\')) {
        name = name.substring(1);
      }
      if (name.isEmpty || name.startsWith('.')) continue;
      if (prefix.isEmpty && _excludedTopLevel.contains(name)) continue;
      var id = '$prefix$name';
      try {
        var type = io.FileSystemEntity.typeSync(entry.path);
        if (type == io.FileSystemEntityType.directory) {
          _walk(io.Directory(entry.path), '$id/', path, ids);
        } else if (type == io.FileSystemEntityType.file &&
            _startsWithTzifMagic(entry.path)) {
          ids.add(id);
        }
      } catch (_) {
        // Skip entries we can't read.
      }
    }
  }

  static bool _startsWithTzifMagic(String path) {
    var file = io.File(path).openSync();
    try {
      return hasTzifMagic(file.readSync(4));
    } finally {
      file.closeSync();
    }
  }
}
