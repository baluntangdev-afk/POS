import 'package:dart_mappable/dart_mappable.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/paginated_data.dart';
import '../entities/product.dart';
import '../use_cases/delete_product.dart';
import '../use_cases/get_products.dart';
import '../use_cases/save_product.dart';

part 'products_notifier.mapper.dart';

final productsProvider = AsyncNotifierProvider<ProductsNotifier, ProductsData>(
  ProductsNotifier.new,
  name: 'productsProvider',
);

@MappableClass()
class ProductsData with ProductsDataMappable {
  const ProductsData({required this.data, this.filter, this.sort});

  final PaginatedData<Product> data;
  final ({String? name, String? description})? filter;
  final String? sort;
}

class ProductsNotifier extends AsyncNotifier<ProductsData> {
  static final saveAction = Mutation<Product>();
  static final deleteAction = Mutation<bool>();

  @override
  Future<ProductsData> build() async {
    final getProducts = ref.watch(getProductsProvider);
    final data = await getProducts(page: 1, limit: 10);
    return ProductsData(data: data);
  }

  Future<void> getResults({
    required int page,
    required int limit,
    String? name,
    String? description,
    String? sort,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final getProducts = ref.read(getProductsProvider);
      final results = await getProducts(
        page: page,
        limit: limit,
        name: name,
        description: description,
        sort: sort,
      );
      final filter = (name: name, description: description);
      return ProductsData(data: results, filter: filter, sort: sort);
    });
  }

  Future<void> refreshResults() async {
    if (!state.hasValue) return;

    final ProductsData(:data, :filter, :sort) = state.requireValue;
    await getResults(
      page: data.page,
      limit: data.limit,
      name: filter?.name,
      description: filter?.description,
      sort: sort,
    );
  }

  Future<Product> save(Product product) async {
    final saveProduct = ref.read(saveProductProvider);
    return saveProduct(product);
  }

  Future<bool> delete(Product product) async {
    final deleteProduct = ref.read(deleteProductProvider);
    return deleteProduct(product);
  }
}
