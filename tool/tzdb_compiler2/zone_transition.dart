import 'package:time_machine2/src/time_machine_internal.dart';

class ZoneTransition {
  final Instant instant;
  final String name;
  final Offset standardOffset;
  final Offset savings;

  ZoneTransition({
    required this.instant,
    required this.name,
    required this.standardOffset,
    required this.savings,
  });

  Offset get wallOffset => standardOffset + savings;

  bool isTransitionFrom(ZoneTransition other) {
    if (instant.isBefore(other.instant)) {
      return false;
    }
    return name != other.name ||
        standardOffset != other.standardOffset ||
        savings != other.savings;
  }

  ZoneInterval toZoneInterval(Instant end) {
    return IZoneInterval.newZoneInterval(
      name,
      instant,
      end,
      wallOffset,
      savings,
    );
  }

  @override
  String toString() {
    return "$name at $instant $standardOffset [$savings]";
  }
}
