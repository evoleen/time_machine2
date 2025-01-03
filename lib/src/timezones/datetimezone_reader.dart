import 'dart:typed_data';

import 'package:time_machine/src/time_machine_internal.dart';

@internal
class DateTimeZoneReader extends BinaryReader {
  DateTimeZoneReader(ByteData binary, [int offset = 0]) : super(binary, offset);

  ZoneInterval readZoneInterval() {
    var name = /*stream.*/ readString();
    var flag = /*stream.*/ readUint8();
    bool startIsLong = (flag & (1 << 2)) != 0;
    bool endIsLong = (flag & (1 << 3)) != 0;
    bool hasStart = (flag & 1) == 1;
    bool hasEnd = (flag & 2) == 2;
    int? startSeconds;
    int? endSeconds;

    if (hasStart) {
      if (startIsLong)
        startSeconds = readInt64();
      else
        startSeconds = /*stream.*/ readInt32();
    }
    if (hasEnd) {
      if (endIsLong)
        endSeconds = readInt64();
      else
        endSeconds = /*stream.*/ readInt32();
    }

    Instant start = startSeconds == null
        ? IInstant.beforeMinValue
        : Instant.fromEpochSeconds(startSeconds);
    Instant end = endSeconds == null
        ? IInstant.afterMaxValue
        : Instant.fromEpochSeconds(endSeconds);

    var wallOffset = /*stream.*/
        readOffsetSeconds2(); // Offset.fromSeconds(stream.readInt32());
    var savings = /*stream.*/
        readOffsetSeconds2(); // Offset.fromSeconds(stream.readInt32());
    return IZoneInterval.newZoneInterval(name, start, end, wallOffset, savings);
  }
}
