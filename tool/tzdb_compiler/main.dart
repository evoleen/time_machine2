// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'package:collection/collection.dart' show mergeSort;

import 'package:path/path.dart' as path;
import 'package:time_machine2/src/utility/binary_writer.dart';

import 'compiler_options.dart';
import 'tzdb/named_id_mapping_support.dart';
import 'tzdb/tzdb_stream_writer.dart';
import 'tzdb/tzdb_zone_info_compiler.dart';
import 'tzdb/cldr_windows_zone_parser.dart';

Future<void> main(List<String> args) async {
  CompilerOptions options = CompilerOptions(args);

  // https://nodatime.org/tzdb/latest.txt --> https://nodatime.org/tzdb/tzdb2018g.nzd
  // https://data.iana.org/time-zones/releases/tzdata2018g.tar.gz
  var tzdbCompiler = TzdbZoneInfoCompiler();
  var tzdb = await tzdbCompiler
      .compile('https://data.iana.org/time-zones/releases/tzdata2026a.tar.gz');
  tzdb.logCounts();

  var windowsZones = LoadWindowsZones(options, tzdb.version);
  if (options.windowsOverride != null) {
    var overrideFile =
        CldrWindowsZonesParser.parseFile(options.windowsOverride!);
    windowsZones = MergeWindowsZones(windowsZones, overrideFile);
  }
  LogWindowsZonesSummary(windowsZones);

  var writer = TzdbStreamWriter();
  final output = List<int>.empty(growable: true);

  var stream = BinaryWriter(output);
  writer.write(
      tzdb, windowsZones, NameIdMappingSupport.StandardNameToIdMap, stream);

  final fileName = path.setExtension(options.outputFileName!, '.nzd');
  File(fileName).writeAsBytesSync(output);

  final compressedFileName =
      path.setExtension(options.outputFileName!, '.nzd.xz');
  final result = Process.runSync(
      'xz',
      [
        '--compress', // make file smaller
        '--force', // overwrite existing compressed file
        '--extreme', // make file even smaller
        fileName,
      ],
      runInShell: true);

  print(result.stdout);
  print(result.stderr);

  if (result.exitCode != 0) {
    print('Error: xz compression failed');
    print(result.stderr);
    exit(1);
  }

  /*
  // The code below can be used to verify that the generated file is valid.
  // To use the section below, add the '--keep' flag to the xz command above.
  print(
      'Compression successful, trying to read the file again as sanity check...');

  final readStream = File(fileName).readAsBytesSync().buffer.asByteData();
  final reader = TzdbStreamReader(readStream);
  print('Read back ${reader.timeZones.length} time zones');
  */

  // Create the destination directory if it doesn't exist
  Directory('lib/data').createSync(recursive: true);

  // Move the compressed file to the destination
  File(compressedFileName).copySync('lib/data/tzdb/tzdb.bin');
  File(compressedFileName).deleteSync();

  // Generate Dart file with embedded TZDB data
  final tzdbBytes = File('lib/data/tzdb/tzdb.bin').readAsBytesSync();
  final dartCode = generateDartFile(
    name: 'tzdb',
    data: bytesAsString(tzdbBytes),
  );
  File('lib/data/tzdb/tzdb.dart').writeAsStringSync(dartCode);
}

String bytesAsString(Uint8List bytes) {
  assert(bytes.length.isEven);
  return bytes.buffer
      .asUint16List()
      .map((u) => '\\u${u.toRadixString(16).padLeft(4, '0')}')
      .join();
}

String generateDartFile({required String name, required String data}) =>
    '''// This is a generated file. Do not edit.
import 'dart:typed_data';

import 'package:time_machine2/src/platforms/dart_native_io.dart';

void registerTzdbAsset() {
  TimeMachineIO.registerAsset('tzdb', 'tzdb.bin',
      ByteData.sublistView(Uint16List.fromList(_embeddedData.codeUnits)));
}

const _embeddedData =
    '$data';
''';

/// <summary>
/// Loads the best windows zones file based on the options. If the WindowsMapping option is
/// just a straight file, that's used. If it's a directory, this method loads all the XML files
/// in the directory (expecting them all to be mapping files) and then picks the best one based
/// on the version of TZDB we're targeting - basically, the most recent one before or equal to the
/// target version.
/// </summary>
WindowsZones LoadWindowsZones(
    CompilerOptions options, String targetTzdbVersion) {
  var mappingPath = options.windowsMapping;
  if (mappingPath == null) {
    throw Exception('No mappingPath was provided');
  }
  if (File(mappingPath).existsSync()) {
    return CldrWindowsZonesParser.parseFile(mappingPath);
  }
  if (!Directory(mappingPath).existsSync()) {
    throw Exception(
        '$mappingPath does not exist as either a file or a directory');
  }
  var xmlFiles = Directory(mappingPath)
      .listSync()
      .where((f) => f is File && f.path.endsWith('.xml'))
      .toList();
  if (xmlFiles.isEmpty) {
    throw Exception('$mappingPath does not contain any XML files');
  }
  // Sort by TZDB version, then by file name. CLDR doesn't always bump the
  // TZDB version, so the file name (e.g. windowsZones-49.xml) breaks ties.
  xmlFiles.sort((a, b) => a.path.compareTo(b.path));
  var allFiles = xmlFiles
      .map((file) => (
            name: path.basename(file.path),
            zones: CldrWindowsZonesParser.parseFile(file.path)
          ))
      .toList();
  mergeSort(allFiles,
      compare: (a, b) => a.zones.tzdbVersion.compareTo(b.zones.tzdbVersion));

  var versions =
      allFiles.map((f) => '${f.name} (TZDB ${f.zones.tzdbVersion})').join(', ');

  var potentiallyBestFiles = allFiles
      .where((f) => f.zones.tzdbVersion.compareTo(targetTzdbVersion) <= 0);
  if (potentiallyBestFiles.isEmpty) {
    throw Exception(
        'No zones files suitable for version $targetTzdbVersion. Found: [$versions]');
  }
  // The files are sorted by TZDB version, so the last suitable one is the most recent.
  var bestFile = potentiallyBestFiles.last;

  print('Picked Windows Zones from ${bestFile.name} out of [$versions] '
      'as best match for TZDB $targetTzdbVersion');
  return bestFile.zones;
}

void LogWindowsZonesSummary(WindowsZones windowsZones) {
  print('Windows Zones:');
  print('  Version: ${windowsZones.version}');
  print('  TZDB version: ${windowsZones.tzdbVersion}');
  print('  Windows version: ${windowsZones.windowsVersion}');
  print('  ${windowsZones.mapZones.length} MapZones');
  print('  ${windowsZones.primaryMapping.length} primary mappings');
}

IOSink createOutputStream(CompilerOptions options) {
  // If we don't have an actual file, just write to an empty stream.
  // That way, while debugging, we still get to see all the data written etc.
  if (options.outputFileName == null) {
    return stdout; // new MemoryStream();
  }

  String file = path.setExtension(options.outputFileName!, 'nzd');
  return File(file).openWrite();
}

/// Merge two WindowsZones objects together. The result has versions present in override,
/// but falling back to the original for versions absent in the override. The set of MapZones
/// in the result is the union of those in the original and override, but any ID/Territory
/// pair present in both results in the override taking priority, unless the override has an
/// empty 'type' entry, in which case the entry is removed entirely.
///
/// While this method could reasonably be in WindowsZones class, it's only needed in
/// TzdbCompiler - and here is as good a place as any.
///
/// The resulting MapZones will be ordered by Windows ID followed by territory.
/// </summary>
/// <param name='windowsZones'>The original WindowsZones</param>
/// <param name='overrideFile'>The WindowsZones to override entries in the original</param>
/// <returns>A merged zones object.</returns>
WindowsZones MergeWindowsZones(
    WindowsZones originalZones, WindowsZones overrideZones) {
  var version = overrideZones.version == ''
      ? originalZones.version
      : overrideZones.version;
  var tzdbVersion = overrideZones.tzdbVersion == ''
      ? originalZones.tzdbVersion
      : overrideZones.tzdbVersion;
  var windowsVersion = overrideZones.windowsVersion == ''
      ? originalZones.windowsVersion
      : overrideZones.windowsVersion;

  // Work everything out using dictionaries, and then sort.
  // Records compare by value, so (Windows ID, territory) works as a key.
  var mapZones = <(String, String), MapZone>{
    for (var mz in originalZones.mapZones) (mz.windowsId, mz.territory): mz
  };

  for (var overrideMapZone in overrideZones.mapZones) {
    var key = (overrideMapZone.windowsId, overrideMapZone.territory);
    if (overrideMapZone.tzdbIds.isEmpty) {
      mapZones.remove(key);
    } else {
      mapZones[key] = overrideMapZone;
    }
  }

  var mapZoneList = (mapZones.entries.toList()
        ..sort((a, b) {
          // Order by Windows ID, then by territory.
          var cmp = a.key.$1.compareTo(b.key.$1);
          return cmp != 0 ? cmp : a.key.$2.compareTo(b.key.$2);
        }))
      .map((entry) => entry.value)
      .toList();

  return WindowsZones(version, tzdbVersion, windowsVersion, mapZoneList);
}
