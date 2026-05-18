import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/user_api.dart';
import '../entities/user.dart';
import '../mappers/user_mappers.dart';

abstract class UserRepository {
  Future<(IList<User>, int total)> getUsers({int? page, int? limit, String? sort, String? filter});

  Future<User> createUser({required User user});

  Future<User> updateUser({required User user});

  Future<User> getUser({required String userId});

  Future<User> updateUerPin({required String userId, required String pin});

  Future<String> deleteUser({required String userId});

  Future<User> resetUserPin({required String userId});

  Future<IList<User>> createBatchUser({required IList<User> users});
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userApi = ref.watch(userApiProvider);
  return UserRepositoryImpl(userApi: userApi);
});

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required UserApi userApi}) : _authApi = userApi;

  final UserApi _authApi;

  @override
  Future<(IList<User>, int)> getUsers({int? page, int? limit, String? sort, String? filter}) async {
    final currentPage = page ?? 1;
    final pageSize = limit ?? 10;

    final firstResponse = await _authApi.getUsers(
      filter: filter,
      limit: pageSize,
      page: currentPage,
      sort: sort,
    );

    final totalItems = firstResponse.total;
    var allUsers = firstResponse.data.map((e) => e.toEntity).toIList();

    final isSinglePage = allUsers.length >= totalItems;
    if (currentPage != 1 || isSinglePage) {
      return (allUsers, totalItems);
    }

    final totalPages = (totalItems + pageSize - 1) ~/ pageSize;
    final remainingPages = List.generate(totalPages - 1, (i) => i + 2);

    const batchSize = 5;
    for (var i = 0; i < remainingPages.length; i += batchSize) {
      final batch = remainingPages.skip(i).take(batchSize);

      final responses = await Future.wait(
        batch.map((p) => _authApi.getUsers(filter: filter, limit: pageSize, page: p, sort: sort)),
      );

      for (final response in responses) {
        allUsers = allUsers.addAll(response.data.map((e) => e.toEntity));
      }
    }

    return (allUsers, totalItems);
  }

  @override
  Future<User> createUser({required User user}) async {
    final result = await _authApi.createUser(user: user.toRequest);
    return result.toEntity;
  }

  @override
  Future<User> updateUser({required User user}) async {
    final result = await _authApi.updateUser(user: user.toRequest);
    return result.toEntity;
  }

  @override
  Future<User> getUser({required String userId}) async {
    final result = await _authApi.getUser(userId: userId);
    return result.toEntity;
  }

  @override
  Future<String> deleteUser({required String userId}) async {
    await _authApi.deleteUser(userId: userId);
    return userId;
  }

  @override
  Future<IList<User>> createBatchUser({required IList<User> users}) async {
    final futures =
        users.map((user) async {
          final result = await _authApi.createUser(user: user.toRequest);
          return result.toEntity;
        }).toIList();
    return Future.wait(futures).then((value) => value.toIList());
  }

  @override
  Future<User> updateUerPin({required String userId, required String pin}) async {
    final result = await _authApi.updatePin(userId: userId, pin: pin);
    return result.toEntity;
  }

  @override
  Future<User> resetUserPin({required String userId}) async {
    final result = await _authApi.resetPin(userId: userId);
    return result.toEntity;
  }
}
