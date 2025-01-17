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
    ..addOption('zoneinfo', defaultsTo: 'tmp_data/zoneinfo');
  final args = parser.parse(arguments);

  final zoneinfoPath = args['zoneinfo'] as String?;
  if (zoneinfoPath == null) {
    print('Usage:\n${parser.usage}');
    exit(1);
  }
}

/// The 44 byte header of a TZif file.
class TzifHeader {
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

  TzifHeader({
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
  factory TzifHeader.fromBytes(Uint8List bytes) {
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

    return TzifHeader(
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

class TzifFile {
  final TzifHeader version1Header;
  final TzifHeader verion2Header;

  TzifFile({
    required this.version1Header,
    required this.verion2Header,
  });

  factory TzifFile.fromBytes(Uint8List bytes) {
    final version1Header = TzifHeader.fromBytes(bytes);
    final version2Header = TzifHeader.fromBytes(bytes.sublist(44, 88));

    return TzifFile(
      version1Header: version1Header,
      verion2Header: version2Header,
    );
  }
}
