// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:js_interop';

/// How the local UTC offset is found, for failure messages.
const String platformClockDescription = 'JavaScript Date#getTimezoneOffset';

/// The local time zone's UTC offset at [epochMilliseconds], in seconds, as
/// the JavaScript engine reports it. Read from JavaScript directly (not via
/// Dart's DateTime) so that dart2wasm is checked against the browser too.
int platformUtcOffsetSeconds(int epochMilliseconds) {
  // getTimezoneOffset is in minutes, and positive west of Greenwich.
  var minutes = _JSDate(epochMilliseconds.toDouble().toJS)
      .getTimezoneOffset()
      .toDartDouble;
  return -(minutes * 60).round();
}

/// The IANA ID of the browser's (or Node's) local time zone, from
/// `Intl.DateTimeFormat().resolvedOptions().timeZone`.
String? platformTimeZoneId() =>
    _DateTimeFormat().resolvedOptions().timeZone?.toDart;

@JS('Date')
extension type _JSDate._(JSObject _) implements JSObject {
  external _JSDate(JSNumber epochMilliseconds);
  external JSNumber getTimezoneOffset();
}

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external _DateTimeFormat();
  external _ResolvedOptions resolvedOptions();
}

extension type _ResolvedOptions._(JSObject _) implements JSObject {
  external JSString? get timeZone;
}
