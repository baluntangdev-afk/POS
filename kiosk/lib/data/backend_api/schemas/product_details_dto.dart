import 'package:dart_mappable/dart_mappable.dart';

import 'menu_item_modifier_group_dto.dart';
import 'product_variant_details_dto.dart';

part 'product_details_dto.mapper.dart';

@MappableClass()
class ProductDetailsDto with ProductDetailsDtoMappable {
  const ProductDetailsDto({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.currencySign,
    required this.displayPrice,
    this.defaultVariantId,
    required this.variants,
    required this.modifierGroups,
    this.categoryName,
  });

  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String currencySign;
  final String displayPrice;
  final int? defaultVariantId;
  final List<ProductVariantDetailsDto> variants;
  final List<MenuItemModifierGroupDto> modifierGroups;
  final String? categoryName;

  static const fromJson = ProductDetailsDtoMapper.fromJson;
}
