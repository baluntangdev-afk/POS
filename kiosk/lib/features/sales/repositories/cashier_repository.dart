import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/user_dto.dart';
import '../../../data/backend_api/sources/auth_api.dart';
import '../entities/cashier.dart';

abstract class CashierRepository {
  Future<Cashier> getCurrent();
}

final cashierRepositoryProvider = Provider<CashierRepository>((ref) {
  final api = ref.watch(authApiProvider);
  return CashierRepositoryImpl(api);
});

class CashierRepositoryImpl implements CashierRepository {
  const CashierRepositoryImpl(this._authApi);

  final AuthApi _authApi;

  @override
  Future<Cashier> getCurrent() async {
    final dto = await _authApi.auth();
    return _cashierFromUserDto(dto);
  }

  Cashier _cashierFromUserDto(UserDto dto) {
    return Cashier(
      id: dto.id,
      employeeId: dto.userId,
      firstName: dto.firstName,
      middleName: dto.middleName,
      lastName: dto.lastName,
      suffix: dto.suffix == 'None' ? null : dto.suffix,
    );
  }
}
