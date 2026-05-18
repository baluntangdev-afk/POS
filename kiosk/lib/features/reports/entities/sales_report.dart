import 'package:dart_mappable/dart_mappable.dart';

part 'sales_report.mapper.dart';

@MappableClass()
class SalesReport with SalesReportMappable {
  const SalesReport({
    required this.transactionDate,
    required this.totalNetSales,
    required this.discount,
    required this.transactions,
    required this.items,
  });

  final DateTime transactionDate;
  final double totalNetSales;
  final double discount;
  final int transactions;
  final int items;
}
