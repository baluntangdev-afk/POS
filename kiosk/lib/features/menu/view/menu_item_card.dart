import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/menu_item.dart';
import '../enums/menu_type.dart';

class MenuItemCard extends HookWidget {
  const MenuItemCard({super.key, required this.menuItem, required this.onTap});

  final MenuItem menuItem;
  final void Function(MenuType) onTap;

  Color _accentColor() {
    switch (menuItem.type) {
      case MenuType.newOrder:
        return ColorSet.primary;
      case MenuType.transactions:
        return const Color(0xFF4A90D9);
      case MenuType.salesReports:
        return ColorSet.success;
      case MenuType.userManagement:
        return const Color(0xFF7B68EE);
      case MenuType.inventory:
        return const Color(0xFFE67E22);
      case MenuType.settings:
        return POSColors.textSecondary;
      case MenuType.logout:
        return ColorSet.danger;
      default:
        return ColorSet.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final responsive = ResponsiveValue.of(context);
    final minHeight = responsive.value<double>(kiosk: 170, tablet: 140, phone: 120);
    final iconSize = responsive.value<double>(kiosk: 52, tablet: 42, phone: 34);
    final labelSize = responsive.value<double>(kiosk: 17, tablet: 15, phone: 13);
    final accent = _accentColor();

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: AnimatedContainer(
        duration: POSAnimation.normal,
        curve: Curves.easeInOut,
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          border: Border.all(
            color: isHovered.value ? accent.withValues(alpha: 0.4) : POSColors.borderDefault,
            width: 1.5,
          ),
          boxShadow: isHovered.value
              ? [BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6))]
              : POSShadow.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          child: InkWell(
            onTap: () => onTap(menuItem.type),
            borderRadius: BorderRadius.circular(POSRadius.xl),
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.all(responsive.value<double>(kiosk: 24, tablet: 20, phone: 16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: POSAnimation.normal,
                    width: iconSize * 1.6,
                    height: iconSize * 1.6,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isHovered.value ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(POSRadius.lg),
                    ),
                    child: Center(
                      child: SizedBox(
                        height: iconSize,
                        width: iconSize,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                          child: menuItem.icon,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                  Text(
                    menuItem.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                      color: POSColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
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
