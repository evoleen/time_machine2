// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'system_time_zone_backend.dart';

/// No known way to read time zone data on this platform.
SystemTimeZoneBackend createSystemTimeZoneBackend() =>
    const UnsupportedSystemTimeZoneBackend('no platform time zone database');
