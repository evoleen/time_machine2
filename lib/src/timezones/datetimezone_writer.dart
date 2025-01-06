import 'package:meta/meta.dart';
import 'package:time_machine2/time_machine2.dart';

@internal
abstract class IDateTimeZoneWriter {
  void writeZoneInterval(ZoneInterval zoneInterval);
  Future? close();
  void write7BitEncodedInt(int value);
  void writeBool(bool value);
  void writeInt32(int value);
  void writeInt64(int value);
  void writeOffsetSeconds(Offset value);
  void writeOffsetSeconds2(Offset value);
  void writeString(String value);
  void writeStringList(List<String> list);
  void writeUint8(int value);

  /// Writes the given dictionary of string to string to the stream.
  /// </summary>
  /// <param name='dictionary'>The <see cref="IDictionary{TKey,TValue}" /> to write.</param>
  void writeDictionary(Map<String, String> map);
}
