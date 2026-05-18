import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';

import '../enums/menu_type.dart';

part 'menu_item.mapper.dart';

@MappableClass()
class MenuItem with MenuItemMappable {
  const MenuItem({required this.label, required this.icon, required this.type});

  final String label;
  final Widget icon;
  final MenuType type;
}
