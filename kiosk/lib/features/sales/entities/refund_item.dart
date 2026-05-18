import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

part 'refund_item.mapper.dart';

@MappableClass()
class RefundItem with RefundItemMappable {
  const RefundItem({
    required this.id,
    required this.receiptItemId,
    required this.sequence,
    required this.description,
    required this.quantity,
    required this.refundAmount,
    required this.isMain,
  });

  final String id;
  final String receiptItemId;
  final int sequence;
  final String description;
  final int quantity;
  final Decimal refundAmount;
  final bool isMain;
}
