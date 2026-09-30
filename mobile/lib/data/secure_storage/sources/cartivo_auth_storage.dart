import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../secure_storage.dart';

final cartivoAuthStorageProvider = Provider<CartivoAuthStorage>((ref) {
  return CartivoAuthStorage(ref.watch(secureStorageProvider));
});

/// Persists the bearer access token issued by `POST /cartivo-auth`.
class CartivoAuthStorage {
  CartivoAuthStorage(this._storage);

  static const _accessTokenKey = 'cartivoAuthPosToken';

  final FlutterSecureStorage _storage;

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}
