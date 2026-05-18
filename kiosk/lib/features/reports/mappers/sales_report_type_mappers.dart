import '../../../data/backend_api/schemas/sales_report_type_dto.dart';
import '../entities/sales_report_type.dart';

extension DTOMapper on SalesReportTypeDto {
  SalesReportType get toEntity => SalesReportType(
    date: date ?? '',
    hour: hour ?? '',
    total: total,
    transactions: transactions,
    items: items,
    discount: discount,
    year: year ?? '',
    month: month ?? '',
  );
}

extension EntityMapper on SalesReportType {
  SalesReportTypeDto get toModel => SalesReportTypeDto(
    date: date,
    hour: hour,
    total: total,
    transactions: transactions,
    items: items,
    discount: discount,
  );
}
