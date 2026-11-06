// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Port of Noda Time's NodaTime.TzdbCompiler.Test/ProgramTest.cs.
import 'package:test/test.dart';

import '../main.dart' show MergeWindowsZones;
import '../tzdb/cldr_windows_zone_parser.dart';

void main() {
  group('Program', () {
    test('MergeWindowsZones', () {
      var originalZones = WindowsZones(
          'orig-version', 'orig-tzdb-version', 'orig-win-version', [
        MapZone('ID1', '001', ['A']),
        MapZone('ID1', 'T1-1', ['B', 'C']),
        MapZone('ID1', 'T1-2', ['D']),
        MapZone('ID2', '001', ['E']),
        MapZone('ID2', 'T2-1', ['F']),
      ]);
      var overrideZones = WindowsZones('override-version', '', '', [
        // Replace ID1 / 001
        MapZone('ID1', '001', ['A1']),
        // Delete ID1 / T1-1
        MapZone('ID1', 'T1-1', []),
        // (Leave ID1 / T1-2)
        // Add ID1 / T1-3
        MapZone('ID1', 'T1-3', ['B1', 'C1', 'G1']),
        // (Leave ID2 / 001)
        // Replace ID2 / T2-1
        MapZone('ID2', 'T2-1', ['H1']),
        // Add ID3 / 001
        MapZone('ID3', '001', ['I1']),
      ]);

      var actual = MergeWindowsZones(originalZones, overrideZones);
      var expected = WindowsZones(
          'override-version', 'orig-tzdb-version', 'orig-win-version', [
        MapZone('ID1', '001', ['A1']),
        MapZone('ID1', 'T1-2', ['D']),
        MapZone('ID1', 'T1-3', ['B1', 'C1', 'G1']),
        MapZone('ID2', '001', ['E']),
        MapZone('ID2', 'T2-1', ['H1']),
        MapZone('ID3', '001', ['I1']),
      ]);

      expect(actual.version, expected.version);
      expect(actual.tzdbVersion, expected.tzdbVersion);
      expect(actual.windowsVersion, expected.windowsVersion);
      expect(actual.mapZones, expected.mapZones);
    });
  });
}
