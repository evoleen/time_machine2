// Copyright 2009 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0,
// as found in the LICENSE.txt file.

import 'dart:convert';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/utility/binary_writer.dart';

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

  final BinaryWriter output;
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
      writeByte(0x80 | (value & 0x7f));
      value >>= 7;
    }
    writeByte(value & 0x7f);
  }

  @override
  void writeMilliseconds(int millis) {
    const millisecondsPerDay = TimeConstants.millisecondsPerMinute * 60 * 24;

    if (millis < -millisecondsPerDay + 1 || millis > millisecondsPerDay - 1) {
      throw ArgumentError.value(millis, 'millis', 'Out of range');
    }

    millis += millisecondsPerDay;

    if (millis % (30 * TimeConstants.millisecondsPerMinute) == 0) {
      writeByte(millis ~/ (30 * TimeConstants.millisecondsPerMinute));
    } else if (millis % TimeConstants.millisecondsPerMinute == 0) {
      int minutes = millis ~/ TimeConstants.millisecondsPerMinute;
      writeByte(0x80 | (minutes >> 8));
      writeByte(minutes & 0xff);
    } else if (millis % 1000 == 0) {
      int seconds = millis ~/ 1000;
      writeByte(0xa0 | (seconds >> 16));
      writeInt16(seconds & 0xffff);
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
    // In practice, most zone interval transitions will occur within 4000-6000 hours of the previous one
    // (i.e. about 5-8 months), and at an integral number of hours difference. We therefore gain a
    // significant reduction in output size by encoding transitions as the whole number of hours since the
    // previous, if possible.
    // If the previous value was "the start of time" then there's no point in trying to use it.
    if (previous != null && previous != IInstant.beforeMinValue) {
      // Note that the difference might exceed the range of a long, so we can't use a Duration here.
      final seconds = value.epochSeconds - previous.epochSeconds;
      if (seconds % 3600 == 0) {
        final hours = seconds ~/ 3600;
        // As noted above, this will generally fall within the 4000-6000 range, although values up to
        // ~700,000 exist in TZDB.
        if (minValueForHoursSincePrevious <= hours &&
            hours < minValueForMinutesSinceEpoch) {
          writeCount(hours);
          return;
        }
      }
    }

    // We can't write the transition out relative to the previous transition, so let's next try writing it
    // out as a whole number of minutes since an (arbitrary, known) epoch.
    if (value >= epochForMinutesSinceEpoch) {
      final seconds =
          value.epochSeconds - epochForMinutesSinceEpoch.epochSeconds;
      if (seconds % 60 == 0) {
        final minutes = seconds ~/ 60;
        // We typically have a count on the order of 80M here.
        if (minValueForMinutesSinceEpoch < minutes &&
            minutes <= Platform.int32MaxValue) {
          writeCount(minutes);
          return;
        }
      }
    }
    // Otherwise, just write out a marker followed by the instant as a 64-bit number of ticks.  Note that
    // while most of the values we write here are actually whole numbers of _seconds_, optimising for that
    // case will save around 2KB (with tzdb 2012j), so doesn't seem worthwhile.
    writeCount(markerRaw);
    writeInt64(value.epochSeconds);
  }

  @override
  void writeString(String value) {
    if (stringPool == null) {
      List<int> data = utf8.encode(value);
      writeCount(data.length);
      data.forEach(writeByte);
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
    writeByte((value >> 8) & 0xff);
    writeByte(value & 0xff);
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
    output.writeUint8(value);
  }
}
