// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';

import '../time_machine_testing.dart';

void main() {
  setUpAll(TimeMachineTest.initialize);

  test('loadCultures', loadCultures);
  test('loadBadCulture', loadBadCulture);
}

Future loadCultures() async {
  var ids = await Cultures.ids;
  expect(ids.length, greaterThan(0));

  for (var id in ids) {
    var culture = (await Cultures.getCulture(id))!;
    expect(culture.name, id);
  }
}

// see: issue #13
Future loadBadCulture() async {
  var culture = (await Cultures.getCulture('en-CN'))!;
  expect(culture.name, 'en');
}
