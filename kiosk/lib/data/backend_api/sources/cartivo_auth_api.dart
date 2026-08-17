import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/cartivo_auth_exception.dart';
import '../api_clients.dart';
import '../schemas/cartivo_auth_response_dto.dart';
import '../schemas/cartivo_login_request_dto.dart';
import '../schemas/cartivo_register_request_dto.dart';

final cartivoAuthApiProvider = Provider<CartivoAuthApi>((ref) {
  final client = ref.watch(cartivoAuthApiClientProvider);
  return CartivoAuthApi(client);
});

class CartivoAuthApi {
  const CartivoAuthApi(this._client);

  final Dio _client;

  Future<CartivoAuthResponseDto> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final request = CartivoRegisterRequestDto(email: email, password: password, name: name);
    try {
      final response = await _client.post<dynamic>('/api/auth/register', data: request.toJson());
      return CartivoAuthResponseDto.fromJson(jsonEncode(response.data));
    } on DioException catch (e) {
      throw _mapError(e, isRegister: true);
    }
  }

  Future<CartivoAuthResponseDto> login({required String email, required String password}) async {
    final request = CartivoLoginRequestDto(email: email, password: password);
    try {
      final response = await _client.post<dynamic>('/api/auth/login', data: request.toJson());
      return CartivoAuthResponseDto.fromJson(jsonEncode(response.data));
    } on DioException catch (e) {
      throw _mapError(e, isRegister: false);
    }
  }

  CartivoAuthException _mapError(DioException e, {required bool isRegister}) {
    if (e.type == DioExceptionType.connectionError) {
      return CartivoAuthException(
        CartivoAuthErrorKind.network,
        'Unable to reach the server. Please check your connection and try again.',
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return CartivoAuthException(
        CartivoAuthErrorKind.network,
        'Request timed out. Please try again.',
      );
    }

    final statusCode = e.response?.statusCode;
    final backendMessage = _extractBackendError(e.response?.data);

    switch (statusCode) {
      case 400:
        return CartivoAuthException(
          CartivoAuthErrorKind.validation,
          backendMessage ?? 'Please check your email and password and try again.',
        );
      case 409:
        return CartivoAuthException(
          CartivoAuthErrorKind.emailTaken,
          backendMessage ?? 'This email is already registered. Try logging in instead.',
        );
      case 401:
        return CartivoAuthException(
          CartivoAuthErrorKind.invalidCredentials,
          'Invalid email or password. Please check your credentials and try again.',
        );
      case 429:
        return CartivoAuthException(
          CartivoAuthErrorKind.rateLimited,
          'Too many attempts. Please wait a moment and try again.',
        );
      default:
        return CartivoAuthException(
          CartivoAuthErrorKind.unknown,
          backendMessage ?? 'Something went wrong. Please try again.',
        );
    }
  }

  String? _extractBackendError(dynamic data) {
    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) map = decoded;
      } catch (_) {}
    }
    if (map == null) return null;
    final error = map['error']?.toString();
    if (error != null && error.isNotEmpty) return error;
    final message = map['message']?.toString();
    if (message != null && message.isNotEmpty) return message;
    return null;
  }
}
