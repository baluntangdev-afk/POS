import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/confirm_sales_order_dto.dart';
import '../schemas/create_sales_order_dto.dart';
import '../schemas/paginated_response_dto.dart';
import '../schemas/sales_order_query_dto.dart';
import '../schemas/sales_order_with_items_response_dto.dart';

final salesOrdersApiProvider = Provider<SalesOrdersApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return SalesOrdersApi(httpClient);
});

class SalesOrdersApi {
  const SalesOrdersApi(this._httpClient);

  final Dio _httpClient;

  Future<SalesOrderWithItemsResponseDto> create(CreateSalesOrderDto request) async {
    final response = await _httpClient.post<dynamic>(
      '/api/v1/sales-orders',
      data: request.toJson(),
    );
    final json = jsonEncode(response.data);
    return SalesOrderWithItemsResponseDto.fromJson(json);
  }

  Future<SalesOrderWithItemsResponseDto> getById(String id) async {
    final response = await _httpClient.get<dynamic>('/api/v1/sales-orders/$id');
    final json = jsonEncode(response.data);
    return SalesOrderWithItemsResponseDto.fromJson(json);
  }

  Future<SalesOrderWithItemsResponseDto> confirm(String id, ConfirmSalesOrderDto request) async {
    final response = await _httpClient.patch<dynamic>(
      '/api/v1/sales-orders/$id/confirm',
      data: request.toJson(),
    );
    final json = jsonEncode(response.data);
    return SalesOrderWithItemsResponseDto.fromJson(json);
  }

  Future<PaginatedResponseDto<SalesOrderWithItemsResponseDto>> getAll(
    SalesOrderQueryDto query,
  ) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/sales-orders',
      queryParameters: query.toMap(),
    );
    final json = jsonEncode(response.data);
    SalesOrderWithItemsResponseDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<SalesOrderWithItemsResponseDto>(json);
  }
}
