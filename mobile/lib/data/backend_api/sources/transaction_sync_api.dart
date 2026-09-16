import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../errors/api_call.dart';
import '../schemas/transaction_sync_result_dto.dart';

final transactionSyncApiProvider = Provider<TransactionSyncApi>((ref) {
  final httpClient = ref.watch(dpoSocketApiClientProvider);
  return TransactionSyncApi(httpClient);
});

class TransactionSyncApi with ApiCall {
  const TransactionSyncApi(this._httpClient);

  final Dio _httpClient;

  /// `POST /merchant/transactions/sync`. `Authorization: Bearer <token>` is
  /// attached automatically by `WebhookTokenInterceptor` on this client —
  /// callers must call `WebhookAuthRepository.ensureToken(storeId)` first
  /// (see `TransactionSyncService.syncPending`), since the interceptor only
  /// attaches an already-cached token, it doesn't mint one from nothing.
  Future<TransactionSyncResultDto> pushBatch({
    required String storeId,
    required List<Map<String, Object?>> sales,
    required List<Map<String, Object?>> refunds,
  }) => guard(() async {
    final response = await _httpClient.post<dynamic>(
      '/merchant/transactions/sync',
      data: {'store_id': storeId, 'sales': sales, 'refunds': refunds},
    );
    return TransactionSyncResultDto.fromJson(jsonEncode(response.data));
  });
}
