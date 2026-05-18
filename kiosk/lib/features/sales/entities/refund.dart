import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'payment.dart';
import 'refund_item.dart';

part 'refund.mapper.dart';

@MappableClass()
class Refund with RefundMappable {
  const Refund({
    required this.id,
    required this.docNumber,
    required this.docDate,
    required this.receiptId,
    required this.reason,
    required this.payment,
    required this.items,
  });

  final String id;
  final String docNumber;
  final DateTime docDate;
  final String receiptId;
  final String reason;
  final Payment payment;
  final IList<RefundItem> items;
}
