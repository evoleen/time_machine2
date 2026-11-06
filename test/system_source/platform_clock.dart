// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// The platform's own idea of local time, to compare SystemDateTimeZoneSource
// against: Dart's DateTime on native platforms, JavaScript's Date and Intl on
// the web (JS and WASM).
export 'platform_clock_native.dart'
    if (dart.library.js_interop) 'platform_clock_web.dart';
