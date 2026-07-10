import 'package:dart_mappable/dart_mappable.dart';

part 'cashier_x_reading.mapper.dart';

@MappableClass()
class NameAmount with NameAmountMappable {
  const NameAmount({required this.name, required this.amount});

  final String name;
  final double amount;
}

@MappableClass()
class PaymentLedgerEntry with PaymentLedgerEntryMappable {
  const PaymentLedgerEntry({required this.time, required this.reference, required this.amount});

  final DateTime time;
  final String? reference;
  final double amount;
}

class PaymentLedgerDateGroup {
  const PaymentLedgerDateGroup({required this.date, required this.entries});

  final DateTime date;
  final List<PaymentLedgerEntry> entries;
}

@MappableClass()
class PaymentLedger with PaymentLedgerMappable {
  const PaymentLedger({
    required this.name,
    required this.total,
    required this.count,
    required this.entries,
  });

  final String name;
  final double total;
  final int count;
  final List<PaymentLedgerEntry> entries;

  /// Entries bucketed by local calendar date, oldest date first. Entries within each
  /// bucket keep the ascending order they arrive in from the backend.
  List<PaymentLedgerDateGroup> get entriesByDate {
    final groups = <DateTime, List<PaymentLedgerEntry>>{};
    for (final entry in entries) {
      final local = entry.time.toLocal();
      final dateKey = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(dateKey, () => []).add(entry);
    }
    final sortedDates = groups.keys.toList()..sort();
    return [
      for (final date in sortedDates) PaymentLedgerDateGroup(date: date, entries: groups[date]!),
    ];
  }
}

@MappableClass()
class CashierXReading with CashierXReadingMappable {
  const CashierXReading({
    this.id,
    required this.cashierName,
    required this.terminalName,
    required this.periodStart,
    required this.periodEnd,
    required this.reportGeneratedAt,
    required this.salesByPaymentMethod,
    required this.paymentLedgers,
    required this.totalSales,
    required this.totalTransactions,
    required this.completedTransactions,
    required this.voidedTransactions,
    required this.refundedTransactions,
    required this.discounts,
    required this.totalDiscounts,
    required this.vatSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.cashCollected,
    required this.averageSale,
    required this.highestSale,
    required this.lowestSale,
    required this.totalQuantitySold,
  });

  final String? id;
  final String cashierName;
  final String terminalName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime reportGeneratedAt;
  final List<NameAmount> salesByPaymentMethod;
  final List<PaymentLedger> paymentLedgers;
  final double totalSales;
  final int totalTransactions;
  final int completedTransactions;
  final int voidedTransactions;
  final int refundedTransactions;
  final List<NameAmount> discounts;
  final double totalDiscounts;
  final double vatSales;
  final double vatAmount;
  final double vatExemptSales;
  final double cashCollected;
  final double averageSale;
  final double highestSale;
  final double lowestSale;
  final int totalQuantitySold;
}

@MappableClass()
class CashierXReadingHistoryItem with CashierXReadingHistoryItemMappable {
  const CashierXReadingHistoryItem({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.totalSales,
    required this.completedTransactions,
  });

  final String id;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime generatedAt;
  final double totalSales;
  final int completedTransactions;
}
