import 'dart:io';

import 'package:archive/archive.dart';

void main(void) {
  const inputFile = 'data/cultures.bin';
  const outputFile = 'culture_source_data.json';

  const zipDecoder = GZipDecoder();

  final binary = zipDecoder.decodeBytes(File(inputFile).readAsBytesSync());

  var reader = CultureReader(ByteData.view(
      binary.buffer,
      binary.offsetInBytes,
      binary.lengthInBytes,
    ));

    while (reader.isMore) {
      var zone = reader.readCulture();
      cache[zone.name] = zone;
      cultureIds.add(zone.name);
    }

    var index = CultureLoader._(cultureIds);
    cache.forEach((id, zone) => index._cache[id] = zone);
}