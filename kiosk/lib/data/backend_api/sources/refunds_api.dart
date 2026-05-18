import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/create_refund_dto.dart';
import '../schemas/paginated_response_dto.dart';
import '../schemas/refund_query_dto.dart';
import '../schemas/refund_with_items_response_dto.dart';

final refundsApiProvider = Provider<RefundsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return RefundsApi(httpClient);
});

class RefundsApi {
  const RefundsApi(this._httpClient);

  final Dio _httpClient;

  Future<RefundWithItemsResponseDto> create(CreateRefundDto request) async {
    final response = await _httpClient.post<dynamic>('/api/v1/refunds', data: request.toJson());
    final json = jsonEncode(response.data);
    return RefundWithItemsResponseDto.fromJson(json);
  }

  Future<PaginatedResponseDto<RefundWithItemsResponseDto>> getAll(RefundQueryDto query) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/refunds',
      queryParameters: query.toMap(),
    );
    final json = jsonEncode(response.data);
    RefundWithItemsResponseDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<RefundWithItemsResponseDto>(json);
  }
}
