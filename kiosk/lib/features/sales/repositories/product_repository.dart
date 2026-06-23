import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/menu_item_modifier_group_dto.dart';
import '../../../data/backend_api/schemas/menu_item_modifier_option_dto.dart';
import '../../../data/backend_api/schemas/product_details_dto.dart';
import '../../../data/backend_api/schemas/product_list_item_dto.dart';
import '../../../data/backend_api/schemas/product_variant_details_dto.dart';
import '../../../data/backend_api/sources/product_groups_api.dart';
import '../../../data/backend_api/sources/products_api.dart';
import '../entities/modifier_group.dart';
import '../entities/modifier_option.dart';
import '../entities/product.dart';
import '../entities/product_group.dart';
import '../entities/product_variant.dart';

abstract class ProductRepository {
  Future<IList<Product>> getByGroup(ProductGroup group);

  Future<Product> getById(int id);
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final productGroupsApi = ref.watch(productGroupsApiProvider);
  final productsApi = ref.watch(productsApiProvider);
  return ProductRepositoryImpl(productGroupsApi, productsApi);
});

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._productGroupsApi, this._productsApi);

  final ProductGroupsApi _productGroupsApi;
  final ProductsApi _productsApi;

  @override
  Future<IList<Product>> getByGroup(ProductGroup group) async {
    try {
      final paginatedDto = await _productGroupsApi.getProductsByGroup(group.id);
      return paginatedDto.data.map(_productFromListItemDto).toIList();
    } catch (e, s) {
      debugPrint('TESTING $e $s');
      return IList.empty();
    }

  }

  @override
  Future<Product> getById(int id) async {
    try {
      final dto = await _productsApi.getById(id);
      return _productFromDetailsDto(dto);
    } catch (e) {
      throw Exception(e);
    }
  }

  Product _productFromListItemDto(ProductListItemDto dto) {
    return Product(
      categoryName: dto.categoryName,
      id: dto.id,
      name: dto.name,
      price: Decimal.parse(dto.price),
      image: dto.imageUrl ?? '',
      modifierGroups: const IList.empty(),
    );
  }

  Product _productFromDetailsDto(ProductDetailsDto dto) {
    return Product(
      categoryName: dto.categoryName ?? '',
      id: dto.id,
      name: dto.name,
      image: dto.imageUrl ?? '',
      price: Decimal.parse(dto.displayPrice),
      modifierGroups: dto.modifierGroups.map(_modifierGroupFromDto).toIList(),
      variants: dto.variants.map(_productVariantFromDto).toIList(),
      defaultVariantId: dto.defaultVariantId ?? 0,
    );
  }

  ProductVariant _productVariantFromDto(ProductVariantDetailsDto dto) {
    return ProductVariant(
      id: dto.id,
      name: dto.name,
      price: Decimal.parse(dto.displayPrice),
      isDefault: dto.isDefault,
    );
  }

  ModifierGroup _modifierGroupFromDto(MenuItemModifierGroupDto dto) {
    return ModifierGroup(
      id: dto.id,
      name: dto.name,
      minSelections: dto.minSelection,
      maxSelections: dto.maxSelection,
      options: dto.options.map(_modifierOptionFromDto).toIList(),
    );
  }

  ModifierOption _modifierOptionFromDto(MenuItemModifierOptionDto dto) {
    return ModifierOption(
      id: dto.id,
      name: dto.name,
      price: Decimal.parse(dto.priceAddOn),
      image: dto.imageUrl,
    );
  }
}
