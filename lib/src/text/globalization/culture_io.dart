// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';

import 'package:archive/archive.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/platforms/platform_io.dart';

@internal
class CultureLoader {
  static Future<CultureLoader> loadAll() async {
    // This won't have any filenames in it.
    // It's just a dummy object that will also give [zoneIds] and [zoneIdExists] functionality
    var cultureIds = HashSet<String>();
    var cache = <String, Culture>{Culture.invariantId: Culture.invariant};

    const zipDecoder = GZipDecoder();

    var binary = zipDecoder.decodeBytes(
        (await PlatformIO.local.getBinary('cultures', 'cultures.bin'))
            .buffer
            .asUint8List());

    var reader = CultureReader(ByteData.view(
      binary.buffer,
      binary.offsetInBytes,
      binary.lengthInBytes,
    ));

    while (reader.isMore) {
      var zone = reader.readCulture();
      print(zone.name);
      cache[zone.name] = zone;
      cultureIds.add(zone.name);
    }

    var index = CultureLoader._(cultureIds);
    cache.forEach((id, zone) => index._cache[id] = zone);
    return index;
  }

  CultureLoader._(this._cultureIds);

  final HashSet<String> _cultureIds;
  final Map<String, Culture> _cache = {};

  Iterable<String> get cultureIds => _cultureIds;
  bool zoneIdExists(String zoneId) => _cultureIds.contains(zoneId);

  Future<Culture?> getCulture(String? cultureId) async {
    if (cultureId == null) return null;

    if (_cache.containsKey(cultureId)) {
      return _cache[cultureId];
    }

    if (_cache.containsKey(cultureId.split('-').first)) {
      return _cache[cultureId.split('-').first];
    }

    return null;
  }

  // static String get locale => Platform.localeName;
}

@internal
class CultureReader extends BinaryReader {
  CultureReader(ByteData binary, [int offset = 0]) : super(binary, offset);

  Culture readCulture() {
    var name = readString();
    var datetimeFormat = readDateTimeFormatInfo();
    return Culture(name, datetimeFormat);
  }

  DateTimeFormat readDateTimeFormatInfo() {
    return (DateTimeFormatBuilder()
          ..amDesignator = readString()
          ..pmDesignator = readString()
          ..timeSeparator = readString()
          ..dateSeparator = readString()
          ..abbreviatedDayNames = readStringList()
          ..dayNames = readStringList()
          ..monthNames = readStringList()
          ..abbreviatedMonthNames = readStringList()
          ..monthGenitiveNames = readStringList()
          ..abbreviatedMonthGenitiveNames = readStringList()
          ..eraNames = readStringList()
          ..calendar = CalendarType.values[read7BitEncodedInt()]
          ..fullDateTimePattern = readString()
          ..shortDatePattern = readString()
          ..longDatePattern = readString()
          ..shortTimePattern = readString()
          ..longTimePattern = readString())
        .Build();
  }
}
