// Copyright 2009 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0,
// as found in the LICENSE.txt file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/datetimezone_writer.dart';

/// Implementation of [IDateTimeZoneReader] for the most recent version
/// of the "blob" format of time zone data. If the format changes, this class will be
/// renamed (e.g. to DateTimeZoneReaderV0) and the new implementation will replace it.
class DateTimeZoneReader implements IDateTimeZoneReader {
  /// Raw stream to read from. Be careful before reading from this - you need to take
  /// account of bufferedByte as well.
  final ByteData input;

  /// String pool to use, or null if no string pool is in use.
  final List<String>? stringPool;

  int currentOffset = 0;

  DateTimeZoneReader(this.input, this.stringPool);

  /// Determines whether there is more data to read from the stream.
  @override
  bool get hasMoreData {
    return currentOffset < input.lengthInBytes;
  }

  /// Reads a non-negative integer value from the stream.
  /// The value must have been written by DateTimeZoneWriter.WriteCount.
  @override
  int readCount() {
    int unsigned = readVarint();
    if (unsigned > 0x7FFFFFFF) {
      throw Exception("Count value greater than Int32.MaxValue");
    }
    return unsigned;
  }

  /// Reads a (possibly-negative) integer value from the stream.
  /// The value must have been written by DateTimeZoneWriter.WriteSignedCount.
  @override
  int readSignedCount() {
    int value = readVarint();
    return (value >> 1) ^ -(value & 1);
  }

  /// Reads a base-128 varint value from the stream.
  /// The value must have been written by DateTimeZoneWriter.WriteVarint.
  int readVarint() {
    int ret = 0;
    int shift = 0;
    while (true) {
      int nextByte = readByte();
      ret += (nextByte & 0x7f) << shift;
      shift += 7;
      if (nextByte < 0x80) {
        return ret;
      }
    }
  }

  /// Reads a signed 8-bit integer value from the stream and returns it as an int.
  /// Throws InvalidNodaDataException if the end of stream is reached unexpectedly.
  @override
  int readByte() {
    try {
      return input.getInt8(currentOffset++);
    } catch (e) {
      throw Exception("Unexpected end of data stream");
    }
  }

  /// Reads a signed 16-bit integer value from the stream and returns it as an int.
  int readInt16() {
    int high = readByte();
    int low = readByte();
    return (high << 8) | low;
  }

  /// Reads a signed 32-bit integer value from the stream and returns it as an int.
  int readInt32() {
    int high = readInt16() & 0xffff;
    int low = readInt16() & 0xffff;
    return (high << 16) | low;
  }

  /// Reads a signed 64-bit integer value from the stream and returns it as an int.
  int readInt64() {
    int high = readInt32() & 0xffffffff;
    int low = readInt32() & 0xffffffff;
    return (high << 32) | low;
  }

  /// Reads a number of milliseconds from the stream.
  @override
  int readMilliseconds() {
    int firstByte = readByte();
    int millis;

    if ((firstByte & 0x80) == 0) {
      millis = firstByte * (30 * 60 * 1000);
    } else {
      int flag = firstByte & 0xe0;
      int firstData = firstByte & 0x1f;
      switch (flag) {
        case 0x80:
          millis = ((firstData << 8) + readByte()) * 60 * 1000;
          break;
        case 0xa0:
          millis = ((firstData << 16) + readInt16()) * 1000;
          break;
        case 0xc0:
          millis = (firstData << 24) + (readByte() << 16) + readInt16();
          break;
        default:
          throw Exception("Invalid flag in offset: ${flag.toRadixString(16)}");
      }
    }
    millis -= 86400000;
    return millis;
  }

  /// Reads a string value from the stream.
  /// The value must have been written by DateTimeZoneWriter.WriteString.
  @override
  String readString() {
    if (stringPool == null) {
      int length = readCount();
      Uint8List data = input.buffer.asUint8List(currentOffset, length);
      currentOffset += length;
      return utf8.decode(data);
    } else {
      int index = readCount();
      return stringPool![index];
    }
  }

  /// Reads an offset value from the stream.
  @override
  Offset readOffset() {
    return Offset(readMilliseconds() ~/ 1000);
  }

  /// Reads a zone interval transition from the stream.
  @override
  Instant readZoneIntervalTransition(Instant? previous) {
    int value = readCount();
    if (value < -DateTimeZoneWriter.minValueForHoursSincePrevious) {
      switch (value) {
        case DateTimeZoneWriter.markerMinValue:
          return IInstant.beforeMinValue;
        case DateTimeZoneWriter.markerMaxValue:
          return IInstant.afterMaxValue;
        case DateTimeZoneWriter.markerRaw:
          return Instant.fromEpochSeconds(readInt64());
        default:
          throw Exception("Unrecognized marker value: $value");
      }
    }
    if (value < DateTimeZoneWriter.minValueForMinutesSinceEpoch) {
      if (previous == null) {
        throw Exception(
            "No previous value, so can't interpret value encoded as delta-since-previous: $value");
      }
      return previous.add(Time(hours: value));
    }
    return DateTimeZoneWriter.epochForMinutesSinceEpoch + Time(minutes: value);
  }

  /// Reads a dictionary of string to string from the stream.
  /// The dictionary must have been written by DateTimeZoneWriter.WriteDictionary.
  @override
  Map<String, String> readDictionary() {
    Map<String, String> results = {};
    int count = readCount();
    for (int i = 0; i < count; i++) {
      String key = readString();
      String value = readString();
      results[key] = value;
    }
    return results;
  }
}
