import 'dart:typed_data';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/product_group_dto.dart';
import '../../../data/backend_api/schemas/product_group_query_dto.dart';
import '../../../data/backend_api/sources/product_groups_api.dart';
import '../../../utils/paginated_data.dart';
import '../entities/product_group.dart';

abstract class GetProductGroups {
  Future<PaginatedData<ProductGroup>> call({
    required int page,
    required int limit,
    String? name,
    String? description,
    String? sort,
  });
}

final getProductGroupsProvider = Provider<GetProductGroups>((ref) {
  return GetProductGroupsImpl(
    productGroupsApi: ref.watch(productGroupsApiProvider),
  );
});

class GetProductGroupsImpl implements GetProductGroups {
  const GetProductGroupsImpl({
    required ProductGroupsApi productGroupsApi,
  }) : _productGroupsApi = productGroupsApi;

  final ProductGroupsApi _productGroupsApi;

  @override
  Future<PaginatedData<ProductGroup>> call({
    required int page,
    required int limit,
    String? name,
    String? description,
    String? sort,
  }) async {
    final query = ProductGroupQueryDto(
      page: page,
      limit: limit,
      name: name,
      description: description,
      sort: sort,
    );
    final response = await _productGroupsApi.getAll(query);
    return PaginatedData(
      page: response.page,
      limit: response.limit,
      total: response.total,
      data: response.data.map(_productGroupFromProductGroupDto).toIList(),
    );
  }

  ProductGroup _productGroupFromProductGroupDto(ProductGroupDto dto) {
    return ProductGroup(
      id: dto.id,
      name: dto.name,
      description: dto.description ?? '',
      image: dto.imageUrl ?? Uint8List(0),
    );
  }
}
