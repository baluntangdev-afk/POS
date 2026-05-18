import 'package:dart_mappable/dart_mappable.dart';

import 'menu_item_modifier_group_dto.dart';

part 'product_variant_details_dto.mapper.dart';

@MappableClass()
class ProductVariantDetailsDto with ProductVariantDetailsDtoMappable {
  const ProductVariantDetailsDto({
    required this.id,
    required this.name,
    required this.displayPrice,
    required this.menuItemId,
    required this.isDefault,
    required this.modifierGroups,
  });

  final int id;
  final String name;
  final String displayPrice;
  final int menuItemId;
  final bool isDefault;
  final List<MenuItemModifierGroupDto> modifierGroups;

  static const fromJson = ProductVariantDetailsDtoMapper.fromJson;
}
