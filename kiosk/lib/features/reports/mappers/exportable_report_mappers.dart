import '../../../data/backend_api/schemas/exportable_report_dto.dart';
import '../entities/exportable_report.dart';
import '../enums/sales_data_item_type.dart';
import 'sales_data_item_mappers.dart';
import 'sales_report_type_mappers.dart';
import 'sales_summary_mappers.dart';

extension ExportableReportDTOMapper on ExportableReportDto {
  ExportableReport get toEntity => ExportableReport(
    date: date,
    count: count,
    summary: summary.toEntity,
    hourlyBreakdown: hourlyBreakdown.map((e) => e.toEntity).toList(),
    byProduct: byProduct
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.product))
        .toList(),
    byProductGroup: byProductGroup
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.productGroup))
        .toList(),
    byPayment: byPayment
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.payment))
        .toList(),
    byCashier: byCashier
        .map((e) => e.toEntity.copyWith(type: SalesDataItemType.user))
        .toList(),
  );
}
