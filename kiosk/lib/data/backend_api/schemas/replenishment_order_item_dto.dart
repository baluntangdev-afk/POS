import 'package:dart_mappable/dart_mappable.dart';

part 'replenishment_order_item_dto.mapper.dart';

@MappableClass()
class ReplenishmentOrderItemDto with ReplenishmentOrderItemDtoMappable {
  const ReplenishmentOrderItemDto({
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

  static const fromJson = ReplenishmentOrderItemDtoMapper.fromJson;
  static const fromMap = ReplenishmentOrderItemDtoMapper.fromMap;
}
