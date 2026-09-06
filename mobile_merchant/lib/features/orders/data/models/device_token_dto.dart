/// Response from `POST /devices/token`.
class DeviceTokenDto {
  const DeviceTokenDto({
    required this.deviceId,
    required this.merchantId,
    required this.token,
    required this.exp,
  });

  final String deviceId;
  final String merchantId;

  /// Short-lived JWT used as `Authorization: Bearer` on the WebSocket handshake.
  final String token;

  /// Unix timestamp (seconds) when [token] expires.
  final int exp;

  factory DeviceTokenDto.fromJson(Map<String, dynamic> json) => DeviceTokenDto(
    deviceId: json['device_id'] as String,
    merchantId: json['merchant_id'] as String,
    token: json['token'] as String,
    exp: json['exp'] as int,
  );
}
