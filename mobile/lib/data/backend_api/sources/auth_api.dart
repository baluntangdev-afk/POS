import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';
import '../api_clients.dart';
import '../schemas/webhook_token_dto.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final httpClient = ref.watch(dpoSocketApiClientProvider);
  final env = ref.watch(appEnvProvider);
  return AuthApi(httpClient, env);
});

class AuthApi {
  const AuthApi(this._httpClient, this._env);

  final Dio _httpClient;
  final AppEnv _env;

  Future<WebhookTokenDto> fetchToken(String merchantId) async {
    final response = await _httpClient.post<dynamic>(
      '/auth/token',
      data: {
        'webhook_secret': _env.webhookSecret,
        'client_id': _env.clientId,
        'merchant_id': merchantId,
      },
    );
    return WebhookTokenDto.fromJson(jsonEncode(response.data));
  }
}
