import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/crypto/csv_encrypter.dart';

void main() {
  const hexKey = '0000000000000000000000000000000000000000000000000000000000000000';
  final encrypter = CsvEncrypter(hexKey);

  test('encrypt returns bytes longer than 16 (IV + cipher)', () async {
    final result = await encrypter.encrypt('hello');
    expect(result.length, greaterThan(16));
  });

  test('round-trip: decrypt recovers original plaintext', () async {
    const plaintext = 'Field,Value\nReport Type,X-Reading\n';
    final blob = await encrypter.encrypt(plaintext);
    final iv = enc.IV(Uint8List.fromList(blob.sublist(0, 16)));
    final cipherBytes = Uint8List.fromList(blob.sublist(16));
    final key = enc.Key.fromBase16(hexKey);
    final e = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = e.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    expect(utf8.decode(decrypted), equals(plaintext));
  });

  test('different calls produce different ciphertexts due to fresh IV', () async {
    final a = await encrypter.encrypt('same plaintext');
    final b = await encrypter.encrypt('same plaintext');
    expect(a, isNot(equals(b)));
  });
}
