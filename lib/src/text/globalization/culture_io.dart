// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'culture_native_loader.dart'
    if (dart.library.html) 'culture_web_loader.dart';

@internal
class CultureLoader {
  static Future<CultureLoader> loadAll() async {
    // This won't have any filenames in it.
    // It's just a dummy object that will also give [zoneIds] and [zoneIdExists] functionality
    var cultureIds = HashSet<String>();
    var cache = <String, Culture>{Culture.invariantId: Culture.invariant};

    final binary = Uint8List.fromList(await getCultureData(''));

    var reader = CultureReader(ByteData.view(
      binary.buffer,
      binary.offsetInBytes,
      binary.lengthInBytes,
    ));

    while (reader.isMore) {
      var zone = reader.readCulture();
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

@internal
class CultureJsonReader {
  CultureJsonReader();

  Culture readCulture(Map<String, dynamic> json) {
    var name = json["name"];
    var datetimeFormat = readDateTimeFormatInfo(json["date_time_format"]);
    return Culture(name, datetimeFormat);
  }

  DateTimeFormat readDateTimeFormatInfo(Map<String, dynamic> json) {
    return (DateTimeFormatBuilder()
          ..amDesignator = json["am_designator"]
          ..pmDesignator = json["pm_designator"]
          ..timeSeparator = json["time_separator"]
          ..dateSeparator = json["date_separator"]
          ..abbreviatedDayNames = json["abbreviated_day_names"] as List<String>
          ..dayNames = json["day_names"] as List<String>
          ..monthNames = json["month_names"] as List<String>
          ..abbreviatedMonthNames =
              json["abbreviated_month_names"] as List<String>
          ..monthGenitiveNames = json["month_genitive_names"] as List<String>
          ..abbreviatedMonthGenitiveNames =
              json["abbreviated_month_genitive_names"] as List<String>
          ..eraNames = json["era_names"] as List<String>
          ..calendar = CalendarType.values[json["calendar"]]
          ..fullDateTimePattern = json["full_date_time_pattern"]
          ..shortDatePattern = json["short_date_pattern"]
          ..longDatePattern = json["long_date_pattern"]
          ..shortTimePattern = json["short_time_pattern"]
          ..longTimePattern = json["long_time_pattern"])
        .Build();
  }
}

@internal
class CultureJsonWriter {
  CultureJsonWriter();

  Map<String, dynamic> writeCulture(Culture culture) {
    final retval = <String, dynamic>{
      "name": culture.name,
      "date_time_format": writeDateTimeFormatInfo(culture.dateTimeFormat),
    };

    return retval;
  }

  Map<String, dynamic> writeDateTimeFormatInfo(DateTimeFormat dateTimeFormat) {
    final retval = <String, dynamic>{
      "am_designator": dateTimeFormat.amDesignator,
      "pm_designator": dateTimeFormat.pmDesignator,
      "time_separator": dateTimeFormat.timeSeparator,
      "date_separator": dateTimeFormat.dateSeparator,
      "abbreviated_day_names": dateTimeFormat.abbreviatedDayNames,
      "day_names": dateTimeFormat.dayNames,
      "month_names": dateTimeFormat.monthNames,
      "abbreviated_month_names": dateTimeFormat.abbreviatedMonthNames,
      "month_genitive_names": dateTimeFormat.monthGenitiveNames,
      "abbreviated_month_genitive_names":
          dateTimeFormat.abbreviatedMonthGenitiveNames,
      "era_names": dateTimeFormat.eraNames,
      "calendar": dateTimeFormat.calendar.index,
      "full_date_time_pattern": dateTimeFormat.fullDateTimePattern,
      "short_date_pattern": dateTimeFormat.shortDatePattern,
      "long_date_pattern": dateTimeFormat.longDatePattern,
      "short_time_pattern": dateTimeFormat.shortTimePattern,
      "long_time_pattern": dateTimeFormat.longTimePattern,
    };

    return retval;
  }
}
