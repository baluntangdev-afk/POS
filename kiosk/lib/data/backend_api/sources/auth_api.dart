import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/login_request_dto.dart';
import '../schemas/login_response_dto.dart';
import '../schemas/user_dto.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final openClient = ref.watch(openApiClientProvider);
  final secureClient = ref.watch(secureApiClientProvider);
  return AuthApi(openClient, secureClient);
});

class AuthApi {
  const AuthApi(this._openClient, this._secureClient);

  final Dio _openClient;
  final Dio _secureClient;

  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final response = await _openClient.post<dynamic>(
      '/api/v1/auth/login/pin',
      data: request.toJson(),
    );
    final json = jsonEncode(response.data);
    return LoginResponseDto.fromJson(json);
  }

  Future<bool> logout() async {
    await _secureClient.post<dynamic>('/api/v1/auth/logout');
    return true;
  }

  Future<UserDto> auth() async {
    final response = await _secureClient.get<dynamic>('/api/v1/auth/me');
    final json = jsonEncode(response.data);
    return UserDto.fromJson(json);
  }
}
