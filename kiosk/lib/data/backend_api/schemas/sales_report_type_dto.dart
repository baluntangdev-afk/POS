import 'package:dart_mappable/dart_mappable.dart';

part 'sales_report_type_dto.mapper.dart';

@MappableClass()
class SalesReportTypeDto with SalesReportTypeDtoMappable {
  const SalesReportTypeDto({
    this.date,
    this.hour,
    required this.total,
    required this.transactions,
    required this.items,
    required this.discount,
    this.month,
    this.year,
  });

  final String? date;
  final String? hour;
  final String? year;
  final String? month;
  final double total;
  final int transactions;
  final int items;
  final double discount;

  static const fromJson = SalesReportTypeDtoMapper.fromJson;
}
