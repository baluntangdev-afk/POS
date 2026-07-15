import 'package:dart_mappable/dart_mappable.dart';

import 'cashier_x_reading.dart';

part 'z_reading.mapper.dart';

@MappableClass()
class ZReadingCashierBreakdown with ZReadingCashierBreakdownMappable {
  const ZReadingCashierBreakdown({
    required this.cashierId,
    required this.cashierName,
    required this.transactionCount,
    required this.salesTotal,
  });

  final int cashierId;
  final String cashierName;
  final int transactionCount;
  final double salesTotal;
}

@MappableClass()
class ZReading with ZReadingMappable {
  const ZReading({
    this.id,
    this.zCounter,
    required this.terminalName,
    this.closedByName,
    this.authorizedByName,
    required this.periodStart,
    required this.periodEnd,
    required this.reportGeneratedAt,
    required this.beginningBalance,
    required this.endingBalance,
    required this.salesByPaymentMethod,
    required this.salesByCategory,
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
    required this.totalQuantitySold,
    required this.salesByCashier,
  });

  final String? id;
  final int? zCounter;
  final String terminalName;
  final String? closedByName;
  final String? authorizedByName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime reportGeneratedAt;
  final double beginningBalance;
  final double endingBalance;
  final List<NameAmount> salesByPaymentMethod;
  final List<NameAmount> salesByCategory;
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
  final int totalQuantitySold;
  final List<ZReadingCashierBreakdown> salesByCashier;
}

@MappableClass()
class ZReadingHistoryItem with ZReadingHistoryItemMappable {
  const ZReadingHistoryItem({
    required this.id,
    required this.zCounter,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.totalSales,
    required this.endingBalance,
    required this.completedTransactions,
  });

  final String id;
  final int zCounter;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime generatedAt;
  final double totalSales;
  final double endingBalance;
  final int completedTransactions;
}
