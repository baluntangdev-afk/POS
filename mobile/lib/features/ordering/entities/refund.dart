import 'refund_item.dart';

class Refund {
  final int id;
  final String docNumber;
  final DateTime docDate;
  final int receiptId;
  final String reason;
  final String method;
  final List<RefundItem> items;

  const Refund({
    required this.id,
    required this.docNumber,
    required this.docDate,
    required this.receiptId,
    required this.reason,
    required this.method,
    required this.items,
  });

  Refund copyWith({int? id, String? docNumber}) => Refund(
        id: id ?? this.id,
        docNumber: docNumber ?? this.docNumber,
        docDate: docDate,
        receiptId: receiptId,
        reason: reason,
        method: method,
        items: items,
      );
}
