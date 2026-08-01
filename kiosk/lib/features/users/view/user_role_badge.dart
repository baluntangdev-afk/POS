import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';

class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (color, iconData, label) = switch (role) {
      'admin' => (ColorSet.secondary, Icons.admin_panel_settings_rounded, 'Admin'),
      'supervisor' => (ColorSet.tertiary, Icons.supervised_user_circle_rounded, 'Supervisor'),
      _ => (ColorSet.success, Icons.person_rounded, 'User'),
    };

    final r = context.responsive;
    final fontSize = r.value<double>(kiosk: 13, tablet: 12, phone: 12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 10, tablet: 9, phone: 8),
        vertical: 4,
      ),
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
