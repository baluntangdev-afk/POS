import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';

/// Tile card for the Cartivo merchant hub grid (Products / Orders /
/// Transactions). Styled like `MenuItemCard` but standalone since that
/// widget is coupled to the in-store `MenuType` enum.
class CartivoDashboardTileCard extends HookWidget {
  const CartivoDashboardTileCard({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final r = context.responsive;
    final minHeight = r.value<double>(kiosk: 170, tablet: 140, phone: 120);
    final iconSize = r.value<double>(kiosk: 52, tablet: 42, phone: 34);
    final labelSize = r.value<double>(kiosk: 17, tablet: 15, phone: 13);

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
            color: isHovered.value ? accentColor.withValues(alpha: 0.4) : POSColors.borderDefault,
            width: 1.5,
          ),
          boxShadow: isHovered.value
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6))]
              : POSShadow.card,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(POSRadius.xl),
            splashColor: accentColor.withValues(alpha: 0.08),
            highlightColor: accentColor.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.all(r.value<double>(kiosk: 24, tablet: 20, phone: 16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: POSAnimation.normal,
                    width: iconSize * 1.6,
                    height: iconSize * 1.6,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isHovered.value ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(POSRadius.lg),
                    ),
                    child: Center(child: Icon(icon, color: accentColor, size: iconSize)),
                  ),
                  SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                  Text(
                    label,
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
