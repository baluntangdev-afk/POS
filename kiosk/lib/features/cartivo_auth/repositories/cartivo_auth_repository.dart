import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/cartivo_auth_response_dto.dart';
import '../../../data/backend_api/sources/cartivo_auth_api.dart';
import '../../../data/secure_storage/schemas/cartivo_auth_doc.dart';
import '../../../data/secure_storage/sources/cartivo_auth_storage.dart';
import '../entities/cartivo_auth.dart';

abstract class CartivoAuthRepository {
  Future<CartivoAuth> register({required String email, required String password, String? name});

  Future<CartivoAuth> login({required String email, required String password});

  Future<void> logout();

  /// Returns the cached session if one is stored and its token hasn't expired yet.
  Future<CartivoAuth?> getStoredSession();
}

final cartivoAuthRepositoryProvider = Provider<CartivoAuthRepository>((ref) {
  final api = ref.watch(cartivoAuthApiProvider);
  final storage = ref.watch(cartivoAuthStorageProvider);
  return CartivoAuthRepositoryImpl(api: api, storage: storage);
});

class CartivoAuthRepositoryImpl implements CartivoAuthRepository {
  CartivoAuthRepositoryImpl({required CartivoAuthApi api, required CartivoAuthStorage storage})
    : _api = api,
      _storage = storage;

  final CartivoAuthApi _api;
  final CartivoAuthStorage _storage;

  @override
  Future<CartivoAuth> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _api.register(email: email, password: password, name: name);
    return _persist(response);
  }

  @override
  Future<CartivoAuth> login({required String email, required String password}) async {
    final response = await _api.login(email: email, password: password);
    return _persist(response);
  }

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<CartivoAuth?> getStoredSession() async {
    final doc = await _storage.latestOrNull;
    if (doc == null || doc.isExpired) return null;
    return CartivoAuth(
      id: doc.userId,
      email: doc.userEmail,
      name: doc.userName,
      tokenExpiresAt: doc.expiresAt,
    );
  }

  Future<CartivoAuth> _persist(CartivoAuthResponseDto response) async {
    final doc = CartivoAuthDoc(
      token: response.token,
      expiresAt: response.expiresAt,
      userId: response.user.id,
      userEmail: response.user.email,
      userName: response.user.name,
    );
    await _storage.write(doc);
    return CartivoAuth(
      id: response.user.id,
      email: response.user.email,
      name: response.user.name,
      tokenExpiresAt: response.expiresAt,
    );
  }
}
