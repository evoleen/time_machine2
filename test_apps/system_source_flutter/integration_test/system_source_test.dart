// Runs the platform-agnostic SystemDateTimeZoneSource checks on a device:
//
//   flutter test integration_test -d <device>
//       [--dart-define=TIME_MACHINE_EXPECT_SYSTEM_TIME_ZONE=America/New_York]
//
// Pass TIME_MACHINE_EXPECT_SYSTEM_TIME_ZONE (the device's time zone, as CI
// sets it) to check systemDefaultId exactly; otherwise that check is skipped.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:time_machine2/time_machine2.dart';

import '../../../test/system_source/checks.dart';

const _expectedZone = String.fromEnvironment(
  'TIME_MACHINE_EXPECT_SYSTEM_TIME_ZONE',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => TimeMachine.initialize({'rootBundle': rootBundle}));

  final platform = SystemSourcePlatform(
    name: 'Flutter on ${defaultTargetPlatform.name}',
    expectedSystemDefaultId: _expectedZone.isEmpty ? null : _expectedZone,
  );

  group('SystemDateTimeZoneSource', () {
    for (final check in systemSourceChecks(platform)) {
      test(check.name, check.body, skip: check.skip);
    }
  });
}
