// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:time_machine2/src/platforms/unix_time_zone.dart';
import 'package:universal_io/io.dart' as io;

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachineTest.initialize();
  await runTests();
}

@Test()
void TzEnvironmentVariable() {
  expect(tzEnvironmentVariable(null), isNull);
  expect(tzEnvironmentVariable(''), '');
  expect(tzEnvironmentVariable('Europe/Berlin'), 'Europe/Berlin');
  // POSIX allows a leading colon
  expect(tzEnvironmentVariable(':Europe/Berlin'), 'Europe/Berlin');
}

@Test()
void TimeZoneDirectory() {
  expect(timeZoneDirectory(null), '/usr/share/zoneinfo/');
  expect(timeZoneDirectory(''), '/usr/share/zoneinfo/');
  expect(timeZoneDirectory('/opt/zoneinfo'), '/opt/zoneinfo/');
  expect(timeZoneDirectory('/opt/zoneinfo/'), '/opt/zoneinfo/');
}

@Test()
@TestCase(['/usr/share/zoneinfo/Europe/Berlin', 'Europe/Berlin'])
@TestCase([
  '/usr/share/zoneinfo/America/Argentina/Buenos_Aires',
  'America/Argentina/Buenos_Aires'
])
@TestCase(['/usr/share/zoneinfo/UTC', 'UTC'])
// macOS: /etc/localtime -> /var/db/timezone/zoneinfo/...
@TestCase(['/var/db/timezone/zoneinfo/Australia/Sydney', 'Australia/Sydney'])
// Relative symlink targets, resolved against /etc
@TestCase(['/etc/../usr/share/zoneinfo/Asia/Tokyo', 'Asia/Tokyo'])
@TestCase(['/usr/share/zoneinfo//Asia/./Tokyo', 'Asia/Tokyo'])
@TestCase(['/etc/localtime', null])
void ZoneIdFromPath(String path, String? expected) {
  expect(zoneIdFromPath(path, '/usr/share/zoneinfo/'), expected);
}

/// On Linux and macOS the local zone comes from the IANA ID the system is
/// configured with, as .NET (and so Noda Time) finds it.
@Test()
Future UnixLocalZoneIsTheConfiguredId() async {
  if (skipUnless(!io.Platform.isWindows && !io.Platform.isAndroid,
      'Linux and macOS only')) {
    return;
  }
  var known = TzdbDateTimeZoneSource.defaultSource.canonicalIdMap;

  String? expected;
  var tz = tzEnvironmentVariable(io.Platform.environment['TZ']);
  if (tz != null && tz.isNotEmpty && !tz.startsWith('/')) {
    expected = tz;
  } else if (tz == null) {
    var link = io.Link('/etc/localtime');
    if (link.existsSync()) {
      // The direct target: on macOS, fully resolving it can leave the
      // zoneinfo directory (/var/db/timezone/zoneinfo is itself a link).
      var target = link.targetSync();
      var index = target.lastIndexOf('/zoneinfo/');
      if (index >= 0) expected = target.substring(index + '/zoneinfo/'.length);
    }
  }
  if (skipUnless(expected != null && known.containsKey(expected),
      'No configured IANA ID found (TZ=$tz)')) {
    return;
  }
  // The configured ID is mapped as Noda Time maps TimeZoneInfo.Local.Id:
  // e.g. 'UTC' (macOS's /etc/localtime target) matches the Windows ID 'UTC'
  // first and becomes 'Etc/UTC'.
  expect(DateTimeZone.local.id,
      TzdbDateTimeZoneSource.defaultSource.mapSystemTimeZoneId(expected!));
}
