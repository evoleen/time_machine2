import 'package:test/test.dart';
import 'package:time_machine2/src/time_machine_internal.dart';

import '../tzdb/datetimezone_builder.dart';
import '../tzdb/zone_rule_set.dart';

void main() {
  group('DateTimeZoneBuilder', () {
    test('FixedZone_Western', () {
      var offset = Offset.hours(-5);
      var rules = [
        ZoneRuleSet.named(
          'GMT+5',
          offset,
          Offset.zero,
          Platform.int32MaxValue,
          ZoneYearOffset.StartOfYear,
        ),
      ];
      var zone = DateTimeZoneBuilder.build('GMT+5', rules);

      expect(zone is FixedDateTimeZone, true);
      var fixedZone = zone as FixedDateTimeZone;
      expect(fixedZone.offset, offset);
    });

    test('FixedZone_Eastern', () {
      var offset = Offset.hours(5);
      var rules = [
        ZoneRuleSet.named(
          'GMT-5',
          offset,
          Offset.zero,
          Platform.int32MaxValue,
          ZoneYearOffset.StartOfYear,
        ),
      ];
      var zone = DateTimeZoneBuilder.build('GMT-5', rules);

      expect(zone is FixedDateTimeZone, true);
      var fixedZone = zone as FixedDateTimeZone;
      expect(fixedZone.offset, offset);
    });
  });
}
