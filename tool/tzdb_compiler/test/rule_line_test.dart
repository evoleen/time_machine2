import 'package:test/test.dart';
import 'package:time_machine2/src/time_machine_internal.dart';

import '../tzdb/rule_line.dart';

void main() {
  group('RuleLine', () {
    test('equality', () {
      var yearOffset = ZoneYearOffset(
        TransitionMode.utc,
        10,
        31,
        DayOfWeek.wednesday.value,
        true,
        LocalTime.midnight,
      );

      var recurrence = ZoneRecurrence(
        'bob',
        Offset.zero,
        yearOffset,
        1971,
        2009,
      );

      var actual = RuleLine(recurrence, 'D', null);
      var expected = RuleLine(recurrence, 'D', null);

      expect(actual, equals(expected));
    });
  });
}
