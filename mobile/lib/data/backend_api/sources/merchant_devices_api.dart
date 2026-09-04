import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../errors/api_call.dart';
import '../schemas/device_registration_dto.dart';
import '../schemas/register_device_request.dart';

final merchantDevicesApiProvider = Provider<MerchantDevicesApi>((ref) {
  final httpClient = ref.watch(dpoSocketApiClientProvider);
  return MerchantDevicesApi(httpClient);
});

class MerchantDevicesApi with ApiCall {
  const MerchantDevicesApi(this._httpClient);

  final Dio _httpClient;

  Future<DeviceRegistrationDto> registerDevice(
    RegisterDeviceRequest request,
  ) => guard(() async {
    final response = await _httpClient.post<dynamic>(
      '/devices/register',
      data: request.toMap(),
      options: Options(headers: {'Idempotency-Key': request.installId}),
    );
    return DeviceRegistrationDto.fromJson(jsonEncode(response.data));
  });
}
