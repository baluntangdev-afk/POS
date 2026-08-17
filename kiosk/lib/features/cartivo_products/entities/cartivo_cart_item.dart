import 'package:dart_mappable/dart_mappable.dart';

import 'cartivo_product.dart';

part 'cartivo_cart_item.mapper.dart';

@MappableClass()
class CartivoCartItem with CartivoCartItemMappable {
  const CartivoCartItem({required this.product, required this.quantity});

  final CartivoProduct product;
  final int quantity;

  double get totalPrice => product.price * quantity;
}
