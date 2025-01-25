import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'tzdb_zone_info_compiler.dart';

/// Main entry point for the time zone information compiler.
/// In theory, we could support multiple sources and formats, but currently, we only support one:
/// https://www.iana.org/time-zones. This system refers to it as TZDB.
/// This also requires a windowsZone.xml file from the Unicode CLDR repository,
/// to map Windows time zone names to TZDB IDs.
Future<int> main(List<String> arguments) async {
  final parser = ArgParser();
  CompilerOptions.addOptionsToArgParser(parser);
  final options = CompilerOptions.fromArgs(parser.parse(arguments));

  if (options == null) {
    stderr.writeln('Invalid options.');
    return 1;
  }

  final tzdbCompiler = TzdbZoneInfoCompiler();
  final tzdb = await tzdbCompiler.compileAsync(options.sourceDirectoryName!);
  tzdb.logCounts();

  if (options.zoneId != null) {
    tzdb.generateDateTimeZone(options.zoneId!);
    return 0;
  }

  var windowsZones = loadWindowsZones(options, tzdb.version);
  if (options.windowsOverride != null) {
    final overrideFile = CldrWindowsZonesParser.parse(options.windowsOverride!);
    windowsZones = mergeWindowsZones(windowsZones, overrideFile);
  }

  logWindowsZonesSummary(windowsZones);

  final writer = TzdbStreamWriter();
  final outputStream = createOutputStream(options);
  await writer.write(tzdb, windowsZones, outputStream);

  if (options.outputFileName != null) {
    print('Reading generated data and validating...');
    final source = read(options);
    source.validate();
  }

  if (options.xmlSchema != null) {
    print('Writing XML schema to ${options.xmlSchema}');
    final source = read(options);
    final provider = DateTimeZoneCache(source);
    XmlSerializationSettings.dateTimeZoneProvider = provider;

    final xmlFile = File(options.xmlSchema!);
    final xmlSink = xmlFile.openWrite(encoding: utf8);
    XmlSchemaDefinition.nodaTimeXmlSchema.write(xmlSink);
    await xmlSink.close();
  }

  return 0;
}

WindowsZones loadWindowsZones(
    CompilerOptions options, String targetTzdbVersion) {
  final mappingPath = options.windowsMapping!;

  if (File(mappingPath).existsSync()) {
    return CldrWindowsZonesParser.parse(mappingPath);
  }

  if (!Directory(mappingPath).existsSync()) {
    throw Exception(
        '$mappingPath does not exist as either a file or a directory');
  }

  final xmlFiles = Directory(mappingPath)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.xml'))
      .toList();

  if (xmlFiles.isEmpty) {
    throw Exception('$mappingPath does not contain any XML files');
  }

  final allFiles = xmlFiles
      .map((file) =>
          {'file': file, 'zones': CldrWindowsZonesParser.parse(file.path)})
      .toList()
      .cast<Map<String, dynamic>>()
    ..sort((a, b) => (b['zones'] as WindowsZones)
        .tzdbVersion
        .compareTo((a['zones'] as WindowsZones).tzdbVersion));

  final bestFile = allFiles.firstWhere(
    (entry) => entry['zones'].tzdbVersion.compareTo(targetTzdbVersion) <= 0,
    orElse: () => throw Exception(
        'No zones files suitable for version $targetTzdbVersion. Found versions targeting: [${allFiles.map((entry) => entry['zones'].tzdbVersion).join(', ')}]'),
  );

  print(
      "Picked Windows Zones from '\${File(bestFile['file'].path).uri.pathSegments.last}' "
      "with TZDB version \${(bestFile['zones'] as WindowsZones).tzdbVersion} as best match for $targetTzdbVersion");

  return bestFile['zones'] as WindowsZones;
}

void logWindowsZonesSummary(WindowsZones windowsZones) {
  print('Windows Zones:');
  print('  Version: ${windowsZones.version}');
  print('  TZDB version: ${windowsZones.tzdbVersion}');
  print('  Windows version: ${windowsZones.windowsVersion}');
  print('  ${windowsZones.mapZones.length} MapZones');
  print('  ${windowsZones.primaryMapping.length} primary mappings');
}

Stream<List<int>> createOutputStream(CompilerOptions options) {
  if (options.outputFileName == null) {
    return StreamController<List<int>>().stream;
  }
  final outputFile = File(options.outputFileName!).openWrite();
  return outputFile;
}

TzdbDateTimeZoneSource read(CompilerOptions options) {
  final file = File(options.outputFileName!);
  if (!file.existsSync()) {
    throw Exception('File does not exist: ${options.outputFileName}');
  }

  final stream = file.openRead();
  return TzdbDateTimeZoneSource.fromStream(stream);
}

WindowsZones mergeWindowsZones(
    WindowsZones originalZones, WindowsZones overrideZones) {
  final version = overrideZones.version.isNotEmpty
      ? overrideZones.version
      : originalZones.version;
  final tzdbVersion = overrideZones.tzdbVersion.isNotEmpty
      ? overrideZones.tzdbVersion
      : originalZones.tzdbVersion;
  final windowsVersion = overrideZones.windowsVersion.isNotEmpty
      ? overrideZones.windowsVersion
      : originalZones.windowsVersion;

  final mapZones = Map.fromEntries(originalZones.mapZones.map(
    (mz) => MapEntry('${mz.windowsId}-${mz.territory}', mz),
  ));

  for (final overrideMapZone in overrideZones.mapZones) {
    final key = '${overrideMapZone.windowsId}-${overrideMapZone.territory}';
    if (overrideMapZone.tzdbIds.isEmpty) {
      mapZones.remove(key);
    } else {
      mapZones[key] = overrideMapZone;
    }
  }

  final sortedMapZones = mapZones.values.toList()
    ..sort((a, b) => a.windowsId.compareTo(b.windowsId) != 0
        ? a.windowsId.compareTo(b.windowsId)
        : a.territory.compareTo(b.territory));

  return WindowsZones(
    version: version,
    tzdbVersion: tzdbVersion,
    windowsVersion: windowsVersion,
    mapZones: sortedMapZones,
  );
}
