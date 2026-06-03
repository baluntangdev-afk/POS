import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/authorizer_dto.dart';
import '../schemas/create_user_dto.dart';
import '../schemas/user_dto.dart';
import '../schemas/users_response_dto.dart';

final userApiProvider = Provider<UserApi>((ref) {
  final secureClient = ref.watch(secureApiClientProvider);
  return UserApi(secureClient);
});

final authorizersProvider = FutureProvider.autoDispose<List<AuthorizerDto>>((ref) {
  return ref.watch(userApiProvider).getAuthorizers();
});

class UserApi {
  UserApi(this._secureClient);

  final Dio _secureClient;

  Future<List<AuthorizerDto>> getAuthorizers() async {
    final response = await _secureClient.get<dynamic>('/api/v1/users/authorizers');
    final list = response.data as List<dynamic>;
    return list.map((item) => AuthorizerDto.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<UserDto> getUserById(int id) async {
    final response = await _secureClient.get<dynamic>('/api/v1/users/$id');
    final json = jsonEncode(response.data);
    return UserDto.fromJson(json);
  }

  Future<UsersResponseDto> getUsers({int? page, int? limit, String? sort, String? filter}) async {
    final response = await _secureClient.get<dynamic>(
      '/api/v1/users',
      queryParameters: {'page': page ?? 1, 'limit': limit ?? 10, 'sort': sort, 'filter': filter},
    );
    final json = jsonEncode(response.data);
    return UsersResponseDto.fromJson(json);
  }

  Future<UserDto> createUser({required CreateUserDto user}) async {
    final response = await _secureClient.post<dynamic>('/api/v1/users', data: user.toMap());
    final json = jsonEncode(response.data);
    return UserDto.fromJson(json);
  }

  Future<UserDto> updateUser({required CreateUserDto user}) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/users/${user.id}',
      data: user.toMap(),
    );
    final json = jsonEncode(response.data);
    return UserDto.fromJson(json);
  }

  Future<UserDto> getUser({required String userId}) async {
    final response = await _secureClient.get<dynamic>('/api/v1/users/$userId');
    final json = jsonEncode(response.data);
    return UserDto.fromJson(json);
  }

  Future<void> deleteUser({required String userId}) async {
    await _secureClient.delete<dynamic>('/api/v1/users/$userId');
  }

  Future<UserDto> updatePin({required String userId, required String pin}) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/users/$userId',
      data: {'devicePin': pin},
    );
    final json = jsonEncode(response.data);
    return UserDto.fromJson(json);
  }

  Future<UserDto> resetPin({required String userId}) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/users/$userId',
      data: {'devicePin': '000000', 'isPinChanged': false},
    );
    final json = jsonEncode(response.data);
    return UserDto.fromJson(json);
  }

  Future<void> verifyPin({required String userId, required String pin}) async {
    await _secureClient.post<dynamic>(
      '/api/v1/users/verify-pin',
      data: {'userId': userId, 'pin': pin},
    );
  }
}
