import '../../../reports/entities/report_data.dart';

class CashLedgerEntry {
  final DateTime date;
  final double total;
  const CashLedgerEntry({required this.date, required this.total});
}

class DailyReportData {
  final int? id; // null = live/unclosed preview, set once closed
  final String cashierName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final double grossSales;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final double netOfTax;
  final int transactionCount;
  final int totalQtySold;
  final double cashSalesTotal;
  final int cashSalesCount;
  final List<TopProductData> salesByProduct;
  final List<CashLedgerEntry> cashLedger;

  const DailyReportData({
    required this.id,
    required this.cashierName,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.grossSales,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.netOfTax,
    required this.transactionCount,
    required this.totalQtySold,
    required this.cashSalesTotal,
    required this.cashSalesCount,
    required this.salesByProduct,
    required this.cashLedger,
  });
}
