import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'cartivo_order_item.dart';
import 'cartivo_order_status.dart';

part 'cartivo_order.mapper.dart';

@MappableClass()
class CartivoOrder with CartivoOrderMappable {
  const CartivoOrder({
    required this.id,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.items = const IList.empty(),
  });

  final String id;
  final CartivoOrderStatus status;
  final double total;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IList<CartivoOrderItem> items;
}
