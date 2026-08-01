import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/void_sales_order_dto.dart';
import '../../../data/backend_api/sources/sales_orders_api.dart';

final voidSaleProvider = Provider<VoidSale>((ref) {
  return VoidSale(ref.watch(salesOrdersApiProvider));
});

class VoidSale {
  const VoidSale(this._api);

  final SalesOrdersApi _api;

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
  }
}
