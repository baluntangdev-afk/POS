import 'package:dart_mappable/dart_mappable.dart';

import 'replenishment_product.dart';

part 'replenishment_cart_item.mapper.dart';

@MappableClass()
class ReplenishmentCartItem with ReplenishmentCartItemMappable {
  const ReplenishmentCartItem({required this.product, required this.quantity});

  final ReplenishmentProduct product;
  final int quantity;

  double get totalPrice => product.price * quantity;
}
