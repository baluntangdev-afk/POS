import '../../../reports/entities/report_data.dart';

class XReadingData {
  final int? id; // null = live/unclosed preview, set once closed
  final String cashierName;
  final DateTime? periodStart; // null when no transaction has happened yet
  final DateTime periodEnd;
  final DateTime generatedAt;
  final double totalSales;
  final int transactionCount;
  final int voidedCount;
  final int refundedCount;
  final List<PaymentBreakdown> paymentBreakdown;
  final List<TopProductData> topProducts;
  final List<PaymentLedger> paymentLedgers;
  final List<NameAmount> discounts;
  final double totalDiscounts;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final double averageSale;
  final double highestSale;
  final double lowestSale;
  final double cashCollected;

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
    required this.paymentLedgers,
    required this.discounts,
    required this.totalDiscounts,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.averageSale,
    required this.highestSale,
    required this.lowestSale,
    required this.cashCollected,
  });
}
