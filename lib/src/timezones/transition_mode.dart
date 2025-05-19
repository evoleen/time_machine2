// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

/// Specifies how transitions are calculated. Whether relative to UTC, the time zones standard
/// offset, or the wall (or daylight savings) offset.
@internal
@immutable
class TransitionMode {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = [
    'Utc',
    'Wall',
    'Standard'
  ];

  static const List<TransitionMode> _isoConstants = [utc, wall, standard];

  /// Calculate transitions against UTC.
  static const TransitionMode utc = TransitionMode(0);

  /// Calculate transitions against wall offset.
  static const TransitionMode wall = TransitionMode(1);

  /// Calculate transitions against standard offset.
  static const TransitionMode standard = TransitionMode(2);

  const TransitionMode(this._value);

  factory TransitionMode.fromValue(int value) {
    switch (value) {
      case 0:
        return utc;
      case 1:
        return wall;
      case 2:
        return standard;
      default:
        throw ArgumentError('Invalid TransitionMode value: $value');
    }
  }

  bool operator <(TransitionMode other) => _value < other._value;
  bool operator <=(TransitionMode other) => _value <= other._value;
  bool operator >(TransitionMode other) => _value > other._value;
  bool operator >=(TransitionMode other) => _value >= other._value;

  int operator -(TransitionMode other) => _value - other._value;
  int operator +(TransitionMode other) => _value + other._value;

  @override
  bool operator ==(Object other) =>
      other is TransitionMode && other._value == _value;
  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value < _stringRepresentations.length
      ? _stringRepresentations[_value]
      : 'undefined:$_value';

  TransitionMode? parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token))
        return _isoConstants[i];
    }

    return null;
  }
}
