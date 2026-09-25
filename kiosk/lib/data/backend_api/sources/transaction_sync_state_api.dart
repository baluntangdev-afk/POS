import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';

final transactionSyncStateApiProvider = Provider<TransactionSyncStateApi>((ref) {
  return TransactionSyncStateApi(ref.watch(secureApiClientProvider));
});

typedef PendingTransactions = ({List<Map<String, dynamic>> sales, List<Map<String, dynamic>> refunds});

typedef PendingTransactionCounts = ({int sales, int refunds});

/// Our own backend's sync-state bookkeeping (`/api/v1/transaction-sync`):
/// hands out ready-to-send batches in the orders-service wire format and
/// records what the orders service accepted. Kiosk sales live in the backend's
/// database, so this replaces the mobile app's local `SalesDao` sync queries.
class TransactionSyncStateApi {
  const TransactionSyncStateApi(this._httpClient);

  final Dio _httpClient;

  /// Next batch of unsynced sales/refunds stamped with [storeId].
  Future<PendingTransactions> fetchPending(String storeId, {int limit = 15}) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/transaction-sync/pending',
      queryParameters: {'storeId': storeId, 'limit': limit},
    );
    final json = response.data as Map<String, dynamic>;
    return (
      sales: (json['sales'] as List<dynamic>).cast<Map<String, dynamic>>(),
      refunds: (json['refunds'] as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }

  Future<PendingTransactionCounts> fetchPendingCount(String storeId) async {
    final response = await _httpClient.get<dynamic>(
      '/api/v1/transaction-sync/pending/count',
      queryParameters: {'storeId': storeId},
    );
    final json = response.data as Map<String, dynamic>;
    return (sales: json['sales'] as int, refunds: json['refunds'] as int);
  }

  /// True if this device has any local sale or refund at all.
  Future<bool> hasTransactions() async {
    final response = await _httpClient.get<dynamic>('/api/v1/transaction-sync/has-transactions');
    return (response.data as Map<String, dynamic>)['hasTransactions'] as bool;
  }

  Future<void> markSynced({required List<int> saleIds, required List<int> refundIds}) async {
    if (saleIds.isEmpty && refundIds.isEmpty) return;
    await _httpClient.post<dynamic>(
      '/api/v1/transaction-sync/mark-synced',
      data: {'saleIds': saleIds, 'refundIds': refundIds},
    );
  }

  /// Re-queues every sale/refund and stamps every sale with [storeId], so the
  /// next sync pushes this device's full history to that merchant.
  Future<void> transfer(String storeId) async {
    await _httpClient.post<dynamic>('/api/v1/transaction-sync/transfer', data: {'storeId': storeId});
  }

  /// Re-queues every sale/refund for re-upload without changing any sale's
  /// store. Admin/supervisor only.
  Future<void> unsync() async {
    await _httpClient.post<dynamic>('/api/v1/transaction-sync/unsync');
  }
}
