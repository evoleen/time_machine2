// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'package:meta/meta.dart';
import 'dart:typed_data';

import 'dart_native_io.dart' if (dart.library.ui) 'flutter_io.dart';

/// This class packages platform specific input-output functions that are initialized by the appropriate Platform Provider
@internal
abstract class PlatformIO {
  static PlatformIO? _localInstance;

  /// Factory method to create a new instance of [PlatformIO]. Must be called
  /// before [local] is accessed. Pass in the global Time Machine configuration.
  factory PlatformIO({required Map<String, dynamic> config}) {
    _localInstance ??= TimeMachineIO(config: config);

    return _localInstance!;
  }

  @internal
  Future<ByteData> getBinary(String path, String filename);

  @internal
  Future<dynamic> getJson(String path, String filename);

  @internal
  static PlatformIO get local {
    if (_localInstance == null) {
      throw Exception('PlatformIO not initialized.');
    }

    return _localInstance!;
  }
}

Future initialize(dynamic arg) {
  throw Exception('Conditional Import Failure.');
}
