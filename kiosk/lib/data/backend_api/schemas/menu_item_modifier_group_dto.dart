import 'package:dart_mappable/dart_mappable.dart';

import 'menu_item_modifier_option_dto.dart';

part 'menu_item_modifier_group_dto.mapper.dart';

@MappableClass()
class MenuItemModifierGroupDto with MenuItemModifierGroupDtoMappable {
  const MenuItemModifierGroupDto({
    required this.id,
    required this.name,
    required this.menuItemModifierId,
    required this.minSelection,
    required this.maxSelection,
    required this.options,
  });

  final int id;
  final int menuItemModifierId;
  final String name;
  final int minSelection;
  final int maxSelection;
  final List<MenuItemModifierOptionDto> options;

  static const fromJson = MenuItemModifierGroupDtoMapper.fromJson;
}
