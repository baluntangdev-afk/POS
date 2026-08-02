import '../../../reports/entities/report_data.dart';

/// A single cashier's contribution to a store-wide Z-Reading period.
class CashierSalesBreakdown {
  final String cashierName;
  final double total;
  final int transactionCount;

  const CashierSalesBreakdown({
    required this.cashierName,
    required this.total,
    required this.transactionCount,
  });
}

/// Store-wide end-of-day reading. Unlike X-Reading/Daily Report, Z-Reading is
/// NOT scoped to a single cashier — it aggregates across the whole store.
class ZReadingData {
  final int? id; // null = live/unclosed preview, set once closed
  final int zCounter;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final String closedByName;
  final String authorizedByName;
  final double beginningBalance;
  final double endingBalance;
  final double totalSales;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final int transactionCount;
  final int completedCount;
  final int voidedCount;
  final int refundedCount;
  final double discountTotal;
  final double cashCollected;
  final int totalQtySold;
  final List<PaymentBreakdown> paymentBreakdown;
  final List<PaymentLedger> paymentLedgers;
  final List<CashierSalesBreakdown> salesByCashier;
  final List<NameAmount> discounts;

  const ZReadingData({
    required this.id,
    required this.zCounter,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.closedByName,
    required this.authorizedByName,
    required this.beginningBalance,
    required this.endingBalance,
    required this.totalSales,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.transactionCount,
    required this.completedCount,
    required this.voidedCount,
    required this.refundedCount,
    required this.discountTotal,
    required this.cashCollected,
    required this.totalQtySold,
    required this.paymentBreakdown,
    required this.paymentLedgers,
    required this.salesByCashier,
    required this.discounts,
  });
}
