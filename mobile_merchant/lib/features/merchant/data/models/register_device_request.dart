import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_device_request.freezed.dart';
part 'register_device_request.g.dart';

@freezed
abstract class RegisterDeviceRequest with _$RegisterDeviceRequest {
  const factory RegisterDeviceRequest({
    required String platform,
    @JsonKey(name: 'install_id') required String installId,
    required String name,
    @JsonKey(name: 'app_version') required String appVersion,
    @JsonKey(name: 'platform_version') required String platformVersion,
    @JsonKey(name: 'device_model') required String deviceModel,
    @Default({}) @JsonKey(name: 'platform_details') Map<String, dynamic> platformDetails,
  }) = _RegisterDeviceRequest;

  factory RegisterDeviceRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterDeviceRequestFromJson(json);
}
