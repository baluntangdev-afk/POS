import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../errors/api_call.dart';
import '../schemas/device_token_dto.dart';

final deviceTokenApiProvider = Provider<DeviceTokenApi>((ref) {
  return DeviceTokenApi(ref.watch(deviceTokenApiClientProvider));
});

class DeviceTokenApi with ApiCall {
  const DeviceTokenApi(this._httpClient);

  final Dio _httpClient;

  /// `POST /devices/token` — exchanges the persisted device credentials for a
  /// short-lived bearer token. Authenticates from the request body, so it runs
  /// on a client without the `/auth/token` bearer interceptor. Throws an
  /// `ApiException` on any failure.
  Future<DeviceTokenDto> fetchToken({
    required String deviceId,
    required String deviceSecret,
  }) => guard(() async {
    final response = await _httpClient.post<dynamic>(
      '/devices/token',
      data: {'device_id': deviceId, 'device_secret': deviceSecret},
    );
    return DeviceTokenDto.fromJson(jsonEncode(response.data));
  });
}
