import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/user.dart';
import '../repositories/user_repository.dart';
import 'user_state.dart';

final modifyUserProvider = AsyncNotifierProvider.autoDispose(
  ModifyUserNotifier.new,
  name: 'modifyUserProvider',
);

class ModifyUserNotifier extends AsyncNotifier<UserState> {
  @override
  Future<UserState> build() async {
    return const UserStateInitial();
  }

  Future<void> createUser(User user) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final result = await repo.createUser(user: user);
      return UserSuccessCreate(result);
    });
  }

  Future<void> updateUser(User user) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final result = await repo.updateUser(user: user);
      return UserSuccessEdit(result);
    });
  }

  Future<void> getUser(User user) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final result = await repo.getUser(userId: user.id);
      return UserSuccessGet(result);
    });
  }

  Future<void> deleteUser(User user) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final result = await repo.deleteUser(userId: user.id);
      return UserSuccessDelete(result);
    });
  }

  Future<void> updatePin({required String userId, required String pin}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final result = await repo.updateUerPin(userId: userId, pin: pin);
      return UserSuccessEdit(result);
    });
  }

  Future<void> resetPin({required String userId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final result = await repo.resetUserPin(userId: userId);
      return UserSuccessReset(result.id);
    });
  }

  // Future<void> batch() async {
  //   final repo = ref.read(userRepositoryProvider);
  //   await repo.createBatchUser(users: MockUsers.getMockUsers);
  // }
}
