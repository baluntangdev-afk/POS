import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';

final healthApiProvider = Provider<HealthApi>((ref) {
  final env = ref.watch(appEnvProvider);
  return HealthApi(env.backendApiBaseUrl);
});

class HealthApi {
  HealthApi(String baseUrl)
      : _client = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ),
        );

  final Dio _client;

  Future<bool> isAlive() async {
    try {
      final response = await _client.get<dynamic>('/api/v1/health/live');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
