import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> arguments) async {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  final log = Logger('main');

  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption('output', defaultsTo: 'tzdb.bin')
    ..addOption('zoneinfo', defaultsTo: 'tool/tzdb_compiler/tmp_data/zoneinfo');
  final args = parser.parse(arguments);

  final zoneinfoPath = args['zoneinfo'] as String?;
  if (zoneinfoPath == null) {
    print('Usage:\n${parser.usage}');
    exit(1);
  }

  final tzifData = File(zoneinfoPath + '/Europe/Berlin').readAsBytesSync();

  final tzif = TZifFile.fromBytes(tzifData);

  print("Done!");
}

/// The 44 byte header of a TZif file.
class TZifHeader {
  /// The magic four-byte ASCII sequence “TZif” identifies the file as a timezone information file.
  final String magic;

  /// A byte identifying the version of the file's format (as of 2021, either an ASCII NUL, “2”, “3”, or “4”).
  final int version;

  /// The number of UT/local indicators stored in the file. (UT is Universal Time.)
  final int ttisutcnt;

  /// The number of standard/wall indicators stored in the file.
  final int ttisstdcnt;

  /// The number of leap seconds for which data entries are stored in the file.
  final int leapcnt;

  /// The number of transition times for which data entries are stored in the file.
  final int timecnt;

  /// The number of local time types for which data entries are stored in the file (must not be zero).
  final int typecnt;

  /// The number of bytes of time zone abbreviation strings stored in the file.
  final int charcnt;

  TZifHeader({
    required this.magic,
    required this.version,
    required this.ttisutcnt,
    required this.ttisstdcnt,
    required this.leapcnt,
    required this.timecnt,
    required this.typecnt,
    required this.charcnt,
  });

  /// Creates a [TzifHeader] from the given bytes.
  factory TZifHeader.fromBytes(Uint8List bytes) {
    final buffer = bytes.buffer.asByteData();
    int offset = 0;

    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    offset += 4;

    if (magic != 'TZif') {
      throw Exception('Invalid magic: $magic (expected "TZif")');
    }

    final version = buffer.getUint8(offset);
    offset += 16;

    final ttisutcnt = buffer.getUint32(offset);
    offset += 4;

    final ttisstdcnt = buffer.getUint32(offset);
    offset += 4;

    final leapcnt = buffer.getUint32(offset);
    offset += 4;

    final timecnt = buffer.getUint32(offset);
    offset += 4;

    final typecnt = buffer.getUint32(offset);
    offset += 4;

    final charcnt = buffer.getUint32(offset);
    offset += 4;

    return TZifHeader(
      magic: magic,
      version: version,
      ttisutcnt: ttisutcnt,
      ttisstdcnt: ttisstdcnt,
      leapcnt: leapcnt,
      timecnt: timecnt,
      typecnt: typecnt,
      charcnt: charcnt,
    );
  }
}

class TZifZone {
  final int utcOffset;
  final bool isDst;
  final int desigIdx;

  TZifZone(
      {required this.utcOffset, required this.isDst, required this.desigIdx});
}

class TZifLeapSecondEntry {
  /// When the leap second is inserted
  final int insertionAt;

  /// How many seconds (positive/negative) are inserted
  final int seconds;

  TZifLeapSecondEntry({required this.insertionAt, required this.seconds});
}

class TZifFile {
  final TZifHeader version1Header;
  final TZifHeader verion2Header;

  /// four/eight-byte signed integer values sorted in ascending order. These values are written in network byte order. Each is used as a transition time (as returned by time(2)) at which the rules for computing local time change.
  final List<int> transitionAt;

  /// one-byte unsigned integer values; each one but the last tells which of the different types of local time types described in the file is associated with the time period starting with the same-indexed transition time and continuing up to but not including the next transition time. (The last time type is present only for consistency checking with the proleptic TZ string described below.) These values serve as indices into the next field.
  final List<int> transitionZone;

  /// ttinfo entries
  final List<TZifZone> zones;

  /// bytes that represent time zone designations, which are null-terminated byte strings, each indexed by the tt_desigidx values mentioned above. The byte strings can overlap if one is a suffix of the other. The encoding of these strings is not specified.
  final Uint8List zoneDesignations;

  /// pairs of four-byte values, written in network byte order; the first value of each pair gives the nonnegative time (as returned by time(2)) at which a leap second occurs or at which the leap second table expires; the second is a signed integer specifying the correction, which is the total number of leap seconds to be applied during the time period starting at the given time
  final List<TZifLeapSecondEntry> leapSeconds;

  /// standard/wall indicators, each stored as a one-byte boolean; they tell whether the transition times associated with local time types were specified as standard time or local (wall clock) time.
  final List<bool> isStd;

  /// UT/local indicators, each stored as a one-byte boolean; they tell whether the transition times associated with local time types were specified as UT or local time. If a UT/local indicator is set, the corresponding standard/wall indicator must also be set.
  final List<bool> isUtc;

  final String prolepticTZString;

  TZifFile({
    required this.version1Header,
    required this.verion2Header,
    required this.transitionAt,
    required this.transitionZone,
    required this.zones,
    required this.zoneDesignations,
    required this.leapSeconds,
    required this.isStd,
    required this.isUtc,
    required this.prolepticTZString,
  });

  factory TZifFile.fromBytes(Uint8List bytes) {
    final buffer = bytes.buffer.asByteData();
    int offset = 0;

    // read version 1 header
    final version1Header = TZifHeader.fromBytes(bytes);
    offset += 44;

    if (version1Header.version < 0x32) {
      throw Exception(
          'Invalid version: ${version1Header.version} (expected >= x032)');
    }

    // skip directly to version 2 data
    offset += version1Header.timecnt * 4 +
        version1Header.timecnt +
        version1Header.typecnt * 6 +
        version1Header.charcnt +
        version1Header.leapcnt * 8 +
        version1Header.ttisstdcnt +
        version1Header.ttisutcnt;

    // read version 2 header
    final version2Header = TZifHeader.fromBytes(bytes.sublist(offset));
    offset += 44;

    if (version2Header.version < 0x32 &&
        version2Header.version != version1Header.version) {
      throw Exception(
          'Invalid version: ${version2Header.version} (expected >= 0x32)');
    }

    final transitionAt = List.generate(
      version2Header.timecnt,
      (index) => buffer.getInt64(offset + index * 8),
    );
    offset += version2Header.timecnt * 8;

    final transitionZone = List.generate(
      version2Header.timecnt,
      (index) => buffer.getUint8(offset + index),
    );
    offset += version2Header.timecnt;

    final zones = List.generate(
      version2Header.typecnt,
      (index) => TZifZone(
        utcOffset: buffer.getInt32(offset + index * 6),
        isDst: buffer.getUint8(offset + index * 6 + 4) == 1,
        desigIdx: buffer.getUint8(offset + index * 6 + 5),
      ),
    );
    offset += version2Header.typecnt * 6;

    final zoneDesignations = bytes.sublist(
      offset,
      offset + version2Header.charcnt,
    );
    offset += version2Header.charcnt;

    final leapSeconds = List.generate(
      version2Header.leapcnt,
      (index) => TZifLeapSecondEntry(
        insertionAt: buffer.getInt64(offset + index * 12),
        seconds: buffer.getInt32(offset + index * 12 + 8),
      ),
    );
    offset += version2Header.leapcnt * 12;

    final isStd = List.generate(
      version2Header.ttisstdcnt,
      (index) => buffer.getUint8(offset + index) == 1,
    );
    offset += version2Header.ttisstdcnt;

    final isUtc = List.generate(
      version2Header.ttisutcnt,
      (index) => buffer.getUint8(offset + index) == 1,
    );
    offset += version2Header.ttisutcnt;

    final prolepticTZStringLength = bytes.indexOf(0x0a, offset + 1);
    final prolepticTZString = String.fromCharCodes(
      bytes.sublist(offset + 1, prolepticTZStringLength),
    );

    return TZifFile(
      version1Header: version1Header,
      verion2Header: version2Header,
      transitionAt: transitionAt,
      transitionZone: transitionZone,
      zones: zones,
      zoneDesignations: zoneDesignations,
      leapSeconds: leapSeconds,
      isStd: isStd,
      isUtc: isUtc,
      prolepticTZString: prolepticTZString,
    );
  }
}
