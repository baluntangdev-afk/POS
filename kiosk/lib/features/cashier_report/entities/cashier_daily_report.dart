import 'package:dart_mappable/dart_mappable.dart';

part 'cashier_daily_report.mapper.dart';

@MappableClass()
class ProductSalesLine with ProductSalesLineMappable {
  const ProductSalesLine({required this.quantity, required this.productName, required this.amount});

  final int quantity;
  final String productName;
  final double amount;
}

@MappableClass()
class CashLedgerEntry with CashLedgerEntryMappable {
  const CashLedgerEntry({required this.time, required this.reference, required this.amount});

  final DateTime time;
  final String? reference;
  final double amount;
}

class CashLedgerSummary {
  const CashLedgerSummary({
    required this.date,
    required this.start,
    required this.end,
    required this.amount,
  });

  final DateTime date;
  final DateTime start;
  final DateTime end;
  final double amount;
}

@MappableClass()
class CashierDailyReport with CashierDailyReportMappable {
  const CashierDailyReport({
    this.id,
    required this.cashierName,
    required this.terminalName,
    required this.periodStart,
    required this.periodEnd,
    required this.reportGeneratedAt,
    required this.grossSales,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.zeroRatedSales,
    required this.netOfTax,
    required this.transactionCount,
    required this.totalQuantity,
    required this.totalCashSales,
    required this.cashSalesCount,
    required this.salesByProduct,
    required this.cashLedger,
  });

  final String? id;
  final String cashierName;
  final String terminalName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime reportGeneratedAt;
  final double grossSales;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final double zeroRatedSales;
  final double netOfTax;
  final int transactionCount;
  final int totalQuantity;
  final double totalCashSales;
  final int cashSalesCount;
  final List<ProductSalesLine> salesByProduct;
  final List<CashLedgerEntry> cashLedger;

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
          start: (groups[date]!..sort((a, b) => a.time.compareTo(b.time))).first.time,
          end: groups[date]!.last.time,
          amount: groups[date]!.fold(0.0, (sum, entry) => sum + entry.amount),
        ),
    ];
  }
}

@MappableClass()
class CashierDailyReportHistoryItem with CashierDailyReportHistoryItemMappable {
  const CashierDailyReportHistoryItem({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.grossSales,
    required this.transactionCount,
  });

  final String id;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime generatedAt;
  final double grossSales;
  final int transactionCount;
}
