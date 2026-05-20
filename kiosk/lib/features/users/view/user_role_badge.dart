import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';

class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({required this.isAdmin, super.key});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final color = isAdmin ? ColorSet.secondary : ColorSet.success;
    final iconData = isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded;
    final label = isAdmin ? 'Admin' : 'User';
    final fontSize = context.responsive.scale(13);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(POSRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: fontSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
