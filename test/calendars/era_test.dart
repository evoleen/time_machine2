// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
// todo: this affects JS_Test_Gen
import 'dart:mirrors';

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  var eraType = reflectType(Era) as ClassMirror;
  // Named by field, as two eras share the name 'AM'.
  Eras = eraType.declarations.values
      .where((v) => v is VariableMirror && v.isStatic)
      .map((v) => TestCaseData(eraType.getField(v.simpleName).reflectee)
        ..name = MirrorSystem.getName(v.simpleName))
      .toList();

  await runTests();
}

List<TestCaseData> Eras =
    []; /*typeof(Era).GetTypeInfo()
    .DeclaredProperties // TODO: Only static and ones...
    .Where(property => property.PropertyType == typeof(Era))
.Select(property => property.GetValue(null, null))
.Cast<Era>();*/

@Test()
@TestCaseSource(#Eras)
void ResourcePresence(Era era) {
  var valueByName = PatternResources.getString(
      IEra.resourceIdentifier(era), Culture.invariant);
  expect(valueByName, isNotEmpty,
      reason: 'Missing resource for ${IEra.resourceIdentifier(era)}');
}

@Test()
@TestCaseSource(#Eras)
void ToStringReturnsName(Era era) {
  expect(era.toString(), era.name);
}
