// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'package:archive/archive.dart';
import 'package:time_machine2/src/platforms/platform_io.dart';

Future<List<int>> getTzdbData([String path = 'latest_10y.tzf']) async {
  final data = await PlatformIO.local.getBinary('tzdb', path);

  const zipDecoder = GZipDecoder();

  return zipDecoder.decodeBytes(data.buffer.asInt8List());
}
