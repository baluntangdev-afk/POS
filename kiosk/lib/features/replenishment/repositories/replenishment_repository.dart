import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/replenishment_products_api.dart';
import '../entities/replenishment_product.dart';
import '../mappers/replenishment_product_mappers.dart';

abstract class ReplenishmentRepository {
  Future<List<ReplenishmentProduct>> getProducts();
}

final replenishmentRepositoryProvider = Provider<ReplenishmentRepository>((ref) {
  final api = ref.watch(replenishmentProductsApiProvider);
  return ReplenishmentRepositoryImpl(api: api);
});

class ReplenishmentRepositoryImpl implements ReplenishmentRepository {
  ReplenishmentRepositoryImpl({required ReplenishmentProductsApi api}) : _api = api;

  final ReplenishmentProductsApi _api;

  @override
  Future<List<ReplenishmentProduct>> getProducts() async {
    final dtos = await _api.getProducts();
    return dtos.map((dto) => dto.toEntity).toList();
  }
}
