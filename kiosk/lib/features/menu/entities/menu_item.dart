import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';

import '../enums/menu_type.dart';

part 'menu_item.mapper.dart';

@MappableClass()
class MenuItem with MenuItemMappable {
  const MenuItem({required this.label, required this.icon, required this.type, this.badgeCount});

  final String label;
  final Widget icon;
  final MenuType type;

  /// Count shown on the tile (e.g. pending orders). `null` hides the badge
  /// entirely; `0` still shows it — set explicitly by tiles that always
  /// display a live count, even when that count is zero.
  final int? badgeCount;
}
