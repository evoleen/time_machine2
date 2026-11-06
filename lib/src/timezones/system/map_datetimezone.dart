// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

/// A [DateTimeZone] backed by a [ZoneIntervalMap], with known offset bounds.
///
/// This is how the system backends expose zones that don't fit
/// [PrecalculatedDateTimeZone] (the equivalent of Noda Time's
/// `BclDateTimeZone`, which also just wraps a map).
@internal
class MapDateTimeZone extends DateTimeZone {
  final ZoneIntervalMap _map;

  /// The zone is fixed if [minOffset] and [maxOffset] are the same, i.e. it
  /// has the same offset at every instant (as Noda Time defines `IsFixed`).
  MapDateTimeZone(String id, this._map, Offset minOffset, Offset maxOffset)
      : super(id, minOffset == maxOffset, minOffset, maxOffset);

  @override
  ZoneInterval getZoneInterval(Instant instant) =>
      _map.getZoneInterval(instant);
}
