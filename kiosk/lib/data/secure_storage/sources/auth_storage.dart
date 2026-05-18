import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';
import '../../../exceptions/missing_record_exception.dart';
import '../schemas/auth_doc.dart';
import '../secure_storage.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  final env = ref.watch(appEnvProvider);
  final storage = AuthStorage(ref.watch(secureStorageProvider), env.secureStorageKey);
  ref.onDispose(storage.dispose);
  return storage;
});

class AuthStorage {
  AuthStorage(this._storage, this._key) {
    _notify();
  }

  final FlutterSecureStorage _storage;
  final String _key;

  final _controller = StreamController<AuthDoc>.broadcast();

  Stream<AuthDoc> get stored => _controller.stream;

  Future<void> _notify() async {
    try {
      _controller.add(await latest);
    } catch (e) {
      _controller.addError(e);
    }
  }

  Future<AuthDoc> get latest async {
    final stored = await _storage.read(key: _key);
    if (stored == null) throw MissingRecordException('No saved credential.');
    return AuthDoc.fromJson(stored);
  }

  Future<void> write(AuthDoc document) async {
    await _storage.write(key: _key, value: document.toJson());
    await _notify();
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _notify();
  }

  void dispose() {
    _controller.close();
  }
}
