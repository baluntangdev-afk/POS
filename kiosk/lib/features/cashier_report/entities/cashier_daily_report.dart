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
  const CashLedgerSummary({required this.start, required this.end, required this.amount});

  final DateTime start;
  final DateTime end;
  final double amount;
}

@MappableClass()
class CashierDailyReport with CashierDailyReportMappable {
  const CashierDailyReport({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
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

  final String cashierName;
  final String terminalName;
  final String businessDate;
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

  CashLedgerSummary? get cashLedgerSummary {
    if (cashLedger.isEmpty) return null;
    final sorted = [...cashLedger]..sort((a, b) => a.time.compareTo(b.time));
    final amount = cashLedger.fold(0.0, (sum, entry) => sum + entry.amount);
    return CashLedgerSummary(start: sorted.first.time, end: sorted.last.time, amount: amount);
  }
}
