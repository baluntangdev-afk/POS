import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/product_groups_api.dart';
import '../entities/product_group.dart';

abstract class DeleteProductGroup {
  Future<bool> call(ProductGroup productGroup);
}

final deleteProductGroupProvider = Provider<DeleteProductGroup>((ref) {
  return DeleteProductGroupImpl(
    productGroupsApi: ref.watch(productGroupsApiProvider),
  );
});

class DeleteProductGroupImpl implements DeleteProductGroup {
  const DeleteProductGroupImpl({
    required ProductGroupsApi productGroupsApi,
  }) : _productGroupsApi = productGroupsApi;

  final ProductGroupsApi _productGroupsApi;

  @override
  Future<bool> call(ProductGroup productGroup) async {
    return _productGroupsApi.delete(productGroup.id);
  }
}
