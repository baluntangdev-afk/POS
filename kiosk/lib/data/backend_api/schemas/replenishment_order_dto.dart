import 'package:dart_mappable/dart_mappable.dart';

import 'replenishment_order_item_dto.dart';

part 'replenishment_order_dto.mapper.dart';

@MappableClass()
class ReplenishmentOrderDto with ReplenishmentOrderDtoMappable {
  const ReplenishmentOrderDto({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerEmail,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  final String id;

  @MappableField(key: 'customer_id')
  final String customerId;

  @MappableField(key: 'customer_name')
  final String? customerName;

  @MappableField(key: 'customer_email')
  final String? customerEmail;

  final String status;
  final int total;
  final String currency;

  @MappableField(key: 'created_at')
  final DateTime createdAt;

  @MappableField(key: 'updated_at')
  final DateTime updatedAt;

  final List<ReplenishmentOrderItemDto>? items;

  static const fromJson = ReplenishmentOrderDtoMapper.fromJson;
  static const fromMap = ReplenishmentOrderDtoMapper.fromMap;
}
