import '../../../data/backend_api/schemas/cashier_daily_report_dto.dart';
import '../entities/cashier_daily_report.dart';

extension ProductSalesLineDTOMapper on ProductSalesLineDto {
  ProductSalesLine get toEntity =>
      ProductSalesLine(quantity: quantity, productName: productName, amount: amount);
}

extension CashLedgerEntryDTOMapper on CashLedgerEntryDto {
  CashLedgerEntry get toEntity =>
      CashLedgerEntry(time: DateTime.parse(time), reference: reference, amount: amount);
}

extension CashierDailyReportDTOMapper on CashierDailyReportDto {
  CashierDailyReport get toEntity => CashierDailyReport(
    cashierName: cashierName,
    terminalName: terminalName,
    businessDate: businessDate,
    reportGeneratedAt: DateTime.parse(reportGeneratedAt),
    grossSales: grossSales,
    vatableSales: vatableSales,
    vatAmount: vatAmount,
    vatExemptSales: vatExemptSales,
    zeroRatedSales: zeroRatedSales,
    netOfTax: netOfTax,
    transactionCount: transactionCount,
    totalQuantity: totalQuantity,
    totalCashSales: totalCashSales,
    cashSalesCount: cashSalesCount,
    salesByProduct: salesByProduct.map((e) => e.toEntity).toList(),
    cashLedger: cashLedger.map((e) => e.toEntity).toList(),
  );
}
