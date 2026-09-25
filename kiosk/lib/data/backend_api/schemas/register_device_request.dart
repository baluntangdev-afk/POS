import 'package:dart_mappable/dart_mappable.dart';

part 'register_device_request.mapper.dart';

/// Request body of the webhook-receiver's `POST /devices/register`.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class RegisterDeviceRequest with RegisterDeviceRequestMappable {
  const RegisterDeviceRequest({
    required this.platform,
    required this.installId,
    required this.name,
    required this.appName,
    required this.packageName,
    required this.appVersion,
    required this.platformVersion,
    required this.deviceModel,
    this.platformDetails = const {},
  });

  /// e.g. `windows`, `android`.
  final String platform;

  /// Stable per-install UUID that survives app restarts.
  final String installId;

  /// Human-readable device label shown to the merchant reviewer.
  final String name;

  /// App display name.
  final String appName;

  /// App package/bundle identifier.
  final String packageName;

  /// App version string, e.g. `1.4.0`.
  final String appVersion;

  /// OS version string, e.g. `Windows 11 Pro 24H2`.
  final String platformVersion;

  /// Device model, e.g. the PC's product name.
  final String deviceModel;

  /// Free-form platform-specific extras (computer name, device id, ...).
  final Map<String, dynamic> platformDetails;

  static const fromJson = RegisterDeviceRequestMapper.fromJson;
}
