import 'package:test/test.dart';
import 'package:time_machine2/src/utility/binary_reader.dart';
import 'dart:typed_data';

void main() {
  group('BinaryReader', () {
    late ByteData data;
    late BinaryReader reader;

    test('readInt32 reads correct value', () {
      data = ByteData(4)..setInt32(0, 0x12345678, Endian.little);
      reader = BinaryReader(data);
      expect(reader.readInt32(), equals(0x12345678));
    });

    test('readInt32 reads negative value', () {
      data = ByteData(4)..setInt32(0, -0x12345678, Endian.little);
      reader = BinaryReader(data);
      expect(reader.readInt32(), equals(-0x12345678));
    });

    test('readUint8 reads correct value', () {
      data = ByteData(1)..setUint8(0, 0xFF);
      reader = BinaryReader(data);
      expect(reader.readUint8(), equals(0xFF));
    });

    test('readUint8 reads high-bit value', () {
      data = ByteData(1)..setUint8(0, 0x80);
      reader = BinaryReader(data);
      expect(reader.readUint8(), equals(0x80));
    });

    test('readBool reads correct value', () {
      data = ByteData(2)
        ..setUint8(0, 1)
        ..setUint8(1, 0);
      reader = BinaryReader(data);
      expect(reader.readBool(), isTrue);
      expect(reader.readBool(), isFalse);
    });

    test('readInt64 reads correct value', () {
      data = ByteData(8)..setInt64(0, 0x1234567890ABCDEF, Endian.little);
      reader = BinaryReader(data);
      expect(reader.readInt64(), equals(0x1234567890ABCDEF));
    });

    test('readInt64 reads negative value', () {
      data = ByteData(8)..setInt64(0, -0x1234567890ABCDEF, Endian.little);
      reader = BinaryReader(data);
      expect(reader.readInt64(), equals(-0x1234567890ABCDEF));
    });

    test('read7BitEncodedInt reads correct value for small numbers', () {
      data = ByteData(1)..setUint8(0, 0x7F);
      reader = BinaryReader(data);
      expect(reader.read7BitEncodedInt(), equals(0x7F));
    });

    test('read7BitEncodedInt reads correct value for large numbers', () {
      data = ByteData(2)
        ..setUint8(0, 0xB4)
        ..setUint8(1, 0x24);
      reader = BinaryReader(data);
      expect(reader.read7BitEncodedInt(), equals(0x1234));
    });

    test('readString reads correct value', () {
      var bytes = [5, 0x48, 0x65, 0x6C, 0x6C, 0x6F]; // "Hello"
      data = ByteData.view(Uint8List.fromList(bytes).buffer);
      reader = BinaryReader(data);
      expect(reader.readString(), equals('Hello'));
    });

    test('readStringList reads correct values', () {
      var bytes = [
        2, // count
        5, 0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
        5, 0x57, 0x6F, 0x72, 0x6C, 0x64 // "World"
      ];
      data = ByteData.view(Uint8List.fromList(bytes).buffer);
      reader = BinaryReader(data);
      expect(reader.readStringList(), equals(['Hello', 'World']));
    });
  });
}
