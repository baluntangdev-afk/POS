import 'package:dart_mappable/dart_mappable.dart';

part 'replenishment_payment_dto.mapper.dart';

@MappableClass()
class ReplenishmentPaymentDto with ReplenishmentPaymentDtoMappable {
  const ReplenishmentPaymentDto({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  @MappableField(key: 'order_id')
  final String orderId;

  final int amount;
  final String currency;
  final String status;

  @MappableField(key: 'created_at')
  final DateTime createdAt;

  @MappableField(key: 'updated_at')
  final DateTime updatedAt;

  static const fromJson = ReplenishmentPaymentDtoMapper.fromJson;
  static const fromMap = ReplenishmentPaymentDtoMapper.fromMap;
}
