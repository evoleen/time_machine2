// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Port of Noda Time's NodaTime.Test/TimeZones/Cldr/MapZoneTest.cs and
// WindowsZonesTest.cs.
import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/cldr/windows_zones.dart';
import 'package:time_machine2/src/timezones/datetimezone_writer.dart';
import 'package:time_machine2/src/utility/binary_writer.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachineTest.initialize();
  await runTests();
}

/// Equivalent of Noda Time's TestHelper.TestEqualsClass.
void _testEqualsClass(Object value, Object equalValue, Object unequalValue) {
  expect(value == equalValue, isTrue);
  expect(value.hashCode, equalValue.hashCode);
  expect(value == unequalValue, isFalse);
  expect(unequalValue == value, isFalse);
}

/// Writes with [write], then reads back with [read], without a string pool.
T _roundTrip<T>(void Function(IDateTimeZoneWriter writer) write,
    T Function(IDateTimeZoneReader reader) read) {
  var output = <int>[];
  write(DateTimeZoneWriter(BinaryWriter(output), null));
  var reader = DateTimeZoneReader(
      ByteData.sublistView(Uint8List.fromList(output)), null);
  return read(reader);
}

// MapZoneTest

@Test()
void MapZone_Equality() {
  var zone1 = MapZone('windowsId', 'territory', ['id1', 'id2', 'id3']);
  var zone2 = MapZone('windowsId', 'territory', ['id1', 'id2', 'id3']);
  var zone3 = MapZone('otherWindowsId', 'territory', ['id1', 'id2', 'id3']);
  var zone4 = MapZone('windowsId', 'otherTerritory', ['id1', 'id2', 'id3']);
  var zone5 = MapZone('windowsId', 'territory', ['id1', 'id2']);
  var zone6 = MapZone('windowsId', 'territory', ['id1', 'id2', 'id4']);

  _testEqualsClass(zone1, zone2, zone3);
  _testEqualsClass(zone1, zone2, zone4);
  _testEqualsClass(zone1, zone2, zone5);
  _testEqualsClass(zone1, zone2, zone6);
}

@Test()
void MapZone_ToString() {
  var zone = MapZone('windowsId', 'territory', ['id1', 'id2', 'id3']);
  expect(zone.toString(),
      'Windows ID: windowsId; Territory: territory; TzdbIds: id1 id2 id3');
}

@Test()
void MapZone_ReadWrite() {
  var zone = MapZone('windowsId', 'territory', ['id1', 'id2', 'id3']);
  var zone2 = _roundTrip(zone.write, MapZone.read);
  expect(zone2, zone);
}

// WindowsZonesTest

final _mapZone1 =
    MapZone('windowsId1', 'territory1', ['id1.1', 'id1.2', 'id1.3']);
final _mapZone2 =
    MapZone('windowsId2', MapZone.primaryTerritory, ['primaryId2']);
final _mapZone3 =
    MapZone('windowsId3', MapZone.primaryTerritory, ['primaryId3']);

@Test()
void WindowsZones_Properties() {
  var zones = WindowsZones('version', 'tzdbVersion', 'windowsVersion',
      [_mapZone1, _mapZone2, _mapZone3]);
  expect(zones.version, 'version');
  expect(zones.tzdbVersion, 'tzdbVersion');
  expect(zones.windowsVersion, 'windowsVersion');
  expect(zones.primaryMapping['windowsId2'], 'primaryId2');
  expect(zones.primaryMapping['windowsId3'], 'primaryId3');
  expect(zones.mapZones, [_mapZone1, _mapZone2, _mapZone3]);
}

@Test()
void WindowsZones_ReadWrite() {
  var zones = WindowsZones('version', 'tzdbVersion', 'windowsVersion',
      [_mapZone1, _mapZone2, _mapZone3]);
  var zones2 = _roundTrip(zones.write, WindowsZones.read);
  expect(zones2.version, 'version');
  expect(zones2.tzdbVersion, 'tzdbVersion');
  expect(zones2.windowsVersion, 'windowsVersion');
  expect(zones2.primaryMapping['windowsId2'], 'primaryId2');
  expect(zones2.primaryMapping['windowsId3'], 'primaryId3');
  expect(zones2.mapZones, [_mapZone1, _mapZone2, _mapZone3]);
}
