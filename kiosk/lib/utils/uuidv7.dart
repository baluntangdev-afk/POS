import 'dart:math';
import 'dart:typed_data';

class UuidV7 {
  const UuidV7._();

  static String generate() {
    final bytes = _generateRawBytes();
    return _formatAsCanonical(bytes);
  }

  static final _random = Random.secure();

  /// Generates a UUIDv7 as raw bytes (16 bytes)
  static Uint8List _generateRawBytes() {
    final bytes = Uint8List(16);

    // Fill the array with random bytes
    for (var i = 0; i < 16; i++) {
      bytes[i] = _random.nextInt(256);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Set timestamp (48 bits) in bytes 0-5
    bytes[0] = (timestamp >> 40) & 0xFF;
    bytes[1] = (timestamp >> 32) & 0xFF;
    bytes[2] = (timestamp >> 24) & 0xFF;
    bytes[3] = (timestamp >> 16) & 0xFF;
    bytes[4] = (timestamp >> 8) & 0xFF;
    bytes[5] = timestamp & 0xFF;

    // Set version bits (bits 12-15 of bytes 6-7)
    bytes[6] = (bytes[6] & 0x0F) | 0x70;

    // Set variant bits (bits 6-7 of byte 8)
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    return bytes;
  }

  /// Formats raw bytes into the canonical UUIDv7 string representation
  static String _formatAsCanonical(Uint8List bytes) {
    final buffer = StringBuffer();

    for (var i = 0; i < 16; i++) {
      // Insert hyphens at the standard positions (after bytes 3, 5, 7, and 9)
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }

      // Convert the byte to a 2-digit hex string
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }

    return buffer.toString();
  }
}
