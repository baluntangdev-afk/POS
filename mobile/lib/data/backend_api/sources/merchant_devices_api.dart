import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/device_registration_dto.dart';
import '../schemas/register_device_request.dart';

final merchantDevicesApiProvider = Provider<MerchantDevicesApi>((ref) {
  final httpClient = ref.watch(dpoSocketApiClientProvider);
  return MerchantDevicesApi(httpClient);
});

class MerchantDevicesApi {
  const MerchantDevicesApi(this._httpClient);

  final Dio _httpClient;

  /// `POST /devices/register` — enrols this device with the backend and
  /// returns the (initially `pending`) registration record.
  ///
  /// The `install_id` doubles as the `Idempotency-Key` so a retry replays the
  /// original 202 (including the one-time `device_secret`) instead of falling
  /// through to the 200 "already exists" shape, which omits the secret.
  Future<DeviceRegistrationDto> registerDevice(
    RegisterDeviceRequest request,
  ) async {
    final response = await _httpClient.post<dynamic>(
      '/devices/register',
      data: request.toMap(),
      options: Options(headers: {'Idempotency-Key': request.installId}),
    );
    return DeviceRegistrationDto.fromJson(jsonEncode(response.data));
  }
}
