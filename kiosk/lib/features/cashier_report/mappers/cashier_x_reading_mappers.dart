import '../../../data/backend_api/schemas/cashier_x_reading_dto.dart';
import '../entities/cashier_x_reading.dart';

extension NameAmountDTOMapper on NameAmountDto {
  NameAmount get toEntity => NameAmount(name: name, amount: amount);
}

extension PaymentLedgerEntryDTOMapper on PaymentLedgerEntryDto {
  PaymentLedgerEntry get toEntity =>
      PaymentLedgerEntry(time: DateTime.parse(time), reference: reference, amount: amount);
}

extension PaymentLedgerDTOMapper on PaymentLedgerDto {
  PaymentLedger get toEntity => PaymentLedger(
    name: name,
    total: total,
    count: count,
    entries: entries.map((e) => e.toEntity).toList(),
  );
}

extension CashierXReadingDTOMapper on CashierXReadingDto {
  CashierXReading get toEntity => CashierXReading(
    cashierName: cashierName,
    terminalName: terminalName,
    businessDate: businessDate,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
    salesByPaymentMethod: salesByPaymentMethod.map((e) => e.toEntity).toList(),
    paymentLedgers: paymentLedgers.map((e) => e.toEntity).toList(),
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
    averageSale: averageSale,
    highestSale: highestSale,
    lowestSale: lowestSale,
    totalQuantitySold: totalQuantitySold,
  );
}
