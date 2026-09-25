import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/transaction_sync/sales_sync_signal.dart';
import '../../../data/backend_api/schemas/void_sales_order_dto.dart';
import '../../../data/backend_api/sources/sales_orders_api.dart';

final voidSaleProvider = Provider<VoidSale>((ref) {
  return VoidSale(ref.watch(salesOrdersApiProvider), syncSignal: ref.watch(salesSyncSignalProvider));
});

class VoidSale {
  const VoidSale(this._api, {SalesSyncSignal? syncSignal}) : _syncSignal = syncSignal;

  final SalesOrdersApi _api;
  final SalesSyncSignal? _syncSignal;

  Future<void> call({
    required String salesOrderId,
    required String reason,
    required String authorizerUserId,
    required String authorizerPin,
  }) async {
    await _api.voidOrder(
      salesOrderId,
      VoidSalesOrderDto(
        reason: reason,
        authorizerUserId: authorizerUserId,
        authorizerPin: authorizerPin,
      ),
    );
    // A void re-queues the sale for sync so the orders service learns of it.
    _syncSignal?.notify();
  }
}
