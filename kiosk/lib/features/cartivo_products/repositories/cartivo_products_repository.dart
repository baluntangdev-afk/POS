import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/cartivo_products_api.dart';
import '../entities/cartivo_product.dart';
import '../mappers/cartivo_product_mappers.dart';

abstract class CartivoProductsRepository {
  Future<List<CartivoProduct>> getProducts();
}

final cartivoProductsRepositoryProvider = Provider<CartivoProductsRepository>((ref) {
  final api = ref.watch(cartivoProductsApiProvider);
  return CartivoProductsRepositoryImpl(api: api);
});

class CartivoProductsRepositoryImpl implements CartivoProductsRepository {
  CartivoProductsRepositoryImpl({required CartivoProductsApi api}) : _api = api;

  final CartivoProductsApi _api;

  @override
  Future<List<CartivoProduct>> getProducts() async {
    final dtos = await _api.getProducts();
    return dtos.map((dto) => dto.toEntity).toList();
  }
}
