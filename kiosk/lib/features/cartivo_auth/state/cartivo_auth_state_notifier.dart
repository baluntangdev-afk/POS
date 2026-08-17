import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/cartivo_auth.dart';
import '../repositories/cartivo_auth_repository.dart';

final cartivoAuthStateProvider = AsyncNotifierProvider<CartivoAuthStateNotifier, CartivoAuth?>(
  CartivoAuthStateNotifier.new,
  name: 'cartivoAuthStateProvider',
);

class CartivoAuthStateNotifier extends AsyncNotifier<CartivoAuth?> {
  @override
  Future<CartivoAuth?> build() async {
    final repository = ref.read(cartivoAuthRepositoryProvider);
    return repository.getStoredSession();
  }

  Future<void> register({required String email, required String password, String? name}) async {
    final repository = ref.read(cartivoAuthRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.register(email: email, password: password, name: name),
    );
  }

  Future<void> login({required String email, required String password}) async {
    final repository = ref.read(cartivoAuthRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.login(email: email, password: password));
  }

  Future<void> logout() async {
    final repository = ref.read(cartivoAuthRepositoryProvider);
    await repository.logout();
    state = const AsyncData(null);
  }
}
