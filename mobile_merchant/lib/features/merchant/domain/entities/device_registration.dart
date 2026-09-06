import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_registration.freezed.dart';

/// Result of `POST /devices/register`.
///
/// 202 — new enrollment: [deviceSecret] present, review fields absent.
/// 200 — duplicate matched on install_id: [deviceSecret] absent, review fields present.
@freezed
abstract class DeviceRegistration with _$DeviceRegistration {
  const factory DeviceRegistration({
    required String deviceId,
    required String status,
    String? deviceSecret,
    String? merchantId,
    String? merchantName,
    String? requestedAt,
    String? reviewedAt,
    String? reviewNote,
  }) = _DeviceRegistration;
}
