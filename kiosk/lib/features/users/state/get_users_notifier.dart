import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/user.dart';
import '../repositories/user_repository.dart';

final getUsersProvider = AsyncNotifierProvider.autoDispose(
  GetUsersNotifier.new,
  name: 'getUsersProvider',
);

class GetUsersNotifier extends AsyncNotifier<IList<User>> {
  @override
  Future<IList<User>> build() async {
    return const IList.empty();
  }

  Future<void> getUsers() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final (users, total) = await repo.getUsers();
      return users;
    });
  }

  Future<void> refresh() async {
    await getUsers();
  }
}
