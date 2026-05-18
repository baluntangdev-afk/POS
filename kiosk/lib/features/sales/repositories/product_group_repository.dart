import 'dart:typed_data';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/product_group_dto.dart';
import '../../../data/backend_api/schemas/product_group_query_dto.dart';
import '../../../data/backend_api/sources/product_groups_api.dart';
import '../entities/product_group.dart';

abstract class ProductGroupRepository {
  Future<IList<ProductGroup>> getAll();
}

final productGroupRepositoryProvider = Provider<ProductGroupRepository>((ref) {
  final api = ref.watch(productGroupsApiProvider);
  return ProductGroupRepositoryImpl(api);
});

class ProductGroupRepositoryImpl implements ProductGroupRepository {
  const ProductGroupRepositoryImpl(this._productGroupsApi);

  final ProductGroupsApi _productGroupsApi;

  @override
  Future<IList<ProductGroup>> getAll() async {
    const query = ProductGroupQueryDto(page: 1, limit: 100);
    final response = await _productGroupsApi.getAll(query);
    return response.data.map(_productGroupFromProductGroupDto).toIList();
  }

  ProductGroup _productGroupFromProductGroupDto(ProductGroupDto dto) {
    return ProductGroup(id: dto.id, name: dto.name, image: dto.imageUrl ?? Uint8List(0));
  }
}
