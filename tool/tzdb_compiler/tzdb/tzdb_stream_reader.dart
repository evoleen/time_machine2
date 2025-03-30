import 'dart:typed_data';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/tzdb_io.dart';
import 'package:time_machine2/src/utility/binary_writer.dart';
import 'package:time_machine2/time_machine2.dart';

import 'tzdb_stream_writer.dart';
import 'cldr_windows_zone_parser.dart';

/// Reads time zone data from a stream in nzd format.
/// This class reads the format written by TzdbStreamWriter.
class TzdbStreamReader {
  static const int _expectedVersion = 0;

  final ByteData _input;
  int _currentOffset = 0;
  late List<String> _stringPool;

  TzdbStreamReader(this._input);

  /// Reads a complete TZDB database from the stream
  TzdbResult read() {
    // Read and validate the version
    int version = _input.getUint8(_currentOffset++);
    if (version != _expectedVersion) {
      throw Exception('Expected version $_expectedVersion but got $version');
    }

    Map<TzdbStreamFieldId, List<int>> fields = _readFields();

    // First read the string pool, as we'll need it for everything else
    _stringPool = _readStringPool(fields[TzdbStreamFieldId.stringPool]!);

    // Now read the actual data
    var reader = DateTimeZoneReader(_input, _stringPool);

    // Read all time zones
    var timeZones = <String, DateTimeZone>{};
    var timeZoneField = fields[TzdbStreamFieldId.timeZone];
    if (timeZoneField != null) {
      reader.currentOffset = timeZoneField[0];
      while (reader.currentOffset < timeZoneField[0] + timeZoneField[1]) {
        var zone = _readTimeZone(reader);
        timeZones[zone.id] = zone;
      }
    }

    // Read version
    var versionField = fields[TzdbStreamFieldId.tzdbVersion]!;
    reader.currentOffset = versionField[0];
    String version = reader.readString();

    // Read zone aliases
    var aliasField = fields[TzdbStreamFieldId.tzdbIdMap]!;
    reader.currentOffset = aliasField[0];
    var aliases = reader.readDictionary();

    // Read Windows mappings
    var windowsZonesField =
        fields[TzdbStreamFieldId.cldrSupplementalWindowsZones]!;
    reader.currentOffset = windowsZonesField[0];
    var windowsZones = WindowsZones.read(reader);

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

    return TzdbResult(
      timeZones: timeZones,
      tzdbVersion: version,
      zoneAliases: aliases,
      windowsMapping: windowsZones,
      zoneLocations: zoneLocations,
      zone1970Locations: zone1970Locations,
    );
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
    int type = reader.readByte();

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

/// Holds the result of reading a TZDB file
class TzdbResult {
  final Map<String, DateTimeZone> timeZones;
  final String tzdbVersion;
  final Map<String, String> zoneAliases;
  final WindowsZones windowsMapping;
  final List<TzdbZoneLocation>? zoneLocations;
  final List<TzdbZone1970Location>? zone1970Locations;

  TzdbResult({
    required this.timeZones,
    required this.tzdbVersion,
    required this.zoneAliases,
    required this.windowsMapping,
    this.zoneLocations,
    this.zone1970Locations,
  });
}
