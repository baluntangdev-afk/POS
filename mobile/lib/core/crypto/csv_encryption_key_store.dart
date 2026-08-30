import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/secure_storage/secure_storage.dart';

final csvEncryptionKeyStoreProvider = Provider<CsvEncryptionKeyStore>((ref) {
  return CsvEncryptionKeyStore(ref.watch(secureStorageProvider));
});

class CsvEncryptionKeyStore {
  CsvEncryptionKeyStore(this._storage);

  static const _storageKey = 'csv_export_aes_key';
  static const _aOptions = AndroidOptions(encryptedSharedPreferences: true);
  final FlutterSecureStorage _storage;

  Future<String> getOrCreate() async {
    final stored = await _storage.read(key: _storageKey, aOptions: _aOptions);
    if (stored != null) return stored;
    return _generate();
  }

  Future<String> regenerate() async {
    final hex = _hexFromBytes(
      Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256))),
    );
    await _storage.write(key: _storageKey, value: hex, aOptions: _aOptions);
    return hex;
  }

  Future<String> _generate() async {
    final hex = _hexFromBytes(
      Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256))),
    );
    await _storage.write(key: _storageKey, value: hex, aOptions: _aOptions);
    return hex;
  }

  static String _hexFromBytes(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
