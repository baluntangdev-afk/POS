import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/create_product_group_dto.dart';
import '../../../data/backend_api/schemas/product_group_dto.dart';
import '../../../data/backend_api/schemas/update_product_group_dto.dart';
import '../../../data/backend_api/sources/product_groups_api.dart';
import '../entities/product_group.dart';

abstract class SaveProductGroup {
  Future<ProductGroup> call(ProductGroup productGroup);
}

final saveProductGroupProvider = Provider<SaveProductGroup>((ref) {
  return SaveProductGroupImpl(productGroupsApi: ref.watch(productGroupsApiProvider));
});

class SaveProductGroupImpl implements SaveProductGroup {
  const SaveProductGroupImpl({required ProductGroupsApi productGroupsApi})
    : _productGroupsApi = productGroupsApi;

  final ProductGroupsApi _productGroupsApi;

  @override
  Future<ProductGroup> call(ProductGroup productGroup) async {
    ProductGroupDto response;

    if (productGroup.id != ProductGroup.draft().id) {
      final request = _updateProductGroupDtoFromProductGroup(productGroup);
      response = await _productGroupsApi.update(
        productGroup.id,
        request,
        image: productGroup.image,
      );
    } else {
      final request = _createProductGroupDtoFromProductGroup(productGroup);
      response = await _productGroupsApi.create(request, image: productGroup.image);
    }

    return productGroup.copyWith(id: response.id);
  }

  CreateProductGroupDto _createProductGroupDtoFromProductGroup(ProductGroup productGroup) {
    return CreateProductGroupDto(name: productGroup.name, description: productGroup.description);
  }

  UpdateProductGroupDto _updateProductGroupDtoFromProductGroup(ProductGroup productGroup) {
    return UpdateProductGroupDto(name: productGroup.name, description: productGroup.description);
  }
}
