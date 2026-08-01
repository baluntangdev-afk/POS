import 'sales_data_item.dart';
import 'sales_report_type.dart';
import 'sales_summary.dart';

class ExportableReport {
  const ExportableReport({
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
  final SalesSummary summary;
  final List<SalesReportType> hourlyBreakdown;
  final List<SalesDataItem> byProduct;
  final List<SalesDataItem> byProductGroup;
  final List<SalesDataItem> byPayment;
  final List<SalesDataItem> byCashier;
}
