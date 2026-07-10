import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/reports_api.dart';
import '../entities/cashier_daily_report.dart';
import '../entities/cashier_x_reading.dart';
import '../mappers/cashier_daily_report_mappers.dart';
import '../mappers/cashier_x_reading_mappers.dart';

abstract class CashierReportRepository {
  Future<CashierXReading> getXReading();

  Future<CashierDailyReport> getDailyReport();
}

final cashierReportRepositoryProvider = Provider<CashierReportRepository>((ref) {
  final reportsApi = ref.watch(reportsApiProvider);
  return CashierReportRepositoryImpl(reportsApi: reportsApi);
});

class CashierReportRepositoryImpl implements CashierReportRepository {
  CashierReportRepositoryImpl({required ReportsApi reportsApi}) : _reportsApi = reportsApi;

  final ReportsApi _reportsApi;

  @override
  Future<CashierXReading> getXReading() async {
    final dto = await _reportsApi.getCashierXReading();
    return dto.toEntity;
  }

  @override
  Future<CashierDailyReport> getDailyReport() async {
    final dto = await _reportsApi.getCashierDailyReport();
    return dto.toEntity;
  }
}
