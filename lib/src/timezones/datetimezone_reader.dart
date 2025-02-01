// Copyright 2009 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0,
// as found in the LICENSE.txt file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Implementation of [IDateTimeZoneReader] for the most recent version
/// of the "blob" format of time zone data. If the format changes, this class will be
/// renamed (e.g. to DateTimeZoneReaderV0) and the new implementation will replace it.
class DateTimeZoneReader implements IDateTimeZoneReader {
  /// Raw stream to read from. Be careful before reading from this - you need to take
  /// account of bufferedByte as well.
  final RandomAccessFile input;

  /// String pool to use, or null if no string pool is in use.
  final List<String>? stringPool;

  /// Sometimes we need to buffer a byte in memory, e.g. to check if there is any
  /// more data. Anything reading directly from the stream should check here first.
  int? bufferedByte;

  DateTimeZoneReader(this.input, this.stringPool);

  /// Determines whether there is more data to read from the stream.
  bool get hasMoreData {
    if (bufferedByte != null) {
      return true;
    }
    int nextByte = input.readByteSync();
    if (nextByte == -1) {
      return false;
    }
    bufferedByte = nextByte;
    return true;
  }

  /// Reads a non-negative integer value from the stream.
  /// The value must have been written by DateTimeZoneWriter.WriteCount.
  int readCount() {
    int unsigned = readVarint();
    if (unsigned > 0x7FFFFFFF) {
      throw Exception("Count value greater than Int32.MaxValue");
    }
    return unsigned;
  }

  /// Reads a (possibly-negative) integer value from the stream.
  /// The value must have been written by DateTimeZoneWriter.WriteSignedCount.
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
  int readByte() {
    if (bufferedByte != null) {
      int ret = bufferedByte!;
      bufferedByte = null;
      return ret;
    }
    try {
      return input.readByteSync();
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

  /// Reads a string value from the stream.
  /// The value must have been written by DateTimeZoneWriter.WriteString.
  String readString() {
    if (stringPool == null) {
      int length = readCount();
      Uint8List data = input.readSync(length);
      return utf8.decode(data);
    } else {
      int index = readCount();
      return stringPool![index];
    }
  }
}
