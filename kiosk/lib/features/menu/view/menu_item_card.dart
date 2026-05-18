import 'package:flutter/material.dart';

import '../../../styles/responsive/responsive_value.dart';
import '../entities/menu_item.dart';
import '../enums/menu_type.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.menuItem, required this.onTap});

  final MenuItem menuItem;
  final void Function(MenuType) onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveValue.of(context);

    return Container(
      height: responsive.scale(300),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onTap(menuItem.type),
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: responsive.scale(90),
                    width: responsive.scale(90),
                    child: menuItem.icon,
                  ),
                  SizedBox(height: responsive.scale(16), width: responsive.scale(16)),
                  Text(
                    menuItem.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: responsive.scale(20), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
