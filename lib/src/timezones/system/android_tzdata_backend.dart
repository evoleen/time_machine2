// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine2/src/platforms/unix_time_zone.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:universal_io/io.dart' as io;

import 'system_time_zone_backend.dart';
import 'tzif.dart';

/// Android: the system tzdata bundle, which is what Android's own
/// `java.util.TimeZone` (and .NET on Android) read: TZif data for each zone,
/// concatenated with an index.
///
/// The bundle is the first of these that exists (the time zone APEX module,
/// then the legacy update location, then the system image's copy).
class AndroidTzdataBackend implements SystemTimeZoneBackend {
  static const List<String> bundlePaths = [
    '/apex/com.android.tzdata/etc/tz/tzdata',
    '/data/misc/zoneinfo/current/tzdata',
    '/system/usr/share/zoneinfo/tzdata',
  ];

  final String? path;
  final AndroidTzdataBundle? _bundle;

  AndroidTzdataBackend(this.path, this._bundle);

  /// The backend for this device's tzdata bundle.
  static SystemTimeZoneBackend create() {
    for (var path in bundlePaths) {
      try {
        var file = io.File(path);
        if (!file.existsSync()) continue;
        return AndroidTzdataBackend(
            path, AndroidTzdataBundle.parse(file.readAsBytesSync()));
      } catch (_) {
        // Unreadable or malformed; try the next location.
      }
    }
    return const UnsupportedSystemTimeZoneBackend('no Android tzdata bundle');
  }

  @override
  String get description => 'Android tzdata ($path)';

  @override
  bool get isSupported => _bundle != null && _bundle.ids.isNotEmpty;

  @override
  String? get dataVersion => _bundle?.version;

  @override
  List<String> getIds() => _bundle?.ids ?? const [];

  @override
  DateTimeZone? loadZone(String id) => _bundle?.loadZone(id);

  @override
  String? get systemDefaultId => readUnixTimeZoneId(getIds());
}

/// A parsed Android tzdata bundle:
///
/// * A 12-byte header: 'tzdata' + the 5-character TZDB version (e.g.
///   '2025b') + NUL.
/// * Big-endian int32 offsets of the index, the data and the final section
///   (formerly zone.tab).
/// * Index entries of 52 bytes each: a 40-byte NUL-padded zone ID, then
///   int32 start (relative to the data offset), int32 length, and an unused
///   int32 (formerly the raw offset).
/// * The zones' TZif data.
@internal
class AndroidTzdataBundle {
  final String version;
  final Uint8List _bytes;
  final int _dataOffset;
  final Map<String, (int, int)> _entries;

  /// The zone IDs, sorted.
  final List<String> ids;

  AndroidTzdataBundle._(
      this.version, this._bytes, this._dataOffset, this._entries, this.ids);

  /// Parses a bundle. Throws a [FormatException] if it's malformed.
  factory AndroidTzdataBundle.parse(Uint8List bytes) {
    if (bytes.length < 24 ||
        ascii.decode(bytes.sublist(0, 6), allowInvalid: true) != 'tzdata' ||
        bytes[11] != 0) {
      throw const FormatException('Not an Android tzdata bundle');
    }
    var version = ascii.decode(bytes.sublist(6, 11), allowInvalid: true);
    var data = ByteData.sublistView(bytes);
    var indexOffset = data.getInt32(12);
    var dataOffset = data.getInt32(16);
    if (indexOffset < 24 ||
        dataOffset < indexOffset ||
        dataOffset > bytes.length ||
        (dataOffset - indexOffset) % 52 != 0) {
      throw const FormatException('Bad Android tzdata offsets');
    }
    var entries = <String, (int, int)>{};
    for (var entry = indexOffset; entry < dataOffset; entry += 52) {
      var nameBytes = bytes.sublist(entry, entry + 40);
      var nameEnd = nameBytes.indexOf(0);
      var name = ascii.decode(
          nameEnd < 0 ? nameBytes : nameBytes.sublist(0, nameEnd),
          allowInvalid: true);
      var start = data.getInt32(entry + 40);
      var length = data.getInt32(entry + 44);
      if (name.isEmpty ||
          start < 0 ||
          length <= 0 ||
          dataOffset + start + length > bytes.length) {
        throw FormatException('Bad Android tzdata entry for "$name"');
      }
      entries[name] = (start, length);
    }
    var ids = entries.keys.toList()..sort();
    return AndroidTzdataBundle._(version, bytes, dataOffset, entries, ids);
  }

  /// The TZif data for [id], or null if the bundle doesn't have it.
  Uint8List? tzifData(String id) {
    var entry = _entries[id];
    if (entry == null) return null;
    var (start, length) = entry;
    return Uint8List.sublistView(
        _bytes, _dataOffset + start, _dataOffset + start + length);
  }

  /// Builds the zone [id], or returns null if the bundle doesn't have it or
  /// its data is malformed.
  DateTimeZone? loadZone(String id) {
    var data = tzifData(id);
    if (data == null) return null;
    try {
      return tzifToDateTimeZone(id, parseTzif(data));
    } on FormatException {
      return null;
    }
  }
}
