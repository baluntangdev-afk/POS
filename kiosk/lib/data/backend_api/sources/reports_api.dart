import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/reports/state/sales_report_state.dart';
import '../api_clients.dart';
import '../schemas/cashier_daily_report_dto.dart';
import '../schemas/cashier_x_reading_dto.dart';
import '../schemas/exportable_report_dto.dart';
import '../schemas/sales_data_item_dto.dart';
import '../schemas/sales_report_type_dto.dart';
import '../schemas/sales_summary_dto.dart';

final reportsApiProvider = Provider<ReportsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return ReportsApi(httpClient);
});

class ReportsApi {
  const ReportsApi(this._httpClient);

  final Dio _httpClient;

  Future<SalesSummaryDto> getSalesReports({DateTime? startDate, DateTime? endDate}) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports',
      queryParameters: {
        'startDate': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'endDate': endDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    );
    final json = jsonEncode(response.data);
    return SalesSummaryDto.fromJson(json);
  }

  Future<List<SalesReportTypeDto>> getSalesReportType({
    required SalesReportPeriod type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports/type/${type.name}',
      queryParameters: {
        'startDate': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'endDate': endDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    );
    final dataList = response.data as List<dynamic>;
    return dataList.map((item) => SalesReportTypeDto.fromJson(jsonEncode(item))).toList();
  }

  Future<List<SalesDataItemDto>> getSalesByProductGroups({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports/product-group',
      queryParameters: {
        'startDate': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'endDate': endDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    );
    final dataList = response.data as List<dynamic>;
    return dataList.map((item) => SalesDataItemDto.fromJson(jsonEncode(item))).toList();
  }

  Future<List<SalesDataItemDto>> getSalesByProducts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports/product',
      queryParameters: {
        'startDate': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'endDate': endDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    );
    final dataList = response.data as List<dynamic>;
    return dataList.map((item) => SalesDataItemDto.fromJson(jsonEncode(item))).toList();
  }

  Future<List<SalesDataItemDto>> getSalesByUser({DateTime? startDate, DateTime? endDate}) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports/user',
      queryParameters: {
        'startDate': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'endDate': endDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    );
    final dataList = response.data as List<dynamic>;
    return dataList.map((item) => SalesDataItemDto.fromJson(jsonEncode(item))).toList();
  }

  Future<List<SalesDataItemDto>> getSalesByPayment({DateTime? startDate, DateTime? endDate}) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports/payment',
      queryParameters: {
        'startDate': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'endDate': endDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    );
    final dataList = response.data as List<dynamic>;
    return dataList.map((item) => SalesDataItemDto.fromJson(jsonEncode(item))).toList();
  }

  Future<ExportableReportDto> getExportable({required DateTime date}) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
    final response = await _httpClient.get<dynamic>(
      '/api/v1/reports/exportable',
      queryParameters: {'date': dateStr},
    );
    return ExportableReportDto.fromJson(jsonEncode(response.data));
  }

  Future<void> markExported({required DateTime date}) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
    await _httpClient.patch<dynamic>(
      '/api/v1/reports/mark-exported',
      data: {'date': dateStr},
    );
  }

  Future<CashierXReadingDto> getCashierXReading() async {
    final response = await _httpClient.get<dynamic>('/api/v1/reports/cashier-x-reading');
    return CashierXReadingDto.fromJson(jsonEncode(response.data));
  }

  Future<CashierDailyReportDto> getCashierDailyReport() async {
    final response = await _httpClient.get<dynamic>('/api/v1/reports/cashier-daily-report');
    return CashierDailyReportDto.fromJson(jsonEncode(response.data));
  }
}
