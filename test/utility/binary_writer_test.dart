import 'package:test/test.dart';
import 'package:time_machine2/src/utility/binary_writer.dart';

void main() {
  group('BinaryWriter', () {
    late List<int> output;
    late BinaryWriter writer;

    setUp(() {
      output = [];
      writer = BinaryWriter(output);
    });

    test('writeInt32 writes correct bytes', () {
      writer.writeInt32(0x12345678);
      expect(output, equals([0x78, 0x56, 0x34, 0x12])); // Little endian
    });

    test('writeInt32 writes negative value', () {
      writer.writeInt32(-0x12345678);
      expect(output, equals([0x88, 0xA9, 0xCB, 0xED])); // Little endian
    });

    test('writeUint8 writes correct byte', () {
      writer.writeUint8(0xFF);
      expect(output, equals([0xFF]));
    });

    test('writeUint8 writes high-bit value', () {
      writer.writeUint8(0x80);
      expect(output, equals([0x80]));
    });

    test('writeBool writes correct byte', () {
      writer.writeBool(true);
      writer.writeBool(false);
      expect(output, equals([1, 0]));
    });

    test('writeInt64 writes correct bytes', () {
      writer.writeInt64(0x1234567890ABCDEF);
      expect(
          output,
          equals([
            0xEF,
            0xCD,
            0xAB,
            0x90,
            0x78,
            0x56,
            0x34,
            0x12
          ])); // Little endian
    });

    test('writeInt64 writes negative value', () {
      writer.writeInt64(-0x1234567890ABCDEF);
      expect(
          output,
          equals([
            0x11,
            0x32,
            0x54,
            0x6F,
            0x87,
            0xA9,
            0xCB,
            0xED
          ])); // Little endian
    });

    test('write7BitEncodedInt writes correct bytes for small numbers', () {
      writer.write7BitEncodedInt(0x7F);
      expect(output, equals([0x7F]));
    });

    test('write7BitEncodedInt writes correct bytes for large numbers', () {
      writer.write7BitEncodedInt(0x1234);
      expect(output, equals([0xB4, 0x24])); // 0x1234 = 0b0001001000110100
    });

    test('writeString writes correct bytes', () {
      writer.writeString('Hello');
      // Length (5) as 7-bit encoded int + UTF-8 bytes
      expect(output, equals([5, 0x48, 0x65, 0x6C, 0x6C, 0x6F]));
    });

    test('writeStringList writes correct bytes', () {
      writer.writeStringList(['Hello', 'World']);
      // Count (2) + two strings with their lengths
      expect(
          output,
          equals([
            2, // count
            5, 0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
            5, 0x57, 0x6F, 0x72, 0x6C, 0x64 // "World"
          ]));
    });
  });
}
