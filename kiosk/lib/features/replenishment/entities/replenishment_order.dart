import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'replenishment_order_item.dart';
import 'replenishment_order_status.dart';

part 'replenishment_order.mapper.dart';

@MappableClass()
class ReplenishmentOrder with ReplenishmentOrderMappable {
  const ReplenishmentOrder({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerEmail,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.items = const IList.empty(),
  });

  final String id;
  final String customerId;
  final String? customerName;
  final String? customerEmail;
  final ReplenishmentOrderStatus status;
  final double total;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IList<ReplenishmentOrderItem> items;
}
