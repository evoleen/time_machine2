import 'dart:typed_data';

import 'package:time_machine2/src/time_machine_internal.dart';

// from: https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/IO/TzdbStreamFieldId.cs

// Add FieldPosition class at the top level
class FieldPosition {
  final int offset;
  final int length;

  FieldPosition(this.offset, this.length);
}

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
  final BinaryReader _reader;
  late List<String> _stringPool;
  late Map<TzdbStreamFieldId, List<FieldPosition>> fields;

  late String tzdbVersion;
  late Map<String, DateTimeZone> timeZones;
  late Map<String, String> aliases;

  TzdbStreamReader(this._input) : _reader = BinaryReader(_input) {
    // Read and validate the version
    int version = _reader.readUint8();
    if (version != _expectedVersion) {
      throw Exception('Expected version $_expectedVersion but got $version');
    }

    // read fields and string pool
    fields = _readFields();
    _stringPool = _readStringPool();

    // Read version
    var versionFields = fields[TzdbStreamFieldId.tzdbVersion]!;
    if (versionFields.isEmpty) {
      throw Exception('Version field not found');
    }
    final dateTimeZoneReader = DateTimeZoneReader(_input, null);
    dateTimeZoneReader.currentOffset = versionFields[0].offset;
    tzdbVersion = dateTimeZoneReader.readString();

    // Now read the actual data
    var reader = DateTimeZoneReader(_input, _stringPool);

    // Read all time zones
    timeZones = <String, DateTimeZone>{};
    var timeZoneFields = fields[TzdbStreamFieldId.timeZone];
    if (timeZoneFields != null) {
      for (var field in timeZoneFields) {
        reader.currentOffset = field.offset;
        var zone = _readTimeZone(reader);
        timeZones[zone.id] = zone;
      }
    }

    // Read zone aliases
    var aliasFields = fields[TzdbStreamFieldId.tzdbIdMap]!;
    if (aliasFields.isEmpty) {
      throw Exception('Alias field not found');
    }
    reader.currentOffset = aliasFields[0].offset;
    aliases = reader.readDictionary();

    /*
    // Read Windows mappings
    var windowsZonesField =
        fields[TzdbStreamFieldId.cldrSupplementalWindowsZones]!;
    reader.currentOffset = windowsZonesField.offset;
    windowsZones = WindowsZones.read(reader);

    // Read zone locations if present
    List<TzdbZoneLocation>? zoneLocations;
    var zoneLocationsField = fields[TzdbStreamFieldId.zoneLocations];
    if (zoneLocationsField != null) {
      reader.currentOffset = zoneLocationsField.offset;
      int count = reader.readCount();
      zoneLocations = List<TzdbZoneLocation>.generate(
          count, (_) => TzdbZoneLocation.read(reader));
    }

    // Read 1970 zone locations if present
    List<TzdbZone1970Location>? zone1970Locations;
    var zone1970Field = fields[TzdbStreamFieldId.zone1970Locations];
    if (zone1970Field != null) {
      reader.currentOffset = zone1970Field.offset;
      int count = reader.readCount();
      zone1970Locations = List<TzdbZone1970Location>.generate(
          count, (_) => TzdbZone1970Location.read(reader));
    }
    */
  }

  Map<TzdbStreamFieldId, List<FieldPosition>> _readFields() {
    var fields = <TzdbStreamFieldId, List<FieldPosition>>{};

    while (_reader.hasMoreData) {
      int fieldId = _reader.readUint8();
      if (fieldId >= TzdbStreamFieldId.values.length) {
        continue; // Skip unknown fields
      }

      // Read the 7-bit encoded length
      int length = _reader.read7BitEncodedInt();

      // Get or create the list for this field ID
      var fieldList = fields.putIfAbsent(
          TzdbStreamFieldId.values[fieldId], () => <FieldPosition>[]);

      // Add the new field position to the list
      fieldList.add(FieldPosition(_reader.currentOffset, length));

      // Skip the field data
      _reader.currentOffset += length;
    }
    return fields;
  }

  List<String> _readStringPool() {
    final reader = BinaryReader(_input);

    final stringPoolFields = fields[TzdbStreamFieldId.stringPool];
    if (stringPoolFields == null || stringPoolFields.isEmpty) {
      throw Exception('String pool not found');
    }

    reader.currentOffset = stringPoolFields[0].offset;
    int count = reader.read7BitEncodedInt();

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
