/// Platform discovery method that exposes a boolean [kIsFlutter].
/// Will be set to true if compiled for Flutter, set to false when compiled
/// for Dart only.

export 'dart_pure.dart' if (dart.library.ui) 'dart_flutter.dart';
