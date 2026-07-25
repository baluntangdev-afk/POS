import '../../../reports/entities/report_data.dart';

class XReadingData {
  final int? id; // null = live/unclosed preview, set once closed
  final String cashierName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final double totalSales;
  final int transactionCount;
  final int voidedCount;
  final int refundedCount;
  final List<PaymentBreakdown> paymentBreakdown;
  final List<TopProductData> topProducts;

  const XReadingData({
    required this.id,
    required this.cashierName,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.totalSales,
    required this.transactionCount,
    required this.voidedCount,
    required this.refundedCount,
    required this.paymentBreakdown,
    required this.topProducts,
  });
}
