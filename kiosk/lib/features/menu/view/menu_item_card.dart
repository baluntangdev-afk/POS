import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
    final responsive = ResponsiveValue.of(context);
    final minWidth = responsive.value<double>(kiosk: 200, tablet: 160, phone: 130);
    final minHeight = responsive.value<double>(kiosk: 160, tablet: 130, phone: 110);
    final iconSize = responsive.value<double>(kiosk: 64, tablet: 48, phone: 36);
    final labelSize = responsive.value<double>(kiosk: 24, tablet: 20, phone: 16);

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => onTap(menuItem.type),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: ColorSet.primary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: iconSize,
                  width: iconSize,
                  child: menuItem.icon,
                ),
                Gap(responsive.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                Text(
                  menuItem.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                    color: ColorSet.dark,
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
