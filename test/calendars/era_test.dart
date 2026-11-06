// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import '../time_machine_testing.dart';

void main() {
  parameterizedTest('ResourcePresence', Eras, ResourcePresence,
      customDescriptionBuilder: describeArguments, skip: 'unimplemented');
}

/// The static Era fields (typeof(Era).GetTypeInfo().DeclaredProperties in
/// Noda Time).
List<Era> Eras = [
  Era.common,
  Era.beforeCommon,
  Era.annoMartyrum,
  Era.annoHegirae,
  Era.annoMundi,
  Era.annoPersico,
  Era.bahai,
];

void ResourcePresence(Era? era) {
  // todo: get us resources?
  var valueByName; // PatternResources.ResourceManager.GetString(era.ResourceIdentifier, Culture.invariantCulture);
  expect(valueByName, isNotNull,
      reason: 'Missing resource for ' +
          (era != null ? IEra.resourceIdentifier(era) : 'null'));
}
