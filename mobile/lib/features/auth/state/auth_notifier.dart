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
        state = AuthAuthenticated(user, mustChangePin: !user.isPinChanged);
        return true;
      },
      onFailure: (err) {
        state = AuthError(err.message);
        return false;
      },
    );
  }

  /// Called once the user has set a new PIN — clears the forced-change flag
  /// without logging them out.
  void completePinSetup() {
    final current = state;
    if (current is AuthAuthenticated) {
      state = AuthAuthenticated(current.user);
    }
  }

  Future<bool> verifySupervisorPin(String pin) async {
    final result = await _repo.verifyAdminPin(pin);
    return result.fold(onSuccess: (ok) => ok, onFailure: (_) => false);
  }

  Future<bool> verifyPinForUser(int userId, String pin) async {
    final result = await _repo.verifyPinForUser(userId, pin);
    return result.fold(onSuccess: (ok) => ok, onFailure: (_) => false);
  }

  Future<List<UserEntity>> loadAuthorizers() async {
    final users = await loadUsers();
    return users.where((u) => u.isAdminOrSupervisor).toList();
  }

  void logout() => state = const AuthInitial();

  void clearError() {
    if (state is AuthError) state = const AuthInitial();
  }
}
