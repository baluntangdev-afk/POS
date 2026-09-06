import 'package:freezed_annotation/freezed_annotation.dart';

part 'webhook_token.freezed.dart';

/// Short-lived JWT returned by `POST /auth/token`.
@freezed
abstract class WebhookToken with _$WebhookToken {
  const factory WebhookToken({
    required String merchantId,
    required String merchantName,
    required String token,

    /// Unix timestamp (seconds) at which the token expires.
    required int exp,
  }) = _WebhookToken;
}
