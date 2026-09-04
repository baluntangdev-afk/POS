import 'package:dart_mappable/dart_mappable.dart';

part 'device_token_dto.mapper.dart';

/// Response of the webhook-receiver's `POST /devices/token` — exchanges the
/// stored `device_id` / `device_secret` for a bearer token used on the live
/// orders WebSocket handshake. Separate from `WebhookTokenDto` (`/auth/token`),
/// which authenticates the orders REST API.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class DeviceTokenDto with DeviceTokenDtoMappable {
  const DeviceTokenDto({
    required this.deviceId,
    required this.merchantId,
    required this.token,
    required this.exp,
  });

  /// Echoes the `device_id` the token was minted for (`dev_...`).
  final String deviceId;

  final String merchantId;
  final String token;

  /// Unix timestamp (seconds) the token expires at.
  final int exp;

  static const fromJson = DeviceTokenDtoMapper.fromJson;
}
