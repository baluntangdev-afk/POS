import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../repositories/auth_repository.dart';

final changePinProvider = AsyncNotifierProvider.autoDispose(
  ChangePinNotifier.new,
  name: 'changePinProvider',
);

class ChangePinNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false;
  }

  Future<void> changePin(int id, String newPin) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.changePin(id, newPin);
      return true;
    });
  }
}
