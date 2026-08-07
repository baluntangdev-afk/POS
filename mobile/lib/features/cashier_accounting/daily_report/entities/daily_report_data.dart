import '../../../reports/entities/report_data.dart';

class CashLedgerEntry {
  final DateTime time;
  final String? reference;
  final double amount;
  const CashLedgerEntry({required this.time, required this.reference, required this.amount});
}

class CashLedgerSummary {
  final DateTime date;
  final List<CashLedgerEntry> entries;
  final double total;
  const CashLedgerSummary({required this.date, required this.entries, required this.total});
}

class DailyReportData {
  final int? id; // null = live/unclosed preview, set once closed
  final String cashierName;
  final DateTime? periodStart; // null when no transaction has happened yet
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

  /// Cash ledger entries summarized per local calendar date, oldest date first.
  List<CashLedgerSummary> get cashLedgerSummariesByDate {
    final groups = <DateTime, List<CashLedgerEntry>>{};
    for (final entry in cashLedger) {
      final local = entry.time.toLocal();
      final dateKey = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(dateKey, () => []).add(entry);
    }
    final sortedDates = groups.keys.toList()..sort();
    return [
      for (final date in sortedDates)
        CashLedgerSummary(
          date: date,
          entries: groups[date]!..sort((a, b) => a.time.compareTo(b.time)),
          total: groups[date]!.fold(0.0, (sum, e) => sum + e.amount),
        ),
    ];
  }
}
