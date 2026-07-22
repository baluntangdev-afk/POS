class HistoryReceiptItem {
  final int saleItemId;
  final String productName;
  final int qty;
  final double unitPrice;
  final List<String> modifiers;

  const HistoryReceiptItem({
    required this.saleItemId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.modifiers,
  });

  double get lineTotal => qty * unitPrice;
}

class HistoryReceiptData {
  final int saleId;
  final DateTime createdAt;
  final String saleType;
  final String cashierName;
  final List<HistoryReceiptItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? reference;

  const HistoryReceiptData({
    required this.saleId,
    required this.createdAt,
    required this.saleType,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    required this.reference,
  });

  String get invoiceNumber => '#${saleId.toString().padLeft(6, '0')}';
}
