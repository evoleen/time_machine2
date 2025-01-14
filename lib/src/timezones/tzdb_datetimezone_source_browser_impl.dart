import 'package:archive/archive.dart';
import 'package:time_machine2/src/platforms/platform_io.dart';

Future<List<int>> getTzdbData([String path = 'latest_all.tzf']) async {
  final data = await PlatformIO.local.getBinary('tzdb', path);

  const zipDecoder = GZipDecoder();

  return zipDecoder.decodeBytes(data.buffer.asInt8List());
}
