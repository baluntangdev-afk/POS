import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/webhook_token.dart';

part 'webhook_token_dto.freezed.dart';
part 'webhook_token_dto.g.dart';

@freezed
abstract class WebhookTokenDto with _$WebhookTokenDto {
  const factory WebhookTokenDto({
    @JsonKey(name: 'merchant_id') required String merchantId,
    @JsonKey(name: 'merchant_name') required String merchantName,
    required String token,
    required int exp,
  }) = _WebhookTokenDto;

  factory WebhookTokenDto.fromJson(Map<String, dynamic> json) =>
      _$WebhookTokenDtoFromJson(json);
}

extension WebhookTokenDtoX on WebhookTokenDto {
  WebhookToken toDomain() => WebhookToken(
        merchantId: merchantId,
        merchantName: merchantName,
        token: token,
        exp: exp,
      );
}
