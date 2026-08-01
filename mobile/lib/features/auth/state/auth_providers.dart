import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/user_entity.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final authorizersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) {
  return ref.read(authNotifierProvider.notifier).loadAuthorizers();
});
