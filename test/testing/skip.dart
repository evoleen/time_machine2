// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:test/test.dart';

/// Marks the current test as skipped, with [reason], unless [condition] holds;
/// the equivalent of NUnit's Assert.Ignore. Returns true if the test should
/// stop, so tests can write `if (skipUnless(isWindows, 'Windows only')) return;`.
bool skipUnless(bool condition, String reason) {
  if (!condition) markTestSkipped(reason);
  return !condition;
}
