// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:collection/collection.dart';
import 'package:time_machine2/src/time_machine_internal.dart';

/// Represents a single `<mapZone>` element in the CLDR Windows zone mapping file.
@immutable
class MapZone {
  /// Identifier used for the primary territory of each Windows time zone. A zone mapping with
  /// this territory will always have a single entry. The value of this constant is '001'.
  static const String primaryTerritory = '001';

  /// Identifier used for the 'fixed offset' territory. A zone mapping with
  /// this territory will always have a single entry. The value of this constant is 'ZZ'.
  static const String fixedOffsetTerritory = 'ZZ';

  /// The Windows system time zone identifier for this mapping, such as 'Central Standard Time'.
  ///
  /// Most Windows system time zone identifiers use the name for the 'standard' part of the zone as
  /// the overall identifier. Just because a time zone includes 'standard' in its identifier
  /// doesn't mean that it doesn't observe daylight saving time.
  final String windowsId;

  /// The territory code for this mapping. This is typically either '001' to indicate that it's
  /// the primary territory for this ID, or 'ZZ' to indicate a fixed-offset ID, or a different
  /// two-character capitalized code which indicates the geographical territory.
  final String territory;

  /// A read-only collection of TZDB zone identifiers for this mapping, such as
  /// 'America/Chicago' and 'America/Matamoros' (both of which are TZDB zones associated with the
  /// 'Central Standard Time' Windows system time zone).
  ///
  /// For the primary and fixed-offset territory IDs ('001' and 'ZZ') this always contains
  /// exactly one entry; for other territories it may contain more than one.
  final List<String> tzdbIds;

  /// Creates a new mapping entry.
  MapZone(this.windowsId, this.territory, List<String> tzdbIds)
      : tzdbIds = List.unmodifiable(tzdbIds);

  /// Reads a mapping written by [write].
  @internal
  static MapZone read(IDateTimeZoneReader reader) {
    var windowsId = reader.readString();
    var territory = reader.readString();
    var count = reader.readCount();
    var tzdbIds = List<String>.generate(count, (_) => reader.readString());
    return MapZone(windowsId, territory, tzdbIds);
  }

  /// Writes this mapping to a writer.
  @internal
  void write(IDateTimeZoneWriter writer) {
    writer.writeString(windowsId);
    writer.writeString(territory);
    writer.writeCount(tzdbIds.length);
    for (var id in tzdbIds) {
      writer.writeString(id);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MapZone &&
      windowsId == other.windowsId &&
      territory == other.territory &&
      const ListEquality<String>().equals(tzdbIds, other.tzdbIds);

  @override
  int get hashCode => Object.hash(
      windowsId, territory, const ListEquality<String>().hash(tzdbIds));

  @override
  String toString() =>
      'Windows ID: $windowsId; Territory: $territory; TzdbIds: ${tzdbIds.join(' ')}';
}

/// Representation of the `<windowsZones>` element of CLDR supplemental data.
///
/// See [the CLDR design proposal](https://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping)
/// for more details of the structure of the file from which data is taken.
@immutable
class WindowsZones {
  /// The version of the Windows zones mapping data read from the original file.
  ///
  /// As with other IDs, this should largely be treated as an opaque string, but the current
  /// method for generating this from the mapping file extracts a number from an element such as
  /// `<version number="$Revision: 7825 $"/>`. This is a Subversion revision number, but
  /// that association should only be used for diagnostic curiosity, and never assumed in code.
  /// Recent CLDR files don't contain a revision number, in which case this is empty.
  final String version;

  /// The TZDB version this Windows zone mapping data was created from.
  ///
  /// The CLDR mapping file usually lags behind the TZDB file somewhat - partly because the
  /// mappings themselves don't always change when the time zone data does. For example, it's
  /// entirely reasonable for a [TzdbDateTimeZoneSource] with a TZDB version of '2013b'
  /// to be supply a `WindowsZones` object with a TZDB version of '2012f'.
  ///
  /// This property will never return a null value, but will be empty if the version cannot be
  /// determined.
  final String tzdbVersion;

  /// The Windows time zone database version this Windows zone mapping data was created from.
  ///
  /// At the time of this writing, this is populated (by CLDR) from the registry key
  /// HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\TzVersion,
  /// so '7dc0101' for example.
  ///
  /// This property will never return a null value, but will be empty if the version cannot be
  /// determined.
  final String windowsVersion;

  /// An immutable collection of mappings from Windows system time zones to
  /// TZDB time zones.
  ///
  /// Each element in the list maps a single Windows time zone ID and territory to one or more
  /// TZDB time zone IDs. Every Windows time zone ID has a primary territory, as well as
  /// potentially non-primary territories.
  final List<MapZone> mapZones;

  /// An immutable dictionary of primary mappings, from Windows system time zone ID
  /// to TZDB zone ID. This corresponds to the '001' territory which is present for every zone
  /// within the mapping file.
  ///
  /// The TZDB IDs in this map are as written by CLDR, and may be aliases (for example
  /// 'Asia/Calcutta'). See [TzdbDateTimeZoneSource.windowsToTzdbIds] for a map
  /// to canonical IDs.
  final Map<String, String> primaryMapping;

  /// Creates a new mapping from its components.
  WindowsZones(this.version, this.tzdbVersion, this.windowsVersion,
      List<MapZone> mapZones)
      : mapZones = List.unmodifiable(mapZones),
        primaryMapping = Map.unmodifiable({
          for (var z
              in mapZones.where((z) => z.territory == MapZone.primaryTerritory))
            z.windowsId: z.tzdbIds.single
        });

  /// Reads a mapping written by [write].
  @internal
  static WindowsZones read(IDateTimeZoneReader reader) {
    var version = reader.readString();
    var tzdbVersion = reader.readString();
    var windowsVersion = reader.readString();
    var count = reader.readCount();
    var mapZones = List<MapZone>.generate(count, (_) => MapZone.read(reader));
    return WindowsZones(version, tzdbVersion, windowsVersion, mapZones);
  }

  /// Writes this mapping to a writer.
  @internal
  void write(IDateTimeZoneWriter writer) {
    writer.writeString(version);
    writer.writeString(tzdbVersion);
    writer.writeString(windowsVersion);
    writer.writeCount(mapZones.length);
    for (var mapZone in mapZones) {
      mapZone.write(writer);
    }
  }
}
