import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/cartivo_auth_api.dart';
import '../../../data/secure_storage/sources/cartivo_auth_storage.dart';

final cartivoAuthRepositoryProvider = Provider<CartivoAuthRepository>((ref) {
  final api = ref.watch(cartivoAuthApiProvider);
  final storage = ref.watch(cartivoAuthStorageProvider);
  return CartivoAuthRepositoryImpl(api, storage);
});

abstract interface class CartivoAuthRepository {
  /// Calls `POST /cartivo-auth` and persists the returned access token when
  /// the backend confirms `authenticated`. Returns the `authenticated` flag.
  Future<bool> authenticate();
}

class CartivoAuthRepositoryImpl implements CartivoAuthRepository {
  const CartivoAuthRepositoryImpl(this._api, this._storage);

  final CartivoAuthApi _api;
  final CartivoAuthStorage _storage;

  @override
  Future<bool> authenticate() async {
    final dto = await _api.authenticate();
    final token = dto.accessToken;
    if (dto.authenticated && token != null && token.isNotEmpty) {
      await _storage.writeAccessToken(token);
    }
    return dto.authenticated;
  }
}
