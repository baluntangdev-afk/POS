import 'cart_item.dart';

class SaleReceiptData {
  final int saleId;
  final DateTime createdAt;
  final String saleType;
  final List<CartItem> items;
  final double subtotal;
  final double totalDiscount;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? reference;
  final String cashierName;

  const SaleReceiptData({
    required this.saleId,
    required this.createdAt,
    required this.saleType,
    required this.items,
    required this.subtotal,
    required this.totalDiscount,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    required this.reference,
    required this.cashierName,
  });
}
