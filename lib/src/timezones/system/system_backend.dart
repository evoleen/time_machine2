// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// Picks the platform's time zone backend: native platforms (dart:io) read the
// OS database; the web (JS and WASM) uses the browser's Intl data.
export 'system_backend_stub.dart'
    if (dart.library.io) 'system_backend_io.dart'
    if (dart.library.js_interop) 'system_backend_web.dart';
