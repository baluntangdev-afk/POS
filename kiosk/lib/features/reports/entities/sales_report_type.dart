import 'package:dart_mappable/dart_mappable.dart';

part 'sales_report_type.mapper.dart';

@MappableClass()
class SalesReportType with SalesReportTypeMappable {
  const SalesReportType({
    required this.date,
    required this.hour,
    required this.total,
    required this.transactions,
    required this.items,
    required this.discount,
    required this.year,
    required this.month,
  });

  final String date;
  final String hour;
  final String month;
  final String year;
  final double total;
  final int transactions;
  final int items;
  final double discount;

  static const fromJson = SalesReportTypeMapper.fromJson;
}
