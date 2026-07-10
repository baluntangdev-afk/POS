import 'package:dart_mappable/dart_mappable.dart';

part 'cashier_daily_report_dto.mapper.dart';

@MappableClass()
class ProductSalesLineDto with ProductSalesLineDtoMappable {
  const ProductSalesLineDto({
    required this.quantity,
    required this.productName,
    required this.amount,
  });

  final int quantity;
  final String productName;
  final double amount;
}

@MappableClass()
class CashLedgerEntryDto with CashLedgerEntryDtoMappable {
  const CashLedgerEntryDto({required this.time, required this.reference, required this.amount});

  final String time;
  final String? reference;
  final double amount;
}

@MappableClass()
class CashierDailyReportDto with CashierDailyReportDtoMappable {
  const CashierDailyReportDto({
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
  final String reportGeneratedAt;
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
  final List<ProductSalesLineDto> salesByProduct;
  final List<CashLedgerEntryDto> cashLedger;

  static const fromJson = CashierDailyReportDtoMapper.fromJson;
}
