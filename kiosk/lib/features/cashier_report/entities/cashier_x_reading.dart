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
}

@MappableClass()
class CashierXReading with CashierXReadingMappable {
  const CashierXReading({
    required this.cashierName,
    required this.terminalName,
    required this.businessDate,
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

  final String cashierName;
  final String terminalName;
  final String businessDate;
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
