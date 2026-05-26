import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

import '../mappers/image_url_mapper.dart';
import 'menu_item_modifier_group_dto.dart';

part 'product_details_dto.mapper.dart';

@MappableClass(includeCustomMappers: [ImageUrlMapper()])
class ProductDetailsDto with ProductDetailsDtoMappable {
  const ProductDetailsDto({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.currencySign,
    required this.displayPrice,
    this.defaultVariantId,
    required this.modifierGroups,
  });

  final int id;
  final String name;
  final String description;
  final Uint8List? imageUrl;
  final String currencySign;
  final String displayPrice;
  final int? defaultVariantId;
  final List<MenuItemModifierGroupDto> modifierGroups;

  static const fromJson = ProductDetailsDtoMapper.fromJson;
}
