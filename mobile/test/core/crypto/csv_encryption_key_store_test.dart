import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/crypto/csv_encryption_key_store.dart';

void main() {
  test('generates a 32-byte hex key on first call', () async {
    final store = CsvEncryptionKeyStore(_FakeStorage());
    final key = await store.getOrCreate();
    expect(key.length, 64);
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key), isTrue);
  });

  test('returns the same key on subsequent calls', () async {
    final storage = _FakeStorage();
    final store = CsvEncryptionKeyStore(storage);
    final first = await store.getOrCreate();
    final second = await store.getOrCreate();
    expect(first, equals(second));
  });

  test('regenerate() replaces the stored key', () async {
    final storage = _FakeStorage();
    final store = CsvEncryptionKeyStore(storage);
    final old = await store.getOrCreate();
    final fresh = await store.regenerate();
    final after = await store.getOrCreate();
    expect(fresh, equals(after));
    expect(fresh, isNot(equals(old)));
  });
}

/// In-memory stub — only Android options matter for this app.
class _FakeStorage implements FlutterSecureStorage {
  final _map = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _map[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _map.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
