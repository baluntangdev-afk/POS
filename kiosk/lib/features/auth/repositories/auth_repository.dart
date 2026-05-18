import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/login_request_dto.dart';
import '../../../data/backend_api/schemas/user_dto.dart';
import '../../../data/backend_api/sources/auth_api.dart';
import '../../../data/backend_api/sources/user_api.dart';
import '../../../data/secure_storage/schemas/auth_doc.dart';
import '../../../data/secure_storage/sources/auth_storage.dart';
import '../entities/auth.dart';

abstract class AuthRepository {
  Future<Auth> getCurrent();

  Future<Auth> login(String username, String pin);

  Future<bool> logout();

  Future<Auth> changePin(int id, String newPin);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApi = ref.watch(authApiProvider);
  final authStorage = ref.watch(authStorageProvider);
  final userApi = ref.watch(userApiProvider);
  return AuthRepositoryImpl(authApi: authApi, authStorage: authStorage, userApi: userApi);
});

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi authApi,
    required AuthStorage authStorage,
    required UserApi userApi,
  }) : _authApi = authApi,
       _authStorage = authStorage,
       _userApi = userApi;

  final AuthApi _authApi;
  final AuthStorage _authStorage;
  final UserApi _userApi;

  @override
  Future<Auth> getCurrent() async {
    final dto = await _authApi.auth();
    return _authFromUserDto(dto);
  }

  @override
  Future<Auth> login(String username, String pin) async {
    final loginRequest = LoginRequestDto(userId: username, devicePin: pin);
    final loginResponse = await _authApi.login(loginRequest);
    final authDoc = AuthDoc(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );
    await _authStorage.write(authDoc);
    final userDto = await _authApi.auth();
    return _authFromUserDto(userDto);
  }

  @override
  Future<bool> logout() async {
    await _authStorage.clear();
    return true;
  }

  @override
  Future<Auth> changePin(int id, String newPin) async {
    final dto = await _userApi.updatePin(userId: '$id', pin: newPin);
    return _authFromUserDto(dto);
  }

  Auth _authFromUserDto(UserDto dto) {
    return Auth(
      id: dto.id,
      username: dto.userId,
      firstName: dto.firstName,
      lastName: dto.lastName,
      middleName: dto.middleName,
      suffix: dto.suffix == 'None' ? null : dto.suffix,
      isPinChanged: dto.isPinChanged,
    );
  }
}
