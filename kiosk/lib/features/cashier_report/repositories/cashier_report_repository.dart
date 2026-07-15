import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/reports_api.dart';
import '../../../utils/paginated_data.dart';
import '../entities/cashier_daily_report.dart';
import '../entities/cashier_x_reading.dart';
import '../entities/z_reading.dart';
import '../mappers/cashier_daily_report_mappers.dart';
import '../mappers/cashier_x_reading_mappers.dart';
import '../mappers/z_reading_mappers.dart';

abstract class CashierReportRepository {
  Future<CashierXReading> getXReading();

  Future<CashierDailyReport> getDailyReport();

  Future<CashierXReading> closeXReading();

  Future<CashierDailyReport> closeDailyReport();

  Future<PaginatedData<CashierXReadingHistoryItem>> getXReadingHistory({
    required int page,
    required int limit,
  });

  Future<PaginatedData<CashierDailyReportHistoryItem>> getDailyReportHistory({
    required int page,
    required int limit,
  });

  Future<CashierXReading> getXReadingHistoryDetail(String id);

  Future<CashierDailyReport> getDailyReportHistoryDetail(String id);

  Future<ZReading> getZReading();

  Future<ZReading> closeZReading({required String authorizerId, required String pin});

  Future<PaginatedData<ZReadingHistoryItem>> getZReadingHistory({
    required int page,
    required int limit,
  });

  Future<ZReading> getZReadingHistoryDetail(String id);
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

  @override
  Future<CashierXReading> closeXReading() async {
    final dto = await _reportsApi.closeCashierXReading();
    return dto.toEntity;
  }

  @override
  Future<CashierDailyReport> closeDailyReport() async {
    final dto = await _reportsApi.closeCashierDailyReport();
    return dto.toEntity;
  }

  @override
  Future<PaginatedData<CashierXReadingHistoryItem>> getXReadingHistory({
    required int page,
    required int limit,
  }) async {
    final response = await _reportsApi.getCashierXReadingHistory(page: page, limit: limit);
    return PaginatedData(
      page: response.page,
      limit: response.limit,
      total: response.total,
      data: response.data.map((dto) => dto.toEntity).toIList(),
    );
  }

  @override
  Future<PaginatedData<CashierDailyReportHistoryItem>> getDailyReportHistory({
    required int page,
    required int limit,
  }) async {
    final response = await _reportsApi.getCashierDailyReportHistory(page: page, limit: limit);
    return PaginatedData(
      page: response.page,
      limit: response.limit,
      total: response.total,
      data: response.data.map((dto) => dto.toEntity).toIList(),
    );
  }

  @override
  Future<CashierXReading> getXReadingHistoryDetail(String id) async {
    final dto = await _reportsApi.getCashierXReadingHistoryDetail(id);
    return dto.toEntity;
  }

  @override
  Future<CashierDailyReport> getDailyReportHistoryDetail(String id) async {
    final dto = await _reportsApi.getCashierDailyReportHistoryDetail(id);
    return dto.toEntity;
  }

  @override
  Future<ZReading> getZReading() async {
    final dto = await _reportsApi.getZReading();
    return dto.toEntity;
  }

  @override
  Future<ZReading> closeZReading({required String authorizerId, required String pin}) async {
    final dto = await _reportsApi.closeZReading(authorizerId: authorizerId, pin: pin);
    return dto.toEntity;
  }

  @override
  Future<PaginatedData<ZReadingHistoryItem>> getZReadingHistory({
    required int page,
    required int limit,
  }) async {
    final response = await _reportsApi.getZReadingHistory(page: page, limit: limit);
    return PaginatedData(
      page: response.page,
      limit: response.limit,
      total: response.total,
      data: response.data.map((dto) => dto.toEntity).toIList(),
    );
  }

  @override
  Future<ZReading> getZReadingHistoryDetail(String id) async {
    final dto = await _reportsApi.getZReadingHistoryDetail(id);
    return dto.toEntity;
  }
}
