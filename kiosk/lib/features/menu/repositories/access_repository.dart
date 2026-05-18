import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/user_dto.dart';
import '../../../data/backend_api/sources/auth_api.dart';
import '../entities/access.dart';
import '../enums/role.dart';

abstract class AccessRepository {
  Future<Access> getCurrent();
}

final accessRepositoryProvider = Provider<AccessRepository>((ref) {
  final api = ref.watch(authApiProvider);
  return AccessRepositoryImpl(api);
});

class AccessRepositoryImpl implements AccessRepository {
  const AccessRepositoryImpl(this._authApi);

  final AuthApi _authApi;

  @override
  Future<Access> getCurrent() async {
    final dto = await _authApi.auth();
    return _accessFromUserDto(dto);
  }

  Access _accessFromUserDto(UserDto dto) {
    return Access(
      employeeId: dto.userId,
      role: dto.systemAdmin ? Role.admin : Role.user,
      firstName: dto.firstName,
      lastName: dto.lastName,
      middleName: dto.middleName,
      suffix: dto.suffix == 'None' ? null : dto.suffix,
    );
  }
}
