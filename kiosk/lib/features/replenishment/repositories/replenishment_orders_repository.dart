import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/replenishment_orders_api.dart';
import '../entities/replenishment_cart_item.dart';
import '../entities/replenishment_order.dart';
import '../entities/replenishment_payment.dart';
import '../mappers/replenishment_order_mappers.dart';

abstract class ReplenishmentOrdersRepository {
  Future<ReplenishmentOrder> createOrder({
    required String customerId,
    required List<ReplenishmentCartItem> items,
  });

  Future<List<ReplenishmentOrder>> getOrders({required String customerId});

  Future<({ReplenishmentOrder order, ReplenishmentPayment payment})> payOrder(String orderId);
}

final replenishmentOrdersRepositoryProvider = Provider<ReplenishmentOrdersRepository>((ref) {
  final api = ref.watch(replenishmentOrdersApiProvider);
  return ReplenishmentOrdersRepositoryImpl(api: api);
});

class ReplenishmentOrdersRepositoryImpl implements ReplenishmentOrdersRepository {
  ReplenishmentOrdersRepositoryImpl({required ReplenishmentOrdersApi api}) : _api = api;

  final ReplenishmentOrdersApi _api;

  @override
  Future<ReplenishmentOrder> createOrder({
    required String customerId,
    required List<ReplenishmentCartItem> items,
  }) async {
    final dto = await _api.createOrder(
      customerId: customerId,
      items: items
          .map((item) => (productId: item.product.id, quantity: item.quantity))
          .toList(),
    );
    return dto.toEntity;
  }

  @override
  Future<List<ReplenishmentOrder>> getOrders({required String customerId}) async {
    final dtos = await _api.getOrders(customerId: customerId);
    return dtos.map((dto) => dto.toEntity).toList();
  }

  @override
  Future<({ReplenishmentOrder order, ReplenishmentPayment payment})> payOrder(
    String orderId,
  ) async {
    final dto = await _api.payOrder(orderId);
    return (order: dto.order.toEntity, payment: dto.payment.toEntity);
  }
}
