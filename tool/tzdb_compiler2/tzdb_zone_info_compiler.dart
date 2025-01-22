// Copyright 2009 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0.

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'tzdb_database.dart';

class TzdbZoneInfoCompiler {
  static const String makefile = 'Makefile';
  static const String zone1970TabFile = 'zone1970.tab';
  static const String iso3166TabFile = 'iso3166.tab';
  static const String zoneTabFile = 'zone.tab';

  static const List<String> zoneFiles = [
    'africa',
    'antarctica',
    'asia',
    'australasia',
    'europe',
    'northamerica',
    'southamerica',
    'pacificnew',
    'etcetera',
    'backward',
    'systemv',
  ];

  static final RegExp versionRegex = RegExp(r'\d{2,4}[a-z]');

  TzdbZoneInfoCompiler();

  Future<TzdbDatabase> compileAsync(String inputPath) async {
    final source = await _loadSourceAsync(inputPath);
    final version = _inferVersion(source, inputPath);
    final database = TzdbDatabase(version);
    _loadZoneFiles(source, database);
    _loadLocationFiles(source, database);
    return database;
  }

  void _loadZoneFiles(Directory source, TzdbDatabase database) {
    final tzdbParser = TzdbZoneInfoParser();
    for (final file in zoneFiles) {
      final filePath = File(path.join(source.path, file));
      if (filePath.existsSync()) {
        print('Parsing file $file . . .');
        final stream = filePath.openRead();
        tzdbParser.parse(stream, database);
      }
    }
  }

  void _loadLocationFiles(Directory source, TzdbDatabase database) {
    final iso3166File = File(path.join(source.path, iso3166TabFile));
    if (!iso3166File.existsSync()) return;

    final iso3166 = iso3166File
        .readAsLinesSync()
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .map((line) => line.split('\t'))
        .toList();

    final zoneTab = File(path.join(source.path, zoneTabFile));
    if (zoneTab.existsSync()) {
      final iso3166Dict = {for (var bits in iso3166) bits[0]: bits[1]};
      database.zoneLocations = zoneTab
          .readAsLinesSync()
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .map(
              (line) => TzdbZoneLocationParser.parseLocation(line, iso3166Dict))
          .toList();
    }

    final zone1970Tab = File(path.join(source.path, zone1970TabFile));
    if (zone1970Tab.existsSync()) {
      final iso3166Dict = {
        for (var bits in iso3166)
          bits[0]: TzdbZone1970Location.Country(code: bits[0], name: bits[1])
      };
      database.zone1970Locations = zone1970Tab
          .readAsLinesSync()
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .map((line) =>
              TzdbZoneLocationParser.parseEnhancedLocation(line, iso3166Dict))
          .toList();
    }
  }

  Future<Directory> _loadSourceAsync(String inputPath) async {
    if (inputPath.startsWith('ftp://') ||
        inputPath.startsWith('http://') ||
        inputPath.startsWith('https://')) {
      print('Downloading $inputPath');
      final response = await http.get(Uri.parse(inputPath));
      if (response.statusCode != 200) {
        throw HttpException('Failed to download file: $inputPath');
      }
      final tempDir = Directory.systemTemp.createTempSync();
      final archiveFile = File(path.join(tempDir.path, 'archive.tar.gz'));
      await archiveFile.writeAsBytes(response.bodyBytes);
      return tempDir;
    } else if (Directory(inputPath).existsSync()) {
      print('Compiling from directory $inputPath');
      return Directory(inputPath);
    } else {
      print('Compiling from archive file $inputPath');
      final tempDir = Directory.systemTemp.createTempSync();
      final archiveFile = File(inputPath);
      archiveFile.copySync(path.join(tempDir.path, 'archive.tar.gz'));
      return tempDir;
    }
  }

  String _inferVersion(Directory source, String inputPath) {
    final makefilePath = File(path.join(source.path, makefile));
    if (makefilePath.existsSync()) {
      for (final line in makefilePath.readAsLinesSync()) {
        if (line.startsWith('VERSION=')) {
          final version = line.substring(8).trim();
          print('Inferred version $version from $makefile');
          return version;
        }
      }
    }

    final match = versionRegex.firstMatch(inputPath);
    if (match != null) {
      final version = match.group(0)!;
      print('Inferred version $version from file/directory name $inputPath');
      return version;
    }

    throw FormatException('Unable to determine TZDB version from source');
  }
}
