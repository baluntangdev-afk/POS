import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/login_roster_item.dart';
import '../repositories/auth_repository.dart';

final loginRosterProvider = AsyncNotifierProvider<LoginRosterNotifier, List<LoginRosterItem>>(
  LoginRosterNotifier.new,
  name: 'loginRosterProvider',
  // The login screen shows its own error/retry UI immediately on failure;
  // Riverpod's default automatic retry (10 attempts, up to ~40s of backoff)
  // would leave the grid spinning long before that UI ever appears.
  retry: (retryCount, error) => null,
);

class LoginRosterNotifier extends AsyncNotifier<List<LoginRosterItem>> {
  @override
  Future<List<LoginRosterItem>> build() async {
    final authRepository = ref.read<AuthRepository>(authRepositoryProvider);
    return authRepository.getLoginRoster();
  }
}
