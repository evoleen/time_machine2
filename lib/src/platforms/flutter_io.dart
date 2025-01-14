// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'platform_io.dart';

/// Concrete implementation of [PlatformIO] when compiled for Flutter.
/// Uses [AssetBundle] to load files.
/// NOTE: At the time of writing the use of the [AssetBundle] type requires
/// the a dependency to the Flutter SDK, which marks the package as non-Dart.
/// The code below deliberately uses a dynamic type for the asset bundle to
/// avoid this. The code is thus not type safe, but at least creats the correct
/// package meta info on pub.dev.
class TimeMachineIO implements PlatformIO {
  final Map<String, dynamic> config;
  late final dynamic _assetBundle;

  TimeMachineIO({required this.config}) {
    _assetBundle = config['rootBundle'];
    if (_assetBundle == null) {
      throw Exception(
          'Time Machine requires the parameter rootBundle to be set in TimeMachine.initialize() when compiled for Flutter.');
    }
  }

  @override
  Future<ByteData> getBinary(String path, String filename) async {
    try {
      ByteData byteData = await _assetBundle.loadStructuredBinaryData(
          'packages/time_machine2/data/$path/$filename',
          (ByteData data) => data);

      return byteData;
    } catch (e) {
      throw Exception(
          'Time Machine is unable to load resource $path/$filename. Is the file listed as asset in pubspec.yaml?');
    }
  }

  @override
  Future /**<Map<String, dynamic>>*/ getJson(
      String path, String filename) async {
    try {
      String text = await _assetBundle
          .loadString('packages/time_machine2/data/$path/$filename');
      return json.decode(text);
    } finally {
      throw Exception(
          'Time Machine is unable to load resource $path/$filename. Is the file listed as asset in pubspec.yaml?');
    }
  }
}
