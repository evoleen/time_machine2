import 'package:time_machine2/time_machine2.dart';

/// Interface for reading time-related data from a binary stream.
/// This is similar to [ByteData], but heavily oriented towards our use cases.
abstract class IDateTimeZoneReader {
  /// Returns whether or not there is more data in this stream.
  bool get hasMoreData;

  /// Reads a non-negative integer from the stream, which must have been written
  /// by a call to `IDateTimeZoneWriter.writeCount`.
  ///
  /// Throws [InvalidNodaDataException] if the data was invalid.
  /// Throws [IOException] if the stream could not be read.
  int readCount();

  /// Reads a non-negative integer from the stream, which must have been written
  /// by a call to `IDateTimeZoneWriter.writeSignedCount`.
  ///
  /// Throws [InvalidNodaDataException] if the data was invalid.
  /// Throws [IOException] if the stream could not be read.
  int readSignedCount();

  /// Reads a string from the stream.
  ///
  /// Throws [InvalidNodaDataException] if the data was invalid.
  /// Throws [IOException] if the stream could not be read.
  String readString();

  /// Reads a signed 8-bit integer value from the stream and returns it as an int.
  ///
  /// Throws [InvalidNodaDataException] if the data in the stream has been exhausted.
  int readByte();

  /// Reads a number of milliseconds from the stream.
  ///
  /// Throws [InvalidNodaDataException] if the data was invalid.
  /// Throws [IOException] if the stream could not be read.
  int readMilliseconds();

  /// Reads an offset from the stream.
  ///
  /// Throws [InvalidNodaDataException] if the data was invalid.
  /// Throws [IOException] if the stream could not be read.
  Offset readOffset();

  /// Reads an instant representing a zone interval transition from the stream.
  ///
  /// [previous] - The previous transition written (usually for a given timezone), or null if there is
  /// no previous transition.
  ///
  /// Throws [InvalidNodaDataException] if the data was invalid.
  /// Throws [IOException] if the stream could not be read.
  Instant readZoneIntervalTransition(Instant? previous);

  /// Reads a string-to-string dictionary from the stream.
  ///
  /// Throws [InvalidNodaDataException] if the data was invalid.
  /// Throws [IOException] if the stream could not be read.
  Map<String, String> readDictionary();
}
