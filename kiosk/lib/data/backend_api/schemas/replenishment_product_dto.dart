import 'package:dart_mappable/dart_mappable.dart';

part 'replenishment_product_dto.mapper.dart';

@MappableClass()
class ReplenishmentProductDto with ReplenishmentProductDtoMappable {
  const ReplenishmentProductDto({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int price;
  final String currency;

  @MappableField(key: 'created_at')
  final DateTime createdAt;

  static const fromJson = ReplenishmentProductDtoMapper.fromJson;
  static const fromMap = ReplenishmentProductDtoMapper.fromMap;
}
