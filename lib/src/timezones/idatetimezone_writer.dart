/// Copyright 2013 The Noda Time Authors. All rights reserved.
/// Use of this source code is governed by the Apache License 2.0,
/// as found in the LICENSE.txt file.

import 'package:time_machine2/time_machine2.dart';

/// Interface for writing time-related data to a binary stream.
/// This is similar to `BinaryWriter`, but heavily oriented towards our use cases.
///
/// It is expected that the code reading data written by an implementation
/// will be able to identify which implementation to use. As of Noda Time 2.0,
/// there is only one implementation - but the interface will allow us to
/// evolve the details of the binary structure independently of the code in the
/// time zone implementations which knows how to write/read in terms of this interface
/// and `IDateTimeZoneReader`.
abstract class IDateTimeZoneWriter {
  /// Writes a non-negative integer to the stream. This is optimized towards
  /// cases where most values will be small.
  ///
  /// Throws an [Exception] if the value couldn't be written to the stream.
  /// Throws an [ArgumentError] if [count] is negative.
  void writeCount(int count);

  /// Writes a possibly-negative integer to the stream. This is optimized for
  /// values of small magnitudes.
  ///
  /// Throws an IO [Exception] if the value couldn't be written to the stream.
  void writeSignedCount(int count);

  /// Writes a string to the stream.
  ///
  /// Callers can reasonably expect that these values will be pooled in some fashion,
  /// so should not apply their own pooling.
  ///
  /// Throws an IO [Exception] if the value couldn't be written to the stream.
  void writeString(String value);

  /// Writes a number of milliseconds to the stream, where the number
  /// of milliseconds must be in the range (-1 day, +1 day).
  ///
  /// Throws an IO [Exception] if the value couldn't be written to the stream.
  /// Throws an [ArgumentError] if [millis] is out of range.
  void writeMilliseconds(int millis);

  /// Writes an offset to the stream.
  ///
  /// Throws an IO[Exception] if the value couldn't be written to the stream.
  void writeOffset(Offset offset);

  /// Writes an instant representing a zone interval transition to the stream.
  ///
  /// This method takes a previously-written transition. Depending on the implementation, this value may be
  /// required by the reader in order to reconstruct the next transition, so it should be deterministic for any
  /// given value.
  ///
  /// Throws an IO [Exception] if the value couldn't be written to the stream.
  void writeZoneIntervalTransition(Instant? previous, Instant value);

  /// Writes a string-to-string dictionary to the stream.
  ///
  /// Throws an IO [Exception] if the value couldn't be written to the stream.
  void writeDictionary(Map<String, String> dictionary);

  /// Writes the given 8-bit integer value to the stream.
  void writeByte(int value);
}
