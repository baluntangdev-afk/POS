import 'package:dart_mappable/dart_mappable.dart';

part 'webhook_token_dto.mapper.dart';

/// Response of the webhook-receiver's `POST /auth/token`.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class WebhookTokenDto with WebhookTokenDtoMappable {
  const WebhookTokenDto({required this.merchantId, required this.token, required this.exp});

  final String merchantId;
  final String token;

  /// Unix timestamp (seconds) the token expires at.
  final int exp;

  static const fromJson = WebhookTokenDtoMapper.fromJson;
}
