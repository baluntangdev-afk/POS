import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

class CsvEncrypter {
  CsvEncrypter(String hexKey) : _key = enc.Key.fromBase16(hexKey);

  final enc.Key _key;

  Future<Uint8List> encrypt(String plaintext) async {
    final ivBytes = Uint8List.fromList(List.generate(16, (_) => Random.secure().nextInt(256)));
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(utf8.encode(plaintext), iv: iv);
    return Uint8List(16 + encrypted.bytes.length)
      ..setAll(0, ivBytes)
      ..setAll(16, encrypted.bytes);
  }
}
