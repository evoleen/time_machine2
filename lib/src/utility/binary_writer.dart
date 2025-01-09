// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine2/src/time_machine_internal.dart';

@internal
class BinaryWriter {
  final List<int> output;

  BinaryWriter(this.output);

  void writeInt32(int value) {
    var buffer = Uint8List(4);
    ByteData.view(buffer.buffer).setInt32(0, value, Endian.little);
    buffer.forEach(output.add);
  }

  void writeUint8(int value) {
    output.add(value & 0xff);
  }

  void writeBool(bool value) {
    output.add(value ? 1 : 0);
  }

  void writeInt64(int value) {
    var buffer = Uint8List(8);
    ByteData.view(buffer.buffer).setInt64(0, value, Endian.little);
    buffer.forEach(output.add);
  }

  void write7BitEncodedInt(int value) {
    do {
      var byte = value & 0x7F;
      value >>= 7;
      if (value != 0) {
        byte |= 0x80;
      }
      output.add(byte);
    } while (value != 0);
  }

  void writeString(String value) {
    var bytes = utf8.encode(value);
    write7BitEncodedInt(bytes.length);
    bytes.forEach(output.add);
  }

  void writeStringList(List<String> values) {
    write7BitEncodedInt(values.length);
    values.forEach(writeString);
  }
}
