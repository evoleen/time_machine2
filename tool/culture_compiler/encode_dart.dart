import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  // final xzEncoder = XZEncoder();

  final cultureDataPath = args[0];
  final dartLibraryPath = args[1];

  // final bytes = xzEncoder.encodeBytes(File(cultureDataPath).readAsBytesSync());
  final bytes = File(cultureDataPath).readAsBytesSync();

  final generatedDartFile = generateDartFile(
    name: p.basenameWithoutExtension(cultureDataPath),
    data: bytesAsString(bytes),
  );

  File(dartLibraryPath + '/cultures.bin').writeAsBytesSync(bytes);

  File(dartLibraryPath + '/cultures.dart').writeAsStringSync(generatedDartFile);
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

void registerCulturesAsset() {
  TimeMachineIO.registerAsset('cultures', 'cultures.bin',
      ByteData.sublistView(Uint16List.fromList(_embeddedData.codeUnits)));
}

const _embeddedData =
    '$data';
''';
