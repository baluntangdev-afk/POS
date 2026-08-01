import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';

final healthApiProvider = Provider<HealthApi>((ref) {
  final env = ref.watch(appEnvProvider);
  return HealthApi(env.backendApiBaseUrl);
});

class HealthCheckResult {
  const HealthCheckResult({required this.isAlive, this.error});
  final bool isAlive;
  final String? error;
}

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

  Future<HealthCheckResult> checkAlive() async {
    try {
      final response = await _client.get<dynamic>('/api/v1/health/live');
      if (response.statusCode == 200) {
        return const HealthCheckResult(isAlive: true);
      }
      return HealthCheckResult(
        isAlive: false,
        error: 'HTTP ${response.statusCode}',
      );
    } on DioException catch (e) {
      final msg = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout =>
          'Connection timed out',
        DioExceptionType.connectionError => 'Cannot connect to backend',
        _ => e.message ?? e.type.name,
      };
      return HealthCheckResult(isAlive: false, error: msg);
    } catch (e) {
      return HealthCheckResult(isAlive: false, error: e.toString());
    }
  }
}
