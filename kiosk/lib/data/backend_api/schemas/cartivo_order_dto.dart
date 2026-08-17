import 'package:dart_mappable/dart_mappable.dart';

import 'cartivo_order_item_dto.dart';

part 'cartivo_order_dto.mapper.dart';

@MappableClass()
class CartivoOrderDto with CartivoOrderDtoMappable {
  const CartivoOrderDto({
    required this.id,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  final String id;
  final String status;
  final int total;
  final String currency;

  @MappableField(key: 'created_at')
  final DateTime createdAt;

  @MappableField(key: 'updated_at')
  final DateTime updatedAt;

  final List<CartivoOrderItemDto>? items;

  static const fromJson = CartivoOrderDtoMapper.fromJson;
  static const fromMap = CartivoOrderDtoMapper.fromMap;
}
