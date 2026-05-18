import 'package:dart_mappable/dart_mappable.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/paginated_data.dart';
import '../entities/product_group.dart';
import '../use_cases/delete_product_group.dart';
import '../use_cases/get_product_groups.dart';
import '../use_cases/save_product_group.dart';

part 'product_groups_notifier.mapper.dart';

final productGroupsProvider = AsyncNotifierProvider<ProductGroupsNotifier, ProductGroupsData>(
  ProductGroupsNotifier.new,
  name: 'productGroupsProvider',
);

@MappableClass()
class ProductGroupsData with ProductGroupsDataMappable {
  const ProductGroupsData({required this.data, this.filter, this.sort});

  final PaginatedData<ProductGroup> data;
  final ({String? name, String? description})? filter;
  final String? sort;
}

class ProductGroupsNotifier extends AsyncNotifier<ProductGroupsData> {
  static final saveAction = Mutation<ProductGroup>();
  static final deleteAction = Mutation<bool>();

  @override
  Future<ProductGroupsData> build() async {
    final getProductGroups = ref.watch(getProductGroupsProvider);
    final data = await getProductGroups(page: 1, limit: 10);
    return ProductGroupsData(data: data);
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
      final getProductGroups = ref.read(getProductGroupsProvider);
      final results = await getProductGroups(
        page: page,
        limit: limit,
        name: name,
        description: description,
        sort: sort,
      );
      final filter = (name: name, description: description);
      return ProductGroupsData(data: results, filter: filter, sort: sort);
    });
  }

  Future<void> refreshResults() async {
    if (!state.hasValue) return;

    final ProductGroupsData(:data, :filter, :sort) = state.requireValue;
    await getResults(
      page: data.page,
      limit: data.limit,
      name: filter?.name,
      description: filter?.description,
      sort: sort,
    );
  }

  Future<ProductGroup> save(ProductGroup productGroup) async {
    final saveProductGroup = ref.read(saveProductGroupProvider);
    return saveProductGroup(productGroup);
  }

  Future<bool> delete(ProductGroup productGroup) async {
    final deleteProductGroup = ref.read(deleteProductGroupProvider);
    return deleteProductGroup(productGroup);
  }
}
