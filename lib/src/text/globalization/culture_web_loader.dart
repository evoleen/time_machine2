import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:time_machine2/src/platforms/platform_io.dart';

Future<List<int>> getCultureData(String path) async {
  const zipDecoder = GZipDecoder();

  var binary = zipDecoder.decodeBytes(
      (await PlatformIO.local.getBinary('cultures', 'cultures.bin'))
          .buffer
          .asUint8List());

  return binary;
}
