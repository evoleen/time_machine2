// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/system/system_datetimezone_source.dart';

@internal
abstract class IDateTimeZoneProviders {
  static set defaultProvider(DateTimeZoneProvider provider) =>
      DateTimeZoneProviders._defaultProvider = provider;

  /// The TZDB source behind [DateTimeZoneProviders.tzdb].
  static TzdbDateTimeZoneSource get tzdbSource =>
      DateTimeZoneProviders._tzdbSource;
}

class DateTimeZoneProviders {
  static DateTimeZoneProviders? _instance;

  DateTimeZoneProviders._(Map<String, dynamic> config);

  factory DateTimeZoneProviders(Map<String, dynamic> config) {
    _instance ??= DateTimeZoneProviders._(config);
    return _instance!;
  }

  static Future<DateTimeZoneProvider>? _tzdb;
  static final TzdbDateTimeZoneSource _tzdbSource = TzdbDateTimeZoneSource();

  static Future<DateTimeZoneProvider> get tzdb =>
      _tzdb ??= DateTimeZoneCache.getCache(_tzdbSource);

  static Future<DateTimeZoneProvider>? _system;

  /// A provider for the platform's own time zone data (see
  /// [SystemDateTimeZoneSource]): the Windows time zone database on Windows,
  /// the TZif files on Linux, macOS and iOS, the tzdata bundle on Android and
  /// the browser's Intl data on the web.
  ///
  /// This never falls back to the embedded TZDB data: on a platform without
  /// time zone data it completes with an [UnsupportedError]. Use [tzdb] when
  /// you need data on every platform.
  static Future<DateTimeZoneProvider> get system =>
      _system ??= DateTimeZoneCache.getCache(SystemDateTimeZoneSource());

  static DateTimeZoneProvider? _defaultProvider;

  /// This is the default [DateTimeZoneProvider] for the currently loaded TimeMachine.
  /// It will be used internally where-ever timezone support is needed when no provider is provided,
  static DateTimeZoneProvider? get defaultProvider => _defaultProvider;
}
