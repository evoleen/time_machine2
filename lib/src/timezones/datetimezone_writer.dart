// Copyright 2009 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0,
// as found in the LICENSE.txt file.

import 'dart:convert';
import 'dart:io';

import 'package:time_machine2/src/time_machine_internal.dart';

/// Implementation of [IDateTimeZoneWriter] for the most recent version
/// of the "blob" format of time zone data. If the format changes, this class will be
/// renamed (e.g. to DateTimeZoneWriterV0) and the new implementation will replace it.
class DateTimeZoneWriter implements IDateTimeZoneWriter {
  static const int markerMinValue = 0;
  static const int markerMaxValue = 1;
  static const int markerRaw = 2;
  static const int minValueForHoursSincePrevious = 1 << 7;
  static const int minValueForMinutesSinceEpoch = 1 << 21;
  static Instant epochForMinutesSinceEpoch = Instant.utc(1800, 1, 1, 0, 0);

  final IOSink output;
  final List<String>? stringPool;

  /// Constructs a DateTimeZoneWriter.
  DateTimeZoneWriter(this.output, this.stringPool);

  /// Writes the given non-negative integer value to the stream.
  @override
  void writeCount(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'Must be non-negative');
    }
    _writeVarint(value);
  }

  /// Writes the given (possibly-negative) integer value to the stream.
  @override
  void writeSignedCount(int count) {
    _writeVarint((count >> 31) ^ (count << 1)); // Zigzag encoding
  }

  void _writeVarint(int value) {
    while (value > 0x7f) {
      output.add([0x80 | (value & 0x7f)]);
      value >>= 7;
    }
    output.add([value & 0x7f]);
  }

  @override
  void writeMilliseconds(int millis) {
    if (millis < -86400000 + 1 || millis > 86400000 - 1) {
      throw ArgumentError.value(millis, 'millis', 'Out of range');
    }
    millis += 86400000;

    if (millis % (30 * 60000) == 0) {
      output.add([(millis ~/ (30 * 60000))]);
    } else if (millis % 60000 == 0) {
      int minutes = millis ~/ 60000;
      output.add([0x80 | (minutes >> 8), minutes & 0xff]);
    } else if (millis % 1000 == 0) {
      int seconds = millis ~/ 1000;
      output
          .add([0xa0 | (seconds >> 16), (seconds >> 8) & 0xff, seconds & 0xff]);
    } else {
      writeInt32(0xc0000000 | millis);
    }
  }

  @override
  void writeOffset(Offset offset) {
    writeMilliseconds(offset.inMilliseconds);
  }

  @override
  void writeDictionary(Map<String, String> dictionary) {
    writeCount(dictionary.length);
    dictionary.forEach((key, value) {
      writeString(key);
      writeString(value);
    });
  }

  @override
  void writeZoneIntervalTransition(Instant? previous, Instant value) {
    if (previous != null && value < previous) {
      throw ArgumentError('Transition must move forward in time');
    }
    if (value == IInstant.beforeMinValue) {
      writeCount(markerMinValue);
      return;
    }
    if (value == IInstant.afterMaxValue) {
      writeCount(markerMaxValue);
      return;
    }
    writeCount(markerRaw);
    writeInt64(value.epochSeconds);
  }

  @override
  void writeString(String value) {
    if (stringPool == null) {
      List<int> data = utf8.encode(value);
      writeCount(data.length);
      output.add(data);
    } else {
      int index = stringPool!.indexOf(value);
      if (index == -1) {
        index = stringPool!.length;
        stringPool!.add(value);
      }
      writeCount(index);
    }
  }

  void writeInt16(int value) {
    output.add([(value >> 8) & 0xff, value & 0xff]);
  }

  void writeInt32(int value) {
    writeInt16(value >> 16);
    writeInt16(value);
  }

  void writeInt64(int value) {
    writeInt32(value >> 32);
    writeInt32(value);
  }

  @override
  void writeByte(int value) {
    output.add([value]);
  }
}
