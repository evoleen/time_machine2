import 'dart:typed_data';

import 'package:time_machine2/src/time_machine_internal.dart';

// from: https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/IO/TzdbStreamFieldId.cs

/// Enumeration of the fields which can occur in a TZDB stream file.
/// This enables the file to be self-describing to a reasonable extent.
enum TzdbStreamFieldId {
  /// String pool. Format is: number of strings (WriteCount) followed by that many string values.
  /// The indexes into the resultant list are used for other strings in the file, in some fields.
  stringPool,

  /// Repeated field of time zones. Format is: zone ID, then zone as written by DateTimeZoneWriter.
  timeZone,

  /// Single field giving the version of the TZDB source data. A string value which does *not* use the string pool.
  tzdbVersion,

  /// Single field giving the mapping of ID to canonical ID, as written by DateTimeZoneWriter.WriteDictionary.
  tzdbIdMap,

  /// Single field containing mapping data as written by WindowsZones.Write.
  cldrSupplementalWindowsZones,

  /// Single field giving the mapping of Windows StandardName to TZDB canonical ID,
  /// for time zones where TimeZoneInfo.Id != TimeZoneInfo.StandardName,
  /// as written by DateTimeZoneWriter.WriteDictionary.
  windowsAdditionalStandardNameToIdMapping,

  /// Single field providing all zone locations. The format is simply a count, and then that many copies of
  /// TzdbZoneLocation data.
  zoneLocations,

  /// Single field providing all 'zone 1970' locations. The format is simply a count, and then that many copies of
  /// TzdbZone1970Location data. This field was introduced in Noda Time 2.0.
  zone1970Locations
}

enum DateTimeZoneType {
  fixed,
  precalculated;

  int get byteValue => index;

  factory DateTimeZoneType.fromByte(int value) {
    return DateTimeZoneType.values[value];
  }
}

/// Reads time zone data from a stream in nzd format.
/// This class reads the format written by TzdbStreamWriter. It follows a different
/// approach than the other stream reader classes and reads all stream data at
/// once in the constructor, then publishes the results as properties of the
/// class.
class TzdbStreamReader {
  static const int _expectedVersion = 0;

  final ByteData _input;
  int _currentOffset = 0;
  late List<String> _stringPool;
  late Map<TzdbStreamFieldId, List<int>> fields;

  late String tzdbVersion;
  late Map<String, DateTimeZone> timeZones;
  late Map<String, String> aliases;

  TzdbStreamReader(this._input) {
    // Read and validate the version
    int version = _input.getUint8(_currentOffset++);
    if (version != _expectedVersion) {
      throw Exception('Expected version $_expectedVersion but got $version');
    }

    // read fields and string pool
    fields = _readFields();
    _stringPool = _readStringPool(fields[TzdbStreamFieldId.stringPool]!);

    // Now read the actual data
    var reader = DateTimeZoneReader(_input, _stringPool);

    // Read version
    var versionField = fields[TzdbStreamFieldId.tzdbVersion]!;
    reader.currentOffset = versionField[0];
    tzdbVersion = reader.readString();

    // Read all time zones
    timeZones = <String, DateTimeZone>{};
    var timeZoneField = fields[TzdbStreamFieldId.timeZone];
    if (timeZoneField != null) {
      reader.currentOffset = timeZoneField[0];
      while (reader.currentOffset < timeZoneField[0] + timeZoneField[1]) {
        var zone = _readTimeZone(reader);
        timeZones[zone.id] = zone;
      }
    }

    // Read zone aliases
    var aliasField = fields[TzdbStreamFieldId.tzdbIdMap]!;
    reader.currentOffset = aliasField[0];
    aliases = reader.readDictionary();

    /*
    // Read Windows mappings
    var windowsZonesField =
        fields[TzdbStreamFieldId.cldrSupplementalWindowsZones]!;
    reader.currentOffset = windowsZonesField[0];
    windowsZones = WindowsZones.read(reader);

    // Read zone locations if present
    List<TzdbZoneLocation>? zoneLocations;
    var zoneLocationsField = fields[TzdbStreamFieldId.zoneLocations];
    if (zoneLocationsField != null) {
      reader.currentOffset = zoneLocationsField[0];
      int count = reader.readCount();
      zoneLocations = List<TzdbZoneLocation>.generate(
          count, (_) => TzdbZoneLocation.read(reader));
    }

    // Read 1970 zone locations if present
    List<TzdbZone1970Location>? zone1970Locations;
    var zone1970Field = fields[TzdbStreamFieldId.zone1970Locations];
    if (zone1970Field != null) {
      reader.currentOffset = zone1970Field[0];
      int count = reader.readCount();
      zone1970Locations = List<TzdbZone1970Location>.generate(
          count, (_) => TzdbZone1970Location.read(reader));
    }
    */
  }

  Map<TzdbStreamFieldId, List<int>> _readFields() {
    var fields = <TzdbStreamFieldId, List<int>>{};

    while (_currentOffset < _input.lengthInBytes) {
      int fieldId = _input.getInt8(_currentOffset++);
      if (fieldId >= TzdbStreamFieldId.values.length) {
        continue; // Skip unknown fields
      }

      // Read the 7-bit encoded length
      int length = 0;
      int shift = 0;
      while (true) {
        int nextByte = _input.getInt8(_currentOffset++);
        length |= (nextByte & 0x7f) << shift;
        if (nextByte < 0x80) break;
        shift += 7;
      }

      fields[TzdbStreamFieldId.values[fieldId]] = [_currentOffset, length];
      _currentOffset += length;
    }
    return fields;
  }

  List<String> _readStringPool(List<int> fieldInfo) {
    var reader = DateTimeZoneReader(_input, null);
    reader.currentOffset = fieldInfo[0];
    int count = reader.readCount();
    return List<String>.generate(count, (_) => reader.readString());
  }

  DateTimeZone _readTimeZone(DateTimeZoneReader reader) {
    String id = reader.readString();
    final type = DateTimeZoneType.fromByte(reader.readByte());

    switch (type) {
      case DateTimeZoneType.fixed:
        return FixedDateTimeZone.read(reader, id);
      case DateTimeZoneType.precalculated:
        return PrecalculatedDateTimeZone.read(reader, id);
      default:
        throw Exception('Unknown zone type: $type');
    }
  }
}
