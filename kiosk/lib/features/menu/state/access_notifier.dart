import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/access.dart';
import '../repositories/access_repository.dart';

final accessProvider = AsyncNotifierProvider.autoDispose(
  AccessNotifier.new,
  name: 'accessProvider',
);

class AccessNotifier extends AsyncNotifier<Access> {
  @override
  Future<Access> build() async {
    final repository = ref.watch(accessRepositoryProvider);
    return repository.getCurrent();
  }
}
