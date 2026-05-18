import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

import '../mappers/image_url_mapper.dart';

part 'menu_item_modifier_option_dto.mapper.dart';

@MappableClass(includeCustomMappers: [ImageUrlMapper()])
class MenuItemModifierOptionDto with MenuItemModifierOptionDtoMappable {
  const MenuItemModifierOptionDto({
    required this.id,
    required this.name,
    required this.priceAddOn,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String priceAddOn;
  final Uint8List? imageUrl;

  static const fromJson = MenuItemModifierOptionDtoMapper.fromJson;
}
