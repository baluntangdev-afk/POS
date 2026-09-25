import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../errors/api_call.dart';
import '../schemas/device_registration_dto.dart';
import '../schemas/register_device_request.dart';

final merchantDevicesApiProvider = Provider<MerchantDevicesApi>((ref) {
  final httpClient = ref.watch(ordersEventsApiClientProvider);
  return MerchantDevicesApi(httpClient);
});

class MerchantDevicesApi with ApiCall {
  const MerchantDevicesApi(this._httpClient);

  final Dio _httpClient;

  /// `POST /devices/register`. The `Idempotency-Key` is the stable install
  /// id, so re-registering replays the current record instead of creating a
  /// new enrollment — which is also how the approval status is re-checked.
  Future<DeviceRegistrationDto> registerDevice(RegisterDeviceRequest request) => guard(() async {
    final response = await _httpClient.post<dynamic>(
      '/devices/register',
      data: request.toMap(),
      options: Options(headers: {'Idempotency-Key': request.installId}),
    );
    return DeviceRegistrationDto.fromJson(jsonEncode(response.data));
  });
}
