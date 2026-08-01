import 'package:dart_mappable/dart_mappable.dart';

import 'sales_data_item_dto.dart';
import 'sales_report_type_dto.dart';
import 'sales_summary_dto.dart';

part 'exportable_report_dto.mapper.dart';

@MappableClass()
class ExportableReportDto with ExportableReportDtoMappable {
  const ExportableReportDto({
    required this.date,
    required this.count,
    required this.summary,
    required this.hourlyBreakdown,
    required this.byProduct,
    required this.byProductGroup,
    required this.byPayment,
    required this.byCashier,
  });

  final String date;
  final int count;
  final SalesSummaryDto summary;
  final List<SalesReportTypeDto> hourlyBreakdown;
  final List<SalesDataItemDto> byProduct;
  final List<SalesDataItemDto> byProductGroup;
  final List<SalesDataItemDto> byPayment;
  final List<SalesDataItemDto> byCashier;

  static const fromJson = ExportableReportDtoMapper.fromJson;
}
