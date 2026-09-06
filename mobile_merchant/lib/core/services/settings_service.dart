import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import '../config/env_config.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../utils/app_logger.dart';

/// Runtime-configurable API base URL.
///
/// Warmed up in `bootstrap()` before the UI builds so the very first request
/// already targets the right endpoint.
@lazySingleton
class SettingsService {
  SettingsService(this._storage, this._apiClient);

  final SecureStorage _storage;
  final ApiClient _apiClient;

  String _baseUrl = EnvConfig.apiBaseUrl;

  String get baseUrl => _baseUrl;

  bool get isUsingCustomEndpoint => _baseUrl != EnvConfig.apiBaseUrl;

  Future<void> init() async {
    try {
      final custom = await _storage.read(AppConfig.customApiBaseUrlKey);
      if (custom != null && custom.isNotEmpty) {
        _baseUrl = custom;
        _apiClient.updateBaseUrl(custom);
        AppLogger.logInfo('SettingsService: using custom endpoint $custom');
      }
    } catch (e, s) {
      AppLogger.logError('SettingsService.init', e, s);
    }
  }

  Future<void> setCustomBaseUrl(String url) async {
    _baseUrl = url;
    _apiClient.updateBaseUrl(url);
    await _storage.write(AppConfig.customApiBaseUrlKey, url);
  }

  Future<void> resetToDefault() async {
    _baseUrl = EnvConfig.apiBaseUrl;
    _apiClient.updateBaseUrl(EnvConfig.apiBaseUrl);
    await _storage.delete(AppConfig.customApiBaseUrlKey);
  }
}
