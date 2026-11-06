// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

/// How the local UTC offset is found, for failure messages.
const String platformClockDescription = 'DateTime.timeZoneOffset';

/// The local time zone's UTC offset at [epochMilliseconds], in seconds, as
/// the platform reports it (the C library on Linux, macOS, iOS and Android;
/// the C runtime / Win32 on Windows).
int platformUtcOffsetSeconds(int epochMilliseconds) =>
    DateTime.fromMillisecondsSinceEpoch(epochMilliseconds)
        .timeZoneOffset
        .inSeconds;

/// The ID of the platform's local time zone, if the platform reports one
/// without help from Time Machine. Native Dart doesn't (DateTime.timeZoneName
/// is an abbreviation or a display name), so this is null.
String? platformTimeZoneId() => null;
