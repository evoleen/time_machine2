import 'package:test/test.dart';
import 'package:time_machine2/time_machine2.dart';
import '../tzdb/zone_transition.dart';

void main() {
  group('ZoneTransition', () {
    test('Construct_Normal', () {
      const name = 'abc';
      var actual = ZoneTransition(
          TimeConstants.unixEpoch, name, Offset.zero, Offset.zero);
      expect(actual.instant, TimeConstants.unixEpoch, reason: 'Instant');
      expect(actual.name, name, reason: 'Name');
      expect(actual.wallOffset, Offset.zero, reason: 'WallOffset');
      expect(actual.standardOffset, Offset.zero, reason: 'StandardOffset');
    });

    test('isTransitionFrom_null_returnsTrue', () {
      var value = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      expect(value.isTransitionFrom(null), isTrue);
    });

    test('isTransitionFrom_identity_false', () {
      var value = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      expect(value.isTransitionFrom(value), isFalse);
    });

    test('isTransitionFrom_equalObject_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_unequalStandardOffset_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.maxValue, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_unequalSavings_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.maxValue);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_unequalName_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'qwe', Offset.zero, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_earlierInstant_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.zero, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_earlierInstantAndUnequalStandardOffset_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.maxValue, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_earlierInstantAndUnequalSavings_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.zero, Offset.maxValue);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_earlierInstantAndUnequalName_false', () {
      var newValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'qwe', Offset.zero, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_laterInstant_false', () {
      var newValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isFalse);
    });

    test('isTransitionFrom_laterInstantAndUnequalStandardOffset_true', () {
      var newValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.maxValue, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isTrue);
    });

    test('isTransitionFrom_laterInstantAndUnequalSavings_true', () {
      var newValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.maxValue);
      expect(newValue.isTransitionFrom(oldValue), isTrue);
    });

    test(
        'isTransitionFrom_laterInstantAndEqualButOppositeStandardAndSavings_true',
        () {
      var newValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.hours(1), Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'abc', Offset.zero, Offset.hours(1));
      expect(newValue.isTransitionFrom(oldValue), isTrue);
    });

    test('isTransitionFrom_laterInstantAndUnequalName_true', () {
      var newValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'qwe', Offset.zero, Offset.zero);
      expect(newValue.isTransitionFrom(oldValue), isTrue);
    });

    test('isTransitionFrom_laterInstantAndUnequalNameAndSavings_true', () {
      var newValue = ZoneTransition(TimeConstants.unixEpoch + Time.epsilon,
          'abc', Offset.zero, Offset.zero);
      var oldValue = ZoneTransition(
          TimeConstants.unixEpoch, 'qwe', Offset.zero, Offset.maxValue);
      expect(newValue.isTransitionFrom(oldValue), isTrue);
    });
  });
}
