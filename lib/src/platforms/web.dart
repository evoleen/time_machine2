// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:js';

// import 'package:resource/resource.dart';
import 'dart:html';

import 'package:http/browser_client.dart' as browser;

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/datetimezone_providers.dart';
import 'package:time_machine2/time_machine2.dart';

import 'platform_io.dart';

class _WebMachineIO implements PlatformIO {
  @override
  Future<ByteData> getBinary(String path, String filename) async {
    final client = browser.BrowserClient();

    try {
      final response = await client.get(
        Uri.parse('packages/time_machine2/data/$path/$filename'),
        headers: {'Accept': 'application/octet-stream'},
      );

      if (response.statusCode == 200) {
        var binary = ByteData.view(response.bodyBytes.buffer,
            response.bodyBytes.offsetInBytes, response.contentLength);

        return binary;
      }

      throw Exception('Unable to load resource $path/$filename');
    } finally {
      client.close();
    }
  }

  @override
  Future /**<Map<String, dynamic>>*/ getJson(
      String path, String filename) async {
    final client = browser.BrowserClient();

    try {
      final response = await client.get(
        Uri.parse('packages/time_machine2/data/$path/$filename'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Unable to load resource $path/$filename');
    } finally {
      client.close();
    }
  }
}

Future initialize(Map args) => TimeMachine.initialize();

class TimeMachine {
  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize() async {
    Platform.startWeb();

    // Map IO functions
    PlatformIO.local = _WebMachineIO();

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
      JsObject options = context['Intl']
          .callMethod('DateTimeFormat')
          .callMethod('resolvedOptions');

      _locale = options['locale'];
      _timeZoneId = options['timeZone'];
      _numberingSystem = options['numberingSystem'];
      _calendar = options['calendar'];
      _yearFormat = options['year'];
      _monthFormat = options['month'];
      _dayFormat = options['day'];
    } catch (e, s) {
      print('Failed to get platform local information.\n$e\n$s');
    }
  }
}
