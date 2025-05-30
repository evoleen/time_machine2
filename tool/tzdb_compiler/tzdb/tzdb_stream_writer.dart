import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/tzdb_stream_reader.dart';
import 'package:time_machine2/src/utility/binary_writer.dart';
import 'package:time_machine2/time_machine2.dart';

import 'package:time_machine2/src/timezones/datetimezone_writer.dart';

import 'cldr_windows_zone_parser.dart';
import 'tzdb_database.dart';

/// Writes time zone data to a stream in nzd format.
///
/// <para>The file format consists of four bytes indicating the file format version/type (mostly for
/// future expansion), followed by a number of fields. Each field is identified by a <see cref='TzdbStreamFieldId'/>.
/// The fields are always written in order, and the format of a field consists of its field ID, a 7-bit-encoded
/// integer with the size of the data, and then the data itself.
///
/// The version number does not need to be increased if new fields are added, as the reader will simply ignore
/// unknown fields. It only needs to be increased for incompatible changes such as a different time zone format,
/// or if old fields are removed.
// todo: internal
class TzdbStreamWriter {
  static const int _version = 0;

  void write(
      TzdbDatabase database,
      WindowsZones cldrWindowsZones,
      Map<String, String> additionalWindowsNameToIdMappings,
      BinaryWriter stream) {
    _FieldCollection fields = _FieldCollection();

    var zones = database.generateDateTimeZones().toList();
    var stringPool = _createOptimizedStringPool(zones, database.zoneLocations,
        database.zone1970Locations, cldrWindowsZones);

    // First assemble the fields (writing to the string pool as we go)
    for (var zone in zones) {
      var zoneField = fields.addField(TzdbStreamFieldId.timeZone, stringPool);
      _writeZone(zone, zoneField.writer);
    }

    fields
        .addField(TzdbStreamFieldId.tzdbVersion, null)
        .writer
        .writeString(database.version);

    // Normalize the aliases
    var timeZoneMap = <String, String>{};
    for (var key in database.aliases.keys) {
      var value = database.aliases[key]!;
      while (database.aliases.containsKey(value)) {
        value = database.aliases[value]!;
      }
      timeZoneMap[key] = value;
    }

    fields
        .addField(TzdbStreamFieldId.tzdbIdMap, stringPool)
        .writer
        .writeDictionary(timeZoneMap);

    // Windows mappings
    cldrWindowsZones.write(fields
        .addField(TzdbStreamFieldId.cldrSupplementalWindowsZones, stringPool)
        .writer);

    // Additional names from Windows Standard Name to canonical ID, used in Noda Time 1.x BclDateTimeZone, when we
    // didn't have access to TimeZoneInfo.Id.
    /*
    fields
        .addField(TzdbStreamFieldId.windowsAdditionalStandardNameToIdMapping,
            stringPool)
        .writer
        .writeDictionary(Map.fromEntries(additionalWindowsNameToIdMappings
            .entries
            .toList()
            .map((entry) => MapEntry(
                entry.key, cldrWindowsZones.primaryMapping[entry.value]!))));
    */

    // Zone locations, if any.
    var zoneLocations = database.zoneLocations;
    if (zoneLocations != null) {
      var field = fields.addField(TzdbStreamFieldId.zoneLocations, stringPool);
      field.writer.writeCount(zoneLocations.length);
      for (var zoneLocation in zoneLocations) {
        zoneLocation.write(field.writer);
      }
    }

    // Zone 1970 locations, if any.
    var zone1970Locations = database.zone1970Locations;
    if (zone1970Locations != null) {
      var field =
          fields.addField(TzdbStreamFieldId.zone1970Locations, stringPool);
      field.writer.writeCount(zone1970Locations.length);
      for (var zoneLocation in zone1970Locations) {
        zoneLocation.write(field.writer);
      }
    }

    var stringPoolField = fields.addField(TzdbStreamFieldId.stringPool, null);
    stringPoolField.writer.writeCount(stringPool.length);
    for (String value in stringPool) {
      stringPoolField.writer.writeString(value);
    }

    // Now write all the fields out, in the right order.
    // new BinaryWriter(stream).writeUint8(_version);
    stream.writeUint8(_version);
    fields.writeTo(stream);
  }

  static void _writeZone(DateTimeZone zone, IDateTimeZoneWriter writer) {
    writer.writeString(zone.id);
    // For cached zones, simply uncache first.
    if (zone is CachedDateTimeZone) {
      zone = zone.timeZone;
    }
    if (zone is FixedDateTimeZone) {
      writer.writeByte(DateTimeZoneType.fixed.byteValue);
      zone.write(writer);
    } else {
      var precalculatedZone = zone as PrecalculatedDateTimeZone?;
      if (precalculatedZone != null) {
        writer.writeByte(DateTimeZoneType.precalculated.byteValue);
        precalculatedZone.write(writer);
      } else {
        throw ArgumentError(
            'Unserializable DateTimeZone type ${zone.runtimeType}');
      }
    }
  }

  /// <summary>
  /// Creates a string pool which contains the most commonly-used strings within the given set
  /// of zones first. This will allow them to be more efficiently represented when we write them out for real.
  /// </summary>
  static List<String> _createOptimizedStringPool(
      Iterable<DateTimeZone> zones,
      Iterable<TzdbZoneLocation>? zoneLocations,
      Iterable<TzdbZone1970Location>? zone1970Locations,
      WindowsZones cldrWindowsZones) {
    var optimizingWriter = _StringPoolOptimizingFakeWriter();
    for (var zone in zones) {
      optimizingWriter.writeString(zone.id);
      _writeZone(zone, optimizingWriter);
    }
    if (zoneLocations != null) {
      for (var location in zoneLocations) {
        location.write(optimizingWriter);
      }
    }
    if (zone1970Locations != null) {
      for (var location in zone1970Locations) {
        location.write(optimizingWriter);
      }
    }
    cldrWindowsZones.write(optimizingWriter);
    return optimizingWriter.createPool();
  }
}

/// <summary>
/// Writer which only cares about strings. It builds a complete list of all strings written for the given
/// zones, then creates a distinct list in most-prevalent-first order. This allows the most frequently-written
/// strings to be the ones which are cheapest to write.
/// </summary>
class _StringPoolOptimizingFakeWriter implements IDateTimeZoneWriter {
  final List<String> _allStrings = <String>[];

  List<String> createPool() {
    // _allStrings.GroupBy(x => x);
    var map = <String, int>{};

    _allStrings.forEach((text) {
      if (map.containsKey(text))
        map[text] = map[text]! + 1;
      else
        map[text] = 1;
    });

    // .OrderByDescending((g) => g.Count())
    var items = map.entries.toList();
    items.sort((a, b) => a.value.compareTo(b.value));

    // .Select((g) => g.Key).ToList()
    return items.map((i) => i.key).toList();
  }

  @override
  void writeString(String value) {
    _allStrings.add(value);
  }

  @override
  void writeMilliseconds(int millis) {}
  @override
  void writeOffset(Offset offset) {}
  @override
  void writeCount(int count) {}
  @override
  void writeByte(int value) {}
  @override
  void writeSignedCount(int count) {}
  @override
  void writeZoneIntervalTransition(Instant? previous, Instant value) {}

  @override
  void writeDictionary(Map<String, String> dictionary) {
    dictionary.forEach((key, value) {
      writeString(key);
      writeString(value);
    });
  }
}

/// <summary>
/// The data for a field, including the field number itself.
/// </summary>
class _FieldData {
  final List<int> stream;

  _FieldData._(this.fieldId, this.stream, this.writer);

  factory _FieldData(TzdbStreamFieldId fieldId, List<String>? stringPool) {
    var stream = List<int>.empty(growable: true);
    // var writer = DateTimeZoneWriter(BinaryWriter(stream), stringPool);
    var writer = DateTimeZoneWriter(BinaryWriter(stream), stringPool);
    return _FieldData._(fieldId, stream, writer);
  }

  final IDateTimeZoneWriter writer;
  final TzdbStreamFieldId fieldId;

  void writeTo(BinaryWriter output) {
    output.writeUint8(fieldId.index);
    int length = stream.length;
    // We've got a 7-bit-encoding routine... might as well use it.
    output.write7BitEncodedInt(length);
    // new DateTimeZoneWriter(output).WriteCount(length);
    stream.forEach(output.writeUint8);
  }
}

class _FieldCollection {
  final List<_FieldData> fields = [];

  _FieldData addField(TzdbStreamFieldId fieldNumber, List<String>? stringPool) {
    var ret = _FieldData(fieldNumber, stringPool);
    fields.add(ret);
    return ret;
  }

  void writeTo(BinaryWriter stream) {
    for (var field in fields
      ..sort((a, b) => a.fieldId.index.compareTo(b.fieldId.index))) {
      field.writeTo(stream);
    }
  }
}
