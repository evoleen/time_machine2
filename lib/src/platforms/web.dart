// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:js_interop';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/datetimezone_providers.dart';
import 'package:time_machine2/time_machine2.dart';

import 'platform_io.dart';

Future initialize(Map<String, dynamic> args) => TimeMachine.initialize(args);

class TimeMachine {
  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize(Map<String, dynamic> args) async {
    Platform.startWeb();

    // Map IO functions
    PlatformIO(config: args);

    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    IDateTimeZoneProviders.defaultProvider = tzdb;

    _readIntlObject();

    // Default TimeZone
    var local = await tzdb[_timeZoneId];
    tzdb.setSystemDefault(local.id);

    // Default Culture
    var cultureId = _locale;
    var culture = await Cultures.getCulture(cultureId);
    ICultures.currentCulture = culture!;
  }

  static late String _timeZoneId;
  static late String _locale;
  // ignore: unused_field
  static late String _numberingSystem;
  // ignore: unused_field
  static late String _calendar;
  // ignore: unused_field
  static late String _yearFormat;
  // ignore: unused_field
  static late String _monthFormat;
  // ignore: unused_field
  static late String _dayFormat;

  // {locale: en-US, numberingSystem: latn, calendar: gregory, timeZone: America/New_York, year: numeric, month: numeric, day: numeric}
  static void _readIntlObject() {
    try {
      final dateTimeFormat = _DateTimeFormat();
      final options = dateTimeFormat.resolvedOptions();

      _locale = options.locale.toDart;
      _timeZoneId = options.timeZone.toDart;
      _numberingSystem = options.numberingSystem.toDart;
      _calendar = options.calendar.toDart;
      _yearFormat = options.year.toDart;
      _monthFormat = options.month.toDart;
      _dayFormat = options.day.toDart;
    } catch (e, s) {
      print('Failed to get platform local information.\n$e\n$s');
    }
  }
}

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external _DateTimeFormat();
  external _ResolvedOptions resolvedOptions();
}

extension type _ResolvedOptions._(JSObject _) implements JSObject {
  external JSString get locale;
  external JSString get timeZone;
  external JSString get numberingSystem;
  external JSString get calendar;
  external JSString get year;
  external JSString get month;
  external JSString get day;
}
