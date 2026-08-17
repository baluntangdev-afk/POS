import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_order_item.mapper.dart';

@MappableClass()
class CartivoOrderItem with CartivoOrderItemMappable {
  const CartivoOrderItem({
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
