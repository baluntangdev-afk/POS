import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/auth.dart';
import '../repositories/auth_repository.dart';

final loginStateProvider = AsyncNotifierProvider.autoDispose(
  LoginStateNotifier.new,
  name: 'loginStateProvider',
);

class LoginStateNotifier extends AsyncNotifier<Auth?> {
  @override
  Future<Auth?> build() async {
    return null;
  }

  Future<void> login(String username, String pin) async {
    final authRepository = ref.read<AuthRepository>(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await authRepository.login(username, pin);
      return user;
    });
  }

  Future<void> getCurrentUser() async {
    final authRepository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final user = await authRepository.getCurrent();
      return user;
    });
  }
}
