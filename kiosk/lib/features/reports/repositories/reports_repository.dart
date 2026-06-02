import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/reports_api.dart';
import '../entities/exportable_report.dart';
import '../entities/sales_data_item.dart';
import '../entities/sales_report_type.dart';
import '../entities/sales_summary.dart';
import '../enums/sales_data_item_type.dart';
import '../mappers/exportable_report_mappers.dart';
import '../mappers/sales_data_item_mappers.dart';
import '../mappers/sales_report_type_mappers.dart';
import '../mappers/sales_summary_mappers.dart';
import '../state/sales_report_state.dart';

abstract class ReportsRepository {
  Future<SalesSummary> getSalesReports({DateTime? startDate, DateTime? endDate});

  Future<IList<SalesReportType>> getSalesReportType({
    required SalesReportPeriod type,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<IList<SalesDataItem>> getSalesByProductGroups({DateTime? startDate, DateTime? endDate});

  Future<IList<SalesDataItem>> getSalesByProducts({DateTime? startDate, DateTime? endDate});

  Future<IList<SalesDataItem>> getSalesByUser({DateTime? startDate, DateTime? endDate});

  Future<IList<SalesDataItem>> getSalesByPayment({DateTime? startDate, DateTime? endDate});

  Future<ExportableReport> getExportable({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> markExported(DateTime date);
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final reportsApi = ref.watch(reportsApiProvider);
  return ReportsRepositoryImpl(reportsApi: reportsApi);
});

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({required ReportsApi reportsApi}) : _reportsApi = reportsApi;

  final ReportsApi _reportsApi;

  @override
  Future<SalesSummary> getSalesReports({DateTime? startDate, DateTime? endDate}) async {
    final response = await _reportsApi.getSalesReports(startDate: startDate, endDate: endDate);
    return response.toEntity;
  }

  @override
  Future<IList<SalesReportType>> getSalesReportType({
    required SalesReportPeriod type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _reportsApi.getSalesReportType(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
    return response.map((e) => e.toEntity).toIList();
  }

  @override
  Future<IList<SalesDataItem>> getSalesByProductGroups({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _reportsApi.getSalesByProductGroups(
      startDate: startDate,
      endDate: endDate,
    );
    return response.map((e) => e.toEntity.copyWith(type: SalesDataItemType.productGroup)).toIList();
  }

  @override
  Future<IList<SalesDataItem>> getSalesByProducts({DateTime? startDate, DateTime? endDate}) async {
    final response = await _reportsApi.getSalesByProducts(startDate: startDate, endDate: endDate);
    return response.map((e) => e.toEntity.copyWith(type: SalesDataItemType.product)).toIList();
  }

  @override
  Future<IList<SalesDataItem>> getSalesByUser({DateTime? startDate, DateTime? endDate}) async {
    final response = await _reportsApi.getSalesByUser(startDate: startDate, endDate: endDate);
    return response.map((e) => e.toEntity.copyWith(type: SalesDataItemType.user)).toIList();
  }

  @override
  Future<IList<SalesDataItem>> getSalesByPayment({DateTime? startDate, DateTime? endDate}) async {
    final response = await _reportsApi.getSalesByPayment(startDate: startDate, endDate: endDate);
    return response.map((e) => e.toEntity.copyWith(type: SalesDataItemType.payment)).toIList();
  }

  @override
  Future<ExportableReport> getExportable({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dto = await _reportsApi.getExportable(
      startDate: startDate,
      endDate: endDate,
    );
    return dto.toEntity;
  }

  @override
  Future<void> markExported(DateTime date) async {
    await _reportsApi.markExported(date: date);
  }
}
