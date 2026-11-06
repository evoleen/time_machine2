// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Prints the local time zone ID Time Machine detects. Run as a child process
// by tz_environment_variable_test.dart, with a chosen TZ environment variable.
import 'package:time_machine2/time_machine2.dart';

Future<void> main() async {
  await TimeMachine.initialize();
  print(DateTimeZone.local.id);
}
