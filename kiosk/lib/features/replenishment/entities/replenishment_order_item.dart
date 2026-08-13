import 'package:dart_mappable/dart_mappable.dart';

part 'replenishment_order_item.mapper.dart';

@MappableClass()
class ReplenishmentOrderItem with ReplenishmentOrderItemMappable {
  const ReplenishmentOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double price;

  double get totalPrice => price * quantity;
}
