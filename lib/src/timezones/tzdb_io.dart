// Copyright (c) 2015, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// TimeZone db file.

import 'dart:collection';
import 'dart:convert' show ascii;
import 'dart:typed_data';

import 'package:time_machine2/src/platforms/platform_io.dart';
import 'package:time_machine2/src/time_machine_internal.dart';

import 'tzdb_location.dart';
import 'tzdb_location_database.dart';

/// Serialize TimeZone Database
List<int> tzdbSerialize(TzdbLocationDatabase db) {
  final locationsInBytes = <List<int>>[];
  var bufferLength = 0;

  for (final l in db.locations.values.toList()
    ..sort((l, r) => l.name.compareTo(r.name))) {
    List<int> b = _serializeLocation(l);
    locationsInBytes.add(b);
    bufferLength += 8 + b.length;
    bufferLength = _align(bufferLength, 8);
  }

  final r = Uint8List(bufferLength);
  final rb = r.buffer.asByteData();

  var offset = 0;
  for (final b in locationsInBytes) {
    var length = _align(b.length, 8);
    rb.setUint32(offset, length);
    r.setAll(offset + 8, b);
    offset += 8 + length;
  }

  return r;
}

/// Deserialize TimeZone Database
Iterable<TzdbLocation> tzdbDeserialize(List<int> rawData) sync* {
  final data = rawData is Uint8List ? rawData : Uint8List.fromList(rawData);
  final bdata = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);

  var offset = 0;
  while (offset < data.length) {
    final length = bdata.getUint32(offset);
    // u32 _pad;
    assert((length % 8) == 0);
    offset += 8;

    yield _deserializeLocation(
        data.buffer.asUint8List(data.offsetInBytes + offset, length));
    offset += length;
  }
}

Uint8List _serializeLocation(TzdbLocation location) {
  var offset = 0;

  final abbreviations = <String>[];
  final abbreviationsIndex = HashMap<String, int>();
  final zoneAbbreviationOffsets = <int>[];

  // The number of bytes of all abbreviations.
  var abbreviationsLength = 0;
  for (final z in location.zones) {
    final ai = abbreviationsIndex.putIfAbsent(z.abbreviation, () {
      final ret = abbreviations.length;
      abbreviationsLength += z.abbreviation.length + 1; // abbreviation + '\0'
      abbreviations.add(z.abbreviation);
      return ret;
    });

    zoneAbbreviationOffsets.add(ai);
  }

  final List<int> encName = ascii.encode(location.name);

  const nameOffset = 32;
  final nameLength = encName.length;
  final abbreviationsOffset = nameOffset + nameLength;
  final zonesOffset = _align(abbreviationsOffset + abbreviationsLength, 4);
  final zonesLength = location.zones.length;
  final transitionsOffset = _align(zonesOffset + zonesLength * 8, 8);
  final transitionsLength = location.transitionAt.length;

  final bufferLength = _align(transitionsOffset + transitionsLength * 9, 8);

  final result = Uint8List(bufferLength);
  final buffer = ByteData.view(result.buffer);

  // write header
  buffer.setUint32(0, nameOffset);
  buffer.setUint32(4, nameLength);
  buffer.setUint32(8, abbreviationsOffset);
  buffer.setUint32(12, abbreviationsLength);
  buffer.setUint32(16, zonesOffset);
  buffer.setUint32(20, zonesLength);
  buffer.setUint32(24, transitionsOffset);
  buffer.setUint32(28, transitionsLength);

  // write name
  offset = nameOffset;
  for (final c in encName) {
    buffer.setUint8(offset++, c);
  }

  // Write abbreviations.
  offset = abbreviationsOffset;
  for (final a in abbreviations) {
    for (final c in a.codeUnits) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint8(offset++, 0);
  }

  // write zones
  offset = zonesOffset;
  for (var i = 0; i < location.zones.length; i++) {
    final zone = location.zones[i];
    buffer.setInt32(offset, zone.offset ~/ 1000); // convert to sec
    buffer.setUint8(offset + 4, zone.isDst ? 1 : 0);
    buffer.setUint8(offset + 5, zoneAbbreviationOffsets[i]);
    offset += 8;
  }

  // write transitions
  offset = transitionsOffset;
  for (final tAt in location.transitionAt) {
    final t = (tAt / 1000).floorToDouble();
    buffer.setFloat64(offset, t.toDouble()); // convert to sec
    offset += 8;
  }

  for (final tZone in location.transitionZone) {
    buffer.setUint8(offset, tZone);
    offset += 1;
  }

  return result;
}

TzdbLocation _deserializeLocation(Uint8List data) {
  final bdata = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
  var offset = 0;

  // Header
  //
  //     struct {
  //       u32 nameOffset;
  //       u32 nameLength;
  //       u32 abbrsOffset;
  //       u32 abbrsLength;
  //       u32 zonesOffset;
  //       u32 zonesLength;
  //       u32 transitionsOffset;
  //       u32 transitionsLength;
  //     } header;
  final nameOffset = bdata.getUint32(0);
  final nameLength = bdata.getUint32(4);
  final abbreviationsOffset = bdata.getUint32(8);
  final abbreviationsLength = bdata.getUint32(12);
  final zonesOffset = bdata.getUint32(16);
  final zonesLength = bdata.getUint32(20);
  final transitionsOffset = bdata.getUint32(24);
  final transitionsLength = bdata.getUint32(28);

  final name = ascii.decode(
      data.buffer.asUint8List(data.offsetInBytes + nameOffset, nameLength));
  final abbreviations = <String>[];
  final zones = <TzdbTimeZone>[];
  final transitionAt = <int>[];
  final transitionZone = <int>[];

  // Abbreviations
  //
  // \0 separated strings
  offset = abbreviationsOffset;
  final abbreviationsEnd = abbreviationsOffset + abbreviationsLength;
  for (var i = abbreviationsOffset; i < abbreviationsEnd; i++) {
    if (data[i] == 0) {
      final abbreviation = ascii.decode(
          data.buffer.asUint8List(data.offsetInBytes + offset, i - offset));
      abbreviations.add(abbreviation);
      offset = i + 1;
    }
  }

  // TimeZones
  //
  //     struct {
  //       i32 offset; // in seconds
  //       u8 isDst;
  //       u8 abbrIndex;
  //       u8 _pad[2];
  //     } zones[zonesLength]; // at zoneOffset
  offset = zonesOffset;
  assert((offset % 4) == 0);
  for (var i = 0; i < zonesLength; i++) {
    final zoneOffset = bdata.getInt32(offset) * 1000; // convert to ms
    final zoneIsDst = bdata.getUint8(offset + 4);
    final zoneAbbreviationIndex = bdata.getUint8(offset + 5);
    offset += 8;
    zones.add(TzdbTimeZone(zoneOffset,
        isDst: zoneIsDst == 1,
        abbreviation: abbreviations[zoneAbbreviationIndex]));
  }

  // Transitions
  //
  //     f64 transitionAt[transitionsLength]; // in seconds
  //     u8 transitionZone[transitionLength]; // at (transitionsOffset + (transitionsLength * 8))
  offset = transitionsOffset;
  assert((offset % 8) == 0);
  for (var i = 0; i < transitionsLength; i++) {
    transitionAt.add(bdata.getFloat64(offset).toInt() * 1000); // convert to ms
    offset += 8;
  }

  for (var i = 0; i < transitionsLength; i++) {
    transitionZone.add(bdata.getUint8(offset));
    offset += 1;
  }

  return TzdbLocation(name, transitionAt, transitionZone, zones);
}

int _align(int offset, int boundary) {
  final i = offset % boundary;
  return i == 0 ? offset : offset + (boundary - i);
}

@internal
class TzdbIndex {
  static Future<TzdbIndex> load() async {
    var _jsonMap = await _loadIdMapping();

    // todo: Dart2.0: seek a more elegant mapping of <String, dynamic> to <String, String>
    var map = <String, String>{IDateTimeZone.utcId: ''};
    _jsonMap.forEach((key, value) {
      map[key] = value;
    });

    return TzdbIndex._(map);
  }

  // todo: if we swap to something supporting offset skipping around 'tzdb.bin' file, just fill the _binaryCache instead.
  static Future<TzdbIndex> loadAll() async {
    // This won't have any filenames in it.
    // It's just a dummy object that will also give [zoneIds] and [zoneIdExists] functionality
    var jsonMap = <String, String>{IDateTimeZone.utcId: ''};
    var cache = <String, DateTimeZone>{};

    var binary = await PlatformIO.local.getBinary('tzdb', 'tzdb.bin');
    var reader = DateTimeZoneReader(binary);

    while (reader.isMore) {
      var id = reader.readString();
      var zone = PrecalculatedDateTimeZone.read(reader, id);
      cache[id] = zone;
      jsonMap[id] = '';
    }

    // todo: this is a good thing to log? (todo: research whether it's ok for libraries in Dart to log)
    // print('Total ${cache.length} zones loaded');

    // todo: we might be able to just foward the _cache.keys instead?
    var index = TzdbIndex._(jsonMap);
    cache.forEach((id, zone) => index._cache[id] = zone);
    return index;
  }

  TzdbIndex._(this._zoneFilenames);

  static Future<Map<String, dynamic>> _loadIdMapping() async {
    var json = await PlatformIO.local.getJson('tzdb', 'tzdb.json');
    return json;
  }

  final Map<String, String> _zoneFilenames;
  final Map<String, DateTimeZone> _cache = {
    IDateTimeZone.utcId: DateTimeZone.utc
  };

  /// Holding place for binary, if it's loaded but not yet transformed into a [DateTimeZone]
  final Map<String, ByteData> _binaryCache = {};

  Iterable<String> get zoneIds => _zoneFilenames.keys;
  bool zoneIdExists(String zoneId) => _zoneFilenames.containsKey(zoneId);

  DateTimeZone _zoneFromBinary(ByteData binary) {
    var reader = DateTimeZoneReader(binary);
    // this should be the same as the index id
    var id = reader.readString();
    var zone = PrecalculatedDateTimeZone.read(reader, id);
    return zone;
  }

  Future<DateTimeZone> getTimeZone(String zoneId) async {
    var zone = getTimeZoneSync(zoneId);
    if (zone != null) return zone;

    var filename = _zoneFilenames[zoneId];
    if (filename == null)
      throw DateTimeZoneNotFoundError('$zoneId had no associated filename.');

    return _cache[zoneId] = _zoneFromBinary(
        await PlatformIO.local.getBinary('tzdb', '$filename.bin'));
  }

  DateTimeZone? getTimeZoneSync(String zoneId) {
    var zone = _cache[zoneId];
    if (zone != null) return zone;

    var binaryData = _binaryCache.remove(zoneId);
    if (binaryData == null) return null;

    return _cache[zoneId] = _zoneFromBinary(binaryData);
  }

  // Default to UTC if we fail to set a local [DateTimeZone]
  static String localId = IDateTimeZone.utcId; // => Platform.localeName;
}

abstract class DateTimeZoneType {
  static const int fixed = 1;
  static const int precalculated = 2;
}

@internal
abstract class IDateTimeZoneWriter {
  void writeZoneInterval(ZoneInterval zoneInterval);
  Future? close();
  void write7BitEncodedInt(int value);
  void writeBool(bool value);
  void writeInt32(int value);
  void writeInt64(int value);
  void writeOffsetSeconds(Offset value);
  void writeOffsetSeconds2(Offset value);
  void writeString(String value);
  void writeStringList(List<String> list);
  void writeUint8(int value);

  /// Writes the given dictionary of string to string to the stream.
  /// </summary>
  /// <param name='dictionary'>The <see cref="IDictionary{TKey,TValue}" /> to write.</param>
  void writeDictionary(Map<String, String> map);
}
