// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Prints, on one line: DateTimeZone.local's ID, the system provider's default
// zone ID, and 'match' if the two zones have the same offsets on the 1st and
// 15th of every month this year (or the first differing instant). Run as a
// child process by system_source_tz_test.dart, with a chosen TZ.
import 'package:time_machine2/time_machine2.dart';

Future<void> main() async {
  await TimeMachine.initialize();
  var local = DateTimeZone.local;
  var provider = await DateTimeZoneProviders.system;
  var system = await provider.getSystemDefault();

  var year = DateTime.now().toUtc().year;
  var result = 'match';
  for (var month = 1; month <= 12 && result == 'match'; month++) {
    for (var day in [1, 15]) {
      var instant = Instant.utc(year, month, day, 12, 0);
      if (local.getUtcOffset(instant) != system.getUtcOffset(instant)) {
        result = 'differ at $instant: ${local.getUtcOffset(instant)} vs '
            '${system.getUtcOffset(instant)}';
        break;
      }
    }
  }
  print('${local.id}|${system.id}|$result');
}
