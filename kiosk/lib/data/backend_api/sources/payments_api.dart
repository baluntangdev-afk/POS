import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/paginated_response_dto.dart';
import '../schemas/payment_query_dto.dart';
import '../schemas/payment_response_dto.dart';

final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  final httpClient = ref.watch(secureApiClientProvider);
  return PaymentsApi(httpClient);
});

class PaymentsApi {
  const PaymentsApi(this._httpClient);

  final Dio _httpClient;

  Future<PaginatedResponseDto<PaymentResponseDto>> getAll(PaymentQueryDto query) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/payments',
      queryParameters: query.toMap(),
    );
    final json = jsonEncode(response.data);
    PaymentResponseDtoMapper.ensureInitialized();
    return PaginatedResponseDtoMapper.fromJson<PaymentResponseDto>(json);
  }
}
