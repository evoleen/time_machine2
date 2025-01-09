import 'dart:convert';
import 'dart:io';

import 'package:time_machine2/src/time_machine_internal.dart';

/// Encodes the culture source JSON data into binary format that can be
/// embedded in compressed form into the library.
void main() async {
  const inputFile = 'tool/culture_compiler/data/culture_source_data.json';
  const outputFile = 'tool/culture_compiler/data/cultures.bin';

  final json =
      jsonDecode(File(inputFile).readAsStringSync()) as Map<String, dynamic>;

  final outputData = List<int>.empty(growable: true);
  final writer = CultureWriter(outputData);

  for (final id in json.keys) {
    final jsonCulture = json[id] as Map<String, dynamic>;
    final culture = CultureJsonReader().readCulture(jsonCulture);
    writer.writeCulture(culture);
  }

  File(outputFile).writeAsBytesSync(outputData);
}
