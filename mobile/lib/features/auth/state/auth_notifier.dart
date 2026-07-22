import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../repositories/auth_repository_provider.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    return const AuthInitial();
  }

  UserEntity? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;

  Future<List<UserEntity>> loadUsers() async {
    final result = await _repo.getActiveUsers();
    return result.fold(onSuccess: (u) => u, onFailure: (_) => []);
  }

  Future<bool> login(int userId, String pin) async {
    state = const AuthLoading();
    final result = await _repo.login(userId, pin);
    return result.fold(
      onSuccess: (user) {
        state = AuthAuthenticated(user);
        return true;
      },
      onFailure: (err) {
        state = AuthError(err.message);
        return false;
      },
    );
  }

  void logout() => state = const AuthInitial();

  void clearError() {
    if (state is AuthError) state = const AuthInitial();
  }
}
