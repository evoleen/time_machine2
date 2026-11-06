// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Runs the platform-agnostic SystemDateTimeZoneSource checks (checks.dart)
// with package:test, on the Dart VM (with the rest of the suite) and on the
// web:
//
//   dart test test/system_source                        # VM
//   dart test -p chrome test/system_source              # dart2js
//   dart test -p chrome -c dart2wasm test/system_source # dart2wasm
//   dart test -p node test/system_source                # dart2js in Node
//
// Set TIME_MACHINE_EXPECT_SYSTEM_TIME_ZONE (VM only) to the zone the system
// is set to, to check systemDefaultId exactly; on the web it's checked
// against Intl's resolved time zone.
import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:universal_io/io.dart' as io;

import 'checks.dart';

// ignore: do_not_use_environment
const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
// ignore: do_not_use_environment
const bool _isWeb = bool.fromEnvironment('dart.library.js_interop');

void main() {
  setUpAll(() => TimeMachine.initialize());

  final expectedZone = _isWeb
      ? null
      : io.Platform.environment['TIME_MACHINE_EXPECT_SYSTEM_TIME_ZONE'];
  final platform = SystemSourcePlatform(
    name: _isWeb
        ? 'web (${_isWasm ? 'dart2wasm' : 'dart2js'})'
        : io.Platform.operatingSystem,
    usesWindowsIds: !_isWeb && io.Platform.isWindows,
    expectedSystemDefaultId:
        expectedZone == null || expectedZone.isEmpty ? null : expectedZone,
  );

  group('SystemDateTimeZoneSource', () {
    for (var check in systemSourceChecks(platform)) {
      test(check.name, check.body, skip: check.skip);
    }
  });
}
