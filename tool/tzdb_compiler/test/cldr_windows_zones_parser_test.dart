// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Port of Noda Time's NodaTime.TzdbCompiler.Test/Tzdb/CldrWindowsZonesParserTest.cs.
import 'dart:io';

import 'package:test/test.dart';
import 'package:xml/xml.dart' as xml;

import '../tzdb/cldr_windows_zone_parser.dart';

void main() {
  group('CldrWindowsZonesParser', () {
    for (final (fileName, expectedVersion) in [
      ('windowsZones-38-1.xml', '38.1'),
      ('windowsZones-47.xml', '47'),
    ]) {
      test('Versions_Present($fileName)', () {
        const source = r'''
<supplementalData>
  <version number='$Revision: rev-version $'/>
  <generation date='$Date: 2012-01-14 03:54:32 -0600 (Sat, 14 Jan 2012) $' />
  <windowsZones>
    <mapTimezones otherVersion='win-version' typeVersion='tzdb-version'>
    </mapTimezones>
  </windowsZones>
</supplementalData>
''';
        var doc = xml.XmlDocument.parse(source);
        var parsed = CldrWindowsZonesParser.parse(doc, '../$fileName');
        expect(parsed.version, expectedVersion);
        expect(parsed.windowsVersion, 'win-version');
        expect(parsed.tzdbVersion, 'tzdb-version');
      });
    }

    test('Versions_Absent', () {
      const source = r'''
<supplementalData>
  <generation date='$Date: 2012-01-14 03:54:32 -0600 (Sat, 14 Jan 2012) $' />
  <windowsZones>
    <mapTimezones>
    </mapTimezones>
  </windowsZones>
</supplementalData>
''';
      var doc = xml.XmlDocument.parse(source);
      var parsed = CldrWindowsZonesParser.parse(doc, '');
      expect(parsed.version, '');
      expect(parsed.windowsVersion, '');
      expect(parsed.tzdbVersion, '');
    });

    test('MapZones', () {
      const source = '''
<supplementalData>
  <windowsZones>
    <mapTimezones>
      <mapZone other='X' territory='t0' type='' />
      <mapZone other='X' territory='t1' type='A' />
      <mapZone other='X' territory='t2' type='B C' />
    </mapTimezones>
  </windowsZones>
</supplementalData>
''';
      var doc = xml.XmlDocument.parse(source);
      var mapZones = CldrWindowsZonesParser.parse(doc, '').mapZones;
      expect(mapZones.length, 3);
      expect(mapZones[0], MapZone('X', 't0', []));
      expect(mapZones[1], MapZone('X', 't1', ['A']));
      expect(mapZones[2], MapZone('X', 't2', ['B', 'C']));
    });

    // Not in Noda Time: every checked-in CLDR file parses, with the version
    // from its name and a primary mapping for every Windows ID.
    test('CheckedInFiles', () {
      var files = Directory('tool/tzdb_compiler/data/cldr')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.xml'))
          .toList();
      expect(files.length, greaterThanOrEqualTo(28));
      for (var file in files) {
        var zones = CldrWindowsZonesParser.parseFile(file.path);
        var name = file.uri.pathSegments.last;
        expect(
            zones.version,
            name
                .replaceAll('windowsZones-', '')
                .replaceAll('.xml', '')
                .replaceAll('-', '.'),
            reason: name);
        expect(zones.primaryMapping, isNotEmpty, reason: name);
        var windowsIds = zones.mapZones.map((z) => z.windowsId).toSet();
        expect(zones.primaryMapping.keys.toSet(), windowsIds, reason: name);
      }
    });

    // Not in Noda Time: the latest checked-in CLDR data.
    test('CheckedInData', () {
      var zones = CldrWindowsZonesParser.parseFile(
          'tool/tzdb_compiler/data/cldr/windowsZones-49.xml');
      expect(zones.version, '49');
      expect(zones.primaryMapping['AUS Eastern Standard Time'],
          'Australia/Sydney');
    });
  });
}
