// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Port of Noda Time's NodaTime.TzdbCompiler.Test/Tzdb/NameIdMappingSupportTest.cs.
// Noda Time reads the system zones from TimeZoneInfo; this reads the same
// Std (standard name) values from the Windows registry.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tzdb/named_id_mapping_support.dart';

/// Standard name -> Windows ID, for the zones on this system where they differ.
/// Empty if we're not on Windows, where these tests are irrelevant.
Map<String, String> _detectedMapping() {
  if (!Platform.isWindows) return const {}; // see the group's skip
  var result = Process.runSync(
      'reg',
      [
        'query',
        r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones',
        '/s',
        '/v',
        'Std',
      ],
      stdoutEncoding: utf8);
  if (result.exitCode != 0) {
    throw StateError('reg query failed: ${result.stderr}');
  }

  var mapping = <String, String>{};
  String? id;
  for (var line in LineSplitter.split(result.stdout as String)) {
    if (line.startsWith('HKEY_')) {
      id = line.substring(line.lastIndexOf(r'\') + 1).trim();
      continue;
    }
    var match = RegExp(r'^\s+Std\s+REG_SZ\s+(.*)$').firstMatch(line);
    if (match == null || id == null) continue;
    var standardName = match.group(1)!.trim();
    if (standardName != id) mapping[standardName] = id;
  }
  return mapping;
}

/// Names whose Windows IDs aren't in CLDR. Noda Time lists Russia TZ 3, 5, 10
/// and 11; CLDR has since added the IDs for 3, 10 and 11.
const _expectedMissingKeys = {'Russia TZ 5 Standard Time'};

void main() {
  group('NameIdMappingSupport', () {
    final detected = _detectedMapping();

    test('AllDetectedNamesAreMapped', () {
      var missing = detected.keys
          .where((name) =>
              !NameIdMappingSupport.StandardNameToIdMap.containsKey(name))
          .where((name) => !_expectedMissingKeys.contains(name))
          .map((name) => '$name => ${detected[name]}')
          .toList();
      expect(missing, isEmpty);
    });

    test('AllDetectedNamesAreMappedCorrectly', () {
      var incorrect = detected.keys
          .where(NameIdMappingSupport.StandardNameToIdMap.containsKey)
          .where((key) =>
              detected[key] != NameIdMappingSupport.StandardNameToIdMap[key])
          .map((key) => 'Expected $key => ${detected[key]}; '
              'was ${NameIdMappingSupport.StandardNameToIdMap[key]}')
          .toList();
      expect(incorrect, isEmpty);
    });
  },
      skip: Platform.isWindows
          ? false
          : 'Windows only: reads the Windows registry');
}
