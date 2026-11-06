// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'intl_backend.dart';
import 'system_time_zone_backend.dart';

/// The web (JS and WASM): the browser's Intl time zone data.
SystemTimeZoneBackend createSystemTimeZoneBackend() => IntlTimeZoneBackend();
