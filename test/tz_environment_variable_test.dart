// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// How the TZ environment variable affects the local time zone.
//
// Linux, macOS and Android follow .NET (and so Noda Time): TZ takes precedence
// over /etc/localtime; an empty TZ means UTC; ':' prefixes are ignored; an
// absolute TZ is a zoneinfo file.
//
// Windows follows Python's tzlocal and Node.js (.NET and Noda Time ignore TZ
// there): an IANA ID in TZ is used, as is a path to a zone file and, on
// Windows only, a Windows zone ID such as 'Tokyo Standard Time'; an empty or
// unrecognised TZ (e.g. a POSIX rule like EST5EDT) is ignored and Windows' own
// zone is used. (Dart's own DateTime applies only POSIX-style TZ values on
// Windows, through the C runtime, so the two can disagree when TZ is set.)

// Uses files and links, which the web doesn't have.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:time_machine2/src/platforms/unix_time_zone.dart';
import 'package:time_machine2/src/platforms/windows_tz_environment.dart';
import 'package:universal_io/io.dart' as io;

import 'time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  test('Tz_Id', Tz_Id);
  test('Tz_ColonPrefix', Tz_ColonPrefix);
  test('Tz_Alias', Tz_Alias);
  test('Tz_Empty_IsUtc', Tz_Empty_IsUtc);
  test('Tz_ColonOnly_IsUtc', Tz_ColonOnly_IsUtc);
  test('Tz_PosixAndRightPrefixes', Tz_PosixAndRightPrefixes);
  test('Tz_UnknownId_IsNotResolved', Tz_UnknownId_IsNotResolved);
  test('Tz_PosixRule_IsNotResolved', Tz_PosixRule_IsNotResolved);
  test(
      'Tz_Unset_NoLocaltime_IsNotResolved', Tz_Unset_NoLocaltime_IsNotResolved);
  test('TzUnset_UsesEtcLocaltimeSymlink', TzUnset_UsesEtcLocaltimeSymlink);
  test('TzUnset_RelativeEtcLocaltimeSymlink',
      TzUnset_RelativeEtcLocaltimeSymlink);
  test('TzUnset_EtcLocaltimeSymlink_PosixAndRightPrefixes',
      TzUnset_EtcLocaltimeSymlink_PosixAndRightPrefixes);
  test('TzUnset_DanglingEtcLocaltimeSymlink',
      TzUnset_DanglingEtcLocaltimeSymlink);
  test('TzUnset_EtcLocaltimeSymlinkToUnknownName_MatchedByContents',
      TzUnset_EtcLocaltimeSymlinkToUnknownName_MatchedByContents);
  test('TzUnset_EtcLocaltimeCopy_MatchedByContents',
      TzUnset_EtcLocaltimeCopy_MatchedByContents);
  test(
      'Tz_TakesPrecedenceOverEtcLocaltime', Tz_TakesPrecedenceOverEtcLocaltime);
  test('Tz_AbsolutePathInZoneInfo', Tz_AbsolutePathInZoneInfo);
  test('Tz_AbsolutePathOutsideZoneInfo_MatchedByContents',
      Tz_AbsolutePathOutsideZoneInfo_MatchedByContents);
  test('Unix_TzIsUsedForLocalZone', Unix_TzIsUsedForLocalZone);
  test('Windows_TzIdIsUsedForLocalZone', Windows_TzIdIsUsedForLocalZone);
  test('WindowsTz_Candidates', WindowsTz_Candidates);
  test('WindowsTz_WindowsId', WindowsTz_WindowsId);
  test('WindowsTz_UnsetOrEmpty_IsIgnored', WindowsTz_UnsetOrEmpty_IsIgnored);
  test('WindowsTz_Id', WindowsTz_Id);
  test('WindowsTz_PosixRuleOrUnknown_IsIgnored',
      WindowsTz_PosixRuleOrUnknown_IsIgnored);
  test('WindowsTz_PathToZoneFile', WindowsTz_PathToZoneFile);
}

const _ids = [
  'Asia/Tokyo',
  'Etc/UTC',
  'Europe/Berlin',
  'UTC',
  // An alias, after the canonical IDs as readUnixTimeZoneId expects.
  'Japan',
];

bool get _isUnix => !io.Platform.isWindows && !io.Platform.isAndroid;

String? _resolve(Map<String, String> environment,
        {String etcLocaltime = '/nonexistent/localtime'}) =>
    resolveUnixTimeZoneId(_ids,
        environment: environment, etcLocaltime: etcLocaltime);

// The rules for TZ itself, which don't touch the file system. Run everywhere.

void Tz_Id() => expect(_resolve({'TZ': 'Europe/Berlin'}), 'Europe/Berlin');

void Tz_ColonPrefix() =>
    expect(_resolve({'TZ': ':Europe/Berlin'}), 'Europe/Berlin');

void Tz_Alias() => expect(_resolve({'TZ': 'Japan'}), 'Japan');

void Tz_Empty_IsUtc() => expect(_resolve({'TZ': ''}), 'UTC');

void Tz_ColonOnly_IsUtc() => expect(_resolve({'TZ': ':'}), 'UTC');

/// A 'posix/' or 'right/' prefix is dropped, as for /etc/localtime's target.
void Tz_PosixAndRightPrefixes() {
  expect(_resolve({'TZ': 'posix/Europe/Berlin'}), 'Europe/Berlin');
  expect(_resolve({'TZ': ':right/Japan'}), 'Japan');
  expect(_resolve({'TZ': 'posix/Mars/Olympus_Mons'}), isNull);
}

/// An unknown TZ isn't resolved, and /etc/localtime isn't consulted instead.
void Tz_UnknownId_IsNotResolved() =>
    expect(_resolve({'TZ': 'Mars/Olympus_Mons'}), isNull);

/// POSIX rule strings such as EST5EDT aren't IDs Time Machine knows here;
/// detection then guesses from the offsets Dart reports.
void Tz_PosixRule_IsNotResolved() =>
    expect(_resolve({'TZ': 'XST5XDT,M3.2.0,M11.1.0'}), isNull);

void Tz_Unset_NoLocaltime_IsNotResolved() =>
    expect(_resolve({'TZDIR': '/nonexistent/zoneinfo'}), isNull);

// File-based rules: a fake zoneinfo directory in a temporary directory. These
// use Unix paths and symlinks, so they run on Linux and macOS.

Future<void> _withZoneInfo(
    Future<void> Function(String root, String zoneInfo) body) async {
  var root = io.Directory.systemTemp.createTempSync('tm_tz_').path;
  try {
    var zoneInfo = '$root/zoneinfo';
    void zone(String id, String contents) {
      io.File('$zoneInfo/$id')
        ..createSync(recursive: true)
        ..writeAsStringSync(contents);
    }

    zone('Europe/Berlin', 'TZif berlin');
    zone('Asia/Tokyo', 'TZif tokyo');
    zone('Japan', 'TZif tokyo'); // same contents as Asia/Tokyo
    zone('Etc/UTC', 'TZif utc');
    await body(root, zoneInfo);
  } finally {
    io.Directory(root).deleteSync(recursive: true);
  }
}

Future TzUnset_UsesEtcLocaltimeSymlink() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    io.Link('$root/localtime').createSync('$zoneInfo/Europe/Berlin');
    expect(_resolve({'TZDIR': zoneInfo}, etcLocaltime: '$root/localtime'),
        'Europe/Berlin');
  });
}

Future TzUnset_RelativeEtcLocaltimeSymlink() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    io.Link('$root/localtime').createSync('zoneinfo/Asia/Tokyo');
    expect(_resolve({'TZDIR': zoneInfo}, etcLocaltime: '$root/localtime'),
        'Asia/Tokyo');
  });
}

/// A 'posix/' or 'right/' prefix in the link target is dropped (.NET keeps it,
/// and Noda Time then guesses).
Future TzUnset_EtcLocaltimeSymlink_PosixAndRightPrefixes() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    for (var (prefix, id) in [
      ('posix', 'Europe/Berlin'),
      ('right', 'Asia/Tokyo')
    ]) {
      io.File('$zoneInfo/$prefix/$id')
        ..createSync(recursive: true)
        ..writeAsStringSync('TZif $prefix');
      var link = io.Link('$root/localtime_$prefix')
        ..createSync('$zoneInfo/$prefix/$id');
      expect(_resolve({'TZDIR': zoneInfo}, etcLocaltime: link.path), id,
          reason: prefix);
    }
  });
}

/// A dangling link (e.g. on an image without tzdata) still names the zone;
/// one naming an unknown zone gives null.
Future TzUnset_DanglingEtcLocaltimeSymlink() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    io.Link('$root/localtime')
        .createSync('$root/missing/zoneinfo/Europe/Berlin');
    expect(_resolve({'TZDIR': zoneInfo}, etcLocaltime: '$root/localtime'),
        'Europe/Berlin');
    io.Link('$root/localtime_unknown')
        .createSync('$root/missing/zoneinfo/Mars/Olympus_Mons');
    expect(
        _resolve({'TZDIR': zoneInfo}, etcLocaltime: '$root/localtime_unknown'),
        isNull);
  });
}

/// A link to a file whose path isn't a known ID (e.g. zoneinfo/localtime)
/// falls back to matching its contents.
Future TzUnset_EtcLocaltimeSymlinkToUnknownName_MatchedByContents() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    io.File('$zoneInfo/Asia/Tokyo').copySync('$zoneInfo/localtime');
    io.Link('$root/localtime').createSync('$zoneInfo/localtime');
    expect(_resolve({'TZDIR': zoneInfo}, etcLocaltime: '$root/localtime'),
        'Asia/Tokyo');
  });
}

/// A copied /etc/localtime is matched by contents, preferring canonical IDs
/// (Asia/Tokyo over its identical alias Japan).
Future TzUnset_EtcLocaltimeCopy_MatchedByContents() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    io.File('$zoneInfo/Asia/Tokyo').copySync('$root/localtime');
    expect(_resolve({'TZDIR': zoneInfo}, etcLocaltime: '$root/localtime'),
        'Asia/Tokyo');
  });
}

Future Tz_TakesPrecedenceOverEtcLocaltime() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    io.Link('$root/localtime').createSync('$zoneInfo/Europe/Berlin');
    expect(
        _resolve({'TZDIR': zoneInfo, 'TZ': 'Asia/Tokyo'},
            etcLocaltime: '$root/localtime'),
        'Asia/Tokyo');
  });
}

Future Tz_AbsolutePathInZoneInfo() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    expect(_resolve({'TZDIR': zoneInfo, 'TZ': '$zoneInfo/Asia/Tokyo'}),
        'Asia/Tokyo');
  });
}

Future Tz_AbsolutePathOutsideZoneInfo_MatchedByContents() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  await _withZoneInfo((root, zoneInfo) async {
    io.File('$zoneInfo/Europe/Berlin').copySync('$root/my_zone');
    expect(
        _resolve({'TZDIR': zoneInfo, 'TZ': '$root/my_zone'}), 'Europe/Berlin');
  });
}

// End to end: Time Machine's detected zone in a child process with TZ set.

// The probe is compiled once, so each child process starts quickly.
Future<String>? _probe;

Future<String> _compileProbe() async {
  var dir = io.Directory.systemTemp.createTempSync('tm_tz_probe_');
  var exe =
      '${dir.path}/print_local_zone${io.Platform.isWindows ? '.exe' : ''}';
  var result = await io.Process.run(io.Platform.resolvedExecutable,
      ['compile', 'exe', 'test/support/print_local_zone.dart', '-o', exe]);
  if (result.exitCode != 0) {
    throw StateError('Compiling the probe failed: ${result.stderr}');
  }
  return exe;
}

Future<String> _localZoneWithTz(String tz) async {
  var exe = await (_probe ??= _compileProbe());
  var environment = Map.of(io.Platform.environment)..['TZ'] = tz;
  var result = await io.Process.run(exe, const [],
      environment: environment,
      includeParentEnvironment: false,
      stdoutEncoding: utf8);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return LineSplitter.split(result.stdout as String).last.trim();
}

Future Unix_TzIsUsedForLocalZone() async {
  if (skipUnless(_isUnix, 'Unix only: uses Unix paths and symlinks')) {
    return;
  }
  expect(await _localZoneWithTz('Asia/Tokyo'), 'Asia/Tokyo');
  expect(await _localZoneWithTz(':Pacific/Chatham'), 'Pacific/Chatham');
  // As in Noda Time: an empty TZ is UTC, whose ID ('UTC') is mapped as the
  // Windows ID 'UTC' first, giving Etc/UTC.
  expect(await _localZoneWithTz(''), 'Etc/UTC');
}

/// As Python's tzlocal and Node.js: an IANA ID in TZ is used on Windows;
/// empty and unrecognised values (POSIX rules) leave Windows' own zone.
Future Windows_TzIdIsUsedForLocalZone() async {
  if (skipUnless(io.Platform.isWindows, 'Windows only')) return;
  var windowsZone = await _localZoneWithTz('');
  expect(windowsZone, DateTimeZone.local.id);
  expect(await _localZoneWithTz('Asia/Tokyo'), 'Asia/Tokyo');
  expect(await _localZoneWithTz(':Pacific/Chatham'), 'Pacific/Chatham');
  // Windows zone IDs, mapped with CLDR as the system zone is.
  expect(await _localZoneWithTz('Tokyo Standard Time'), 'Asia/Tokyo');
  expect(await _localZoneWithTz('SA Western Standard Time'), 'America/La_Paz');
  // EST5EDT looks like a POSIX rule but is also an IANA ID, as in tzlocal.
  expect(await _localZoneWithTz('EST5EDT'), 'EST5EDT');
  for (var tz in ['XST5XDT,M3.2.0,M11.1.0', 'Mars/Olympus_Mons']) {
    expect(await _localZoneWithTz(tz), windowsZone, reason: 'TZ=$tz');
  }
}

// The Windows rules for TZ (as Python's tzlocal), which don't need Windows.

final _knownIds = {
  'Asia/Tokyo',
  'Europe/Berlin',
  'UTC',
  'Japan',
  'Tokyo Standard Time',
};

void WindowsTz_Candidates() {
  expect(windowsTzEnvironmentCandidates(null), isEmpty);
  expect(windowsTzEnvironmentCandidates(''), isEmpty);
  expect(windowsTzEnvironmentCandidates(':'), isEmpty);
  expect(windowsTzEnvironmentCandidates(':Asia/Tokyo'), ['Asia/Tokyo']);
  expect(windowsTzEnvironmentCandidates('Tokyo Standard Time'),
      ['Tokyo Standard Time']);
  // A path that doesn't exist is only the value itself.
  expect(windowsTzEnvironmentCandidates('/missing/zoneinfo/Asia/Tokyo'),
      ['/missing/zoneinfo/Asia/Tokyo']);
}

void WindowsTz_WindowsId() {
  expect(windowsTzEnvironmentZoneId('Tokyo Standard Time', _knownIds),
      'Tokyo Standard Time');
  expect(windowsTzEnvironmentZoneId(':Tokyo Standard Time', _knownIds),
      'Tokyo Standard Time');
  expect(windowsTzEnvironmentZoneId('tokyo standard time', _knownIds), isNull);
}

void WindowsTz_UnsetOrEmpty_IsIgnored() {
  expect(windowsTzEnvironmentZoneId(null, _knownIds), isNull);
  expect(windowsTzEnvironmentZoneId('', _knownIds), isNull);
  expect(windowsTzEnvironmentZoneId(':', _knownIds), isNull);
}

void WindowsTz_Id() {
  expect(windowsTzEnvironmentZoneId('Asia/Tokyo', _knownIds), 'Asia/Tokyo');
  expect(windowsTzEnvironmentZoneId(':Asia/Tokyo', _knownIds), 'Asia/Tokyo');
  expect(windowsTzEnvironmentZoneId('Japan', _knownIds), 'Japan');
  expect(windowsTzEnvironmentZoneId('UTC', _knownIds), 'UTC');
}

void WindowsTz_PosixRuleOrUnknown_IsIgnored() {
  expect(windowsTzEnvironmentZoneId('XST5XDT', _knownIds), isNull);
  expect(
      windowsTzEnvironmentZoneId('XST5XDT,M3.2.0,M11.1.0', _knownIds), isNull);
  expect(windowsTzEnvironmentZoneId('Mars/Olympus_Mons', _knownIds), isNull);
  expect(windowsTzEnvironmentZoneId('asia/tokyo', _knownIds), isNull);
}

void WindowsTz_PathToZoneFile() {
  var root = io.Directory.systemTemp.createTempSync('tm_wtz_');
  try {
    var file = io.File('${root.path}/zoneinfo/Asia/Tokyo')
      ..createSync(recursive: true)
      ..writeAsStringSync('TZif');
    expect(windowsTzEnvironmentZoneId(file.path, _knownIds), 'Asia/Tokyo');
    expect(
        windowsTzEnvironmentZoneId(':${file.path}', _knownIds), 'Asia/Tokyo');
    var other = io.File('${root.path}/not_a_zone')..writeAsStringSync('x');
    expect(windowsTzEnvironmentZoneId(other.path, _knownIds), isNull);
    expect(
        windowsTzEnvironmentZoneId(
            '${root.path}/missing/Asia/Tokyo', _knownIds),
        isNull);
  } finally {
    root.deleteSync(recursive: true);
  }
}
