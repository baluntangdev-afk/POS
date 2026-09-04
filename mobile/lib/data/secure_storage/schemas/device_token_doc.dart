import 'package:dart_mappable/dart_mappable.dart';

part 'device_token_doc.mapper.dart';

/// Caches the bearer token issued by the webhook-receiver's `/devices/token`,
/// used to authenticate the live orders WebSocket handshake.
@MappableClass()
class DeviceTokenDoc with DeviceTokenDocMappable {
  const DeviceTokenDoc({
    required this.merchantId,
    required this.token,
    required this.expiresAt,
  });

  final String merchantId;
  final String token;
  final DateTime expiresAt;

  static const fromJson = DeviceTokenDocMapper.fromJson;
}
