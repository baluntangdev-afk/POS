import 'package:dart_mappable/dart_mappable.dart';

part 'sales_summary.mapper.dart';

@MappableClass()
class SalesSummary with SalesSummaryMappable {
  const SalesSummary({
    required this.totalSales,
    required this.totalDiscount,
    required this.totalRefunds,
    required this.totalItems,
    required this.totalTransactions,
    this.totalVoidedTransactions = 0,
    this.totalVoidedAmount = 0,
  });

  final double totalSales;
  final double totalDiscount;
  final double totalRefunds;
  final int totalItems;
  final int totalTransactions;
  final int totalVoidedTransactions;
  final double totalVoidedAmount;
}
