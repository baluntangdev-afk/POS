import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/cartivo_orders_api.dart';
import '../../cartivo_products/entities/cartivo_cart_item.dart';
import '../entities/cartivo_order.dart';
import '../mappers/cartivo_order_mappers.dart';

abstract class CartivoOrdersRepository {
  Future<CartivoOrder> createOrder({required List<CartivoCartItem> items});

  Future<List<CartivoOrder>> getOrders();
}

final cartivoOrdersRepositoryProvider = Provider<CartivoOrdersRepository>((ref) {
  final api = ref.watch(cartivoOrdersApiProvider);
  return CartivoOrdersRepositoryImpl(api: api);
});

class CartivoOrdersRepositoryImpl implements CartivoOrdersRepository {
  CartivoOrdersRepositoryImpl({required CartivoOrdersApi api}) : _api = api;

  final CartivoOrdersApi _api;

  @override
  Future<CartivoOrder> createOrder({required List<CartivoCartItem> items}) async {
    final dto = await _api.createOrder(
      items: items.map((item) => (productId: item.product.id, quantity: item.quantity)).toList(),
    );
    return dto.toEntity;
  }

  @override
  Future<List<CartivoOrder>> getOrders() async {
    final dtos = await _api.getOrders();
    return dtos.map((dto) => dto.toEntity).toList();
  }
}
