import 'package:dart_mappable/dart_mappable.dart';

part 'webhook_auth_doc.mapper.dart';

@MappableClass()
class WebhookAuthDoc with WebhookAuthDocMappable {
  const WebhookAuthDoc({required this.merchantId, required this.token, required this.expiresAt});

  final String merchantId;
  final String token;
  final DateTime expiresAt;

  static const fromJson = WebhookAuthDocMapper.fromJson;
}
