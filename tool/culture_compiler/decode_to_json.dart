import 'dart:convert';
import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'package:time_machine2/src/time_machine_internal.dart';

/// Decodes the original culture binary file into a JSON file.
/// The intention is that all future edits will happen in the JSON file.
/// The JSON file will then be re-encoded into a binary file using a
/// separate script.
void main() {
  const inputFile = 'tool/culture_compiler/data/cultures.bin';
  const outputFile = 'tool/culture_compiler/data/culture_source_data.json';

  final binary = File(inputFile).readAsBytesSync();

  var reader = CultureReader(ByteData.view(
    binary.buffer,
    binary.offsetInBytes,
    binary.lengthInBytes,
  ));

  final cache = <String, Culture>{};

  while (reader.isMore) {
    var zone = reader.readCulture();
    cache[zone.name] = zone;
  }

  final jsonData = <String, dynamic>{};
  final cultureJsonWriter = CultureJsonWriter();

  for (final id in cache.keys) {
    jsonData[id] = cultureJsonWriter.writeCulture(cache[id]!);
  }

  const jsonEncoder = JsonEncoder.withIndent('    ');

  File(outputFile).writeAsStringSync(jsonEncoder.convert(jsonData));
}
