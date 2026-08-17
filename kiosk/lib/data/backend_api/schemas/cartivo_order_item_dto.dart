import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_order_item_dto.mapper.dart';

@MappableClass()
class CartivoOrderItemDto with CartivoOrderItemDtoMappable {
  const CartivoOrderItemDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  @MappableField(key: 'product_id')
  final String productId;

  @MappableField(key: 'product_name')
  final String productName;

  final int quantity;
  final int price;

  static const fromJson = CartivoOrderItemDtoMapper.fromJson;
  static const fromMap = CartivoOrderItemDtoMapper.fromMap;
}
