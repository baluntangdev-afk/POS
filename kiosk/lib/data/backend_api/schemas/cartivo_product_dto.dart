import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_product_dto.mapper.dart';

@MappableClass()
class CartivoProductDto with CartivoProductDtoMappable {
  const CartivoProductDto({
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

  static const fromJson = CartivoProductDtoMapper.fromJson;
  static const fromMap = CartivoProductDtoMapper.fromMap;
}
