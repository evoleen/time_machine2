// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'platform_io.dart';

import 'package:time_machine2/data/static_assets.dart';

/// Concrete implementation of [PlatformIO] when compiled for Dart.
/// Uses an internal asset manager to handle files.
/// Since Dart doesn't have any support for native assets, this implementation
/// uses a bundling mechanism that compiles binary assets straight into Dart
/// variables, thus embedding them as part of the resulting executable.
/// This method is only suitable for relatively small assets because it
/// consumes RAM (once for embedding and once more for loading / unpacking).
class TimeMachineIO implements PlatformIO {
  final Map<String, dynamic> config;
  static final Map<String, ByteData> _assets = {};

  TimeMachineIO({required this.config}) {
    registerAllStaticAssets();
  }

  /// Register an asset with the asset manager.
  static void registerAsset(String path, String filename, ByteData data) {
    _assets['$path/$filename'] = data;
  }

  /// Retrieve a registered asset
  static ByteData? _getAsset(String path, String filename) {
    return _assets['$path/$filename'];
  }

  @override
  Future<ByteData> getBinary(String path, String filename) async {
    final asset = _getAsset(path, filename);

    if (asset == null) {
      throw Exception(
          'Time Machine is unable to load resource $path/$filename. Is the file listed as asset in pubspec.yaml?');
    }

    return asset;
  }

  @override
  Future<dynamic> getJson(String path, String filename) async {
    final asset = _getAsset(path, filename);

    if (asset == null) {
      throw Exception(
          'Time Machine is unable to load resource $path/$filename. Is the file listed as asset in pubspec.yaml?');
    }

    final assetString = const Utf8Decoder().convert(asset.buffer.asUint8List());

    return jsonDecode(assetString);
  }
}
