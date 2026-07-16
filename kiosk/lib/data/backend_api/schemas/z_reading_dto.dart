import 'package:dart_mappable/dart_mappable.dart';

import 'cashier_x_reading_dto.dart';

part 'z_reading_dto.mapper.dart';

@MappableClass()
class ItemSalesDto with ItemSalesDtoMappable {
  const ItemSalesDto({required this.name, this.quantity = 0, required this.amount});

  final String name;
  final int quantity;
  final double amount;
}

@MappableClass()
class ZReadingCashierBreakdownDto with ZReadingCashierBreakdownDtoMappable {
  const ZReadingCashierBreakdownDto({
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
class ZReadingDto with ZReadingDtoMappable {
  const ZReadingDto({
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
    this.paymentLedgers = const [],
    this.salesByItem = const [],
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
  final String? periodStart;
  final String? periodEnd;
  final String reportGeneratedAt;
  final double beginningBalance;
  final double endingBalance;
  final List<NameAmountDto> salesByPaymentMethod;
  final List<PaymentLedgerDto> paymentLedgers;
  final List<ItemSalesDto> salesByItem;
  final double totalSales;
  final int totalTransactions;
  final int completedTransactions;
  final int voidedTransactions;
  final int refundedTransactions;
  final List<NameAmountDto> discounts;
  final double totalDiscounts;
  final double vatSales;
  final double vatAmount;
  final double vatExemptSales;
  final double cashCollected;
  final int totalQuantitySold;
  final List<ZReadingCashierBreakdownDto> salesByCashier;

  static const fromJson = ZReadingDtoMapper.fromJson;
}

@MappableClass()
class ZReadingHistoryItemDto with ZReadingHistoryItemDtoMappable {
  const ZReadingHistoryItemDto({
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
  final String? periodStart;
  final String? periodEnd;
  final String generatedAt;
  final double totalSales;
  final double endingBalance;
  final int completedTransactions;

  static const fromJson = ZReadingHistoryItemDtoMapper.fromJson;
}
