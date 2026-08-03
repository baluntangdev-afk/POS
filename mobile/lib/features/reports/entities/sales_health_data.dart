import '../../../core/database/daos/sales_dao.dart';
import 'report_data.dart';

class SalesHealthData {
  final List<PaymentBreakdown> paymentBreakdown;
  final List<CashierSales> salesByCashier;
  final List<ProductGroupSales> salesByCategory;
  final List<TimeSeriesPoint> timeSeries;
  final String granularity;
  final DateTime from;
  final DateTime to;

  const SalesHealthData({
    required this.paymentBreakdown,
    required this.salesByCashier,
    required this.salesByCategory,
    required this.timeSeries,
    required this.granularity,
    required this.from,
    required this.to,
  });
}
