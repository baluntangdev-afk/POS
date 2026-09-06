import 'order_event_dto.dart';

class MerchantOrdersDto {
  const MerchantOrdersDto({
    required this.merchantId,
    required this.events,
  });

  final String merchantId;
  final List<OrderEventDto> events;

  factory MerchantOrdersDto.fromJson(Map<String, dynamic> json) =>
      MerchantOrdersDto(
        merchantId: json['merchant_id'] as String,
        events: (json['events'] as List)
            .map((e) => OrderEventDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
