import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../orders/data/models/device_token_dto.dart';
import '../../orders/data/models/merchant_orders_dto.dart';
import 'models/device_registration_dto.dart';
import 'models/register_device_request.dart';
import 'models/webhook_token_dto.dart';

/// Raised when the backend returns an error response on auth/device endpoints.
class MerchantApiException implements Exception {
  const MerchantApiException({
    required this.statusCode,
    required this.error,
    required this.message,
  });

  final int statusCode;
  final String error;
  final String message;

  @override
  String toString() => message;
}

/// Data source for webhook auth and device registration.
@lazySingleton
class MerchantApi {
  const MerchantApi(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /auth/token` — exchanges [webhookSecret] + [merchantId] for a
  /// short-lived JWT.
  Future<WebhookTokenDto> fetchToken(String merchantId) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.authToken,
      data: {
        'webhook_secret': EnvConfig.webhookSecret,
        'merchant_id': merchantId,
      },
    );
    _assertSuccess(response, const {200});
    return WebhookTokenDto.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  /// `POST /devices/register` — enrolls this device under [merchantId].
  ///
  /// [token] is the JWT from [fetchToken]. [request.installId] is sent as
  /// `Idempotency-Key` to make replays safe.
  Future<DeviceRegistrationDto> registerDevice({
    required RegisterDeviceRequest request,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.devicesRegister,
      data: request.toJson(),
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Idempotency-Key': request.installId,
        },
      ),
    );
    _assertSuccess(response, const {200, 202});
    return DeviceRegistrationDto.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  /// `POST /devices/token` — exchanges device credentials for a short-lived
  /// JWT used as the `Authorization: Bearer` header on the WebSocket handshake.
  Future<DeviceTokenDto> fetchDeviceToken({
    required String deviceId,
    required String deviceSecret,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.devicesToken,
      data: {'device_id': deviceId, 'device_secret': deviceSecret},
    );
    _assertSuccess(response, const {200});
    return DeviceTokenDto.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  /// `GET /merchant/orders` — returns paginated order events for [merchantId].
  ///
  /// [token] must be a valid webhook JWT. Returns an empty event list when the
  /// merchant has no events yet.
  Future<MerchantOrdersDto> fetchOrders({
    required String merchantId,
    required String token,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.merchantOrders,
      queryParameters: {'merchant_id': merchantId},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    _assertSuccess(response, const {200});
    return MerchantOrdersDto.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  void _assertSuccess(Response<dynamic> response, Set<int> expected) {
    final code = response.statusCode ?? 0;
    if (expected.contains(code)) return;
    final data = response.data;
    final error =
        (data is Map ? data['error'] : null) as String? ?? 'unknown_error';
    final message = (data is Map ? data['message'] : null) as String? ??
        'Request failed (HTTP $code).';
    throw MerchantApiException(
      statusCode: code,
      error: error,
      message: message,
    );
  }
}
