// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';

// todo: the Internal Classes here make me sad

@internal
abstract class IDateTimeZoneProviders {
  static set defaultProvider(DateTimeZoneProvider provider) =>
      DateTimeZoneProviders._defaultProvider = provider;
}

// todo: I think we need an easy way for library users to inject their own IDateTimeZoneSource
abstract class DateTimeZoneProviders {
  // todo: await ... await ... patterns are so ick.

  static Future<DateTimeZoneProvider>? _tzdb;

  static Future<DateTimeZoneProvider> get tzdb =>
      _tzdb ??= DateTimeZoneCache.getCache(TzdbDateTimeZoneSource());

  static DateTimeZoneProvider? _defaultProvider;

  /// This is the default [DateTimeZoneProvider] for the currently loaded TimeMachine.
  /// It will be used internally where-ever timezone support is needed when no provider is provided,
  static DateTimeZoneProvider? get defaultProvider => _defaultProvider;
}
