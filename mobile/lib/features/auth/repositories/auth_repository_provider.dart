import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import 'auth_repository.dart';
import 'auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(databaseProvider));
});
