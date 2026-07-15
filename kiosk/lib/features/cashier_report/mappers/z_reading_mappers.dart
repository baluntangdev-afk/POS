import '../../../data/backend_api/schemas/z_reading_dto.dart';
import '../entities/z_reading.dart';
import 'cashier_x_reading_mappers.dart';

extension ZReadingCashierBreakdownDTOMapper on ZReadingCashierBreakdownDto {
  ZReadingCashierBreakdown get toEntity => ZReadingCashierBreakdown(
    cashierId: cashierId,
    cashierName: cashierName,
    transactionCount: transactionCount,
    salesTotal: salesTotal,
  );
}

extension ZReadingDTOMapper on ZReadingDto {
  ZReading get toEntity => ZReading(
    id: id,
    zCounter: zCounter,
    terminalName: terminalName,
    closedByName: closedByName,
    authorizedByName: authorizedByName,
    periodStart: periodStart != null ? DateTime.parse(periodStart!) : null,
    periodEnd: periodEnd != null ? DateTime.parse(periodEnd!) : null,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
    beginningBalance: beginningBalance,
    endingBalance: endingBalance,
    salesByPaymentMethod: salesByPaymentMethod.map((e) => e.toEntity).toList(),
    salesByCategory: salesByCategory.map((e) => e.toEntity).toList(),
    totalSales: totalSales,
    totalTransactions: totalTransactions,
    completedTransactions: completedTransactions,
    voidedTransactions: voidedTransactions,
    refundedTransactions: refundedTransactions,
    discounts: discounts.map((e) => e.toEntity).toList(),
    totalDiscounts: totalDiscounts,
    vatSales: vatSales,
    vatAmount: vatAmount,
    vatExemptSales: vatExemptSales,
    cashCollected: cashCollected,
    totalQuantitySold: totalQuantitySold,
    salesByCashier: salesByCashier.map((e) => e.toEntity).toList(),
  );
}

extension ZReadingHistoryItemDTOMapper on ZReadingHistoryItemDto {
  ZReadingHistoryItem get toEntity => ZReadingHistoryItem(
    id: id,
    zCounter: zCounter,
    periodStart: periodStart != null ? DateTime.parse(periodStart!) : null,
    periodEnd: periodEnd != null ? DateTime.parse(periodEnd!) : null,
    generatedAt: DateTime.parse(generatedAt),
    totalSales: totalSales,
    endingBalance: endingBalance,
    completedTransactions: completedTransactions,
  );
}
