import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/device_registration.dart';

part 'device_registration_dto.freezed.dart';
part 'device_registration_dto.g.dart';

@freezed
abstract class DeviceRegistrationDto with _$DeviceRegistrationDto {
  const factory DeviceRegistrationDto({
    @JsonKey(name: 'device_id') required String deviceId,
    required String status,
    @JsonKey(name: 'device_secret') String? deviceSecret,
    @JsonKey(name: 'merchant_id') String? merchantId,
    @JsonKey(name: 'merchant_name') String? merchantName,
    @JsonKey(name: 'requested_at') String? requestedAt,
    @JsonKey(name: 'reviewed_at') String? reviewedAt,
    @JsonKey(name: 'review_note') String? reviewNote,
  }) = _DeviceRegistrationDto;

  factory DeviceRegistrationDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegistrationDtoFromJson(json);
}

extension DeviceRegistrationDtoX on DeviceRegistrationDto {
  DeviceRegistration toDomain() => DeviceRegistration(
        deviceId: deviceId,
        status: status,
        deviceSecret: deviceSecret,
        merchantId: merchantId,
        merchantName: merchantName,
        requestedAt: requestedAt,
        reviewedAt: reviewedAt,
        reviewNote: reviewNote,
      );
}
