// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:universal_io/io.dart' as io;

import 'android_tzdata_backend.dart';
import 'system_time_zone_backend.dart';
import 'tzif_directory_backend.dart';
import 'windows_system_backend.dart';

/// Native platforms: the OS's own time zone database.
SystemTimeZoneBackend createSystemTimeZoneBackend() {
  if (io.Platform.isWindows) return WindowsSystemTimeZoneBackend();
  if (io.Platform.isAndroid) return AndroidTzdataBackend.create();
  // Linux, macOS, iOS and other Unix-like systems.
  return TzifDirectoryBackend.create();
}
