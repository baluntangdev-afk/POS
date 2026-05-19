import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../entities/menu_item.dart';
import '../enums/menu_type.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.menuItem, required this.onTap});

  final MenuItem menuItem;
  final void Function(MenuType) onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return AspectRatio(
      aspectRatio: r.value(kiosk: 1.0, tablet: 1.0, phone: 1.1),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onTap(menuItem.type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(r.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 3,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: menuItem.icon,
                    ),
                  ),
                ),
                SizedBox(height: r.spacingMd),
                Flexible(
                  child: Text(
                    menuItem.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.fontBody,
                      fontWeight: FontWeight.w500,
                      color: ColorSet.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
