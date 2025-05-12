// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:io';

// import 'package:time_machine/src/time_machine_internal.dart';
import 'package:path/path.dart' as path;
import 'package:time_machine2/src/timezones/tzdb_stream_reader.dart';
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
      .compile('https://data.iana.org/time-zones/releases/tzdata2025b.tar.gz');
  tzdb.logCounts();

  //final windowsZones = LoadWindowsZones(options, tzdb.version);
  final windowsZones = WindowsZones('0.0', '0.0', '0.0', const []);

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
        '--keep', // keep original file
        '--force', // overwrite existing compressed file
        '--extreme', // make file even smaller
        fileName,
      ],
      runInShell: true);

  print(result.stdout);
  print(result.stderr);

  final readStream = File(fileName).readAsBytesSync().buffer.asByteData();
  final reader = TzdbStreamReader(readStream);
  print(reader.timeZones.length);
}

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
  var allFiles = xmlFiles
      .map((file) => CldrWindowsZonesParser.parseFile(file.path))
      .toList()
    ..sort((a, b) => a.tzdbVersion.compareTo(b.tzdbVersion));

  var versions = allFiles.map((z) => z.tzdbVersion).join(', ');

  var potentiallyBestFiles = allFiles
      .where((zones) => (zones.tzdbVersion.compareTo(targetTzdbVersion)) <= 0);
  if (potentiallyBestFiles.isEmpty) {
    throw Exception(
        'No zones files suitable for version $targetTzdbVersion. Found versions targeting: [$versions]');
  }
  var bestFile = potentiallyBestFiles.first;

  print(
      "Picked Windows Zones with TZDB version ${bestFile.tzdbVersion} out of [$versions] as best match for $targetTzdbVersion");
  return bestFile;
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
  Map<Map<String, String>, MapZone> mapZones = {
    for (MapZone mz in originalZones.mapZones)
      {
        'windowsId': mz.windowsId,
        'territory': mz.territory,
      }: mz
  };

  for (var overrideMapZone in overrideZones.mapZones) {
    var key = {
      'windowsId': overrideMapZone.windowsId,
      'territory': overrideMapZone.territory
    };
    if (overrideMapZone.tzdbIds.isEmpty) {
      mapZones.remove(key);
    } else {
      mapZones[key] = overrideMapZone;
    }
  }

  var mapZoneList = (mapZones.entries.toList()
        ..sort((a, b) {
          // order by 'windowsId'
          var cmp = a.key['windowsId']!.compareTo(b.key['windowsId']!);
          if (cmp != 0) return cmp;

          // then by 'territory'
          return a.key['territory']!.compareTo(b.key['territory']!);
        }))
      .map((a) => a.value)
      .toList();

  return WindowsZones(version, tzdbVersion, windowsVersion, mapZoneList);
}
